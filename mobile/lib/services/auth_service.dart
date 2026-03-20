import 'package:firebase_auth/firebase_auth.dart';
import '../core/utils/logger.dart';
import '../data/models/user_model.dart';
import 'api_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
      
      // Register user in backend with full name.
      // Non-fatal: Firebase auth is the primary auth source.
      // userProfileProvider will retry registration if this fails.
      try {
        await registerInBackend(fullName: fullName);
      } catch (e) {
        logger.w('Backend registration failed during signup (will retry via profile provider): $e');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      logger.e('Firebase signup error: ${e.code}');
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
      
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      
      // Request client authorization to get access token (needed for some Firebase/Google features)
      final GoogleSignInClientAuthorization? clientAuth = 
          await googleUser.authorizationClient.authorizationForScopes(['email', 'profile']);
          
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
  
  /// Sign out
  Future<void> signOut() async {
    logger.i('Signing out user');
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
