import 'package:dio/dio.dart';

import 'test_config.dart';

/// Client for the local Firebase Admin helper service
/// (integration_test/tools/test_admin_helper.py).
///
/// Lets the on-device test verify a freshly signed-up account's email and clean
/// up the account — operations the Admin SDK must perform off-device.
class AdminHelperClient {
  AdminHelperClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: TestConfig.helperBaseUrl,
              connectTimeout: const Duration(seconds: 5),
              // The helper's first Firebase Admin SDK call cold-starts its
              // connection to the Auth emulator, which can take well over 10s.
              receiveTimeout: const Duration(seconds: 30),
            ),
          );

  final Dio _dio;

  /// Blocks until the helper answers /health, so the test fails fast with a
  /// clear message if the helper was not started.
  Future<void> waitUntilReady({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      try {
        final res = await _dio.get<Map<String, dynamic>>('/health');
        if (res.statusCode == 200) return;
      } catch (_) {
        // Not up yet; retry.
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    throw StateError(
      'Firebase Admin helper not reachable at ${TestConfig.helperBaseUrl}. '
      'Start it with mobile/scripts/run_e2e.ps1 (or run the Python helper '
      'manually) before running the suite.',
    );
  }

  /// Marks [email]'s account as email-verified.
  Future<void> verifyEmail(String email) async {
    await _dio.post<Map<String, dynamic>>(
      '/verify-email',
      data: {'email': email},
    );
  }

  /// Deletes [email]'s account if it exists. Idempotent — safe to call as a
  /// pre-flight and as a teardown safety net.
  Future<void> deleteUser(String email) async {
    await _dio.post<Map<String, dynamic>>(
      '/delete-user',
      data: {'email': email},
    );
  }

  /// Creates and returns a Firebase custom token for [email].
  ///
  /// Use with [FirebaseAuth.instance.signInWithCustomToken] to bypass
  /// RecaptchaCallWrapper, which hangs on successful email/password sign-ins
  /// in automated test environments (Play Integrity cannot complete).
  Future<String> customToken(String email) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/custom-token',
      data: {'email': email},
    );
    return res.data!['token'] as String;
  }

  /// Whether a Firebase user with [email] currently exists.
  Future<bool> userExists(String email) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/user-exists',
      queryParameters: {'email': email},
    );
    return res.data?['exists'] == true;
  }
}
