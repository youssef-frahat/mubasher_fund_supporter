import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    try {
      // Firebase must be initialized before using messaging.
      // Make sure flutterfire configure was run by the user.
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      // Request permission for iOS/Web (Android 13+ is handled via permission_handler)
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Get FCM Token (used to send notifications to this specific device)
      final token = await _messaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $token');
      }

      // Listen to messages while app is in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Got a message whilst in the foreground!');
          print('Message data: ${message.data}');
          if (message.notification != null) {
            print('Message also contained a notification: ${message.notification}');
          }
        }
        // TODO: Show local notification or in-app alert
      });

      // Handle background/terminated state opens
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('A new onMessageOpenedApp event was published!');
        }
        // TODO: Navigate to a specific screen based on message.data
      });
    } catch (e) {
      if (kDebugMode) {
        print('Firebase Messaging initialization failed. Ensure google-services.json is configured: $e');
      }
    }
  }
}

// Global background handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}
