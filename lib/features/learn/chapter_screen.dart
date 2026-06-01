import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/chapter.dart';
import 'learn_repository.dart';

class ChapterScreen extends StatefulWidget {
  final String chapterId;
  const ChapterScreen({super.key, required this.chapterId});
  @override State<ChapterScreen> createState() => _State();
}

class _State extends State<ChapterScreen> {
  final _repo  = LearnRepository();
  ChapterDetail? _detail;
  int _index   = 0;
  Set<String> _read = {};
  final _lang  = 'zh_CN';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final detail = await _repo.fetchChapterDetail(widget.chapterId);
    final read   = await _repo.getReadCards();
    if (mounted) setState(() { _detail = detail; _read = read; });
  }

  Future<void> _onRead(CardItem card) async {
    if (_read.contains(card.cardId)) return;
    await _repo.markCardRead(card.cardId);
    await _repo.awardPoints(card.pointsAction);
    if (mounted) setState(() => _read.add(card.cardId));
  }

  @override
  Widget build(BuildContext context) {
    if (_detail == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final card   = _detail!.cards[_index];
    final isLast = _index == _detail!.cards.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_index + 1} / ${_detail!.cards.length}'),
        actions: [
          TextButton(
            onPressed: () => context.push('/learn/quiz/${widget.chapterId}'),
            child: const Text('跳到测验'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: (_index + 1) / _detail!.cards.length),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.localTitle(_lang),
                      style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    Text(card.localBody(_lang),
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(height: 1.7)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_read.contains(card.cardId))
              Row(children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 6),
                Text('已获得积分',
                  style: TextStyle(color: Colors.green.shade700, fontSize: 13)),
              ]),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                await _onRead(card);
                if (_index < _detail!.cards.length - 1) {
                  setState(() => _index++);
                } else {
                  context.push('/learn/quiz/${widget.chapterId}');
                }
              },
              child: Text(isLast ? '完成阅读，进入测验' : '已读，下一张'),
            ),
          ],
        ),
      ),
    );
  }
}