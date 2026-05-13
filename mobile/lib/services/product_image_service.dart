// coverage:ignore-file
import '../core/utils/logger.dart';
import 'api_service.dart';
import '../core/constants/app_constants.dart';

/// Service for searching product images via backend proxy
class ProductImageService {
  final ApiService _apiService;

  ProductImageService(this._apiService);

  /// Search for a product image by product name.
  ///
  /// Returns the image URL string, or `null` if not found / error.
  Future<String?> getProductImageUrl(String productName) async {
    if (productName.trim().isEmpty) return null;

    try {
      final response = await _apiService.post(
        ApiConstants.productImageSearch,
        data: {'query': productName.trim()},
      );

      logger.d(
        'Image search response: status=${response.statusCode} data=${response.data}',
      );

      if (response.statusCode != 200) {
        logger.w(
          'Image search non-200 status ${response.statusCode} for "$productName"',
        );
        return null;
      }

      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('imageUrl')) {
        final url = data['imageUrl'] as String?;
        if (url != null && url.isNotEmpty) {
          logger.i('Product image found for "$productName": $url');
          return url;
        }
        logger.w(
          'Image search returned null/empty imageUrl for "$productName" (data: $data)',
        );
      } else {
        logger.w(
          'Image search unexpected response shape for "$productName": $data',
        );
      }

      return null;
    } catch (e) {
      logger.w('Product image lookup failed for "$productName": $e');
      return null;
    }
  }
}
