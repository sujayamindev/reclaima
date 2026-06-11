// coverage:ignore-file
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/notification_preferences_model.dart';
import 'service_providers.dart';

part 'notification_provider.g.dart';

// ── Fetch preferences ──────────────────────────────────────────────────────

/// Loads the current user's notification preferences from the backend.
/// A default row is auto-created by the backend on first access.
final notificationPreferencesProvider =
    FutureProvider<NotificationPreferencesModel?>((ref) async {
      final notifService = ref.watch(notificationServiceProvider);
      return notifService.getPreferences();
    });

// ── Preferences controller ─────────────────────────────────────────────────

@riverpod
class NotificationPreferencesController
    extends AsyncNotifier<NotificationPreferencesModel?> {
  @override
  Future<NotificationPreferencesModel?> build() async {
    return ref.read(notificationServiceProvider).getPreferences();
  }

  /// Persist updated preferences and update local state optimistically.
  Future<void> save(NotificationPreferencesModel updated) async {
    // Optimistic update
    state = AsyncValue.data(updated);
    try {
      final saved = await ref
          .read(notificationServiceProvider)
          .savePreferences(updated);
      if (saved != null) state = AsyncValue.data(saved);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    try {
      final prefs = await ref
          .read(notificationServiceProvider)
          .getPreferences();
      state = AsyncValue.data(prefs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
