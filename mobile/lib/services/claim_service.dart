import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/logger.dart';
import 'api_service.dart';
import '../providers/service_providers.dart';

/// Response model for claim document operations
class ClaimDocumentResponse {
  final String id;
  final String receiptId;
  final String? lineItemId;
  final String issueDescription;
  final String? claimType;
  final String status;
  final String? notes;
  final String? generatedPdfS3Key;
  final String? url; // Pre-signed S3 URL for downloading
  final DateTime createdAt;
  final DateTime updatedAt;

  ClaimDocumentResponse({
    required this.id,
    required this.receiptId,
    this.lineItemId,
    required this.issueDescription,
    this.claimType,
    required this.status,
    this.notes,
    this.generatedPdfS3Key,
    this.url,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClaimDocumentResponse.fromJson(Map<String, dynamic> json) {
    return ClaimDocumentResponse(
      id: json['id'] as String,
      receiptId: json['receiptId'] ?? json['receipt_id'] as String,
      lineItemId: json['lineItemId'] ?? json['line_item_id'] as String?,
      issueDescription: json['issueDescription'] ?? json['issue_description'] as String,
      claimType: json['claimType'] ?? json['claim_type'] as String?,
      status: json['status'] as String? ?? 'SUBMITTED',
      notes: json['notes'] as String?,
      generatedPdfS3Key: json['generatedPdfS3Key'] ?? json['generated_pdf_s3_key'] as String?,
      url: json['url'] as String?,
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'receiptId': receiptId,
    'lineItemId': lineItemId,
    'issueDescription': issueDescription,
    'claimType': claimType,
    'status': status,
    'notes': notes,
    'generatedPdfS3Key': generatedPdfS3Key,
    'url': url,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

/// Service for managing warranty claim PDFs
class ClaimService {
  final ApiService _apiService;

  ClaimService(this._apiService);

  /// Generate a warranty claim PDF for a receipt
  ///
  /// Args:
  ///   receiptId: Receipt ID for which to generate the claim
  ///   issueDescription: Description of the issue/claim
  ///   claimType: Type of claim (warranty, return)
  ///   lineItemId: Optional line item ID (product) for which to generate the claim
  ///
  /// Returns:
  ///   ClaimDocumentResponse with claim metadata.
  ///   Use [accessClaimPdf] when the user explicitly wants to open/download/share/copy the PDF.
  ///
  /// Throws:
  ///   Exception if generation fails
  Future<ClaimDocumentResponse> generateClaimPdf({
    required String receiptId,
    required String issueDescription,
    required String claimType,
    String? lineItemId,
  }) async {
    try {
      logger.i('Generating claim PDF for receipt $receiptId, product ${lineItemId ?? "all"}');

      final response = await _apiService.post(
        '/claims',
        data: {
          'receiptId': receiptId,
          'issueDescription': issueDescription,
          'claimType': claimType,
          if (lineItemId != null) 'lineItemId': lineItemId,
        },
      );

      if (response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        logger.i('Claim PDF generated successfully: ${data['id']}');
        return ClaimDocumentResponse.fromJson(data);
      } else {
        throw Exception('Failed to generate claim PDF: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error generating claim PDF: $e');
      rethrow;
    }
  }

  /// Get all claims (optionally filtered by receipt or line item)
  ///
  /// Args:
  ///   receiptId: Optional receipt ID to filter claims by
  ///   lineItemId: Optional line item ID (product) to filter claims by - takes precedence
  ///
  /// Returns:
  ///   List of ClaimDocumentResponse objects
  ///
  /// Throws:
  ///   Exception if retrieval fails
  Future<List<ClaimDocumentResponse>> getClaims({String? receiptId, String? lineItemId}) async {
    try {
      if (lineItemId != null) {
        logger.i('Fetching claims for product $lineItemId');
      } else if (receiptId != null) {
        logger.i('Fetching claims for receipt $receiptId');
      } else {
        logger.i('Fetching all claims');
      }

      final queryParams = <String, dynamic>{};
      if (lineItemId != null) {
        queryParams['line_item_id'] = lineItemId;
      } else if (receiptId != null) {
        queryParams['receipt_id'] = receiptId;
      }

      final response = await _apiService.get(
        '/claims',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        final data = response.data as List;
        logger.i('Retrieved ${data.length} claims');
        return data
            .map((json) => ClaimDocumentResponse.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to retrieve claims: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error retrieving claims: $e');
      rethrow;
    }
  }

  /// Get a specific claim document
  ///
  /// Args:
  ///   claimId: Claim ID to retrieve
  ///
  /// Returns:
  ///   ClaimDocumentResponse with claim metadata.
  ///   Use [accessClaimPdf] when the user explicitly wants to open/download/share/copy the PDF.
  ///
  /// Throws:
  ///   Exception if retrieval fails
  Future<ClaimDocumentResponse> getClaim(String claimId) async {
    try {
      logger.i('Fetching claim $claimId');

      final response = await _apiService.get('/claims/$claimId');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        logger.i('Retrieved claim $claimId');
        return ClaimDocumentResponse.fromJson(data);
      } else {
        throw Exception('Failed to retrieve claim: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error retrieving claim: $e');
      rethrow;
    }
  }

  /// Access claim PDF for user-initiated actions (open/download/share/copy).
  ///
  /// This endpoint is the only path that may regenerate a missing PDF.
  Future<ClaimDocumentResponse> accessClaimPdf(String claimId) async {
    try {
      logger.i('Accessing claim PDF for $claimId');

      final response = await _apiService.post('/claims/$claimId/pdf-access', data: {});

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        logger.i('Claim PDF access URL generated for $claimId');
        return ClaimDocumentResponse.fromJson(data);
      } else {
        throw Exception('Failed to access claim PDF: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error accessing claim PDF: $e');
      rethrow;
    }
  }

  /// Delete a claim document
  ///
  /// Args:
  ///   claimId: Claim ID to delete
  ///
  /// Throws:
  ///   Exception if deletion fails
  Future<void> deleteClaim(String claimId) async {
    try {
      logger.i('Deleting claim $claimId');

      final response = await _apiService.patch('/claims/$claimId', data: {});

      if (response.statusCode == 204 || response.statusCode == 200) {
        logger.i('Claim $claimId deleted');
      } else {
        throw Exception('Failed to delete claim: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error deleting claim: $e');
      rethrow;
    }
  }

  /// Resolve a warranty claim
  ///
  /// Args:
  ///   claimId: Claim ID
  ///   outcome: Resolution outcome (REFUNDED, REPAIRED, REPLACED)
  ///   linkedItemId: Optional item ID to link to the replacement
  ///   duplicateDetails: Whether to clone the original item as a replacement
  ///
  /// Returns:
  ///   Updated ClaimDocumentResponse object
  Future<ClaimDocumentResponse> resolveClaim(
    String claimId,
    String outcome, {
    String? linkedItemId,
    bool? duplicateDetails,
  }) async {
    try {
      logger.i('Resolving claim $claimId with outcome $outcome');
      
      final Map<String, dynamic> data = {
        'outcome': outcome,
      };
      
      if (linkedItemId != null) {
        data['linkedItemId'] = linkedItemId;
      }
      if (duplicateDetails != null) {
        data['duplicateDetails'] = duplicateDetails;
      }

      final response = await _apiService.post(
        '/claims/$claimId/resolve',
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        logger.i('Claim resolved successfully');
        return ClaimDocumentResponse.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to resolve claim: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error resolving claim: $e');
      rethrow;
    }
  }

  /// Update an existing claim
  Future<ClaimDocumentResponse> updateClaim(String claimId, {String? status, String? notes}) async {
    try {
      logger.i('Updating claim $claimId');
      
      final data = <String, dynamic>{};
      if (status != null) data['status'] = status;
      if (notes != null) data['notes'] = notes;

      final response = await _apiService.patch(
        '/claims/$claimId',
        data: data,
      );

      if (response.statusCode == 200) {
        final respData = response.data as Map<String, dynamic>;
        logger.i('Claim updated successfully: $claimId');
        return ClaimDocumentResponse.fromJson(respData);
      } else {
        throw Exception('Failed to update claim: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error updating claim: $e');
      rethrow;
    }
  }
}

/// Provider for ClaimService
final claimServiceProvider = Provider<ClaimService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ClaimService(apiService);
});
