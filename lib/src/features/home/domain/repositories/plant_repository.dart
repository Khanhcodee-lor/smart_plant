import 'package:app_iot/src/features/home/domain/entities/plant.dart';

abstract class PlantRepository {
  /// Lấy danh sách cây realtime từ Firebase Realtime Database
  Stream<List<Plant>> getPlantsStream();
}
