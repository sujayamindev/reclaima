import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/claim_service.dart';
import '../core/utils/logger.dart';

/// Provider for managing claim documents
///
/// Provides reactive state management for claims including:
/// - Fetching claims by receipt
/// - Getting individual claims
/// - Managing claim updates
/// - Deleting claims

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
class ClaimsNotifier extends StateNotifier<ClaimsState> {
  final ClaimService _claimService;
  final String receiptId;

  ClaimsNotifier(this._claimService, this.receiptId)
    : super(const ClaimsState()) {
    loadClaims();
  }

  /// Load all claims for the receipt
  Future<void> loadClaims() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      logger.i('Loading claims for receipt $receiptId');
      final claims = await _claimService.getClaims(receiptId: receiptId);
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
      final updatedClaim = await _claimService.updateClaim(
        claimId,
        status: status,
        notes: notes,
      );

      // Update the claim in the list
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
      await _claimService.deleteClaim(claimId);

      // Remove the claim from the list
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
      final updatedClaim = await _claimService.resolveClaim(
        claimId,
        outcome,
        linkedItemId: linkedItemId,
        duplicateDetails: duplicateDetails,
      );

      // Update the claim in the list
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

/// Provider family for claims by receipt ID
final claimsProvider =
    StateNotifierProvider.family<ClaimsNotifier, ClaimsState, String>((
      ref,
      receiptId,
    ) {
      final claimService = ref.watch(claimServiceProvider);
      return ClaimsNotifier(claimService, receiptId);
    });

/// Provider for getting a single claim by ID
final claimProvider = FutureProvider.family<ClaimDocumentResponse, String>((
  ref,
  claimId,
) async {
  final claimService = ref.watch(claimServiceProvider);
  return claimService.getClaim(claimId);
});

/// Provider for counting claims for a receipt (useful for badges)
final claimsCountProvider = Provider.family<int, String>((ref, receiptId) {
  final claimsState = ref.watch(claimsProvider(receiptId));
  return claimsState.claims.length;
});
