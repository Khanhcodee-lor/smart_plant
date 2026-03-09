import 'package:app_iot/src/features/home/data/repositories/plant_repository_impl.dart';
import 'package:app_iot/src/features/home/domain/entities/plant.dart';
import 'package:app_iot/src/features/home/domain/repositories/plant_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_plants_stream_usecase.g.dart';

class GetPlantsStreamUseCase {
  final PlantRepository _repository;

  GetPlantsStreamUseCase(this._repository);

  Stream<List<Plant>> call() {
    return _repository.getPlantsStream();
  }
}

@riverpod
GetPlantsStreamUseCase getPlantsStreamUseCase(GetPlantsStreamUseCaseRef ref) {
  final repo = ref.watch(plantRepositoryProvider);
  return GetPlantsStreamUseCase(repo);
}
