import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../services/auth_service.dart';
import 'service_providers.dart';

/// Auth state provider - listen to Firebase auth changes
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value;
});

/// User profile provider - fetch from backend
final userProfileProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  
  if (user == null) return null;
  
  // Wait a brief moment for backend registration to complete
  // (Firebase auth fires before our backend POST /auth/register finishes)
  await Future.delayed(const Duration(milliseconds: 500));
  
  final authService = ref.watch(authServiceProvider);
  try {
    return await authService.getCurrentUserProfile();
  } catch (e) {
    // If user not found in backend (404), auto-register them
    // This handles returning users whose backend record may be missing
    try {
      return await authService.registerInBackend();
    } catch (_) {
      return null;
    }
  }
});

/// Auth Controller
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;
  
  AuthController(this._authService) : super(const AsyncValue.data(null));
  
  /// Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  /// Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      await _authService.signIn(email: email, password: password);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  /// Reset password
  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    
    try {
      await _authService.resetPassword(email);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Auth controller provider
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthController(authService);
});
