import 'package:app_iot/src/features/home/data/data_sources/plant_remote_data_source.dart';
import 'package:app_iot/src/features/home/domain/entities/plant.dart';
import 'package:app_iot/src/features/home/domain/repositories/plant_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'plant_repository_impl.g.dart';

class PlantRepositoryImpl implements PlantRepository {
  final PlantRemoteDataSource _remoteDataSource;

  PlantRepositoryImpl(this._remoteDataSource);

  @override
  Stream<List<Plant>> getPlantsStream() {
    return _remoteDataSource.getPlantsStream();
  }
}

@riverpod
PlantRepository plantRepository(PlantRepositoryRef ref) {
  final remoteDataSource = ref.watch(plantRemoteDataSourceProvider);
  return PlantRepositoryImpl(remoteDataSource);
}
