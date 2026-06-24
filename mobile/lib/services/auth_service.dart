// coverage:ignore-file
import 'package:firebase_auth/firebase_auth.dart';
import '../core/utils/logger.dart';
import '../data/models/user_model.dart';
import 'api_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../core/constants/app_constants.dart';

/// Authentication service
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiService _apiService;
  bool _isGoogleInitialized = false;

  AuthService(this._apiService);

  /// Get current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      if (currentUser != null && !currentUser!.emailVerified) {
        await currentUser!.sendEmailVerification();
        logger.i('Verification email sent to ${currentUser!.email}');
      }
    } catch (e) {
      logger.e('Failed to send verification email: $e');
      rethrow;
    }
  }

  /// Reload user and check if email is verified
  Future<bool> isEmailVerified() async {
    if (currentUser == null) return false;
    await currentUser!.reload();
    return currentUser!.emailVerified;
  }

  /// Sign up with email and password
  Future<UserCredential> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      logger.i('Signing up user: $email');

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      try {
        await userCredential.user?.sendEmailVerification();
      } catch (e) {
        logger.w('Failed to send verification email during signup: $e');
      }

      // Register user in backend with full name.
      // Non-fatal: Firebase auth is the primary auth source.
      // userProfileProvider will retry registration if this fails.
      try {
        await registerInBackend(fullName: fullName);
      } catch (e) {
        logger.w(
          'Backend registration failed during signup (will retry via profile provider): $e',
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      logger.e('Firebase signup error: ${e.code}');

      if (e.code == 'email-already-in-use') {
        throw 'This email is already in use. If you signed up with Google or Apple, please use that sign-in button.';
      }

      rethrow;
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      logger.i('Signing in user: $email');

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      logger.e('Firebase signin error: ${e.code}');

      if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
        throw 'Incorrect email or password. If you signed up with Google or Apple, please use that sign-in button.';
      }

      rethrow;
    }
  }

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      logger.i('Starting Google sign-in flow');

      if (!_isGoogleInitialized) {
        await GoogleSignIn.instance.initialize();
        _isGoogleInitialized = true;
      }

      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Request client authorization to get access token (needed for some Firebase/Google features)
      final GoogleSignInClientAuthorization? clientAuth = await googleUser
          .authorizationClient
          .authorizationForScopes(['email', 'profile']);

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: clientAuth?.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Register or update user in backend
      try {
        await registerInBackend(fullName: userCredential.user?.displayName);
      } catch (e) {
        logger.w('Backend registration failed during Google signup: $e');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      logger.e('Firebase Google signin error: ${e.code}');
      rethrow;
    } catch (e) {
      logger.e('Google signin error: $e');
      throw Exception('Google sign-in failed: $e'); // standardized throwing
    }
  }

  /// Sign in with Apple
  Future<UserCredential> signInWithApple() async {
    try {
      logger.i('Starting Apple sign-in flow');

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final OAuthCredential credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Register or update user in backend
      try {
        await registerInBackend(fullName: userCredential.user?.displayName);
      } catch (e) {
        logger.w('Backend registration failed during Apple signup: $e');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      logger.e('Firebase Apple signin error: ${e.code}');
      rethrow;
    } catch (e) {
      logger.e('Apple signin error: $e');
      throw Exception('Apple sign-in failed: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    logger.i('Signing out user');
    if (_isGoogleInitialized) {
      try {
        await GoogleSignIn.instance.disconnect();
      } catch (e) {
        logger.w('Failed to disconnect GoogleSignIn: $e');
      }
      try {
        await GoogleSignIn.instance.signOut();
      } catch (e) {
        logger.w('Failed to sign out from GoogleSignIn: $e');
      }
    }
    await _auth.signOut();
  }

  /// Register user in backend after Firebase signup
  Future<UserModel> registerInBackend({String? fullName}) async {
    try {
      final data = fullName != null ? {'full_name': fullName} : null;
      final response = await _apiService.post(
        ApiConstants.authRegister,
        data: data,
      );
      return UserModel.fromJson(response.data);
    } catch (e) {
      logger.e('Error registering user in backend: $e');
      rethrow;
    }
  }

  /// Get current user profile from backend
  Future<UserModel> getCurrentUserProfile() async {
    try {
      final response = await _apiService.get(ApiConstants.authMe);
      return UserModel.fromJson(response.data);
    } catch (e) {
      logger.e('Error getting user profile: $e');
      rethrow;
    }
  }

  /// Update current user profile in backend
  Future<UserModel> updateProfile({
    String? displayName,
    String? contactNumber,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (displayName != null) data['displayName'] = displayName;
      if (contactNumber != null) data['contactNumber'] = contactNumber;

      final response = await _apiService.patch(ApiConstants.authMe, data: data);
      return UserModel.fromJson(response.data);
    } catch (e) {
      logger.e('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Delete current user account (Backend + Firebase)
  Future<void> deleteAccount() async {
    logger.i('Deleting user account...');

    // Best-effort: remove the backend record. Don't let a backend HTTP error
    // (transient outage, auth mismatch in test environments) block the user
    // from deleting their Firebase account.
    try {
      await _apiService.delete(ApiConstants.authMe);
    } catch (e) {
      logger.w('Backend delete /auth/me failed (continuing): $e');
    }

    // Firebase Auth delete is the primary operation; requires-recent-login
    // is re-thrown so the UI can prompt the user to re-authenticate.
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await user.delete();
        logger.i('User deleted successfully');
      } catch (e) {
        logger.e('Error deleting user from Firebase: $e');
        rethrow;
      }
    }
  }

  /// Change password for currently signed-in user
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('User not signed in or email not available');
      }

      // Re-authenticate user first
      final AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Then update password
      await user.updatePassword(newPassword);
      logger.i('Password updated successfully');
    } on FirebaseAuthException catch (e) {
      logger.e('Error changing password: ${e.code}');
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      logger.i('Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      logger.e('Password reset error: ${e.code}');
      rethrow;
    }
  }
}
