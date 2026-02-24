import 'package:app_iot/src/features/home/domain/entities/weather.dart';
import 'package:app_iot/src/features/home/domain/repositories/weather_repository.dart';
import 'package:app_iot/src/features/home/data/data_sources/weather_remote_data_source.dart';
import 'package:app_iot/src/features/home/data/data_sources/location_service.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherRemoteDataSource remoteDataSource;
  final LocationService locationService;

  WeatherRepositoryImpl(this.remoteDataSource, this.locationService);

  @override
  Future<Weather> getWeatherByCurrentLocation() async {
    // 1. Lấy vị trí
    final position = await locationService.getCurrentPosition();
    // 2. Lấy thời tiết dựa trên toạ độ
    return await remoteDataSource.getWeather(
      position.latitude,
      position.longitude,
    );
  }
}
