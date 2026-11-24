import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/layout/reading_width.dart';
import '../../core/router/app_back_button.dart';
import '../../core/models/chapter.dart';
import '../../core/progress/progress_store.dart';
import 'learn_repository.dart';

/// 每张卡片至少停留这么久，才允许点「已读」。
const chapterReadCountdownSeconds = 5;

class ChapterScreen extends StatefulWidget {
  final String chapterId;

  /// 测试可直接传入章节，避免请求接口。
  final ChapterDetail? initialDetail;

  /// 测试可预置已读卡片。
  final Set<String>? initialRead;

  /// 测试可缩短倒计时。
  final int countdownSeconds;

  const ChapterScreen({
    super.key,
    required this.chapterId,
    this.initialDetail,
    this.initialRead,
    this.countdownSeconds = chapterReadCountdownSeconds,
  });
  @override
  State<ChapterScreen> createState() => _State();
}

class _State extends State<ChapterScreen> {
  final _repo = LearnRepository();
  ChapterDetail? _detail;
  int _index = 0;
  Set<String> _read = {};
  final _lang = 'zh_CN';
  int _remainSeconds = 0;
  Timer? _countdown;

  @override
  void initState() {
    super.initState();
    if (widget.initialRead != null) {
      _read = Set<String>.from(widget.initialRead!);
    }
    if (widget.initialDetail != null) {
      _detail = widget.initialDetail;
      _startCountdown();
      return;
    }
    _load();
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final detail = await _repo.fetchChapterDetail(widget.chapterId);
    final read = await _repo.getReadCards();
    if (!mounted) return;
    setState(() {
      _detail = detail;
      _read = read;
    });
    _startCountdown();
  }

  void _startCountdown() {
    _countdown?.cancel();
    final total = widget.countdownSeconds;
    if (total <= 0) {
      setState(() => _remainSeconds = 0);
      return;
    }
    setState(() => _remainSeconds = total);
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainSeconds <= 1) {
        timer.cancel();
        setState(() => _remainSeconds = 0);
        return;
      }
      setState(() => _remainSeconds--);
    });
  }

  void _goNextCard() {
    setState(() => _index++);
    _startCountdown();
  }

  Future<bool> _onRead(CardItem card) async {
    if (_read.contains(card.cardId)) return true;
    try {
      await _repo.markCardRead(card.cardId);
    } on ProgressNotSaved {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(progressNotSavedMessage)));
      }
      return false;
    }
    await _repo.awardPoints(card.pointsAction);
    if (mounted) setState(() => _read.add(card.cardId));
    return true;
  }

  String _readButtonLabel(bool isLast) {
    if (_remainSeconds > 0) return '请阅读 ${_remainSeconds}s';
    return isLast ? '完成阅读，进入测验' : '已读，下一张';
  }

  @override
  Widget build(BuildContext context) {
    if (_detail == null) {
      return Scaffold(
        appBar: AppBar(
          leading: appBarLeading(context),
          title: const Text('章节'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final card = _detail!.cards[_index];
    final isLast = _index == _detail!.cards.length - 1;

    return Scaffold(
      appBar: AppBar(
        leading: appBarLeading(context),
        title: Text('${_index + 1} / ${_detail!.cards.length}'),
        actions: [
          TextButton(
            onPressed: () => context.push('/learn/quiz/${widget.chapterId}'),
            child: const Text('跳到测验'),
          ),
        ],
      ),
      body: ReadingWidth(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: (_index + 1) / _detail!.cards.length,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.localTitle(_lang),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        card.localBody(_lang),
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(height: 1.7),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_read.contains(card.cardId))
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '这一张读完了',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _remainSeconds > 0
                    ? null
                    : () async {
                        final saved = await _onRead(card);
                        if (!saved || !context.mounted) return;
                        if (_index < _detail!.cards.length - 1) {
                          _goNextCard();
                        } else {
                          context.push('/learn/quiz/${widget.chapterId}');
                        }
                      },
                child: Text(_readButtonLabel(isLast)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
