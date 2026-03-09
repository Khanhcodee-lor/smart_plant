import 'package:app_iot/src/features/home/domain/entities/plant.dart';
import 'package:app_iot/src/features/home/domain/usecases/get_plants_stream_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'plant_controller.g.dart';

@riverpod
class PlantController extends _$PlantController {
  @override
  Stream<List<Plant>> build() {
    final getPlantsStreamUseCase = ref.watch(getPlantsStreamUseCaseProvider);
    return getPlantsStreamUseCase.call();
  }
}
