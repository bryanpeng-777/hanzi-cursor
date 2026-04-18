// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hanzi_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$HanziCharacter {
  String get character => throw _privateConstructorUsedError;
  String get pinyin => throw _privateConstructorUsedError;
  String get meaning => throw _privateConstructorUsedError;
  String get emoji => throw _privateConstructorUsedError;
  String get strokeCount => throw _privateConstructorUsedError;
  List<String> get exampleWords => throw _privateConstructorUsedError;
  int get level => throw _privateConstructorUsedError;

  /// Create a copy of HanziCharacter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HanziCharacterCopyWith<HanziCharacter> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HanziCharacterCopyWith<$Res> {
  factory $HanziCharacterCopyWith(
          HanziCharacter value, $Res Function(HanziCharacter) then) =
      _$HanziCharacterCopyWithImpl<$Res, HanziCharacter>;
  @useResult
  $Res call(
      {String character,
      String pinyin,
      String meaning,
      String emoji,
      String strokeCount,
      List<String> exampleWords,
      int level});
}

/// @nodoc
class _$HanziCharacterCopyWithImpl<$Res, $Val extends HanziCharacter>
    implements $HanziCharacterCopyWith<$Res> {
  _$HanziCharacterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HanziCharacter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? character = null,
    Object? pinyin = null,
    Object? meaning = null,
    Object? emoji = null,
    Object? strokeCount = null,
    Object? exampleWords = null,
    Object? level = null,
  }) {
    return _then(_value.copyWith(
      character: null == character
          ? _value.character
          : character // ignore: cast_nullable_to_non_nullable
              as String,
      pinyin: null == pinyin
          ? _value.pinyin
          : pinyin // ignore: cast_nullable_to_non_nullable
              as String,
      meaning: null == meaning
          ? _value.meaning
          : meaning // ignore: cast_nullable_to_non_nullable
              as String,
      emoji: null == emoji
          ? _value.emoji
          : emoji // ignore: cast_nullable_to_non_nullable
              as String,
      strokeCount: null == strokeCount
          ? _value.strokeCount
          : strokeCount // ignore: cast_nullable_to_non_nullable
              as String,
      exampleWords: null == exampleWords
          ? _value.exampleWords
          : exampleWords // ignore: cast_nullable_to_non_nullable
              as List<String>,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HanziCharacterImplCopyWith<$Res>
    implements $HanziCharacterCopyWith<$Res> {
  factory _$$HanziCharacterImplCopyWith(_$HanziCharacterImpl value,
          $Res Function(_$HanziCharacterImpl) then) =
      __$$HanziCharacterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String character,
      String pinyin,
      String meaning,
      String emoji,
      String strokeCount,
      List<String> exampleWords,
      int level});
}

/// @nodoc
class __$$HanziCharacterImplCopyWithImpl<$Res>
    extends _$HanziCharacterCopyWithImpl<$Res, _$HanziCharacterImpl>
    implements _$$HanziCharacterImplCopyWith<$Res> {
  __$$HanziCharacterImplCopyWithImpl(
      _$HanziCharacterImpl _value, $Res Function(_$HanziCharacterImpl) _then)
      : super(_value, _then);

  /// Create a copy of HanziCharacter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? character = null,
    Object? pinyin = null,
    Object? meaning = null,
    Object? emoji = null,
    Object? strokeCount = null,
    Object? exampleWords = null,
    Object? level = null,
  }) {
    return _then(_$HanziCharacterImpl(
      character: null == character
          ? _value.character
          : character // ignore: cast_nullable_to_non_nullable
              as String,
      pinyin: null == pinyin
          ? _value.pinyin
          : pinyin // ignore: cast_nullable_to_non_nullable
              as String,
      meaning: null == meaning
          ? _value.meaning
          : meaning // ignore: cast_nullable_to_non_nullable
              as String,
      emoji: null == emoji
          ? _value.emoji
          : emoji // ignore: cast_nullable_to_non_nullable
              as String,
      strokeCount: null == strokeCount
          ? _value.strokeCount
          : strokeCount // ignore: cast_nullable_to_non_nullable
              as String,
      exampleWords: null == exampleWords
          ? _value._exampleWords
          : exampleWords // ignore: cast_nullable_to_non_nullable
              as List<String>,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$HanziCharacterImpl implements _HanziCharacter {
  const _$HanziCharacterImpl(
      {required this.character,
      required this.pinyin,
      required this.meaning,
      required this.emoji,
      required this.strokeCount,
      required final List<String> exampleWords,
      required this.level})
      : _exampleWords = exampleWords;

  @override
  final String character;
  @override
  final String pinyin;
  @override
  final String meaning;
  @override
  final String emoji;
  @override
  final String strokeCount;
  final List<String> _exampleWords;
  @override
  List<String> get exampleWords {
    if (_exampleWords is EqualUnmodifiableListView) return _exampleWords;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_exampleWords);
  }

  @override
  final int level;

  @override
  String toString() {
    return 'HanziCharacter(character: $character, pinyin: $pinyin, meaning: $meaning, emoji: $emoji, strokeCount: $strokeCount, exampleWords: $exampleWords, level: $level)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HanziCharacterImpl &&
            (identical(other.character, character) ||
                other.character == character) &&
            (identical(other.pinyin, pinyin) || other.pinyin == pinyin) &&
            (identical(other.meaning, meaning) || other.meaning == meaning) &&
            (identical(other.emoji, emoji) || other.emoji == emoji) &&
            (identical(other.strokeCount, strokeCount) ||
                other.strokeCount == strokeCount) &&
            const DeepCollectionEquality()
                .equals(other._exampleWords, _exampleWords) &&
            (identical(other.level, level) || other.level == level));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      character,
      pinyin,
      meaning,
      emoji,
      strokeCount,
      const DeepCollectionEquality().hash(_exampleWords),
      level);

  /// Create a copy of HanziCharacter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HanziCharacterImplCopyWith<_$HanziCharacterImpl> get copyWith =>
      __$$HanziCharacterImplCopyWithImpl<_$HanziCharacterImpl>(
          this, _$identity);
}

abstract class _HanziCharacter implements HanziCharacter {
  const factory _HanziCharacter(
      {required final String character,
      required final String pinyin,
      required final String meaning,
      required final String emoji,
      required final String strokeCount,
      required final List<String> exampleWords,
      required final int level}) = _$HanziCharacterImpl;

  @override
  String get character;
  @override
  String get pinyin;
  @override
  String get meaning;
  @override
  String get emoji;
  @override
  String get strokeCount;
  @override
  List<String> get exampleWords;
  @override
  int get level;

  /// Create a copy of HanziCharacter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HanziCharacterImplCopyWith<_$HanziCharacterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LearningProgress _$LearningProgressFromJson(Map<String, dynamic> json) {
  return _LearningProgress.fromJson(json);
}

/// @nodoc
mixin _$LearningProgress {
  String get character => throw _privateConstructorUsedError;
  bool get isLearned => throw _privateConstructorUsedError;
  bool get isFavorite => throw _privateConstructorUsedError;
  int get stars => throw _privateConstructorUsedError;
  DateTime? get lastStudied => throw _privateConstructorUsedError;

  /// Serializes this LearningProgress to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LearningProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LearningProgressCopyWith<LearningProgress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LearningProgressCopyWith<$Res> {
  factory $LearningProgressCopyWith(
          LearningProgress value, $Res Function(LearningProgress) then) =
      _$LearningProgressCopyWithImpl<$Res, LearningProgress>;
  @useResult
  $Res call(
      {String character,
      bool isLearned,
      bool isFavorite,
      int stars,
      DateTime? lastStudied});
}

/// @nodoc
class _$LearningProgressCopyWithImpl<$Res, $Val extends LearningProgress>
    implements $LearningProgressCopyWith<$Res> {
  _$LearningProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LearningProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? character = null,
    Object? isLearned = null,
    Object? isFavorite = null,
    Object? stars = null,
    Object? lastStudied = freezed,
  }) {
    return _then(_value.copyWith(
      character: null == character
          ? _value.character
          : character // ignore: cast_nullable_to_non_nullable
              as String,
      isLearned: null == isLearned
          ? _value.isLearned
          : isLearned // ignore: cast_nullable_to_non_nullable
              as bool,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      stars: null == stars
          ? _value.stars
          : stars // ignore: cast_nullable_to_non_nullable
              as int,
      lastStudied: freezed == lastStudied
          ? _value.lastStudied
          : lastStudied // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LearningProgressImplCopyWith<$Res>
    implements $LearningProgressCopyWith<$Res> {
  factory _$$LearningProgressImplCopyWith(_$LearningProgressImpl value,
          $Res Function(_$LearningProgressImpl) then) =
      __$$LearningProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String character,
      bool isLearned,
      bool isFavorite,
      int stars,
      DateTime? lastStudied});
}

/// @nodoc
class __$$LearningProgressImplCopyWithImpl<$Res>
    extends _$LearningProgressCopyWithImpl<$Res, _$LearningProgressImpl>
    implements _$$LearningProgressImplCopyWith<$Res> {
  __$$LearningProgressImplCopyWithImpl(_$LearningProgressImpl _value,
      $Res Function(_$LearningProgressImpl) _then)
      : super(_value, _then);

  /// Create a copy of LearningProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? character = null,
    Object? isLearned = null,
    Object? isFavorite = null,
    Object? stars = null,
    Object? lastStudied = freezed,
  }) {
    return _then(_$LearningProgressImpl(
      character: null == character
          ? _value.character
          : character // ignore: cast_nullable_to_non_nullable
              as String,
      isLearned: null == isLearned
          ? _value.isLearned
          : isLearned // ignore: cast_nullable_to_non_nullable
              as bool,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      stars: null == stars
          ? _value.stars
          : stars // ignore: cast_nullable_to_non_nullable
              as int,
      lastStudied: freezed == lastStudied
          ? _value.lastStudied
          : lastStudied // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LearningProgressImpl implements _LearningProgress {
  const _$LearningProgressImpl(
      {required this.character,
      this.isLearned = false,
      this.isFavorite = false,
      this.stars = 0,
      this.lastStudied});

  factory _$LearningProgressImpl.fromJson(Map<String, dynamic> json) =>
      _$$LearningProgressImplFromJson(json);

  @override
  final String character;
  @override
  @JsonKey()
  final bool isLearned;
  @override
  @JsonKey()
  final bool isFavorite;
  @override
  @JsonKey()
  final int stars;
  @override
  final DateTime? lastStudied;

  @override
  String toString() {
    return 'LearningProgress(character: $character, isLearned: $isLearned, isFavorite: $isFavorite, stars: $stars, lastStudied: $lastStudied)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LearningProgressImpl &&
            (identical(other.character, character) ||
                other.character == character) &&
            (identical(other.isLearned, isLearned) ||
                other.isLearned == isLearned) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite) &&
            (identical(other.stars, stars) || other.stars == stars) &&
            (identical(other.lastStudied, lastStudied) ||
                other.lastStudied == lastStudied));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, character, isLearned, isFavorite, stars, lastStudied);

  /// Create a copy of LearningProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LearningProgressImplCopyWith<_$LearningProgressImpl> get copyWith =>
      __$$LearningProgressImplCopyWithImpl<_$LearningProgressImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LearningProgressImplToJson(
      this,
    );
  }
}

abstract class _LearningProgress implements LearningProgress {
  const factory _LearningProgress(
      {required final String character,
      final bool isLearned,
      final bool isFavorite,
      final int stars,
      final DateTime? lastStudied}) = _$LearningProgressImpl;

  factory _LearningProgress.fromJson(Map<String, dynamic> json) =
      _$LearningProgressImpl.fromJson;

  @override
  String get character;
  @override
  bool get isLearned;
  @override
  bool get isFavorite;
  @override
  int get stars;
  @override
  DateTime? get lastStudied;

  /// Create a copy of LearningProgress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LearningProgressImplCopyWith<_$LearningProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
