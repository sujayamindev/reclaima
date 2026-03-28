import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../../core/constants/app_constants.dart';
import '../receipt/add_receipt_screen.dart';
import '../../data/models/receipt_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/receipt_provider.dart';
import '../receipt/product_detail_screen.dart';
import '../receipt/claim_detail_screen.dart';
import '../receipt/claims_list_screen.dart';
import '../../services/claim_service.dart';
import '../../providers/claim_provider.dart';
import '../../widgets/all_clear_placeholder.dart';

// ── Attention item ─────────────────────────────────────────────────────────────

class _AttentionItem {
  final String receiptId;
  final String? lineItemId;
  final String productName;
  final String? storeName;
  final String? productImageUrl;
  final int daysRemaining;

  /// true = return window expiring, false = warranty expiring
  final bool isReturn;
  final bool isClaim;
  final String? claimStatus;
  final String? claimId;

  const _AttentionItem({
    required this.receiptId,
    required this.lineItemId,
    required this.productName,
    this.storeName,
    this.productImageUrl,
    required this.daysRemaining,
    required this.isReturn,
    this.isClaim = false,
    this.claimStatus,
    this.claimId,
  });
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const int _warrantyAlertDays = 90;
  static const int _returnAlertDays = 14;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
    });
  }

  Future<void> _requestPermissions() async {
    // Request notification and camera permissions on app load
    await [
      Permission.notification,
      Permission.camera,
      Permission
          .storage, // Storage is often needed along with camera for attachments
    ].request();
  }

  List<_AttentionItem> _buildAttentionItems(
    List<ReceiptModel> receipts,
    List<ClaimDocumentResponse> claims,
  ) {
    final alertItems = <_AttentionItem>[];
    final allUpcomingItems = <_AttentionItem>[];

    for (final receipt in receipts) {
      for (final item in receipt.lineItems) {
        if (item.status == 'ARCHIVED') continue;

        final returnDays = item.returnDaysRemaining;
        if (returnDays != null && !item.isReturnExpired) {
          final attentionItem = _AttentionItem(
            receiptId: receipt.id,
            lineItemId: item.id,
            productName: item.displayName,
            storeName: receipt.storeName,
            productImageUrl: item.productImageUrl,
            daysRemaining: returnDays,
            isReturn: true,
          );
          allUpcomingItems.add(attentionItem);
          
          if (returnDays <= _returnAlertDays) {
            alertItems.add(attentionItem);
          }
        }

        final warrantyDays = item.warrantyDaysRemaining;
        if (warrantyDays != null && !item.isWarrantyExpired) {
          final attentionItem = _AttentionItem(
            receiptId: receipt.id,
            lineItemId: item.id,
            productName: item.displayName,
            storeName: receipt.storeName,
            productImageUrl: item.productImageUrl,
            daysRemaining: warrantyDays,
            isReturn: false,
          );
          allUpcomingItems.add(attentionItem);
          
          if (warrantyDays <= _warrantyAlertDays) {
            alertItems.add(attentionItem);
          }
        }
      }
    }

    // Add claims that need attention
    for (final claim in claims) {
      final status = claim.status.toUpperCase();
      if (status != 'RESOLVED' && status != 'DENIED') {
        final receipt = receipts
            .where((r) => r.id == claim.receiptId)
            .firstOrNull;
        if (receipt != null) {
          // Find matching line item or fallback to the first one available
          final lineItem =
              (claim.lineItemId != null && claim.lineItemId!.isNotEmpty)
              ? (receipt.lineItems
                        .where((i) => i.id == claim.lineItemId)
                        .firstOrNull ??
                    receipt.lineItems.firstOrNull)
              : receipt.lineItems.firstOrNull;

          // Even if line item is archived, we still show the claim because it's active.
          alertItems.add(
            _AttentionItem(
              receiptId: receipt.id,
              lineItemId: lineItem?.id,
              productName:
                  lineItem?.displayName ??
                  receipt.productName ??
                  'Unknown Product',
              storeName: receipt.storeName,
              productImageUrl:
                  lineItem?.productImageUrl ?? receipt.productImageUrl,
              daysRemaining:
                  9999, // Lower priority than expiring returns/warranties
              isReturn: false,
              isClaim: true,
              claimStatus: claim.status,
              claimId: claim.id,
            ),
          );
        }
      }
    }

    // Determine final list of items to show
    List<_AttentionItem> finalItems;
    if (alertItems.isNotEmpty) {
      // Option 1: Show threshold-based items (and claims) if there's at least one
      finalItems = alertItems;
    } else {
      // Option 2: Fallback to the closest upcoming items across all receipts
      allUpcomingItems.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
      finalItems = allUpcomingItems.take(5).toList();
    }

    finalItems.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
    return finalItems;
  }

  void _goToDetail(_AttentionItem item) {
    if (item.isClaim && item.claimId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClaimDetailScreen(
            claimId: item.claimId!,
            receiptStoreName: item.storeName ?? 'Unknown Store',
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(
            receiptId: item.receiptId,
            lineItemId: item.lineItemId,
          ),
        ),
      );
    }
  }

  Future<void> _refreshHomeData() async {
    await Future.wait([
      ref.refresh(receiptsProvider.future),
      ref.refresh(userClaimsProvider.future),
    ]);
  }

  void _showProductSelector(List<ReceiptModel> receipts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProductSelectorSheet(receipts: receipts),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers that need to load data
    final receiptState = ref.watch(receiptsProvider);
    final claimState = ref.watch(userClaimsProvider);
    
    // Check if both data sets have loaded
    if (receiptState.hasValue && claimState.hasValue) {
      // Remove splash screen once the initial API calls are completed.
      // This is safe to call multiple times.
      FlutterNativeSplash.remove();
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greeting = ref.watch(greetingProvider);
    final userName = ref.watch(displayNameProvider);
    final receiptsAsync = ref.watch(receiptsProvider);
    final claimsAsync = ref.watch(userClaimsProvider);

    final bg = AppColors.background(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);
    final card = AppColors.card(isDark);
    final border = AppColors.border(isDark);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: RefreshIndicator(
                onRefresh: _refreshHomeData,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    // ── Top bar ──────────────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppDimensions.paddingPage,
                          20,
                          AppDimensions.paddingPage,
                          0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Receipta.',
                              style: AppTextStyles.appName.copyWith(
                                color: textPrimary,
                              ),
                            ),
                            Row(
                              children: [
                                _CircleIconButton(
                                  icon: Symbols.search_rounded,
                                  iconColor: textSecondary,
                                  cardColor: card,
                                  borderColor: border,
                                  onPressed: () {},
                                ),
                                const SizedBox(width: 10),
                                _CircleIconButton(
                                  icon: Symbols.notifications_rounded,
                                  iconColor: textSecondary,
                                  cardColor: card,
                                  borderColor: border,
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Greeting ─────────────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppDimensions.paddingPage,
                          24,
                          AppDimensions.paddingPage,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$userName 👋',
                              style: AppTextStyles.headingLarge.copyWith(
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Stats row ─────────────────────────────────────────────────
                    receiptsAsync.when(
                      data: (receipts) => SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppDimensions.paddingPage,
                            28,
                            AppDimensions.paddingPage,
                            0,
                          ),
                          child: _StatsRow(receipts: receipts, isDark: isDark),
                        ),
                      ),
                      loading: () =>
                          const SliverToBoxAdapter(child: SizedBox(height: 28)),
                      error: (_, _) =>
                          const SliverToBoxAdapter(child: SizedBox(height: 28)),
                    ),

                    // ── At a glance ───────────────────────────────────────────────
                    receiptsAsync.when(
                      data: (receipts) {
                        return claimsAsync.when(
                          data: (claims) {
                            final attentionItems = _buildAttentionItems(
                              receipts,
                              claims,
                            );
                            return SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  _AttentionSection(
                                    items: attentionItems,
                                    isDark: isDark,
                                    onTap: _goToDetail,
                                  ),
                                  const SizedBox(height: 32),
                                  _InsightsSection(
                                    receipts: receipts,
                                    claims: claims,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            );
                          },
                          loading: () => const SliverToBoxAdapter(
                            child: SizedBox.shrink(),
                          ),
                          error: (_, _) => const SliverToBoxAdapter(
                            child: SizedBox.shrink(),
                          ),
                        );
                      },
                      loading: () =>
                          const SliverToBoxAdapter(child: SizedBox.shrink()),
                      error: (_, _) =>
                          const SliverToBoxAdapter(child: SizedBox.shrink()),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Add receipt button ─────────────────────────────────────────
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.paddingPage,
                12,
                AppDimensions.paddingPage,
                32,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddReceiptScreen(),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 10),
                            Text(
                              'Add New',
                              style: AppTextStyles.button.copyWith(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              height: 30,
                              width: 30,
                              decoration: BoxDecoration(
                                color: AppColors.onPrimary.withValues(
                                  alpha: 0.15,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Symbols.arrow_right_alt_rounded,
                                size: AppDimensions.iconSmall,
                                weight: AppDimensions.iconWeightBold,
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final receipts = ref.read(receiptsProvider).valueOrNull ?? [];
                        final hasProducts = receipts.any((r) => r.lineItems.any((i) => i.status != 'ARCHIVED'));
                        if (!hasProducts) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('No products available to claim.'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        _showProductSelector(receipts);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.card(isDark),
                          border: Border.all(color: AppColors.border(isDark)),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 10),
                            Text(
                              'Claim PDF',
                              style: AppTextStyles.button.copyWith(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              height: 30,
                              width: 30,
                              decoration: BoxDecoration(
                                color: AppColors.onPrimary.withValues(
                                  alpha: 0.08,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Symbols.adf_scanner_rounded,
                                size: AppDimensions.iconSmall,
                                weight: AppDimensions.iconWeightBold,
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ──────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.receipts, required this.isDark});

  final List<ReceiptModel> receipts;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final activeItems = receipts
        .expand((r) => r.lineItems)
        .where((i) => i.status != 'ARCHIVED')
        .toList();
    final total = activeItems.length;
    final protected = activeItems
        .where((i) => i.warrantyExpiryDate != null && !i.isWarrantyExpired)
        .length;

    String fmt(int n) => n == 0 ? '00' : n.toString().padLeft(2, '0');

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: fmt(total),
            label: 'Total',
            isDark: isDark,
            icon: Symbols.shopping_bag_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: fmt(protected),
            label: 'Protected',
            isDark: isDark,
            icon: Symbols.shield_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.isDark,
    required this.icon,
  });

  final String value;
  final String label;
  final bool isDark;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final labelColor = AppColors.textSecondary(isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.textSecondary(isDark).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: AppDimensions.iconSmall,
              color: labelColor,
              weight: AppDimensions.iconWeightBold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.textPrimary(isDark),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: labelColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Attention section ──────────────────────────────────────────────────────────

Color _accentFor(_AttentionItem item) {
  if (item.isClaim) return AppColors.info;
  return (item.isReturn || item.daysRemaining <= 7)
      ? AppColors.error
      : AppColors.warning;
}

class _AttentionSection extends StatefulWidget {
  const _AttentionSection({
    required this.items,
    required this.isDark,
    required this.onTap,
  });

  final List<_AttentionItem> items;
  final bool isDark;
  final void Function(_AttentionItem) onTap;

  @override
  State<_AttentionSection> createState() => _AttentionSectionState();
}

class _AttentionSectionState extends State<_AttentionSection> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!mounted || widget.items.length <= 1) return;
      if (_pageController.hasClients) {
        int nextPage = _currentPage + 1;
        if (nextPage >= widget.items.length) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  void _pauseAndDelayResume() {
    _timer?.cancel();
    _delayTimer?.cancel();
    _delayTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        _startAutoPlay();
      }
    });
  }

  void _onUserInteractionDown(PointerDownEvent event) {
    _timer?.cancel();
    _delayTimer?.cancel();
  }

  void _onUserInteractionUp(PointerEvent event) {
    _pauseAndDelayResume();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _delayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final isDark = widget.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.paddingPage,
            32,
            AppDimensions.paddingPage,
            0,
          ),
          child: Row(
            children: [
              Text(
                'AT A GLANCE',
                style: AppTextStyles.capsLabel.copyWith(
                  color: AppColors.textSecondary(isDark),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Show placeholder if no items, otherwise show PageView
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingPage,
            ),
            child: AllClearPlaceholder(isDark: isDark),
          )
        else ...[
          SizedBox(
            height: 160,
            child: Listener(
              onPointerDown: _onUserInteractionDown,
              onPointerUp: _onUserInteractionUp,
              onPointerCancel: _onUserInteractionUp,
              child: PageView.builder(
                controller: _pageController,
                itemCount: items.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingPage,
                  ),
                  child: _AttentionCard(
                    item: items[i],
                    isDark: isDark,
                    onTap: () => widget.onTap(items[i]),
                  ),
                ),
              ),
            ),
          ),

          if (items.length > 1) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(items.length, (i) {
                final active = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? _accentFor(items[i]).withValues(alpha: 0.8)
                        : AppColors.border(isDark),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ],
      ],
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  final _AttentionItem item;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accentColor = _accentFor(item);
    final typeLabel = item.isClaim
        ? 'ACTIVE CLAIM'
        : item.isReturn
        ? 'RETURN PERIOD'
        : 'WARRANTY';
    final daysLabel = item.isClaim
        ? (item.claimStatus ?? 'Pending')
              .replaceAll('_', ' ')
              .split(' ')
              .map(
                (word) =>
                    word[0].toUpperCase() + word.substring(1).toLowerCase(),
              )
              .join(' ')
        : item.daysRemaining == 0
        ? 'Expires today'
        : '${item.daysRemaining} day${item.daysRemaining == 1 ? '' : 's'} left';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.card(isDark),
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          border: Border.all(color: AppColors.border(isDark)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Product image ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.paddingCardSmall,
                AppDimensions.paddingCardSmall,
                0,
                AppDimensions.paddingCardSmall,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                child: SizedBox(
                  width: 110,
                  child: item.productImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: item.productImageUrl!,
                          fit: BoxFit.contain,
                          errorWidget: (_, _, _) =>
                              _ImagePlaceholder(color: accentColor),
                        )
                      : _ImagePlaceholder(color: accentColor),
                ),
              ),
            ),

            // ── Text content ──────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingCardSmall),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TypeBadge(label: typeLabel, color: accentColor),
                        const SizedBox(height: 8),
                        Text(
                          item.productName,
                          style: AppTextStyles.listTitle.copyWith(
                            color: AppColors.textPrimary(isDark),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.storeName != null) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Symbols.storefront_rounded,
                                size: AppDimensions.iconTiny,
                                color: AppColors.textSecondary(isDark),
                                weight: 600.0,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.storeName!,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary(isDark),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.isClaim
                              ? Symbols.info_rounded
                              : Symbols.timer_rounded,
                          size: AppDimensions.iconTiny,
                          color: accentColor,
                          weight: AppDimensions.iconWeightBold,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          daysLabel,
                          style: AppTextStyles.bodyXSmall.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Insights section ───────────────────────────────────────────────────────────

class _InsightsSection extends StatelessWidget {
  const _InsightsSection({
    required this.receipts,
    required this.claims,
    required this.isDark,
  });

  final List<ReceiptModel> receipts;
  final List<ClaimDocumentResponse> claims;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    int totalEligible = 0;
    int protectedCount = 0;

    for (final r in receipts) {
      for (final item in r.lineItems) {
        if (item.status == 'ARCHIVED') {
          continue;
        }

        totalEligible++;

        // Item is protected if it still has an active warranty
        final hasActiveWarranty =
            item.warrantyExpiryDate != null && !item.isWarrantyExpired;

        if (hasActiveWarranty) {
          protectedCount++;
        }
      }
    }

    final double scorePercentage = totalEligible == 0 ? 0.0 : (protectedCount / totalEligible);
    final int scoreDisplay = (scorePercentage * 100).round();

    // Determine the color of the bar indicator
    Color barColor = AppColors.success;
    if (scorePercentage < 0.5) {
      barColor = AppColors.error;
    } else if (scorePercentage < 0.8) {
      barColor = AppColors.warning;
    }

    final card = AppColors.card(isDark);
    final border = AppColors.border(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingPage,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.paddingCardSmall, 
          AppDimensions.paddingCardSmall, 
          AppDimensions.paddingCardSmall, 
          AppDimensions.paddingCardSmall
        ),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'COVERAGE',
                    style: AppTextStyles.capsLabel.copyWith(
                      color: textSecondary,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$protectedCount',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      ' / $totalEligible',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Custom linear progress bar
            LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                final fillWidth = totalEligible == 0 ? 0.0 : (maxWidth * scorePercentage);
                return Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.border(isDark),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.fastOutSlowIn,
                      height: 8,
                      width: fillWidth,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              totalEligible == 0
                  ? "Add your first receipt to start tracking your coverage."
                  : '$scoreDisplay% of your products are actively protected',
              style: AppTextStyles.spaceGrotesk.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textSecondary, 
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared small widgets ───────────────────────────────────────────────────────

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          Symbols.image_not_supported_rounded,
          size: AppDimensions.iconNormal,
          color: color.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall - 2),
      ),
      child: Text(label, style: AppTextStyles.badgeText.copyWith(color: color)),
    );
  }
}

// ── Circular icon button ───────────────────────────────────────────────────────

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
          child: Icon(
            icon,
            size: AppDimensions.iconMedium,
            color: iconColor,
            weight: AppDimensions.iconWeightBold,
          ),
        ),
      ),
    );
  }
}

// ── Product Selector Sheet ───────────────────────────────────────────────────

class _ProductSelectorSheet extends StatefulWidget {
  final List<ReceiptModel> receipts;
  
  const _ProductSelectorSheet({required this.receipts});

  @override
  State<_ProductSelectorSheet> createState() => _ProductSelectorSheetState();
}

class _ProductSelectorSheetState extends State<_ProductSelectorSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.background(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);
    
    // Extract flatten products
    final products = <Map<String, dynamic>>[];
    for (final receipt in widget.receipts) {
      for (final item in receipt.lineItems) {
        if (item.status == 'ARCHIVED') continue;
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!item.displayName.toLowerCase().contains(query) && 
              !(receipt.storeName?.toLowerCase().contains(query) ?? false)) {
            continue;
          }
        }
        products.add({
          'receiptId': receipt.id,
          'receiptStoreName': receipt.storeName ?? 'Unknown Store',
          'lineItemId': item.id,
          'productName': item.displayName,
          'storeName': receipt.storeName,
          'productImageUrl': item.productImageUrl,
        });
      }
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXXL)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border(isDark),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingPage),
            child: Row(
              children: [
                Text(
                  'Select Product to Claim',
                  style: AppTextStyles.headingLarge.copyWith(color: textPrimary, fontSize: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingPage),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: AppTextStyles.bodyMedium.copyWith(color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Search products or stores...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: textSecondary.withValues(alpha: 0.5)),
                prefixIcon: Icon(Symbols.search_rounded, color: textSecondary),
                filled: true,
                fillColor: AppColors.card(isDark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                  borderSide: BorderSide(color: AppColors.border(isDark)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                  borderSide: BorderSide(color: AppColors.border(isDark)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: products.isEmpty 
                ? Center(child: Text('No products found', style: AppTextStyles.bodyMedium.copyWith(color: textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingPage, vertical: 8),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final p = products[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context); // Close sheet
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ClaimsListScreen(
                                receiptId: p['receiptId'],
                                lineItemId: p['lineItemId'],
                                receiptStoreName: p['receiptStoreName'],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.card(isDark),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                            border: Border.all(color: AppColors.border(isDark)),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.white,
                                  child: p['productImageUrl'] != null
                                      ? CachedNetworkImage(
                                          imageUrl: p['productImageUrl'],
                                          fit: BoxFit.contain,
                                          errorWidget: (_, _, _) => Icon(Symbols.image_not_supported_rounded, color: textSecondary.withValues(alpha: 0.5), size: 24),
                                        )
                                      : Icon(Symbols.image_not_supported_rounded, color: textSecondary.withValues(alpha: 0.5), size: 24),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p['productName'],
                                      style: AppTextStyles.listTitle.copyWith(color: textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      p['storeName'] ?? 'Unknown Store',
                                      style: AppTextStyles.caption.copyWith(color: textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Symbols.chevron_right_rounded, color: textSecondary),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

