import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/product_view_model.dart';
import '../../providers/product_provider.dart';
import '../receipt/add_receipt_screen.dart';
import '../receipt/product_detail_screen.dart';

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

  // ── Products content ────────────────────────────────────────────
  Widget _buildContent(
    BuildContext context,
    Color cardColor,
    Color borderColor,
    Color textPrimaryColor,
    Color textSecondaryColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productsAsync = ref.watch(productsProvider);

    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
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
                    Icons.inventory_2_outlined,
                    size: 44,
                    color: textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'No products yet',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to scan your first receipt',
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
          onRefresh: () async => ref.invalidate(productsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _ProductCard(
                product: product,
                isDark: isDark,
                cardColor: cardColor,
                borderColor: borderColor,
                textPrimaryColor: textPrimaryColor,
                textSecondaryColor: textSecondaryColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(
                        receiptId: product.receiptId,
                        lineItemId: product.lineItemId,
                      ),
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
                'Error loading products',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyXSmall
                    .copyWith(color: textSecondaryColor),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => ref.invalidate(productsProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusPill),
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
    final productsAsync = ref.watch(productsProvider);

    final attentionCount = productsAsync.when(
      data: (products) =>
          products.where((p) => p.warrantyExpiresSoon).length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    final text = attentionCount > 0
        ? '$attentionCount ${attentionCount == 1 ? 'warranty expires' : 'warranties expire'} within 30 days.'
        : 'All your products and warranties are up to date.';

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

// ── Product card ──────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.isDark,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
    required this.onTap,
  });

  final ProductViewModel product;
  final bool isDark;
  final Color cardColor;
  final Color borderColor;
  final Color textPrimaryColor;
  final Color textSecondaryColor;
  final VoidCallback onTap;

  /// Deterministic avatar background color from the product name.
  Color get _avatarColor {
    const palette = [
      Color(0xFF12E28C), // primary
      Color(0xFF3B82F6), // info
      Color(0xFFF59E0B), // warning
      Color(0xFF8B5CF6), // purple
      Color(0xFFEC4899), // pink
      Color(0xFF14B8A6), // teal
    ];
    final code = product.displayName.isNotEmpty
        ? product.displayName.codeUnitAt(0)
        : 0;
    return palette[code % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = product.isPending ? AppColors.warning : _avatarColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // ── Avatar ──────────────────────────────────────────────
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: avatarColor.withValues(alpha: 0.14),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Center(
                    child: product.isPending
                        ? Icon(Icons.sync,
                            size: 22,
                            color: AppColors.warning.withValues(alpha: 0.9))
                        : Text(
                            product.displayName.isNotEmpty
                                ? product.displayName[0].toUpperCase()
                                : '?',
                            style: AppTextStyles.listTitle.copyWith(
                              fontSize: 18,
                              color: avatarColor,
                              height: 1.0,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),

                // ── Info ────────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.displayName,
                        style: AppTextStyles.listTitle.copyWith(
                          fontSize: 15,
                          color: textPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        product.isPending
                            ? 'Processing…'
                            : _buildSubtitle(),
                        style: AppTextStyles.caption.copyWith(
                          color: textSecondaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      _buildWarrantyChip(),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // ── Amount + chevron ────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (product.itemAmount != null)
                      Text(
                        CurrencyFormatter.format(
                          product.itemAmount!,
                          currency: product.currency ?? 'USD',
                        ),
                        style: AppTextStyles.listTitle.copyWith(
                          fontSize: 14,
                          color: textPrimaryColor,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Icon(Icons.chevron_right,
                        color: textSecondaryColor, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (product.receipt.storeName != null) {
      parts.add(product.receipt.storeName!);
    }
    if (product.receipt.purchaseDate != null) {
      parts.add(DateFormatter.formatDate(product.receipt.purchaseDate!));
    }
    return parts.join(' · ');
  }

  Widget _buildWarrantyChip() {
    if (product.isPending) return const SizedBox.shrink();

    if (!product.hasWarranty) {
      return const SizedBox.shrink();
    }

    final isExpired = product.isWarrantyExpired;
    final days = product.warrantyDaysRemaining;
    final expiresSoon =
        !isExpired && days != null && days <= 30;

    Color chipColor;
    String chipText;
    IconData chipIcon;

    if (isExpired) {
      chipColor = AppColors.error;
      chipText = 'Warranty expired';
      chipIcon = Icons.shield_outlined;
    } else if (expiresSoon) {
      chipColor = AppColors.warning;
      chipText = '$days days left';
      chipIcon = Icons.shield_outlined;
    } else {
      chipColor = AppColors.success;
      chipText = '$days days left';
      chipIcon = Icons.shield_outlined;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Icon(chipIcon, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Text(
            chipText,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }
}
