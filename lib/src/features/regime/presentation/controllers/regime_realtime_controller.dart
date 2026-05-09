import 'dart:async';

import 'package:app_iot/src/core/services/firebase/firebase_realtime_database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegimeRealtimeData {
  const RegimeRealtimeData({
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.pump,
    this.updatedAt = '',
  });

  final double temperature;
  final double humidity;
  final double soilMoisture;
  final PumpControlState pump;
  final String updatedAt;

  factory RegimeRealtimeData.fromDatabase(dynamic value) {
    final root = _asMap(value);
    final sensor = _asMap(root['sensor']);
    final air = _asMap(sensor['air']);
    final soil = _asMap(sensor['soil']);
    final control = _asMap(root['control']);

    return RegimeRealtimeData(
      temperature: _firstDouble([
        air['temperature_c'],
        air['temperature'],
        sensor['temperature_c'],
        sensor['temperature'],
      ]),
      humidity: _firstDouble([air['humidity'], sensor['humidity']]),
      soilMoisture: _firstDouble([
        soil['moisture_percent'],
        soil['soil_moisture'],
        soil['soilMoisture'],
        sensor['moisture_percent'],
        sensor['soil_moisture'],
        sensor['soilMoisture'],
      ]),
      pump: PumpControlState.fromDatabase(control['pump']),
      updatedAt:
          _firstNonEmptyString([sensor['updated_at'], root['updated_at']]) ??
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

  factory PumpControlState.fromDatabase(dynamic value) {
    final map = _asMap(value);
    return PumpControlState(
      mode: _firstNonEmptyString([map['mode']]) ?? '',
      command: _firstNonEmptyString([map['command'], map['status']]) ?? '',
      enabled: _parseBool(map['enabled']) ?? false,
      updatedAt: _firstNonEmptyString([map['updated_at']]) ?? '',
    );
  }
}

enum PumpControlAction { automatic, manualOff }

class PumpControlService {
  const PumpControlService(this._database);

  final FirebaseRealtimeDatabaseService _database;

  Future<void> setAutomatic(String plantId) async {
    await _database.updateData(
      buildPumpControlPath(plantId),
      buildPumpControlPayload(
        action: PumpControlAction.automatic,
        now: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> turnOffManual(String plantId) async {
    await _database.updateData(
      buildPumpControlPath(plantId),
      buildPumpControlPayload(
        action: PumpControlAction.manualOff,
        now: DateTime.now().toUtc(),
      ),
    );
  }
}

String buildRegimePlantPath(String plantId) {
  return 'plant/${plantId.trim()}';
}

String buildPumpControlPath(String plantId) {
  return '${buildRegimePlantPath(plantId)}/control/pump';
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
        final value = await database.getData(buildRegimePlantPath(plantId));
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

double _firstDouble(List<dynamic> candidates) {
  for (final candidate in candidates) {
    if (candidate == null) {
      continue;
    }
    final parsed = _parseDouble(candidate);
    if (parsed != 0.0 || candidate.toString() == '0') {
      return parsed;
    }
  }
  return 0.0;
}

double _parseDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
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
