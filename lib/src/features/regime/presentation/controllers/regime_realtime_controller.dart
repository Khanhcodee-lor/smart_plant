import 'dart:async';

import 'package:app_iot/src/core/services/firebase/firebase_realtime_database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegimeRealtimeData {
  const RegimeRealtimeData({
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.pump,
    this.hasTemperature = false,
    this.hasHumidity = false,
    this.hasSoilMoisture = false,
    this.gasMq2,
    this.light,
    this.waterLevel,
    this.updatedAt = '',
  });

  final double temperature;
  final double humidity;
  final double soilMoisture;
  final PumpControlState pump;
  final bool hasTemperature;
  final bool hasHumidity;
  final bool hasSoilMoisture;
  final double? gasMq2;
  final double? light;
  final double? waterLevel;
  final String updatedAt;

  factory RegimeRealtimeData.fromDatabase(dynamic value) {
    final root = _asMap(value);
    final nestedSensor = _asMap(root['sensor']);
    final sensor = nestedSensor.isNotEmpty ? nestedSensor : root;
    final sensors = _asMap(root['sensors']);
    final sensorsLatest = _asMap(sensors['latest']);
    final air = _asMap(sensor['air']);
    final soil = _asMap(sensor['soil']);
    final control = _asMap(root['control']);
    final temperature = _firstDoubleOrNull([
      air['temperature_c'],
      air['temperature'],
      sensor['temperature_c'],
      sensor['temperature'],
      sensorsLatest['temperature'],
      sensorsLatest['temp'],
      root['temperature'],
    ]);
    final humidity = _firstDoubleOrNull([
      air['humidity'],
      sensor['humidity'],
      sensorsLatest['humidity'],
      root['humidity'],
    ]);
    final soilMoisture = _firstDoubleOrNull([
      soil['moisture_percent'],
      soil['soil_moisture'],
      soil['soilMoisture'],
      sensor['moisture_percent'],
      sensor['soil_moisture'],
      sensor['soilMoisture'],
      sensorsLatest['soilMoisture'],
      sensorsLatest['soil_moisture'],
      root['soilMoisture'],
      root['soil_moisture'],
    ]);

    return RegimeRealtimeData(
      temperature: temperature ?? 0,
      humidity: humidity ?? 0,
      soilMoisture: soilMoisture ?? 0,
      hasTemperature: temperature != null,
      hasHumidity: humidity != null,
      hasSoilMoisture: soilMoisture != null,
      gasMq2: _firstDoubleOrNull([sensor['gas_mq2'], root['gas_mq2']]),
      light: _firstDoubleOrNull([sensor['light'], root['light']]),
      waterLevel: _firstDoubleOrNull([
        sensor['water_level'],
        root['water_level'],
      ]),
      pump: PumpControlState.fromDatabase(
        _firstNonNull([control['pump'], root['pump']]),
        fallbackEnabled: _firstNonNull([
          sensor['pump_on'],
          root['pump_on'],
        ]),
      ),
      updatedAt:
          _firstNonEmptyString([
            sensor['updated_at'],
            sensorsLatest['updated_at'],
            sensorsLatest['time'],
            root['updated_at'],
          ]) ??
          '',
    );
  }
}

class PumpControlState {
  const PumpControlState({
    required this.mode,
    required this.command,
    required this.enabled,
    this.updatedAt = '',
  });

  final String mode;
  final String command;
  final bool enabled;
  final String updatedAt;

  bool get isAutomatic => mode == 'auto' || command == 'auto';
  bool get isManualOff =>
      mode == 'manual' && (command == 'off' || enabled == false);

  String get displayLabel {
    if (isAutomatic) {
      return 'Bơm tự động';
    }
    if (isManualOff) {
      return 'Tắt thủ công';
    }
    if (enabled) {
      return 'Đang bật';
    }
    return 'Chưa có lệnh';
  }

  factory PumpControlState.fromDatabase(
    dynamic value, {
    dynamic fallbackEnabled,
  }) {
    final map = _asMap(value);
    return PumpControlState(
      mode: _firstNonEmptyString([map['mode']]) ?? '',
      command: _firstNonEmptyString([map['command'], map['status']]) ?? '',
      enabled:
          _parseBool(map['enabled']) ??
          _parseBool(map['status']) ??
          _parseBool(fallbackEnabled) ??
          false,
      updatedAt: _firstNonEmptyString([map['updated_at']]) ?? '',
    );
  }
}

enum PumpControlAction { automatic, manualOff }

class PumpControlService {
  const PumpControlService(this._database);

  final FirebaseRealtimeDatabaseService _database;

  Future<void> setAutomatic(String plantId) async {
    await _updateKnownRealtimePaths(
      _database,
      buildPumpControlPaths(plantId),
      buildPumpControlPayload(
        action: PumpControlAction.automatic,
        now: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> turnOffManual(String plantId) async {
    await _updateKnownRealtimePaths(
      _database,
      buildPumpControlPaths(plantId),
      buildPumpControlPayload(
        action: PumpControlAction.manualOff,
        now: DateTime.now().toUtc(),
      ),
    );
  }
}

String buildRegimePlantPath(String plantId) {
  return buildRegimePlantPaths(plantId).first;
}

List<String> buildRegimePlantPaths(String plantId) {
  final normalizedPlantId = plantId.trim();
  // `plants` is the current backend path, so prefer it to the legacy root.
  return ['plants/$normalizedPlantId', 'plant/$normalizedPlantId'];
}

// The current Firebase project connects its single plant to this sensor node.
const _sensorNodeByPlantId = <String, String>{'tomato_001': 'node1'};

List<String> _regimeRealtimeDataPaths(String plantId) {
  final normalizedPlantId = plantId.trim();
  final sensorNodeId = _sensorNodeByPlantId[normalizedPlantId];
  return [
    'plants/$normalizedPlantId',
    if (sensorNodeId != null) '$sensorNodeId/sensor',
    'plant/$normalizedPlantId',
  ];
}

String buildPumpControlPath(String plantId) {
  return buildPumpControlPaths(plantId).first;
}

List<String> buildPumpControlPaths(String plantId) {
  return [
    for (final path in buildRegimePlantPaths(plantId)) '$path/control/pump',
  ];
}

Map<String, dynamic> buildPumpControlPayload({
  required PumpControlAction action,
  required DateTime now,
}) {
  final updatedAt = now.toIso8601String();
  final updatedTs = now.millisecondsSinceEpoch / 1000;

  return switch (action) {
    PumpControlAction.automatic => {
      'mode': 'auto',
      'command': 'auto',
      'enabled': true,
      'manual_override': false,
      'updated_at': updatedAt,
      'updated_ts': updatedTs,
      'updated_by': 'app',
    },
    PumpControlAction.manualOff => {
      'mode': 'manual',
      'command': 'off',
      'enabled': false,
      'manual_override': true,
      'updated_at': updatedAt,
      'updated_ts': updatedTs,
      'updated_by': 'app',
    },
  };
}

final regimeRealtimeDataProvider = StreamProvider.autoDispose
    .family<RegimeRealtimeData, String>((ref, plantId) async* {
      final database = ref.watch(firebaseRealtimeDatabaseServiceProvider);

      while (true) {
        final value = await _getFirstRealtimePlantValue(database, plantId);
        yield RegimeRealtimeData.fromDatabase(value);
        await Future<void>.delayed(const Duration(seconds: 3));
      }
    });

final pumpControlServiceProvider = Provider<PumpControlService>((ref) {
  final database = ref.watch(firebaseRealtimeDatabaseServiceProvider);
  return PumpControlService(database);
});

final pumpControlInFlightProvider = StateProvider.autoDispose
    .family<PumpControlAction?, String>((ref, plantId) => null);

Map<dynamic, dynamic> _asMap(dynamic value) {
  if (value is Map<dynamic, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<dynamic, dynamic>.from(value);
  }
  return <dynamic, dynamic>{};
}

double? _firstDoubleOrNull(List<dynamic> candidates) {
  for (final candidate in candidates) {
    if (candidate == null) {
      continue;
    }
    final parsed = _parseDouble(candidate);
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}

double? _parseDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim());
  }
  return null;
}

dynamic _firstNonNull(List<dynamic> candidates) {
  for (final candidate in candidates) {
    if (candidate != null) {
      return candidate;
    }
  }
  return null;
}

bool? _parseBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'on') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'off') {
      return false;
    }
  }
  return null;
}

String? _firstNonEmptyString(List<dynamic> candidates) {
  for (final candidate in candidates) {
    final value = candidate?.toString().trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return null;
}

Future<dynamic> _getFirstRealtimePlantValue(
  FirebaseRealtimeDatabaseService database,
  String plantId,
) async {
  var merged = <dynamic, dynamic>{};
  dynamic firstScalarValue;
  Object? firstError;
  StackTrace? firstStackTrace;

  // Merge fallback paths first and canonical paths last so current plant
  // fields take precedence while sensor-only nodes fill any missing fields.
  for (final path in _regimeRealtimeDataPaths(plantId).reversed) {
    try {
      final value = await database.getData(path);
      if (value is Map) {
        merged = _mergeRealtimeMaps(_asMap(value), merged);
      } else if (value != null) {
        firstScalarValue ??= value;
      }
    } catch (error, stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }
  }

  if (merged.isNotEmpty) {
    return merged;
  }
  if (firstScalarValue != null) {
    return firstScalarValue;
  }
  if (firstError != null) {
    Error.throwWithStackTrace(firstError, firstStackTrace!);
  }
  return null;
}

Map<dynamic, dynamic> _mergeRealtimeMaps(
  Map<dynamic, dynamic> primary,
  Map<dynamic, dynamic> fallback,
) {
  final merged = Map<dynamic, dynamic>.from(fallback);
  for (final entry in primary.entries) {
    final primaryValue = entry.value;
    final fallbackValue = merged[entry.key];
    if (primaryValue is Map && fallbackValue is Map) {
      merged[entry.key] = _mergeRealtimeMaps(
        _asMap(primaryValue),
        _asMap(fallbackValue),
      );
    } else if (primaryValue != null) {
      merged[entry.key] = primaryValue;
    }
  }
  return merged;
}

Future<void> _updateKnownRealtimePaths(
  FirebaseRealtimeDatabaseService database,
  List<String> paths,
  Map<String, dynamic> payload,
) async {
  Object? firstError;
  StackTrace? firstStackTrace;
  var successCount = 0;

  for (final path in paths) {
    try {
      await database.updateData(path, payload);
      successCount += 1;
    } catch (error, stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }
  }

  if (successCount == 0 && firstError != null) {
    Error.throwWithStackTrace(firstError, firstStackTrace!);
  }
}
