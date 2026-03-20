import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../services/claim_service.dart';
import '../../core/utils/logger.dart';

/// Screen for viewing and managing an existing warranty claim
class ClaimDetailScreen extends ConsumerStatefulWidget {
  final String claimId;
  final String receiptStoreName;

  const ClaimDetailScreen({
    super.key,
    required this.claimId,
    required this.receiptStoreName,
  });

  @override
  ConsumerState<ClaimDetailScreen> createState() => _ClaimDetailScreenState();
}

class _ClaimDetailScreenState extends ConsumerState<ClaimDetailScreen> {
  late final TextEditingController _notesController = TextEditingController();
  bool _isLoading = true;
  bool _isUpdating = false;
  ClaimDocumentResponse? _claim;
  String? _error;

  final List<String> _statusOptions = ['DRAFT', 'SUBMITTED', 'IN_PROGRESS', 'RESOLVED', 'DENIED'];

  @override
  void initState() {
    super.initState();
    _loadClaim();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadClaim() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      logger.i('Loading claim ${widget.claimId}');
      final claimService = ref.read(claimServiceProvider);
      final claim = await claimService.getClaim(widget.claimId);

      if (!mounted) return;
      setState(() {
        _claim = claim;
        _notesController.text = claim.notes ?? '';
        _isLoading = false;
      });
      logger.i('Claim loaded successfully');
    } catch (e) {
      logger.e('Error loading claim: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateClaimStatus(String newStatus) async {
    if (_claim == null) return;
    setState(() => _isUpdating = true);
    try {
      final claimService = ref.read(claimServiceProvider);
      final updated = await claimService.updateClaim(_claim!.id, status: newStatus);
      setState(() => _claim = updated);
    } catch (e) {
      logger.e('Error updating status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _updateClaimNotes() async {
    if (_claim == null) return;
    setState(() => _isUpdating = true);
    try {
      final claimService = ref.read(claimServiceProvider);
      final updated = await claimService.updateClaim(_claim!.id, notes: _notesController.text);
      setState(() => _claim = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notes saved')),
        );
      }
    } catch (e) {
      logger.e('Error updating notes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _showResolutionOutcomeDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = AppColors.card(isDark);
    final textColor = AppColors.textPrimary(isDark);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Claim Resolved', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: textColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('What was the outcome of this claim?', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary(isDark))),
                const SizedBox(height: 24),

                // Refunded
                _buildOutcomeOption(
                  icon: Symbols.payments,
                  title: 'Refunded / Returned',
                  subtitle: 'Item will be archived and stop tracking warranty.',
                  onTap: () {
                    Navigator.pop(ctx);
                    _resolveClaimOutcome('REFUNDED');
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // Repaired
                _buildOutcomeOption(
                  icon: Symbols.build,
                  title: 'Repaired',
                  subtitle: 'Item stays active. You can update its warranty date.',
                  onTap: () {
                    Navigator.pop(ctx);
                    _resolveClaimOutcome('REPAIRED');
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // Replaced
                _buildOutcomeOption(
                  icon: Symbols.autorenew,
                  title: 'Replaced with New Item',
                  subtitle: 'Archive old item and prepare a new digital record.',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showReplacementStrategyDialog();
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildOutcomeOption({required IconData icon, required String title, required String subtitle, required VoidCallback onTap, required bool isDark}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border(isDark)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary(isDark), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary(isDark))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReplacementStrategyDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.card(isDark),
          title: Text('Add Replacement', style: TextStyle(color: AppColors.textPrimary(isDark))),
          content: Text(
            'How would you like to add the new replacement item to your inventory?',
            style: TextStyle(color: AppColors.textSecondary(isDark)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                // Implementation for Phase 4 linking will go here shortly.
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload a new receipt to link it (Coming soon)')));
              },
              child: const Text('Scan New Receipt', style: TextStyle(color: AppColors.primary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _resolveClaimOutcome('REPLACED', duplicateDetails: true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onPrimary),
              child: const Text('Duplicate Old Details'),
            ),
          ],
        );
      }
    );
  }

  Future<void> _resolveClaimOutcome(String outcome, {bool duplicateDetails = false}) async {
    if (_claim == null) return;
    setState(() => _isUpdating = true);
    try {
      final claimService = ref.read(claimServiceProvider);
      final updated = await claimService.resolveClaim(
        _claim!.id,
        outcome,
        duplicateDetails: duplicateDetails ? true : null,
      );
      setState(() => _claim = updated);

      if (!mounted) return;
      if (outcome == 'REFUNDED') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item successfully archived.')));
      } else if (outcome == 'REPAIRED') {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.card(Theme.of(context).brightness == Brightness.dark),
            title: Text('Claim Resolved', style: TextStyle(color: AppColors.textPrimary(Theme.of(context).brightness == Brightness.dark))),
            content: Text('Please check your warranty and return coverages and update them if they got extended.', style: TextStyle(color: AppColors.textSecondary(Theme.of(context).brightness == Brightness.dark))),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(color: AppColors.primary)),
              )
            ]
          )
        );
      } else if (outcome == 'REPLACED') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Replacement item created successfully.')));
      }
    } catch (e) {
      logger.e('Error resolving claim: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resolve claim: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _downloadPdf() async {
    if (_claim?.url == null) return;
    try {
      final uri = Uri.parse(_claim!.url!);

      // Try to launch URL
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        if (!mounted) return;
        // If can't launch, offer to copy link instead
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Copy link and paste in browser'),
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _claim!.url!));
              },
            ),
          ),
        );
        return;
      }

      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      logger.e('Error downloading PDF: $e');
      if (!mounted) return;

      // On error, offer to copy link
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Copy link and paste in browser'),
          action: SnackBarAction(
            label: 'Copy',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _claim!.url!));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
          ),
        ),
      );
    }
  }

  Future<void> _sharePdf() async {
    if (_claim?.url == null) return;
    try {
      await Share.share(
        'Check out my warranty claim: ${_claim!.url}',
        subject: 'Warranty Claim PDF - ${_claim!.id}',
      );
    } catch (e) {
      logger.e('Error sharing PDF: $e');
    }
  }

  Future<void> _copyLink() async {
    if (_claim?.url == null) return;
    await Clipboard.setData(ClipboardData(text: _claim!.url!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background(isDark),
        appBar: AppBar(
          title: const Text('Claim Details'),
          backgroundColor: AppColors.card(isDark),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _claim == null) {
      return Scaffold(
        backgroundColor: AppColors.background(isDark),
        appBar: AppBar(
          title: const Text('Claim Details'),
          backgroundColor: AppColors.card(isDark),
          elevation: 0,
        ),
        body: Center(
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
                  'Failed to load claim',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary(isDark),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? 'Claim not found',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary(isDark),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _buildDetailScreen(isDark);
  }

  Widget _buildDetailScreen(bool isDark) {
    final cardColor = AppColors.card(isDark);
    final textColor = AppColors.textPrimary(isDark);
    final secondaryColor = AppColors.textSecondary(isDark);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Claim Details'),
        backgroundColor: AppColors.card(isDark),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Symbols.refresh),
            onPressed: _loadClaim,
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: AppColors.background(isDark),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Symbols.description,
                      color: AppColors.primary,
                      size: 48,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Center(
                child: Text(
                  'Warranty Claim',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              // Claim details card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border(isDark)),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Claim ID', _claim!.id.substring(0, 12) + '...', isDark),
                    const SizedBox(height: 12),
                    _buildDetailRow('Type', _claim!.claimType?.toUpperCase() ?? 'UNKNOWN', isDark),
                    const SizedBox(height: 12),
                    _buildDetailRow('Store', widget.receiptStoreName, isDark),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Status', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary(isDark))),
                        _isUpdating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) :
                        DropdownButton<String>(
                          value: _claim!.status,
                          items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary(isDark))))).toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            if (val == 'RESOLVED') {
                              _showResolutionOutcomeDialog();
                            } else {
                              _updateClaimStatus(val);
                            }
                          },
                          underline: const SizedBox(),
                          alignment: Alignment.centerRight,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Issue Description
              Text('Issue Description', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: secondaryColor, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border(isDark)),
                ),
                child: Text(
                  _claim!.issueDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textColor),
                ),
              ),
              const SizedBox(height: 24),

              // Notes field
              Text('Resolution Notes', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: secondaryColor, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _notesController,
                      maxLines: 3,
                      minLines: 2,
                      enabled: !_isUpdating,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Add tracking numbers, support ticket IDs, or resolution notes...',
                        hintStyle: TextStyle(color: secondaryColor.withValues(alpha: 0.5)),
                        filled: true,
                        fillColor: cardColor,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border(isDark))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isUpdating ? null : _updateClaimNotes,
                    icon: const Icon(Symbols.save),
                    color: AppColors.primary,
                    tooltip: 'Save Notes',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Download link section
              Text(
                'Download Link',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: secondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // URL display (selectable)
                    SelectableText(
                      _claim!.url ?? 'No download link available',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 3,
                      onTap: () {
                        if (_claim!.url != null) {
                          _copyLink();
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Copy button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _claim?.url != null ? _copyLink : null,
                        icon: const Icon(Symbols.content_copy, size: 18),
                        label: const Text('Copy Link'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action buttons
              Text(
                'Actions',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: secondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Download button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _claim?.url != null ? _downloadPdf : null,
                  icon: const Icon(Symbols.file_download),
                  label: const Text('Download PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Share button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _claim?.url != null ? _sharePdf : null,
                  icon: const Icon(Symbols.share),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Info box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Symbols.info,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Download link expires in 1 hour. Save the PDF or screenshot for later access.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true), // Return true to indicate changes may have been made
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.card(isDark),
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.primary),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary(isDark),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textPrimary(isDark),
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
