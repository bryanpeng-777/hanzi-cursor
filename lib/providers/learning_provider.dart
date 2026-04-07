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

  Map<String, LearningProgress> get progressMap => _progressMap;
  int get totalStars => _totalStars;
  int get currentStreak => _currentStreak;
  bool get isLoaded => _isLoaded;

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
