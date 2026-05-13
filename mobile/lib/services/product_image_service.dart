// coverage:ignore-file
import 'package:dio/dio.dart';
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
      final response = await _apiService.get(
        ApiConstants.productImageSearch,
        queryParameters: {'query': productName.trim()},
        // Accept any non-5xx status so 422/404 from the image-search
        // endpoint don't throw — they mean "no image found", not an error.
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode != 200) return null;

      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('imageUrl')) {
        final url = data['imageUrl'] as String?;
        if (url != null && url.isNotEmpty) {
          logger.i('Product image found for "$productName"');
          return url;
        }
      }

      return null;
    } catch (e) {
      logger.w('Product image lookup failed for "$productName": $e');
      return null;
    }
  }
}
