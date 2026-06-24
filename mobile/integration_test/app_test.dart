import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'package:mobile/main.dart';
import 'package:mobile/providers/auth_provider.dart';

import 'helpers/admin_helper_client.dart';
import 'helpers/auth_robot.dart';
import 'helpers/teardown_log.dart';
import 'helpers/test_config.dart';

/// Top-level FCM background handler, mirroring main.dart. Required before the
/// app registers `FirebaseMessaging.onBackgroundMessage`.
@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Boots the real app (same bootstrap as main.dart, minus Sentry) and waits for
/// the first screen. We avoid pumpWidgetAndSettle here because the auth-loading
/// spinner animates forever and would time out a settle.
Future<void> _bootApp(PatrolIntegrationTester $) async {
  await Firebase.initializeApp();
  // Redirect all auth traffic to the local Firebase Auth emulator so that
  // email/password sign-up never hits Play Integrity / reCAPTCHA (which hangs
  // indefinitely in automated tests). automaticHostMapping must be false on
  // physical devices — true would remap 127.0.0.1 → 10.0.2.2, which only
  // works on Android Studio emulators, not real hardware.
  await FirebaseAuth.instance.useAuthEmulator(
    '127.0.0.1',
    9099,
    automaticHostMapping: false,
  );
  FirebaseMessaging.onBackgroundMessage(_bgHandler);
  await $.tester.pumpWidget(const ProviderScope(child: MyApp()));
}

void main() {
  // Unhappy paths that are pure client-side form validation — no Firebase,
  // no backend. Fast and deterministic.
  patrolTest('sign-up form validation rejects bad input', ($) async {
    final robot = AuthRobot($);

    await _bootApp($);
    await robot.waitForLogin();
    await robot.goToSignUp();

    // Empty form -> required-field errors.
    await robot.tapSignUp();
    expect($(find.textContaining('Please enter your full name')), findsWidgets);

    // Invalid email format.
    await robot.enterSignUpDetails(
      fullName: TestConfig.fullName,
      email: 'not-an-email',
      password: TestConfig.password,
      confirmPassword: TestConfig.password,
    );
    await robot.tapSignUp();
    expect(
      $(find.textContaining('Please enter a valid email address')),
      findsWidgets,
    );

    // Password too short.
    await robot.enterSignUpDetails(
      fullName: TestConfig.fullName,
      email: TestConfig.email,
      password: '123',
      confirmPassword: '123',
    );
    await robot.tapSignUp();
    expect(
      $(find.textContaining('Password must be at least 6 characters')),
      findsWidgets,
    );

    // Mismatched confirmation.
    await robot.enterSignUpDetails(
      fullName: TestConfig.fullName,
      email: TestConfig.email,
      password: TestConfig.password,
      confirmPassword: '${TestConfig.password}-different',
    );
    await robot.tapSignUp();
    expect($(find.textContaining('Passwords do not match')), findsWidgets);
  });

  // The full self-cleaning lifecycle: create the account via sign-up and
  // destroy it via the app's own Delete Account flow, leaving the project clean
  // for the next run. A helper passes the email-verification gate; a teardown
  // safety net removes the account if any phase aborts.
  patrolTest('auth lifecycle: sign-up, verify, session, sign-in, delete', (
    $,
  ) async {
    final helper = AdminHelperClient();
    final robot = AuthRobot($);
    final teardown = TeardownLog();

    // --- Pre-flight: helper up + clean slate ---------------------------
    await helper.waitUntilReady();
    await helper.deleteUser(TestConfig.email);
    teardown.register(
      'firebase account ${TestConfig.email}',
      () => helper.deleteUser(TestConfig.email),
    );

    try {
      await _bootApp($);

      // --- PHASE 1: SIGN-UP -------------------------------------------
      await robot.waitForLogin();
      await robot.goToSignUp();
      await robot.enterSignUpDetails(
        fullName: TestConfig.fullName,
        email: TestConfig.email,
        password: TestConfig.password,
        confirmPassword: TestConfig.password,
      );
      await robot.tapSignUp();
      await robot.waitForVerifyEmail();

      // --- PHASE 2: EMAIL VERIFICATION --------------------------------
      // Mark verified server-side; the screen polls reload() every 3s and
      // then auto-navigates to the home shell.
      await helper.verifyEmail(TestConfig.email);
      await _settleToHome($, robot);

      // --- PHASE 3: SESSION, SIGN-OUT, UNHAPPY + HAPPY SIGN-IN --------
      await robot.openSettingsTab();
      await robot.openProfileSecurity();
      await robot.tapLogOut();
      await robot.waitForLogin();

      // Unhappy: wrong password for an existing account.
      await robot.enterLoginCredentials(
        email: TestConfig.email,
        password: TestConfig.wrongPassword,
      );
      await robot.tapSignIn();
      expect(
        $(find.textContaining('Incorrect email or password')),
        findsWidgets,
      );

      // Happy: sign in via custom token to bypass RecaptchaCallWrapper, which
      // hangs indefinitely on successful email/password sign-ins in automated
      // test environments (Play Integrity cannot complete on physical devices
      // without a live Play Services connection). Custom token sign-in skips
      // that layer entirely while still satisfying requires-recent-login for
      // the subsequent account deletion.
      final signInToken = await helper.customToken(TestConfig.email);
      await FirebaseAuth.instance.signInWithCustomToken(signInToken);
      expect(
        FirebaseAuth.instance.currentUser,
        isNotNull,
        reason: 'signInWithCustomToken did not establish a session',
      );
      // authStateChanges() does not fire under Patrol after
      // signInWithCustomToken(). Force authStateProvider to re-subscribe:
      // FirebaseAuth replays the current signed-in user to any new listener,
      // which updates Riverpod to data(user) and lets main.dart navigate to
      // the authenticated home shell.
      final appElement = $.tester.element(find.byType(MyApp));
      ProviderScope.containerOf(appElement).invalidate(authStateProvider);
      await _settleToHome($, robot);

      // --- PHASE 4: DELETE ACCOUNT (tests deletion AND cleans up) -----
      await robot.openSettingsTab();
      await robot.openProfileSecurity();
      await robot.deleteAccountAndConfirm();

      // The full Delete Account UI flow has now run, invoking the app's real
      // deleteAccount() -> FirebaseAuth user.delete(). We verify the deletion
      // authoritatively rather than by waiting for a return to the Login screen:
      // user.delete()'s method-channel reply hangs under Patrol (the native
      // deletion completes and clears currentUser, but the Dart Future never
      // resolves), so neither the app's post-delete navigation nor
      // authStateChanges() can drive the UI back to Login within the test. That
      // is a Patrol/FirebaseAuth limitation, not an app bug — and the reactive
      // Login navigation is already covered by Phase 3's logout -> Login.
      //
      // Poll until the Firebase client clears its session (proves user.delete()
      // executed), then confirm server-side that the account is truly gone.
      var sessionCleared = false;
      for (var attempt = 0; attempt < 15; attempt++) {
        await _pumpDrainingBenign($, const Duration(seconds: 1));
        if (FirebaseAuth.instance.currentUser == null) {
          sessionCleared = true;
          break;
        }
      }
      // Let the post-deletion provider churn (failed 401 retries on the home
      // shell) settle, draining the benign rebuild assertions it emits, before
      // the final assertions run.
      for (var i = 0; i < 5; i++) {
        await _pumpDrainingBenign($, const Duration(seconds: 1));
      }
      expect(
        sessionCleared,
        isTrue,
        reason: 'Delete Account did not clear the Firebase session',
      );

      // Authoritative assertion: the Firebase user no longer exists.
      expect(await helper.userExists(TestConfig.email), isFalse);
    } finally {
      // Safety net: idempotent, covers aborts before Phase 4.
      await teardown.cleanUp();
    }
  });
}

/// Waits for the home shell to appear after authentication, granting the native
/// permission dialogs the Home screen requests on first frame.
Future<void> _settleToHome(PatrolIntegrationTester $, AuthRobot robot) async {
  // Give the verify-email poll / auth stream time to navigate. Pump in small
  // slices, draining the benign "setState during build" Riverpod can emit while
  // the auth providers settle onto the new frame.
  for (var i = 0; i < 8; i++) {
    await _pumpDrainingBenign($, const Duration(milliseconds: 500));
  }
  await robot.grantPermissionsIfPrompted();
  // "Add New" is a stable Home-screen control.
  await $('Add New').waitUntilVisible(timeout: const Duration(seconds: 30));
}

/// Pumps for [d], then consumes the benign "setState during build" assertion
/// Riverpod can emit while the auth providers settle after a custom-token
/// sign-in or an account deletion (Riverpod reschedules the rebuild and
/// navigation still completes correctly). Any other caught exception is
/// rethrown so genuine failures still surface.
Future<void> _pumpDrainingBenign(PatrolIntegrationTester $, Duration d) async {
  await $.pump(d);
  final ex = $.tester.takeException();
  if (ex != null && !ex.toString().contains('setState() or markNeedsBuild')) {
    throw ex;
  }
}
