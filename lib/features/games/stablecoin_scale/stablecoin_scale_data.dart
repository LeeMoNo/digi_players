import 'stablecoin_scale_logic.dart';

const stablecoinScalePassScore = 4;

const stablecoinScaleMechanism = '锚定是承诺，储备决定承诺能不能兑。';

/// 固定盘面：玩家读天平，选出正确判断。
class StablecoinBoard {
  const StablecoinBoard({
    required this.title,
    required this.snapshot,
    required this.options,
    required this.answerIndex,
    required this.analysis,
  });

  final String title;
  final PegSnapshot snapshot;
  final List<String> options;
  final int answerIndex;
  final String analysis;
}

const stablecoinBoards = [
  StablecoinBoard(
    title: '盘面 A',
    snapshot: PegSnapshot(cash: 55, treasury: 35, risk: 10, pressure: 25),
    options: [
      '仍接近锚定，兑付大致撑得住',
      '已经脱锚',
      '报价或许还在，兑付先撑不住',
    ],
    answerIndex: 0,
    analysis:
        '安全储备占比高、赎回压力不高时，承诺比较站得住。'
        '这仍是示意，不是某只币的评级。',
  ),
  StablecoinBoard(
    title: '盘面 B',
    snapshot: PegSnapshot(cash: 10, treasury: 15, risk: 75, pressure: 70),
    options: [
      '仍接近锚定，兑付大致撑得住',
      '已经脱锚',
      '报价或许还在，兑付先撑不住',
    ],
    answerIndex: 1,
    analysis:
        '风险资产太重、挤兑又猛，示意价格会明显离开 1 美元。'
        '脱锚说的是承诺暂时或长期做不到。',
  ),
  StablecoinBoard(
    title: '盘面 C',
    snapshot: PegSnapshot(cash: 40, treasury: 40, risk: 20, pressure: 90),
    options: [
      '仍接近锚定，兑付大致撑得住',
      '已经脱锚',
      '报价或许还在，兑付先撑不住',
    ],
    answerIndex: 2,
    analysis:
        '账面储备看起来不差，但赎回潮大于安全垫时，'
        '「还有人报价接近 1」也不等于你随时兑得出来。',
  ),
];

class StablecoinNewsCard {
  const StablecoinNewsCard({
    required this.headline,
    required this.options,
    required this.answerIndex,
    required this.analysis,
  });

  final String headline;
  final List<String> options;
  final int answerIndex;
  final String analysis;
}

const stablecoinNewsCards = [
  StablecoinNewsCard(
    headline:
        '社群热传：某稳定币链上成交仍在 0.99–1.01，'
        '但发行方银行账户「临时冻结」，赎回要等通知。',
    options: [
      '价格还在，说明储备完全没问题',
      '先分清：报价在，不等于兑付通道通',
      '既然还能交易，应立刻加仓',
    ],
    answerIndex: 1,
    analysis:
        '锚定叙事看价格；兑付能力看你能不能按约 1 美元拿回法币或等价物。'
        '两件事可以暂时脱节。',
  ),
  StablecoinNewsCard(
    headline:
        '算法稳定币宣发「永远锚定 1 美元」，'
        '没有足额现金/国债储备，只靠发行与销毁循环维持。',
    options: [
      '没有现金储备就一定马上归零',
      '该慌的是锚定机制本身是否靠得住，而不只是某一天的报价',
      '算法比国债更安全',
    ],
    answerIndex: 1,
    analysis:
        '承诺可以写得很满；撑住承诺的是机制与储备质量。'
        '读新闻时先问：脱锚时谁来补、用什么补。',
  ),
];
