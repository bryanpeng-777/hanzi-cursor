import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hanzi_model.dart';
import '../data/hanzi_data.dart';

class LearningProvider extends ChangeNotifier {
  Map<String, LearningProgress> _progressMap = {};
  int _totalStars = 0;
  int _currentStreak = 0;
  bool _isLoaded = false;
  Set<String> _pinyinMistakes = {};
  Set<String> _hanziQuizMistakes = {};
  Set<int> _hanziQuizPassedLevels = {};
  Map<int, int> _hanziQuizBestScores = {};

  Map<String, LearningProgress> get progressMap => _progressMap;
  int get totalStars => _totalStars;
  int get currentStreak => _currentStreak;
  bool get isLoaded => _isLoaded;
  Set<String> get pinyinMistakes => Set.unmodifiable(_pinyinMistakes);
  Set<String> get hanziQuizMistakes => Set.unmodifiable(_hanziQuizMistakes);

  bool isHanziLevelUnlocked(int level) =>
      level == 1 || _hanziQuizPassedLevels.contains(level - 1);

  bool isHanziLevelPassed(int level) =>
      _hanziQuizPassedLevels.contains(level);

  int getHanziQuizBestScore(int level) => _hanziQuizBestScores[level] ?? 0;

  List<HanziCharacter> get learnedCharacters =>
      allHanzi.where((h) => _progressMap[h.character]?.isLearned == true).toList();

  List<HanziCharacter> get favoriteCharacters =>
      allHanzi.where((h) => _progressMap[h.character]?.isFavorite == true).toList();

  int get learnedCount => learnedCharacters.length;
  int get totalCount => allHanzi.length;

  double get overallProgress => totalCount > 0 ? learnedCount / totalCount : 0.0;

  LearningProgress getProgress(String character) {
    return _progressMap[character] ?? LearningProgress(character: character);
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('learning_progress');
    if (data != null) {
      final decoded = json.decode(data) as Map<String, dynamic>;
      _progressMap = decoded.map(
        (k, v) => MapEntry(k, LearningProgress.fromJson(v as Map<String, dynamic>)),
      );
    }
    _totalStars = prefs.getInt('total_stars') ?? 0;
    _currentStreak = prefs.getInt('current_streak') ?? 0;
    final mistakesStr = prefs.getString('pinyin_mistakes') ?? '';
    _pinyinMistakes = mistakesStr.isEmpty
        ? {}
        : Set<String>.from(mistakesStr.split(','));
    final hanziMistakesStr = prefs.getString('hanzi_quiz_mistakes') ?? '';
    _hanziQuizMistakes = hanziMistakesStr.isEmpty
        ? {}
        : Set<String>.from(hanziMistakesStr.split(','));
    final passedStr = prefs.getString('hanzi_quiz_passed_levels') ?? '';
    _hanziQuizPassedLevels = passedStr.isEmpty
        ? {}
        : Set<int>.from(passedStr.split(',').map(int.parse));
    final bestScoresStr = prefs.getString('hanzi_quiz_best_scores') ?? '{}';
    final bestScoresJson = json.decode(bestScoresStr) as Map<String, dynamic>;
    _hanziQuizBestScores = bestScoresJson
        .map((k, v) => MapEntry(int.parse(k), v as int));
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(
      _progressMap.map((k, v) => MapEntry(k, v.toJson())),
    );
    await prefs.setString('learning_progress', encoded);
    await prefs.setInt('total_stars', _totalStars);
    await prefs.setInt('current_streak', _currentStreak);
    await prefs.setString('pinyin_mistakes', _pinyinMistakes.join(','));
    await prefs.setString('hanzi_quiz_mistakes', _hanziQuizMistakes.join(','));
    await prefs.setString(
        'hanzi_quiz_passed_levels',
        _hanziQuizPassedLevels.map((e) => e.toString()).join(','));
    await prefs.setString(
        'hanzi_quiz_best_scores',
        json.encode(_hanziQuizBestScores
            .map((k, v) => MapEntry(k.toString(), v))));
  }

  Future<void> addPinyinMistake(String initial) async {
    if (_pinyinMistakes.add(initial)) {
      notifyListeners();
      await _saveProgress();
    }
  }

  Future<void> removePinyinMistake(String initial) async {
    if (_pinyinMistakes.remove(initial)) {
      notifyListeners();
      await _saveProgress();
    }
  }

  Future<void> clearPinyinMistakes() async {
    if (_pinyinMistakes.isNotEmpty) {
      _pinyinMistakes.clear();
      notifyListeners();
      await _saveProgress();
    }
  }

  Future<void> addHanziMistake(String character) async {
    if (_hanziQuizMistakes.add(character)) {
      notifyListeners();
      await _saveProgress();
    }
  }

  Future<void> removeHanziMistake(String character) async {
    if (_hanziQuizMistakes.remove(character)) {
      notifyListeners();
      await _saveProgress();
    }
  }

  Future<void> markHanziLevelPassed(int level, int scorePercent) async {
    _hanziQuizPassedLevels.add(level);
    if (scorePercent > (_hanziQuizBestScores[level] ?? 0)) {
      _hanziQuizBestScores[level] = scorePercent;
    }
    notifyListeners();
    await _saveProgress();
  }

  Future<void> markAsLearned(String character, {int starsEarned = 1}) async {
    final progress = _progressMap[character] ?? LearningProgress(character: character);
    if (!progress.isLearned) {
      progress.isLearned = true;
      progress.stars = starsEarned;
      progress.lastStudied = DateTime.now();
      _progressMap[character] = progress;
      _totalStars += starsEarned;
      notifyListeners();
      await _saveProgress();
    }
  }

  Future<void> addStars(String character, int count) async {
    final progress = _progressMap[character] ?? LearningProgress(character: character);
    progress.stars += count;
    progress.lastStudied = DateTime.now();
    _progressMap[character] = progress;
    _totalStars += count;
    notifyListeners();
    await _saveProgress();
  }

  Future<void> toggleFavorite(String character) async {
    final progress = _progressMap[character] ?? LearningProgress(character: character);
    progress.isFavorite = !progress.isFavorite;
    _progressMap[character] = progress;
    notifyListeners();
    await _saveProgress();
  }

  bool isFavorite(String character) => _progressMap[character]?.isFavorite ?? false;
  bool isLearned(String character) => _progressMap[character]?.isLearned ?? false;

  int getStars(String character) => _progressMap[character]?.stars ?? 0;
}
