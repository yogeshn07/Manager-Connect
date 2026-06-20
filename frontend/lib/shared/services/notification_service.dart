import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manager_connect/core/constants/supabase_constants.dart';

class NotificationService {
  NotificationService._();

  static Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    messaging.onTokenRefresh.listen(_onTokenRefresh);

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  static Future<void> registerToken(String userId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await Supabase.instance.client
          .from(Table.profiles)
          .update({'push_token': token}).eq('id', userId);
    } catch (e) {
      log('Failed to register push token: $e');
    }
  }

  static Future<void> nullifyToken(String userId) async {
    try {
      await Supabase.instance.client
          .from(Table.profiles)
          .update({'push_token': null}).eq('id', userId);
    } catch (e) {
      log('Failed to nullify push token: $e');
    }
  }

  static void _onTokenRefresh(String token) {
    log('FCM token refreshed: ${token.substring(0, 10)}...');
    // Token update will be handled when auth state is available
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    log('Foreground notification: ${message.notification?.title}');
    // Full implementation in Sprint 5
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background handler must be top-level function
  log('Background notification: ${message.notification?.title}');
}
