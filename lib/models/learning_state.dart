import 'package:freezed_annotation/freezed_annotation.dart';
import 'hanzi_model.dart';
import '../data/hanzi_data.dart';

part 'learning_state.freezed.dart';

@freezed
class LearningState with _$LearningState {
  const LearningState._();

  const factory LearningState({
    @Default({}) Map<String, LearningProgress> progressMap,
    @Default(0) int totalStars,
    @Default(0) int currentStreak,
    @Default(false) bool isLoaded,
    @Default({}) Set<String> pinyinMistakes,
    @Default({}) Set<String> hanziQuizMistakes,
    @Default({}) Set<int> hanziQuizPassedLevels,
    @Default({}) Map<int, int> hanziQuizBestScores,
  }) = _LearningState;

  bool isHanziLevelUnlocked(int level) =>
      level == 1 || hanziQuizPassedLevels.contains(level - 1);

  bool isHanziLevelPassed(int level) => hanziQuizPassedLevels.contains(level);

  int getHanziQuizBestScore(int level) => hanziQuizBestScores[level] ?? 0;

  List<HanziCharacter> get learnedCharacters =>
      allHanzi.where((h) => progressMap[h.character]?.isLearned == true).toList();

  List<HanziCharacter> get favoriteCharacters =>
      allHanzi.where((h) => progressMap[h.character]?.isFavorite == true).toList();

  int get learnedCount => learnedCharacters.length;
  int get totalCount => allHanzi.length;
  double get overallProgress => totalCount > 0 ? learnedCount / totalCount : 0.0;

  LearningProgress getProgress(String character) =>
      progressMap[character] ?? LearningProgress(character: character);

  bool isFavorite(String character) => progressMap[character]?.isFavorite ?? false;
  bool isLearned(String character) => progressMap[character]?.isLearned ?? false;
  int getStars(String character) => progressMap[character]?.stars ?? 0;
}
