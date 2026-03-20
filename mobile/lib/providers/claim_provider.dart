import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/claim_service.dart';
import 'auth_provider.dart';

/// User claims list provider
///
/// Waits for [userProfileProvider] to resolve first so that the backend user
/// record is guaranteed to exist.
final userClaimsProvider = FutureProvider<List<ClaimDocumentResponse>>((ref) async {
  // Block until the user profile is confirmed (or confirmed absent).
  await ref.watch(userProfileProvider.future);

  final claimService = ref.watch(claimServiceProvider);
  return await claimService.getClaims();
});

/// Provider for tracking a pending replacement claim ID when the user chooses "Add New Receipt"
final pendingReplacementClaimIdProvider = StateProvider<String?>((ref) => null);
