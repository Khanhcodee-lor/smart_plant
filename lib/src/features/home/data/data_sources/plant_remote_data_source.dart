import 'package:app_iot/src/core/services/firebase/firebase_realtime_database_service.dart';
import 'package:app_iot/src/features/home/domain/entities/plant.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'plant_remote_data_source.g.dart';

abstract class PlantRemoteDataSource {
  Stream<List<Plant>> getPlantsStream();
}

class PlantRemoteDataSourceImpl implements PlantRemoteDataSource {
  final FirebaseRealtimeDatabaseService _dbService;

  PlantRemoteDataSourceImpl(this._dbService);

  @override
  Stream<List<Plant>> getPlantsStream() {
    // Lắng nghe thay đổi tại node 'plants'
    return _dbService.streamData('plants').map((event) {
      final data = event.snapshot.value;
      if (data == null) {
        return [];
      }

      // Realtime Database thường trả về dữ liệu Map cho danh sách có key ngẫu nhiên
      if (data is Map) {
        return data.entries.map((e) {
          final mappedData = e.value as Map<dynamic, dynamic>;
          return Plant.fromRealtimeDb(e.key.toString(), mappedData);
        }).toList();
      }

      return [];
    });
  }
}

@riverpod
PlantRemoteDataSource plantRemoteDataSource(PlantRemoteDataSourceRef ref) {
  final dbService = ref.watch(firebaseRealtimeDatabaseServiceProvider);
  return PlantRemoteDataSourceImpl(dbService);
}
