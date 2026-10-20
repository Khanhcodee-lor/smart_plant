import 'dart:async';
import 'dart:convert';

import 'package:app_iot/src/core/services/firebase/firebase_firestore_service.dart';
import 'package:app_iot/src/core/services/firebase/firebase_realtime_database_service.dart';
import 'package:app_iot/src/core/ulits/logger_ulits.dart';
import 'package:app_iot/src/features/home/domain/entities/plant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _noDiseaseDetectedLabel = 'Kh\u00f4ng ph\u00e1t hi\u1ec7n b\u1ec7nh';

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

class _CaptureMetadata {
  const _CaptureMetadata({required this.capturedAt, required this.snapshotUrl});

  final String capturedAt;
  final String snapshotUrl;
}

final plantDetectionsProvider = StreamProvider.autoDispose
    .family<PlantDetectionsData, String>((ref, plantId) {
      final database = ref.watch(firebaseRealtimeDatabaseServiceProvider);
      final firestore = ref.watch(firebaseFirestoreServiceProvider);

      return Stream.multi((controller) {
        var cancelled = false;
        var realtimeDetections = const PlantDetectionsData();
        final firestoreDetectionsByPath = <String, PlantDetectionsData>{};
        final subscriptions = <StreamSubscription<dynamic>>[];

        void emitMerged() {
          if (cancelled) {
            return;
          }

          final firestoreDetections = _mergeDetectionsByPath(
            firestoreDetectionsByPath,
          );
          controller.add(
            _mergeDetections(firestoreDetections, realtimeDetections),
          );
        }

        void handleFirestoreError(
          String path,
          Object error,
          StackTrace stackTrace,
        ) {
          firestoreDetectionsByPath[path] = const PlantDetectionsData();
          if (error is FirebaseException && error.code == 'permission-denied') {
            LoggerUtils.i('Firestore path denied and ignored: $path');
          } else {
            LoggerUtils.e(
              'Failed to read Firestore path: $path',
              error,
              stackTrace,
            );
          }
          emitMerged();
        }

        for (final path in _firestoreCaptureCollectionPaths(plantId)) {
          subscriptions.add(
            firestore
                .collectionStreamWithIds(path)
                .listen(
                  (documents) {
                    final parsed = _parseDetectionsFromCollection(documents);
                    _logParsedDetections(path, parsed);
                    firestoreDetectionsByPath[path] = parsed;
                    emitMerged();
                  },
                  onError: (Object error, StackTrace stackTrace) {
                    handleFirestoreError(path, error, stackTrace);
                  },
                ),
          );
        }

        for (final path in _firestorePlantDocumentPaths(plantId)) {
          subscriptions.add(
            firestore
                .documentStream(path)
                .listen(
                  (data) {
                    final parsed = _parseDetectionsFromDocument(data);
                    _logParsedDetections(path, parsed);
                    firestoreDetectionsByPath[path] = parsed;
                    emitMerged();
                  },
                  onError: (Object error, StackTrace stackTrace) {
                    handleFirestoreError(path, error, stackTrace);
                  },
                ),
          );
        }

        Future<void> poll() async {
          while (!cancelled) {
            try {
              final value = await _readRealtimePlantValue(database, plantId);
              final parsed = _parseDetectionsFromRealtimePlant(
                value,
                plantId: plantId,
              );
              _logParsedDetections(
                'Realtime Database: plants/$plantId/plant_captures',
                parsed,
              );
              realtimeDetections = parsed;
              emitMerged();
            } catch (error, stackTrace) {
              LoggerUtils.e(
                'Failed to read Realtime Database detections for $plantId',
                error,
                stackTrace,
              );
              realtimeDetections = const PlantDetectionsData();
              emitMerged();
            }

            await Future<void>.delayed(const Duration(seconds: 3));
          }
        }

        unawaited(poll());
        controller.onCancel = () async {
          cancelled = true;
          for (final subscription in subscriptions) {
            await subscription.cancel();
          }
        };
      });
    });

List<String> _firestoreCaptureCollectionPaths(String plantId) {
  final normalizedPlantId = plantId.trim();
  return [
    'plants/$normalizedPlantId/plant_captures',
    'plant/$normalizedPlantId/plant_captures',
  ];
}

List<String> _firestorePlantDocumentPaths(String plantId) {
  final normalizedPlantId = plantId.trim();
  return ['plants/$normalizedPlantId', 'plant/$normalizedPlantId'];
}

Future<dynamic> _readRealtimePlantValue(
  FirebaseRealtimeDatabaseService database,
  String plantId,
) async {
  final normalizedPlantId = plantId.trim();
  for (final path in [
    'plants/$normalizedPlantId',
    'plant/$normalizedPlantId',
  ]) {
    final capturesPath = '$path/plant_captures';
    try {
      final captures = await database.getData(capturesPath);
      if ((captures is Map && captures.isNotEmpty) ||
          (captures is List && captures.isNotEmpty)) {
        return {'plant_captures': captures};
      }
    } catch (_) {
      // Older database rules may allow reading the plant node but not this
      // child directly. Fall back to the parent node in that case.
    }

    final value = await database.getData(path);
    if (value is Map && value.isNotEmpty) {
      return value;
    }
  }
  return null;
}

PlantDetectionsData _parseDetectionsFromRealtimePlant(
  dynamic value, {
  required String plantId,
}) {
  final plant = _asMap(value);
  final nestedDetections = _asMap(
    plant['detections'] ?? plant['diseaseDetection'] ?? plant['detection'],
  );
  final source = nestedDetections.isNotEmpty ? nestedDetections : plant;
  final plantData = _parseDetectionsFromDocument(_asStringMap(source));
  final captures =
      plant['plant_captures'] ?? plant['plantCaptures'] ?? plant['captures'];
  final captureData = _parseRealtimeCaptureCollection(
    captures,
    collectionPath: 'plants/${plantId.trim()}/plant_captures',
  );

  return _mergeDetections(plantData, captureData);
}

PlantDetectionsData _parseRealtimeCaptureCollection(
  dynamic value, {
  required String collectionPath,
}) {
  if (value is! Map && value is! List) {
    return const PlantDetectionsData();
  }

  final captures = <FirestoreDocumentData>[];

  void addCapture(String id, dynamic data) {
    final capture = _asMap(data);
    if (capture.isEmpty) {
      return;
    }

    captures.add(
      FirestoreDocumentData(
        id: id,
        path: '$collectionPath/$id',
        data: _asStringMap(capture),
      ),
    );
  }

  if (value is List) {
    for (var index = 0; index < value.length; index++) {
      addCapture(index.toString(), value[index]);
    }
  } else {
    final map = _asMap(value);
    if (_isRealtimeCaptureDocument(map)) {
      addCapture('latest', map);
    } else {
      for (final entry in map.entries) {
        addCapture(entry.key.toString(), entry.value);
      }
    }
  }

  return _parseDetectionsFromCollection(captures);
}

bool _isRealtimeCaptureDocument(Map<dynamic, dynamic> data) {
  return _diseaseClassFromMap(data) != null ||
      _snapshotUrlFromMap(data, fallbackSnapshotUrl: '').trim().isNotEmpty ||
      _detectionTimeFromMap(data, fallbackTime: '').trim().isNotEmpty;
}

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

@visibleForTesting
PlantDetectionsData debugMergePlantDetectionsByPath(
  Map<String, PlantDetectionsData> detectionsByPath,
) {
  return _mergeDetectionsByPath(detectionsByPath);
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
      normalized['captured_at'],
      normalized['capturedAt'],
      normalized['capture_time'],
      normalized['captureTime'],
      normalized['processed_at'],
      normalized['processedAt'],
      normalized['uploaded_at'],
      normalized['uploadedAt'],
      normalized['annotated_frame_local_saved_at'],
      normalized['firestore_saved_at'],
      normalized['received_at'],
      normalized['timestamp'],
      _dateTimeFromRequestId(normalized['request_id']),
      _dateTimeFromRequestId(normalized['requestId']),
      normalized['updated_at'],
      normalized['updatedAt'],
    ]),
  );
  final latestSnapshotUrl = _snapshotUrlFromMap(
    normalized,
    fallbackSnapshotUrl: '',
  );

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
  var latestSnapshotUrl = '';
  var latestCapturedAt = '';
  var latestMetadataIsStandalone = false;

  for (final document in documents) {
    final normalized = Map<dynamic, dynamic>.from(document.data);
    final sourceDocumentPath = document.path.trim();
    final detectedTime = _stringifyTime(
      _firstNonNull([
        normalized['annotated_frame_local_saved_at'],
        normalized['latest_detection_at'],
        normalized['latestDetectionAt'],
        normalized['detected_at'],
        normalized['detectedAt'],
        normalized['captured_at'],
        normalized['capturedAt'],
        normalized['capture_time'],
        normalized['captureTime'],
        normalized['processed_at'],
        normalized['processedAt'],
        normalized['uploaded_at'],
        normalized['uploadedAt'],
        normalized['created_at'],
        normalized['createdAt'],
        normalized['saved_at'],
        normalized['savedAt'],
        normalized['firestore_saved_at'],
        normalized['received_at'],
        normalized['updated_at'],
        normalized['updatedAt'],
        normalized['time'],
        normalized['timestamp'],
        _dateTimeFromRequestId(normalized['request_id']),
        _dateTimeFromRequestId(normalized['requestId']),
      ]),
    );
    final snapshotUrl = _snapshotUrlFromMap(
      normalized,
      fallbackSnapshotUrl: '',
    );

    void considerDocumentMetadata({required bool isStandalone}) {
      if (_isCaptureMetadataNewer(
        candidateTime: detectedTime,
        candidateSnapshotUrl: snapshotUrl,
        currentTime: latestCapturedAt,
        currentSnapshotUrl: latestSnapshotUrl,
      )) {
        latestCapturedAt = detectedTime;
        latestSnapshotUrl = snapshotUrl;
        latestMetadataIsStandalone = isStandalone;
      }
    }

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
      considerDocumentMetadata(isStandalone: false);
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
      considerDocumentMetadata(isStandalone: false);
      continue;
    }

    final noDiseaseDetection = _toNoDiseaseDetectionItem(
      data: normalized,
      fallbackTime: detectedTime,
      fallbackSnapshotUrl: snapshotUrl,
      sourceDocumentPath: sourceDocumentPath,
    );
    if (noDiseaseDetection != null) {
      history.add(noDiseaseDetection);
      final noDiseaseGroup = <DetectionItem>[noDiseaseDetection];
      if (_isCandidateGroupNewer(noDiseaseGroup, latestGroup)) {
        latestGroup = noDiseaseGroup;
      }
      considerDocumentMetadata(isStandalone: false);
      continue;
    }

    considerDocumentMetadata(isStandalone: true);
  }

  final effectiveLatestGroup =
      latestMetadataIsStandalone &&
          _isStandaloneMetadataNewerThanDetections(
            latestCapturedAt,
            latestGroup,
          )
      ? const <DetectionItem>[]
      : latestGroup;

  return _buildDetections(
    effectiveLatestGroup.isNotEmpty ? effectiveLatestGroup.first : null,
    history,
    latestDetections: effectiveLatestGroup,
    latestSnapshotUrl: latestSnapshotUrl,
    latestCapturedAt: latestCapturedAt,
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
  final metadataIsStandaloneLatest =
      hydratedLatestDetection == null &&
      hydratedLatest.isEmpty &&
      _hasCaptureMetadata(
        latestCapturedAt: latestCapturedAt,
        latestSnapshotUrl: latestSnapshotUrl,
      ) &&
      _isStandaloneMetadataNewerThanDetections(latestCapturedAt, mergedHistory);
  final effectiveLatest = metadataIsStandaloneLatest
      ? null
      : (normalizedLatest.isNotEmpty
            ? normalizedLatest.first
            : (mergedHistory.isNotEmpty
                  ? mergedHistory.first
                  : hydratedLatestDetection));
  final effectiveLatestDetections = metadataIsStandaloneLatest
      ? const <DetectionItem>[]
      : (normalizedLatest.isNotEmpty
            ? normalizedLatest
            : (effectiveLatest == null
                  ? const <DetectionItem>[]
                  : <DetectionItem>[effectiveLatest]));
  final effectiveSnapshotUrl = metadataIsStandaloneLatest
      ? latestSnapshotUrl
      : (_firstNonEmptyDetectionSnapshot([
              ...effectiveLatestDetections,
              ...mergedHistory,
            ]) ??
            latestSnapshotUrl);
  final effectiveCapturedAt = metadataIsStandaloneLatest
      ? latestCapturedAt
      : (_firstNonEmptyDetectionTime([
              ...effectiveLatestDetections,
              ...mergedHistory,
            ]) ??
            latestCapturedAt);

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
  final standaloneMetadata = _newerStandaloneMetadata(
    primary,
    secondary,
    latestDetections,
  );
  if (standaloneMetadata != null) {
    return _buildDetections(
      null,
      [
        ...primary.history,
        ...secondary.history,
        if (primary.latestDetection != null) primary.latestDetection!,
        if (secondary.latestDetection != null) secondary.latestDetection!,
      ],
      latestSnapshotUrl: standaloneMetadata.snapshotUrl,
      latestCapturedAt: standaloneMetadata.capturedAt,
    );
  }

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

PlantDetectionsData _mergeDetectionsByPath(
  Map<String, PlantDetectionsData> detectionsByPath,
) {
  var merged = const PlantDetectionsData();
  for (final detections in detectionsByPath.values) {
    merged = _mergeDetections(merged, detections);
  }
  return merged;
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
    final decodedSource = _decodeStructuredPayload(source);
    if (decodedSource is String) {
      final item = _detectionItemFromLabel(
        decodedSource,
        fallbackTime: fallbackTime,
        fallbackSnapshotUrl: fallbackSnapshotUrl,
        sourceDocumentPath: sourceDocumentPath,
      );
      if (item != null) {
        history.add(item);
      }
      continue;
    }

    if (decodedSource is List) {
      final classItems = _extractDetectionItemsFromClassArray(
        decodedSource,
        fallbackTime: fallbackTime,
        fallbackSnapshotUrl: fallbackSnapshotUrl,
        sourceDocumentPath: sourceDocumentPath,
      );
      if (classItems.isNotEmpty) {
        history.addAll(classItems);
        continue;
      }

      for (final item in decodedSource) {
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

    if (decodedSource is Map) {
      history.addAll(
        _extractDetectionItemsFromMap(
          _asMap(decodedSource),
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

dynamic _decodeStructuredPayload(dynamic value) {
  var decoded = value;
  for (var depth = 0; depth < 3 && decoded is String; depth++) {
    try {
      decoded = jsonDecode(decoded.trim());
    } on FormatException {
      break;
    }
  }
  return decoded;
}

DetectionItem? _detectionItemFromLabel(
  String value, {
  required String fallbackTime,
  required String fallbackSnapshotUrl,
  required String sourceDocumentPath,
}) {
  final label = value.trim();
  if (label.isEmpty ||
      label.contains('://') ||
      DateTime.tryParse(label) != null ||
      !_looksLikeDiseaseClass(label)) {
    return null;
  }

  final confidenceMatch = RegExp(
    r'^(.*?)\s*\(?\s*(\d+(?:\.\d+)?)\s*%\s*\)?\s*$',
  ).firstMatch(label);
  final diseaseClass = (confidenceMatch?.group(1) ?? label).trim();
  if (diseaseClass.isEmpty) {
    return null;
  }

  final parsedConfidence = confidenceMatch == null
      ? 0.0
      : _normalizeConfidence(confidenceMatch.group(2));
  final isNoDisease = _isNoDiseaseClass(diseaseClass);
  return DetectionItem(
    diseaseClass: isNoDisease ? _noDiseaseDetectedLabel : diseaseClass,
    confidence: isNoDisease ? 0 : parsedConfidence,
    time: fallbackTime,
    snapshotUrl: fallbackSnapshotUrl,
    sourceDocumentPath: sourceDocumentPath,
  );
}

bool _looksLikeDiseaseClass(String value) {
  final normalized = value.trim().toLowerCase();
  return [
    'khoe manh',
    'khỏe mạnh',
    'khong phat hien benh',
    'không phát hiện bệnh',
    'tomato',
    'leaf',
    'septoria',
    'blight',
    'mosaic',
    'bacterial spot',
    'healthy',
    'disease',
    'cà chua',
    'ca chua',
    'lá',
    'bệnh',
    'benh',
    'đốm',
    'dom',
    'mốc',
    'moc',
  ].any(normalized.contains);
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

  final keyedDiseaseItems = _extractKeyedDiseaseItems(
    data,
    fallbackTime: localTime,
    fallbackSnapshotUrl: localSnapshotUrl,
    sourceDocumentPath: sourceDocumentPath,
  );
  if (keyedDiseaseItems.isNotEmpty) {
    return keyedDiseaseItems;
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

List<DetectionItem> _extractKeyedDiseaseItems(
  Map<dynamic, dynamic> data, {
  required String fallbackTime,
  required String fallbackSnapshotUrl,
  required String sourceDocumentPath,
}) {
  final items = <DetectionItem>[];
  for (final entry in data.entries) {
    final diseaseClass = entry.key.toString().trim();
    if (!_looksLikeDiseaseClass(diseaseClass)) {
      continue;
    }

    final value = _decodeStructuredPayload(entry.value);
    final valueMap = _asMap(value);
    final confidence = _normalizeConfidence(
      value is num
          ? value
          : _firstNonNull([
              valueMap['confidence'],
              valueMap['score'],
              valueMap['probability'],
            ]),
    );
    items.add(
      DetectionItem(
        diseaseClass: diseaseClass,
        confidence: confidence,
        time: fallbackTime,
        snapshotUrl: fallbackSnapshotUrl,
        sourceDocumentPath: sourceDocumentPath,
      ),
    );
  }
  return items;
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

  final rawDiseaseClass = _diseaseClassFromMap(data);
  final status = data['status']?.toString().trim().toLowerCase() ?? '';
  final statusIndicatesNoDisease = const {
    'no_detection',
    'no detection',
    'no_disease',
    'no disease',
    'healthy',
    'clean',
  }.contains(status.replaceAll('-', '_'));
  final isNoDisease =
      statusIndicatesNoDisease ||
      (rawDiseaseClass != null && _isNoDiseaseClass(rawDiseaseClass));
  final diseaseClass = rawDiseaseClass == null && !statusIndicatesNoDisease
      ? null
      : (isNoDisease ? _noDiseaseDetectedLabel : rawDiseaseClass);
  final confidence = isNoDisease
      ? 0.0
      : _normalizeConfidence(
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
      data['latestDetectionAt'],
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
      _dateTimeFromRequestId(data['request_id']),
      _dateTimeFromRequestId(data['requestId']),
      fallbackTime,
    ]),
  );
  final snapshotUrl = _snapshotUrlFromMap(
    data,
    fallbackSnapshotUrl: fallbackSnapshotUrl,
  );

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

DetectionItem? _toNoDiseaseDetectionItem({
  required Map<dynamic, dynamic> data,
  required String fallbackTime,
  required String fallbackSnapshotUrl,
  required String sourceDocumentPath,
}) {
  if (!_explicitlyReportsNoDisease(data) ||
      (fallbackTime.trim().isEmpty && fallbackSnapshotUrl.trim().isEmpty)) {
    return null;
  }

  return DetectionItem(
    diseaseClass: _noDiseaseDetectedLabel,
    confidence: 0,
    time: fallbackTime,
    snapshotUrl: fallbackSnapshotUrl,
    sourceDocumentPath: sourceDocumentPath,
  );
}

bool _explicitlyReportsNoDisease(Map<dynamic, dynamic> data) {
  const resultFields = [
    'latest_objects',
    'latestObjects',
    'detected_objects',
    'detectedObjects',
    'disease_list_unique_top',
    'disease_list',
    'disease_objects',
    'objects',
    'detections',
    'diseases',
    'disease_result',
    'diseaseResult',
    'disease_results',
    'diseaseResults',
    'disease_result_json',
    'diseaseResultJson',
    'disease_json',
    'diseaseJson',
    'detection_result',
    'detectionResult',
    'detection_results',
    'detectionResults',
    'detection_result_json',
    'detectionResultJson',
    'detection_json',
    'detectionJson',
    'latest_result',
    'latestResult',
    'all_detections',
    'allDetections',
    'predictions',
    'results',
  ];
  if (resultFields.any((key) => _hasPayload(data[key]))) {
    return false;
  }

  final status = data['status']?.toString().trim().toLowerCase();
  if (status != null &&
      const {
        'no_detection',
        'no detection',
        'no_disease',
        'no disease',
      }.contains(status.replaceAll('-', '_'))) {
    return true;
  }

  final objectCount = _firstNonNull([
    data['latest_total_objects'],
    data['latestTotalObjects'],
    data['total_objects'],
    data['totalObjects'],
    data['object_count'],
    data['objectCount'],
    data['detection_count'],
    data['detectionCount'],
  ]);
  final parsedObjectCount = _nullableDouble(objectCount);
  if (parsedObjectCount != null && parsedObjectCount <= 0) {
    return true;
  }

  final diseaseDetected = _firstNonNull([
    data['disease_detected'],
    data['diseaseDetected'],
    data['has_disease'],
    data['hasDisease'],
  ]);
  if (diseaseDetected != null &&
      const {
        'false',
        '0',
        'no',
      }.contains(diseaseDetected.toString().trim().toLowerCase())) {
    return true;
  }

  final isHealthy = _firstNonNull([data['is_healthy'], data['isHealthy']]);
  if (isHealthy != null &&
      const {
        'true',
        '1',
        'yes',
      }.contains(isHealthy.toString().trim().toLowerCase())) {
    return true;
  }

  const classArrayFields = [
    'all_classes_detected_vi',
    'all_classes_detected',
    'all_classes_detected_en',
    'latest_diseases',
    'latestDiseases',
  ];
  final classArrays = classArrayFields
      .where(data.containsKey)
      .map((key) => data[key])
      .toList();
  return classArrays.isNotEmpty && classArrays.every(_isEmptyArrayLike);
}

bool _hasPayload(dynamic value) {
  final decoded = _decodeStructuredPayload(value);
  if (decoded is Map) {
    return decoded.isNotEmpty;
  }
  if (decoded is List) {
    return decoded.isNotEmpty;
  }
  return decoded is String && decoded.trim().isNotEmpty;
}

double? _nullableDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim());
  }
  return null;
}

bool _isEmptyArrayLike(dynamic value) {
  if (value is List) {
    return value.every(
      (item) => item == null || item.toString().trim().isEmpty,
    );
  }
  if (value is Map) {
    return value.isEmpty;
  }
  return false;
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
    data['latest'],
    data['latest_detection'],
    data['latestDetection'],
    data['latest_detections'],
    data['latestDetections'],
    data['currentDetection'],
    data['data'],
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
    data['latest_diseases'],
    data['latestDiseases'],
    data['diseaseDetection'],
    data['detection'],
    data['disease_result'],
    data['diseaseResult'],
    data['disease_results'],
    data['diseaseResults'],
    data['disease_result_json'],
    data['diseaseResultJson'],
    data['disease_json'],
    data['diseaseJson'],
    data['diseases_detected'],
    data['diseasesDetected'],
    data['detected_diseases'],
    data['detectedDiseases'],
    data['latest_disease'],
    data['latestDisease'],
    data['latest_disease_name'],
    data['latestDiseaseName'],
    data['detected_disease'],
    data['detectedDisease'],
    data['top_disease'],
    data['topDisease'],
    data['detection_result'],
    data['detectionResult'],
    data['detection_results'],
    data['detectionResults'],
    data['detection_result_json'],
    data['detectionResultJson'],
    data['detection_json'],
    data['detectionJson'],
    data['latest_result'],
    data['latestResult'],
    data['all_detections'],
    data['allDetections'],
    data['predictions'],
    data['results'],
    data['all_classes_detected_vi'],
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
      data['updated_at'],
      data['updatedAt'],
      data['time'],
      data['timestamp'],
      _dateTimeFromRequestId(data['request_id']),
      _dateTimeFromRequestId(data['requestId']),
      fallbackTime,
    ]),
  );
}

String _snapshotUrlFromMap(
  Map<dynamic, dynamic> data, {
  required String fallbackSnapshotUrl,
}) {
  return _firstNonEmptyString([
        _inlineImageDataCandidate(data['annotated_frame_base64']),
        _inlineImageDataCandidate(data['annotated_image_base64']),
        _inlineImageDataCandidate(data['processed_frame_base64']),
        _inlineImageDataCandidate(data['processed_image_base64']),
        _inlineImageDataCandidate(data['output_frame_base64']),
        _inlineImageDataCandidate(data['output_image_base64']),
        _inlineImageDataCandidate(data['result_frame_base64']),
        _inlineImageDataCandidate(data['result_image_base64']),
        data['annotated_frame_storage_path'],
        data['annotated_storage_path'],
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
        data['annotated_frame'],
        data['annotatedFrame'],
        data['processed_frame_storage_path'],
        data['processedFrameStoragePath'],
        data['processed_frame_url'],
        data['processedFrameUrl'],
        data['processed_frame'],
        data['processedFrame'],
        data['processed_image_url'],
        data['processedImageUrl'],
        data['processed_image'],
        data['processedImage'],
        data['output_frame_storage_path'],
        data['outputFrameStoragePath'],
        data['output_frame_url'],
        data['outputFrameUrl'],
        data['output_frame'],
        data['outputFrame'],
        data['output_image_url'],
        data['outputImageUrl'],
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
        data['snapshot'],
        data['snapshotUrl'],
        data['annotated_image_url'],
        data['annotatedImageUrl'],
        data['annotated_image'],
        data['annotatedImage'],
        data['image'],
        _safeImageUrlCandidate(data['image_url']),
        _safeImageUrlCandidate(data['imageUrl']),
        fallbackSnapshotUrl,
      ]) ??
      '';
}

List<DetectionItem> _dedupeDetections(List<DetectionItem> items) {
  final deduped = <String, DetectionItem>{};

  for (final item in items) {
    final key = _detectionDedupeKey(item);

    final existing = deduped[key];
    if (existing == null || _shouldReplaceDedupedDetection(item, existing)) {
      deduped[key] = item;
    }
  }

  return deduped.values.toList();
}

String _detectionDedupeKey(DetectionItem item) {
  final diseaseClass = item.diseaseClass.trim().toLowerCase();
  if (item.time.trim().isNotEmpty) {
    return [diseaseClass, item.time].join('|');
  }

  return [diseaseClass, item.snapshotUrl, item.sourceDocumentPath].join('|');
}

bool _shouldReplaceDedupedDetection(
  DetectionItem candidate,
  DetectionItem current,
) {
  if (candidate.confidence != current.confidence) {
    return candidate.confidence > current.confidence;
  }

  final candidateHasSnapshot = candidate.snapshotUrl.trim().isNotEmpty;
  final currentHasSnapshot = current.snapshotUrl.trim().isNotEmpty;
  if (candidateHasSnapshot != currentHasSnapshot) {
    return candidateHasSnapshot;
  }

  return current.sourceDocumentPath.trim().isEmpty &&
      candidate.sourceDocumentPath.trim().isNotEmpty;
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

_CaptureMetadata? _newerStandaloneMetadata(
  PlantDetectionsData primary,
  PlantDetectionsData secondary,
  List<DetectionItem> currentLatestDetections,
) {
  _CaptureMetadata? newest;
  for (final data in [primary, secondary]) {
    final dataLatest = data.latestDetections.isNotEmpty
        ? data.latestDetections
        : <DetectionItem>[
            if (data.latestDetection != null) data.latestDetection!,
          ];
    if (dataLatest.isNotEmpty) {
      continue;
    }

    if (!_hasCaptureMetadata(
      latestCapturedAt: data.latestCapturedAt,
      latestSnapshotUrl: data.latestSnapshotUrl,
    )) {
      continue;
    }

    if (!_isStandaloneMetadataNewerThanDetections(
      data.latestCapturedAt,
      currentLatestDetections,
    )) {
      continue;
    }

    final candidate = _CaptureMetadata(
      capturedAt: data.latestCapturedAt,
      snapshotUrl: data.latestSnapshotUrl,
    );
    if (newest == null ||
        _isCaptureMetadataNewer(
          candidateTime: candidate.capturedAt,
          candidateSnapshotUrl: candidate.snapshotUrl,
          currentTime: newest.capturedAt,
          currentSnapshotUrl: newest.snapshotUrl,
        )) {
      newest = candidate;
    }
  }

  return newest;
}

bool _hasCaptureMetadata({
  required String latestCapturedAt,
  required String latestSnapshotUrl,
}) {
  return latestCapturedAt.trim().isNotEmpty ||
      latestSnapshotUrl.trim().isNotEmpty;
}

bool _isStandaloneMetadataNewerThanDetections(
  String metadataTime,
  List<DetectionItem> detections,
) {
  if (detections.isEmpty) {
    return metadataTime.trim().isNotEmpty;
  }

  final newestDetectionTime = _firstNonEmptyDetectionTime(detections) ?? '';
  if (metadataTime.trim().isEmpty || newestDetectionTime.trim().isEmpty) {
    return false;
  }

  final metadataDate = _tryParseDateTime(metadataTime);
  final detectionDate = _tryParseDateTime(newestDetectionTime);
  if (metadataDate != null && detectionDate != null) {
    return metadataDate.isAfter(detectionDate);
  }

  return metadataTime.compareTo(newestDetectionTime) > 0;
}

bool _isCaptureMetadataNewer({
  required String candidateTime,
  required String candidateSnapshotUrl,
  required String currentTime,
  required String currentSnapshotUrl,
}) {
  final hasCandidate =
      candidateTime.trim().isNotEmpty || candidateSnapshotUrl.trim().isNotEmpty;
  if (!hasCandidate) {
    return false;
  }

  final hasCurrent =
      currentTime.trim().isNotEmpty || currentSnapshotUrl.trim().isNotEmpty;
  if (!hasCurrent) {
    return true;
  }

  if (candidateTime.trim().isEmpty) {
    return false;
  }
  if (currentTime.trim().isEmpty) {
    return true;
  }

  final candidateDate = _tryParseDateTime(candidateTime);
  final currentDate = _tryParseDateTime(currentTime);
  if (candidateDate != null && currentDate != null) {
    if (candidateDate.isAfter(currentDate)) {
      return true;
    }
    if (candidateDate.isAtSameMomentAs(currentDate)) {
      return candidateSnapshotUrl.trim().isNotEmpty &&
          currentSnapshotUrl.trim().isEmpty;
    }
    return false;
  }

  final timeCompare = candidateTime.compareTo(currentTime);
  if (timeCompare != 0) {
    return timeCompare > 0;
  }

  return candidateSnapshotUrl.trim().isNotEmpty &&
      currentSnapshotUrl.trim().isEmpty;
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

  final aIsNoDisease = _isNoDiseaseClass(a.diseaseClass);
  final bIsNoDisease = _isNoDiseaseClass(b.diseaseClass);
  if (aIsNoDisease != bIsNoDisease) {
    return aIsNoDisease ? 1 : -1;
  }

  final confidenceCompare = b.confidence.compareTo(a.confidence);
  if (confidenceCompare != 0) {
    return confidenceCompare;
  }

  return a.diseaseClass.compareTo(b.diseaseClass);
}

bool _isNoDiseaseClass(String diseaseClass) {
  final normalized = diseaseClass
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
  return normalized == 'healthy' ||
      normalized == 'tomato healthy' ||
      normalized == 'no disease detected' ||
      normalized == 'khong phat hien benh' ||
      normalized == 'không phát hiện bệnh' ||
      normalized.contains('healthy') ||
      normalized.contains('khoe manh') ||
      normalized.contains('khỏe mạnh');
}

DateTime? _tryParseDateTime(String value) {
  if (value.isEmpty) {
    return null;
  }

  return DateTime.tryParse(value.replaceFirst(' ', 'T'));
}

DateTime? _dateTimeFromRequestId(dynamic value) {
  final requestId = value?.toString().trim();
  if (requestId == null || requestId.isEmpty) {
    return null;
  }

  final match = RegExp(r'(?:^|_)(\d{13})(?:_|$)').firstMatch(requestId);
  if (match == null) {
    return null;
  }

  final milliseconds = int.tryParse(match.group(1)!);
  if (milliseconds == null) {
    return null;
  }

  return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
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

Map<String, dynamic> _asStringMap(Map<dynamic, dynamic> value) {
  return <String, dynamic>{
    for (final entry in value.entries) entry.key.toString(): entry.value,
  };
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

String? _diseaseClassFromMap(Map<dynamic, dynamic> data) {
  return _firstNonEmptyString([
    data['pest_type'],
    data['pestType'],
    data['disease_class_vi'],
    data['diseaseClassVi'],
    data['disease_class_name'],
    data['diseaseClassName'],
    data['class_label'],
    data['classLabel'],
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
    data['disease_name'],
    data['disease_label'],
    data['diseaseLabel'],
    data['latest_disease'],
    data['latestDisease'],
    data['latest_disease_name'],
    data['latestDiseaseName'],
    data['detected_disease'],
    data['detectedDisease'],
    data['top_disease'],
    data['topDisease'],
    data['predicted_class'],
    data['predictedClass'],
    _firstStringFromArrayLike(data['all_classes_detected_vi']),
    _firstStringFromArrayLike(data['all_classes_detected']),
    data['class_name_en'],
    data['class_en'],
    data['label_en'],
    data['disease_en'],
    data['disease_name_en'],
    _firstStringFromArrayLike(data['all_classes_detected_en']),
    data['prediction'],
    data['result'],
  ]);
}

String? _inlineImageDataCandidate(dynamic value) {
  final image = value?.toString().trim();
  if (image == null || image.isEmpty) {
    return null;
  }

  return image.startsWith('data:image/')
      ? image
      : 'data:image/jpeg;base64,$image';
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

void _logParsedDetections(String path, PlantDetectionsData data) {
  final latestClasses = data.latestDetections
      .map((item) => item.diseaseClass)
      .join(', ');
  if (latestClasses.isEmpty) {
    LoggerUtils.d('Detections empty at $path');
    return;
  }

  LoggerUtils.d(
    'Detections loaded from $path: [$latestClasses], '
    'history=${data.history.length}',
  );
}

extension _BlankStringExtension on String {
  String? get ifNotBlank {
    final value = trim();
    return value.isEmpty ? null : value;
  }
}
