import '../data/pinyin_data.dart';

/// 将拼音项转为中文 TTS 可读的文本（避免 Latin 字母被读成英文）。
abstract final class PinyinSpeech {
  /// 声母标准单音节读法（教学常用带韵母音，如 b→bō）
  static const Map<String, String> _initialSyllables = {
    'b': 'bō',
    'p': 'pō',
    'm': 'mō',
    'f': 'fó',
    'd': 'dé',
    't': 'tè',
    'n': 'nè',
    'l': 'lè',
    'g': 'gē',
    'k': 'kē',
    'h': 'hē',
    'j': 'jī',
    'q': 'qī',
    'x': 'xī',
    'zh': 'zhī',
    'ch': 'chī',
    'sh': 'shī',
    'r': 'rì',
    'z': 'zī',
    'c': 'cī',
    's': 'sī',
    'y': 'yī',
    'w': 'wū',
  };

  /// 正面喇叭：读拼音音（声母/韵母），非例字汉字。
  static String frontSpeech(PinyinItem item) {
    if (item.type == 'initial') {
      return _initialSyllables[item.symbol] ?? item.examplePinyin;
    }
    if (item.examplePinyin.isNotEmpty) {
      return item.examplePinyin;
    }
    if (item.tones.isNotEmpty) {
      return item.tones.first;
    }
    return item.symbol;
  }
}
