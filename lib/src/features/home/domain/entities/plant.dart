import 'package:freezed_annotation/freezed_annotation.dart';

part 'plant.freezed.dart';

@freezed
class DetectionItem with _$DetectionItem {
  const factory DetectionItem({
    required String diseaseClass,
    required double confidence,
    required String time,
    @Default('') String snapshotUrl,
    @Default('') String sourceDocumentPath,
  }) = _DetectionItem;
}

@freezed
class SensorHistoryItem with _$SensorHistoryItem {
  const factory SensorHistoryItem({
    required double temperature,
    required double humidity,
    required double soilMoisture,
    required String time,
  }) = _SensorHistoryItem;
}

@freezed
class Plant with _$Plant {
  const factory Plant({
    required String id,
    required String name,
    required String status,
    required String imageUrl,
    required String videoUrl,
    required double temperature,
    required double humidity,
    required double soilMoisture,
    required DetectionItem? latestDetection,
    required List<DetectionItem> history,
    required List<SensorHistoryItem> sensorHistory,
  }) = _Plant;

  factory Plant.fromFirestore(String id, Map<dynamic, dynamic> data) =>
      Plant.fromMap(id, data);

  factory Plant.fromMap(String id, Map<dynamic, dynamic> data) {
    final normalizedData = _asMap(data);

    final info = _firstMap([
      normalizedData['info'],
      normalizedData['plantInfo'],
    ]);
    final streamData = _firstMap([
      normalizedData['stream'],
      normalizedData['videoStream'],
    ]);
    final detections = _firstMap([
      normalizedData['detections'],
      normalizedData['diseaseDetection'],
      normalizedData['detection'],
    ]);
    final sensors = _firstMap([
      normalizedData['sensors'],
      normalizedData['sensor'],
    ]);

    final stringName =
        _firstNonEmptyString([
          info['name'],
          normalizedData['name'],
          normalizedData['plantName'],
          normalizedData['title'],
        ]) ??
        _inferPlantName(id);

    final stringImage =
        _firstNonEmptyString([
          info['image'],
          normalizedData['image'],
          normalizedData['imageUrl'],
          normalizedData['thumbnail'],
        ]) ??
        '';

    final videoUrl =
        _firstNonEmptyString([
          streamData['video_url'],
          streamData['videoUrl'],
          normalizedData['video_url'],
          normalizedData['videoUrl'],
          normalizedData['streamUrl'],
        ]) ??
        '';

    final latestData = _firstMap([
      detections['latest'],
      normalizedData['latest'],
      normalizedData['latestDetection'],
      normalizedData['currentDetection'],
      normalizedData,
    ]);

    final latestDiseaseClass = _firstNonEmptyString([
      latestData['class_name_en'],
      latestData['class_name'],
      latestData['class'],
      latestData['label'],
      latestData['disease'],
      latestData['diseaseClass'],
      latestData['disease_name_en'],
      latestData['disease_name'],
      _firstDiseaseClassFromListLike(latestData['disease_list_unique_top']),
      _firstDiseaseClassFromListLike(latestData['disease_list']),
      _firstDiseaseClassFromListLike(latestData['disease_objects']),
      _firstDiseaseClassFromListLike(latestData['objects']),
      _firstStringFromArrayLike(latestData['all_classes_detected_en']),
      _firstStringFromArrayLike(latestData['all_classes_detected']),
      latestData['prediction'],
      latestData['result'],
    ]);
    final latestConfidence = _normalizeConfidence(
      _firstNonNull([
        latestData['confidence'],
        latestData['score'],
        latestData['probability'],
        latestData['best_confidence'],
        latestData['highest_confidence'],
        latestData['max_confidence'],
        latestData['avg_confidence'],
        _firstDiseaseConfidenceFromListLike(
          latestData['disease_list_unique_top'],
        ),
        _firstDiseaseConfidenceFromListLike(latestData['disease_list']),
        _firstDiseaseConfidenceFromListLike(latestData['disease_objects']),
        _firstDiseaseConfidenceFromListLike(latestData['objects']),
        _firstNumericFromArrayLike(latestData['confidences']),
        _firstNumericFromArrayLike(latestData['all_confidences']),
      ]),
    );
    final latestTime = _stringifyTime(
      _firstNonNull([
        latestData['annotated_frame_local_saved_at'],
        latestData['latest_detection_at'],
        latestData['detected_at'],
        latestData['detectedAt'],
        latestData['created_at'],
        latestData['createdAt'],
        latestData['saved_at'],
        latestData['savedAt'],
        latestData['firestore_saved_at'],
        latestData['received_at'],
        latestData['time'],
        latestData['timestamp'],
      ]),
    );
    final safeLatestImageUrl = _safeImageUrlCandidate(latestData['image_url']);
    final safeLatestImageUrlLegacy = _safeImageUrlCandidate(
      latestData['imageUrl'],
    );
    final latestSnapshot =
        _firstNonEmptyString([
          latestData['annotated_frame_storage_path'],
          latestData['frame_storage_path'],
          latestData['annotatedFrameStoragePath'],
          latestData['snapshot_path'],
          latestData['annotated_frame_url'],
          latestData['frame_url'],
          latestData['annotatedFrameUrl'],
          latestData['snapshot'],
          latestData['snapshotUrl'],
          latestData['annotated_image_url'],
          latestData['annotatedImageUrl'],
          latestData['processed_image_url'],
          latestData['processedImageUrl'],
          latestData['output_image_url'],
          latestData['outputImageUrl'],
          latestData['annotated_image'],
          latestData['image'],
          safeLatestImageUrl,
          safeLatestImageUrlLegacy,
        ]) ??
        '';

    DetectionItem? latestDetection;
    if (latestDiseaseClass != null || latestConfidence > 0) {
      latestDetection = DetectionItem(
        diseaseClass: latestDiseaseClass ?? 'Unknown',
        confidence: latestConfidence,
        time: latestTime,
        snapshotUrl: latestSnapshot,
      );
    }

    final latestDiseaseText = latestDetection?.diseaseClass;
    final stringStatus =
        (latestDiseaseText != null &&
            latestDiseaseText.isNotEmpty &&
            latestDiseaseText.toLowerCase() != 'healthy' &&
            latestDiseaseText.toLowerCase() != 'unknown')
        ? latestDiseaseText
        : 'Hãy đến thăm khu vườn của bạn';

    final historyNodes = _collectMapEntries([
      detections['history'],
      normalizedData['history'],
      normalizedData['detectionHistory'],
    ]);
    final historyList = historyNodes
        .map(_buildDetectionItem)
        .whereType<DetectionItem>()
        .toList();

    final sensorsLatest = _firstMap([
      sensors['latest'],
      normalizedData['latestSensors'],
      normalizedData['sensorLatest'],
    ]);
    final temperature = _firstDouble([
      sensorsLatest['temperature'],
      sensorsLatest['temp'],
      normalizedData['temperature'],
    ]);
    final humidity = _firstDouble([
      sensorsLatest['humidity'],
      normalizedData['humidity'],
    ]);
    final soilMoisture = _firstDouble([
      sensorsLatest['soilMoisture'],
      sensorsLatest['soil_moisture'],
      normalizedData['soilMoisture'],
      normalizedData['soil_moisture'],
    ]);

    final sensorHistoryNodes = _collectMapEntries([
      sensors['history'],
      normalizedData['sensorHistory'],
      normalizedData['sensorsHistory'],
    ]);
    final sensorHistoryList = sensorHistoryNodes
        .map(_buildSensorHistoryItem)
        .whereType<SensorHistoryItem>()
        .toList();

    sensorHistoryList.sort((a, b) => a.time.compareTo(b.time));
    historyList.sort((a, b) => b.time.compareTo(a.time));

    return Plant(
      id: id,
      name: stringName,
      status: stringStatus,
      imageUrl: stringImage,
      videoUrl: videoUrl,
      temperature: temperature,
      humidity: humidity,
      soilMoisture: soilMoisture,
      latestDetection: latestDetection,
      history: historyList,
      sensorHistory: sensorHistoryList,
    );
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

Map<dynamic, dynamic> _firstMap(List<dynamic> candidates) {
  for (final candidate in candidates) {
    final map = _asMap(candidate);
    if (map.isNotEmpty) {
      return map;
    }
  }
  return <dynamic, dynamic>{};
}

dynamic _firstNonNull(List<dynamic> candidates) {
  for (final candidate in candidates) {
    if (candidate != null) {
      return candidate;
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

String? _safeImageUrlCandidate(dynamic value) {
  final url = value?.toString().trim();
  if (url == null || url.isEmpty) {
    return null;
  }
  if (_isFirebaseStorageUrl(url)) {
    return url;
  }
  return null;
}

bool _isFirebaseStorageUrl(String value) {
  final normalized = value.trim();
  if (normalized.startsWith('gs://')) {
    return true;
  }

  final uri = Uri.tryParse(normalized);
  if (uri == null) {
    return false;
  }

  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') {
    return false;
  }

  final host = uri.host.toLowerCase();
  return host == 'storage.googleapis.com' ||
      host.contains('firebasestorage.googleapis.com');
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

double _normalizeConfidence(dynamic value) {
  final confidence = _parseDouble(value);
  if (confidence > 1 && confidence <= 100) {
    return confidence / 100;
  }
  return confidence;
}

List<Map<dynamic, dynamic>> _collectMapEntries(List<dynamic> candidates) {
  final items = <Map<dynamic, dynamic>>[];

  for (final candidate in candidates) {
    if (candidate is List) {
      for (final item in candidate) {
        final map = _asMap(item);
        if (map.isNotEmpty) {
          items.add(map);
        }
      }
    } else if (candidate is Map) {
      for (final item in candidate.values) {
        final map = _asMap(item);
        if (map.isNotEmpty) {
          items.add(map);
        }
      }
    }
  }

  return items;
}

DetectionItem? _buildDetectionItem(Map<dynamic, dynamic> value) {
  final diseaseClass = _firstNonEmptyString([
    value['class_name_en'],
    value['class_name'],
    value['class'],
    value['label'],
    value['disease'],
    value['diseaseClass'],
    value['disease_name_en'],
    value['disease_name'],
    _firstStringFromArrayLike(value['all_classes_detected_en']),
    _firstStringFromArrayLike(value['all_classes_detected']),
    value['prediction'],
    value['result'],
  ]);
  final confidence = _normalizeConfidence(
    _firstNonNull([
      value['confidence'],
      value['score'],
      value['probability'],
      value['best_confidence'],
      value['max_confidence'],
      _firstNumericFromArrayLike(value['confidences']),
      _firstNumericFromArrayLike(value['all_confidences']),
    ]),
  );
  final time = _stringifyTime(
    _firstNonNull([
      value['annotated_frame_local_saved_at'],
      value['latest_detection_at'],
      value['detected_at'],
      value['detectedAt'],
      value['created_at'],
      value['createdAt'],
      value['saved_at'],
      value['savedAt'],
      value['time'],
      value['timestamp'],
    ]),
  );
  final snapshotUrl =
      _firstNonEmptyString([
        value['annotated_frame_storage_path'],
        value['frame_storage_path'],
        value['annotatedFrameStoragePath'],
        value['snapshot_path'],
        value['annotated_frame_url'],
        value['frame_url'],
        value['annotatedFrameUrl'],
        value['snapshot'],
        value['snapshotUrl'],
        value['annotated_image_url'],
        value['annotatedImageUrl'],
        value['processed_image_url'],
        value['processedImageUrl'],
        value['output_image_url'],
        value['outputImageUrl'],
        value['annotated_image'],
        value['image'],
        _safeImageUrlCandidate(value['image_url']),
        _safeImageUrlCandidate(value['imageUrl']),
      ]) ??
      '';

  if (diseaseClass == null &&
      confidence == 0 &&
      time.isEmpty &&
      snapshotUrl.isEmpty) {
    return null;
  }

  return DetectionItem(
    diseaseClass: diseaseClass ?? 'Unknown',
    confidence: confidence,
    time: time,
    snapshotUrl: snapshotUrl,
  );
}

SensorHistoryItem? _buildSensorHistoryItem(Map<dynamic, dynamic> value) {
  final temperature = _firstDouble([value['temperature'], value['temp']]);
  final humidity = _firstDouble([value['humidity']]);
  final soilMoisture = _firstDouble([
    value['soilMoisture'],
    value['soil_moisture'],
  ]);
  final time = _stringifyTime(
    _firstNonNull([
      value['time'],
      value['timestamp'],
      value['createdAt'],
      value['created_at'],
      value['saved_at'],
    ]),
  );

  if (temperature == 0 && humidity == 0 && soilMoisture == 0 && time.isEmpty) {
    return null;
  }

  return SensorHistoryItem(
    temperature: temperature,
    humidity: humidity,
    soilMoisture: soilMoisture,
    time: time,
  );
}

String _stringifyTime(dynamic value) {
  if (value == null) {
    return '';
  }
  if (value is DateTime) {
    return _formatDateTime(value);
  }
  if (value is num) {
    return _formatEpoch(value.toDouble());
  }

  final stringValue = value.toString().trim();
  if (stringValue.isEmpty) {
    return '';
  }

  final parsedNumber = double.tryParse(stringValue);
  if (parsedNumber != null) {
    return _formatEpoch(parsedNumber);
  }

  final parsedDate = _tryParseDateTime(stringValue);
  if (parsedDate != null) {
    return _formatDateTime(parsedDate);
  }

  return stringValue;
}

String _formatDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  final second = local.second.toString().padLeft(2, '0');

  return '$year-$month-$day $hour:$minute:$second';
}

String _formatEpoch(double value) {
  final milliseconds = value > 1000000000000 ? value : value * 1000;
  final dateTime = DateTime.fromMillisecondsSinceEpoch(
    milliseconds.round(),
    isUtc: true,
  );
  return _formatDateTime(dateTime);
}

DateTime? _tryParseDateTime(String value) {
  if (value.isEmpty) {
    return null;
  }

  return DateTime.tryParse(value.replaceFirst(' ', 'T'));
}

String? _firstStringFromArrayLike(dynamic value) {
  if (value is Iterable) {
    for (final item in value) {
      final candidate = item?.toString().trim();
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    }
  }
  return null;
}

double? _firstNumericFromArrayLike(dynamic value) {
  if (value is Iterable) {
    for (final item in value) {
      final parsed = _parseDouble(item);
      if (parsed > 0 || item?.toString() == '0') {
        return parsed;
      }
    }
  }
  return null;
}

String? _firstDiseaseClassFromListLike(dynamic value) {
  if (value is! Iterable) {
    return null;
  }

  for (final item in value) {
    final map = _asMap(item);
    if (map.isEmpty) {
      continue;
    }

    final diseaseClass = _firstNonEmptyString([
      map['class_name_en'],
      map['class_name'],
      map['class'],
      map['class_en'],
      map['label'],
      map['label_en'],
      map['disease'],
      map['disease_en'],
      map['diseaseClass'],
      map['disease_name_en'],
      map['disease_name'],
    ]);
    if (diseaseClass != null) {
      return diseaseClass;
    }
  }

  return null;
}

double? _firstDiseaseConfidenceFromListLike(dynamic value) {
  if (value is! Iterable) {
    return null;
  }

  for (final item in value) {
    final map = _asMap(item);
    if (map.isEmpty) {
      continue;
    }

    final confidence = _firstDouble([
      map['confidence'],
      map['score'],
      map['probability'],
      map['best_confidence'],
      map['highest_confidence'],
      map['max_confidence'],
      map['avg_confidence'],
    ]);
    if (confidence > 0) {
      return confidence;
    }
  }

  return null;
}

String _inferPlantName(String id) {
  final lowerId = id.toLowerCase();

  if (lowerId == 'all') {
    return 'CÃ  chua';
  }

  if (lowerId.contains('tomato')) {
    return 'Cà chua';
  }
  if (lowerId.contains('chili') || lowerId.contains('pepper')) {
    return 'Ớt';
  }
  if (lowerId.contains('cucumber')) {
    return 'Dưa leo';
  }

  final normalizedId = id.replaceAll('_', ' ').trim();
  if (normalizedId.isEmpty) {
    return 'Cây không xác định';
  }

  return normalizedId[0].toUpperCase() + normalizedId.substring(1);
}
