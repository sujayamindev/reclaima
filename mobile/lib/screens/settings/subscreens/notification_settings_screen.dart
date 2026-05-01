// coverage:ignore-file
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/notification_preferences_model.dart';
import '../../../providers/notification_provider.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _warrantyReminders = true;
  bool _returnReminders = true;
  bool _processingAlerts = true;
  bool _quietHoursEnabled = false;

  int _warrantyLeadDays = 30;
  int _returnLeadDays = 3;

  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 8, minute: 0);

  static const _warrantyLeadOptions = [7, 14, 30, 60, 90];
  static const _returnLeadOptions = [1, 2, 3, 5, 7];

  @override
  void initState() {
    super.initState();
    _initializeFromPreferences();
  }

  void _initializeFromPreferences() {
    final prefsAsync = ref.read(notificationPreferencesControllerProvider);
    prefsAsync.whenData((prefs) {
      if (prefs != null && mounted) {
        setState(() {
          _warrantyReminders = prefs.warrantyRemindersEnabled;
          _returnReminders = prefs.returnRemindersEnabled;
          _processingAlerts = prefs.ocrNotificationsEnabled;
          _warrantyLeadDays = prefs.warrantyLeadDays;
          _returnLeadDays = prefs.returnLeadDays;
          _quietHoursEnabled =
              prefs.quietHoursStart != null && prefs.quietHoursEnd != null;
          _quietStart = TimeOfDay(hour: prefs.quietHoursStart ?? 22, minute: 0);
          _quietEnd = TimeOfDay(hour: prefs.quietHoursEnd ?? 8, minute: 0);
        });
      }
    });
  }

  NotificationPreferencesModel _buildUpdatedPreferences(
    NotificationPreferencesModel basePrefs,
  ) {
    return basePrefs.copyWith(
      warrantyRemindersEnabled: _warrantyReminders,
      returnRemindersEnabled: _returnReminders,
      ocrNotificationsEnabled: _processingAlerts,
      warrantyLeadDays: _warrantyLeadDays,
      returnLeadDays: _returnLeadDays,
      quietHoursStart: _quietHoursEnabled ? _quietStart.hour : null,
      quietHoursEnd: _quietHoursEnabled ? _quietEnd.hour : null,
      clearQuietHours: !_quietHoursEnabled,
    );
  }

  Future<void> _savePreferences() async {
    final prefsAsync = ref.read(notificationPreferencesControllerProvider);
    final basePrefs = prefsAsync.valueOrNull;
    if (basePrefs == null) return;

    final updated = _buildUpdatedPreferences(basePrefs);
    try {
      await ref
          .read(notificationPreferencesControllerProvider.notifier)
          .save(updated);
    } catch (e) {
      logger.e('Failed to save preferences: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save preferences'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ── Section card ──────────────────────────────────────────────────────────
  Widget _buildSectionCard(
    bool isDark,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingCard),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: AppDimensions.iconMedium,
                color: AppColors.primary,
                weight: AppDimensions.iconWeightHeavy,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.textPrimary(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  // ── Toggle row ────────────────────────────────────────────────────────────
  Widget _buildToggleRow(
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppDimensions.iconMedium,
            color: AppColors.textSecondary(isDark),
            weight: 600.0,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.formLabel.copyWith(
                    color: AppColors.label(isDark),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary(isDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 26,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Dropdown row ──────────────────────────────────────────────────────────
  Widget _buildDropdownRow(
    bool isDark, {
    required IconData icon,
    required String title,
    required List<int> options,
    required int selectedValue,
    required String unit,
    required ValueChanged<int> onChanged,
    bool enabled = true,
  }) {
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !enabled,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: AppDimensions.iconMedium,
                color: AppColors.textSecondary(isDark),
                weight: 600.0,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.formLabel.copyWith(
                    color: AppColors.label(isDark),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                ),
                child: DropdownButton<int>(
                  value: selectedValue,
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  icon: Icon(
                    Symbols.arrow_drop_down_rounded,
                    size: AppDimensions.iconMedium,
                    color: AppColors.primary,
                    weight: AppDimensions.iconWeightBold,
                  ),
                  style: AppTextStyles.listTitle.copyWith(
                    color: AppColors.primary,
                  ),
                  dropdownColor: AppColors.card(isDark),
                  items: options
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(
                            '$v $unit',
                            style: TextStyle(
                              color: AppColors.textPrimary(isDark),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onChanged(v);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Time picker row ───────────────────────────────────────────────────────
  Widget _buildTimePickerRow(
    bool isDark, {
    required IconData icon,
    required String title,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: AppDimensions.iconMedium,
                color: AppColors.textSecondary(isDark),
                weight: 600.0,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.listTitle.copyWith(
                    color: AppColors.textPrimary(isDark),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                ),
                child: Text(
                  time.format(context),
                  style: AppTextStyles.listTitle.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefsAsync = ref.watch(notificationPreferencesControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        title: Text(
          'Notifications & Reminders',
          style: AppTextStyles.headingLarge.copyWith(
            color: AppColors.textPrimary(isDark),
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary(isDark)),
      ),
      body: prefsAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, st) => Center(
          child: Text(
            'Failed to load settings',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary(isDark),
            ),
          ),
        ),
        data: (_) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.paddingPage,
            8,
            AppDimensions.paddingPage,
            40,
          ),
          child: Column(
            children: [
              _buildSectionCard(
                isDark,
                'Reminder Types',
                Symbols.tune_rounded,
                [
                  _buildToggleRow(
                    isDark,
                    icon: Symbols.verified_user_rounded,
                    title: 'Warranty Reminders',
                    subtitle: 'Alerts before warranty expiry',
                    value: _warrantyReminders,
                    onChanged: (v) {
                      setState(() => _warrantyReminders = v);
                      _savePreferences();
                    },
                  ),
                  Divider(color: AppColors.border(isDark), height: 1),
                  _buildToggleRow(
                    isDark,
                    icon: Symbols.keyboard_return_rounded,
                    title: 'Return Window Reminders',
                    subtitle: 'Alerts before return period ends',
                    value: _returnReminders,
                    onChanged: (v) {
                      setState(() => _returnReminders = v);
                      _savePreferences();
                    },
                  ),
                  Divider(color: AppColors.border(isDark), height: 1),
                  _buildToggleRow(
                    isDark,
                    icon: Symbols.document_scanner_rounded,
                    title: 'Receipt Processing',
                    subtitle: 'Alerts when receipt scan completes',
                    value: _processingAlerts,
                    onChanged: (v) {
                      setState(() => _processingAlerts = v);
                      _savePreferences();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                isDark,
                'Reminder Timing',
                Symbols.schedule_rounded,
                [
                  _buildDropdownRow(
                    isDark,
                    icon: Symbols.event_note_rounded,
                    title: 'Warranty Lead Time',
                    options: _warrantyLeadOptions,
                    selectedValue: _warrantyLeadDays,
                    unit: 'days',
                    enabled: _warrantyReminders,
                    onChanged: (v) {
                      setState(() => _warrantyLeadDays = v);
                      _savePreferences();
                    },
                  ),
                  Divider(color: AppColors.border(isDark), height: 1),
                  _buildDropdownRow(
                    isDark,
                    icon: Symbols.event_note_rounded,
                    title: 'Return Window Lead Time',
                    options: _returnLeadOptions,
                    selectedValue: _returnLeadDays,
                    unit: 'days',
                    enabled: _returnReminders,
                    onChanged: (v) {
                      setState(() => _returnLeadDays = v);
                      _savePreferences();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                isDark,
                'Do Not Disturb',
                Symbols.bedtime_rounded,
                [
                  _buildToggleRow(
                    isDark,
                    icon: Symbols.nights_stay_rounded,
                    title: 'Quiet Hours',
                    subtitle: 'Mute notifications during sleep',
                    value: _quietHoursEnabled,
                    onChanged: (v) {
                      setState(() => _quietHoursEnabled = v);
                      _savePreferences();
                    },
                  ),
                  if (_quietHoursEnabled) ...[
                    Divider(color: AppColors.border(isDark), height: 1),
                    _buildTimePickerRow(
                      isDark,
                      icon: Symbols.start_rounded,
                      title: 'Start Time',
                      time: _quietStart,
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _quietStart,
                        );
                        if (time != null && mounted) {
                          setState(() => _quietStart = time);
                          _savePreferences();
                        }
                      },
                    ),
                    Divider(color: AppColors.border(isDark), height: 1),
                    _buildTimePickerRow(
                      isDark,
                      icon: Symbols.stop_rounded,
                      title: 'End Time',
                      time: _quietEnd,
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _quietEnd,
                        );
                        if (time != null && mounted) {
                          setState(() => _quietEnd = time);
                          _savePreferences();
                        }
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
