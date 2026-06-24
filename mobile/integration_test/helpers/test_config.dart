/// Configuration for the E2E auth suite.
///
/// Values are injected at build time via `--dart-define` so credentials never
/// live in source. See integration_test/README.md for the full command.
///
/// Example:
///   patrol test \
///     --dart-define=E2E_EMAIL=e2e-test@yourdomain.com \
///     --dart-define=E2E_PASSWORD='SuperSecret123!' \
///     --dart-define=E2E_HELPER_URL=http://10.0.2.2:8765
class TestConfig {
  /// Test account email. The suite creates this account via sign-up and
  /// destroys it via the app's Delete Account flow on every run.
  static const String email = String.fromEnvironment(
    'E2E_EMAIL',
    defaultValue: 'e2e-test@example.com',
  );

  /// Test account password. Must satisfy the app's 6-char minimum and
  /// Firebase's policy.
  static const String password = String.fromEnvironment(
    'E2E_PASSWORD',
    defaultValue: 'Test1234!',
  );

  /// Display name used during sign-up.
  static const String fullName = String.fromEnvironment(
    'E2E_FULL_NAME',
    defaultValue: 'E2E Tester',
  );

  /// Base URL of the local Firebase Admin helper, reachable from the Android
  /// emulator at the host loopback alias 10.0.2.2.
  static const String helperBaseUrl = String.fromEnvironment(
    'E2E_HELPER_URL',
    defaultValue: 'http://10.0.2.2:8765',
  );

  /// A deliberately wrong password for unhappy-path sign-in tests.
  static const String wrongPassword = 'WrongPass!99';

  /// An email that should not exist, for unknown-account sign-in tests.
  static const String unknownEmail = 'no-such-user-e2e@example.com';
}
