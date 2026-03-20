import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../../services/claim_service.dart';
import 'claim_detail_screen.dart';
import 'claim_pdf_screen.dart';

/// Screen that displays all claims for a receipt
class ClaimsListScreen extends ConsumerStatefulWidget {
  final String receiptId;
  final String receiptStoreName;

  const ClaimsListScreen({
    super.key,
    required this.receiptId,
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
      logger.i('Loading claims for receipt ${widget.receiptId}');
      final claimService = ref.read(claimServiceProvider);
      final claims = await claimService.getClaims(receiptId: widget.receiptId);

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
        backgroundColor: AppColors.card(Theme.of(context).brightness == Brightness.dark),
        title: Text('Delete Claim', style: TextStyle(color: AppColors.textPrimary(Theme.of(context).brightness == Brightness.dark))),
        content: Text(
          'Are you sure you want to delete this claim? This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary(Theme.of(context).brightness == Brightness.dark)),
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
        SnackBar(content: Text('Failed to delete claim: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Color _getStatusColor(String status, bool isDark) {
    switch (status.toUpperCase()) {
      case 'SUBMITTED':
        return AppColors.primary;
      case 'IN_PROGRESS':
        return AppColors.warning;
      case 'RESOLVED':
        return Colors.green;
      case 'DENIED':
        return Colors.red;
      case 'DRAFT':
        return AppColors.textSecondary(isDark);
      default:
        return AppColors.textSecondary(isDark);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'SUBMITTED':
        return Symbols.send;
      case 'IN_PROGRESS':
        return Symbols.pending;
      case 'RESOLVED':
        return Symbols.check_circle;
      case 'DENIED':
        return Symbols.cancel;
      case 'DRAFT':
        return Symbols.draft;
      default:
        return Symbols.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        title: const Text('Warranty Claims'),
        backgroundColor: AppColors.card(isDark),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Symbols.refresh),
            onPressed: _loadClaims,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState(isDark)
                : _claims.isEmpty
                    ? _buildEmptyState(isDark)
                    : _buildClaimsList(isDark),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClaimPdfScreen(
                receiptId: widget.receiptId,
                receiptStoreName: widget.receiptStoreName,
              ),
            ),
          );

          // Reload claims after generating new one
          if (result != null || mounted) {
            _loadClaims();
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Symbols.add),
        label: const Text('New Claim'),
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
              Symbols.error,
              size: 64,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load claims',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary(isDark),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An unknown error occurred',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary(isDark),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadClaims,
              icon: const Icon(Symbols.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
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
                  Symbols.description,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Claims Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary(isDark),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t submitted any warranty claims for this receipt yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary(isDark),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Tap the + button below to create your first claim',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    return RefreshIndicator(
      onRefresh: _loadClaims,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card(isDark),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(isDark)),
            ),
            child: Row(
              children: [
                Icon(
                  Symbols.storefront,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.receiptStoreName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary(isDark),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_claims.length} ${_claims.length == 1 ? 'claim' : 'claims'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Claims list
          ..._claims.map((claim) => _buildClaimCard(claim, isDark)),
        ],
      ),
    );
  }

  Widget _buildClaimCard(ClaimDocumentResponse claim, bool isDark) {
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(12),
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
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border(isDark)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(claim.status, isDark).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(claim.status),
                            size: 14,
                            color: _getStatusColor(claim.status, isDark),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            claim.status.toUpperCase(),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: _getStatusColor(claim.status, isDark),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Claim type
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (claim.claimType ?? 'warranty').toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Issue description
                Text(
                  claim.issueDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary(isDark),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Notes (if any)
                if (claim.notes != null && claim.notes!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background(isDark),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Symbols.note,
                          size: 14,
                          color: AppColors.textSecondary(isDark),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            claim.notes!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary(isDark),
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Date and actions
                Row(
                  children: [
                    Icon(
                      Symbols.schedule,
                      size: 14,
                      color: AppColors.textSecondary(isDark),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(claim.createdAt.toLocal()),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary(isDark),
                      ),
                    ),
                    const Spacer(),
                    // Delete button
                    IconButton(
                      icon: const Icon(Symbols.delete, size: 18),
                      color: Colors.red.withValues(alpha: 0.7),
                      onPressed: () => _deleteClaim(claim.id),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Delete claim',
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
