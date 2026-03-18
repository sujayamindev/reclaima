import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/notification_preferences_model.dart';
import 'service_providers.dart';

// ── Fetch preferences ──────────────────────────────────────────────────────

/// Loads the current user's notification preferences from the backend.
/// A default row is auto-created by the backend on first access.
final notificationPreferencesProvider =
    FutureProvider<NotificationPreferencesModel?>((ref) async {
  final notifService = ref.watch(notificationServiceProvider);
  return notifService.getPreferences();
});

// ── Preferences controller ─────────────────────────────────────────────────

class NotificationPreferencesController
    extends StateNotifier<AsyncValue<NotificationPreferencesModel?>> {
  final Ref _ref;

  NotificationPreferencesController(this._ref)
      : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final prefs =
          await _ref.read(notificationServiceProvider).getPreferences();
      state = AsyncValue.data(prefs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Persist updated preferences and update local state optimistically.
  Future<void> save(NotificationPreferencesModel updated) async {
    // Optimistic update
    state = AsyncValue.data(updated);
    try {
      final saved =
          await _ref.read(notificationServiceProvider).savePreferences(updated);
      if (saved != null) state = AsyncValue.data(saved);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> reload() => _load();
}

final notificationPreferencesControllerProvider = StateNotifierProvider<
    NotificationPreferencesController,
    AsyncValue<NotificationPreferencesModel?>>(
  (ref) => NotificationPreferencesController(ref),
);
