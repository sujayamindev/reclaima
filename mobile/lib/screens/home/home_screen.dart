import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/receipt_provider.dart';
import '../receipt/receipt_detail_screen.dart';
import '../receipt/add_receipt_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = AppColors.background(isDark);
    final textPrimaryColor = AppColors.textPrimary(isDark);
    final textSecondaryColor = AppColors.textSecondary(isDark);
    final cardColor = AppColors.card(isDark);
    final borderColor = AppColors.border(isDark);
    final navBarColor = AppColors.navBar(isDark);

    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddReceiptScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recepta.',
                    style: AppTextStyles.appName.copyWith(
                      color: textPrimaryColor,
                    ),
                  ),
                  Row(
                    children: [
                      // Search button
                      _CircleIconButton(
                        icon: Icons.search,
                        iconColor: textSecondaryColor,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        onPressed: () {},
                      ),
                      const SizedBox(width: 10),
                      // Notification button with badge
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _CircleIconButton(
                            icon: Icons.notifications_outlined,
                            iconColor: textSecondaryColor,
                            cardColor: cardColor,
                            borderColor: borderColor,
                            onPressed: () {},
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Hero text ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: AppTextStyles.headingLarge.copyWith(
                        color: textPrimaryColor,
                      ),
                      children: [
                        const TextSpan(text: 'Focus on what '),
                        const TextSpan(
                          text: 'matters',
                          style: TextStyle(color: AppColors.primary),
                        ),
                        TextSpan(
                          text: '.',
                          style: TextStyle(color: textPrimaryColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  _AttentionSubtitle(textSecondaryColor: textSecondaryColor),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Content ───────────────────────────────────────────
            Expanded(
              child: _buildContent(
                context,
                cardColor,
                borderColor,
                textPrimaryColor,
                textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
      // ── Bottom nav pill ───────────────────────────────────────
      bottomNavigationBar: _buildBottomNav(
        navBarColor,
        textSecondaryColor,
      ),
    );
  }

  // ── Receipts content ────────────────────────────────────────────
  Widget _buildContent(
    BuildContext context,
    Color cardColor,
    Color borderColor,
    Color textPrimaryColor,
    Color textSecondaryColor,
  ) {
    final receiptsAsync = ref.watch(receiptsProvider);

    return receiptsAsync.when(
      data: (receipts) {
        if (receipts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: cardColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    size: 44,
                    color: textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'No receipts yet',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to add your first receipt',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: textSecondaryColor,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.invalidate(receiptsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            itemCount: receipts.length,
            itemBuilder: (context, index) {
              final receipt = receipts[index];
              return _ReceiptCard(
                receipt: receipt,
                cardColor: cardColor,
                borderColor: borderColor,
                textPrimaryColor: textPrimaryColor,
                textSecondaryColor: textSecondaryColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ReceiptDetailScreen(receiptId: receipt.id),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Error loading receipts',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyXSmall.copyWith(color: textSecondaryColor),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => ref.invalidate(receiptsProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom nav pill ─────────────────────────────────────────
  Widget _buildBottomNav(
    Color navBarColor,
    Color inactiveColor,
  ) {
    const items = [
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.receipt_long_outlined, label: 'Receipts'),
      (icon: Icons.shield_outlined, label: 'Warranty'),
      (icon: Icons.settings_outlined, label: 'Settings'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Container(
        height: AppDimensions.navBarHeight,
        decoration: BoxDecoration(
          color: navBarColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusNavBar),
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final isActive = _selectedIndex == index;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _selectedIndex = index),
                child: Icon(
                  items[index].icon,
                  size: 24,
                  color: isActive ? AppColors.primary : inactiveColor,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── Attention subtitle (dynamic count) ────────────────────────────
class _AttentionSubtitle extends ConsumerWidget {
  const _AttentionSubtitle({required this.textSecondaryColor});
  final Color textSecondaryColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = ref.watch(receiptsProvider);

    final attentionCount = receiptsAsync.when(
      data: (receipts) => receipts.where((r) {
        final days = r.warrantyDaysRemaining;
        return days != null && days <= 30 && !(r.isWarrantyExpired);
      }).length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    final text = attentionCount > 0
        ? '$attentionCount ${attentionCount == 1 ? 'warranty expires' : 'warranties expire'} within 30 days.'
        : 'All your receipts and warranties are up to date.';

    return Text(
      text,
      style: AppTextStyles.bodyMedium.copyWith(
        fontSize: 15,
        color: textSecondaryColor,
        height: 1.4,
      ),
    );
  }
}

// ── Circular icon button ───────────────────────────────────────────
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.iconColor,
    required this.cardColor,
    required this.borderColor,
    required this.onPressed,
  });

  final IconData icon;
  final Color iconColor;
  final Color cardColor;
  final Color borderColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimensions.circleButtonSize,
      height: AppDimensions.circleButtonSize,
      decoration: BoxDecoration(
        color: cardColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Icon(icon, size: 22, color: iconColor),
        ),
      ),
    );
  }
}

// ── Receipt card ──────────────────────────────────────────────────
class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({
    required this.receipt,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
    required this.onTap,
  });

  final dynamic receipt;
  final Color cardColor;
  final Color borderColor;
  final Color textPrimaryColor;
  final Color textSecondaryColor;
  final VoidCallback onTap;

  Color get _statusColor {
    switch (receipt.status.toString()) {
      case 'ReceiptStatus.completed':
        return AppColors.primary;
      case 'ReceiptStatus.processing':
        return AppColors.warning;
      case 'ReceiptStatus.ocrFailed':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  IconData get _statusIcon {
    switch (receipt.status.toString()) {
      case 'ReceiptStatus.completed':
        return Icons.check_circle_outline;
      case 'ReceiptStatus.processing':
        return Icons.sync;
      case 'ReceiptStatus.ocrFailed':
        return Icons.error_outline;
      default:
        return Icons.receipt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Status indicator
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Icon(_statusIcon, color: _statusColor, size: 22),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receipt.storeName ?? 'Unknown Store',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: textPrimaryColor,
                        ),
                      ),
                      if (receipt.productName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          receipt.productName!,
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (receipt.warrantyExpiryDate != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 12,
                              color: receipt.isWarrantyExpired
                                  ? AppColors.error
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              receipt.isWarrantyExpired
                                  ? 'Warranty expired'
                                  : '${receipt.warrantyDaysRemaining} days left',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: receipt.isWarrantyExpired
                                    ? AppColors.error
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Amount + chevron
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (receipt.totalAmount != null)
                      Text(
                        '${receipt.currency ?? 'USD'} ${receipt.totalAmount!.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: textPrimaryColor,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.chevron_right,
                      color: textSecondaryColor,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
