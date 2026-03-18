import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/logger.dart';
import 'api_service.dart';
import '../providers/service_providers.dart';

/// Response model for claim document operations
class ClaimDocumentResponse {
  final String id;
  final String receiptId;
  final String issueDescription;
  final String? claimType;
  final String? generatedPdfS3Key;
  final String? url; // Pre-signed S3 URL for downloading
  final DateTime createdAt;
  final DateTime updatedAt;

  ClaimDocumentResponse({
    required this.id,
    required this.receiptId,
    required this.issueDescription,
    this.claimType,
    this.generatedPdfS3Key,
    this.url,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClaimDocumentResponse.fromJson(Map<String, dynamic> json) {
    return ClaimDocumentResponse(
      id: json['id'] as String,
      receiptId: json['receiptId'] ?? json['receipt_id'] as String,
      issueDescription: json['issueDescription'] ?? json['issue_description'] as String,
      claimType: json['claimType'] ?? json['claim_type'] as String?,
      generatedPdfS3Key: json['generatedPdfS3Key'] ?? json['generated_pdf_s3_key'] as String?,
      url: json['url'] as String?,
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'receiptId': receiptId,
    'issueDescription': issueDescription,
    'claimType': claimType,
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
  ///   receipted: Receipt ID for which to generate the claim
  ///   issueDescription: Description of the issue/claim
  ///   claimType: Type of claim (warranty, return, repair)
  ///
  /// Returns:
  ///   ClaimDocumentResponse with claim details and download URL
  ///
  /// Throws:
  ///   Exception if generation fails
  Future<ClaimDocumentResponse> generateClaimPdf({
    required String receiptId,
    required String issueDescription,
    required String claimType,
  }) async {
    try {
      logger.i('Generating claim PDF for receipt $receiptId');

      final response = await _apiService.post(
        '/claims',
        data: {
          'receiptId': receiptId,
          'issueDescription': issueDescription,
          'claimType': claimType,
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

  /// Get all claims for a specific receipt
  ///
  /// Args:
  ///   receiptId: Receipt ID to filter claims by
  ///
  /// Returns:
  ///   List of ClaimDocumentResponse objects
  ///
  /// Throws:
  ///   Exception if retrieval fails
  Future<List<ClaimDocumentResponse>> getClaimsForReceipt(String receiptId) async {
    try {
      logger.i('Fetching claims for receipt $receiptId');

      final response = await _apiService.get(
        '/claims',
        queryParameters: {'receiptId': receiptId},
      );

      if (response.statusCode == 200) {
        final data = response.data as List;
        logger.i('Retrieved ${data.length} claims for receipt $receiptId');
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
  ///   ClaimDocumentResponse with claim details and download URL
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
}

/// Provider for ClaimService
final claimServiceProvider = Provider<ClaimService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ClaimService(apiService);
});
