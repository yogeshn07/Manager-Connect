import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manager_connect/app.dart';
import 'package:manager_connect/core/config/env.dart';
import 'package:manager_connect/core/config/firebase_config.dart';
import 'package:manager_connect/shared/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase: initialize when config is provided via dart-define
  if (FirebaseConfig.isConfigured) {
    try {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: FirebaseConfig.apiKey,
          authDomain: FirebaseConfig.authDomain,
          projectId: FirebaseConfig.projectId,
          storageBucket: FirebaseConfig.storageBucket,
          messagingSenderId: FirebaseConfig.messagingSenderId,
          appId: FirebaseConfig.appId,
        ),
      );
      log('Firebase initialized');
    } catch (e) {
      log('Firebase init failed: $e');
    }
  } else if (!kIsWeb) {
    // Native platforms: try default config (google-services.json / GoogleService-Info.plist)
    try {
      await Firebase.initializeApp();
      log('Firebase initialized (default config)');
    } catch (e) {
      log('Firebase init skipped: $e');
    }
  } else {
    log('Firebase skipped: no config provided via dart-define');
  }

  if (!Env.isConfigured) {
    runApp(const _ErrorApp(message: 'Missing SUPABASE_URL or SUPABASE_ANON_KEY'));
    return;
  }

  try {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
    );
  } catch (e) {
    runApp(_ErrorApp(message: 'Supabase init failed: $e'));
    return;
  }

  // Notification service: initialize when Firebase is available
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
              'Something went wrong.\n${details.exceptionAsString()}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ),
      ),
    );
  };

  runApp(const ProviderScope(child: App()));
}

class _ErrorApp extends StatelessWidget {
  const _ErrorApp({required this.message});
  final String message;

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
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
