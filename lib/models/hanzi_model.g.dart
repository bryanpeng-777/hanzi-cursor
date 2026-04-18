// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hanzi_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LearningProgressImpl _$$LearningProgressImplFromJson(
        Map<String, dynamic> json) =>
    _$LearningProgressImpl(
      character: json['character'] as String,
      isLearned: json['isLearned'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
      stars: (json['stars'] as num?)?.toInt() ?? 0,
      lastStudied: json['lastStudied'] == null
          ? null
          : DateTime.parse(json['lastStudied'] as String),
    );

Map<String, dynamic> _$$LearningProgressImplToJson(
        _$LearningProgressImpl instance) =>
    <String, dynamic>{
      'character': instance.character,
      'isLearned': instance.isLearned,
      'isFavorite': instance.isFavorite,
      'stars': instance.stars,
      'lastStudied': instance.lastStudied?.toIso8601String(),
    };
