// coverage:ignore-file
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/claim_service.dart';
import 'auth_provider.dart';
import 'service_providers.dart';

/// User claims list provider — offline first.
///
/// Waits for [userProfileProvider] to resolve first so that the backend user
/// record is guaranteed to exist.
final userClaimsProvider = FutureProvider<List<ClaimDocumentResponse>>((
  ref,
) async {
  // Block until the user profile is confirmed.
  final profile = await ref.watch(userProfileProvider.future);
  if (profile == null) return [];

  final repository = ref.watch(claimRepositoryProvider);
  return repository.getClaims(forceRefresh: true);
});

/// Provider for tracking a pending replacement claim ID when the user chooses "Add New Receipt"
final pendingReplacementClaimIdProvider = StateProvider<String?>((ref) => null);
