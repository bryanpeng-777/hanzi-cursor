import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cs_ui/cs_ui.dart';
import '../data/pinyin_data.dart';
import '../providers/learning_provider.dart';
import '../utils/app_theme.dart';

class PinyinLearnScreen extends ConsumerStatefulWidget {
  const PinyinLearnScreen({super.key});

  @override
  ConsumerState<PinyinLearnScreen> createState() => _PinyinLearnScreenState();
}

class _PinyinLearnScreenState extends ConsumerState<PinyinLearnScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isAutoMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      appBar: CsAppBar(
        title: '拼音学习 📚',
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                        value: false,
                        label: Text('手动模式'),
                        icon: Icon(Icons.touch_app)),
                    ButtonSegment(
                        value: true,
                        label: Text('自动模式'),
                        icon: Icon(Icons.play_circle_outline)),
                  ],
                  selected: {_isAutoMode},
                  onSelectionChanged: (s) =>
                      setState(() => _isAutoMode = s.first),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppTheme.primaryOrange;
                      }
                      return Colors.white;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return Colors.grey[700];
                    }),
                  ),
                ),
              ),
              if (!_isAutoMode)
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryOrange,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppTheme.primaryOrange,
                  tabs: const [
                    Tab(text: '声母'),
                    Tab(text: '韵母'),
                    Tab(text: '四声'),
                  ],
                ),
            ],
          ),
        ),
      ),
      body: _isAutoMode
          ? _AutoModeView()
          : TabBarView(
              controller: _tabController,
              children: const [
                _InitialsGrid(),
                _FinalsGrid(),
                _TonesView(),
              ],
            ),
    );
  }
}

// ─── 手动模式：声母网格 ─────────────────────────────────────────────────────────

class _InitialsGrid extends ConsumerWidget {
  const _InitialsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mistakes = ref.watch(learningNotifierProvider).pinyinMistakes;
    return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: allInitials.length,
          itemBuilder: (context, i) {
            final item = allInitials[i];
            final hasMistake = mistakes.contains(item.symbol);
            return _PinyinCard(
              item: item,
              hasMistake: hasMistake,
            ).animate(delay: (i * 40).ms).fadeIn().scale(
                  begin: const Offset(0.85, 0.85),
                );
          },
        );
  }
}

// ─── 手动模式：韵母网格 ─────────────────────────────────────────────────────────

class _FinalsGrid extends StatelessWidget {
  const _FinalsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: allFinals.length,
      itemBuilder: (context, i) {
        final item = allFinals[i];
        return _PinyinCard(item: item, hasMistake: false)
            .animate(delay: (i * 40).ms)
            .fadeIn()
            .scale(begin: const Offset(0.85, 0.85));
      },
    );
  }
}

// ─── 手动模式：四声页 ───────────────────────────────────────────────────────────

class _TonesView extends StatelessWidget {
  const _TonesView();

  static const _toneData = [
    {
      'tone': '一声 ā',
      'mark': '—',
      'desc': '平平的，像在唱歌',
      'example': '妈 māma',
      'emoji': '👩',
      'color': Color(0xFF4CAF50),
    },
    {
      'tone': '二声 á',
      'mark': '/',
      'desc': '往上升，像在问问题',
      'example': '麻 máma',
      'emoji': '🤔',
      'color': Color(0xFF2196F3),
    },
    {
      'tone': '三声 ǎ',
      'mark': '∨',
      'desc': '先降后升，像在叹气',
      'example': '马 mǎ',
      'emoji': '🐴',
      'color': Color(0xFFFF9800),
    },
    {
      'tone': '四声 à',
      'mark': '\\',
      'desc': '快快往下，像在命令',
      'example': '骂 mà',
      'emoji': '😤',
      'color': Color(0xFFE91E8C),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final tts = FlutterTts();
    tts.setLanguage('zh-CN');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _toneData.length,
      itemBuilder: (context, i) {
        final data = _toneData[i];
        final color = data['color'] as Color;
        return GestureDetector(
          onTap: () => tts.speak(data['example'] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      data['mark'] as String,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['tone'] as String,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['desc'] as String,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${data['emoji']}  ${data['example']}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.volume_up_rounded,
                    color: Colors.grey, size: 22),
              ],
            ),
          ).animate(delay: (i * 100).ms).fadeIn().slideX(begin: 0.1),
        );
      },
    );
  }
}

// ─── 手动模式：拼音卡片（折叠/展开） ────────────────────────────────────────────

class _PinyinCard extends StatefulWidget {
  final PinyinItem item;
  final bool hasMistake;

  const _PinyinCard({required this.item, required this.hasMistake});

  @override
  State<_PinyinCard> createState() => _PinyinCardState();
}

class _PinyinCardState extends State<_PinyinCard> {
  bool _expanded = false;
  final _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('zh-CN');
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (!_expanded) {
      _tts.speak(widget.item.example);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _expanded
                  ? AppTheme.primaryOrange.withOpacity(0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _expanded
                    ? AppTheme.primaryOrange
                    : Colors.grey.shade200,
                width: _expanded ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _expanded ? _buildExpanded() : _buildCollapsed(),
          ),
          // 错题红点
          if (widget.hasMistake)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCollapsed() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.item.symbol,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.item.emoji,
          style: const TextStyle(fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildExpanded() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 拼音符号 + emoji
          Row(
            children: [
              Text(
                widget.item.symbol,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryOrange,
                ),
              ),
              const Spacer(),
              Text(widget.item.emoji,
                  style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 2),
          // 例字 + 拼音
          Text(
            '${widget.item.example}  ${widget.item.examplePinyin}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
          ),
          const SizedBox(height: 4),
          // 四声行（韵母专用）
          if (widget.item.tones.isNotEmpty)
            Wrap(
              spacing: 4,
              children: widget.item.tones
                  .asMap()
                  .entries
                  .map((e) => Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.levelColors[
                              e.key.clamp(0, AppTheme.levelColors.length - 1)],
                        ),
                      ))
                  .toList(),
            ),
          if (widget.item.tones.isNotEmpty) const SizedBox(height: 4),
          // 口诀
          Text(
            '「${widget.item.mnemonic}」',
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          // 组词
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: widget.item.exampleWords
                .map((w) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        w,
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF555555)),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── 自动模式 ──────────────────────────────────────────────────────────────────

class _AutoModeView extends StatefulWidget {
  @override
  State<_AutoModeView> createState() => _AutoModeViewState();
}

class _AutoModeViewState extends State<_AutoModeView> {
  bool _initialsSelected = true; // true=声母 false=韵母
  bool _started = false;

  late List<PinyinItem> _items;
  int _currentIndex = 0;
  bool _isPlaying = false;
  Timer? _autoTimer;
  final _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('zh-CN');
    _items = allInitials;
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _tts.stop();
    super.dispose();
  }

  void _startAuto() {
    setState(() {
      _items = _initialsSelected ? allInitials : allFinals;
      _currentIndex = 0;
      _isPlaying = true;
      _started = true;
    });
    _speakAndAdvance();
  }

  void _speakAndAdvance() async {
    if (!mounted || !_isPlaying) return;
    final item = _items[_currentIndex];
    await _tts.speak(item.example);
    // 朗读完成后停 2 秒再切换
    _autoTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted || !_isPlaying) return;
      if (_currentIndex < _items.length - 1) {
        setState(() => _currentIndex++);
        _speakAndAdvance();
      } else {
        setState(() => _isPlaying = false);
      }
    });
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _autoTimer?.cancel();
      _tts.stop();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);
      _speakAndAdvance();
    }
  }

  void _goTo(int index) {
    _autoTimer?.cancel();
    _tts.stop();
    setState(() => _currentIndex = index);
    if (_isPlaying) _speakAndAdvance();
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) return _buildSelector();

    final item = _items[_currentIndex];
    final isLast = _currentIndex == _items.length - 1;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 进度条
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('第 ${_currentIndex + 1} 个',
                  style: const TextStyle(fontSize: 16)),
              Text('共 ${_items.length} 个',
                  style: const TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _items.length,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryOrange),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 24),

          // 大卡片
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.85),
                    const Color(0xFF764BA2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 大拼音符号
                  Text(
                    item.symbol,
                    style: const TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate(key: ValueKey(item.symbol)).fadeIn(duration: 300.ms),
                  const SizedBox(height: 12),
                  // 例字 + emoji
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.example,
                          style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(width: 12),
                      Text(item.emoji,
                          style: const TextStyle(fontSize: 36)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.examplePinyin,
                    style: TextStyle(
                      fontSize: 22,
                      color: AppTheme.primaryYellow,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // 四声行（韵母）
                  if (item.tones.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 14,
                      children: item.tones
                          .asMap()
                          .entries
                          .map((e) => Text(
                                e.value,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.levelColors[
                                      e.key.clamp(
                                          0,
                                          AppTheme.levelColors.length - 1)],
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 14),
                  // 口诀
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '「${item.mnemonic}」',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // 拼读示范
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: item.blendExamples
                        .map((b) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                b,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  // 组词
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: item.exampleWords
                        .map((w) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryYellow.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                w,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ).animate(key: ValueKey(_currentIndex)).fadeIn(duration: 250.ms),

          const SizedBox(height: 20),

          // 控制按钮
          if (!_isPlaying && isLast)
            Text('🎉 全部学完了！',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen))
                .animate()
                .fadeIn()
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ControlBtn(
                  icon: Icons.skip_previous_rounded,
                  onTap: _currentIndex > 0
                      ? () => _goTo(_currentIndex - 1)
                      : null,
                ),
                GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryOrange.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                _ControlBtn(
                  icon: Icons.skip_next_rounded,
                  onTap: !isLast ? () => _goTo(_currentIndex + 1) : null,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSelector() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '选择学习内容',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _initialsSelected = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 110,
                      decoration: BoxDecoration(
                        color: _initialsSelected
                            ? AppTheme.primaryOrange.withOpacity(0.12)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _initialsSelected
                              ? AppTheme.primaryOrange
                              : Colors.grey.shade200,
                          width: _initialsSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🔤', style: TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          const Text('声母',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('${allInitials.length} 个',
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _initialsSelected = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 110,
                      decoration: BoxDecoration(
                        color: !_initialsSelected
                            ? AppTheme.primaryBlue.withOpacity(0.12)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: !_initialsSelected
                              ? AppTheme.primaryBlue
                              : Colors.grey.shade200,
                          width: !_initialsSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🔡', style: TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          const Text('韵母',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('${allFinals.length} 个',
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ShadButton(
                onPressed: _startAuto,
                leading: const Icon(Icons.play_arrow_rounded),
                child: const Text('开始自动学习'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ControlBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: onTap != null ? Colors.white : Colors.grey.shade200,
          shape: BoxShape.circle,
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: onTap != null ? AppTheme.primaryOrange : Colors.grey.shade400,
          size: 28,
        ),
      ),
    );
  }
}
