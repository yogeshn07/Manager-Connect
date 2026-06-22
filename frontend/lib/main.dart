import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manager_connect/app.dart';
import 'package:manager_connect/core/config/env.dart';
import 'package:manager_connect/shared/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    log('Firebase init skipped: $e');
  }

  if (!Env.isConfigured) {
    runApp(const _MissingEnvApp());
    return;
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );

  try {
    await NotificationService.initialize();
  } catch (e) {
    log('Notification init skipped: $e');
  }

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Something went wrong.\nPlease restart the app.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  };

  runApp(const ProviderScope(child: App()));
}

class _MissingEnvApp extends StatelessWidget {
  const _MissingEnvApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber, size: 48, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Missing Configuration',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  kDebugMode
                      ? 'Add --dart-define=SUPABASE_URL=... and --dart-define=SUPABASE_ANON_KEY=...'
                      : 'App configuration is incomplete.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
