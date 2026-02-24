import 'package:app_iot/src/features/home/domain/entities/weather.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_iot/src/features/home/domain/repositories/weather_repository.dart';
import 'package:app_iot/src/features/home/data/data_sources/location_service.dart';
import 'package:app_iot/src/features/home/data/data_sources/weather_remote_data_source.dart';
import 'package:app_iot/src/features/home/data/repositories/weather_repository_impl.dart';

// --- Providers ---
final dioProvider = Provider<Dio>((ref) => Dio());

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

final weatherRemoteDataSourceProvider = Provider<WeatherRemoteDataSource>((
  ref,
) {
  return WeatherRemoteDataSource(ref.read(dioProvider));
});

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return WeatherRepositoryImpl(
    ref.read(weatherRemoteDataSourceProvider),
    ref.read(locationServiceProvider),
  );
});

// --- Controller (State Management) ---
// Dùng FutureProvider là cách tốt nhất trong Riverpod để handle 1 tác vụ call API 1 lần lúc init
final weatherProvider = FutureProvider.autoDispose<Weather>((ref) async {
  final repository = ref.watch(weatherRepositoryProvider);
  return repository.getWeatherByCurrentLocation();
});
