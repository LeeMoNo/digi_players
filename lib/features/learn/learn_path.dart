import '../../core/progress/progress_store.dart';

/// 学习路径的完成情况。标记存在服务端，本机只保留当前 DID 的缓存。
class LearnPathProgress {
  final bool chapter1;
  final bool block;
  final bool hash;
  final bool p2p;
  final bool chapter2;
  final bool antiscam;

  const LearnPathProgress({
    this.chapter1 = false,
    this.block = false,
    this.hash = false,
    this.p2p = false,
    this.chapter2 = false,
    this.antiscam = false,
  });

  bool get isComplete =>
      chapter1 && block && hash && p2p && chapter2 && antiscam;
}

class LearnPathStep {
  final String title;
  final String button;
  final String route;

  /// 继续卡上「相关资料」指向的时间小节；路径走完时为空。
  final String? readingEraId;

  const LearnPathStep({
    required this.title,
    required this.button,
    required this.route,
    this.readingEraId,
  });
}

class LearnCatalogItem {
  final String title;
  final String route;
  final bool done;
  final bool current;
  final String? readingEraId;

  const LearnCatalogItem({
    required this.title,
    required this.route,
    required this.done,
    required this.current,
    this.readingEraId,
  });
}

const _steps = [
  LearnPathStep(
    title: '第一节 · 共有的账本',
    button: '继续阅读',
    route: '/learn/chapter/ch_001',
    readingEraId: 'ledger',
  ),
  LearnPathStep(
    title: '练习 · 区块链拼图',
    button: '去做练习',
    route: '/game/block-puzzle',
    readingEraId: 'ledger',
  ),
  LearnPathStep(
    title: '练习 · 哈希碰碰乐',
    button: '去做练习',
    route: '/games/hash',
    readingEraId: 'work',
  ),
  LearnPathStep(
    title: '练习 · 节点怎么传消息',
    button: '去做练习',
    route: '/game/p2p',
    readingEraId: 'broadcast',
  ),
  LearnPathStep(
    title: '第二节 · 密码学入门',
    button: '继续阅读',
    route: '/learn/chapter/ch_002',
    readingEraId: 'custody',
  ),
  LearnPathStep(
    title: '练习 · 反诈识别',
    button: '去做练习',
    route: '/games/antiscam',
    readingEraId: 'new_coins',
  ),
];

const _doneStep = LearnPathStep(
  title: '这条路径走完了',
  button: '去资料里看年史和骗局',
  route: '/learn/library',
);

/// 第一个还没完成的步骤。六步都完成时指向资料页。
LearnPathStep nextLearnStep(LearnPathProgress progress) {
  final flags = [
    progress.chapter1,
    progress.block,
    progress.hash,
    progress.p2p,
    progress.chapter2,
    progress.antiscam,
  ];
  for (var i = 0; i < flags.length; i++) {
    if (!flags[i]) return _steps[i];
  }
  return _doneStep;
}

List<LearnCatalogItem> learnCatalog(LearnPathProgress progress) {
  final flags = [
    progress.chapter1,
    progress.block,
    progress.hash,
    progress.p2p,
    progress.chapter2,
    progress.antiscam,
  ];
  final currentIndex = flags.indexWhere((done) => !done);
  return [
    for (var i = 0; i < _steps.length; i++)
      LearnCatalogItem(
        title: _steps[i].title,
        route: _steps[i].route,
        done: flags[i],
        current: i == currentIndex,
        readingEraId: _steps[i].readingEraId,
      ),
  ];
}

/// 练习通关后的主按钮。P2P 只有第一节已完成且第二节未通过时才打开第二节。
LearnPathStep practiceClearDestination({
  required String practice,
  required LearnPathProgress progress,
}) {
  switch (practice) {
    case 'block':
      return const LearnPathStep(
        title: '哈希碰碰乐',
        button: '去做哈希碰碰乐',
        route: '/games/hash',
      );
    case 'hash':
      return const LearnPathStep(
        title: 'P2P 节点模拟器',
        button: '去做 P2P 节点模拟器',
        route: '/game/p2p',
      );
    case 'p2p':
      if (progress.chapter1 && !progress.chapter2) {
        return const LearnPathStep(
          title: '第二节 · 密码学入门',
          button: '去读第二节',
          route: '/learn/chapter/ch_002',
        );
      }
      return const LearnPathStep(title: '继续', button: '继续', route: '/learn');
    default:
      return const LearnPathStep(title: '继续', button: '继续', route: '/learn');
  }
}

/// 测验通过后的主按钮。只把第一节接到拼图、第二节接到反诈。
/// 对应练习已经完成时，回到学习页。
LearnPathStep quizPassDestination({
  required String chapterId,
  required LearnPathProgress progress,
}) {
  if (chapterId == 'ch_001' && !progress.block) {
    return const LearnPathStep(
      title: '练习 · 区块链拼图',
      button: '去做区块链拼图',
      route: '/game/block-puzzle',
    );
  }
  if (chapterId == 'ch_002' && !progress.antiscam) {
    return const LearnPathStep(
      title: '练习 · 反诈识别',
      button: '去做反诈练习',
      route: '/games/antiscam',
    );
  }
  return const LearnPathStep(title: '继续', button: '继续', route: '/learn');
}

Future<LearnPathProgress> readLearnPathProgress() async {
  final flags = await ProgressStore.readFlags();
  bool flag(String key) => flags[key] == true;
  return LearnPathProgress(
    chapter1: flag('completed_ch_001'),
    block: flag('game_done_game_block'),
    hash: flag('game_done_game_hash'),
    p2p: flag('game_done_game_p2p'),
    chapter2: flag('completed_ch_002'),
    antiscam: flag('game_done_game_antiscam'),
  );
}
