// coverage:ignore-file
// Theme & design system — single import for all screens:
export 'app_colors.dart';
export 'app_text_styles.dart';
export 'app_dimensions.dart';
export 'app_theme.dart';

/// API configuration constants
class ApiConstants {
  // Base URL - Change this to your backend URL.
  // Override at build time with --dart-define=API_BASE_URL=... (used by E2E tests).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://168.138.170.92:8000/api/v1',
  );

  // For Android emulator to access host machine
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:8000/api/v1';

  // Endpoints
  static const String authRegister = '/auth/register';
  static const String authMe = '/auth/me';
  static const String receipts = '/receipts';
  static const String warranties = '/warranties';
  static const String productImageSearch = '/products/image-search';
  static const String notificationPreferences = '/notifications/preferences';
  static const String fcmToken = '/notifications/fcm-token';
  static const String health = '/health';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

/// App configuration constants
class AppConstants {
  static const String appName = 'Reclaima';
  static const String appVersion = '1.0.0';

  // File upload limits
  static const int maxFileSizeMB = 20;
  static const int maxFileSizeBytes = maxFileSizeMB * 1024 * 1024;

  // Allowed file types
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];
  static const List<String> allowedDocTypes = ['pdf'];

  // Pagination
  static const int defaultPageSize = 20;

  // Claim types for warranty claims
  static const List<String> claimTypes = ['warranty', 'return'];
}

/// Storage keys for shared preferences
class StorageKeys {
  static const String firebaseToken = 'firebase_token';
  static const String userId = 'user_id';
  static const String userEmail = 'user_email';
  static const String isFirstLaunch = 'is_first_launch';
}
