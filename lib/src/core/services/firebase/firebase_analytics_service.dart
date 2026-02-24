import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_analytics_service.g.dart';

class FirebaseAnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver getObserver() => FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logEvent({required String name, Map<String, Object>? parameters}) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  Future<void> setUserId(String id) async {
    await _analytics.setUserId(id: id);
  }

  Future<void> setCurrentScreen(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }
}

@riverpod
FirebaseAnalyticsService firebaseAnalyticsService(FirebaseAnalyticsServiceRef ref) {
  return FirebaseAnalyticsService();
}
