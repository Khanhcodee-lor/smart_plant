// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pi_provision_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PiProvisionState {
  bool get isSupported => throw _privateConstructorUsedError;
  bool get isInitialized => throw _privateConstructorUsedError;
  bool get permissionsGranted => throw _privateConstructorUsedError;
  bool get permissionsPermanentlyDenied => throw _privateConstructorUsedError;
  bool get bluetoothEnabled => throw _privateConstructorUsedError;
  ProvisionBleStage get bleStage => throw _privateConstructorUsedError;
  List<ScanResult> get devices => throw _privateConstructorUsedError;
  ScanResult? get selectedDevice => throw _privateConstructorUsedError;
  List<PiWifiNetwork> get wifiNetworks => throw _privateConstructorUsedError;
  PiWifiNetwork? get selectedWifiNetwork => throw _privateConstructorUsedError;
  PiWifiStatus? get wifiStatus => throw _privateConstructorUsedError;
  String get wifiPassword => throw _privateConstructorUsedError;
  String? get lastCommandAction => throw _privateConstructorUsedError;
  String? get infoMessage => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  String? get statusDebugValue => throw _privateConstructorUsedError;

  /// Create a copy of PiProvisionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PiProvisionStateCopyWith<PiProvisionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PiProvisionStateCopyWith<$Res> {
  factory $PiProvisionStateCopyWith(
    PiProvisionState value,
    $Res Function(PiProvisionState) then,
  ) = _$PiProvisionStateCopyWithImpl<$Res, PiProvisionState>;
  @useResult
  $Res call({
    bool isSupported,
    bool isInitialized,
    bool permissionsGranted,
    bool permissionsPermanentlyDenied,
    bool bluetoothEnabled,
    ProvisionBleStage bleStage,
    List<ScanResult> devices,
    ScanResult? selectedDevice,
    List<PiWifiNetwork> wifiNetworks,
    PiWifiNetwork? selectedWifiNetwork,
    PiWifiStatus? wifiStatus,
    String wifiPassword,
    String? lastCommandAction,
    String? infoMessage,
    String? errorMessage,
    String? statusDebugValue,
  });
}

/// @nodoc
class _$PiProvisionStateCopyWithImpl<$Res, $Val extends PiProvisionState>
    implements $PiProvisionStateCopyWith<$Res> {
  _$PiProvisionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PiProvisionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isSupported = null,
    Object? isInitialized = null,
    Object? permissionsGranted = null,
    Object? permissionsPermanentlyDenied = null,
    Object? bluetoothEnabled = null,
    Object? bleStage = null,
    Object? devices = null,
    Object? selectedDevice = freezed,
    Object? wifiNetworks = null,
    Object? selectedWifiNetwork = freezed,
    Object? wifiStatus = freezed,
    Object? wifiPassword = null,
    Object? lastCommandAction = freezed,
    Object? infoMessage = freezed,
    Object? errorMessage = freezed,
    Object? statusDebugValue = freezed,
  }) {
    return _then(
      _value.copyWith(
            isSupported: null == isSupported
                ? _value.isSupported
                : isSupported // ignore: cast_nullable_to_non_nullable
                      as bool,
            isInitialized: null == isInitialized
                ? _value.isInitialized
                : isInitialized // ignore: cast_nullable_to_non_nullable
                      as bool,
            permissionsGranted: null == permissionsGranted
                ? _value.permissionsGranted
                : permissionsGranted // ignore: cast_nullable_to_non_nullable
                      as bool,
            permissionsPermanentlyDenied: null == permissionsPermanentlyDenied
                ? _value.permissionsPermanentlyDenied
                : permissionsPermanentlyDenied // ignore: cast_nullable_to_non_nullable
                      as bool,
            bluetoothEnabled: null == bluetoothEnabled
                ? _value.bluetoothEnabled
                : bluetoothEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            bleStage: null == bleStage
                ? _value.bleStage
                : bleStage // ignore: cast_nullable_to_non_nullable
                      as ProvisionBleStage,
            devices: null == devices
                ? _value.devices
                : devices // ignore: cast_nullable_to_non_nullable
                      as List<ScanResult>,
            selectedDevice: freezed == selectedDevice
                ? _value.selectedDevice
                : selectedDevice // ignore: cast_nullable_to_non_nullable
                      as ScanResult?,
            wifiNetworks: null == wifiNetworks
                ? _value.wifiNetworks
                : wifiNetworks // ignore: cast_nullable_to_non_nullable
                      as List<PiWifiNetwork>,
            selectedWifiNetwork: freezed == selectedWifiNetwork
                ? _value.selectedWifiNetwork
                : selectedWifiNetwork // ignore: cast_nullable_to_non_nullable
                      as PiWifiNetwork?,
            wifiStatus: freezed == wifiStatus
                ? _value.wifiStatus
                : wifiStatus // ignore: cast_nullable_to_non_nullable
                      as PiWifiStatus?,
            wifiPassword: null == wifiPassword
                ? _value.wifiPassword
                : wifiPassword // ignore: cast_nullable_to_non_nullable
                      as String,
            lastCommandAction: freezed == lastCommandAction
                ? _value.lastCommandAction
                : lastCommandAction // ignore: cast_nullable_to_non_nullable
                      as String?,
            infoMessage: freezed == infoMessage
                ? _value.infoMessage
                : infoMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
            errorMessage: freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
            statusDebugValue: freezed == statusDebugValue
                ? _value.statusDebugValue
                : statusDebugValue // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PiProvisionStateImplCopyWith<$Res>
    implements $PiProvisionStateCopyWith<$Res> {
  factory _$$PiProvisionStateImplCopyWith(
    _$PiProvisionStateImpl value,
    $Res Function(_$PiProvisionStateImpl) then,
  ) = __$$PiProvisionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool isSupported,
    bool isInitialized,
    bool permissionsGranted,
    bool permissionsPermanentlyDenied,
    bool bluetoothEnabled,
    ProvisionBleStage bleStage,
    List<ScanResult> devices,
    ScanResult? selectedDevice,
    List<PiWifiNetwork> wifiNetworks,
    PiWifiNetwork? selectedWifiNetwork,
    PiWifiStatus? wifiStatus,
    String wifiPassword,
    String? lastCommandAction,
    String? infoMessage,
    String? errorMessage,
    String? statusDebugValue,
  });
}

/// @nodoc
class __$$PiProvisionStateImplCopyWithImpl<$Res>
    extends _$PiProvisionStateCopyWithImpl<$Res, _$PiProvisionStateImpl>
    implements _$$PiProvisionStateImplCopyWith<$Res> {
  __$$PiProvisionStateImplCopyWithImpl(
    _$PiProvisionStateImpl _value,
    $Res Function(_$PiProvisionStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PiProvisionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isSupported = null,
    Object? isInitialized = null,
    Object? permissionsGranted = null,
    Object? permissionsPermanentlyDenied = null,
    Object? bluetoothEnabled = null,
    Object? bleStage = null,
    Object? devices = null,
    Object? selectedDevice = freezed,
    Object? wifiNetworks = null,
    Object? selectedWifiNetwork = freezed,
    Object? wifiStatus = freezed,
    Object? wifiPassword = null,
    Object? lastCommandAction = freezed,
    Object? infoMessage = freezed,
    Object? errorMessage = freezed,
    Object? statusDebugValue = freezed,
  }) {
    return _then(
      _$PiProvisionStateImpl(
        isSupported: null == isSupported
            ? _value.isSupported
            : isSupported // ignore: cast_nullable_to_non_nullable
                  as bool,
        isInitialized: null == isInitialized
            ? _value.isInitialized
            : isInitialized // ignore: cast_nullable_to_non_nullable
                  as bool,
        permissionsGranted: null == permissionsGranted
            ? _value.permissionsGranted
            : permissionsGranted // ignore: cast_nullable_to_non_nullable
                  as bool,
        permissionsPermanentlyDenied: null == permissionsPermanentlyDenied
            ? _value.permissionsPermanentlyDenied
            : permissionsPermanentlyDenied // ignore: cast_nullable_to_non_nullable
                  as bool,
        bluetoothEnabled: null == bluetoothEnabled
            ? _value.bluetoothEnabled
            : bluetoothEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        bleStage: null == bleStage
            ? _value.bleStage
            : bleStage // ignore: cast_nullable_to_non_nullable
                  as ProvisionBleStage,
        devices: null == devices
            ? _value._devices
            : devices // ignore: cast_nullable_to_non_nullable
                  as List<ScanResult>,
        selectedDevice: freezed == selectedDevice
            ? _value.selectedDevice
            : selectedDevice // ignore: cast_nullable_to_non_nullable
                  as ScanResult?,
        wifiNetworks: null == wifiNetworks
            ? _value._wifiNetworks
            : wifiNetworks // ignore: cast_nullable_to_non_nullable
                  as List<PiWifiNetwork>,
        selectedWifiNetwork: freezed == selectedWifiNetwork
            ? _value.selectedWifiNetwork
            : selectedWifiNetwork // ignore: cast_nullable_to_non_nullable
                  as PiWifiNetwork?,
        wifiStatus: freezed == wifiStatus
            ? _value.wifiStatus
            : wifiStatus // ignore: cast_nullable_to_non_nullable
                  as PiWifiStatus?,
        wifiPassword: null == wifiPassword
            ? _value.wifiPassword
            : wifiPassword // ignore: cast_nullable_to_non_nullable
                  as String,
        lastCommandAction: freezed == lastCommandAction
            ? _value.lastCommandAction
            : lastCommandAction // ignore: cast_nullable_to_non_nullable
                  as String?,
        infoMessage: freezed == infoMessage
            ? _value.infoMessage
            : infoMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
        errorMessage: freezed == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
        statusDebugValue: freezed == statusDebugValue
            ? _value.statusDebugValue
            : statusDebugValue // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$PiProvisionStateImpl extends _PiProvisionState {
  const _$PiProvisionStateImpl({
    this.isSupported = true,
    this.isInitialized = false,
    this.permissionsGranted = false,
    this.permissionsPermanentlyDenied = false,
    this.bluetoothEnabled = false,
    this.bleStage = ProvisionBleStage.idle,
    final List<ScanResult> devices = const [],
    this.selectedDevice,
    final List<PiWifiNetwork> wifiNetworks = const [],
    this.selectedWifiNetwork,
    this.wifiStatus,
    this.wifiPassword = '',
    this.lastCommandAction,
    this.infoMessage,
    this.errorMessage,
    this.statusDebugValue,
  }) : _devices = devices,
       _wifiNetworks = wifiNetworks,
       super._();

  @override
  @JsonKey()
  final bool isSupported;
  @override
  @JsonKey()
  final bool isInitialized;
  @override
  @JsonKey()
  final bool permissionsGranted;
  @override
  @JsonKey()
  final bool permissionsPermanentlyDenied;
  @override
  @JsonKey()
  final bool bluetoothEnabled;
  @override
  @JsonKey()
  final ProvisionBleStage bleStage;
  final List<ScanResult> _devices;
  @override
  @JsonKey()
  List<ScanResult> get devices {
    if (_devices is EqualUnmodifiableListView) return _devices;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_devices);
  }

  @override
  final ScanResult? selectedDevice;
  final List<PiWifiNetwork> _wifiNetworks;
  @override
  @JsonKey()
  List<PiWifiNetwork> get wifiNetworks {
    if (_wifiNetworks is EqualUnmodifiableListView) return _wifiNetworks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_wifiNetworks);
  }

  @override
  final PiWifiNetwork? selectedWifiNetwork;
  @override
  final PiWifiStatus? wifiStatus;
  @override
  @JsonKey()
  final String wifiPassword;
  @override
  final String? lastCommandAction;
  @override
  final String? infoMessage;
  @override
  final String? errorMessage;
  @override
  final String? statusDebugValue;

  @override
  String toString() {
    return 'PiProvisionState(isSupported: $isSupported, isInitialized: $isInitialized, permissionsGranted: $permissionsGranted, permissionsPermanentlyDenied: $permissionsPermanentlyDenied, bluetoothEnabled: $bluetoothEnabled, bleStage: $bleStage, devices: $devices, selectedDevice: $selectedDevice, wifiNetworks: $wifiNetworks, selectedWifiNetwork: $selectedWifiNetwork, wifiStatus: $wifiStatus, wifiPassword: $wifiPassword, lastCommandAction: $lastCommandAction, infoMessage: $infoMessage, errorMessage: $errorMessage, statusDebugValue: $statusDebugValue)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PiProvisionStateImpl &&
            (identical(other.isSupported, isSupported) ||
                other.isSupported == isSupported) &&
            (identical(other.isInitialized, isInitialized) ||
                other.isInitialized == isInitialized) &&
            (identical(other.permissionsGranted, permissionsGranted) ||
                other.permissionsGranted == permissionsGranted) &&
            (identical(
                  other.permissionsPermanentlyDenied,
                  permissionsPermanentlyDenied,
                ) ||
                other.permissionsPermanentlyDenied ==
                    permissionsPermanentlyDenied) &&
            (identical(other.bluetoothEnabled, bluetoothEnabled) ||
                other.bluetoothEnabled == bluetoothEnabled) &&
            (identical(other.bleStage, bleStage) ||
                other.bleStage == bleStage) &&
            const DeepCollectionEquality().equals(other._devices, _devices) &&
            (identical(other.selectedDevice, selectedDevice) ||
                other.selectedDevice == selectedDevice) &&
            const DeepCollectionEquality().equals(
              other._wifiNetworks,
              _wifiNetworks,
            ) &&
            (identical(other.selectedWifiNetwork, selectedWifiNetwork) ||
                other.selectedWifiNetwork == selectedWifiNetwork) &&
            (identical(other.wifiStatus, wifiStatus) ||
                other.wifiStatus == wifiStatus) &&
            (identical(other.wifiPassword, wifiPassword) ||
                other.wifiPassword == wifiPassword) &&
            (identical(other.lastCommandAction, lastCommandAction) ||
                other.lastCommandAction == lastCommandAction) &&
            (identical(other.infoMessage, infoMessage) ||
                other.infoMessage == infoMessage) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.statusDebugValue, statusDebugValue) ||
                other.statusDebugValue == statusDebugValue));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    isSupported,
    isInitialized,
    permissionsGranted,
    permissionsPermanentlyDenied,
    bluetoothEnabled,
    bleStage,
    const DeepCollectionEquality().hash(_devices),
    selectedDevice,
    const DeepCollectionEquality().hash(_wifiNetworks),
    selectedWifiNetwork,
    wifiStatus,
    wifiPassword,
    lastCommandAction,
    infoMessage,
    errorMessage,
    statusDebugValue,
  );

  /// Create a copy of PiProvisionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PiProvisionStateImplCopyWith<_$PiProvisionStateImpl> get copyWith =>
      __$$PiProvisionStateImplCopyWithImpl<_$PiProvisionStateImpl>(
        this,
        _$identity,
      );
}

abstract class _PiProvisionState extends PiProvisionState {
  const factory _PiProvisionState({
    final bool isSupported,
    final bool isInitialized,
    final bool permissionsGranted,
    final bool permissionsPermanentlyDenied,
    final bool bluetoothEnabled,
    final ProvisionBleStage bleStage,
    final List<ScanResult> devices,
    final ScanResult? selectedDevice,
    final List<PiWifiNetwork> wifiNetworks,
    final PiWifiNetwork? selectedWifiNetwork,
    final PiWifiStatus? wifiStatus,
    final String wifiPassword,
    final String? lastCommandAction,
    final String? infoMessage,
    final String? errorMessage,
    final String? statusDebugValue,
  }) = _$PiProvisionStateImpl;
  const _PiProvisionState._() : super._();

  @override
  bool get isSupported;
  @override
  bool get isInitialized;
  @override
  bool get permissionsGranted;
  @override
  bool get permissionsPermanentlyDenied;
  @override
  bool get bluetoothEnabled;
  @override
  ProvisionBleStage get bleStage;
  @override
  List<ScanResult> get devices;
  @override
  ScanResult? get selectedDevice;
  @override
  List<PiWifiNetwork> get wifiNetworks;
  @override
  PiWifiNetwork? get selectedWifiNetwork;
  @override
  PiWifiStatus? get wifiStatus;
  @override
  String get wifiPassword;
  @override
  String? get lastCommandAction;
  @override
  String? get infoMessage;
  @override
  String? get errorMessage;
  @override
  String? get statusDebugValue;

  /// Create a copy of PiProvisionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PiProvisionStateImplCopyWith<_$PiProvisionStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
