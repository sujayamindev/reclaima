import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:patrol/patrol.dart';

/// Page-object for the authentication screens.
///
/// Selectors mirror the real widgets: text fields are plain [TextFormField]s
/// (from `AppTextField`) targeted by their order on each form, and buttons /
/// links / list tiles are matched by their visible label.
///
/// Form field order (do not reorder without updating these):
///   Login:  [0] Email, [1] Password
///   Signup: [0] Full Name, [1] Email, [2] Password, [3] Confirm Password
class AuthRobot {
  AuthRobot(this.$);

  final PatrolIntegrationTester $;

  // ---- Login screen ----------------------------------------------------

  Future<void> waitForLogin() =>
      $('Log In').waitUntilVisible(timeout: const Duration(seconds: 30));

  Future<void> enterLoginCredentials({
    required String email,
    required String password,
  }) async {
    await $(TextFormField).at(0).enterText(email);
    await $(TextFormField).at(1).enterText(password);
  }

  Future<void> tapSignIn() => $('Sign In').tap();

  /// Login screen -> Signup screen via the "Sign Up" link.
  Future<void> goToSignUp() async {
    await $('Sign Up').tap();
    await $('Sign up').waitUntilVisible(); // signup header
  }

  // ---- Signup screen ---------------------------------------------------

  Future<void> enterSignUpDetails({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    await $(TextFormField).at(0).enterText(fullName);
    await $(TextFormField).at(1).enterText(email);
    await $(TextFormField).at(2).enterText(password);
    await $(TextFormField).at(3).enterText(confirmPassword);
  }

  Future<void> tapSignUp() => $('Sign Up').tap();

  // ---- Verify-email screen --------------------------------------------

  Future<void> waitForVerifyEmail() => $(
    'Verify your email',
  ).waitUntilVisible(timeout: const Duration(seconds: 30));

  // ---- Authenticated shell --------------------------------------------

  /// After verification the app lands on the Home tab, which requests native
  /// camera/notification/storage permissions on first frame. Grant any dialog
  /// so it doesn't block subsequent interactions.
  Future<void> grantPermissionsIfPrompted() async {
    for (var i = 0; i < 3; i++) {
      if (await $.native.isPermissionDialogVisible()) {
        await $.native.grantPermissionWhenInUse();
        await $.pump(const Duration(milliseconds: 500));
      } else {
        break;
      }
    }
  }

  // ---- Settings -> Profile & Security -> Danger Zone ------------------

  Future<void> openSettingsTab() async {
    await $(Symbols.menu_rounded).tap();
    await $('Profile & Security').waitUntilVisible();
  }

  Future<void> openProfileSecurity() async {
    await $('Profile & Security').tap();
  }

  Future<void> tapLogOut() async {
    await $('Log Out').scrollTo().tap();
  }

  /// Opens the Delete Account confirmation dialog and confirms it.
  Future<void> deleteAccountAndConfirm() async {
    await $('Delete Account').scrollTo().tap();
    // Confirmation dialog: title "Delete Account", action button "Delete".
    await $('Delete').waitUntilVisible();
    await $('Delete').tap();
  }
}
