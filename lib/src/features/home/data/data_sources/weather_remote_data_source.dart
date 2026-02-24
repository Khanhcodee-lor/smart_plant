import 'package:dio/dio.dart';
import 'package:app_iot/src/features/home/domain/entities/weather.dart';

class WeatherRemoteDataSource {
  final Dio dio;

  WeatherRemoteDataSource(this.dio);

  Future<Weather> getWeather(double lat, double lon) async {
    final String apiKey = 'e2d38d896534ab72fb4c9c15554e587e';

    // 1. Gọi API Thời tiết
    final weatherResponse = await dio.get(
      'https://api.openweathermap.org/data/2.5/weather',
      queryParameters: {
        'lat': lat,
        'lon': lon,
        'appid': apiKey,
        'units': 'metric',
        'lang': 'vi',
      },
    );

    // 2. Gọi API Chất lượng không khí (Air Pollution)
    final airResponse = await dio.get(
      'http://api.openweathermap.org/data/2.5/air_pollution',
      queryParameters: {'lat': lat, 'lon': lon, 'appid': apiKey},
    );

    // 3. Bóc tách chỉ số AQI (từ 1 đến 5) và chuyển thành chữ tiếng Việt
    int aqiIndex = airResponse.data['list'][0]['main']['aqi'];
    String airQualityText = _getAirQualityText(aqiIndex);

    // 4. Trả về Entity gộp
    return Weather(
      temperature: weatherResponse.data['main']['temp'].toDouble(),
      humidity: weatherResponse.data['main']['humidity'],
      description: weatherResponse.data['weather'][0]['description'],
      city: weatherResponse.data['name'],
      icon: weatherResponse.data['weather'][0]['icon'],
      airQuality: airQualityText, // <-- TRUYỀN DỮ LIỆU VÀO ĐÂY
    );
  }

  // Hàm phụ trợ chuyển đổi số AQI sang chữ
  String _getAirQualityText(int aqi) {
    switch (aqi) {
      case 1:
        return 'Rất tốt';
      case 2:
        return 'Tốt';
      case 3:
        return 'Trung bình';
      case 4:
        return 'Kém';
      case 5:
        return 'Rất kém';
      default:
        return 'Không rõ';
    }
  }
}
