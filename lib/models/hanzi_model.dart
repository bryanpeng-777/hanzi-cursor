class HanziCharacter {
  final String character;
  final String pinyin;
  final String meaning;
  final String emoji;
  final String strokeCount;
  final List<String> exampleWords;
  final int level;

  const HanziCharacter({
    required this.character,
    required this.pinyin,
    required this.meaning,
    required this.emoji,
    required this.strokeCount,
    required this.exampleWords,
    required this.level,
  });
}

class LearningProgress {
  final String character;
  bool isLearned;
  bool isFavorite;
  int stars;
  DateTime? lastStudied;

  LearningProgress({
    required this.character,
    this.isLearned = false,
    this.isFavorite = false,
    this.stars = 0,
    this.lastStudied,
  });

  Map<String, dynamic> toJson() => {
        'character': character,
        'isLearned': isLearned,
        'isFavorite': isFavorite,
        'stars': stars,
        'lastStudied': lastStudied?.toIso8601String(),
      };

  factory LearningProgress.fromJson(Map<String, dynamic> json) =>
      LearningProgress(
        character: json['character'],
        isLearned: json['isLearned'] ?? false,
        isFavorite: json['isFavorite'] ?? false,
        stars: json['stars'] ?? 0,
        lastStudied: json['lastStudied'] != null
            ? DateTime.parse(json['lastStudied'])
            : null,
      );
}
