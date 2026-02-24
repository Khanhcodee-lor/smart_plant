import 'package:app_iot/src/core/ulits/logger_ulits.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_messaging_service.g.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      LoggerUtils.i('User granted permission');

      // Get token
      String? token = await _messaging.getToken();
      LoggerUtils.i('FCM Token: $token');
    } else {
      LoggerUtils.e('User declined or has not accepted permission');
    }

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      LoggerUtils.i('Got a message whilst in the foreground!');
      LoggerUtils.i('Message data: ${message.data}');

      if (message.notification != null) {
        LoggerUtils.i(
          'Message also contained a notification: ${message.notification}',
        );
      }
    });
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    LoggerUtils.i("Handling a background message: ${message.messageId}");
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
}

@riverpod
FirebaseMessagingService firebaseMessagingService(
  FirebaseMessagingServiceRef ref,
) {
  return FirebaseMessagingService();
}
