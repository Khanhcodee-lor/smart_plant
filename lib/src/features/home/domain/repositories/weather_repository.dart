import 'package:app_iot/src/features/home/domain/entities/weather.dart';

abstract class WeatherRepository {
  Future<Weather> getWeatherByCurrentLocation();
}
