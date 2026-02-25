import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const activeColor = AppColors.primary;
    final inactiveColor = AppColors.border(isDark);
    final inactiveTextColor = AppColors.muted(isDark);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 1; i <= totalSteps; i++) ...[
          _buildDot(i, activeColor, inactiveColor, inactiveTextColor),
          if (i < totalSteps) _buildLine(i, activeColor, inactiveColor),
        ],
      ],
    );
  }

  Widget _buildDot(
    int step,
    Color activeColor,
    Color inactiveColor,
    Color inactiveTextColor,
  ) {
    final isActive = step == currentStep;
    final isCompleted = step < currentStep;
    final filled = isActive || isCompleted;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? activeColor : Colors.transparent,
        border: Border.all(
          color: filled ? activeColor : inactiveColor,
          width: 2,
        ),
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, size: 14, color: AppColors.onPrimary)
            : Text(
                '$step',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive
                      ? AppColors.onPrimary
                      : inactiveTextColor,
                ),
              ),
      ),
    );
  }

  Widget _buildLine(int step, Color activeColor, Color inactiveColor) {
    final isCompleted = step < currentStep;
    return Expanded(
      child: Container(
        height: 2,
        decoration: BoxDecoration(
          color: isCompleted ? activeColor : inactiveColor,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
