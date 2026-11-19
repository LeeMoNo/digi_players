import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/chapter.dart';
import 'learn_path.dart';
import 'learn_repository.dart';

class QuizScreen extends StatefulWidget {
  final String chapterId;

  /// 测试可直接传入题目，避免请求章节接口。
  final ChapterDetail? initialDetail;

  /// 测试可替换通过后的记分与完成标记。
  final Future<void> Function()? recordPass;

  /// 测试可替换本地进度。
  final Future<LearnPathProgress> Function()? loadProgress;

  const QuizScreen({
    super.key,
    required this.chapterId,
    this.initialDetail,
    this.recordPass,
    this.loadProgress,
  });

  @override State<QuizScreen> createState() => _State();
}

class _State extends State<QuizScreen> {
  final _repo  = LearnRepository();
  ChapterDetail? _detail;
  int  _qIndex = 0, _score = 0;
  int? _selected;
  bool _answered = false, _finished = false;
  LearnPathStep? _passStep;
  final _lang = 'zh_CN';

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDetail;
    if (initial != null) {
      _detail = initial;
      return;
    }
    _repo.fetchChapterDetail(widget.chapterId)
        .then((d) { if (mounted) setState(() => _detail = d); });
  }

  void _select(int idx) {
    if (_answered) return;
    setState(() { _selected = idx; _answered = true; });
    if (idx == _detail!.quizQuestions[_qIndex].answer) _score++;
  }

  Future<void> _next() async {
    if (_qIndex < _detail!.quizQuestions.length - 1) {
      setState(() { _qIndex++; _selected = null; _answered = false; });
    } else {
      final passed = _score >= _detail!.passScore;
      LearnPathStep? passStep;
      if (passed) {
        if (widget.recordPass != null) {
          await widget.recordPass!();
        } else {
          await _repo.awardPoints(_detail!.quizPointsAction);
          await _repo.awardPoints(_detail!.completionAction);
          await _repo.markChapterCompleted(widget.chapterId);
        }
        final progress = await (widget.loadProgress ?? readLearnPathProgress)();
        passStep = quizPassDestination(
          chapterId: widget.chapterId,
          progress: progress,
        );
      }
      if (!mounted) return;
      setState(() {
        _passStep = passStep;
        _finished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_detail == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_finished)       return _result();

    final q    = _detail!.quizQuestions[_qIndex];
    final opts = q.localOptions(_lang);

    return Scaffold(
      appBar: AppBar(title: Text('测验 ${_qIndex + 1}/${_detail!.quizQuestions.length}')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(q.localQuestion(_lang),
              style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            for (int i = 0; i < opts.length; i++)
              _Option(
                text: opts[i],
                state: !_answered ? _S.normal
                    : i == q.answer   ? _S.correct
                    : i == _selected  ? _S.wrong
                    : _S.normal,
                onTap: () => _select(i),
              ),
            const Spacer(),
            if (_answered)
              FilledButton(
                onPressed: _next,
                child: Text(_qIndex < _detail!.quizQuestions.length - 1
                    ? '下一题' : '查看结果'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _result() {
    final passed = _score >= _detail!.passScore;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(passed ? Icons.emoji_events : Icons.replay,
                size: 80, color: passed ? Colors.amber : Colors.grey),
              const SizedBox(height: 24),
              Text(passed ? '通过！' : '未通过',
                style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('$_score / ${_detail!.quizQuestions.length} 题正确'),
              const SizedBox(height: 32),
              if (passed)
                FilledButton(
                  onPressed: () => context.go(_passStep!.route),
                  child: Text(_passStep!.button),
                )
              else ...[
                FilledButton(
                  onPressed: () => context.replace('/learn/quiz/${widget.chapterId}'),
                  child: const Text('重新测验'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.go('/learn'),
                  child: const Text('返回学习'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _S { normal, correct, wrong }

class _Option extends StatelessWidget {
  final String text;
  final _S state;
  final VoidCallback onTap;
  const _Option({required this.text, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _S.correct => Colors.green,
      _S.wrong   => Colors.red,
      _S.normal  => Theme.of(context).colorScheme.outline,
    };
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(12),
          color: state == _S.normal ? null : color.withOpacity(0.08),
        ),
        child: Text(text),
      ),
    );
  }
}