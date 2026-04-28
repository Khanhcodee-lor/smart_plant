import 'dart:async';

import 'package:app_iot/src/core/services/firebase/firebase_firestore_service.dart';
import 'package:app_iot/src/core/ulits/logger_ulits.dart';
import 'package:app_iot/src/features/home/domain/entities/plant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'plant_remote_data_source.g.dart';

abstract class PlantRemoteDataSource {
  Stream<List<Plant>> getPlantsStream();
}

class PlantRemoteDataSourceImpl implements PlantRemoteDataSource {
  final FirebaseFirestoreService _firestore;

  PlantRemoteDataSourceImpl(this._firestore);

  @override
  Stream<List<Plant>> getPlantsStream() {
    return Stream.multi((controller) {
      var directPlants = _fallbackKnownPlants();
      final directDocumentPaths = _knownPlantDocumentPaths();
      final pendingPaths = directDocumentPaths.toSet();

      void emitMerged() {
        final merged = <String, Plant>{};
        for (final plant in directPlants.values) {
          merged[plant.id] = plant;
        }

        if (merged.isEmpty && pendingPaths.isNotEmpty) {
          return;
        }

        final plants = merged.values.toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        controller.add(plants);
      }

      void handleError(String path, Object error, StackTrace stackTrace) {
        pendingPaths.remove(path);
        if (error is FirebaseException && error.code == 'permission-denied') {
          LoggerUtils.i('Firestore plants path denied and ignored: $path');
          emitMerged();
          return;
        }

        LoggerUtils.e(
          'Failed to read Firestore plants path: $path',
          error,
          stackTrace,
        );
        emitMerged();
      }

      final documentSubscriptions = <StreamSubscription<Map<String, dynamic>?>>[
        for (final path in directDocumentPaths)
          _firestore
              .documentStream(path)
              .listen(
                (data) {
                  pendingPaths.remove(path);
                  directPlants = _upsertDirectPlant(directPlants, path, data);
                  emitMerged();
                },
                onError: (error, stackTrace) {
                  handleError(path, error, stackTrace);
                },
              ),
      ];

      controller.onCancel = () async {
        for (final subscription in documentSubscriptions) {
          await subscription.cancel();
        }
      };
    });
  }

  Map<String, Plant> _upsertDirectPlant(
    Map<String, Plant> current,
    String path,
    Map<String, dynamic>? data,
  ) {
    final next = Map<String, Plant>.from(current);
    final id = path.split('/').last;
    if (data == null) {
      next[path] = _fallbackPlant(id);
      return next;
    }

    next[path] = Plant.fromFirestore(id, data);
    return next;
  }
}

List<String> _knownPlantDocumentPaths() {
  const knownIds = ['tomato_001'];
  return [
    for (final id in knownIds) ...['plant/$id', 'plants/$id'],
  ];
}

Map<String, Plant> _fallbackKnownPlants() {
  return {'plant/tomato_001': _fallbackPlant('tomato_001')};
}

Plant _fallbackPlant(String id) {
  return Plant.fromFirestore(id, const {'name': 'Cà chua', 'image': 'tomato'});
}

@riverpod
PlantRemoteDataSource plantRemoteDataSource(PlantRemoteDataSourceRef ref) {
  final firestore = ref.watch(firebaseFirestoreServiceProvider);
  return PlantRemoteDataSourceImpl(firestore);
}
