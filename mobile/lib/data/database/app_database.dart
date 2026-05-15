// coverage:ignore-file
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

/// Claim documents table
class ClaimDocuments extends Table {
  TextColumn get id => text()();
  TextColumn get receiptId => text()();
  TextColumn get lineItemId => text().nullable()();
  TextColumn get issueDescription => text()();
  TextColumn get claimType => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('SUBMITTED'))();
  TextColumn get notes => text().nullable()();
  TextColumn get generatedPdfS3Key => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Defect images associated with a claim document
class ClaimDefectImages extends Table {
  TextColumn get id => text()();
  TextColumn get claimId =>
      text().references(ClaimDocuments, #id, onDelete: KeyAction.cascade)();
  TextColumn get s3ObjectKey => text()();
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Receipts,
    ReceiptLineItems,
    UploadQueue,
    ClaimDocuments,
    ClaimDefectImages,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // In-memory database for widget tests — avoids platform path_provider calls.
  AppDatabase.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 4;

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
        // v2 → v3: Schema change - quantity and amount removed.
        // In SQLite, we can just leave the columns in the physical table.
        // Drift will stop using them since they are no longer defined in the ReceiptLineItems class.
        // This preserves all other data in the table.
      }
      if (from < 4) {
        // v3 → v4: Claim documents and defect images added for offline support.
        await m.createTable(claimDocuments);
        await m.createTable(claimDefectImages);
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
      (update(receipts)..where((r) => r.id.equals(id))).write(
        ReceiptsCompanion(syncedAt: Value(DateTime.now())),
      );

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
  Future<int> incrementUploadRetry(
    String id,
    int currentRetryCount,
    String? errorMsg,
  ) => (update(uploadQueue)..where((u) => u.id.equals(id))).write(
    UploadQueueCompanion(
      retryCount: Value(currentRetryCount + 1),
      lastAttemptAt: Value(DateTime.now()),
      errorMessage: Value(errorMsg),
    ),
  );

  // Claim operations

  /// Get claims, optionally filtered by receipt or line item
  Future<List<ClaimDocument>> getClaims({
    String? receiptId,
    String? lineItemId,
  }) {
    final query = select(claimDocuments);
    if (lineItemId != null) {
      query.where((c) => c.lineItemId.equals(lineItemId));
    } else if (receiptId != null) {
      query.where((c) => c.receiptId.equals(receiptId));
    }
    return query.get();
  }

  /// Get a single claim by ID
  Future<ClaimDocument?> getClaimById(String id) =>
      (select(claimDocuments)..where((c) => c.id.equals(id))).getSingleOrNull();

  /// Upsert a claim and replace its defect images atomically
  Future<void> upsertClaimWithImages(
    ClaimDocumentsCompanion claim,
    List<ClaimDefectImagesCompanion> images,
  ) async {
    await transaction(() async {
      await into(claimDocuments).insertOnConflictUpdate(claim);
      await (delete(
        claimDefectImages,
      )..where((i) => i.claimId.equals(claim.id.value))).go();
      for (final img in images) {
        await into(claimDefectImages).insertOnConflictUpdate(img);
      }
    });
  }

  /// Get defect images for a claim, ordered by display position
  Future<List<ClaimDefectImage>> getDefectImagesForClaim(String claimId) =>
      (select(claimDefectImages)
            ..where((i) => i.claimId.equals(claimId))
            ..orderBy([(i) => OrderingTerm.asc(i.displayOrder)]))
          .get();

  /// Delete a claim (cascades to its defect images)
  Future<int> deleteClaimById(String id) =>
      (delete(claimDocuments)..where((c) => c.id.equals(id))).go();
}

/// Open database connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'smart_receipt.db'));
    return NativeDatabase(file);
  });
}
