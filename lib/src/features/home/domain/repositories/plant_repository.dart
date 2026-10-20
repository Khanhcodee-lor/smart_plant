import 'package:app_iot/src/features/home/domain/entities/plant.dart';

abstract class PlantRepository {
  /// Streams plant data from Firebase Realtime Database.
  Stream<List<Plant>> getPlantsStream();
}
