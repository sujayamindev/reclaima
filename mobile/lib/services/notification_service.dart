import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';
import '../core/utils/navigation.dart';
import '../data/models/notification_preferences_model.dart';
import 'api_service.dart';

/// Handles FCM token lifecycle, notification permission, and deep-link
/// navigation for foreground and tapped background notifications.
class NotificationService {
  final ApiService _api;

  NotificationService(this._api);

  // ── Initialise ────────────────────────────────────────────────────────────

  /// Call once after Firebase is ready and the user is authenticated.
  /// Requests permission (iOS), registers the FCM token with the backend,
  /// and wires up foreground + tap handlers.
  Future<void> init() async {
    await _requestPermission();
    final token = await _registerToken();
    if (token != null) {
      logger.d('FCM token registered: ${token.substring(0, 20)}...');
    }

    // Refresh token when it rotates (e.g. app reinstall)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      logger.d('FCM token refreshed');
      _uploadToken(newToken);
    });

    // Foreground messages — show a snackbar via the global navigator
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background / terminated tap — called when user taps the notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Terminated state — app launched by tapping a notification
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      // Defer until the navigator is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationTap(initialMessage);
      });
    }
  }

  // ── Preferences API ────────────────────────────────────────────────────────

  /// Fetch notification preferences from the backend.
  Future<NotificationPreferencesModel?> getPreferences() async {
    try {
      final response = await _api.get(ApiConstants.notificationPreferences);
      return NotificationPreferencesModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      logger.e('Failed to load notification preferences: $e');
      return null;
    }
  }

  /// Persist notification preferences to the backend.
  Future<NotificationPreferencesModel?> savePreferences(
    NotificationPreferencesModel prefs,
  ) async {
    try {
      final response = await _api.patch(
        ApiConstants.notificationPreferences,
        data: prefs.toUpdateJson(),
      );
      return NotificationPreferencesModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      logger.e('Failed to save notification preferences: $e');
      return null;
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false, // iOS: ask explicitly
    );
    logger.d('Notification permission: ${settings.authorizationStatus.name}');
  }

  Future<String?> _registerToken() async {
    // On iOS, get APNS token first — required before getToken() on physical devices
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.getAPNSToken();
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _uploadToken(token);
    }
    return token;
  }

  Future<void> _uploadToken(String token) async {
    try {
      await _api.patch(ApiConstants.fcmToken, data: {'token': token});
    } catch (e) {
      logger.e('Failed to register FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    logger.d('Foreground FCM: ${notification.title}');

    // Show a banner using the global navigator / ScaffoldMessenger
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(
            notification.body ?? notification.title ?? 'New notification',
          ),
          behavior: SnackBarBehavior.floating,
          action: message.data['receipt_id'] != null
              ? SnackBarAction(
                  label: 'View',
                  onPressed: () => _handleNotificationTap(message),
                )
              : null,
        ),
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    final receiptId = message.data['receipt_id'] as String?;
    final lineItemId = message.data['line_item_id'] as String?;

    if (receiptId == null) return;

    _navigateToDetail(receiptId, lineItemId);
  }

  void _navigateToDetail(String receiptId, String? lineItemId) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    // Lazy import to avoid circular dependencies with screen files
    nav.pushNamed(
      '/product-detail',
      arguments: {'receiptId': receiptId, 'lineItemId': lineItemId},
    );
  }

  /// Clear the FCM token on sign-out so the user stops receiving pushes.
  Future<void> deregisterToken() async {
    try {
      await _api.patch(ApiConstants.fcmToken, data: {'token': null});
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      logger.e('Failed to deregister FCM token: $e');
    }
  }
}
