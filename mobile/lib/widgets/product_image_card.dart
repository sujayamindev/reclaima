import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../core/constants/app_constants.dart';

/// A card widget that displays a product image fetched from the internet.
///
/// Shows a shimmer placeholder while loading, a fallback icon on error,
/// and the product name beneath the image.
class ProductImageCard extends StatelessWidget {
  final String productName;
  final Future<String?> imageUrlFuture;
  final bool isDark;

  const ProductImageCard({
    super.key,
    required this.productName,
    required this.imageUrlFuture,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimary(isDark);
    final cardColor = AppColors.card(isDark);
    final borderColor = AppColors.border(isDark);
    final labelColor = AppColors.textSecondary(isDark);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Section header
          Row(
            children: [
              const Icon(
                Symbols.shopping_bag,
                size: AppDimensions.iconMedium,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Product Preview',
                style: AppTextStyles.sectionTitle.copyWith(color: textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Product image
          FutureBuilder<String?>(
            future: imageUrlFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildShimmerPlaceholder(cardColor, borderColor);
              }

              final imageUrl = snapshot.data;
              if (imageUrl == null || imageUrl.isEmpty) {
                return _buildFallbackIcon(labelColor);
              }

              return ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.contain,
                  placeholder: (context, url) =>
                      _buildShimmerPlaceholder(cardColor, borderColor),
                  errorWidget: (context, url, error) =>
                      _buildFallbackIcon(labelColor),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Pulsing shimmer placeholder while the image loads.
  Widget _buildShimmerPlaceholder(Color cardColor, Color borderColor) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: borderColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      child: const Center(
        child: SizedBox(
          height: 28,
          width: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  /// Fallback icon when no image is available.
  Widget _buildFallbackIcon(Color labelColor) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.image_not_supported,
              size: AppDimensions.iconLarge,
              color: labelColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Image not available',
              style: TextStyle(
                fontSize: 12,
                color: labelColor.withValues(alpha: 0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
