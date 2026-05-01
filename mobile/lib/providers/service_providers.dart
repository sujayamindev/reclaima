// coverage:ignore-file
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/receipt_service.dart';
import '../services/product_image_service.dart';
import '../services/notification_service.dart';
import '../data/database/app_database.dart';
import '../data/repositories/receipt_repository.dart';

/// API Service provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

/// Database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Auth Service provider
final authServiceProvider = Provider<AuthService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthService(apiService);
});

/// Receipt Service provider
final receiptServiceProvider = Provider<ReceiptService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ReceiptService(apiService);
});

/// Receipt Repository provider
final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  final service = ref.watch(receiptServiceProvider);
  final db = ref.watch(databaseProvider);
  return ReceiptRepository(service, db);
});

/// Product Image Service provider
final productImageServiceProvider = Provider<ProductImageService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ProductImageService(apiService);
});

/// Notification Service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return NotificationService(apiService);
});
