import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/constants/app_constants.dart';

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
                    'All Clear!',
                    style: AppTextStyles.listTitle.copyWith(
                      color: textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'No immediate action items at the moment. You\'re all caught up!',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: textSecondary,
                      fontSize: 13,
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
                child: SvgPicture.asset(
                  'assets/images/all_clear_symbol.svg',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
