import 'dart:convert';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manager_connect/core/constants/supabase_constants.dart';

/// Background FCM handler — must be a top-level function annotated vm:entry-point.
/// This runs in a separate isolate when the app is in background or killed.
/// We manually display a local notification here to cover data-only FCM messages
/// (pure data payloads are not auto-displayed by Android/FCM).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  final local = FlutterLocalNotificationsPlugin();
  await local.initialize(const InitializationSettings(android: androidInit));

  // Prefer the notification payload; fall back to data fields for data-only msgs.
  final n = message.notification;
  final title =
      n?.title ?? (message.data['title'] as String?) ?? 'The Catalysts';
  final body =
      n?.body ?? (message.data['body'] as String?) ?? 'You have a new update';

  await local.show(
    message.hashCode,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'mc_default',
        'The Catalysts',
        channelDescription: 'The Catalysts alerts and updates',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    ),
    payload: jsonEncode(message.data),
  );
}

class NotificationService {
  NotificationService._();

  static final _local = FlutterLocalNotificationsPlugin();
  static const _channelId = 'mc_default';
  static const _channelName = 'The Catalysts';

  // GoRouter is set by the App widget once the navigator tree is ready.
  static GoRouter? _router;
  // If a notification is tapped before the router is ready, store the route here.
  static String? _pendingRoute;

  // ── Public API ──────────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    if (Firebase.apps.isEmpty) {
      log('NotificationService: Firebase not initialised, skipping');
      return;
    }

    try {
      // ── flutter_local_notifications setup (Android) ──────────────────
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _local.initialize(
        const InitializationSettings(android: androidInit),
        onDidReceiveNotificationResponse: _onLocalTap,
      );

      // High-importance channel so heads-up banners pop over other apps
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'The Catalysts alerts and updates',
        importance: Importance.high,
        playSound: true,
      );
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      // ── Firebase Messaging setup ─────────────────────────────────────
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // Token lifecycle
      messaging.onTokenRefresh.listen(_onTokenRefresh);

      // Foreground message: FCM does NOT auto-show a system notification
      // when the app is open — we display one ourselves via _local.
      FirebaseMessaging.onMessage.listen(_onForeground);

      // Background tap: app was running in background, user tapped the
      // system notification that FCM auto-displayed.
      FirebaseMessaging.onMessageOpenedApp.listen(_onTap);

      // Terminated tap: app was killed, system notification was tapped.
      // Router isn't ready yet, so we store the route for later.
      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        _pendingRoute = _routeFor(initial.data);
      }

      log('NotificationService: initialised');
    } catch (e) {
      log('NotificationService: init failed: $e');
    }
  }

  /// Called by App.build() every time the router rebuilds.
  /// Flushes any pending deep-link navigation accumulated before the router
  /// was ready (e.g. tapping a notification while the app was terminated).
  static void setRouter(GoRouter router) {
    _router = router;
    final pending = _pendingRoute;
    if (pending != null) {
      _pendingRoute = null;
      Future.microtask(() => _navigate(pending));
    }
  }

  static Future<void> registerToken(String userId) async {
    if (Firebase.apps.isEmpty) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await Supabase.instance.client
          .from(Table.profiles)
          .update({'push_token': token})
          .eq('id', userId);
      log('Push token registered');
    } catch (e) {
      log('Failed to register push token: $e');
    }
  }

  static Future<void> nullifyToken(String userId) async {
    try {
      await Supabase.instance.client
          .from(Table.profiles)
          .update({'push_token': null})
          .eq('id', userId);
    } catch (e) {
      log('Failed to nullify push token: $e');
    }
  }

  // ── Private ─────────────────────────────────────────────────────────────────

  static void _onTokenRefresh(String token) {
    log('FCM token refreshed: ${token.substring(0, 10)}…');
  }

  /// Foreground FCM message — display a system notification manually.
  static void _onForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    _local.show(
      message.hashCode,
      n.title,
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          // ic_launcher is colorful; Android 5+ renders it as a white silhouette
          // in the status bar, which is fine for an internal beta.
          icon: '@mipmap/ic_launcher',
        ),
      ),
      // Encode FCM data so we can route on tap
      payload: jsonEncode(message.data),
    );
  }

  /// User tapped an FCM-generated system notification (background/killed).
  static void _onTap(RemoteMessage message) {
    _navigate(_routeFor(message.data));
  }

  /// User tapped a locally-displayed foreground notification.
  static void _onLocalTap(NotificationResponse response) {
    final raw = response.payload;
    if (raw == null) return;
    try {
      final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      _navigate(_routeFor(data));
    } catch (_) {}
  }

  /// Map FCM `data` fields to a GoRouter path.
  /// The backend Edge Function should include `type` and optionally `id`.
  static String _routeFor(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final id = data['id'] as String?;
    return switch (type) {
      'post' when id != null => '/feed/post/$id',
      'event' when id != null => '/events/event/$id',
      'poll' when id != null => '/events/poll/$id',
      'challenge' when id != null => '/growth/challenge/$id',
      'recognition' when id != null => '/notifications',
      _ => '/notifications',
    };
  }

  static void _navigate(String route) {
    if (_router != null) {
      _router!.go(route);
    } else {
      _pendingRoute = route;
    }
  }
}
