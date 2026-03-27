import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/constants/app_constants.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Placeholder card shown when there are no immediate action items
/// Matches the attention card design for consistency
class AllClearPlaceholder extends StatelessWidget {
  const AllClearPlaceholder({
    super.key,
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);
    final primary = AppColors.primary;

    return Container(
      height: 160,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Text content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppDimensions.paddingCardSmall+12, AppDimensions.paddingCardSmall, AppDimensions.paddingCardSmall, AppDimensions.paddingCardSmall),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Nothing Here Yet!',
                    style: AppTextStyles.listTitle.copyWith(
                      color: textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Nothing at the moment. Add receipts to start tracking!',
                    style: AppTextStyles.bodyXSmall.copyWith(
                      color: textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          // Character icon section (matching the image area width)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              0,
              AppDimensions.paddingCardSmall,
              AppDimensions.paddingCardSmall,
              AppDimensions.paddingCardSmall,
            ),
            child: SizedBox(
              width: 100,
              child: Center(
                child: Icon(Symbols.contextual_token_add_rounded, size: 64, color: primary, weight: AppDimensions.iconWeightNormal),)
              ),
            ),
        ],
      ),
    );
  }
}
