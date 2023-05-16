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
    required TResult Function(StationConfig field0) stationRefreshed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? preAccount,
    TResult? Function(List<NearbyStation> field0)? nearbyStations,
    TResult? Function(StationConfig field0)? stationRefreshed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? preAccount,
    TResult Function(List<NearbyStation> field0)? nearbyStations,
    TResult Function(StationConfig field0)? stationRefreshed,
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
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DomainMessage_PreAccount value)? preAccount,
    TResult? Function(DomainMessage_NearbyStations value)? nearbyStations,
    TResult? Function(DomainMessage_StationRefreshed value)? stationRefreshed,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DomainMessage_PreAccount value)? preAccount,
    TResult Function(DomainMessage_NearbyStations value)? nearbyStations,
    TResult Function(DomainMessage_StationRefreshed value)? stationRefreshed,
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
    required TResult Function(StationConfig field0) stationRefreshed,
  }) {
    return preAccount();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? preAccount,
    TResult? Function(List<NearbyStation> field0)? nearbyStations,
    TResult? Function(StationConfig field0)? stationRefreshed,
  }) {
    return preAccount?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? preAccount,
    TResult Function(List<NearbyStation> field0)? nearbyStations,
    TResult Function(StationConfig field0)? stationRefreshed,
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
  }) {
    return preAccount(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DomainMessage_PreAccount value)? preAccount,
    TResult? Function(DomainMessage_NearbyStations value)? nearbyStations,
    TResult? Function(DomainMessage_StationRefreshed value)? stationRefreshed,
  }) {
    return preAccount?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DomainMessage_PreAccount value)? preAccount,
    TResult Function(DomainMessage_NearbyStations value)? nearbyStations,
    TResult Function(DomainMessage_StationRefreshed value)? stationRefreshed,
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
    required TResult Function(StationConfig field0) stationRefreshed,
  }) {
    return nearbyStations(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? preAccount,
    TResult? Function(List<NearbyStation> field0)? nearbyStations,
    TResult? Function(StationConfig field0)? stationRefreshed,
  }) {
    return nearbyStations?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? preAccount,
    TResult Function(List<NearbyStation> field0)? nearbyStations,
    TResult Function(StationConfig field0)? stationRefreshed,
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
  }) {
    return nearbyStations(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DomainMessage_PreAccount value)? preAccount,
    TResult? Function(DomainMessage_NearbyStations value)? nearbyStations,
    TResult? Function(DomainMessage_StationRefreshed value)? stationRefreshed,
  }) {
    return nearbyStations?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DomainMessage_PreAccount value)? preAccount,
    TResult Function(DomainMessage_NearbyStations value)? nearbyStations,
    TResult Function(DomainMessage_StationRefreshed value)? stationRefreshed,
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
  $Res call({StationConfig field0});
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
  }) {
    return _then(_$DomainMessage_StationRefreshed(
      null == field0
          ? _value.field0
          : field0 // ignore: cast_nullable_to_non_nullable
              as StationConfig,
    ));
  }
}

/// @nodoc

class _$DomainMessage_StationRefreshed
    implements DomainMessage_StationRefreshed {
  const _$DomainMessage_StationRefreshed(this.field0);

  @override
  final StationConfig field0;

  @override
  String toString() {
    return 'DomainMessage.stationRefreshed(field0: $field0)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DomainMessage_StationRefreshed &&
            (identical(other.field0, field0) || other.field0 == field0));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field0);

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
    required TResult Function(StationConfig field0) stationRefreshed,
  }) {
    return stationRefreshed(field0);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? preAccount,
    TResult? Function(List<NearbyStation> field0)? nearbyStations,
    TResult? Function(StationConfig field0)? stationRefreshed,
  }) {
    return stationRefreshed?.call(field0);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? preAccount,
    TResult Function(List<NearbyStation> field0)? nearbyStations,
    TResult Function(StationConfig field0)? stationRefreshed,
    required TResult orElse(),
  }) {
    if (stationRefreshed != null) {
      return stationRefreshed(field0);
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
  }) {
    return stationRefreshed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(DomainMessage_PreAccount value)? preAccount,
    TResult? Function(DomainMessage_NearbyStations value)? nearbyStations,
    TResult? Function(DomainMessage_StationRefreshed value)? stationRefreshed,
  }) {
    return stationRefreshed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(DomainMessage_PreAccount value)? preAccount,
    TResult Function(DomainMessage_NearbyStations value)? nearbyStations,
    TResult Function(DomainMessage_StationRefreshed value)? stationRefreshed,
    required TResult orElse(),
  }) {
    if (stationRefreshed != null) {
      return stationRefreshed(this);
    }
    return orElse();
  }
}

abstract class DomainMessage_StationRefreshed implements DomainMessage {
  const factory DomainMessage_StationRefreshed(final StationConfig field0) =
      _$DomainMessage_StationRefreshed;

  StationConfig get field0;
  @JsonKey(ignore: true)
  _$$DomainMessage_StationRefreshedCopyWith<_$DomainMessage_StationRefreshed>
      get copyWith => throw _privateConstructorUsedError;
}
