import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manager_connect/core/constants/supabase_constants.dart';

class NotificationService {
  NotificationService._();

  static Future<void> initialize() async {
    // Skip if Firebase is not initialized
    if (Firebase.apps.isEmpty) {
      log('NotificationService: Firebase not initialized, skipping');
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      messaging.onTokenRefresh.listen(_onTokenRefresh);
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      log('NotificationService: initialized');
    } catch (e) {
      log('NotificationService: init failed: $e');
    }
  }

  static Future<void> registerToken(String userId) async {
    if (Firebase.apps.isEmpty) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await Supabase.instance.client
          .from(Table.profiles)
          .update({'push_token': token}).eq('id', userId);
      log('Push token registered');
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
