/// G9 牌照与上下架。
///
/// 机制句：能交易 ≠ 受你所在地法保护；下架先砸流动性。
/// 只练读新闻/公告时该先查什么，不给买卖或迁所操作步骤。
class ListingDeskScenario {
  const ListingDeskScenario({
    required this.kind,
    required this.prompt,
    required this.options,
    required this.answerIndex,
    required this.analysis,
  });

  /// promo = 宣传语该先核对什么；action = 下架公告后的优先判断。
  final ListingDeskKind kind;
  final String prompt;
  final List<String> options;
  final int answerIndex;
  final String analysis;
}

enum ListingDeskKind { promo, action }

const listingDeskPassScore = 4;

const listingDeskMechanism = '能交易 ≠ 受你所在地法保护；下架先砸流动性。';

const listingDeskScenarios = [
  // —— 宣传语 ↔ 该先查的事实 ——
  ListingDeskScenario(
    kind: ListingDeskKind.promo,
    prompt:
        '项目或平台宣传：「我们已取得欧盟 MiCA / CASP 牌照，'
        '所以全球用户都受同等保护。」你该先核哪一点？',
    options: [
      '牌照覆盖的法域与业务范围（对谁、在哪展业）',
      '有牌照就等于永不被盗',
      '牌照名称好听就够了，不必看法域',
    ],
    answerIndex: 0,
    analysis:
        '持牌说明有人审过治理与客户资产规则，不是保险单。'
        '更要看：牌照允许面向哪些地区的用户；你所在地未必自动被盖住。',
  ),
  ListingDeskScenario(
    kind: ListingDeskKind.promo,
    prompt:
        '广告：「链上股票代币 = 你持有对应上市公司股票，'
        '还有投票权。」更靠谱的读法是？',
    options: [
      '多数只跟踪价格敞口，通常没有上市公司投票权',
      '既然叫股票代币，法律上一定等于登记股东',
      '能交易就说明发行人已把股票过户给你',
    ],
    answerIndex: 0,
    analysis:
        '名称容易误导。先分清：跟的是价格，还是登记在册的股权与投票。'
        '二者常不是一回事。',
  ),
  ListingDeskScenario(
    kind: ListingDeskKind.promo,
    prompt: '社群说：「交易对还挂着，所以随时能按合理价格卖掉。」问题在哪？',
    options: [
      '「对还在」不等于订单簿还有深度；下架预期会先抽干流动性',
      '交易对存在就保证有人必须按你的价接盘',
      '只要还能点卖出，滑点可以忽略',
    ],
    answerIndex: 0,
    analysis:
        '上架不是背书，下架也不等于项目从链上消失。'
        '真正先砸的是流动性：想卖时可能已经没有合理对手盘。',
  ),
  ListingDeskScenario(
    kind: ListingDeskKind.promo,
    prompt:
        '平台体量很大，但未说明是否持有你所在地要求的牌照。'
        '更稳妥的理解是？',
    options: [
      '能登录交易 ≠ 当地法律一定会按持牌标准保护你',
      '成交量全球第一就等于各地都已持牌',
      '无牌照只影响客服语气，不影响关户或限业务风险',
    ],
    answerIndex: 0,
    analysis:
        '无牌照不等于立刻被盗，但可能限业务、要求搬家甚至关户。'
        '体量与「你所在地是否允许它继续服务你」是两件事。',
  ),
  // —— 下架公告后的优先判断（仍是素养题，不是操作手册）——
  ListingDeskScenario(
    kind: ListingDeskKind.action,
    prompt:
        '交易所公告：某山寨币交易对将在约 24 小时后下架。'
        '作为读者，你该先抓住哪一句？',
    options: [
      '下架窗口里流动性可能迅速变差；「还能点卖」不等于还能合理成交',
      '下架前必须加仓，否则会错过最后一波',
      '下架后币会从区块链上删除，所以要立刻再买回来',
    ],
    answerIndex: 0,
    analysis:
        '下架抽走的是交易所订单簿，不是必然删链上合约。'
        '读公告时优先想：流动性与提币/自管通道还开着吗——'
        '本题只练判断，不指引你买或卖。',
  ),
];
