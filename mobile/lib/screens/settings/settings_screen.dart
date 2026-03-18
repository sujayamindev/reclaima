import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../../data/models/notification_preferences_model.dart';
import '../../providers/notification_provider.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Settings screen with notification preferences, data/privacy options,
/// and app information. Notification settings are persisted to the backend.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Local working state (synced from backend on init)
  late bool _warrantyReminders;
  late bool _returnReminders;
  late bool _processingAlerts;
  late bool _quietHoursEnabled;

  // Reminder lead times
  late int _warrantyLeadDays;
  late int _returnLeadDays;

  // Quiet hours
  late TimeOfDay _quietStart;
  late TimeOfDay _quietEnd;

  bool _isSaving = false;

  static const _warrantyLeadOptions = [7, 14, 30, 60, 90];
  static const _returnLeadOptions = [1, 2, 3, 5, 7];

  @override
  void initState() {
    super.initState();
    _initializeFromPreferences();
  }

  /// Load preferences from backend and populate local state
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

  /// Build updated preferences model from current local state
  NotificationPreferencesModel _buildUpdatedPreferences(
      NotificationPreferencesModel basePrefs) {
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

  /// Save preferences to backend
  Future<void> _savePreferences() async {
    final prefsAsync = ref.read(notificationPreferencesControllerProvider);
    final basePrefs = prefsAsync.valueOrNull;
    if (basePrefs == null) return;

    setState(() => _isSaving = true);
    try {
      final updated = _buildUpdatedPreferences(basePrefs);
      await ref
          .read(notificationPreferencesControllerProvider.notifier)
          .save(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(milliseconds: 1500),
          ),
        );
      }
    } catch (e) {
      logger.e('Failed to save preferences: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save settings'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefsAsync = ref.watch(notificationPreferencesControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      body: SafeArea(
        child: prefsAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, st) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Symbols.error, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Failed to load settings',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textPrimary(isDark))),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () =>
                      ref.refresh(notificationPreferencesControllerProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (_) => CustomScrollView(
            slivers: [
              // ── Top bar ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Symbols.arrow_back,
                            color: AppColors.textPrimary(isDark)),
                        padding: const EdgeInsets.all(8),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shape: const CircleBorder(),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Settings',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.listTitle.copyWith(
                            fontSize: 17,
                            color: AppColors.textPrimary(isDark),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppDimensions.paddingPage, 4, AppDimensions.paddingPage, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Notification Preferences ─────────────────────────
                    _buildSectionCard(
                      isDark,
                      'Reminder Types',
                      Symbols.tune,
                      [
                        _buildToggleRow(
                          isDark,
                          icon: Symbols.shield,
                          title: 'Warranty Reminders',
                          subtitle: '$_warrantyLeadDays days before expiry',
                          value: _warrantyReminders,
                          onChanged: (v) =>
                              setState(() => _warrantyReminders = v),
                        ),
                        Divider(
                            color: AppColors.border(isDark),
                            height: 1,
                            indent: 40),
                        _buildToggleRow(
                          isDark,
                          icon: Symbols.assignment_return,
                          title: 'Return Reminders',
                          subtitle: '$_returnLeadDays days before deadline',
                          value: _returnReminders,
                          onChanged: (v) =>
                              setState(() => _returnReminders = v),
                        ),
                        Divider(
                            color: AppColors.border(isDark),
                            height: 1,
                            indent: 40),
                        _buildToggleRow(
                          isDark,
                          icon: Symbols.sync,
                          title: 'Processing Alerts',
                          subtitle: 'OCR complete or failed',
                          value: _processingAlerts,
                          onChanged: (v) =>
                              setState(() => _processingAlerts = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Reminder Timing ──────────────────────────
                    _buildSectionCard(
                      isDark,
                      'Reminder Timing',
                      Symbols.schedule,
                      [
                        _buildDropdownRow(
                          isDark,
                          icon: Symbols.shield,
                          title: 'Warranty Lead Time',
                          options: _warrantyLeadOptions,
                          selectedValue: _warrantyLeadDays,
                          unit: 'days',
                          onChanged: (v) =>
                              setState(() => _warrantyLeadDays = v),
                          enabled: _warrantyReminders,
                        ),
                        Divider(
                            color: AppColors.border(isDark),
                            height: 1,
                            indent: 40),
                        _buildDropdownRow(
                          isDark,
                          icon: Symbols.assignment_return,
                          title: 'Return Lead Time',
                          options: _returnLeadOptions,
                          selectedValue: _returnLeadDays,
                          unit: 'days',
                          onChanged: (v) =>
                              setState(() => _returnLeadDays = v),
                          enabled: _returnReminders,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Quiet Hours ──────────────────────────────
                    _buildSectionCard(
                      isDark,
                      'Quiet Hours',
                      Symbols.do_not_disturb_on,
                      [
                        _buildToggleRow(
                          isDark,
                          icon: Symbols.bedtime,
                          title: 'Enable Quiet Hours',
                          subtitle: _quietHoursEnabled
                              ? '${_quietStart.format(context)} – ${_quietEnd.format(context)}'
                              : 'No restrictions',
                          value: _quietHoursEnabled,
                          onChanged: (v) =>
                              setState(() => _quietHoursEnabled = v),
                        ),
                        if (_quietHoursEnabled) ...[
                          Divider(
                              color: AppColors.border(isDark),
                              height: 1,
                              indent: 40),
                          _buildTimePickerRow(
                            isDark,
                            icon: Symbols.nightlight,
                            title: 'From',
                            time: _quietStart,
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: _quietStart,
                              );
                              if (t != null) {
                                setState(() => _quietStart = t);
                              }
                            },
                          ),
                          Divider(
                              color: AppColors.border(isDark),
                              height: 1,
                              indent: 40),
                          _buildTimePickerRow(
                            isDark,
                            icon: Symbols.wb_sunny,
                            title: 'Until',
                            time: _quietEnd,
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: _quietEnd,
                              );
                              if (t != null) {
                                setState(() => _quietEnd = t);
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Data & Privacy ───────────────────────────────────
                    _buildSectionCard(
                      isDark,
                      'Data & Privacy',
                      Symbols.lock,
                      [
                        _buildTapRow(
                          isDark,
                          icon: Symbols.download,
                          title: 'Export Data',
                          subtitle: 'Download all receipts and warranties',
                          onTap: () => _showComingSoon(context),
                        ),
                        Divider(
                            color: AppColors.border(isDark),
                            height: 1,
                            indent: 40),
                        _buildTapRow(
                          isDark,
                          icon: Symbols.delete_forever,
                          title: 'Delete Account',
                          subtitle: 'Permanently remove all data',
                          onTap: () => _showComingSoon(context),
                          isDestructive: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── About ────────────────────────────────────────────
                    _buildSectionCard(
                      isDark,
                      'About',
                      Symbols.info,
                      [
                        _buildInfoRow(isDark, 'App Version',
                            AppConstants.appVersion),
                        Divider(
                            color: AppColors.border(isDark),
                            height: 1,
                            indent: 40),
                        _buildInfoRow(isDark, 'App Name', AppConstants.appName),
                      ],
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      // ── Floating Save Button ──────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _savePreferences,
        backgroundColor: AppColors.primary,
        icon: _isSaving
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation(AppColors.background(false)),
                ),
              )
            : const Icon(Symbols.save),
        label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
      ),
    );
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
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTextStyles.sectionTitle
                    .copyWith(color: AppColors.textPrimary(isDark)),
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
          Icon(icon, size: 18, color: AppColors.textSecondary(isDark)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary(isDark),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary(isDark)),
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
              activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
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
              Icon(icon, size: 18, color: AppColors.textSecondary(isDark)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary(isDark),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                child: DropdownButton<int>(
                  value: selectedValue,
                  underline: const SizedBox.shrink(),
                  isDense: true,
                  icon: Icon(Symbols.arrow_drop_down,
                      size: 18, color: AppColors.primary),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  dropdownColor: AppColors.card(isDark),
                  items: options
                      .map((v) => DropdownMenuItem(
                            value: v,
                            child: Text('$v $unit'),
                          ))
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
              Icon(icon, size: 18, color: AppColors.textSecondary(isDark)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary(isDark),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                child: Text(
                  time.format(context),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tappable row ──────────────────────────────────────────────────────────

  Widget _buildTapRow(
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final textColor =
        isDestructive ? AppColors.error : AppColors.textPrimary(isDark);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon,
                  size: 18,
                  color: isDestructive
                      ? AppColors.error
                      : AppColors.textSecondary(isDark)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: isDestructive
                            ? AppColors.error.withValues(alpha: 0.7)
                            : AppColors.textSecondary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Symbols.chevron_right,
                  size: 18, color: AppColors.muted(isDark)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Info row ──────────────────────────────────────────────────────────────

  Widget _buildInfoRow(bool isDark, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(Symbols.circle, size: 6, color: AppColors.muted(isDark)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary(isDark),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary(isDark)),
          ),
        ],
      ),
    );
  }

  // ── Coming soon ───────────────────────────────────────────────────────────

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
