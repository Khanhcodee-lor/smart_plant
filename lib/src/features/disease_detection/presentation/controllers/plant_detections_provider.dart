import 'dart:async';

import 'package:app_iot/src/core/services/firebase/firebase_firestore_service.dart';
import 'package:app_iot/src/core/ulits/logger_ulits.dart';
import 'package:app_iot/src/features/home/domain/entities/plant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlantDetectionsData {
  const PlantDetectionsData({
    this.latestDetection,
    this.latestDetections = const <DetectionItem>[],
    this.history = const <DetectionItem>[],
    this.latestSnapshotUrl = '',
    this.latestCapturedAt = '',
  });

  final DetectionItem? latestDetection;
  final List<DetectionItem> latestDetections;
  final List<DetectionItem> history;
  final String latestSnapshotUrl;
  final String latestCapturedAt;

  bool get hasAnyData =>
      latestDetection != null ||
      latestDetections.isNotEmpty ||
      history.isNotEmpty ||
      latestSnapshotUrl.trim().isNotEmpty ||
      latestCapturedAt.trim().isNotEmpty;
}

final plantDetectionsProvider = StreamProvider.autoDispose
    .family<PlantDetectionsData, String>((ref, plantId) {
      final firestore = ref.watch(firebaseFirestoreServiceProvider);

      return Stream.multi((controller) {
        var docDetections = const PlantDetectionsData();
        var collectionDetections = const PlantDetectionsData();
        final documentPaths = _detectionDocumentPaths(plantId);
        final collectionPaths = _detectionCollectionPaths(plantId);

        void emitMerged() {
          controller.add(_mergeDetections(docDetections, collectionDetections));
        }

        void handleError(String path, Object error, StackTrace stackTrace) {
          if (_isPermissionDenied(error)) {
            LoggerUtils.i('Firestore path denied and ignored: $path');
            emitMerged();
            return;
          }

          LoggerUtils.e(
            'Failed to read Firestore path: $path',
            error,
            stackTrace,
          );
          emitMerged();
        }

        emitMerged();

        final subscriptions = <StreamSubscription<dynamic>>[
          for (final path in documentPaths)
            firestore
                .documentStream(path)
                .listen(
                  (data) {
                    final parsed = _parseDetectionsFromDocument(data);
                    _logParsedDetections(path, parsed);
                    docDetections = _mergeDetections(docDetections, parsed);
                    emitMerged();
                  },
                  onError: (error, stackTrace) {
                    handleError(path, error, stackTrace);
                  },
                ),
          for (final path in collectionPaths)
            firestore
                .collectionStreamWithIds(path)
                .listen(
                  (documents) {
                    final parsed = _parseDetectionsFromCollection(documents);
                    _logParsedDetections(path, parsed);
                    collectionDetections = _mergeDetections(
                      collectionDetections,
                      parsed,
                    );
                    emitMerged();
                  },
                  onError: (error, stackTrace) {
                    handleError(path, error, stackTrace);
                  },
                ),
        ];

        controller.onCancel = () async {
          for (final subscription in subscriptions) {
            await subscription.cancel();
          }
        };
      });
    });

@visibleForTesting
PlantDetectionsData debugParsePlantDetectionsDocument(
  Map<String, dynamic>? data,
) {
  return _parseDetectionsFromDocument(data);
}

@visibleForTesting
PlantDetectionsData debugParsePlantDetectionsCollection(
  List<FirestoreDocumentData> documents,
) {
  return _parseDetectionsFromCollection(documents);
}

@visibleForTesting
PlantDetectionsData debugMergePlantDetections(
  PlantDetectionsData primary,
  PlantDetectionsData secondary,
) {
  return _mergeDetections(primary, secondary);
}

PlantDetectionsData _parseDetectionsFromDocument(Map<String, dynamic>? data) {
  if (data == null) {
    return const PlantDetectionsData();
  }

  final normalized = Map<dynamic, dynamic>.from(data);
  final latestTime = _stringifyTime(
    _firstNonNull([
      normalized['latest_detection_at'],
      normalized['latestDetectionAt'],
      normalized['latest_detected_at'],
      normalized['annotated_frame_local_saved_at'],
      normalized['firestore_saved_at'],
      normalized['received_at'],
      normalized['timestamp'],
      normalized['updated_at'],
      normalized['updatedAt'],
    ]),
  );
  final latestSnapshotUrl =
      _firstNonEmptyString([
        normalized['annotated_frame_storage_path'],
        normalized['latest_annotated_frame_storage_path'],
        normalized['latest_snapshot_path'],
        normalized['annotated_frame_url'],
        normalized['latest_annotated_frame_url'],
        normalized['latest_snapshot_url'],
      ]) ??
      '';

  final latestItems = _extractFirstNonEmptyDetectionItemsFromCandidates(
    _detectionCandidateSources(normalized),
    fallbackTime: latestTime,
    fallbackSnapshotUrl: latestSnapshotUrl,
  );

  final latest = latestItems.isNotEmpty
      ? latestItems.first
      : _toDetectionItem(
          normalized,
          fallbackTime: latestTime,
          fallbackSnapshotUrl: latestSnapshotUrl,
        );

  final history = _extractDetectionItemsFromCandidates(
    [normalized['history'], normalized['detectionHistory']],
    fallbackTime: latestTime,
    fallbackSnapshotUrl: latestSnapshotUrl,
  );

  return _buildDetections(
    latest,
    history,
    latestDetections: latestItems,
    latestSnapshotUrl: latestSnapshotUrl,
    latestCapturedAt: latestTime,
  );
}

PlantDetectionsData _parseDetectionsFromCollection(
  List<FirestoreDocumentData> documents,
) {
  final history = <DetectionItem>[];
  var latestGroup = const <DetectionItem>[];

  for (final document in documents) {
    final normalized = Map<dynamic, dynamic>.from(document.data);
    final sourceDocumentPath = document.path.trim();
    final detectedTime = _stringifyTime(
      _firstNonNull([
        normalized['annotated_frame_local_saved_at'],
        normalized['latest_detection_at'],
        normalized['detected_at'],
        normalized['detectedAt'],
        normalized['created_at'],
        normalized['createdAt'],
        normalized['saved_at'],
        normalized['savedAt'],
        normalized['firestore_saved_at'],
        normalized['received_at'],
        normalized['time'],
        normalized['timestamp'],
      ]),
    );
    final snapshotUrl =
        _firstNonEmptyString([
          normalized['annotated_frame_storage_path'],
          normalized['frame_storage_path'],
          normalized['annotatedFrameStoragePath'],
          normalized['snapshot_path'],
          normalized['annotated_frame_url'],
          normalized['frame_url'],
          normalized['annotatedFrameUrl'],
          normalized['snapshot'],
          normalized['snapshotUrl'],
          normalized['image'],
          normalized['image_url'],
        ]) ??
        '';

    final nestedItems = _extractFirstNonEmptyDetectionItemsFromCandidates(
      _detectionCandidateSources(normalized),
      fallbackTime: detectedTime,
      fallbackSnapshotUrl: snapshotUrl,
      sourceDocumentPath: sourceDocumentPath,
    );
    if (nestedItems.isNotEmpty) {
      final normalizedItems = _normalizeDetectionList(nestedItems);
      history.addAll(normalizedItems);
      if (_isCandidateGroupNewer(normalizedItems, latestGroup)) {
        latestGroup = normalizedItems;
      }
      continue;
    }

    final directDetection = _toDetectionItem(
      normalized,
      fallbackTime: detectedTime,
      fallbackSnapshotUrl: snapshotUrl,
      sourceDocumentPath: sourceDocumentPath,
    );
    if (directDetection != null) {
      history.add(directDetection);
      final directGroup = <DetectionItem>[directDetection];
      if (_isCandidateGroupNewer(directGroup, latestGroup)) {
        latestGroup = directGroup;
      }
    }
  }

  return _buildDetections(
    latestGroup.isNotEmpty ? latestGroup.first : null,
    history,
    latestDetections: latestGroup,
  );
}

PlantDetectionsData _buildDetections(
  DetectionItem? latestDetection,
  List<DetectionItem> history, {
  List<DetectionItem> latestDetections = const <DetectionItem>[],
  String latestSnapshotUrl = '',
  String latestCapturedAt = '',
}) {
  final hydratedLatest = _hydrateDetections(
    latestDetections,
    fallbackTime: latestCapturedAt,
    fallbackSnapshotUrl: latestSnapshotUrl,
  );
  final hydratedLatestDetection = _hydrateDetection(
    latestDetection,
    fallbackTime: latestCapturedAt,
    fallbackSnapshotUrl: latestSnapshotUrl,
  );
  final hydratedHistory = _hydrateDetections(
    history,
    fallbackTime: latestCapturedAt,
    fallbackSnapshotUrl: latestSnapshotUrl,
  );
  final normalizedLatest = _normalizeDetectionList([
    ...hydratedLatest,
    ..._singleDetection(hydratedLatestDetection),
  ]);
  final mergedHistory = _normalizeDetectionList([
    ...hydratedHistory,
    ...normalizedLatest,
  ]);
  final effectiveLatest = normalizedLatest.isNotEmpty
      ? normalizedLatest.first
      : (mergedHistory.isNotEmpty
            ? mergedHistory.first
            : hydratedLatestDetection);
  final effectiveLatestDetections = normalizedLatest.isNotEmpty
      ? normalizedLatest
      : (effectiveLatest == null
            ? const <DetectionItem>[]
            : <DetectionItem>[effectiveLatest]);
  final effectiveSnapshotUrl =
      _firstNonEmptyDetectionSnapshot([
        ...effectiveLatestDetections,
        ...mergedHistory,
      ]) ??
      latestSnapshotUrl;
  final effectiveCapturedAt =
      _firstNonEmptyDetectionTime([
        ...effectiveLatestDetections,
        ...mergedHistory,
      ]) ??
      latestCapturedAt;

  return PlantDetectionsData(
    latestDetection: effectiveLatest,
    latestDetections: effectiveLatestDetections,
    history: mergedHistory,
    latestSnapshotUrl: effectiveSnapshotUrl,
    latestCapturedAt: effectiveCapturedAt,
  );
}

PlantDetectionsData _mergeDetections(
  PlantDetectionsData primary,
  PlantDetectionsData secondary,
) {
  final primaryLatest = primary.latestDetections.isNotEmpty
      ? primary.latestDetections
      : <DetectionItem>[
          if (primary.latestDetection != null) primary.latestDetection!,
        ];
  final secondaryLatest = secondary.latestDetections.isNotEmpty
      ? secondary.latestDetections
      : <DetectionItem>[
          if (secondary.latestDetection != null) secondary.latestDetection!,
        ];

  final latestDetections =
      _isCandidateGroupNewer(secondaryLatest, primaryLatest)
      ? secondaryLatest
      : primaryLatest;
  final latestDetection = latestDetections.isNotEmpty
      ? latestDetections.first
      : (secondary.latestDetection ?? primary.latestDetection);
  final fallbackSnapshotUrl =
      _firstNonEmptyDetectionSnapshot(latestDetections) ??
      secondary.latestSnapshotUrl.ifNotBlank ??
      primary.latestSnapshotUrl.ifNotBlank ??
      '';
  final fallbackCapturedAt =
      _firstNonEmptyDetectionTime(latestDetections) ??
      secondary.latestCapturedAt.ifNotBlank ??
      primary.latestCapturedAt.ifNotBlank ??
      '';

  return _buildDetections(
    latestDetection,
    [
      ...primary.history,
      ...secondary.history,
      if (primary.latestDetection != null) primary.latestDetection!,
      if (secondary.latestDetection != null) secondary.latestDetection!,
    ],
    latestDetections: latestDetections,
    latestSnapshotUrl: fallbackSnapshotUrl,
    latestCapturedAt: fallbackCapturedAt,
  );
}

List<DetectionItem> _extractFirstNonEmptyDetectionItemsFromCandidates(
  List<dynamic> sources, {
  String fallbackTime = '',
  String fallbackSnapshotUrl = '',
  String sourceDocumentPath = '',
  int depth = 0,
}) {
  for (final source in sources) {
    final items = _extractDetectionItemsFromCandidates(
      [source],
      fallbackTime: fallbackTime,
      fallbackSnapshotUrl: fallbackSnapshotUrl,
      sourceDocumentPath: sourceDocumentPath,
      depth: depth,
    );
    if (items.isNotEmpty) {
      return items;
    }
  }

  return const <DetectionItem>[];
}

List<DetectionItem> _extractDetectionItemsFromCandidates(
  List<dynamic> sources, {
  String fallbackTime = '',
  String fallbackSnapshotUrl = '',
  String sourceDocumentPath = '',
  int depth = 0,
}) {
  final history = <DetectionItem>[];

  for (final source in sources) {
    if (source is List) {
      final classItems = _extractDetectionItemsFromClassArray(
        source,
        fallbackTime: fallbackTime,
        fallbackSnapshotUrl: fallbackSnapshotUrl,
        sourceDocumentPath: sourceDocumentPath,
      );
      if (classItems.isNotEmpty) {
        history.addAll(classItems);
        continue;
      }

      for (final item in source) {
        final detections = _extractDetectionItemsFromMap(
          _asMap(item),
          fallbackTime: fallbackTime,
          fallbackSnapshotUrl: fallbackSnapshotUrl,
          sourceDocumentPath: sourceDocumentPath,
          depth: depth + 1,
        );
        history.addAll(detections);
      }
      continue;
    }

    if (source is Map) {
      history.addAll(
        _extractDetectionItemsFromMap(
          _asMap(source),
          fallbackTime: fallbackTime,
          fallbackSnapshotUrl: fallbackSnapshotUrl,
          sourceDocumentPath: sourceDocumentPath,
          depth: depth + 1,
        ),
      );
    }
  }

  return history;
}

List<DetectionItem> _extractDetectionItemsFromMap(
  Map<dynamic, dynamic> data, {
  required String fallbackTime,
  required String fallbackSnapshotUrl,
  required String sourceDocumentPath,
  required int depth,
}) {
  if (data.isEmpty || depth > 8) {
    return const <DetectionItem>[];
  }

  final localTime = _detectionTimeFromMap(data, fallbackTime: fallbackTime);
  final localSnapshotUrl = _snapshotUrlFromMap(
    data,
    fallbackSnapshotUrl: fallbackSnapshotUrl,
  );

  final nestedItems = _extractFirstNonEmptyDetectionItemsFromCandidates(
    _detectionCandidateSources(data),
    fallbackTime: localTime,
    fallbackSnapshotUrl: localSnapshotUrl,
    sourceDocumentPath: sourceDocumentPath,
    depth: depth + 1,
  );
  if (nestedItems.isNotEmpty) {
    return nestedItems;
  }

  final directDetection = _toDetectionItem(
    data,
    fallbackTime: localTime,
    fallbackSnapshotUrl: localSnapshotUrl,
    sourceDocumentPath: sourceDocumentPath,
  );
  if (directDetection != null) {
    return <DetectionItem>[directDetection];
  }

  final nestedMapItems = <DetectionItem>[];
  for (final value in data.values) {
    if (value is! Map && value is! List) {
      continue;
    }

    nestedMapItems.addAll(
      _extractDetectionItemsFromCandidates(
        [value],
        fallbackTime: localTime,
        fallbackSnapshotUrl: localSnapshotUrl,
        sourceDocumentPath: sourceDocumentPath,
        depth: depth + 1,
      ),
    );
  }

  return nestedMapItems;
}

DetectionItem? _toDetectionItem(
  Map<dynamic, dynamic> data, {
  String fallbackTime = '',
  String fallbackSnapshotUrl = '',
  String sourceDocumentPath = '',
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
    _firstStringFromArrayLike(data['all_classes_detected']),
    _firstStringFromArrayLike(data['all_classes_detected_en']),
    data['prediction'],
    data['result'],
  ]);
  final confidence = _normalizeConfidence(
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
  );
  final time = _stringifyTime(
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
  );
  final snapshotUrl =
      _firstNonEmptyString([
        data['annotated_frame_storage_path'],
        data['frame_storage_path'],
        data['annotatedFrameStoragePath'],
        data['snapshot_path'],
        data['annotated_frame_url'],
        data['frame_url'],
        data['annotatedFrameUrl'],
        data['snapshot'],
        data['snapshotUrl'],
        data['image'],
        data['image_url'],
        fallbackSnapshotUrl,
      ]) ??
      '';

  if (diseaseClass == null) {
    return null;
  }

  return DetectionItem(
    diseaseClass: diseaseClass,
    confidence: confidence,
    time: time,
    snapshotUrl: snapshotUrl,
    sourceDocumentPath: sourceDocumentPath,
  );
}

List<String> _detectionDocumentPaths(String plantId) {
  return [
    for (final id in _detectionIds(plantId)) ...['plant/$id', 'plants/$id'],
  ];
}

List<String> _detectionCollectionPaths(String plantId) {
  return [
    for (final id in _detectionIds(plantId)) ...[
      'plant/$id/detections',
      'plants/$id/detections',
    ],
  ];
}

List<String> _detectionIds(String plantId) {
  final ids = <String>{};
  final normalized = plantId.trim();
  if (normalized.isNotEmpty) {
    ids.add(normalized);
  }
  if (ids.isEmpty) {
    ids.add('all');
  }
  return ids.toList(growable: false);
}

List<DetectionItem> _extractDetectionItemsFromClassArray(
  List<dynamic> source, {
  required String fallbackTime,
  required String fallbackSnapshotUrl,
  required String sourceDocumentPath,
}) {
  final items = <DetectionItem>[];

  for (final value in source) {
    if (value is Map) {
      return const <DetectionItem>[];
    }

    final diseaseClass = value?.toString().trim();
    if (diseaseClass == null || diseaseClass.isEmpty) {
      continue;
    }

    items.add(
      DetectionItem(
        diseaseClass: diseaseClass,
        confidence: 0,
        time: fallbackTime,
        snapshotUrl: fallbackSnapshotUrl,
        sourceDocumentPath: sourceDocumentPath,
      ),
    );
  }

  return items;
}

DetectionItem? _hydrateDetection(
  DetectionItem? item, {
  required String fallbackTime,
  required String fallbackSnapshotUrl,
}) {
  if (item == null) {
    return null;
  }

  final hydratedTime = item.time.trim().isNotEmpty ? item.time : fallbackTime;
  final hydratedSnapshotUrl = item.snapshotUrl.trim().isNotEmpty
      ? item.snapshotUrl
      : fallbackSnapshotUrl;

  if (hydratedTime == item.time && hydratedSnapshotUrl == item.snapshotUrl) {
    return item;
  }

  return item.copyWith(time: hydratedTime, snapshotUrl: hydratedSnapshotUrl);
}

List<DetectionItem> _hydrateDetections(
  List<DetectionItem> items, {
  required String fallbackTime,
  required String fallbackSnapshotUrl,
}) {
  if (items.isEmpty) {
    return const <DetectionItem>[];
  }

  return [
    for (final item in items)
      _hydrateDetection(
        item,
        fallbackTime: fallbackTime,
        fallbackSnapshotUrl: fallbackSnapshotUrl,
      )!,
  ];
}

List<dynamic> _detectionCandidateSources(Map<dynamic, dynamic> data) {
  return [
    data['data'],
    data['latest_diseases'],
    data['latestDiseases'],
    data['disease_list_unique_top'],
    data['disease_list'],
    data['disease_objects'],
    data['objects'],
    data['detections'],
    data['diseases'],
    data['diseaseDetection'],
    data['detection'],
    data['predictions'],
    data['results'],
    data['all_classes_detected'],
    data['all_classes_detected_en'],
    data['history'],
    data['detectionHistory'],
  ];
}

String _detectionTimeFromMap(
  Map<dynamic, dynamic> data, {
  required String fallbackTime,
}) {
  return _stringifyTime(
    _firstNonNull([
      data['annotated_frame_local_saved_at'],
      data['latest_detection_at'],
      data['latestDetectionAt'],
      data['latest_detected_at'],
      data['detected_at'],
      data['detectedAt'],
      data['created_at'],
      data['createdAt'],
      data['saved_at'],
      data['savedAt'],
      data['firestore_saved_at'],
      data['received_at'],
      data['updated_at'],
      data['updatedAt'],
      data['time'],
      data['timestamp'],
      fallbackTime,
    ]),
  );
}

String _snapshotUrlFromMap(
  Map<dynamic, dynamic> data, {
  required String fallbackSnapshotUrl,
}) {
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
        data['image'],
        data['image_url'],
        fallbackSnapshotUrl,
      ]) ??
      '';
}

List<DetectionItem> _dedupeDetections(List<DetectionItem> items) {
  final deduped = <String, DetectionItem>{};

  for (final item in items) {
    final key = [
      item.diseaseClass,
      item.confidence.toStringAsFixed(4),
      item.time,
      item.snapshotUrl,
    ].join('|');

    final existing = deduped[key];
    if (existing == null ||
        (existing.sourceDocumentPath.trim().isEmpty &&
            item.sourceDocumentPath.trim().isNotEmpty)) {
      deduped[key] = item;
    }
  }

  return deduped.values.toList();
}

List<DetectionItem> _normalizeDetectionList(List<DetectionItem> items) {
  final normalized = _dedupeDetections(items);
  normalized.sort(_compareDetectionByNewest);
  return normalized;
}

bool _isCandidateGroupNewer(
  List<DetectionItem> candidate,
  List<DetectionItem> current,
) {
  if (candidate.isEmpty) {
    return false;
  }
  if (current.isEmpty) {
    return true;
  }

  return _compareDetectionByNewest(candidate.first, current.first) < 0;
}

List<DetectionItem> _singleDetection(DetectionItem? item) {
  return item == null ? const <DetectionItem>[] : <DetectionItem>[item];
}

String? _firstNonEmptyDetectionSnapshot(Iterable<DetectionItem> items) {
  for (final item in items) {
    final snapshot = item.snapshotUrl.trim();
    if (snapshot.isNotEmpty) {
      return snapshot;
    }
  }

  return null;
}

String? _firstNonEmptyDetectionTime(Iterable<DetectionItem> items) {
  for (final item in items) {
    final time = item.time.trim();
    if (time.isNotEmpty) {
      return time;
    }
  }

  return null;
}

int _compareDetectionByNewest(DetectionItem a, DetectionItem b) {
  final aTime = _tryParseDateTime(a.time);
  final bTime = _tryParseDateTime(b.time);

  if (aTime != null && bTime != null) {
    final timeCompare = bTime.compareTo(aTime);
    if (timeCompare != 0) {
      return timeCompare;
    }
  }

  final stringTimeCompare = b.time.compareTo(a.time);
  if (stringTimeCompare != 0) {
    return stringTimeCompare;
  }

  final confidenceCompare = b.confidence.compareTo(a.confidence);
  if (confidenceCompare != 0) {
    return confidenceCompare;
  }

  return a.diseaseClass.compareTo(b.diseaseClass);
}

DateTime? _tryParseDateTime(String value) {
  if (value.isEmpty) {
    return null;
  }

  return DateTime.tryParse(value.replaceFirst(' ', 'T'));
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
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}

String _stringifyTime(dynamic value) {
  if (value == null) {
    return '';
  }
  if (value is Timestamp) {
    return _formatDateTime(value.toDate());
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

bool _isPermissionDenied(Object error) {
  return error is FirebaseException && error.code == 'permission-denied';
}

void _logParsedDetections(String path, PlantDetectionsData data) {
  final latestClasses = data.latestDetections
      .map((item) => item.diseaseClass)
      .join(', ');
  if (latestClasses.isEmpty) {
    LoggerUtils.d('Firestore detections empty at $path');
    return;
  }

  LoggerUtils.d(
    'Firestore detections loaded from $path: [$latestClasses], '
    'history=${data.history.length}',
  );
}

extension _BlankStringExtension on String {
  String? get ifNotBlank {
    final value = trim();
    return value.isEmpty ? null : value;
  }
}
