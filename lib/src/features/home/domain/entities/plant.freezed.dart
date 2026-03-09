// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plant.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$DetectionItem {
  String get diseaseClass => throw _privateConstructorUsedError;
  double get confidence => throw _privateConstructorUsedError;
  String get time => throw _privateConstructorUsedError;
  String get snapshotUrl => throw _privateConstructorUsedError;

  /// Create a copy of DetectionItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DetectionItemCopyWith<DetectionItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DetectionItemCopyWith<$Res> {
  factory $DetectionItemCopyWith(
    DetectionItem value,
    $Res Function(DetectionItem) then,
  ) = _$DetectionItemCopyWithImpl<$Res, DetectionItem>;
  @useResult
  $Res call({
    String diseaseClass,
    double confidence,
    String time,
    String snapshotUrl,
  });
}

/// @nodoc
class _$DetectionItemCopyWithImpl<$Res, $Val extends DetectionItem>
    implements $DetectionItemCopyWith<$Res> {
  _$DetectionItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DetectionItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? diseaseClass = null,
    Object? confidence = null,
    Object? time = null,
    Object? snapshotUrl = null,
  }) {
    return _then(
      _value.copyWith(
            diseaseClass: null == diseaseClass
                ? _value.diseaseClass
                : diseaseClass // ignore: cast_nullable_to_non_nullable
                      as String,
            confidence: null == confidence
                ? _value.confidence
                : confidence // ignore: cast_nullable_to_non_nullable
                      as double,
            time: null == time
                ? _value.time
                : time // ignore: cast_nullable_to_non_nullable
                      as String,
            snapshotUrl: null == snapshotUrl
                ? _value.snapshotUrl
                : snapshotUrl // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DetectionItemImplCopyWith<$Res>
    implements $DetectionItemCopyWith<$Res> {
  factory _$$DetectionItemImplCopyWith(
    _$DetectionItemImpl value,
    $Res Function(_$DetectionItemImpl) then,
  ) = __$$DetectionItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String diseaseClass,
    double confidence,
    String time,
    String snapshotUrl,
  });
}

/// @nodoc
class __$$DetectionItemImplCopyWithImpl<$Res>
    extends _$DetectionItemCopyWithImpl<$Res, _$DetectionItemImpl>
    implements _$$DetectionItemImplCopyWith<$Res> {
  __$$DetectionItemImplCopyWithImpl(
    _$DetectionItemImpl _value,
    $Res Function(_$DetectionItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DetectionItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? diseaseClass = null,
    Object? confidence = null,
    Object? time = null,
    Object? snapshotUrl = null,
  }) {
    return _then(
      _$DetectionItemImpl(
        diseaseClass: null == diseaseClass
            ? _value.diseaseClass
            : diseaseClass // ignore: cast_nullable_to_non_nullable
                  as String,
        confidence: null == confidence
            ? _value.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double,
        time: null == time
            ? _value.time
            : time // ignore: cast_nullable_to_non_nullable
                  as String,
        snapshotUrl: null == snapshotUrl
            ? _value.snapshotUrl
            : snapshotUrl // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$DetectionItemImpl implements _DetectionItem {
  const _$DetectionItemImpl({
    required this.diseaseClass,
    required this.confidence,
    required this.time,
    this.snapshotUrl = '',
  });

  @override
  final String diseaseClass;
  @override
  final double confidence;
  @override
  final String time;
  @override
  @JsonKey()
  final String snapshotUrl;

  @override
  String toString() {
    return 'DetectionItem(diseaseClass: $diseaseClass, confidence: $confidence, time: $time, snapshotUrl: $snapshotUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DetectionItemImpl &&
            (identical(other.diseaseClass, diseaseClass) ||
                other.diseaseClass == diseaseClass) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.time, time) || other.time == time) &&
            (identical(other.snapshotUrl, snapshotUrl) ||
                other.snapshotUrl == snapshotUrl));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, diseaseClass, confidence, time, snapshotUrl);

  /// Create a copy of DetectionItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DetectionItemImplCopyWith<_$DetectionItemImpl> get copyWith =>
      __$$DetectionItemImplCopyWithImpl<_$DetectionItemImpl>(this, _$identity);
}

abstract class _DetectionItem implements DetectionItem {
  const factory _DetectionItem({
    required final String diseaseClass,
    required final double confidence,
    required final String time,
    final String snapshotUrl,
  }) = _$DetectionItemImpl;

  @override
  String get diseaseClass;
  @override
  double get confidence;
  @override
  String get time;
  @override
  String get snapshotUrl;

  /// Create a copy of DetectionItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DetectionItemImplCopyWith<_$DetectionItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$Plant {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get imageUrl => throw _privateConstructorUsedError;
  String get videoUrl => throw _privateConstructorUsedError;
  DetectionItem? get latestDetection => throw _privateConstructorUsedError;
  List<DetectionItem> get history => throw _privateConstructorUsedError;

  /// Create a copy of Plant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlantCopyWith<Plant> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlantCopyWith<$Res> {
  factory $PlantCopyWith(Plant value, $Res Function(Plant) then) =
      _$PlantCopyWithImpl<$Res, Plant>;
  @useResult
  $Res call({
    String id,
    String name,
    String status,
    String imageUrl,
    String videoUrl,
    DetectionItem? latestDetection,
    List<DetectionItem> history,
  });

  $DetectionItemCopyWith<$Res>? get latestDetection;
}

/// @nodoc
class _$PlantCopyWithImpl<$Res, $Val extends Plant>
    implements $PlantCopyWith<$Res> {
  _$PlantCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Plant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? status = null,
    Object? imageUrl = null,
    Object? videoUrl = null,
    Object? latestDetection = freezed,
    Object? history = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            imageUrl: null == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            videoUrl: null == videoUrl
                ? _value.videoUrl
                : videoUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            latestDetection: freezed == latestDetection
                ? _value.latestDetection
                : latestDetection // ignore: cast_nullable_to_non_nullable
                      as DetectionItem?,
            history: null == history
                ? _value.history
                : history // ignore: cast_nullable_to_non_nullable
                      as List<DetectionItem>,
          )
          as $Val,
    );
  }

  /// Create a copy of Plant
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DetectionItemCopyWith<$Res>? get latestDetection {
    if (_value.latestDetection == null) {
      return null;
    }

    return $DetectionItemCopyWith<$Res>(_value.latestDetection!, (value) {
      return _then(_value.copyWith(latestDetection: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PlantImplCopyWith<$Res> implements $PlantCopyWith<$Res> {
  factory _$$PlantImplCopyWith(
    _$PlantImpl value,
    $Res Function(_$PlantImpl) then,
  ) = __$$PlantImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String status,
    String imageUrl,
    String videoUrl,
    DetectionItem? latestDetection,
    List<DetectionItem> history,
  });

  @override
  $DetectionItemCopyWith<$Res>? get latestDetection;
}

/// @nodoc
class __$$PlantImplCopyWithImpl<$Res>
    extends _$PlantCopyWithImpl<$Res, _$PlantImpl>
    implements _$$PlantImplCopyWith<$Res> {
  __$$PlantImplCopyWithImpl(
    _$PlantImpl _value,
    $Res Function(_$PlantImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Plant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? status = null,
    Object? imageUrl = null,
    Object? videoUrl = null,
    Object? latestDetection = freezed,
    Object? history = null,
  }) {
    return _then(
      _$PlantImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        imageUrl: null == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        videoUrl: null == videoUrl
            ? _value.videoUrl
            : videoUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        latestDetection: freezed == latestDetection
            ? _value.latestDetection
            : latestDetection // ignore: cast_nullable_to_non_nullable
                  as DetectionItem?,
        history: null == history
            ? _value._history
            : history // ignore: cast_nullable_to_non_nullable
                  as List<DetectionItem>,
      ),
    );
  }
}

/// @nodoc

class _$PlantImpl implements _Plant {
  const _$PlantImpl({
    required this.id,
    required this.name,
    required this.status,
    required this.imageUrl,
    required this.videoUrl,
    required this.latestDetection,
    required final List<DetectionItem> history,
  }) : _history = history;

  @override
  final String id;
  @override
  final String name;
  @override
  final String status;
  @override
  final String imageUrl;
  @override
  final String videoUrl;
  @override
  final DetectionItem? latestDetection;
  final List<DetectionItem> _history;
  @override
  List<DetectionItem> get history {
    if (_history is EqualUnmodifiableListView) return _history;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_history);
  }

  @override
  String toString() {
    return 'Plant(id: $id, name: $name, status: $status, imageUrl: $imageUrl, videoUrl: $videoUrl, latestDetection: $latestDetection, history: $history)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlantImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.videoUrl, videoUrl) ||
                other.videoUrl == videoUrl) &&
            (identical(other.latestDetection, latestDetection) ||
                other.latestDetection == latestDetection) &&
            const DeepCollectionEquality().equals(other._history, _history));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    status,
    imageUrl,
    videoUrl,
    latestDetection,
    const DeepCollectionEquality().hash(_history),
  );

  /// Create a copy of Plant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlantImplCopyWith<_$PlantImpl> get copyWith =>
      __$$PlantImplCopyWithImpl<_$PlantImpl>(this, _$identity);
}

abstract class _Plant implements Plant {
  const factory _Plant({
    required final String id,
    required final String name,
    required final String status,
    required final String imageUrl,
    required final String videoUrl,
    required final DetectionItem? latestDetection,
    required final List<DetectionItem> history,
  }) = _$PlantImpl;

  @override
  String get id;
  @override
  String get name;
  @override
  String get status;
  @override
  String get imageUrl;
  @override
  String get videoUrl;
  @override
  DetectionItem? get latestDetection;
  @override
  List<DetectionItem> get history;

  /// Create a copy of Plant
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlantImplCopyWith<_$PlantImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
