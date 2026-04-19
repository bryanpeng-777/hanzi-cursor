import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'hanzi_model.freezed.dart';
part 'hanzi_model.g.dart';

@freezed
class HanziCharacter with _$HanziCharacter {
  const factory HanziCharacter({
    required String character,
    required String pinyin,
    required String meaning,
    /// 配图语义说明（供 CsImage description），禁止写入 Unicode 表情符号。
    required String iconHint,
    required String strokeCount,
    required List<String> exampleWords,
    required int level,
  }) = _HanziCharacter;
}

@freezed
class LearningProgress with _$LearningProgress {
  const factory LearningProgress({
    required String character,
    @Default(false) bool isLearned,
    @Default(false) bool isFavorite,
    @Default(0) int stars,
    DateTime? lastStudied,
  }) = _LearningProgress;

  factory LearningProgress.fromJson(Map<String, dynamic> json) =>
      _$LearningProgressFromJson(json);
}
