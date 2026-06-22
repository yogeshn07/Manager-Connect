import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manager_connect/core/constants/supabase_constants.dart';

class NotificationService {
  NotificationService._();

  static Future<void> initialize() async {
    if (kIsWeb) return;

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    messaging.onTokenRefresh.listen(_onTokenRefresh);

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  static Future<void> registerToken(String userId) async {
    if (kIsWeb) return;
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
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    log('Foreground notification: ${message.notification?.title}');
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('Background notification: ${message.notification?.title}');
}
