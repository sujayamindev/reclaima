import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../services/claim_service.dart';
import '../../core/utils/logger.dart';

/// Screen for generating and managing warranty claim PDFs
class ClaimPdfScreen extends ConsumerStatefulWidget {
  final String receiptId;
  final String receiptStoreName;

  const ClaimPdfScreen({
    super.key,
    required this.receiptId,
    required this.receiptStoreName,
  });

  @override
  ConsumerState<ClaimPdfScreen> createState() => _ClaimPdfScreenState();
}

class _ClaimPdfScreenState extends ConsumerState<ClaimPdfScreen> {
  late final TextEditingController _issueController = TextEditingController();
  String _selectedClaimType = 'warranty';
  bool _isLoading = false;
  ClaimDocumentResponse? _generatedClaim;
  String? _error;

  @override
  void dispose() {
    _issueController.dispose();
    super.dispose();
  }

  Future<void> _generateClaim() async {
    // Validate input
    if (_issueController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the issue')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      logger.i('Generating claim PDF...');
      final claimService = ref.read(claimServiceProvider);

      final claim = await claimService.generateClaimPdf(
        receiptId: widget.receiptId,
        issueDescription: _issueController.text,
        claimType: _selectedClaimType,
      );

      logger.i('Claim PDF generated successfully: ${claim.id}');

      setState(() {
        _generatedClaim = claim;
      });
    } catch (e) {
      logger.e('Error generating claim: $e');
      setState(() {
        _error = e.toString();
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate claim: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _downloadPdf() async {
    if (_generatedClaim?.url == null) return;
    try {
      if (await canLaunchUrl(Uri.parse(_generatedClaim!.url!))) {
        await launchUrl(
          Uri.parse(_generatedClaim!.url!),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      logger.e('Error downloading PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download: $e')),
      );
    }
  }

  Future<void> _sharePdf() async {
    if (_generatedClaim?.url == null) return;
    try {
      await Share.share(
        'Check out my warranty claim: ${_generatedClaim!.url}',
        subject: 'Warranty Claim PDF - ${_generatedClaim!.id}',
      );
    } catch (e) {
      logger.e('Error sharing PDF: $e');
    }
  }

  Future<void> _copyLink() async {
    if (_generatedClaim?.url == null) return;
    await Clipboard.setData(ClipboardData(text: _generatedClaim!.url!));
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

    if (_generatedClaim != null) {
      return _buildSuccessScreen(isDark);
    }

    return _buildFormScreen(isDark);
  }

  Widget _buildFormScreen(bool isDark) {
    final cardColor = AppColors.card(isDark);
    final textColor = AppColors.textPrimary(isDark);
    final secondaryColor = AppColors.textSecondary(isDark);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Claim PDF'),
        backgroundColor: AppColors.card(isDark),
        elevation: 0,
      ),
      backgroundColor: AppColors.background(isDark),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
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
                      child: Text(
                        widget.receiptStoreName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Issue description
              Text(
                'Issue Description *',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: secondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _issueController,
                enabled: !_isLoading,
                maxLines: 4,
                minLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe the issue or reason for the claim...\n\nE.g., Screen has dead pixels, battery not holding charge, product damaged on arrival',
                  hintStyle: TextStyle(color: secondaryColor.withValues(alpha: 0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border(isDark)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: cardColor,
                ),
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 24),

              // Claim type
              Text(
                'Claim Type',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: secondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border(isDark)),
                  borderRadius: BorderRadius.circular(12),
                  color: cardColor,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedClaimType,
                  onChanged: _isLoading ? null : (value) {
                    if (value != null) {
                      setState(() => _selectedClaimType = value);
                    }
                  },
                  underline: const SizedBox(),
                  items: AppConstants.claimTypes
                      .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(
                          type.replaceFirst(
                            type[0],
                            type[0].toUpperCase(),
                          ),
                          style: TextStyle(color: textColor),
                        ),
                      ))
                      .toList(),
                ),
              ),

              // Error message
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Symbols.error, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Generate button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generateClaim,
                  icon: _isLoading
                      ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      )
                      : const Icon(Symbols.file_download),
                  label: Text(
                    _isLoading ? 'Generating PDF...' : 'Generate PDF',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen(bool isDark) {
    final cardColor = AppColors.card(isDark);
    final textColor = AppColors.textPrimary(isDark);
    final secondaryColor = AppColors.textSecondary(isDark);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Claim PDF Generated'),
        backgroundColor: AppColors.card(isDark),
        elevation: 0,
      ),
      backgroundColor: AppColors.background(isDark),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Success icon
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
                      Symbols.check_circle,
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
                  'Claim PDF Ready!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Center(
                child: Text(
                  'Your warranty claim document has been generated',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: secondaryColor,
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
                    _buildDetailRow('Claim ID', _generatedClaim!.id.substring(0, 12) + '...', isDark),
                    const SizedBox(height: 12),
                    _buildDetailRow('Type', _generatedClaim!.claimType?.toUpperCase() ?? 'UNKNOWN', isDark),
                    const SizedBox(height: 12),
                    _buildDetailRow('Store', widget.receiptStoreName, isDark),
                  ],
                ),
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
                      _generatedClaim!.url ?? 'No download link available',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 3,
                      onTap: () {
                        if (_generatedClaim!.url != null) {
                          _copyLink();
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Copy button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _generatedClaim?.url != null ? _copyLink : null,
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
                  onPressed: _generatedClaim?.url != null ? _downloadPdf : null,
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
                  onPressed: _generatedClaim?.url != null ? _sharePdf : null,
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
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.card(isDark),
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.primary),
                ),
              ),
              child: const Text(
                'Back to Receipt',
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
