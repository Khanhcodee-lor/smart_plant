import 'package:app_iot/src/core/services/firebase/firebase_realtime_database_service.dart';
import 'package:app_iot/src/core/ulits/logger_ulits.dart';
import 'package:app_iot/src/features/home/domain/entities/plant.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'plant_remote_data_source.g.dart';

abstract class PlantRemoteDataSource {
  Stream<List<Plant>> getPlantsStream();
}

class PlantRemoteDataSourceImpl implements PlantRemoteDataSource {
  PlantRemoteDataSourceImpl(this._database);

  final FirebaseRealtimeDatabaseService _database;
  static const _knownPlantIds = ['tomato_001'];

  @override
  Stream<List<Plant>> getPlantsStream() async* {
    while (true) {
      try {
        final plants = await _readPlants();
        yield plants;
      } catch (error, stackTrace) {
        LoggerUtils.e(
          'Failed to read Realtime Database plants',
          error,
          stackTrace,
        );
        yield const <Plant>[];
      }

      await Future<void>.delayed(const Duration(seconds: 3));
    }
  }

  Future<List<Plant>> _readPlants() async {
    final merged = <String, Plant>{};
    Object? lastReadError;
    StackTrace? lastReadStackTrace;

    void rememberReadError(Object error, StackTrace stackTrace) {
      lastReadError ??= error;
      lastReadStackTrace ??= stackTrace;
    }

    // The IoT backend stores plant data under the Realtime Database root
    // `plants`. Keep `plant` as a compatibility path for older devices.
    for (final rootPath in const ['plants', 'plant']) {
      dynamic value;
      try {
        value = await _database.getData(rootPath);
      } catch (error, stackTrace) {
        rememberReadError(error, stackTrace);
        continue;
      }

      if (value is! Map) {
        continue;
      }

      _addPlantsFromMap(merged, value);
    }

    // A ruleset can allow reads at the plant path while denying a read of the
    // whole root. Try the configured plant directly so it still appears in
    // the garden in that case.
    for (final id in _knownPlantIds) {
      if (merged.containsKey(id)) {
        continue;
      }

      for (final rootPath in const ['plants', 'plant']) {
        final plantPath = '$rootPath/$id';
        try {
          final value = await _database.getData(plantPath);
          final plantData = _asMap(value);
          if (plantData.isNotEmpty) {
            merged[id] = Plant.fromMap(id, plantData);
            break;
          }
        } catch (error, stackTrace) {
          rememberReadError(error, stackTrace);
        }

        // Some deployments expose only the captures child. Its existence is
        // enough to include the plant; the disease screen reads its details.
        try {
          final captures = await _database.getData('$plantPath/plant_captures');
          if ((captures is Map && captures.isNotEmpty) ||
              (captures is List && captures.isNotEmpty)) {
            merged[id] = Plant.fromMap(id, const {});
            break;
          }
        } catch (error, stackTrace) {
          rememberReadError(error, stackTrace);
        }
      }
    }

    if (merged.isEmpty && lastReadError != null) {
      LoggerUtils.e(
        'Could not load plants from Realtime Database',
        lastReadError,
        lastReadStackTrace,
      );
    }

    return merged.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }
}

void _addPlantsFromMap(Map<String, Plant> target, Map<dynamic, dynamic> data) {
  for (final entry in data.entries) {
    if (entry.value is! Map) {
      continue;
    }

    final id = entry.key.toString().trim();
    if (id.isEmpty) {
      continue;
    }

    target[id] = Plant.fromMap(id, _asMap(entry.value));
  }
}

Map<dynamic, dynamic> _asMap(dynamic value) {
  if (value is Map<dynamic, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<dynamic, dynamic>.from(value);
  }
  return <dynamic, dynamic>{};
}

@riverpod
PlantRemoteDataSource plantRemoteDataSource(PlantRemoteDataSourceRef ref) {
  final database = ref.watch(firebaseRealtimeDatabaseServiceProvider);
  return PlantRemoteDataSourceImpl(database);
}
