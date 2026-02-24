import 'package:firebase_performance/firebase_performance.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_performance_service.g.dart';

class FirebasePerformanceService {
  final FirebasePerformance _perf = FirebasePerformance.instance;

  Future<void> setPerformanceCollectionEnabled(bool enabled) async {
    await _perf.setPerformanceCollectionEnabled(enabled);
  }

  Trace newTrace(String name) {
    return _perf.newTrace(name);
  }

  HttpMetric newHttpMetric(String url, HttpMethod method) {
    return _perf.newHttpMetric(url, method);
  }
}

@riverpod
FirebasePerformanceService firebasePerformanceService(FirebasePerformanceServiceRef ref) {
  return FirebasePerformanceService();
}
