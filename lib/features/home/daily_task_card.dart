// lib/features/home/daily_task_card.dart
import 'dart:math';

import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/shuffled_options.dart';

typedef DailyAnswerSubmit =
    Future<bool> Function(Object? qId, int selectedIndex);

/// 每日一题。
///
/// Workers `GET /daily/quiz` 目前按 `did + UTC 日期` 哈希从固定题池抽题，
/// **不接受**路径步骤等查询参数（无 `path_step` / `focus`）。
/// 因此这里不传「当前未完成步骤」，也不做本地题库兜底；失败或空题只留占位文案。
class DailyTaskCard extends StatefulWidget {
  const DailyTaskCard({super.key, this.loader, this.submitAnswer, this.random});

  /// 返回题目数据；失败或没有题目时返回 null。测试可替换。
  final Future<Map<String, dynamic>?> Function()? loader;

  /// 测试可替换提交。参数是题目原下标，不是屏幕上的位置。
  final DailyAnswerSubmit? submitAnswer;

  /// 测试可固定打乱结果。
  final Random? random;

  @override
  State<DailyTaskCard> createState() => _State();
}

class _State extends State<DailyTaskCard> {
  Map<String, dynamic>? _quiz;
  bool _completedToday = false;

  /// 屏幕上的位置，提交前会映射回原始下标。
  int? _selectedDisplay;
  ShuffledOptions? _shown;
  bool? _answeredCorrect;
  bool _loading = true;
  bool _submitting = false;
  final _lang = 'zh_CN'; // 后期接全局语言 provider

  @override
  void initState() {
    super.initState();
    _load(resetUi: false);
  }

  Future<void> _load({bool resetUi = true}) async {
    if (resetUi) {
      setState(() {
        _loading = true;
        _quiz = null;
        _shown = null;
        _selectedDisplay = null;
        _answeredCorrect = null;
        _completedToday = false;
      });
    }
    try {
      final data = widget.loader != null
          ? await widget.loader!()
          : await _loadFromApi();
      if (!mounted) return;
      setState(() {
        _quiz = data;
        _shown = _shuffle(data);
        _completedToday = data?['completed_today'] == true;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _quiz = null;
        _shown = null;
        _loading = false;
      });
    }
  }

  /// 接口无贴路径能力；故意不带进度查询参数。见类注释。
  Future<Map<String, dynamic>?> _loadFromApi() async {
    final res = await ApiClient.dio.get('/daily/quiz');
    final data = res.data;
    if (data is! Map) return null;
    return Map<String, dynamic>.from(data);
  }

  ShuffledOptions? _shuffle(Map<String, dynamic>? data) {
    final options = _optionsOf(data);
    if (options == null) return null;
    return ShuffledOptions.shuffle(options, random: widget.random);
  }

  Future<void> _submit() async {
    final display = _selectedDisplay;
    final shown = _shown;
    if (display == null || shown == null || _submitting) return;
    setState(() => _submitting = true);
    final original = shown.originalIndex(display);

    try {
      final correct = widget.submitAnswer != null
          ? await widget.submitAnswer!(_quiz!['q_id'], original)
          : await _submitToApi(original);
      if (!mounted) return;
      setState(() {
        _answeredCorrect = correct;
        if (correct) _completedToday = true;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<bool> _submitToApi(int originalIndex) async {
    final res = await ApiClient.dio.post(
      '/daily/quiz/answer',
      data: {'q_id': _quiz!['q_id'], 'selected': originalIndex},
    );
    return res.data['correct'] as bool;
  }

  String get _questionText {
    final raw = _quiz?['question'];
    if (raw is! Map) return '';
    final question = raw.map((key, value) => MapEntry('$key', '$value'));
    return question[_lang] ?? question['en'] ?? '';
  }

  List<String>? _optionsOf(Map<String, dynamic>? quiz) {
    final raw = quiz?['options'];
    if (raw is! Map) return null;
    final localized = raw[_lang] ?? raw['en'];
    if (localized is! List || localized.isEmpty) return null;
    return localized.map((item) => '$item').toList();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    final unavailable = !_loading && (_questionText.isEmpty || shown == null);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.10),
            Theme.of(context).colorScheme.secondary.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.today,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '每日一题',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              if (_completedToday)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '今日已完成',
                    style: TextStyle(fontSize: 11, color: Colors.green),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (_loading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (unavailable || shown == null) ...[
            const Text('今天的题暂时取不到'),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _load,
                child: const Text('重试'),
              ),
            ),
          ] else ...[
            Text(
              _questionText,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 10),

            if (_completedToday && _answeredCorrect != true) ...[
              const Text(
                '明天再来挑战吧～',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ] else if (_answeredCorrect != null) ...[
              // 答题结果
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _answeredCorrect!
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      _answeredCorrect! ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: _answeredCorrect! ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _answeredCorrect! ? '今天的题完成了' : '回答错误，再想想看',
                      style: TextStyle(
                        fontSize: 12,
                        color: _answeredCorrect!
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_answeredCorrect!) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() {
                    _selectedDisplay = null;
                    _answeredCorrect = null;
                    _shown = _shuffle(_quiz);
                  }),
                  child: const Text('重新选择'),
                ),
              ],
            ] else ...[
              // 选项列表
              for (var i = 0; i < shown.texts.length; i++)
                _DailyOption(
                  text: shown.texts[i],
                  selected: _selectedDisplay == i,
                  onTap: () => setState(() => _selectedDisplay = i),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selectedDisplay == null || _submitting
                      ? null
                      : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('提交'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _DailyOption extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  const _DailyOption({
    required this.text,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: selected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            size: 18,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    ),
  );
}
