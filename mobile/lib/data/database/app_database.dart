import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'app_database.g.dart';

/// Receipts table (product/warranty fields have moved to ReceiptLineItems)
class Receipts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get s3ObjectKey => text().nullable()();
  TextColumn get storeName => text().nullable()();
  DateTimeColumn get purchaseDate => dateTime().nullable()();
  RealColumn get totalAmount => real().nullable()();
  TextColumn get currency => text().nullable()();
  TextColumn get status => text()();
  IntColumn get ocrRetryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastOcrAttemptAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  // Invoice / vendor fields
  TextColumn get invoiceNumber => text().nullable()();
  TextColumn get vendorAddress => text().nullable()();
  TextColumn get vendorPhone => text().nullable()();
  TextColumn get vendorEmail => text().nullable()();
  TextColumn get vendorUrl => text().nullable()();
  // Document-level OCR text
  TextColumn get warrantyNotes => text().nullable()();
  TextColumn get remarks => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  TextColumn get localImagePath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Receipt line items table (warranty & product info lives here)
class ReceiptLineItems extends Table {
  TextColumn get id => text()();
  TextColumn get receiptId =>
      text().references(Receipts, #id, onDelete: KeyAction.cascade)();
  IntColumn get rowIndex => integer().withDefault(const Constant(0))();
  TextColumn get productCode => text().nullable()();
  TextColumn get itemDescription => text().nullable()();
  RealColumn get unitPrice => real().nullable()();
  // Per-item product & warranty fields
  TextColumn get productName => text().nullable()();
  TextColumn get productCategory => text().nullable()();
  TextColumn get productImageUrl => text().nullable()();
  IntColumn get warrantyPeriodMonths => integer().nullable()();
  DateTimeColumn get warrantyExpiryDate => dateTime().nullable()();
  IntColumn get returnPeriodDays => integer().nullable()();
  DateTimeColumn get returnExpiryDate => dateTime().nullable()();
  // Reminder settings
  IntColumn get warrantyLeadDaysOverride => integer().nullable()();
  IntColumn get returnLeadDaysOverride => integer().nullable()();
  BoolColumn get warrantyReminderEnabled => boolean().nullable()();
  BoolColumn get returnReminderEnabled => boolean().nullable()();
  TextColumn get status => text().withDefault(const Constant('ACTIVE'))();
  TextColumn get replacementForId => text().nullable()();
  TextColumn get replacedById => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Upload queue for offline support
class UploadQueue extends Table {
  TextColumn get id => text()();
  TextColumn get receiptId => text()();
  TextColumn get localImagePath => text()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get errorMessage => text().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Receipts, ReceiptLineItems, UploadQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v1 → v2: ReceiptLineItems table added;
            // product/warranty columns dropped from Receipts.
            await m.createTable(receiptLineItems);
            await m.addColumn(receipts, receipts.invoiceNumber);
            await m.addColumn(receipts, receipts.vendorAddress);
            await m.addColumn(receipts, receipts.vendorPhone);
            await m.addColumn(receipts, receipts.vendorEmail);
            await m.addColumn(receipts, receipts.vendorUrl);
            await m.addColumn(receipts, receipts.warrantyNotes);
            await m.addColumn(receipts, receipts.remarks);
            // Note: Drift cannot drop columns on SQLite — the old
            // productName, productCategory, warrantyPeriodMonths,
            // warrantyExpiryDate, returnPeriodDays, returnExpiryDate columns
            // will remain in the physical table but are no longer mapped.
          }
          if (from < 3) {
            // v2 → v3: Schema change - quantity and amount removed
            // For fresh databases, onCreate handles this.
            // For existing v2 databases, we recreate the table to match new schema.
            // This is acceptable since the database is fresh (confirmed by user).
            
            // Drop and recreate ReceiptLineItems table with new schema
            await m.deleteTable('receipt_line_items');
            await m.createTable(receiptLineItems);
          }
        },
      );
  
  // Receipt operations
  
  /// Get all receipts
  Future<List<Receipt>> getAllReceipts() => select(receipts).get();
  
  /// Get receipt by ID
  Future<Receipt?> getReceipt(String id) =>
      (select(receipts)..where((r) => r.id.equals(id))).getSingleOrNull();
  
  /// Insert or update receipt
  Future<int> upsertReceipt(ReceiptsCompanion receipt) =>
      into(receipts).insertOnConflictUpdate(receipt);
  
  /// Delete receipt
  Future<int> deleteReceipt(String id) =>
      (delete(receipts)..where((r) => r.id.equals(id))).go();
  
  /// Get receipts that need syncing
  Future<List<Receipt>> getUnsyncedReceipts() =>
      (select(receipts)..where((r) => r.syncedAt.isNull())).get();
  
  /// Mark receipt as synced
  Future<int> markReceiptSynced(String id) =>
      (update(receipts)..where((r) => r.id.equals(id)))
          .write(ReceiptsCompanion(syncedAt: Value(DateTime.now())));
  
  // Upload queue operations
  
  /// Get all pending uploads
  Future<List<UploadQueueData>> getPendingUploads() =>
      select(uploadQueue).get();
  
  /// Add to upload queue
  Future<int> addToUploadQueue(UploadQueueCompanion upload) =>
      into(uploadQueue).insert(upload);
  
  /// Remove from upload queue
  Future<int> removeFromUploadQueue(String id) =>
      (delete(uploadQueue)..where((u) => u.id.equals(id))).go();
  
  /// Update upload retry count
  Future<int> incrementUploadRetry(String id, int currentRetryCount, String? errorMsg) =>
      (update(uploadQueue)..where((u) => u.id.equals(id))).write(
        UploadQueueCompanion(
          retryCount: Value(currentRetryCount + 1),
          lastAttemptAt: Value(DateTime.now()),
          errorMessage: Value(errorMsg),
        ),
      );
}

/// Open database connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'smart_receipt.db'));
    return NativeDatabase(file);
  });
}
