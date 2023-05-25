// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bridge_definitions.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$DomainMessage {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() preAccount,
    required TResult Function(List<NearbyStation> field0) nearbyStations,
    required TResult Function(StationConfig field0, SensitiveConfig? field1)
        stationRefreshed,
    required TResult Function(TransferProgress field0) transferProgress,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? preAccount,
    TResult? Function(List<NearbyStation> field0)? nearbyStations,
    TResult? Function(StationConfig field0, SensitiveConfig? field1)?
        stationRefreshed,
    TResult? Function(TransferProgress field0)? transferProgress,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? preAccount,
    TResult Function(List<NearbyStation> field0)? nearbyStations,
    TResult Function(StationConfig field0, SensitiveConfig? field1)?
        stationRefreshed,
    TResult Function(TransferProgress field0)? transferProgress,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DomainMessage_PreAccount value) preAccount,
    required TResult Function(DomainMessage_NearbyStations value)
        nearbyStations,
    required TResult Function(DomainMessage_StationRefreshed value)
        stationRefreshed,
    required TResult Function(DomainMessage_TransferProgress value)
        transferProgress,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DomainMessage_PreAccount value)? preAccount,
    TResult? Function(DomainMessage_NearbyStations value)? nearbyStations,
    TResult? Function(DomainMessage_StationRefreshed value)? stationRefreshed,
    TResult? Function(DomainMessage_TransferProgress value)? transferProgress,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DomainMessage_PreAccount value)? preAccount,
    TResult Function(DomainMessage_NearbyStations value)? nearbyStations,
    TResult Function(DomainMessage_StationRefreshed value)? stationRefreshed,
    TResult Function(DomainMessage_TransferProgress value)? transferProgress,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DomainMessageCopyWith<$Res> {
  factory $DomainMessageCopyWith(
          DomainMessage value, $Res Function(DomainMessage) then) =
      _$DomainMessageCopyWithImpl<$Res, DomainMessage>;
}

/// @nodoc
class _$DomainMessageCopyWithImpl<$Res, $Val extends DomainMessage>
    implements $DomainMessageCopyWith<$Res> {
  _$DomainMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$DomainMessage_PreAccountCopyWith<$Res> {
  factory _$$DomainMessage_PreAccountCopyWith(_$DomainMessage_PreAccount value,
          $Res Function(_$DomainMessage_PreAccount) then) =
      __$$DomainMessage_PreAccountCopyWithImpl<$Res>;
}

/// @nodoc
class __$$DomainMessage_PreAccountCopyWithImpl<$Res>
    extends _$DomainMessageCopyWithImpl<$Res, _$DomainMessage_PreAccount>
    implements _$$DomainMessage_PreAccountCopyWith<$Res> {
  __$$DomainMessage_PreAccountCopyWithImpl(_$DomainMessage_PreAccount _value,
      $Res Function(_$DomainMessage_PreAccount) _then)
      : super(_value, _then);
}

/// @nodoc

class _$DomainMessage_PreAccount implements DomainMessage_PreAccount {
  const _$DomainMessage_PreAccount();

  @override
  String toString() {
    return 'DomainMessage.preAccount()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DomainMessage_PreAccount);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() preAccount,
    required TResult Function(List<NearbyStation> field0) nearbyStations,
    required TResult Function(StationConfig field0, SensitiveConfig? field1)
        stationRefreshed,
    required TResult Function(TransferProgress field0) transferProgress,
  }) {
    return preAccount();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? preAccount,
    TResult? Function(List<NearbyStation> field0)? nearbyStations,
    TResult? Function(StationConfig field0, SensitiveConfig? field1)?
        stationRefreshed,
    TResult? Function(TransferProgress field0)? transferProgress,
  }) {
    return preAccount?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? preAccount,
    TResult Function(List<NearbyStation> field0)? nearbyStations,
    TResult Function(StationConfig field0, SensitiveConfig? field1)?
        stationRefreshed,
    TResult Function(TransferProgress field0)? transferProgress,
    required TResult orElse(),
  }) {
    if (preAccount != null) {
      return preAccount();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DomainMessage_PreAccount value) preAccount,
    required TResult Function(DomainMessage_NearbyStations value)
        nearbyStations,
    required TResult Function(DomainMessage_StationRefreshed value)
        stationRefreshed,
    required TResult Function(DomainMessage_TransferProgress value)
        transferProgress,
  }) {
    return preAccount(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DomainMessage_PreAccount value)? preAccount,
    TResult? Function(DomainMessage_NearbyStations value)? nearbyStations,
    TResult? Function(DomainMessage_StationRefreshed value)? stationRefreshed,
    TResult? Function(DomainMessage_TransferProgress value)? transferProgress,
  }) {
    return preAccount?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DomainMessage_PreAccount value)? preAccount,
    TResult Function(DomainMessage_NearbyStations value)? nearbyStations,
    TResult Function(DomainMessage_StationRefreshed value)? stationRefreshed,
    TResult Function(DomainMessage_TransferProgress value)? transferProgress,
    required TResult orElse(),
  }) {
    if (preAccount != null) {
      return preAccount(this);
    }
    return orElse();
  }
}

abstract class DomainMessage_PreAccount implements DomainMessage {
  const factory DomainMessage_PreAccount() = _$DomainMessage_PreAccount;
}

/// @nodoc
abstract class _$$DomainMessage_NearbyStationsCopyWith<$Res> {
  factory _$$DomainMessage_NearbyStationsCopyWith(
          _$DomainMessage_NearbyStations value,
          $Res Function(_$DomainMessage_NearbyStations) then) =
      __$$DomainMessage_NearbyStationsCopyWithImpl<$Res>;
  @useResult
  $Res call({List<NearbyStation> field0});
}

/// @nodoc
class __$$DomainMessage_NearbyStationsCopyWithImpl<$Res>
    extends _$DomainMessageCopyWithImpl<$Res, _$DomainMessage_NearbyStations>
    implements _$$DomainMessage_NearbyStationsCopyWith<$Res> {
  __$$DomainMessage_NearbyStationsCopyWithImpl(
      _$DomainMessage_NearbyStations _value,
      $Res Function(_$DomainMessage_NearbyStations) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$DomainMessage_NearbyStations(
      null == field0
          ? _value._field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as List<NearbyStation>,
    ));
  }
}

/// @nodoc

class _$DomainMessage_NearbyStations implements DomainMessage_NearbyStations {
  const _$DomainMessage_NearbyStations(final List<NearbyStation> field0)
      : _field0 = field0;

  final List<NearbyStation> _field0;
  @override
  List<NearbyStation> get field0 {
    if (_field0 is EqualUnmodifiableListView) return _field0;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_field0);
  }

  @override
  String toString() {
    return 'DomainMessage.nearbyStations(field0: $field0)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DomainMessage_NearbyStations &&
            const DeepCollectionEquality().equals(other._field0, _field0));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_field0));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DomainMessage_NearbyStationsCopyWith<_$DomainMessage_NearbyStations>
      get copyWith => __$$DomainMessage_NearbyStationsCopyWithImpl<
          _$DomainMessage_NearbyStations>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() preAccount,
    required TResult Function(List<NearbyStation> field0) nearbyStations,
    required TResult Function(StationConfig field0, SensitiveConfig? field1)
        stationRefreshed,
    required TResult Function(TransferProgress field0) transferProgress,
  }) {
    return nearbyStations(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? preAccount,
    TResult? Function(List<NearbyStation> field0)? nearbyStations,
    TResult? Function(StationConfig field0, SensitiveConfig? field1)?
        stationRefreshed,
    TResult? Function(TransferProgress field0)? transferProgress,
  }) {
    return nearbyStations?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? preAccount,
    TResult Function(List<NearbyStation> field0)? nearbyStations,
    TResult Function(StationConfig field0, SensitiveConfig? field1)?
        stationRefreshed,
    TResult Function(TransferProgress field0)? transferProgress,
    required TResult orElse(),
  }) {
    if (nearbyStations != null) {
      return nearbyStations(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DomainMessage_PreAccount value) preAccount,
    required TResult Function(DomainMessage_NearbyStations value)
        nearbyStations,
    required TResult Function(DomainMessage_StationRefreshed value)
        stationRefreshed,
    required TResult Function(DomainMessage_TransferProgress value)
        transferProgress,
  }) {
    return nearbyStations(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DomainMessage_PreAccount value)? preAccount,
    TResult? Function(DomainMessage_NearbyStations value)? nearbyStations,
    TResult? Function(DomainMessage_StationRefreshed value)? stationRefreshed,
    TResult? Function(DomainMessage_TransferProgress value)? transferProgress,
  }) {
    return nearbyStations?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DomainMessage_PreAccount value)? preAccount,
    TResult Function(DomainMessage_NearbyStations value)? nearbyStations,
    TResult Function(DomainMessage_StationRefreshed value)? stationRefreshed,
    TResult Function(DomainMessage_TransferProgress value)? transferProgress,
    required TResult orElse(),
  }) {
    if (nearbyStations != null) {
      return nearbyStations(this);
    }
    return orElse();
  }
}

abstract class DomainMessage_NearbyStations implements DomainMessage {
  const factory DomainMessage_NearbyStations(final List<NearbyStation> field0) =
      _$DomainMessage_NearbyStations;

  List<NearbyStation> get field0;
  @JsonKey(ignore: true)
  _$$DomainMessage_NearbyStationsCopyWith<_$DomainMessage_NearbyStations>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DomainMessage_StationRefreshedCopyWith<$Res> {
  factory _$$DomainMessage_StationRefreshedCopyWith(
          _$DomainMessage_StationRefreshed value,
          $Res Function(_$DomainMessage_StationRefreshed) then) =
      __$$DomainMessage_StationRefreshedCopyWithImpl<$Res>;
  @useResult
  $Res call({StationConfig field0, SensitiveConfig? field1});
}

/// @nodoc
class __$$DomainMessage_StationRefreshedCopyWithImpl<$Res>
    extends _$DomainMessageCopyWithImpl<$Res, _$DomainMessage_StationRefreshed>
    implements _$$DomainMessage_StationRefreshedCopyWith<$Res> {
  __$$DomainMessage_StationRefreshedCopyWithImpl(
      _$DomainMessage_StationRefreshed _value,
      $Res Function(_$DomainMessage_StationRefreshed) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
    Object? field1 = freezed,
  }) {
    return _then(_$DomainMessage_StationRefreshed(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as StationConfig,
      freezed == field1
          ? _value.field1
          : field1 // ignore: cast_nullable_to_non_nullable
              as SensitiveConfig?,
    ));
  }
}

/// @nodoc

class _$DomainMessage_StationRefreshed
    implements DomainMessage_StationRefreshed {
  const _$DomainMessage_StationRefreshed(this.field0, [this.field1]);

  @override
  final StationConfig field0;
  @override
  final SensitiveConfig? field1;

  @override
  String toString() {
    return 'DomainMessage.stationRefreshed(field0: $field0, field1: $field1)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DomainMessage_StationRefreshed &&
            (identical(other.field0, field0) || other.field0 == field0) &&
            (identical(other.field1, field1) || other.field1 == field1));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0, field1);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DomainMessage_StationRefreshedCopyWith<_$DomainMessage_StationRefreshed>
      get copyWith => __$$DomainMessage_StationRefreshedCopyWithImpl<
          _$DomainMessage_StationRefreshed>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() preAccount,
    required TResult Function(List<NearbyStation> field0) nearbyStations,
    required TResult Function(StationConfig field0, SensitiveConfig? field1)
        stationRefreshed,
    required TResult Function(TransferProgress field0) transferProgress,
  }) {
    return stationRefreshed(field0, field1);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? preAccount,
    TResult? Function(List<NearbyStation> field0)? nearbyStations,
    TResult? Function(StationConfig field0, SensitiveConfig? field1)?
        stationRefreshed,
    TResult? Function(TransferProgress field0)? transferProgress,
  }) {
    return stationRefreshed?.call(field0, field1);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? preAccount,
    TResult Function(List<NearbyStation> field0)? nearbyStations,
    TResult Function(StationConfig field0, SensitiveConfig? field1)?
        stationRefreshed,
    TResult Function(TransferProgress field0)? transferProgress,
    required TResult orElse(),
  }) {
    if (stationRefreshed != null) {
      return stationRefreshed(field0, field1);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DomainMessage_PreAccount value) preAccount,
    required TResult Function(DomainMessage_NearbyStations value)
        nearbyStations,
    required TResult Function(DomainMessage_StationRefreshed value)
        stationRefreshed,
    required TResult Function(DomainMessage_TransferProgress value)
        transferProgress,
  }) {
    return stationRefreshed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DomainMessage_PreAccount value)? preAccount,
    TResult? Function(DomainMessage_NearbyStations value)? nearbyStations,
    TResult? Function(DomainMessage_StationRefreshed value)? stationRefreshed,
    TResult? Function(DomainMessage_TransferProgress value)? transferProgress,
  }) {
    return stationRefreshed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DomainMessage_PreAccount value)? preAccount,
    TResult Function(DomainMessage_NearbyStations value)? nearbyStations,
    TResult Function(DomainMessage_StationRefreshed value)? stationRefreshed,
    TResult Function(DomainMessage_TransferProgress value)? transferProgress,
    required TResult orElse(),
  }) {
    if (stationRefreshed != null) {
      return stationRefreshed(this);
    }
    return orElse();
  }
}

abstract class DomainMessage_StationRefreshed implements DomainMessage {
  const factory DomainMessage_StationRefreshed(final StationConfig field0,
      [final SensitiveConfig? field1]) = _$DomainMessage_StationRefreshed;

  StationConfig get field0;
  SensitiveConfig? get field1;
  @JsonKey(ignore: true)
  _$$DomainMessage_StationRefreshedCopyWith<_$DomainMessage_StationRefreshed>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DomainMessage_TransferProgressCopyWith<$Res> {
  factory _$$DomainMessage_TransferProgressCopyWith(
          _$DomainMessage_TransferProgress value,
          $Res Function(_$DomainMessage_TransferProgress) then) =
      __$$DomainMessage_TransferProgressCopyWithImpl<$Res>;
  @useResult
  $Res call({TransferProgress field0});
}

/// @nodoc
class __$$DomainMessage_TransferProgressCopyWithImpl<$Res>
    extends _$DomainMessageCopyWithImpl<$Res, _$DomainMessage_TransferProgress>
    implements _$$DomainMessage_TransferProgressCopyWith<$Res> {
  __$$DomainMessage_TransferProgressCopyWithImpl(
      _$DomainMessage_TransferProgress _value,
      $Res Function(_$DomainMessage_TransferProgress) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$DomainMessage_TransferProgress(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as TransferProgress,
    ));
  }
}

/// @nodoc

class _$DomainMessage_TransferProgress
    implements DomainMessage_TransferProgress {
  const _$DomainMessage_TransferProgress(this.field0);

  @override
  final TransferProgress field0;

  @override
  String toString() {
    return 'DomainMessage.transferProgress(field0: $field0)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DomainMessage_TransferProgress &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DomainMessage_TransferProgressCopyWith<_$DomainMessage_TransferProgress>
      get copyWith => __$$DomainMessage_TransferProgressCopyWithImpl<
          _$DomainMessage_TransferProgress>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() preAccount,
    required TResult Function(List<NearbyStation> field0) nearbyStations,
    required TResult Function(StationConfig field0, SensitiveConfig? field1)
        stationRefreshed,
    required TResult Function(TransferProgress field0) transferProgress,
  }) {
    return transferProgress(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? preAccount,
    TResult? Function(List<NearbyStation> field0)? nearbyStations,
    TResult? Function(StationConfig field0, SensitiveConfig? field1)?
        stationRefreshed,
    TResult? Function(TransferProgress field0)? transferProgress,
  }) {
    return transferProgress?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? preAccount,
    TResult Function(List<NearbyStation> field0)? nearbyStations,
    TResult Function(StationConfig field0, SensitiveConfig? field1)?
        stationRefreshed,
    TResult Function(TransferProgress field0)? transferProgress,
    required TResult orElse(),
  }) {
    if (transferProgress != null) {
      return transferProgress(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(DomainMessage_PreAccount value) preAccount,
    required TResult Function(DomainMessage_NearbyStations value)
        nearbyStations,
    required TResult Function(DomainMessage_StationRefreshed value)
        stationRefreshed,
    required TResult Function(DomainMessage_TransferProgress value)
        transferProgress,
  }) {
    return transferProgress(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DomainMessage_PreAccount value)? preAccount,
    TResult? Function(DomainMessage_NearbyStations value)? nearbyStations,
    TResult? Function(DomainMessage_StationRefreshed value)? stationRefreshed,
    TResult? Function(DomainMessage_TransferProgress value)? transferProgress,
  }) {
    return transferProgress?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DomainMessage_PreAccount value)? preAccount,
    TResult Function(DomainMessage_NearbyStations value)? nearbyStations,
    TResult Function(DomainMessage_StationRefreshed value)? stationRefreshed,
    TResult Function(DomainMessage_TransferProgress value)? transferProgress,
    required TResult orElse(),
  }) {
    if (transferProgress != null) {
      return transferProgress(this);
    }
    return orElse();
  }
}

abstract class DomainMessage_TransferProgress implements DomainMessage {
  const factory DomainMessage_TransferProgress(final TransferProgress field0) =
      _$DomainMessage_TransferProgress;

  TransferProgress get field0;
  @JsonKey(ignore: true)
  _$$DomainMessage_TransferProgressCopyWith<_$DomainMessage_TransferProgress>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$TransferStatus {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() starting,
    required TResult Function(DownloadProgress field0) transferring,
    required TResult Function() completed,
    required TResult Function() failed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? starting,
    TResult? Function(DownloadProgress field0)? transferring,
    TResult? Function()? completed,
    TResult? Function()? failed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? starting,
    TResult Function(DownloadProgress field0)? transferring,
    TResult Function()? completed,
    TResult Function()? failed,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TransferStatus_Starting value) starting,
    required TResult Function(TransferStatus_Transferring value) transferring,
    required TResult Function(TransferStatus_Completed value) completed,
    required TResult Function(TransferStatus_Failed value) failed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TransferStatus_Starting value)? starting,
    TResult? Function(TransferStatus_Transferring value)? transferring,
    TResult? Function(TransferStatus_Completed value)? completed,
    TResult? Function(TransferStatus_Failed value)? failed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TransferStatus_Starting value)? starting,
    TResult Function(TransferStatus_Transferring value)? transferring,
    TResult Function(TransferStatus_Completed value)? completed,
    TResult Function(TransferStatus_Failed value)? failed,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransferStatusCopyWith<$Res> {
  factory $TransferStatusCopyWith(
          TransferStatus value, $Res Function(TransferStatus) then) =
      _$TransferStatusCopyWithImpl<$Res, TransferStatus>;
}

/// @nodoc
class _$TransferStatusCopyWithImpl<$Res, $Val extends TransferStatus>
    implements $TransferStatusCopyWith<$Res> {
  _$TransferStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$TransferStatus_StartingCopyWith<$Res> {
  factory _$$TransferStatus_StartingCopyWith(_$TransferStatus_Starting value,
          $Res Function(_$TransferStatus_Starting) then) =
      __$$TransferStatus_StartingCopyWithImpl<$Res>;
}

/// @nodoc
class __$$TransferStatus_StartingCopyWithImpl<$Res>
    extends _$TransferStatusCopyWithImpl<$Res, _$TransferStatus_Starting>
    implements _$$TransferStatus_StartingCopyWith<$Res> {
  __$$TransferStatus_StartingCopyWithImpl(_$TransferStatus_Starting _value,
      $Res Function(_$TransferStatus_Starting) _then)
      : super(_value, _then);
}

/// @nodoc

class _$TransferStatus_Starting implements TransferStatus_Starting {
  const _$TransferStatus_Starting();

  @override
  String toString() {
    return 'TransferStatus.starting()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransferStatus_Starting);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() starting,
    required TResult Function(DownloadProgress field0) transferring,
    required TResult Function() completed,
    required TResult Function() failed,
  }) {
    return starting();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? starting,
    TResult? Function(DownloadProgress field0)? transferring,
    TResult? Function()? completed,
    TResult? Function()? failed,
  }) {
    return starting?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? starting,
    TResult Function(DownloadProgress field0)? transferring,
    TResult Function()? completed,
    TResult Function()? failed,
    required TResult orElse(),
  }) {
    if (starting != null) {
      return starting();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TransferStatus_Starting value) starting,
    required TResult Function(TransferStatus_Transferring value) transferring,
    required TResult Function(TransferStatus_Completed value) completed,
    required TResult Function(TransferStatus_Failed value) failed,
  }) {
    return starting(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TransferStatus_Starting value)? starting,
    TResult? Function(TransferStatus_Transferring value)? transferring,
    TResult? Function(TransferStatus_Completed value)? completed,
    TResult? Function(TransferStatus_Failed value)? failed,
  }) {
    return starting?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TransferStatus_Starting value)? starting,
    TResult Function(TransferStatus_Transferring value)? transferring,
    TResult Function(TransferStatus_Completed value)? completed,
    TResult Function(TransferStatus_Failed value)? failed,
    required TResult orElse(),
  }) {
    if (starting != null) {
      return starting(this);
    }
    return orElse();
  }
}

abstract class TransferStatus_Starting implements TransferStatus {
  const factory TransferStatus_Starting() = _$TransferStatus_Starting;
}

/// @nodoc
abstract class _$$TransferStatus_TransferringCopyWith<$Res> {
  factory _$$TransferStatus_TransferringCopyWith(
          _$TransferStatus_Transferring value,
          $Res Function(_$TransferStatus_Transferring) then) =
      __$$TransferStatus_TransferringCopyWithImpl<$Res>;
  @useResult
  $Res call({DownloadProgress field0});
}

/// @nodoc
class __$$TransferStatus_TransferringCopyWithImpl<$Res>
    extends _$TransferStatusCopyWithImpl<$Res, _$TransferStatus_Transferring>
    implements _$$TransferStatus_TransferringCopyWith<$Res> {
  __$$TransferStatus_TransferringCopyWithImpl(
      _$TransferStatus_Transferring _value,
      $Res Function(_$TransferStatus_Transferring) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? field0 = null,
  }) {
    return _then(_$TransferStatus_Transferring(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as DownloadProgress,
    ));
  }
}

/// @nodoc

class _$TransferStatus_Transferring implements TransferStatus_Transferring {
  const _$TransferStatus_Transferring(this.field0);

  @override
  final DownloadProgress field0;

  @override
  String toString() {
    return 'TransferStatus.transferring(field0: $field0)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransferStatus_Transferring &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TransferStatus_TransferringCopyWith<_$TransferStatus_Transferring>
      get copyWith => __$$TransferStatus_TransferringCopyWithImpl<
          _$TransferStatus_Transferring>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() starting,
    required TResult Function(DownloadProgress field0) transferring,
    required TResult Function() completed,
    required TResult Function() failed,
  }) {
    return transferring(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? starting,
    TResult? Function(DownloadProgress field0)? transferring,
    TResult? Function()? completed,
    TResult? Function()? failed,
  }) {
    return transferring?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? starting,
    TResult Function(DownloadProgress field0)? transferring,
    TResult Function()? completed,
    TResult Function()? failed,
    required TResult orElse(),
  }) {
    if (transferring != null) {
      return transferring(field0);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TransferStatus_Starting value) starting,
    required TResult Function(TransferStatus_Transferring value) transferring,
    required TResult Function(TransferStatus_Completed value) completed,
    required TResult Function(TransferStatus_Failed value) failed,
  }) {
    return transferring(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TransferStatus_Starting value)? starting,
    TResult? Function(TransferStatus_Transferring value)? transferring,
    TResult? Function(TransferStatus_Completed value)? completed,
    TResult? Function(TransferStatus_Failed value)? failed,
  }) {
    return transferring?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TransferStatus_Starting value)? starting,
    TResult Function(TransferStatus_Transferring value)? transferring,
    TResult Function(TransferStatus_Completed value)? completed,
    TResult Function(TransferStatus_Failed value)? failed,
    required TResult orElse(),
  }) {
    if (transferring != null) {
      return transferring(this);
    }
    return orElse();
  }
}

abstract class TransferStatus_Transferring implements TransferStatus {
  const factory TransferStatus_Transferring(final DownloadProgress field0) =
      _$TransferStatus_Transferring;

  DownloadProgress get field0;
  @JsonKey(ignore: true)
  _$$TransferStatus_TransferringCopyWith<_$TransferStatus_Transferring>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TransferStatus_CompletedCopyWith<$Res> {
  factory _$$TransferStatus_CompletedCopyWith(_$TransferStatus_Completed value,
          $Res Function(_$TransferStatus_Completed) then) =
      __$$TransferStatus_CompletedCopyWithImpl<$Res>;
}

/// @nodoc
class __$$TransferStatus_CompletedCopyWithImpl<$Res>
    extends _$TransferStatusCopyWithImpl<$Res, _$TransferStatus_Completed>
    implements _$$TransferStatus_CompletedCopyWith<$Res> {
  __$$TransferStatus_CompletedCopyWithImpl(_$TransferStatus_Completed _value,
      $Res Function(_$TransferStatus_Completed) _then)
      : super(_value, _then);
}

/// @nodoc

class _$TransferStatus_Completed implements TransferStatus_Completed {
  const _$TransferStatus_Completed();

  @override
  String toString() {
    return 'TransferStatus.completed()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransferStatus_Completed);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() starting,
    required TResult Function(DownloadProgress field0) transferring,
    required TResult Function() completed,
    required TResult Function() failed,
  }) {
    return completed();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? starting,
    TResult? Function(DownloadProgress field0)? transferring,
    TResult? Function()? completed,
    TResult? Function()? failed,
  }) {
    return completed?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? starting,
    TResult Function(DownloadProgress field0)? transferring,
    TResult Function()? completed,
    TResult Function()? failed,
    required TResult orElse(),
  }) {
    if (completed != null) {
      return completed();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TransferStatus_Starting value) starting,
    required TResult Function(TransferStatus_Transferring value) transferring,
    required TResult Function(TransferStatus_Completed value) completed,
    required TResult Function(TransferStatus_Failed value) failed,
  }) {
    return completed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TransferStatus_Starting value)? starting,
    TResult? Function(TransferStatus_Transferring value)? transferring,
    TResult? Function(TransferStatus_Completed value)? completed,
    TResult? Function(TransferStatus_Failed value)? failed,
  }) {
    return completed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TransferStatus_Starting value)? starting,
    TResult Function(TransferStatus_Transferring value)? transferring,
    TResult Function(TransferStatus_Completed value)? completed,
    TResult Function(TransferStatus_Failed value)? failed,
    required TResult orElse(),
  }) {
    if (completed != null) {
      return completed(this);
    }
    return orElse();
  }
}

abstract class TransferStatus_Completed implements TransferStatus {
  const factory TransferStatus_Completed() = _$TransferStatus_Completed;
}

/// @nodoc
abstract class _$$TransferStatus_FailedCopyWith<$Res> {
  factory _$$TransferStatus_FailedCopyWith(_$TransferStatus_Failed value,
          $Res Function(_$TransferStatus_Failed) then) =
      __$$TransferStatus_FailedCopyWithImpl<$Res>;
}

/// @nodoc
class __$$TransferStatus_FailedCopyWithImpl<$Res>
    extends _$TransferStatusCopyWithImpl<$Res, _$TransferStatus_Failed>
    implements _$$TransferStatus_FailedCopyWith<$Res> {
  __$$TransferStatus_FailedCopyWithImpl(_$TransferStatus_Failed _value,
      $Res Function(_$TransferStatus_Failed) _then)
      : super(_value, _then);
}

/// @nodoc

class _$TransferStatus_Failed implements TransferStatus_Failed {
  const _$TransferStatus_Failed();

  @override
  String toString() {
    return 'TransferStatus.failed()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$TransferStatus_Failed);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() starting,
    required TResult Function(DownloadProgress field0) transferring,
    required TResult Function() completed,
    required TResult Function() failed,
  }) {
    return failed();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? starting,
    TResult? Function(DownloadProgress field0)? transferring,
    TResult? Function()? completed,
    TResult? Function()? failed,
  }) {
    return failed?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? starting,
    TResult Function(DownloadProgress field0)? transferring,
    TResult Function()? completed,
    TResult Function()? failed,
    required TResult orElse(),
  }) {
    if (failed != null) {
      return failed();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TransferStatus_Starting value) starting,
    required TResult Function(TransferStatus_Transferring value) transferring,
    required TResult Function(TransferStatus_Completed value) completed,
    required TResult Function(TransferStatus_Failed value) failed,
  }) {
    return failed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TransferStatus_Starting value)? starting,
    TResult? Function(TransferStatus_Transferring value)? transferring,
    TResult? Function(TransferStatus_Completed value)? completed,
    TResult? Function(TransferStatus_Failed value)? failed,
  }) {
    return failed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TransferStatus_Starting value)? starting,
    TResult Function(TransferStatus_Transferring value)? transferring,
    TResult Function(TransferStatus_Completed value)? completed,
    TResult Function(TransferStatus_Failed value)? failed,
    required TResult orElse(),
  }) {
    if (failed != null) {
      return failed(this);
    }
    return orElse();
  }
}

abstract class TransferStatus_Failed implements TransferStatus {
  const factory TransferStatus_Failed() = _$TransferStatus_Failed;
}
