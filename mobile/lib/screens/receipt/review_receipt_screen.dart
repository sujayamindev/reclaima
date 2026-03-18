import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/receipt_model.dart';
import '../../data/models/receipt_line_item_model.dart';
import '../../providers/receipt_provider.dart';
import '../../widgets/step_progress_bar.dart';
import 'receipt_confirmation_screen.dart';
import 'package:material_symbols_icons/symbols.dart';

class ReviewReceiptScreen extends ConsumerStatefulWidget {
  /// ID of an existing receipt to load from the provider.
  /// Null for new receipts (both OCR and manual-entry paths).
  final String? receiptId;
  final bool isManualEntry;

  /// OCR-extracted data returned by POST /receipts/ocr-extract.
  /// When provided the screen pre-populates the form directly without
  /// polling the receipt provider.
  final Map<String, dynamic>? ocrData;

  /// S3 key of the image uploaded during OCR extract.
  /// Passed through to [ReceiptConfirmationScreen] so the final save can
  /// attach the image to the new receipt record.
  final String? stagingS3Key;

  const ReviewReceiptScreen({
    super.key,
    this.receiptId,
    required this.isManualEntry,
    this.ocrData,
    this.stagingS3Key,
  });

  @override
  ConsumerState<ReviewReceiptScreen> createState() =>
      _ReviewReceiptScreenState();
}

class _ReviewReceiptScreenState extends ConsumerState<ReviewReceiptScreen> {
  // OCR polling
  Timer? _pollTimer;
  int _pollSeconds = 0;
  bool _timedOut = false;
  bool _forceShowForm = false;
  bool _populated = false;

  final _formKey = GlobalKey<FormState>();

  // 📄 Purchase Details
  final _invoiceNumberCtrl = TextEditingController();
  final _storeNameCtrl = TextEditingController();
  DateTime? _purchaseDate;
  final _totalAmountCtrl = TextEditingController();
  final _currencyCtrl = TextEditingController();

  // 🏪 Store Contact
  final _vendorAddressCtrl = TextEditingController();
  final _vendorPhoneCtrl = TextEditingController();
  final _vendorEmailCtrl = TextEditingController();

  // 📦 Product Info
  final _productNameCtrl = TextEditingController();
  String _selectedCategory = 'Electronics';
  List<ReceiptLineItemModel> _lineItems = [];
  /// ID of the primary (first) OCR-generated line item, if one exists.
  /// Used to PATCH the line item rather than the receipt for warranty data.
  String? _primaryLineItemId;

  static const List<String> _categories = [
    'Electronics',
    'Appliances',
    'Clothing & Apparel',
    'Furniture & Home',
    'Automotive',
    'Groceries & Food',
    'Health & Beauty',
    'Sports & Outdoors',
    'Books & Media',
    'Tools & Hardware',
    'Toys & Games',
    'Jewelry & Watches',
    'Office Supplies',
    'Software & Games',
    'Other',
  ];

  // 🛡️ Warranty Info
  final _warrantyPeriodCtrl = TextEditingController();
  DateTime? _warrantyExpiryDate;
  int? _warrantyLeadDaysOverride;
  bool _warrantyReminderEnabled = true;

  // 💵 Return Policy
  final _returnPeriodCtrl = TextEditingController();
  DateTime? _returnExpiryDate;
  int? _returnLeadDaysOverride;
  bool _returnReminderEnabled = true;

  // 📝 Remarks & Notes
  final _remarksCtrl = TextEditingController();
  final _warrantyNotesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.ocrData != null) {
      // OCR data already available — no polling required.
      // _populateFromOcrData() is called inside build() guarded by _populated.
    } else if (!widget.isManualEntry && widget.receiptId != null) {
      _startPolling();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollSeconds = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      _pollSeconds += 3;
      if (_pollSeconds >= 60) {
        _pollTimer?.cancel();
        setState(() => _timedOut = true);
        return;
      }
      ref.invalidate(receiptProvider(widget.receiptId!));
    });
  }

  void _populateFields(ReceiptModel receipt) {
    if (_populated) return;
    _populated = true;

    _invoiceNumberCtrl.text = receipt.invoiceNumber ?? '';
    _storeNameCtrl.text = receipt.storeName ?? '';
    _purchaseDate = receipt.purchaseDate;
    _totalAmountCtrl.text = receipt.totalAmount != null
        ? receipt.totalAmount!.toStringAsFixed(2)
        : '';
    _currencyCtrl.text = receipt.currency ?? 'USD';
    _vendorAddressCtrl.text = receipt.vendorAddress ?? '';
    _vendorPhoneCtrl.text = receipt.vendorPhone ?? '';
    _vendorEmailCtrl.text = receipt.vendorEmail ?? '';
    _remarksCtrl.text = receipt.remarks ?? '';
    _warrantyNotesCtrl.text = receipt.warrantyNotes ?? '';
    _lineItems = receipt.lineItems;

    // Product / warranty fields come from the primary line item
    if (receipt.lineItems.isNotEmpty) {
      final primary = receipt.lineItems.first;
      _primaryLineItemId = primary.id;
      _productNameCtrl.text = primary.productName ?? primary.itemDescription ?? '';
      final ocrCategory = primary.productCategory ?? '';
      _selectedCategory =
          _categories.contains(ocrCategory) ? ocrCategory : 'Electronics';
      _warrantyPeriodCtrl.text = primary.warrantyPeriodMonths?.toString() ?? '';
      _warrantyExpiryDate = primary.warrantyExpiryDate;
      _warrantyLeadDaysOverride = primary.warrantyLeadDaysOverride;
      _returnPeriodCtrl.text = primary.returnPeriodDays?.toString() ?? '';
      _returnExpiryDate = primary.returnExpiryDate;
      _returnLeadDaysOverride = primary.returnLeadDaysOverride;
    } else {
      _primaryLineItemId = null;
      _productNameCtrl.text = '';
      _selectedCategory = 'Electronics';
      _warrantyPeriodCtrl.text = '';
      _returnPeriodCtrl.text = '';
      _warrantyExpiryDate = null;
      _returnExpiryDate = null;
      _warrantyLeadDaysOverride = null;
      _returnLeadDaysOverride = null;
    }
  }

  /// Pre-populate form fields from the OCR extract response map.
  ///
  /// Called once (guarded by [_populated]) from [build()] when [widget.ocrData]
  /// is available.  Unlike [_populateFields], this path requires no DB record —
  /// line items are created as display-only objects from the raw OCR JSON.
  void _populateFromOcrData(Map<String, dynamic> data) {
    if (_populated) return;
    _populated = true;

    _invoiceNumberCtrl.text = (data['invoiceNumber'] as String?) ?? '';
    _storeNameCtrl.text = (data['storeName'] as String?) ?? '';
    final pdStr = data['purchaseDate'] as String?;
    if (pdStr != null) _purchaseDate = DateTime.tryParse(pdStr);
    final rawAmount = data['totalAmount'];
    _totalAmountCtrl.text =
        rawAmount != null ? (rawAmount as num).toStringAsFixed(2) : '';
    _currencyCtrl.text = (data['currency'] as String?) ?? 'USD';
    _vendorAddressCtrl.text = (data['vendorAddress'] as String?) ?? '';
    _vendorPhoneCtrl.text = (data['vendorPhone'] as String?) ?? '';
    _vendorEmailCtrl.text = (data['vendorEmail'] as String?) ?? '';
    _remarksCtrl.text = (data['remarks'] as String?) ?? '';
    _warrantyNotesCtrl.text = (data['warrantyNotes'] as String?) ?? '';

    // Build display-only line items (no DB IDs yet).
    final rawItems = data['lineItems'] as List<dynamic>? ?? [];
    _lineItems = rawItems
        .map((e) => ReceiptLineItemModel.fromOcrExtract(
              e as Map<String, dynamic>,
            ))
        .toList();

    // Primary product info: prefer the first line item, fall back to
    // receipt-level product hint (single-product receipts / mock data).
    _primaryLineItemId = null; // no DB item yet — confirmation screen creates it
    if (_lineItems.isNotEmpty) {
      final first = _lineItems.first;
      _productNameCtrl.text =
          first.productName ?? first.itemDescription ?? '';
      final ocrCategory = first.productCategory ?? '';
      _selectedCategory =
          _categories.contains(ocrCategory) ? ocrCategory : 'Electronics';
      _warrantyPeriodCtrl.text =
          first.warrantyPeriodMonths?.toString() ?? '';
    } else {
      _productNameCtrl.text =
          (data['productName'] as String?) ?? '';
      _warrantyPeriodCtrl.text =
          data['warrantyPeriodMonths']?.toString() ?? '';
    }

    if (_purchaseDate != null) {
      _autoComputeWarrantyExpiry();
      _autoComputeReturnExpiry();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _invoiceNumberCtrl.dispose();
    _storeNameCtrl.dispose();
    _totalAmountCtrl.dispose();
    _currencyCtrl.dispose();
    _vendorAddressCtrl.dispose();
    _vendorPhoneCtrl.dispose();
    _vendorEmailCtrl.dispose();
    _productNameCtrl.dispose();
    _warrantyPeriodCtrl.dispose();
    _returnPeriodCtrl.dispose();
    _remarksCtrl.dispose();
    _warrantyNotesCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T00:00:00';

  String _displayDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _pickDate({
    required DateTime? current,
    required void Function(DateTime) onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => onPicked(picked));
    }
  }

  void _autoComputeWarrantyExpiry() {
    final months = int.tryParse(_warrantyPeriodCtrl.text);
    if (months != null && _purchaseDate != null) {
      setState(() {
        _warrantyExpiryDate = DateTime(
          _purchaseDate!.year,
          _purchaseDate!.month + months,
          _purchaseDate!.day,
        );
      });
    }
  }

  void _autoComputeReturnExpiry() {
    final days = int.tryParse(_returnPeriodCtrl.text);
    if (days != null && _purchaseDate != null) {
      setState(() {
        _returnExpiryDate = _purchaseDate!.add(Duration(days: days));
      });
    }
  }

  void _goToConfirmation() {
    final isValid = _formKey.currentState?.validate() ?? true;
    if (!isValid) return;

    if (_purchaseDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a purchase date.')),
      );
      return;
    }

    // ── Receipt-level fields (go to PATCH /receipts/{id}) ────────────────
    final receiptData = <String, dynamic>{};
    if (_invoiceNumberCtrl.text.isNotEmpty) {
      receiptData['invoiceNumber'] = _invoiceNumberCtrl.text;
    }
    if (_storeNameCtrl.text.isNotEmpty) {
      receiptData['storeName'] = _storeNameCtrl.text;
    }
    if (_purchaseDate != null) {
      receiptData['purchaseDate'] = _formatDate(_purchaseDate!);
    }
    if (_totalAmountCtrl.text.isNotEmpty) {
      final amount = double.tryParse(_totalAmountCtrl.text);
      if (amount != null) receiptData['totalAmount'] = amount;
    }
    if (_currencyCtrl.text.isNotEmpty) {
      receiptData['currency'] = _currencyCtrl.text;
    }
    if (_vendorAddressCtrl.text.isNotEmpty) {
      receiptData['vendorAddress'] = _vendorAddressCtrl.text;
    }
    if (_vendorPhoneCtrl.text.isNotEmpty) {
      receiptData['vendorPhone'] = _vendorPhoneCtrl.text;
    }
    if (_vendorEmailCtrl.text.isNotEmpty) {
      receiptData['vendorEmail'] = _vendorEmailCtrl.text;
    }
    if (_remarksCtrl.text.isNotEmpty) {
      receiptData['remarks'] = _remarksCtrl.text;
    }
    if (_warrantyNotesCtrl.text.isNotEmpty) {
      receiptData['warrantyNotes'] = _warrantyNotesCtrl.text;
    }

    // ── Line-item fields (go to PATCH/POST /receipts/{id}/items/{itemId}) ─
    final lineItemData = <String, dynamic>{};
    if (_productNameCtrl.text.isNotEmpty) {
      lineItemData['productName'] = _productNameCtrl.text;
      // Also keep in receiptData purely for confirmation screen display
      receiptData['productName'] = _productNameCtrl.text;
    }
    if (_selectedCategory.isNotEmpty) {
      lineItemData['productCategory'] = _selectedCategory;
      receiptData['productCategory'] = _selectedCategory;
    }
    if (_warrantyPeriodCtrl.text.isNotEmpty) {
      final months = int.tryParse(_warrantyPeriodCtrl.text);
      if (months != null) {
        lineItemData['warrantyPeriodMonths'] = months;
        receiptData['warrantyPeriodMonths'] = months;
      }
    } else {
      lineItemData['warrantyPeriodMonths'] = null;
    }
    if (_returnPeriodCtrl.text.isNotEmpty) {
      final days = int.tryParse(_returnPeriodCtrl.text);
      if (days != null) {
        lineItemData['returnPeriodDays'] = days;
        receiptData['returnPeriodDays'] = days;
      }
    } else {
      lineItemData['returnPeriodDays'] = null;
    }

    // ── Notification lead time overrides ────────────────────────────────────
    if (_warrantyLeadDaysOverride != null) {
      lineItemData['warrantyLeadDaysOverride'] = _warrantyLeadDaysOverride;
    }
    if (_returnLeadDaysOverride != null) {
      lineItemData['returnLeadDaysOverride'] = _returnLeadDaysOverride;
    }

    // ── Notification reminder on/off ────────────────────────────────────────
    lineItemData['warrantyReminderEnabled'] = _warrantyReminderEnabled;
    lineItemData['returnReminderEnabled'] = _returnReminderEnabled;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptConfirmationScreen(
          receiptId: widget.receiptId,
          isManualEntry: widget.isManualEntry,
          formData: receiptData,
          primaryLineItemId: _primaryLineItemId,
          lineItemData: lineItemData,
          stagingS3Key: widget.stagingS3Key,
          warrantyExpiryDate: _warrantyPeriodCtrl.text.isNotEmpty
              ? _warrantyExpiryDate
              : null,
          returnExpiryDate: _returnPeriodCtrl.text.isNotEmpty
              ? _returnExpiryDate
              : null,
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = AppColors.background(isDark);
    final textPrimary = AppColors.textPrimary(isDark);

    final receiptAsync = widget.receiptId != null
        ? ref.watch(receiptProvider(widget.receiptId!))
        : const AsyncValue<ReceiptModel>.loading();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Symbols.arrow_back, color: textPrimary),
                    padding: const EdgeInsets.all(8),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: const CircleBorder(),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: StepProgressBar(currentStep: 2, totalSteps: 3),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────────
            Expanded(
              child: widget.ocrData != null
                  // ── New OCR path: data already in memory, no polling ────
                  ? _buildBodyFromOcrData(isDark, textPrimary)
                  : widget.receiptId == null
                      // ── Manual entry: empty form ────────────────────────
                      ? _buildFormBody(isDark, textPrimary)
                      : widget.isManualEntry
                          ? _buildFormFromProvider(
                              isDark, textPrimary, receiptAsync)
                          : receiptAsync.when(
                              loading: () =>
                                  _buildRiverpodLoadingBody(textPrimary),
                              error: (e, _) => _buildErrorBody(textPrimary),
                              data: (receipt) {
                                final isProcessing =
                                    receipt.status ==
                                        ReceiptStatus.uploaded ||
                                    receipt.status ==
                                        ReceiptStatus.processing;

                                if (!_forceShowForm &&
                                    isProcessing &&
                                    !_timedOut) {
                                  return _buildOcrLoadingBody(textPrimary);
                                }

                                if (!_forceShowForm &&
                                    _timedOut &&
                                    isProcessing) {
                                  return _buildTimedOutBody(
                                      isDark, textPrimary);
                                }

                                _populateFields(receipt);
                                return _buildFormBody(isDark, textPrimary);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  // For manual entry: we still need the receipt to exist, so watch it
  Widget _buildFormFromProvider(
    bool isDark,
    Color textPrimary,
    AsyncValue<ReceiptModel> receiptAsync,
  ) {
    return receiptAsync.when(
      loading: () => _buildRiverpodLoadingBody(textPrimary),
      error: (e, _) => _buildErrorBody(textPrimary),
      data: (receipt) {
        _populateFields(receipt);
        return _buildFormBody(isDark, textPrimary);
      },
    );
  }

  /// Build the review form using already-available OCR data.
  ///
  /// Pre-populates form controllers and immediately shows the form with an
  /// optional OCR-failed banner when [widget.ocrData] is present.
  Widget _buildBodyFromOcrData(bool isDark, Color textPrimary) {
    // Safe to call in build — guarded by the _populated flag.
    _populateFromOcrData(widget.ocrData!);
    final ocrFailed =
        (widget.ocrData!['ocrStatus'] as String?) == 'failed';
    if (!ocrFailed) {
      return _buildFormBody(isDark, textPrimary);
    }
    // Show a warning banner above the form when OCR couldn't read the image.
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            border: Border.all(
                color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Symbols.warning,
                  color: AppColors.error, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Could not read receipt — please check the details below.',
                  style: AppTextStyles.bodyXSmall.copyWith(
                    color: AppColors.error,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildFormBody(isDark, textPrimary)),
      ],
    );
  }

  // ─── State bodies ─────────────────────────────────────────────────────────

  Widget _buildRiverpodLoadingBody(Color textPrimary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
          const SizedBox(height: 20),
          Text('Loading…', style: TextStyle(color: textPrimary, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildOcrLoadingBody(Color textPrimary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Analyzing your receipt…',
              style: TextStyle(
                color: textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Our AI is extracting text and data\nfrom your document.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textPrimary.withValues(alpha: 0.6),
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            TextButton.icon(
              onPressed: () {
                _pollTimer?.cancel();
                setState(() {
                  _pollSeconds = 0;
                  _timedOut = false;
                });
                ref.invalidate(receiptProvider(widget.receiptId!));
                _startPolling();
              },
              icon: const Icon(Symbols.refresh, size: 16),
              label: const Text('Refresh'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimedOutBody(bool isDark, Color textPrimary) {
    final cardColor = AppColors.card(isDark);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Symbols.timer_off,
                size: 48,
                color: AppColors.warning,
              ),
              const SizedBox(height: 16),
              Text(
                'Taking longer than expected',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'OCR processing is still in progress. You can wait, refresh, or fill in the details manually.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textPrimary.withValues(alpha: 0.6),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _timedOut = false;
                      _pollSeconds = 0;
                    });
                    ref.invalidate(receiptProvider(widget.receiptId!));
                    _startPolling();
                  },
                  icon: const Icon(Symbols.refresh, size: 18),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLarge,
                      ),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  _pollTimer?.cancel();
                  setState(() {
                    _timedOut = false;
                    _forceShowForm = true;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: textPrimary.withValues(alpha: 0.5),
                ),
                child: const Text('Fill in manually instead'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBody(Color textPrimary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Symbols.error, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load receipt data.',
              style: TextStyle(
                color: textPrimary.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () =>
                  ref.invalidate(receiptProvider(widget.receiptId!)),
              icon: const Icon(Symbols.refresh, size: 16),
              label: const Text('Retry'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Form body ────────────────────────────────────────────────────────────

  Widget _buildFormBody(bool isDark, Color textPrimary) {
    return Column(
      children: [
        // Hero - Fixed at top
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Review Details',
                style: AppTextStyles.headingSmall.copyWith(color: textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                widget.isManualEntry || _forceShowForm
                    ? 'Enter your receipt details below.'
                    : 'Check and correct any extracted data.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: textPrimary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Purchase Details
                  _buildSection(
                    isDark: isDark,
                    textPrimary: textPrimary,
                    title: 'Purchase Details',
                    icon: Symbols.receipt_long,
                    iconColor: AppColors.primary,
                    children: [
                      _buildTextField(
                        isDark: isDark,
                        label: 'Invoice No.',
                        controller: _invoiceNumberCtrl,
                        hint: 'e.g. INV-00123',
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        isDark: isDark,
                        label: 'Store Name',
                        controller: _storeNameCtrl,
                        hint: 'e.g. Best Buy',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Store name is required'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _buildDateField(
                        isDark: isDark,
                        label: 'Purchase Date',
                        value: _purchaseDate,
                        hint: 'Select date',
                        onTap: () => _pickDate(
                          current: _purchaseDate,
                          onPicked: (d) {
                            _purchaseDate = d;
                            _autoComputeWarrantyExpiry();
                            _autoComputeReturnExpiry();
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildTextField(
                              isDark: isDark,
                              label: 'Total Amount',
                              controller: _totalAmountCtrl,
                              hint: '0.00',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: _buildTextField(
                              isDark: isDark,
                              label: 'Currency',
                              controller: _currencyCtrl,
                              hint: 'USD',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Store Contact
                  _buildSection(
                    isDark: isDark,
                    textPrimary: textPrimary,
                    title: 'Store Contact',
                    icon: Symbols.store,
                    iconColor: AppColors.primary,
                    children: [
                      _buildTextField(
                        isDark: isDark,
                        label: 'Address',
                        controller: _vendorAddressCtrl,
                        hint: 'e.g. 123 Main St, City',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        isDark: isDark,
                        label: 'Phone',
                        controller: _vendorPhoneCtrl,
                        hint: 'e.g. +94 77 123 4567',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        isDark: isDark,
                        label: 'Email',
                        controller: _vendorEmailCtrl,
                        hint: 'e.g. info@store.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Product Info
                  _buildSection(
                    isDark: isDark,
                    textPrimary: textPrimary,
                    title: 'Product Info',
                    icon: Symbols.inventory_2,
                    iconColor: AppColors.primary,
                    children: [
                      _buildTextField(
                        isDark: isDark,
                        label: 'Product Name',
                        controller: _productNameCtrl,
                        hint: 'e.g. MacBook Pro 14"',
                      ),
                      const SizedBox(height: 14),
                      _buildCategoryDropdown(isDark: isDark),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Items (read-only, from OCR line items)
                  if (_lineItems.isNotEmpty)
                    _buildLineItemsCard(isDark, textPrimary),
                  if (_lineItems.isNotEmpty) const SizedBox(height: 16),

                  // Warranty Info
                  _buildSection(
                    isDark: isDark,
                    textPrimary: textPrimary,
                    title: 'Warranty Info',
                    icon: Symbols.verified,
                    iconColor: AppColors.primary,
                    children: [
                      _buildTextField(
                        isDark: isDark,
                        label: 'Warranty Period (months)',
                        controller: _warrantyPeriodCtrl,
                        hint: 'e.g. 12',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (_) => _autoComputeWarrantyExpiry(),
                      ),
                      const SizedBox(height: 14),
                      _buildLeadTimeDropdown(
                        isDark: isDark,
                        label: 'Remind me before warranty expires (optional)',
                        hint: 'Default: use my default setting',
                        options: const [7, 14, 30, 60, 90],
                        selectedValue: _warrantyLeadDaysOverride,
                        reminderEnabled: _warrantyReminderEnabled,
                        onChanged: (value) =>
                            setState(() => _warrantyLeadDaysOverride = value),
                        onReminderEnabledChanged: (value) =>
                            setState(() => _warrantyReminderEnabled = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Return Policy
                  _buildSection(
                    isDark: isDark,
                    textPrimary: textPrimary,
                    title: 'Return Policy',
                    icon: Symbols.assignment_return,
                    iconColor: AppColors.primary,
                    children: [
                      _buildTextField(
                        isDark: isDark,
                        label: 'Return Period (days)',
                        controller: _returnPeriodCtrl,
                        hint: 'e.g. 30',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (_) => _autoComputeReturnExpiry(),
                      ),
                      const SizedBox(height: 14),
                      _buildLeadTimeDropdown(
                        isDark: isDark,
                        label: 'Remind me before return deadline (optional)',
                        hint: 'Default: use my default setting',
                        options: const [1, 2, 3, 5, 7],
                        selectedValue: _returnLeadDaysOverride,
                        reminderEnabled: _returnReminderEnabled,
                        onChanged: (value) =>
                            setState(() => _returnLeadDaysOverride = value),
                        onReminderEnabledChanged: (value) =>
                            setState(() => _returnReminderEnabled = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Remarks & Notes
                  _buildSection(
                    isDark: isDark,
                    textPrimary: textPrimary,
                    title: 'Remarks & Notes',
                    icon: Symbols.notes,
                    iconColor: AppColors.primary,
                    children: [
                      _buildTextField(
                        isDark: isDark,
                        label: 'Remarks',
                        controller: _remarksCtrl,
                        hint: 'Any additional remarks from the receipt',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        isDark: isDark,
                        label: 'Warranty Notes',
                        controller: _warrantyNotesCtrl,
                        hint: 'Warranty terms and conditions',
                        maxLines: 5,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Footer ────────────────────────────────────────────────────────
        _buildSaveFooter(isDark),
      ],
    );
  }

  // ─── Section card ─────────────────────────────────────────────────────────

  Widget _buildSection({
    required bool isDark,
    required Color textPrimary,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    final cardColor = AppColors.card(isDark);
    final borderColor = AppColors.border(isDark);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTextStyles.sectionTitle.copyWith(color: textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // ─── Field helpers ────────────────────────────────────────────────────────

  Widget _buildTextField({
    required bool isDark,
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    final textPrimary = AppColors.textPrimary(isDark);
    final labelColor = AppColors.label(isDark);
    final borderColor = AppColors.border(isDark);
    final fillColor = AppColors.card(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.formLabel.copyWith(
            color: labelColor.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          validator: validator,
          maxLines: maxLines,
          style: TextStyle(
            color: textPrimary,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: labelColor.withValues(alpha: 0.5)),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(maxLines > 1 ? 12 : 24),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(maxLines > 1 ? 12 : 24),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(maxLines > 1 ? 12 : 24),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(maxLines > 1 ? 12 : 24),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(maxLines > 1 ? 12 : 24),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown({required bool isDark}) {
    final labelColor = AppColors.label(isDark);
    final borderColor = AppColors.border(isDark);
    final fillColor = AppColors.card(isDark);
    final textPrimary = AppColors.textPrimary(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: AppTextStyles.formLabel.copyWith(
            color: labelColor.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          dropdownColor: AppColors.card(isDark),
          style: TextStyle(color: textPrimary, fontSize: 15),
          icon: Icon(
            Symbols.keyboard_arrow_down,
            color: labelColor,
            size: 20,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          items: _categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _selectedCategory = value);
          },
        ),
      ],
    );
  }

  /// Custom notification lead time chip selector (optional override)
  Widget _buildLeadTimeDropdown({
    required bool isDark,
    required String label,
    required String hint,
    required List<int> options,
    required int? selectedValue,
    required bool reminderEnabled,
    required ValueChanged<int?> onChanged,
    required ValueChanged<bool> onReminderEnabledChanged,
  }) {
    final labelColor = AppColors.label(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.formLabel.copyWith(
            color: labelColor.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // "Off" option
            GestureDetector(
              onTap: () {
                onReminderEnabledChanged(false);
                onChanged(null);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: !reminderEnabled
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusPill),
                  border: Border.all(
                    color: !reminderEnabled
                        ? AppColors.primary
                        : AppColors.border(isDark),
                  ),
                ),
                child: Text(
                  'Off',
                  style: TextStyle(
                    fontSize: 13,
                    color: !reminderEnabled
                        ? AppColors.primary
                        : labelColor.withValues(alpha: 0.7),
                    fontWeight:
                        !reminderEnabled ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
            // "Use default" option
            GestureDetector(
              onTap: () {
                onReminderEnabledChanged(true);
                onChanged(null);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: reminderEnabled && selectedValue == null
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusPill),
                  border: Border.all(
                    color: reminderEnabled && selectedValue == null
                        ? AppColors.primary
                        : AppColors.border(isDark),
                  ),
                ),
                child: Text(
                  'Use default',
                  style: TextStyle(
                    fontSize: 13,
                    color: reminderEnabled && selectedValue == null
                        ? AppColors.primary
                        : labelColor.withValues(alpha: 0.7),
                    fontWeight:
                        reminderEnabled && selectedValue == null ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
            // Custom options
            ...options.map((days) {
              final isSelected = reminderEnabled && days == selectedValue;
              return GestureDetector(
                onTap: () {
                  onReminderEnabledChanged(true);
                  onChanged(days);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusPill),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border(isDark),
                    ),
                  ),
                  child: Text(
                    '$days days',
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected
                          ? AppColors.primary
                          : labelColor.withValues(alpha: 0.7),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  /// Read-only card showing OCR-extracted line items (product code, qty, etc.)
  Widget _buildLineItemsCard(bool isDark, Color textPrimary) {
    final cardColor = AppColors.card(isDark);
    final borderColor = AppColors.border(isDark);
    final labelColor = AppColors.label(isDark);
    final headerStyle = AppTextStyles.tableHeader.copyWith(color: labelColor);
    const cellStyle = TextStyle(fontSize: 13);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Symbols.shopping_cart,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Items Purchased',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                ),
                child: Text(
                  '${_lineItems.length} item${_lineItems.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Extracted from receipt — edit via Receipt Details if needed.',
            style: TextStyle(
              fontSize: 11,
              color: labelColor,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          // Table header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('Description', style: headerStyle),
                ),
                SizedBox(width: 52, child: Text('Code', style: headerStyle)),
                SizedBox(
                  width: 36,
                  child: Text(
                    'Qty',
                    style: headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    'Amount',
                    style: headerStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 8, color: borderColor),
          // Item rows
          ..._lineItems.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(item.itemDescription ?? '—', style: cellStyle),
                  ),
                  SizedBox(
                    width: 52,
                    child: Text(
                      item.productCode ?? '—',
                      style: TextStyle(
                        fontSize: 11,
                        color: labelColor,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      item.quantity ?? '—',
                      style: cellStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: 72,
                    child: Text(
                      item.amount != null
                          ? item.amount!.toStringAsFixed(2)
                          : '—',
                      style: cellStyle.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.right,
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

  Widget _buildDateField({
    required bool isDark,
    required String label,
    required DateTime? value,
    required String hint,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final textPrimary = AppColors.textPrimary(isDark);
    final labelColor = AppColors.label(isDark);
    final borderColor = AppColors.border(isDark);
    final fillColor = AppColors.card(isDark);

    final displayText = value != null ? _displayDate(value) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.formLabel.copyWith(
            color: labelColor.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayText ?? hint,
                    style: TextStyle(
                      color: displayText != null
                          ? textPrimary
                          : labelColor.withValues(alpha: 0.5),
                      fontSize: 15,
                    ),
                  ),
                ),
                if (value != null && onClear != null)
                  GestureDetector(
                    onTap: onClear,
                    child: Icon(Symbols.close, size: 16, color: labelColor),
                  )
                else
                  Icon(
                    Symbols.calendar_today,
                    size: 16,
                    color: labelColor,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Save footer ──────────────────────────────────────────────────────────

  Widget _buildSaveFooter(bool isDark) {
    final backgroundColor = AppColors.background(isDark);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(color: backgroundColor),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _goToConfirmation,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.onPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 17),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Continue',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
