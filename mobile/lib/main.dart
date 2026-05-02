// coverage:ignore-file
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'core/constants/app_theme.dart';
import 'core/utils/logger.dart';
import 'core/utils/navigation.dart';
import 'providers/auth_provider.dart';
import 'providers/service_providers.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/main_shell.dart';
import 'screens/receipt/product_detail_screen.dart';

/// Top-level FCM background / terminated message handler.
/// Runs in a separate isolate — no Flutter widget APIs allowed.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  logger.d('Background FCM: ${message.messageId}');
  // Navigation is handled via getInitialMessage() / onMessageOpenedApp once
  // the user foregrounds the app — nothing else to do here.
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    await Firebase.initializeApp();
    logger.i('Firebase initialised');
  } catch (e) {
    logger.e('Firebase init error: $e');
  }

  // Register the background handler before runApp
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 1.0;
        options.profilesSampleRate = 1.0;
      },
      appRunner: () => runApp(
        const ProviderScope(
          child: MyApp(),
        ),
      ),
    );
  } else {
    runApp(const ProviderScope(child: MyApp()));
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Smart Receipt Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      navigatorKey: navigatorKey,
      navigatorObservers: [
        SentryNavigatorObserver(),
      ],
      // Named route used by NotificationService to deep-link into a product
      onGenerateRoute: (settings) {
        if (settings.name == '/product-detail') {
          final args = (settings.arguments as Map<String, dynamic>?) ?? {};
          final receiptId = args['receiptId'] as String?;
          final lineItemId = args['lineItemId'] as String?;
          if (receiptId != null) {
            return MaterialPageRoute(
              builder: (_) => ProductDetailScreen(
                receiptId: receiptId,
                lineItemId: lineItemId,
              ),
            );
          }
        }
        return null;
      },
      home: authState.when(
        data: (user) {
          // Do not remove splash here if logged in; let MainShell/HomeScreen remove it.
          if (user == null) {
            FlutterNativeSplash.remove();
            return const LoginScreen();
          }
          if (!user.emailVerified &&
              user.providerData.any((p) => p.providerId == 'password')) {
            FlutterNativeSplash.remove();
            return const VerifyEmailScreen();
          }
          return const _AuthenticatedRoot();
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) {
          FlutterNativeSplash.remove();
          return const LoginScreen();
        },
      ),
    );
  }
}

/// Wraps [MainShell] and initialises [NotificationService] once the widget
/// tree is bound and the user is authenticated.
class _AuthenticatedRoot extends ConsumerStatefulWidget {
  const _AuthenticatedRoot();

  @override
  ConsumerState<_AuthenticatedRoot> createState() => _AuthenticatedRootState();
}

class _AuthenticatedRootState extends ConsumerState<_AuthenticatedRoot> {
  bool _notifInitialised = false;

  @override
  void initState() {
    super.initState();
    // Defer to post-frame so navigatorKey.currentContext is bound
    WidgetsBinding.instance.addPostFrameCallback((_) => _initNotifications());
  }

  Future<void> _initNotifications() async {
    if (_notifInitialised) return;
    _notifInitialised = true;
    try {
      await ref.read(notificationServiceProvider).init();
    } catch (e) {
      logger.e('Notification init error: $e');
    }
  }

  @override
  Widget build(BuildContext context) => const MainShell();
}
