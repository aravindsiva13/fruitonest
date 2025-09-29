import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Get FCM token
    String? token = await _messaging.getToken(
      vapidKey: kIsWeb ? 'YOUR_VAPID_KEY_HERE' : null, // Only needed for web
    );
    print('FCM Token: $token');
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received: ${message.notification?.title}');
      _showNotification(message);
    });
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
  
  Future<void> _showNotification(RemoteMessage message) async {
    if (kIsWeb) {
      // For web, use browser notifications
      print('Web notification: ${message.notification?.title}');
      print('Web notification body: ${message.notification?.body}');
      // Browser will automatically show notification if permission granted
    } else {
      // For mobile, you would use flutter_local_notifications here
      // But since we're focusing on web support, we'll skip mobile implementation
      print('Mobile notification: ${message.notification?.title}');
    }
  }
  
  Future<String?> getToken() async {
    return await _messaging.getToken(
      vapidKey: kIsWeb ? 'YOUR_VAPID_KEY_HERE' : null,
    );
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
}