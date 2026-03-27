import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/receipt_model.dart';
import '../../data/models/receipt_line_item_model.dart';
import '../../providers/receipt_provider.dart';
import '../../widgets/step_progress_bar.dart';
import '../../widgets/app_primary_button.dart';
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

class LineItemFormState {
  final TextEditingController productNameCtrl = TextEditingController();
  final TextEditingController productCodeCtrl = TextEditingController();
  String selectedCategory = 'Electronics';

  String? quantity;
  double? unitPrice;
  double? amount;
  String? itemDescription;
  
  final TextEditingController warrantyPeriodCtrl = TextEditingController();
  DateTime? warrantyExpiryDate;
  int? warrantyLeadDaysOverride;
  bool warrantyReminderEnabled = true;

  final TextEditingController returnPeriodCtrl = TextEditingController();
  DateTime? returnExpiryDate;
  int? returnLeadDaysOverride;
  bool returnReminderEnabled = true;

  String? existingId;

  void dispose() {
    productNameCtrl.dispose();
    productCodeCtrl.dispose();
    warrantyPeriodCtrl.dispose();
    returnPeriodCtrl.dispose();
  }
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

  // 📦 Line Items Form State
  List<LineItemFormState> _itemForms = [LineItemFormState()];
  List<ReceiptLineItemModel> _ocrLineItems = [];

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
    _ocrLineItems = receipt.lineItems;

    if (receipt.lineItems.isNotEmpty) {
      _itemForms.clear();
      for (final item in receipt.lineItems) {
        final form = LineItemFormState();
        form.existingId = item.id;
        form.itemDescription = item.itemDescription;
        form.quantity = item.quantity;
        form.unitPrice = item.unitPrice;
        form.amount = item.amount;
        form.productNameCtrl.text = item.productName ?? item.itemDescription ?? '';
        form.productCodeCtrl.text = item.productCode ?? '';
        final cat = item.productCategory ?? '';
        form.selectedCategory = _categories.contains(cat) ? cat : 'Electronics';
        form.warrantyPeriodCtrl.text = item.warrantyPeriodMonths?.toString() ?? '';
        form.warrantyExpiryDate = item.warrantyExpiryDate;
        form.warrantyLeadDaysOverride = item.warrantyLeadDaysOverride;
        form.warrantyReminderEnabled = item.warrantyReminderEnabled ?? true;
        form.returnPeriodCtrl.text = item.returnPeriodDays?.toString() ?? '';
        form.returnExpiryDate = item.returnExpiryDate;
        form.returnLeadDaysOverride = item.returnLeadDaysOverride;
        form.returnReminderEnabled = item.returnReminderEnabled ?? true;
        _itemForms.add(form);
      }
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
    _totalAmountCtrl.text = rawAmount != null
        ? (rawAmount as num).toStringAsFixed(2)
        : '';
    _currencyCtrl.text = (data['currency'] as String?) ?? 'USD';
    _vendorAddressCtrl.text = (data['vendorAddress'] as String?) ?? '';
    _vendorPhoneCtrl.text = (data['vendorPhone'] as String?) ?? '';
    _vendorEmailCtrl.text = (data['vendorEmail'] as String?) ?? '';
    _remarksCtrl.text = (data['remarks'] as String?) ?? '';
    _warrantyNotesCtrl.text = (data['warrantyNotes'] as String?) ?? '';

    final rawItems = data['lineItems'] as List<dynamic>? ?? [];
    _ocrLineItems = rawItems
        .map(
          (e) => ReceiptLineItemModel.fromOcrExtract(e as Map<String, dynamic>),
        )
        .toList();
    
    if (_ocrLineItems.isNotEmpty) {
      _itemForms.clear();
      for (final item in _ocrLineItems) {
        final form = LineItemFormState();
        form.itemDescription = item.itemDescription;
        form.quantity = item.quantity;
        form.unitPrice = item.unitPrice;
        form.amount = item.amount;
        form.productNameCtrl.text = item.productName ?? item.itemDescription ?? '';
        form.productCodeCtrl.text = item.productCode ?? '';
        final cat = item.productCategory ?? '';
        form.selectedCategory = _categories.contains(cat) ? cat : 'Electronics';
        form.warrantyPeriodCtrl.text = item.warrantyPeriodMonths?.toString() ?? '';
        _itemForms.add(form);
      }
    } else {
      _itemForms.first.productNameCtrl.text = (data['productName'] as String?) ?? '';
      _itemForms.first.warrantyPeriodCtrl.text = data['warrantyPeriodMonths']?.toString() ?? '';
    }

    if (_purchaseDate != null) {
      for (int i = 0; i < _itemForms.length; i++) {
        _autoComputeWarrantyExpiry(i);
        _autoComputeReturnExpiry(i);
      }
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
    for (var form in _itemForms) { form.dispose(); }
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

  void _autoComputeWarrantyExpiry(int index) {
    if (index >= _itemForms.length) return;
    final form = _itemForms[index];
    final months = int.tryParse(form.warrantyPeriodCtrl.text);
    if (months != null && _purchaseDate != null) {
      setState(() {
        form.warrantyExpiryDate = DateTime(
          _purchaseDate!.year,
          _purchaseDate!.month + months,
          _purchaseDate!.day,
        );
      });
    } else {
      setState(() {
        form.warrantyExpiryDate = null;
      });
    }
  }

  void _autoComputeReturnExpiry(int index) {
    if (index >= _itemForms.length) return;
    final form = _itemForms[index];
    final days = int.tryParse(form.returnPeriodCtrl.text);
    if (days != null && _purchaseDate != null) {
      setState(() {
        form.returnExpiryDate = _purchaseDate!.add(Duration(days: days));
      });
    } else {
      setState(() {
        form.returnExpiryDate = null;
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
    final invoiceNumber = _invoiceNumberCtrl.text.trim();
    if (invoiceNumber.isNotEmpty) {
      receiptData['invoiceNumber'] = invoiceNumber;
    }
    final storeName = _storeNameCtrl.text.trim();
    if (storeName.isNotEmpty) {
      receiptData['storeName'] = storeName;
    }
    if (_purchaseDate != null) {
      receiptData['purchaseDate'] = _formatDate(_purchaseDate!);
    }
    final totalAmountText = _totalAmountCtrl.text.trim();
    if (totalAmountText.isNotEmpty) {
      final amount = double.tryParse(totalAmountText);
      if (amount != null) receiptData['totalAmount'] = amount;
    }
    final currency = _currencyCtrl.text.trim();
    if (currency.isNotEmpty) {
      receiptData['currency'] = currency;
    }
    final vendorAddress = _vendorAddressCtrl.text.trim();
    if (vendorAddress.isNotEmpty) {
      receiptData['vendorAddress'] = vendorAddress;
    }
    final vendorPhone = _vendorPhoneCtrl.text.trim();
    if (vendorPhone.isNotEmpty) {
      receiptData['vendorPhone'] = vendorPhone;
    }
    final vendorEmail = _vendorEmailCtrl.text.trim();
    if (vendorEmail.isNotEmpty) {
      receiptData['vendorEmail'] = vendorEmail;
    }
    final remarks = _remarksCtrl.text.trim();
    if (remarks.isNotEmpty) {
      receiptData['remarks'] = remarks;
    }
    final warrantyNotes = _warrantyNotesCtrl.text.trim();
    if (warrantyNotes.isNotEmpty) {
      receiptData['warrantyNotes'] = warrantyNotes;
    }

    final List<Map<String, dynamic>> itemsPayload = [];
    for (final form in _itemForms) {
        final liData = <String, dynamic>{};
        if (form.existingId != null) liData['_existingId'] = form.existingId;
        if (form.itemDescription != null) liData['itemDescription'] = form.itemDescription;
        if (form.quantity != null) liData['quantity'] = form.quantity;
        if (form.unitPrice != null) liData['unitPrice'] = form.unitPrice;
        if (form.amount != null) liData['amount'] = form.amount;
        
        final productName = form.productNameCtrl.text.trim();
        if (productName.isNotEmpty) liData['productName'] = productName;
        
        final productCode = form.productCodeCtrl.text.trim();
        if (productCode.isNotEmpty) liData['productCode'] = productCode;
        
        liData['productCategory'] = form.selectedCategory;
        
        if (form.warrantyPeriodCtrl.text.isNotEmpty) {
            final months = int.tryParse(form.warrantyPeriodCtrl.text);
            if (months != null) liData['warrantyPeriodMonths'] = months;
        } else {
            liData['warrantyPeriodMonths'] = null;
        }
        
        if (form.returnPeriodCtrl.text.isNotEmpty) {
            final days = int.tryParse(form.returnPeriodCtrl.text);
            if (days != null) liData['returnPeriodDays'] = days;
        } else {
            liData['returnPeriodDays'] = null;
        }
        
        if (form.warrantyLeadDaysOverride != null) liData['warrantyLeadDaysOverride'] = form.warrantyLeadDaysOverride;
        if (form.returnLeadDaysOverride != null) liData['returnLeadDaysOverride'] = form.returnLeadDaysOverride;
        liData['warrantyReminderEnabled'] = form.warrantyReminderEnabled;
        liData['returnReminderEnabled'] = form.returnReminderEnabled;
        itemsPayload.add(liData);
    }
    
    // Pass the first item's name to receiptData for display
    if (itemsPayload.isNotEmpty && itemsPayload.first['productName'] != null) {
        receiptData['productName'] = itemsPayload.first['productName'];
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptConfirmationScreen(
          receiptId: widget.receiptId,
          isManualEntry: widget.isManualEntry,
          formData: receiptData,
          itemsPayload: itemsPayload,
          itemForms: _itemForms, // Pass for UI logic
          stagingS3Key: widget.stagingS3Key,
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
                    icon: Icon(Symbols.arrow_back_rounded, color: textPrimary),
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
                  ? _buildFormFromProvider(isDark, textPrimary, receiptAsync)
                  : receiptAsync.when(
                      loading: () => _buildRiverpodLoadingBody(textPrimary),
                      error: (e, _) => _buildErrorBody(textPrimary),
                      data: (receipt) {
                        final isProcessing =
                            receipt.status == ReceiptStatus.uploaded ||
                            receipt.status == ReceiptStatus.processing;

                        if (!_forceShowForm && isProcessing && !_timedOut) {
                          return _buildOcrLoadingBody(textPrimary);
                        }

                        if (!_forceShowForm && _timedOut && isProcessing) {
                          return _buildTimedOutBody(isDark, textPrimary);
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
    final ocrFailed = (widget.ocrData!['ocrStatus'] as String?) == 'failed';
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
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Symbols.warning_rounded, color: AppColors.error, size: AppDimensions.iconMedium),
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
          Text(
            'Loading…',
            style: AppTextStyles.bodyMedium.copyWith(color: textPrimary),
          ),
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
              style: AppTextStyles.headingMedium.copyWith(color: textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              'Our AI is extracting text and data\nfrom your document.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: textPrimary.withValues(alpha: 0.6),
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
              icon: const Icon(Symbols.refresh_rounded, size: AppDimensions.iconSmall),
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
              const Icon(Symbols.timer_off_rounded, size: AppDimensions.iconXL, color: AppColors.warning),
              const SizedBox(height: 16),
              Text(
                'Taking longer than expected',
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge.copyWith(color: textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'OCR processing is still in progress. You can wait, refresh, or fill in the details manually.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: textPrimary.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              AppPrimaryButton(
                onPressed: () {
                  setState(() {
                    _timedOut = false;
                    _pollSeconds = 0;
                  });
                  ref.invalidate(receiptProvider(widget.receiptId!));
                  _startPolling();
                },
                icon: const Icon(Symbols.refresh_rounded, size: AppDimensions.iconMedium),
                text: 'Refresh',
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
            const Icon(Symbols.error_rounded, size: AppDimensions.iconXL, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: AppTextStyles.titleLarge.copyWith(color: textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load receipt data.',
              style: AppTextStyles.bodySmall.copyWith(
                color: textPrimary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () =>
                  ref.invalidate(receiptProvider(widget.receiptId!)),
              icon: const Icon(Symbols.refresh_rounded, size: AppDimensions.iconSmall),
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
                    icon: Symbols.receipt_long_rounded,
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
                            for (int i = 0; i < _itemForms.length; i++) {
                              _autoComputeWarrantyExpiry(i);
                              _autoComputeReturnExpiry(i);
                            }
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
                    icon: Symbols.store_rounded,
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
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9+\- ()]'),
                          ),
                        ],
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

                  // Items (read-only, from OCR line items)
                  if (_ocrLineItems.isNotEmpty)
                    _buildLineItemsCard(isDark, textPrimary),
                  if (_ocrLineItems.isNotEmpty) const SizedBox(height: 16),

                  ...List.generate(_itemForms.length, (index) {
                      final form = _itemForms[index];
                      return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                              color: AppColors.card(isDark).withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                              border: Border.all(color: AppColors.border(isDark)),
                          ),
                          child: Column(
                              children: [
                                  Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                              Text('Item ${index + 1}', style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary(isDark))),
                                              if (_itemForms.length > 1) 
                                                IconButton(
                                                    icon: const Icon(Symbols.delete_rounded, color: AppColors.error),
                                                    onPressed: () {
                                                        setState(() { _itemForms.removeAt(index); });
                                                    }
                                                )
                                          ]
                                      )
                                  ),
                                  // Product Info
                                  _buildSection(
                                    isDark: isDark,
                                    textPrimary: textPrimary,
                                    title: 'Product Info',
                                    icon: Symbols.inventory_2_rounded,
                                    iconColor: AppColors.primary,
                                    children: [
                                      _buildTextField(
                                        isDark: isDark,
                                        label: 'Product Name',
                                        controller: form.productNameCtrl,
                                        hint: 'e.g. MacBook Pro 14"',
                                        validator: (v) => (v == null || v.trim().isEmpty)
                                            ? 'Product name is required'
                                            : null,
                                      ),
                                      const SizedBox(height: 14),
                                      _buildTextField(
                                        isDark: isDark,
                                        label: 'SKU / Product Code',
                                        controller: form.productCodeCtrl,
                                        hint: 'e.g. MK1234',
                                      ),
                                      const SizedBox(height: 14),
                                      _buildCategoryDropdown(isDark: isDark, form: form),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Warranty Info
                                  _buildSection(
                                    isDark: isDark,
                                    textPrimary: textPrimary,
                                    title: 'Warranty Info',
                                    icon: Symbols.verified_rounded,
                                    iconColor: AppColors.primary,
                                    children: [
                                      _buildTextField(
                                        isDark: isDark,
                                        label: 'Warranty Period (months)',
                                        controller: form.warrantyPeriodCtrl,
                                        hint: 'e.g. 12',
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                        onChanged: (_) => _autoComputeWarrantyExpiry(index),
                                      ),
                                      const SizedBox(height: 14),
                                      _buildLeadTimeDropdown(
                                        isDark: isDark,
                                        label: 'Remind me before warranty expires (optional)',
                                        hint: 'Default: use my default setting',
                                        options: const [7, 14, 30, 60, 90],
                                        selectedValue: form.warrantyLeadDaysOverride,
                                        reminderEnabled: form.warrantyReminderEnabled,
                                        onChanged: (value) =>
                                            setState(() => form.warrantyLeadDaysOverride = value),
                                        onReminderEnabledChanged: (value) =>
                                            setState(() => form.warrantyReminderEnabled = value),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Return Policy
                                  _buildSection(
                                    isDark: isDark,
                                    textPrimary: textPrimary,
                                    title: 'Return Policy',
                                    icon: Symbols.assignment_return_rounded,
                                    iconColor: AppColors.primary,
                                    children: [
                                      _buildTextField(
                                        isDark: isDark,
                                        label: 'Return Period (days)',
                                        controller: form.returnPeriodCtrl,
                                        hint: 'e.g. 30',
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                        onChanged: (_) => _autoComputeReturnExpiry(index),
                                      ),
                                      const SizedBox(height: 14),
                                      _buildLeadTimeDropdown(
                                        isDark: isDark,
                                        label: 'Remind me before return deadline (optional)',
                                        hint: 'Default: use my default setting',
                                        options: const [1, 2, 3, 5, 7],
                                        selectedValue: form.returnLeadDaysOverride,
                                        reminderEnabled: form.returnReminderEnabled,
                                        onChanged: (value) =>
                                            setState(() => form.returnLeadDaysOverride = value),
                                        onReminderEnabledChanged: (value) =>
                                            setState(() => form.returnReminderEnabled = value),
                                      ),
                                    ],
                                  ),
                              ]
                          )
                      );
                  }),
                  
                  // Add Another Item Button
                  Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextButton.icon(
                          onPressed: () {
                              setState(() { _itemForms.add(LineItemFormState()); });
                          },
                          icon: const Icon(Symbols.add_rounded),
                          label: const Text('Add Another Item')
                      )
                  ),
                  const SizedBox(height: 16),

                  // Remarks & Notes
                  _buildSection(
                    isDark: isDark,
                    textPrimary: textPrimary,
                    title: 'Remarks & Notes',
                    icon: Symbols.notes_rounded,
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
              Icon(icon, size: AppDimensions.iconMedium, color: iconColor),
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
          style: AppTextStyles.bodyMedium.copyWith(color: textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodySmall.copyWith(
              color: labelColor.withValues(alpha: 0.5),
            ),
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

  Widget _buildCategoryDropdown({required bool isDark, required LineItemFormState form}) {
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
          value: form.selectedCategory,
          dropdownColor: AppColors.card(isDark),
          style: AppTextStyles.bodyMedium.copyWith(color: textPrimary),
          icon: Icon(Symbols.keyboard_arrow_down_rounded, color: labelColor, size: AppDimensions.iconMedium),
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
            if (value != null) setState(() => form.selectedCategory = value);
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: !reminderEnabled
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  border: Border.all(
                    color: !reminderEnabled
                        ? AppColors.primary
                        : AppColors.border(isDark),
                  ),
                ),
                child: Text(
                  'Off',
                  style: AppTextStyles.bodyXSmall.copyWith(
                    color: !reminderEnabled
                        ? AppColors.primary
                        : labelColor.withValues(alpha: 0.7),
                    fontWeight: !reminderEnabled
                        ? FontWeight.w600
                        : FontWeight.w500,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: reminderEnabled && selectedValue == null
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  border: Border.all(
                    color: reminderEnabled && selectedValue == null
                        ? AppColors.primary
                        : AppColors.border(isDark),
                  ),
                ),
                child: Text(
                  'Use default',
                  style: AppTextStyles.bodyXSmall.copyWith(
                    color: reminderEnabled && selectedValue == null
                        ? AppColors.primary
                        : labelColor.withValues(alpha: 0.7),
                    fontWeight: reminderEnabled && selectedValue == null
                        ? FontWeight.w600
                        : FontWeight.w500,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusPill,
                    ),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border(isDark),
                    ),
                  ),
                  child: Text(
                    '$days days',
                    style: AppTextStyles.bodyXSmall.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : labelColor.withValues(alpha: 0.7),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
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
    final cellStyle = AppTextStyles.bodyXSmall;

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
                Symbols.shopping_cart_rounded,
                size: AppDimensions.iconMedium,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Items Purchased',
                style: AppTextStyles.sectionTitle.copyWith(color: textPrimary),
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
                  '${_ocrLineItems.length} item${_ocrLineItems.length == 1 ? '' : 's'}',
                  style: AppTextStyles.badgeText.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Extracted from receipt - edit via Receipt Details if needed.',
            style: AppTextStyles.caption.copyWith(
              color: labelColor,
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
          ..._ocrLineItems.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(item.itemDescription ?? '—', style: cellStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(
                      item.productCode ?? '—',
                      style: AppTextStyles.caption.copyWith(
                        color: labelColor,
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
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: displayText != null
                          ? textPrimary
                          : labelColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                if (value != null && onClear != null)
                  GestureDetector(
                    onTap: onClear,
                    child: Icon(Symbols.close_rounded, size: AppDimensions.iconSmall, color: labelColor),
                  )
                else
                  Icon(Symbols.calendar_today_rounded, size: AppDimensions.iconSmall, color: labelColor),
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
      child: AppPrimaryButton.dark(
        onPressed: _goToConfirmation,
        text: 'Continue',
      ),
    );
  }
}
