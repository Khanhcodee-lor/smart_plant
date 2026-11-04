import 'dart:async';

import 'package:app_iot/src/core/ulits/logger_ulits.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_messaging_service.g.dart';

typedef FirebaseMessageCallback = void Function(RemoteMessage message);

class FirebaseMessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final Set<String> _subscribedTopics = <String>{};
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  Future<void>? _permissionFuture;
  bool _initialized = false;

  Future<void> init({
    required FirebaseMessageCallback onNotificationOpened,
    required FirebaseMessageCallback onForegroundMessage,
  }) async {
    if (_initialized) return;
    _initialized = true;
    if (!_supportsPushMessaging) return;

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      onForegroundMessage,
      onError: (Object error, StackTrace stackTrace) {
        LoggerUtils.e('Failed to receive foreground FCM message', error, stackTrace);
      },
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      onNotificationOpened,
      onError: (Object error, StackTrace stackTrace) {
        LoggerUtils.e('Failed to handle opened FCM message', error, stackTrace);
      },
    );

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (user) {
        if (user == null) {
          unawaited(syncPlantTopics(const <String>[]));
        } else {
          _permissionFuture = _requestMessagingPermission();
          unawaited(_permissionFuture!);
        }
      },
    );

    _tokenSubscription = _messaging.onTokenRefresh.listen((_) {
      LoggerUtils.i('FCM registration token refreshed');
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      onNotificationOpened(initialMessage);
    }
  }

  Future<void> _requestMessagingPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await _messaging.getToken();
        LoggerUtils.i('Push notification permission granted');
      } else {
        LoggerUtils.i('Push notification permission was not granted');
      }
    } catch (error, stackTrace) {
      LoggerUtils.e('Could not initialize Firebase Messaging permission', error, stackTrace);
    }
  }

  Future<void> syncPlantTopics(Iterable<String> plantIds) async {
    if (!_supportsPushMessaging) return;
    await _permissionFuture;
    final authenticated = FirebaseAuth.instance.currentUser != null;
    final nextTopics = (authenticated ? plantIds : const <String>[])
        .map((id) => id.trim())
        .where((id) => RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(id))
        .map((id) => 'plant_$id')
        .toSet();

    for (final topic in _subscribedTopics.difference(nextTopics).toList()) {
      try {
        await _messaging.unsubscribeFromTopic(topic);
        _subscribedTopics.remove(topic);
      } catch (error, stackTrace) {
        LoggerUtils.e('Could not unsubscribe from FCM topic $topic', error, stackTrace);
      }
    }

    for (final topic in nextTopics.difference(_subscribedTopics)) {
      try {
        await _messaging.subscribeToTopic(topic);
        _subscribedTopics.add(topic);
      } catch (error, stackTrace) {
        LoggerUtils.e('Could not subscribe to FCM topic $topic', error, stackTrace);
      }
    }
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
  }

  bool get _supportsPushMessaging =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  LoggerUtils.i('Received background FCM message ${message.messageId}');
}

@riverpod
FirebaseMessagingService firebaseMessagingService(
  FirebaseMessagingServiceRef ref,
) {
  final service = FirebaseMessagingService();
  ref.onDispose(service.dispose);
  return service;
}
