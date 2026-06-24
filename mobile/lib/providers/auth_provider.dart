// coverage:ignore-file
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/user_model.dart';
import 'service_providers.dart';

part 'auth_provider.g.dart';

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
///
/// keepAlive so long-running async methods (deleteAccount, signOut) that
/// `ref.read` services across `await` points aren't disposed mid-flight when
/// the only caller `ref.read`s the notifier without watching it — disposal
/// would make the post-await `ref.read` throw "Ref ... already disposed".
@Riverpod(keepAlive: true)
class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(authServiceProvider)
          .signUp(email: email, password: password, fullName: fullName);
      // Guard: the auth-state stream can fire and unmount this provider before
      // the await returns (especially with a local emulator that responds in ms).
      if (ref.mounted) state = const AsyncValue.data(null);
    } catch (e, st) {
      if (ref.mounted) state = AsyncValue.error(e, st);
    }
  }

  /// Sign in with email and password
  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(authServiceProvider)
          .signIn(email: email, password: password);
      if (ref.mounted) state = const AsyncValue.data(null);
    } catch (e, st) {
      if (ref.mounted) state = AsyncValue.error(e, st);
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      if (ref.mounted) state = const AsyncValue.data(null);
    } catch (e, st) {
      if (ref.mounted) state = AsyncValue.error(e, st);
    }
  }

  /// Sign in with Apple
  Future<void> signInWithApple() async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authServiceProvider).signInWithApple();
      if (ref.mounted) state = const AsyncValue.data(null);
    } catch (e, st) {
      if (ref.mounted) state = AsyncValue.error(e, st);
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authServiceProvider).sendEmailVerification();
      if (ref.mounted) state = const AsyncValue.data(null);
    } catch (e, st) {
      if (ref.mounted) state = AsyncValue.error(e, st);
    }
  }

  /// Check if email is verified
  Future<bool> checkEmailVerified() async {
    return await ref.read(authServiceProvider).isEmailVerified();
  }

  /// Update current user profile
  Future<void> updateProfile({
    String? displayName,
    String? contactNumber,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(authServiceProvider)
          .updateProfile(
            displayName: displayName,
            contactNumber: contactNumber,
          );
      if (ref.mounted) state = const AsyncValue.data(null);
    } catch (e, st) {
      if (ref.mounted) state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Delete user account completely
  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    try {
      // Best effort deregister of FCM tokens before deletion
      try {
        await ref.read(notificationServiceProvider).deregisterToken();
      } catch (_) {
        // Ignore errors, we are deleting the account anyway
      }
      await ref.read(authServiceProvider).deleteAccount();
      // Clearing state and resetting happens via the authState stream yielding null,
      // but we set this manually just in case
      if (ref.mounted) state = const AsyncValue.data(null);
    } catch (e, st) {
      if (ref.mounted) state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Sign out — deregisters FCM token first so push stops immediately
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await ref.read(notificationServiceProvider).deregisterToken();
      await ref.read(authServiceProvider).signOut();
      if (ref.mounted) state = const AsyncValue.data(null);
    } catch (e, st) {
      if (ref.mounted) state = AsyncValue.error(e, st);
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(authServiceProvider)
          .changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
      if (ref.mounted) state = const AsyncValue.data(null);
    } catch (e, st) {
      if (ref.mounted) state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authServiceProvider).resetPassword(email);
      if (ref.mounted) state = const AsyncValue.data(null);
    } catch (e, st) {
      if (ref.mounted) state = AsyncValue.error(e, st);
    }
  }
}

/// Display name provider - resolves from backend profile, Firebase, or email
final displayNameProvider = Provider<String>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  final firebaseUser = ref.watch(currentUserProvider);

  return profileAsync.maybeWhen(
    data: (profile) {
      if (profile?.displayName != null && profile!.displayName!.isNotEmpty) {
        return profile.displayName!.split(' ').first;
      }
      if (firebaseUser?.displayName != null &&
          firebaseUser!.displayName!.isNotEmpty) {
        return firebaseUser.displayName!.split(' ').first;
      }
      final email = firebaseUser?.email ?? profile?.email ?? '';
      return email.isNotEmpty ? email.split('@').first : 'there';
    },
    orElse: () {
      if (firebaseUser?.displayName != null &&
          firebaseUser!.displayName!.isNotEmpty) {
        return firebaseUser.displayName!.split(' ').first;
      }
      final email = firebaseUser?.email ?? '';
      return email.isNotEmpty ? email.split('@').first : 'there';
    },
  );
});

/// Greeting provider - returns time-appropriate greeting
final greetingProvider = Provider<String>((_) {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning,';
  if (hour < 17) return 'Good afternoon,';
  return 'Good evening,';
});
