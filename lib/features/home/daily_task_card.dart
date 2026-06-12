// lib/features/home/daily_task_card.dart
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

//每日任务卡片
class DailyTaskCard extends StatefulWidget {
  const DailyTaskCard({super.key});
  @override State<DailyTaskCard> createState() => _State();
}

class _State extends State<DailyTaskCard> {
  Map<String, dynamic>? _quiz;
  bool _completedToday = false;
  int? _selected;
  bool? _answeredCorrect;
  bool _loading = true;
  bool _submitting = false;
  final _lang = 'zh_CN'; // 后期接全局语言 provider

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await ApiClient.dio.get('/daily/quiz');
      setState(() {
        _quiz = res.data;
        _completedToday = res.data['completed_today'] as bool;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_selected == null || _submitting) return;
    setState(() => _submitting = true);

    try {
      final res = await ApiClient.dio.post('/daily/quiz/answer', data: {
        'q_id':     _quiz!['q_id'],
        'selected': _selected,
      });
      setState(() {
        _answeredCorrect = res.data['correct'] as bool;
        if (_answeredCorrect == true) _completedToday = true;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_quiz == null) return const SizedBox.shrink();

    final question = Map<String, String>.from(_quiz!['question']);
    final options  = (_quiz!['options'] as Map)[_lang] as List? ??
        (_quiz!['options'] as Map)['en'] as List;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
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
          Row(children: [
            Icon(Icons.today,
                size: 18,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text('每日一题',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                )),
            const Spacer(),
            if (_completedToday)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('今日已完成',
                    style: TextStyle(
                        fontSize: 11, color: Colors.green)),
              ),
          ]),
          const SizedBox(height: 10),

          Text(question[_lang] ?? question['en'] ?? '',
              style: const TextStyle(fontSize: 14, height: 1.5)),
          const SizedBox(height: 10),

          if (_completedToday && _answeredCorrect != true) ...[
            const Text('明天再来挑战吧～',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
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
              child: Row(children: [
                Icon(
                  _answeredCorrect! ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: _answeredCorrect! ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 6),
                Text(
                  _answeredCorrect!
                      ? '回答正确！获得 2 积分 🎉'
                      : '回答错误，再想想看',
                  style: TextStyle(
                    fontSize: 12,
                    color: _answeredCorrect!
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ]),
            ),
            if (!_answeredCorrect!) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() {
                  _selected = null;
                  _answeredCorrect = null;
                }),
                child: const Text('重新选择'),
              ),
            ],
          ] else ...[
            // 选项列表
            for (int i = 0; i < options.length; i++)
              _DailyOption(
                text:     options[i] as String,
                selected: _selected == i,
                onTap:    () => setState(() => _selected = i),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selected == null || _submitting
                    ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 16, width: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('提交'),
              ),
            ),
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
    required this.text, required this.selected, required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 9),
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
      child: Row(children: [
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
      ]),
    ),
  );
}