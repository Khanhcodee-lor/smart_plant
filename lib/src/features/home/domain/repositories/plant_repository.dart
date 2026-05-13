import 'package:app_iot/src/features/home/domain/entities/plant.dart';

abstract class PlantRepository {
  /// Streams plant data from Cloud Firestore.
  Stream<List<Plant>> getPlantsStream();
}
