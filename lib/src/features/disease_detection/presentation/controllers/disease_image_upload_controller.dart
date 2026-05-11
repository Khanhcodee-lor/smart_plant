import 'dart:convert';

import 'package:app_iot/src/features/home/domain/entities/plant.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

const diseaseImageUploadEndpoint = String.fromEnvironment(
  'DISEASE_UPLOAD_API_URL',
  defaultValue: 'https://khanhsssd-khanhdz.hf.space/api/detect',
);

class DiseaseImageUploadException implements Exception {
  const DiseaseImageUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DiseaseImageUploadResult {
  const DiseaseImageUploadResult({
    required this.snapshotUrl,
    required this.capturedAt,
    required this.hasServerSnapshot,
    this.detections = const <DetectionItem>[],
  });

  final String snapshotUrl;
  final String capturedAt;
  final bool hasServerSnapshot;
  final List<DetectionItem> detections;

  DetectionItem? get latestDetection =>
      detections.isEmpty ? null : detections.first;
}

class DiseaseImageUploadService {
  const DiseaseImageUploadService(this._dio);

  final Dio _dio;

  Future<DiseaseImageUploadResult> uploadImage({
    required String plantId,
    required XFile image,
  }) async {
    final endpoint = diseaseImageUploadEndpoint.trim();
    if (endpoint.isEmpty) {
      throw const DiseaseImageUploadException(
        'Chưa cấu hình API upload ảnh. Thêm --dart-define=DISEASE_UPLOAD_API_URL=https://server-cua-ban/detect khi chạy app.',
      );
    }

    final normalizedPlantId = plantId.trim();
    if (normalizedPlantId.isEmpty) {
      throw const DiseaseImageUploadException('Không tìm thấy mã cây để gửi.');
    }

    final bytes = await image.readAsBytes();
    final frame = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    final capturedAt = _formatDateTime(DateTime.now());
    final fallbackSnapshotUrl = image.path.trim().isEmpty ? frame : image.path;

    try {
      final response = await _dio.post<dynamic>(
        endpoint,
        data: {
          'frame': frame,
          'device_id': normalizedPlantId,
          'device': normalizedPlantId,
          'plant_id': normalizedPlantId,
          'source': 'mobile_app',
          'captured_at': DateTime.now().toUtc().toIso8601String(),
          'persist': true,
        },
        options: Options(contentType: Headers.jsonContentType),
      );

      return _parseUploadResult(
        response.data,
        fallbackSnapshotUrl: fallbackSnapshotUrl,
        fallbackTime: capturedAt,
      );
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final serverMessage = error.response?.data?.toString();
      final message = serverMessage == null || serverMessage.trim().isEmpty
          ? error.message
          : serverMessage;

      throw DiseaseImageUploadException(
        statusCode == null
            ? 'Gửi ảnh lên server thất bại: $message'
            : 'Server trả lỗi $statusCode: $message',
      );
    }
  }
}

@visibleForTesting
DiseaseImageUploadResult debugParseDiseaseImageUploadResult(
  dynamic data, {
  String fallbackSnapshotUrl = 'local.jpg',
  String fallbackTime = '2026-05-11 10:50:00',
}) {
  return _parseUploadResult(
    data,
    fallbackSnapshotUrl: fallbackSnapshotUrl,
    fallbackTime: fallbackTime,
  );
}

DiseaseImageUploadResult _parseUploadResult(
  dynamic data, {
  required String fallbackSnapshotUrl,
  required String fallbackTime,
}) {
  final normalizedData = _normalizeResponseData(data);
  final root = _asMap(normalizedData);
  final payload = _firstMap([
    root['data'],
    root['result'],
    root['response'],
    root['prediction'],
    root,
  ]);

  final capturedAt = _stringifyTime(
    _firstNonNull([
      payload['annotated_frame_local_saved_at'],
      payload['latest_detection_at'],
      payload['detected_at'],
      payload['detectedAt'],
      payload['created_at'],
      payload['createdAt'],
      payload['saved_at'],
      payload['savedAt'],
      payload['firestore_saved_at'],
      payload['received_at'],
      payload['time'],
      payload['timestamp'],
      fallbackTime,
    ]),
  );
  final serverSnapshotUrl =
      _snapshotUrlFromMap(payload) ?? _snapshotUrlFromMap(root);
  final snapshotUrl = serverSnapshotUrl ?? fallbackSnapshotUrl;
  final detections = _extractDetectionItems(
    [
      if (normalizedData is Iterable && normalizedData is! String)
        normalizedData,
      payload['data'],
      payload['disease_list_unique_top'],
      payload['disease_list'],
      payload['disease_objects'],
      payload['objects'],
      payload['detections'],
      payload['diseases'],
      payload['predictions'],
      payload['results'],
      payload['all_classes_detected_en'],
      payload['all_classes_detected'],
      payload,
    ],
    fallbackTime: capturedAt,
    fallbackSnapshotUrl: snapshotUrl,
  );
  final normalizedDetections = _normalizeDetectionList(detections);

  return DiseaseImageUploadResult(
    snapshotUrl: snapshotUrl,
    capturedAt: capturedAt,
    hasServerSnapshot: serverSnapshotUrl?.trim().isNotEmpty ?? false,
    detections: normalizedDetections,
  );
}

dynamic _normalizeResponseData(dynamic data) {
  if (data is String) {
    final normalized = data.trim();
    if (normalized.isEmpty) {
      return const <String, dynamic>{};
    }

    try {
      return jsonDecode(normalized);
    } on FormatException {
      return {'result': normalized};
    }
  }

  return data ?? const <String, dynamic>{};
}

List<DetectionItem> _extractDetectionItems(
  List<dynamic> sources, {
  required String fallbackTime,
  required String fallbackSnapshotUrl,
}) {
  final items = <DetectionItem>[];

  for (final source in sources) {
    if (source is Iterable && source is! String) {
      final classItems = _extractClassArrayItems(
        source,
        fallbackTime: fallbackTime,
        fallbackSnapshotUrl: fallbackSnapshotUrl,
      );
      if (classItems.isNotEmpty) {
        items.addAll(classItems);
        continue;
      }

      for (final value in source) {
        final item = _toDetectionItem(
          _asMap(value),
          fallbackTime: fallbackTime,
          fallbackSnapshotUrl: fallbackSnapshotUrl,
        );
        if (item != null) {
          items.add(item);
        }
      }
      continue;
    }

    final item = _toDetectionItem(
      _asMap(source),
      fallbackTime: fallbackTime,
      fallbackSnapshotUrl: fallbackSnapshotUrl,
    );
    if (item != null) {
      items.add(item);
    }
  }

  return items;
}

List<DetectionItem> _extractClassArrayItems(
  Iterable<dynamic> source, {
  required String fallbackTime,
  required String fallbackSnapshotUrl,
}) {
  final items = <DetectionItem>[];
  final confidences = source
      .whereType<num>()
      .map((value) => value.toDouble())
      .toList(growable: false);

  for (final value in source) {
    if (value is Map) {
      return const <DetectionItem>[];
    }

    final diseaseClass = value?.toString().trim();
    if (diseaseClass == null ||
        diseaseClass.isEmpty ||
        double.tryParse(diseaseClass) != null) {
      continue;
    }

    items.add(
      DetectionItem(
        diseaseClass: diseaseClass,
        confidence: confidences.isEmpty
            ? 0
            : _normalizeConfidence(confidences.first),
        time: fallbackTime,
        snapshotUrl: fallbackSnapshotUrl,
      ),
    );
  }

  return items;
}

DetectionItem? _toDetectionItem(
  Map<dynamic, dynamic> data, {
  required String fallbackTime,
  required String fallbackSnapshotUrl,
}) {
  if (data.isEmpty) {
    return null;
  }

  final diseaseClass = _firstNonEmptyString([
    data['class_name_en'],
    data['class_name'],
    data['class'],
    data['class_en'],
    data['label'],
    data['label_en'],
    data['disease'],
    data['disease_en'],
    data['diseaseClass'],
    data['disease_name_en'],
    data['disease_name'],
    data['prediction'],
    data['result'],
    _firstStringFromArrayLike(data['all_classes_detected_en']),
    _firstStringFromArrayLike(data['all_classes_detected']),
  ]);
  if (diseaseClass == null) {
    return null;
  }

  return DetectionItem(
    diseaseClass: diseaseClass,
    confidence: _normalizeConfidence(
      _firstNonNull([
        data['confidence'],
        data['score'],
        data['probability'],
        data['best_confidence'],
        data['highest_confidence'],
        data['max_confidence'],
        data['avg_confidence'],
        _firstNumericFromArrayLike(data['confidences']),
        _firstNumericFromArrayLike(data['all_confidences']),
      ]),
    ),
    time: _stringifyTime(
      _firstNonNull([
        data['annotated_frame_local_saved_at'],
        data['latest_detection_at'],
        data['detected_at'],
        data['detectedAt'],
        data['created_at'],
        data['createdAt'],
        data['saved_at'],
        data['savedAt'],
        data['time'],
        data['timestamp'],
        fallbackTime,
      ]),
    ),
    snapshotUrl: _snapshotUrlFromMap(data) ?? fallbackSnapshotUrl,
  );
}

String? _snapshotUrlFromMap(Map<dynamic, dynamic> data) {
  final base64Image = _firstNonEmptyString([
    data['annotated_frame_base64'],
    data['annotated_image_base64'],
    data['image_base64'],
  ]);
  if (base64Image != null) {
    return base64Image.startsWith('data:image/')
        ? base64Image
        : 'data:image/jpeg;base64,$base64Image';
  }

  return _firstNonEmptyString([
    data['annotated_frame_storage_path'],
    data['latest_annotated_frame_storage_path'],
    data['frame_storage_path'],
    data['annotatedFrameStoragePath'],
    data['latest_snapshot_path'],
    data['snapshot_path'],
    data['annotated_frame_url'],
    data['latest_annotated_frame_url'],
    data['frame_url'],
    data['annotatedFrameUrl'],
    data['latest_snapshot_url'],
    data['snapshot'],
    data['snapshotUrl'],
    data['image_url'],
    data['imageUrl'],
    data['annotated_image'],
    data['image'],
  ]);
}

List<DetectionItem> _normalizeDetectionList(List<DetectionItem> items) {
  final deduped = <String, DetectionItem>{};
  for (final item in items) {
    final key = item.diseaseClass.trim().toLowerCase();
    if (key.isEmpty) {
      continue;
    }

    final current = deduped[key];
    if (current == null || item.confidence > current.confidence) {
      deduped[key] = item;
    }
  }
  return deduped.values.toList();
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

double _normalizeConfidence(dynamic value) {
  final confidence = _parseDouble(value);
  if (confidence > 1 && confidence <= 100) {
    return confidence / 100;
  }
  return confidence;
}

double _parseDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
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

  final parsedDate = DateTime.tryParse(stringValue.replaceFirst(' ', 'T'));
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
  return _formatDateTime(
    DateTime.fromMillisecondsSinceEpoch(milliseconds.round(), isUtc: true),
  );
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

final diseaseImageUploadDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 45),
    ),
  );
});

final diseaseImageUploadServiceProvider = Provider<DiseaseImageUploadService>((
  ref,
) {
  return DiseaseImageUploadService(ref.watch(diseaseImageUploadDioProvider));
});

final diseaseImageUploadInFlightProvider = StateProvider.autoDispose
    .family<bool, String>((ref, plantId) => false);

final diseaseImageUploadLatestResultProvider = StateProvider.autoDispose
    .family<DiseaseImageUploadResult?, String>((ref, plantId) => null);
