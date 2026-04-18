import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cs_framework/cs_framework.dart';
import '../models/hanzi_model.dart';
import '../models/learning_state.dart';

part 'learning_provider.g.dart';

@Riverpod(keepAlive: true)
class LearningNotifier extends _$LearningNotifier {
  @override
  LearningState build() {
    _loadProgress();
    return const LearningState();
  }

  // ── 加载 ──────────────────────────────────────────────────────────────────

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final cloudRow = await DataManager.selectOne('hanzi_cursor_user_progress');
      if (cloudRow != null) {
        state = _applyCloudRow(cloudRow, state).copyWith(isLoaded: true);
        return;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[LearningNotifier] 云端读取失败，回退到本地: $e');
    }

    state = _applyPrefs(prefs, state).copyWith(isLoaded: true);

    if (state.progressMap.isNotEmpty || state.totalStars > 0) {
      _saveToCloud().catchError((e) {
        if (kDebugMode) debugPrint('[LearningNotifier] 本地数据迁移云端失败: $e');
      });
    }
  }

  LearningState _applyPrefs(SharedPreferences prefs, LearningState s) {
    final data = prefs.getString('learning_progress');
    Map<String, LearningProgress> progressMap = {};
    if (data != null) {
      final decoded = json.decode(data) as Map<String, dynamic>;
      progressMap = decoded.map(
        (k, v) => MapEntry(k, LearningProgress.fromJson(v as Map<String, dynamic>)),
      );
    }
    final mistakesStr = prefs.getString('pinyin_mistakes') ?? '';
    final hanziMistakesStr = prefs.getString('hanzi_quiz_mistakes') ?? '';
    final passedStr = prefs.getString('hanzi_quiz_passed_levels') ?? '';
    final bestScoresStr = prefs.getString('hanzi_quiz_best_scores') ?? '{}';
    final bestScoresJson = json.decode(bestScoresStr) as Map<String, dynamic>;

    return s.copyWith(
      progressMap: progressMap,
      totalStars: prefs.getInt('total_stars') ?? 0,
      currentStreak: prefs.getInt('current_streak') ?? 0,
      pinyinMistakes: mistakesStr.isEmpty ? {} : Set<String>.from(mistakesStr.split(',')),
      hanziQuizMistakes:
          hanziMistakesStr.isEmpty ? {} : Set<String>.from(hanziMistakesStr.split(',')),
      hanziQuizPassedLevels:
          passedStr.isEmpty ? {} : Set<int>.from(passedStr.split(',').map(int.parse)),
      hanziQuizBestScores:
          bestScoresJson.map((k, v) => MapEntry(int.parse(k), v as int)),
    );
  }

  LearningState _applyCloudRow(Map<String, dynamic> row, LearningState s) {
    final lpStr = row['learning_progress'];
    Map<String, LearningProgress> progressMap = {};
    if (lpStr != null && lpStr is String && lpStr.isNotEmpty) {
      final decoded = json.decode(lpStr) as Map<String, dynamic>;
      progressMap = decoded.map(
        (k, v) => MapEntry(k, LearningProgress.fromJson(v as Map<String, dynamic>)),
      );
    }
    final mistakesStr = row['pinyin_mistakes'] as String? ?? '';
    final hanziMistakesStr = row['hanzi_quiz_mistakes'] as String? ?? '';
    final passedStr = row['hanzi_quiz_passed_levels'] as String? ?? '';
    final bestScoresRaw = row['hanzi_quiz_best_scores'];
    Map<int, int> bestScores = {};
    if (bestScoresRaw != null) {
      final Map<String, dynamic> bs = bestScoresRaw is String
          ? json.decode(bestScoresRaw) as Map<String, dynamic>
          : Map<String, dynamic>.from(bestScoresRaw as Map);
      bestScores = bs.map((k, v) => MapEntry(int.parse(k), (v as num).toInt()));
    }
    return s.copyWith(
      progressMap: progressMap,
      totalStars: (row['total_stars'] as num?)?.toInt() ?? 0,
      currentStreak: (row['current_streak'] as num?)?.toInt() ?? 0,
      pinyinMistakes:
          mistakesStr.isEmpty ? {} : Set<String>.from(mistakesStr.split(',')),
      hanziQuizMistakes:
          hanziMistakesStr.isEmpty ? {} : Set<String>.from(hanziMistakesStr.split(',')),
      hanziQuizPassedLevels:
          passedStr.isEmpty ? {} : Set<int>.from(passedStr.split(',').map(int.parse)),
      hanziQuizBestScores: bestScores,
    );
  }

  // ── 持久化 ────────────────────────────────────────────────────────────────

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(
      state.progressMap.map((k, v) => MapEntry(k, v.toJson())),
    );
    await prefs.setString('learning_progress', encoded);
    await prefs.setInt('total_stars', state.totalStars);
    await prefs.setInt('current_streak', state.currentStreak);
    await prefs.setString('pinyin_mistakes', state.pinyinMistakes.join(','));
    await prefs.setString('hanzi_quiz_mistakes', state.hanziQuizMistakes.join(','));
    await prefs.setString(
        'hanzi_quiz_passed_levels',
        state.hanziQuizPassedLevels.map((e) => e.toString()).join(','));
    await prefs.setString(
        'hanzi_quiz_best_scores',
        json.encode(state.hanziQuizBestScores.map((k, v) => MapEntry(k.toString(), v))));

    _saveToCloud().catchError((e) {
      if (kDebugMode) debugPrint('[LearningNotifier] 云端保存失败: $e');
    });
  }

  Future<void> _saveToCloud() async {
    final userId = CsClient.supabase.auth.currentUser?.id;
    if (userId == null) return;
    await DataManager.upsert(
      'hanzi_cursor_user_progress',
      {
        'user_id': userId,
        'learning_progress':
            json.encode(state.progressMap.map((k, v) => MapEntry(k, v.toJson()))),
        'total_stars': state.totalStars,
        'current_streak': state.currentStreak,
        'pinyin_mistakes': state.pinyinMistakes.join(','),
        'hanzi_quiz_mistakes': state.hanziQuizMistakes.join(','),
        'hanzi_quiz_passed_levels':
            state.hanziQuizPassedLevels.map((e) => e.toString()).join(','),
        'hanzi_quiz_best_scores':
            json.encode(state.hanziQuizBestScores.map((k, v) => MapEntry(k.toString(), v))),
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id',
    );
  }

  // ── 操作方法 ───────────────────────────────────────────────────────────────

  Future<void> addPinyinMistake(String initial) async {
    if (!state.pinyinMistakes.contains(initial)) {
      state = state.copyWith(
        pinyinMistakes: {...state.pinyinMistakes, initial},
      );
      await _saveProgress();
    }
  }

  Future<void> removePinyinMistake(String initial) async {
    if (state.pinyinMistakes.contains(initial)) {
      state = state.copyWith(
        pinyinMistakes: state.pinyinMistakes.difference({initial}),
      );
      await _saveProgress();
    }
  }

  Future<void> clearPinyinMistakes() async {
    if (state.pinyinMistakes.isNotEmpty) {
      state = state.copyWith(pinyinMistakes: {});
      await _saveProgress();
    }
  }

  Future<void> addHanziMistake(String character) async {
    if (!state.hanziQuizMistakes.contains(character)) {
      state = state.copyWith(
        hanziQuizMistakes: {...state.hanziQuizMistakes, character},
      );
      await _saveProgress();
    }
  }

  Future<void> removeHanziMistake(String character) async {
    if (state.hanziQuizMistakes.contains(character)) {
      state = state.copyWith(
        hanziQuizMistakes: state.hanziQuizMistakes.difference({character}),
      );
      await _saveProgress();
    }
  }

  Future<void> markHanziLevelPassed(int level, int scorePercent) async {
    final newBestScores = Map<int, int>.from(state.hanziQuizBestScores);
    if (scorePercent > (newBestScores[level] ?? 0)) {
      newBestScores[level] = scorePercent;
    }
    state = state.copyWith(
      hanziQuizPassedLevels: {...state.hanziQuizPassedLevels, level},
      hanziQuizBestScores: newBestScores,
    );
    await _saveProgress();
  }

  Future<void> markAsLearned(String character, {int starsEarned = 1}) async {
    final progress = state.getProgress(character);
    if (!progress.isLearned) {
      state = state.copyWith(
        progressMap: {
          ...state.progressMap,
          character: progress.copyWith(
            isLearned: true,
            stars: starsEarned,
            lastStudied: DateTime.now(),
          ),
        },
        totalStars: state.totalStars + starsEarned,
      );
      await _saveProgress();
    }
  }

  Future<void> addStars(String character, int count) async {
    final progress = state.getProgress(character);
    state = state.copyWith(
      progressMap: {
        ...state.progressMap,
        character: progress.copyWith(
          stars: progress.stars + count,
          lastStudied: DateTime.now(),
        ),
      },
      totalStars: state.totalStars + count,
    );
    await _saveProgress();
  }

  Future<void> toggleFavorite(String character) async {
    final progress = state.getProgress(character);
    state = state.copyWith(
      progressMap: {
        ...state.progressMap,
        character: progress.copyWith(isFavorite: !progress.isFavorite),
      },
    );
    await _saveProgress();
  }
}
