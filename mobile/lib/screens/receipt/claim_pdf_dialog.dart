import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../core/constants/app_constants.dart';
import '../../services/claim_service.dart';
import '../../core/utils/logger.dart';

/// Dialog for generating warranty claim PDFs
class ClaimPdfDialog extends ConsumerStatefulWidget {
  final String receiptId;
  final String receiptStoreName;

  const ClaimPdfDialog({
    super.key,
    required this.receiptId,
    required this.receiptStoreName,
  });

  @override
  ConsumerState<ClaimPdfDialog> createState() => _ClaimPdfDialogState();
}

class _ClaimPdfDialogState extends ConsumerState<ClaimPdfDialog> {
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

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Claim PDF generated! ID: ${claim.id.substring(0, 8)}...'),
          duration: const Duration(seconds: 3),
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = AppColors.card(isDark);
    final textColor = AppColors.textPrimary(isDark);
    final secondaryColor = AppColors.textSecondary(isDark);

    // If claim has been generated, show success screen
    if (_generatedClaim != null) {
      return AlertDialog(
        backgroundColor: cardColor,
        title: Row(
          children: [
            Icon(
              Symbols.check_circle,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Claim PDF Generated',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Claim ID: ${_generatedClaim!.id.substring(0, 8)}...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: secondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Type: ${_generatedClaim!.claimType ?? "warranty"}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: secondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Store: ${widget.receiptStoreName}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: secondaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
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
                        'PDF is ready for download. Use the link below to access your claim document.',
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _generatedClaim),
            child: const Text('Done'),
          ),
        ],
      );
    }

    // Show claim generation form
    return AlertDialog(
      backgroundColor: cardColor,
      title: Row(
        children: [
          Icon(
            Symbols.description,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Generate Claim PDF',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: textColor,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Issue Description Field
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
              maxLines: 3,
              minLines: 3,
              decoration: InputDecoration(
                hintText: 'E.g., Screen has dead pixels, battery not holding charge...',
                hintStyle: TextStyle(color: secondaryColor.withValues(alpha: 0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border(isDark)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              style: TextStyle(color: textColor),
            ),
            const SizedBox(height: 16),

            // Claim Type Dropdown
            Text(
              'Claim Type',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: secondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedClaimType,
              onChanged: _isLoading
                  ? null
                  : (value) {
                    if (value != null) {
                      setState(() => _selectedClaimType = value);
                    }
                  },
              items: AppConstants.claimTypes
                  .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(
                      type.capitalizeFirst(),
                      style: TextStyle(color: textColor),
                    ),
                  ))
                  .toList(),
              underline: Container(
                height: 1,
                color: AppColors.border(isDark),
              ),
            ),

            // Error message if any
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Symbols.error,
                      color: Colors.red,
                      size: 20,
                    ),
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _generateClaim,
          icon: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                )
              : const Icon(Symbols.file_download),
          label: Text(_isLoading ? 'Generating...' : 'Generate PDF'),
        ),
      ],
    );
  }
}

/// Extension to capitalize first letter of string
extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}
