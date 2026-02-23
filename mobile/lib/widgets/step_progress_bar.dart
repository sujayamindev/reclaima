import 'package:flutter/material.dart';

class StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isDark;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF12E28C);
    final inactiveColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final inactiveTextColor =
        isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 1; i <= totalSteps; i++) ...[
          _buildDot(i, primaryGreen, inactiveColor, inactiveTextColor),
          if (i < totalSteps) _buildLine(i, primaryGreen, inactiveColor),
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
            ? const Icon(Icons.check, size: 14, color: Color(0xFF0F172A))
            : Text(
                '$step',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive
                      ? const Color(0xFF0F172A)
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
