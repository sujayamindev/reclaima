// coverage:ignore-file
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/claim_service.dart';
import '../core/utils/logger.dart';
import 'service_providers.dart';

part 'claims_provider.g.dart';

/// State class for claims
class ClaimsState {
  final List<ClaimDocumentResponse> claims;
  final bool isLoading;
  final String? error;

  const ClaimsState({
    this.claims = const [],
    this.isLoading = false,
    this.error,
  });

  ClaimsState copyWith({
    List<ClaimDocumentResponse>? claims,
    bool? isLoading,
    String? error,
  }) {
    return ClaimsState(
      claims: claims ?? this.claims,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing claims for a specific receipt
@riverpod
class Claims extends _$Claims {
  @override
  ClaimsState build(String receiptId) {
    Future.microtask(loadClaims);
    return const ClaimsState();
  }

  /// Load all claims for the receipt — offline first.
  Future<void> loadClaims() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      logger.i('Loading claims for receipt $receiptId');
      final claims = await ref
          .read(claimRepositoryProvider)
          .getClaims(receiptId: receiptId);
      state = state.copyWith(claims: claims, isLoading: false);
      logger.i('Loaded ${claims.length} claims');
    } catch (e) {
      logger.e('Error loading claims: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Update a claim's status or notes
  Future<void> updateClaim(
    String claimId, {
    String? status,
    String? notes,
  }) async {
    try {
      logger.i('Updating claim $claimId');
      final updatedClaim = await ref
          .read(claimRepositoryProvider)
          .updateClaim(claimId, status: status, notes: notes);

      final updatedClaims = state.claims.map((claim) {
        return claim.id == claimId ? updatedClaim : claim;
      }).toList();

      state = state.copyWith(claims: updatedClaims);
      logger.i('Claim updated successfully');
    } catch (e) {
      logger.e('Error updating claim: $e');
      rethrow;
    }
  }

  /// Delete a claim
  Future<void> deleteClaim(String claimId) async {
    try {
      logger.i('Deleting claim $claimId');
      await ref.read(claimRepositoryProvider).deleteClaim(claimId);

      final updatedClaims = state.claims
          .where((claim) => claim.id != claimId)
          .toList();
      state = state.copyWith(claims: updatedClaims);
      logger.i('Claim deleted successfully');
    } catch (e) {
      logger.e('Error deleting claim: $e');
      rethrow;
    }
  }

  /// Resolve a claim with an outcome
  Future<void> resolveClaim(
    String claimId,
    String outcome, {
    String? linkedItemId,
    bool? duplicateDetails,
  }) async {
    try {
      logger.i('Resolving claim $claimId with outcome $outcome');
      final updatedClaim = await ref
          .read(claimRepositoryProvider)
          .resolveClaim(
            claimId,
            outcome,
            linkedItemId: linkedItemId,
            duplicateDetails: duplicateDetails,
          );

      final updatedClaims = state.claims.map((claim) {
        return claim.id == claimId ? updatedClaim : claim;
      }).toList();

      state = state.copyWith(claims: updatedClaims);
      logger.i('Claim resolved successfully');
    } catch (e) {
      logger.e('Error resolving claim: $e');
      rethrow;
    }
  }
}

/// Provider for getting a single claim by ID — offline first via repository.
final claimProvider = FutureProvider.family<ClaimDocumentResponse, String>((
  ref,
  claimId,
) async {
  final repository = ref.watch(claimRepositoryProvider);
  return repository.getClaim(claimId);
});

/// Provider for counting claims for a receipt (useful for badges)
final claimsCountProvider = Provider.family<int, String>((ref, receiptId) {
  final claimsState = ref.watch(claimsProvider(receiptId));
  return claimsState.claims.length;
});
