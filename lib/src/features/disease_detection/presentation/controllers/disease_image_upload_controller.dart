import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:app_iot/src/features/home/domain/entities/plant.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

const _noDiseaseDetectedLabel = 'Kh\u00f4ng ph\u00e1t hi\u1ec7n b\u1ec7nh';

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
    this.requestId = '',
    this.severity = '',
    this.treatment = '',
    this.timedOut = false,
  });

  final String snapshotUrl;
  final String capturedAt;
  final bool hasServerSnapshot;
  final List<DetectionItem> detections;
  final String requestId;
  final String severity;
  final String treatment;
  final bool timedOut;

  DetectionItem? get latestDetection =>
      detections.isEmpty ? null : detections.first;
}

class DiseaseImageUploadService {
  const DiseaseImageUploadService({
    required this.database,
    required this.storage,
  });

  final FirebaseDatabase database;
  final FirebaseStorage storage;

  Future<DiseaseImageUploadResult> uploadImage({
    required String plantId,
    required XFile image,
    void Function()? onQueued,
  }) async {
    final normalizedPlantId = plantId.trim();
    if (!RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(normalizedPlantId)) {
      throw const DiseaseImageUploadException('Mã cây không hợp lệ.');
    }

    final bytes = await image.readAsBytes();
    if (bytes.isEmpty) {
      throw const DiseaseImageUploadException('Ảnh được chọn đang trống.');
    }

    final now = DateTime.now().toUtc();
    final randomSuffix = Random.secure().nextInt(0x7fffffff).toRadixString(16);
    final requestId =
        'mobile_upload_${now.millisecondsSinceEpoch}_$randomSuffix';
    final capturedAt = now.toIso8601String();
    final storagePath =
        'plants/$normalizedPlantId/mobile_uploads/$requestId.jpg';
    final storageRef = storage.ref().child(storagePath);
    late final String downloadUrl;

    try {
      await storageRef.putData(
        bytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'plant_id': normalizedPlantId,
            'request_id': requestId,
            'source': 'mobile_app',
          },
        ),
      );
      downloadUrl = await storageRef.getDownloadURL();
      await database.ref('plants/$normalizedPlantId/commands/analyze').set({
        'status': 1,
        'request_id': requestId,
        'image_storage_path': storageRef.fullPath,
        'image_url': downloadUrl,
        'plant_id': normalizedPlantId,
        'source': 'mobile_app',
        'captured_at': capturedAt,
        'created_at': now.millisecondsSinceEpoch / 1000,
      });
    } catch (error) {
      throw DiseaseImageUploadException(
        'Không thể tải ảnh hoặc gửi yêu cầu: $error',
      );
    }

    onQueued?.call();
    return _waitForResult(
      plantId: normalizedPlantId,
      requestId: requestId,
      snapshotUrl: downloadUrl,
      capturedAt: capturedAt,
    );
  }

  Future<DiseaseImageUploadResult> _waitForResult({
    required String plantId,
    required String requestId,
    required String snapshotUrl,
    required String capturedAt,
  }) async {
    final completer = Completer<DiseaseImageUploadResult>();
    final captureRef = database.ref(
      'plants/$plantId/plant_captures/$requestId',
    );
    final commandRef = database.ref('plants/$plantId/commands/analyze');
    void fail(Object error) {
      if (!completer.isCompleted) {
        completer.completeError(
          error is DiseaseImageUploadException
              ? error
              : DiseaseImageUploadException(
                  'Không đọc được kết quả từ Firebase: $error',
                ),
        );
      }
    }

    final captureSubscription = captureRef.onValue.listen((event) {
      final result = _asMap(event.snapshot.value);
      if (result['request_id']?.toString() != requestId) {
        return;
      }
      final status = result['status']?.toString().toLowerCase();
      final capturePath = 'plants/$plantId/plant_captures/$requestId';
      if (status == 'completed' && !completer.isCompleted) {
        completer.complete(
          _parseUploadResult(
            result,
            fallbackSnapshotUrl: snapshotUrl,
            fallbackTime: capturedAt,
            sourceDocumentPath: capturePath,
          ),
        );
      } else if (status == 'failed' && !completer.isCompleted) {
        fail(
          DiseaseImageUploadException(
            result['error']?.toString() ?? 'Pi không thể phân tích ảnh.',
          ),
        );
      }
    }, onError: fail);
    final commandSubscription = commandRef.onValue.listen((event) {
      final command = _asMap(event.snapshot.value);
      if (command['request_id']?.toString() == requestId &&
          command['status']?.toString() == '-1') {
        fail(
          DiseaseImageUploadException(
            command['error']?.toString() ?? 'Pi không thể phân tích ảnh.',
          ),
        );
      }
    }, onError: fail);
    final timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (!completer.isCompleted) {
        completer.complete(
          DiseaseImageUploadResult(
            snapshotUrl: snapshotUrl,
            capturedAt: capturedAt,
            hasServerSnapshot: true,
            requestId: requestId,
            timedOut: true,
            detections: _noDiseaseDetections(
              fallbackTime: capturedAt,
              fallbackSnapshotUrl: snapshotUrl,
              sourceDocumentPath: 'plants/$plantId/plant_captures/$requestId',
            ),
          ),
        );
      }
    });

    try {
      return await completer.future;
    } finally {
      timeoutTimer.cancel();
      await captureSubscription.cancel();
      await commandSubscription.cancel();
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
  String sourceDocumentPath = '',
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
      payload['captured_at'],
      payload['capturedAt'],
      payload['capture_time'],
      payload['captureTime'],
      payload['processed_at'],
      payload['processedAt'],
      payload['uploaded_at'],
      payload['uploadedAt'],
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
      _processedSnapshotUrlFromMap(payload) ??
      _processedSnapshotUrlFromMap(root);
  final snapshotUrl = serverSnapshotUrl ?? fallbackSnapshotUrl;
  final requestId =
      _firstNonEmptyString([payload['request_id'], root['request_id']]) ?? '';
  final plantId =
      _firstNonEmptyString([payload['plant_id'], root['plant_id']]) ?? '';
  final effectiveSourcePath = sourceDocumentPath.isNotEmpty
      ? sourceDocumentPath
      : (requestId.isNotEmpty && plantId.isNotEmpty
          ? 'plants/$plantId/plant_captures/$requestId'
          : '');
  final detections = _extractDetectionItems(
    [
      if (normalizedData is Iterable && normalizedData is! String)
        normalizedData,
      payload['data'],
      payload['latest_objects'],
      payload['latestObjects'],
      payload['detected_objects'],
      payload['detectedObjects'],
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
    sourceDocumentPath: effectiveSourcePath,
  );
  final normalizedDetections = _normalizeDetectionList(detections);
  final effectiveDetections = normalizedDetections.isEmpty
      ? _noDiseaseDetections(
          fallbackTime: capturedAt,
          fallbackSnapshotUrl: snapshotUrl,
          sourceDocumentPath: effectiveSourcePath,
        )
      : normalizedDetections;

  return DiseaseImageUploadResult(
    snapshotUrl: snapshotUrl,
    capturedAt: capturedAt,
    hasServerSnapshot: serverSnapshotUrl?.trim().isNotEmpty ?? false,
    detections: effectiveDetections,
    requestId:
        _firstNonEmptyString([payload['request_id'], root['request_id']]) ?? '',
    severity:
        _firstNonEmptyString([payload['severity'], root['severity']]) ?? '',
    treatment:
        _firstNonEmptyString([
          payload['treatment'],
          payload['notes'],
          root['treatment'],
          root['notes'],
        ]) ??
        '',
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
  String sourceDocumentPath = '',
  int depth = 0,
}) {
  if (depth > 8) {
    return const <DetectionItem>[];
  }

  final items = <DetectionItem>[];

  for (final source in sources) {
    if (source is Iterable && source is! String) {
      final classItems = _extractClassArrayItems(
        source,
        fallbackTime: fallbackTime,
        fallbackSnapshotUrl: fallbackSnapshotUrl,
        sourceDocumentPath: sourceDocumentPath,
      );
      if (classItems.isNotEmpty) {
        items.addAll(classItems);
        continue;
      }

      for (final value in source) {
        final nestedItems = _extractDetectionItemsFromMap(
          _asMap(value),
          fallbackTime: fallbackTime,
          fallbackSnapshotUrl: fallbackSnapshotUrl,
          sourceDocumentPath: sourceDocumentPath,
          depth: depth + 1,
        );
        items.addAll(nestedItems);
      }
      continue;
    }

    final nestedItems = _extractDetectionItemsFromMap(
      _asMap(source),
      fallbackTime: fallbackTime,
      fallbackSnapshotUrl: fallbackSnapshotUrl,
      sourceDocumentPath: sourceDocumentPath,
      depth: depth + 1,
    );
    items.addAll(nestedItems);
  }

  return items;
}

List<DetectionItem> _extractDetectionItemsFromMap(
  Map<dynamic, dynamic> data, {
  required String fallbackTime,
  required String fallbackSnapshotUrl,
  String sourceDocumentPath = '',
  int depth = 0,
}) {
  if (data.isEmpty || depth > 8) {
    return const <DetectionItem>[];
  }

  final localTime = _stringifyTime(
    _firstNonNull([
      data['annotated_frame_local_saved_at'],
      data['latest_detection_at'],
      data['detected_at'],
      data['detectedAt'],
      data['captured_at'],
      data['capturedAt'],
      data['capture_time'],
      data['captureTime'],
      data['processed_at'],
      data['processedAt'],
      data['uploaded_at'],
      data['uploadedAt'],
      data['created_at'],
      data['createdAt'],
      data['saved_at'],
      data['savedAt'],
      data['firestore_saved_at'],
      data['received_at'],
      data['time'],
      data['timestamp'],
      fallbackTime,
    ]),
  );
  final localSnapshotUrl =
      _processedSnapshotUrlFromMap(data) ?? fallbackSnapshotUrl;

  final nestedItems = _extractDetectionItems(
    [
      data['latest_objects'],
      data['latestObjects'],
      data['detected_objects'],
      data['detectedObjects'],
      data['disease_list_unique_top'],
      data['disease_list'],
      data['disease_objects'],
      data['objects'],
      data['detections'],
      data['diseases'],
      data['predictions'],
      data['results'],
      data['all_classes_detected_vi'],
      data['all_classes_detected'],
      data['all_classes_detected_en'],
    ],
    fallbackTime: localTime,
    fallbackSnapshotUrl: localSnapshotUrl,
    sourceDocumentPath: sourceDocumentPath,
    depth: depth + 1,
  );
  if (nestedItems.isNotEmpty) {
    return nestedItems;
  }

  final directItem = _toDetectionItem(
    data,
    fallbackTime: localTime,
    fallbackSnapshotUrl: localSnapshotUrl,
    sourceDocumentPath: sourceDocumentPath,
  );
  if (directItem != null) {
    return <DetectionItem>[directItem];
  }

  return const <DetectionItem>[];
}

List<DetectionItem> _extractClassArrayItems(
  Iterable<dynamic> source, {
  required String fallbackTime,
  required String fallbackSnapshotUrl,
  String sourceDocumentPath = '',
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
        sourceDocumentPath: sourceDocumentPath,
      ),
    );
  }

  return items;
}

List<DetectionItem> _noDiseaseDetections({
  required String fallbackTime,
  required String fallbackSnapshotUrl,
  String sourceDocumentPath = '',
}) {
  if (fallbackTime.trim().isEmpty && fallbackSnapshotUrl.trim().isEmpty) {
    return const <DetectionItem>[];
  }

  return [
    DetectionItem(
      diseaseClass: _noDiseaseDetectedLabel,
      confidence: 0,
      time: fallbackTime,
      snapshotUrl: fallbackSnapshotUrl,
      sourceDocumentPath: sourceDocumentPath,
    ),
  ];
}

DetectionItem? _toDetectionItem(
  Map<dynamic, dynamic> data, {
  required String fallbackTime,
  required String fallbackSnapshotUrl,
  String sourceDocumentPath = '',
}) {
  if (data.isEmpty) {
    return null;
  }

  final diseaseClass = _firstNonEmptyString([
    data['class_name_vi'],
    data['class_vi'],
    data['label_vi'],
    data['disease_vi'],
    data['disease_name_vi'],
    data['class_name'],
    data['class'],
    data['label'],
    data['disease'],
    data['disease_class'],
    data['diseaseClass'],
    data['pest_type'],
    data['disease_name'],
    _firstStringFromArrayLike(data['all_classes_detected_vi']),
    _firstStringFromArrayLike(data['all_classes_detected']),
    data['class_name_en'],
    data['class_en'],
    data['label_en'],
    data['disease_en'],
    data['disease_name_en'],
    data['prediction'],
    data['result'],
    _firstStringFromArrayLike(data['all_classes_detected_en']),
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
        data['captured_at'],
        data['capturedAt'],
        data['capture_time'],
        data['captureTime'],
        data['processed_at'],
        data['processedAt'],
        data['uploaded_at'],
        data['uploadedAt'],
        data['created_at'],
        data['createdAt'],
        data['saved_at'],
        data['savedAt'],
        data['firestore_saved_at'],
        data['received_at'],
        data['time'],
        data['timestamp'],
        fallbackTime,
      ]),
    ),
    snapshotUrl: _processedSnapshotUrlFromMap(data) ?? fallbackSnapshotUrl,
    sourceDocumentPath: sourceDocumentPath,
  );
}

String? _processedSnapshotUrlFromMap(Map<dynamic, dynamic> data) {
  final base64Image = _firstNonEmptyString([
    data['annotated_frame_base64'],
    data['annotated_image_base64'],
    data['processed_frame_base64'],
    data['processed_image_base64'],
    data['output_frame_base64'],
    data['output_image_base64'],
    data['result_frame_base64'],
    data['result_image_base64'],
  ]);
  if (base64Image != null) {
    return base64Image.startsWith('data:image/')
        ? base64Image
        : 'data:image/jpeg;base64,$base64Image';
  }

  return _firstNonEmptyString([
    data['annotated_frame_storage_path'],
    data['latest_annotated_frame_storage_path'],
    data['annotatedFrameStoragePath'],
    data['annotated_frame_url'],
    data['latest_annotated_frame_url'],
    data['annotatedFrameUrl'],
    data['annotated_image_url'],
    data['annotatedImageUrl'],
    data['annotated_frame'],
    data['annotatedFrame'],
    data['annotated_image'],
    data['annotatedImage'],
    data['processed_frame_storage_path'],
    data['processedFrameStoragePath'],
    data['processed_frame_url'],
    data['processedFrameUrl'],
    data['processed_image_url'],
    data['processedImageUrl'],
    data['processed_frame'],
    data['processedFrame'],
    data['processed_image'],
    data['processedImage'],
    data['output_frame_storage_path'],
    data['outputFrameStoragePath'],
    data['output_frame_url'],
    data['outputFrameUrl'],
    data['output_image_url'],
    data['outputImageUrl'],
    data['output_frame'],
    data['outputFrame'],
    data['output_image'],
    data['outputImage'],
    data['result_frame_storage_path'],
    data['resultFrameStoragePath'],
    data['result_image_storage_path'],
    data['resultImageStoragePath'],
    data['result_frame_url'],
    data['resultFrameUrl'],
    data['result_image_url'],
    data['resultImageUrl'],
    data['result_frame'],
    data['resultFrame'],
    data['result_image'],
    data['resultImage'],
    data['snapshot_url'],
    data['snapshotUrl'],
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

final diseaseImageUploadServiceProvider = Provider<DiseaseImageUploadService>((
  ref,
) {
  return DiseaseImageUploadService(
    database: FirebaseDatabase.instance,
    storage: FirebaseStorage.instance,
  );
});

final diseaseImageUploadInFlightProvider = StateProvider.autoDispose
    .family<bool, String>((ref, plantId) => false);

final diseaseImageUploadLatestResultProvider = StateProvider.autoDispose
    .family<DiseaseImageUploadResult?, String>((ref, plantId) => null);
