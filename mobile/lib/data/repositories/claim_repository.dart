// coverage:ignore-file
import 'dart:io';

import 'package:drift/drift.dart';
import '../../services/claim_service.dart';
import '../database/app_database.dart';

/// Repository that coordinates between local SQLite (Drift) and the remote claims API.
///
/// Offline-first strategy:
///   - Reads: serve local cache immediately, background-sync with remote.
///   - Writes: always hit remote first, then persist the result locally.
///   - Deletes: remove from remote, then remove from local.
///   - Pre-signed PDF URLs are never cached — they are ephemeral.
class ClaimRepository {
  final ClaimService _remoteService;
  final AppDatabase _localDb;

  ClaimRepository(this._remoteService, this._localDb);

  /// Get claims — offline first.
  ///
  /// Returns local cache immediately. If cache is empty or [forceRefresh] is
  /// true, fetches from remote (falling back to stale local data on error).
  /// Otherwise kicks off a background sync so the cache stays fresh.
  Future<List<ClaimDocumentResponse>> getClaims({
    String? receiptId,
    String? lineItemId,
    bool forceRefresh = false,
  }) async {
    final rows = await _localDb.getClaims(
      receiptId: receiptId,
      lineItemId: lineItemId,
    );
    final local = await Future.wait(rows.map(_rowToResponse));

    if (local.isEmpty || forceRefresh) {
      try {
        return await syncClaims(receiptId: receiptId, lineItemId: lineItemId);
      } catch (_) {
        return local;
      }
    }

    _syncInBackground(receiptId: receiptId, lineItemId: lineItemId);
    return local;
  }

  /// Get a single claim — local first.
  ///
  /// Returns the cached row if present; otherwise fetches from remote and caches it.
  Future<ClaimDocumentResponse> getClaim(String claimId) async {
    final row = await _localDb.getClaimById(claimId);
    if (row != null) {
      return _rowToResponse(row);
    }
    final remote = await _remoteService.getClaim(claimId);
    await _saveOne(remote);
    return remote;
  }

  /// Fetch claims from remote and persist them locally.
  Future<List<ClaimDocumentResponse>> syncClaims({
    String? receiptId,
    String? lineItemId,
  }) async {
    final remote = await _remoteService.getClaims(
      receiptId: receiptId,
      lineItemId: lineItemId,
    );
    for (final c in remote) {
      await _saveOne(c);
    }
    return remote;
  }

  /// Generate a claim PDF — calls remote, then caches the result.
  Future<ClaimDocumentResponse> generateClaimPdf({
    required String receiptId,
    required String issueDescription,
    required String claimType,
    String? lineItemId,
    List<File>? defectImages,
  }) async {
    final result = await _remoteService.generateClaimPdf(
      receiptId: receiptId,
      issueDescription: issueDescription,
      claimType: claimType,
      lineItemId: lineItemId,
      defectImages: defectImages,
    );
    await _saveOne(result);
    return result;
  }

  /// Update a claim — calls remote, then updates the local cache.
  Future<ClaimDocumentResponse> updateClaim(
    String claimId, {
    String? status,
    String? notes,
  }) async {
    final result = await _remoteService.updateClaim(
      claimId,
      status: status,
      notes: notes,
    );
    await _saveOne(result);
    return result;
  }

  /// Delete a claim — removes from remote, then from local cache.
  Future<void> deleteClaim(String claimId) async {
    await _remoteService.deleteClaim(claimId);
    await _localDb.deleteClaimById(claimId);
  }

  /// Resolve a claim — calls remote, then updates the local cache.
  Future<ClaimDocumentResponse> resolveClaim(
    String claimId,
    String outcome, {
    String? linkedItemId,
    bool? duplicateDetails,
  }) async {
    final result = await _remoteService.resolveClaim(
      claimId,
      outcome,
      linkedItemId: linkedItemId,
      duplicateDetails: duplicateDetails,
    );
    await _saveOne(result);
    return result;
  }

  /// Access the claim PDF pre-signed URL — always hits remote (URL is ephemeral).
  ///
  /// Caches the updated claim metadata (status, s3 key) but NOT the URL itself.
  /// The returned response includes [url] for immediate use in the current session.
  Future<ClaimDocumentResponse> accessClaimPdf(String claimId) async {
    final result = await _remoteService.accessClaimPdf(claimId);
    await _saveOne(result);
    return result;
  }

  Future<void> _syncInBackground({
    String? receiptId,
    String? lineItemId,
  }) async {
    try {
      await syncClaims(receiptId: receiptId, lineItemId: lineItemId);
    } catch (_) {}
  }

  Future<void> _saveOne(ClaimDocumentResponse r) async {
    await _localDb.upsertClaimWithImages(
      _toCompanion(r),
      _imagesToCompanions(r),
    );
  }

  ClaimDocumentsCompanion _toCompanion(ClaimDocumentResponse r) {
    return ClaimDocumentsCompanion(
      id: Value(r.id),
      receiptId: Value(r.receiptId),
      lineItemId: Value(r.lineItemId),
      issueDescription: Value(r.issueDescription),
      claimType: Value(r.claimType),
      status: Value(r.status),
      notes: Value(r.notes),
      generatedPdfS3Key: Value(r.generatedPdfS3Key),
      createdAt: Value(r.createdAt),
      updatedAt: Value(r.updatedAt),
      syncedAt: Value(DateTime.now()),
    );
  }

  List<ClaimDefectImagesCompanion> _imagesToCompanions(
    ClaimDocumentResponse r,
  ) {
    return r.defectImages
        .map(
          (img) => ClaimDefectImagesCompanion(
            id: Value(img.id),
            claimId: Value(r.id),
            s3ObjectKey: Value(img.s3ObjectKey),
            displayOrder: Value(img.displayOrder),
            createdAt: Value(img.createdAt),
          ),
        )
        .toList();
  }

  Future<ClaimDocumentResponse> _rowToResponse(ClaimDocument row) async {
    final images = await _localDb.getDefectImagesForClaim(row.id);
    return ClaimDocumentResponse(
      id: row.id,
      receiptId: row.receiptId,
      lineItemId: row.lineItemId,
      issueDescription: row.issueDescription,
      claimType: row.claimType,
      status: row.status,
      notes: row.notes,
      generatedPdfS3Key: row.generatedPdfS3Key,
      url:
          null, // Pre-signed URLs are ephemeral; use accessClaimPdf() to fetch one
      defectImages: images
          .map(
            (i) => ClaimDefectImageResponse(
              id: i.id,
              s3ObjectKey: i.s3ObjectKey,
              displayOrder: i.displayOrder,
              createdAt: i.createdAt,
            ),
          )
          .toList(),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
