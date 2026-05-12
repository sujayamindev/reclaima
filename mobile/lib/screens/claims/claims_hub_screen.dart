// coverage:ignore-file
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/receipt_model.dart';
import '../../providers/claim_provider.dart';
import '../../providers/receipt_provider.dart';
import '../../services/claim_service.dart';
import '../../widgets/product_selector_sheet.dart';
import '../receipt/claim_detail_screen.dart';

// ── Filter enum ───────────────────────────────────────────────────────────

enum ClaimsFilterType {
  all('All Claims'),
  ongoing('Ongoing Claims'),
  closed('Closed Claims');

  final String label;
  const ClaimsFilterType(this.label);
}

// ── Sort enum ─────────────────────────────────────────────────────────────

enum ClaimsSortType {
  newest('Newest First'),
  oldest('Oldest First'),
  status('Status');

  final String label;
  const ClaimsSortType(this.label);
}

// ── Main screen ───────────────────────────────────────────────────────────

class ClaimsHubScreen extends ConsumerStatefulWidget {
  const ClaimsHubScreen({super.key});

  @override
  ConsumerState<ClaimsHubScreen> createState() => _ClaimsHubScreenState();
}

class _ClaimsHubScreenState extends ConsumerState<ClaimsHubScreen> {
  String _searchQuery = '';
  ClaimsFilterType _selectedFilter = ClaimsFilterType.all;
  ClaimsSortType _selectedSort = ClaimsSortType.newest;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ClaimDocumentResponse> _filterAndSortClaims(
    List<ClaimDocumentResponse> allClaims,
  ) {
    // Apply search
    var searchFiltered = allClaims.where((claim) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      final idMatches = claim.id.toLowerCase().contains(q);
      final descMatches = claim.issueDescription.toLowerCase().contains(q);
      return idMatches || descMatches;
    }).toList();

    // Apply status filter
    var filtered = searchFiltered.where((claim) {
      final isOngoing =
          claim.status.toUpperCase() != 'RESOLVED' &&
          claim.status.toUpperCase() != 'DENIED';
      switch (_selectedFilter) {
        case ClaimsFilterType.all:
          return true;
        case ClaimsFilterType.ongoing:
          return isOngoing;
        case ClaimsFilterType.closed:
          return !isOngoing;
      }
    }).toList();

    // Apply sort
    filtered.sort((a, b) {
      switch (_selectedSort) {
        case ClaimsSortType.newest:
          return b.createdAt.compareTo(a.createdAt);
        case ClaimsSortType.oldest:
          return a.createdAt.compareTo(b.createdAt);
        case ClaimsSortType.status:
          return a.status.compareTo(b.status);
      }
    });

    return filtered;
  }

  void _navigateToClaimDetail(
    ClaimDocumentResponse claim,
    List<ReceiptModel> allReceipts,
  ) {
    // Find the receipt to get the store name
    ReceiptModel? receipt;
    try {
      receipt = allReceipts.firstWhere((r) => r.id == claim.receiptId);
    } catch (e) {
      // Receipt not found, use placeholder
      receipt = null;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClaimDetailScreen(
          claimId: claim.id,
          receiptStoreName: receipt?.storeName ?? 'Unknown Store',
        ),
      ),
    );
  }

  Future<void> _refreshClaims() async {
    ref.invalidate(userClaimsProvider);
    await ref.read(userClaimsProvider.future);
  }

  Future<void> _showClaimsInfoDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(isDark),
        title: Text(
          'How to Use Claims',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textPrimary(isDark),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoSection(
                icon: Symbols.add_circle_rounded,
                title: 'Creating a Claim PDF',
                steps: [
                  'Select the product you want to file a claim for from the Vault',
                  'Tap on the "Manage Claims" button',
                  'Tap "New Claim" button',
                  'Fill in the issue description and select claim type',
                  'Tap "Generate Claim PDF" to create your claim document',
                ],
                isDark: isDark,
              ),
              const SizedBox(height: 20),
              _buildInfoSection(
                icon: Symbols.check_circle_rounded,
                title: 'Updating Claim Status',
                steps: [
                  'Open the claim you want to update',
                  'Tap on the status dropdown (e.g., "DRAFT", "SUBMITTED")',
                  'Select the new status from the list',
                  'Tap the "Done" button',
                  'Status options: DRAFT → SUBMITTED → IN_PROGRESS → RESOLVED/DENIED',
                ],
                isDark: isDark,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Got it',
              style: AppTextStyles.buttonSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required List<String> steps,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: AppDimensions.iconMedium,
              weight: AppDimensions.iconWeightBold,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary(isDark),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...steps.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.key + 1}. ',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary(isDark),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.value,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary(isDark),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final claimsAsync = ref.watch(userClaimsProvider);
    final receiptsAsync = ref.watch(receiptsProvider);

    final bg = AppColors.background(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton(
          heroTag: 'fab_claims',
          onPressed: () {
            final receipts = ref.read(receiptsProvider).valueOrNull;
            if (receipts != null) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => ProductSelectorSheet(receipts: receipts),
              );
            }
          },
          backgroundColor: AppColors.primary,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          child: Icon(
            Symbols.add_rounded,
            size: AppDimensions.iconLarge,
            weight: AppDimensions.iconWeightBold,
            color: AppColors.onPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: claimsAsync.when(
          data: (allClaims) {
            final filteredClaims = _filterAndSortClaims(allClaims);

            return receiptsAsync.when(
              data: (allReceipts) {
                return Column(
                  children: [
                    // ── Header ────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimensions.paddingPage,
                        20,
                        AppDimensions.paddingPage,
                        16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Claims',
                                style: AppTextStyles.headingLarge.copyWith(
                                  color: textPrimary,
                                ),
                              ),
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: IconButton(
                                  icon: Icon(
                                    Symbols.info_rounded,
                                    color: AppColors.textSecondary(isDark),
                                    size: AppDimensions.iconNormal,
                                    weight: AppDimensions.iconWeightBold,
                                  ),
                                  onPressed: () => _showClaimsInfoDialog(),
                                  tooltip: 'How to use claims',
                                  padding: EdgeInsets.zero,
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shape: const CircleBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Search Bar
                          GestureDetector(
                            onTap: () => FocusScope.of(context).unfocus(),
                            behavior: HitTestBehavior.translucent,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.card(isDark),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusXL,
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) =>
                                    setState(() => _searchQuery = val),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search claims...',
                                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary(isDark),
                                  ),
                                  prefixIcon: Icon(
                                    Symbols.search_rounded,
                                    color: AppColors.textSecondary(isDark),
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(
                                            Symbols.close_rounded,
                                            color: AppColors.textSecondary(
                                              isDark,
                                            ),
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
                                            FocusScope.of(context).unfocus();
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${filteredClaims.length} claim${filteredClaims.length != 1 ? 's' : ''}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Filter & sort bar ─────────────────────────────────
                    GestureDetector(
                      onTap: () => FocusScope.of(context).unfocus(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingPage,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _FilterChip(
                              label: _selectedFilter.label,
                              isDark: isDark,
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: AppColors.background(isDark),
                                  builder: (context) => _FilterMenu(
                                    selectedFilter: _selectedFilter,
                                    onFilterSelected: (filter) {
                                      setState(() => _selectedFilter = filter);
                                      Navigator.pop(context);
                                    },
                                    isDark: isDark,
                                  ),
                                );
                              },
                              icon: Symbols.tune_rounded,
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: _selectedSort.label,
                              isDark: isDark,
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: AppColors.background(isDark),
                                  builder: (context) => _SortMenu(
                                    selectedSort: _selectedSort,
                                    onSortSelected: (sort) {
                                      setState(() => _selectedSort = sort);
                                      Navigator.pop(context);
                                    },
                                    isDark: isDark,
                                  ),
                                );
                              },
                              icon: Symbols.swap_vert_rounded,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Claims list ────────────────────────────────────────
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refreshClaims,
                        color: AppColors.primary,
                        child: GestureDetector(
                          onTap: () => FocusScope.of(context).unfocus(),
                          behavior: HitTestBehavior.translucent,
                          child: filteredClaims.isEmpty
                              ? _buildEmptyState(
                                  isDark,
                                  textPrimary,
                                  textSecondary,
                                )
                              : _buildClaimsList(
                                  filteredClaims,
                                  isDark,
                                  textPrimary,
                                  textSecondary,
                                  allReceipts,
                                ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, st) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Symbols.error_rounded,
                      size: AppDimensions.iconXXL,
                      color: Colors.red.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading receipts',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textPrimary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, st) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Symbols.error_rounded,
                  size: AppDimensions.iconXXL,
                  color: Colors.red.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading claims',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Something went wrong. Please try again.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary(isDark),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color textPrimary, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Symbols.assignment_rounded,
            size: AppDimensions.iconXXL,
            color: textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No claims found',
            style: AppTextStyles.headingSmall.copyWith(color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a claim from your receipts to get started',
            style: AppTextStyles.bodySmall.copyWith(color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimsList(
    List<ClaimDocumentResponse> claims,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    List<ReceiptModel> allReceipts,
  ) {
    final ongoingClaims = claims.where((claim) {
      final status = claim.status.toUpperCase();
      return status != 'RESOLVED' && status != 'DENIED';
    }).toList();

    final closedClaims = claims.where((claim) {
      final status = claim.status.toUpperCase();
      return status == 'RESOLVED' || status == 'DENIED';
    }).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingPage,
        vertical: 8,
      ),
      children: [
        if (ongoingClaims.isNotEmpty) ...[
          Text(
            'ONGOING CLAIMS',
            style: AppTextStyles.capsLabel.copyWith(
              color: AppColors.textSecondary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          ...ongoingClaims.map(
            (claim) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ClaimCard(
                claim: claim,
                isDark: isDark,
                allReceipts: allReceipts,
                onTap: () => _navigateToClaimDetail(claim, allReceipts),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (closedClaims.isNotEmpty) ...[
          Text(
            'CLOSED CLAIMS',
            style: AppTextStyles.capsLabel.copyWith(
              color: AppColors.textSecondary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          ...closedClaims.map(
            (claim) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ClaimCard(
                claim: claim,
                isDark: isDark,
                allReceipts: allReceipts,
                onTap: () => _navigateToClaimDetail(claim, allReceipts),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Claim card ─────────────────────────────────────────────────────────────

class _ClaimCard extends StatelessWidget {
  final ClaimDocumentResponse claim;
  final bool isDark;
  final List<ReceiptModel> allReceipts;
  final VoidCallback onTap;

  const _ClaimCard({
    required this.claim,
    required this.isDark,
    required this.allReceipts,
    required this.onTap,
  });

  String _getProductNames() {
    try {
      final receipt = allReceipts.firstWhere((r) => r.id == claim.receiptId);

      if (claim.lineItemId != null) {
        try {
          final item = receipt.lineItems.firstWhere(
            (i) => i.id == claim.lineItemId,
          );
          return item.displayName;
        } catch (_) {}
      }

      final productNames = receipt.lineItems
          .map((item) => item.displayName)
          .toList();
      if (productNames.isEmpty) return 'Unknown Product';
      if (productNames.length == 1) return productNames.first;
      return '${productNames.first} + ${productNames.length - 1} more';
    } catch (e) {
      return 'Unknown Product';
    }
  }

  String? get _productImageUrl {
    try {
      final receipt = allReceipts.firstWhere((r) => r.id == claim.receiptId);
      if (claim.lineItemId != null) {
        try {
          final item = receipt.lineItems.firstWhere(
            (i) => i.id == claim.lineItemId,
          );
          if (item.productImageUrl != null) return item.productImageUrl;
        } catch (_) {}
      }
      return receipt.productImageUrl;
    } catch (e) {
      return null;
    }
  }

  Color _getStatusColor() {
    final s = claim.status.toUpperCase();
    if (s == 'RESOLVED') {
      return AppColors.success;
    }
    if (s == 'DENIED') {
      return AppColors.error;
    }
    if (s == 'SUBMITTED' || s == 'IN_PROGRESS') {
      return AppColors.warning;
    }
    return AppColors.textSecondary(isDark);
  }

  IconData _getStatusIcon() {
    final s = claim.status.toUpperCase();
    if (s == 'RESOLVED') {
      return Symbols.check_circle_rounded;
    }
    if (s == 'DENIED') {
      return Symbols.cancel_rounded;
    }
    if (s == 'SUBMITTED' || s == 'IN_PROGRESS') {
      return Symbols.pending_actions_rounded;
    }
    return Symbols.info_rounded;
  }

  String _getStatusLabel() {
    return claim.status
        .replaceAll(RegExp(r'_'), ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);
    final statusColor = _getStatusColor();
    final imageUrl = _productImageUrl;

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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
                  width: 84,
                  height: 84,
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
                          errorWidget: (_, _, _) =>
                              _ClaimImagePlaceholder(color: statusColor),
                        )
                      : _ClaimImagePlaceholder(color: statusColor),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingCardSmall),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getProductNames(),
                      style: AppTextStyles.listTitle.copyWith(
                        color: textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (claim.issueDescription.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 0.0),
                            child: Icon(
                              Symbols.notes_rounded,
                              size: AppDimensions.iconTiny,
                              color: textSecondary,
                              weight: AppDimensions.iconWeightBold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              claim.issueDescription,
                              style: AppTextStyles.bodyXSmall.copyWith(
                                color: textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(),
                          size: AppDimensions.iconTiny,
                          color: statusColor,
                          weight: AppDimensions.iconWeightBold,
                        ),
                        const SizedBox(width: 4),
                        if (claim.claimType != null &&
                            claim.claimType!.isNotEmpty)
                          Text(
                            '${claim.claimType![0].toUpperCase()}${claim.claimType!.substring(1).toLowerCase()} claim is ${_getStatusLabel().toLowerCase()}',
                            style: AppTextStyles.bodyXSmall.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          Text(
                            'Claim is ${_getStatusLabel().toLowerCase()}',
                            style: AppTextStyles.bodyXSmall.copyWith(
                              color: statusColor,
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

class _ClaimImagePlaceholder extends StatelessWidget {
  final Color color;

  const _ClaimImagePlaceholder({required this.color});

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

// ── Filter menu ────────────────────────────────────────────────────────────

class _FilterMenu extends StatelessWidget {
  final ClaimsFilterType selectedFilter;
  final ValueChanged<ClaimsFilterType> onFilterSelected;
  final bool isDark;

  const _FilterMenu({
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimary(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Filter by Status',
              style: AppTextStyles.headingSmall.copyWith(color: textPrimary),
            ),
          ),
          const SizedBox(height: 12),
          ...ClaimsFilterType.values.map(
            (filter) => _MenuItem(
              label: filter.label,
              isSelected: filter == selectedFilter,
              isDark: isDark,
              onTap: () => onFilterSelected(filter),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Sort menu ──────────────────────────────────────────────────────────────

class _SortMenu extends StatelessWidget {
  final ClaimsSortType selectedSort;
  final ValueChanged<ClaimsSortType> onSortSelected;
  final bool isDark;

  const _SortMenu({
    required this.selectedSort,
    required this.onSortSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimary(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Sort by',
              style: AppTextStyles.headingSmall.copyWith(color: textPrimary),
            ),
          ),
          const SizedBox(height: 12),
          ...ClaimsSortType.values.map(
            (sort) => _MenuItem(
              label: sort.label,
              isSelected: sort == selectedSort,
              isDark: isDark,
              onTap: () => onSortSelected(sort),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Menu item ──────────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _MenuItem({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimary(isDark);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected ? AppColors.primary : textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (isSelected)
                Icon(
                  Symbols.check_rounded,
                  color: AppColors.primary,
                  size: AppDimensions.iconMedium,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Filter chip ────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  final IconData icon;

  const _FilterChip({
    required this.label,
    required this.isDark,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final card = AppColors.card(isDark);
    final border = AppColors.border(isDark);
    final textPrimary = AppColors.textPrimary(isDark);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: AppDimensions.iconSmall,
              color: textPrimary,
              weight: AppDimensions.iconWeightBold,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(color: textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
