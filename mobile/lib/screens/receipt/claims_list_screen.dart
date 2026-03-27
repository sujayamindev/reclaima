import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/logger.dart';
import '../../services/claim_service.dart';
import 'claim_detail_screen.dart';
import 'claim_pdf_screen.dart';

/// Screen that displays claims for a specific product (line item)
class ClaimsListScreen extends ConsumerStatefulWidget {
  final String receiptId;
  final String? lineItemId; // Product/line item ID - optional for filtering
  final String receiptStoreName;

  const ClaimsListScreen({
    super.key,
    required this.receiptId,
    this.lineItemId,
    required this.receiptStoreName,
  });

  @override
  ConsumerState<ClaimsListScreen> createState() => _ClaimsListScreenState();
}

class _ClaimsListScreenState extends ConsumerState<ClaimsListScreen> {
  bool _isLoading = true;
  List<ClaimDocumentResponse> _claims = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClaims();
  }

  Future<void> _loadClaims() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      logger.i(
        'Loading claims for product ${widget.lineItemId ?? "all"} in receipt ${widget.receiptId}',
      );
      final claimService = ref.read(claimServiceProvider);
      final claims = await claimService.getClaims(
        receiptId: widget.receiptId,
        lineItemId: widget.lineItemId,
      );

      if (!mounted) return;
      setState(() {
        _claims = claims;
        _isLoading = false;
      });
      logger.i('Loaded ${claims.length} claims');
    } catch (e) {
      logger.e('Error loading claims: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteClaim(String claimId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(
          Theme.of(context).brightness == Brightness.dark,
        ),
        title: Text(
          'Delete Claim',
          style: TextStyle(
            color: AppColors.textPrimary(
              Theme.of(context).brightness == Brightness.dark,
            ),
          ),
        ),
        content: Text(
          'Are you sure you want to delete this claim? This action cannot be undone.',
          style: TextStyle(
            color: AppColors.textSecondary(
              Theme.of(context).brightness == Brightness.dark,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final claimService = ref.read(claimServiceProvider);
      await claimService.deleteClaim(claimId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Claim deleted successfully')),
      );

      // Reload claims
      _loadClaims();
    } catch (e) {
      logger.e('Error deleting claim: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete claim: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.background(isDark),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Symbols.arrow_back_rounded,
            color: AppColors.textPrimary(isDark),
            weight: 800.0,
          ),
          padding: const EdgeInsets.all(8),
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent,
            shape: const CircleBorder(),
          ),
        ),
        title: Text(
          'Manage Claims',
          style: AppTextStyles.listTitle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary(isDark),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Symbols.cached_rounded,
              color: AppColors.textPrimary(isDark),
              size: 22,
              weight: 800.0,
            ),
            onPressed: _loadClaims,
            tooltip: 'Refresh',
            padding: const EdgeInsets.all(8),
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _error != null
            ? _buildErrorState(isDark)
            : _claims.isEmpty
            ? _buildEmptyState(isDark)
            : _buildClaimsList(isDark),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.paddingPage,
            16,
            AppDimensions.paddingPage,
            16,
          ),
          child: SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClaimPdfScreen(
                      receiptId: widget.receiptId,
                      lineItemId: widget.lineItemId,
                      receiptStoreName: widget.receiptStoreName,
                    ),
                  ),
                );

                // Reload claims after generating new one
                if (result != null || mounted) {
                  _loadClaims();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                overlayColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
                enableFeedback: false,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                ),
              ),
              icon: const Icon(
                Symbols.add_rounded,
                weight: AppDimensions.iconWeightHeavy,
              ),
              label: const Text('New Claim'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.error_rounded,
              size: AppDimensions.iconXXL,
              weight: AppDimensions.iconWeightHeavy,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load claims',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textPrimary(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An unknown error occurred',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary(isDark),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadClaims,
              icon: const Icon(
                Symbols.refresh_rounded,
                weight: AppDimensions.iconWeightHeavy,
              ),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Symbols.description_rounded,
                  size: AppDimensions.iconXXL,
                  weight: AppDimensions.iconWeightHeavy,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Claims Yet',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textPrimary(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t submitted any claims for this product yet.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary(isDark),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Tap the + button below to create your first claim',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary(isDark),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClaimsList(bool isDark) {
    final ongoingClaims = _claims.where((claim) {
      final status = claim.status.toUpperCase();
      return status != 'RESOLVED' && status != 'DENIED';
    }).toList();
    final closedClaims = _claims.where((claim) {
      final status = claim.status.toUpperCase();
      return status == 'RESOLVED' || status == 'DENIED';
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadClaims,
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingPage),
        children: [
          if (ongoingClaims.isNotEmpty) ...[
            _buildSectionLabel('ONGOING CLAIMS', isDark),
            const SizedBox(height: 10),
            ...ongoingClaims.map((claim) => _buildClaimCard(claim, isDark)),
          ],
          if (closedClaims.isNotEmpty) ...[
            if (ongoingClaims.isNotEmpty) const SizedBox(height: 8),
            _buildSectionLabel('CLOSED CLAIMS', isDark),
            const SizedBox(height: 10),
            ...closedClaims.map((claim) => _buildClaimCard(claim, isDark)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.capsLabel.copyWith(
            color: AppColors.textSecondary(isDark),
          ),
        ),
      ],
    );
  }

  String _normalizeTimelineStatus(String status) {
    final normalized = status.toUpperCase();
    if (normalized == 'RESOLVED' || normalized == 'DENIED') {
      return 'CLOSED';
    }
    if (normalized == 'SUBMITTED' || normalized == 'IN_PROGRESS') {
      return normalized;
    }
    return 'DRAFT';
  }

  int _timelineIndex(String status) {
    switch (status) {
      case 'DRAFT':
        return 0;
      case 'SUBMITTED':
        return 1;
      case 'IN_PROGRESS':
        return 2;
      case 'CLOSED':
        return 3;
      default:
        return 0;
    }
  }

  Widget _buildClaimProgressTimeline(String status, bool isDark) {
    const steps = ['Draft', 'Submitted', 'In Progress', 'Closed'];
    const stepFlex = [2, 3, 3, 2];
    final normalized = _normalizeTimelineStatus(status);
    final activeIndex = _timelineIndex(normalized);
    final isDenied = status.toUpperCase() == 'DENIED';

    return Column(
      children: [
        Row(
          children: [
            for (int i = 0; i < steps.length; i++)
              Expanded(
                flex: stepFlex[i],
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: i == 0
                              ? Colors.transparent
                              : (i - 1) < activeIndex
                              ? AppColors.primary.withValues(alpha: 0.9)
                              : AppColors.border(isDark),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < activeIndex
                            ? AppColors.primary
                            : i == activeIndex
                            ? (isDenied ? AppColors.primary : AppColors.primary)
                            : Colors.transparent,
                        border: Border.all(
                          color: i <= activeIndex
                              ? (i == activeIndex && isDenied
                                    ? AppColors.primary
                                    : AppColors.primary)
                              : AppColors.border(isDark),
                          width: 1.3,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: i == steps.length - 1
                              ? Colors.transparent
                              : i < activeIndex
                              ? AppColors.primary.withValues(alpha: 0.9)
                              : AppColors.border(isDark),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (int i = 0; i < steps.length; i++)
              Expanded(
                flex: stepFlex[i],
                child: Text(
                  steps[i],
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: i == activeIndex
                        ? (isDenied
                              ? AppColors.textPrimary(isDark)
                              : AppColors.textPrimary(isDark))
                        : AppColors.textSecondary(isDark),
                    fontWeight: i == activeIndex
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    required bool isDark,
    TextStyle? textStyle,
    int maxLines = 1,
    double? fixedHeight,
  }) {
    Widget content = Row(
      children: [
        Icon(
          icon,
          size: AppDimensions.iconTiny,
          weight: AppDimensions.iconWeightHeavy,
          color: AppColors.textSecondary(isDark),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style:
                textStyle ??
                AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary(isDark),
                ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (fixedHeight != null) {
      return SizedBox(height: fixedHeight, child: content);
    }
    return content;
  }

  Widget _buildClaimCard(ClaimDocumentResponse claim, bool isDark) {
    final claimType = (claim.claimType ?? 'warranty').toUpperCase();
    final shortClaimId = claim.id.length > 10
        ? claim.id.substring(0, 10)
        : claim.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ClaimDetailScreen(
                  claimId: claim.id,
                  receiptStoreName: widget.receiptStoreName,
                ),
              ),
            );

            // Reload if claim was updated
            if (result == true) {
              _loadClaims();
            }
          },
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingCardSmall),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
              border: Border.all(color: AppColors.border(isDark)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            icon: Symbols.confirmation_number_rounded,
                            text: 'Claim #$shortClaimId',
                            isDark: isDark,
                            textStyle: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary(isDark),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          _buildInfoRow(
                            icon: Symbols.calendar_month_rounded,
                            text: DateFormatter.formatDate(
                              claim.createdAt.toLocal(),
                            ),
                            isDark: isDark,
                            textStyle: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary(isDark),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Claim type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusSmall,
                        ),
                      ),
                      child: Text(
                        claimType,
                        style: AppTextStyles.badgeText.copyWith(
                          color: AppColors.primary,
                          letterSpacing: 0.35,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Issue description
                _buildInfoRow(
                  icon: Symbols.report_problem_rounded,
                  text: claim.issueDescription,
                  isDark: isDark,
                  maxLines: 1,
                  fixedHeight: 20, // Exact height for 1 line of text
                  textStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary(isDark),
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 12),

                // Notes — only shown when present
                if (claim.notes != null && claim.notes!.isNotEmpty) ...[
                  _buildInfoRow(
                    icon: Symbols.sticky_note_2_rounded,
                    text: claim.notes!,
                    isDark: isDark,
                    maxLines: 1,
                    fixedHeight: 20,
                    textStyle: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary(isDark),
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                _buildClaimProgressTimeline(claim.status, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
