// 首页与子页静态内容（产品文案定稿）

enum TimelineEventType { tech, market, regulation, security }

class TimelineEvent {
  const TimelineEvent({
    required this.yearMonth,
    required this.title,
    required this.type,
    this.related,
    this.fraudScamId,
  });

  final String yearMonth;
  final String title;
  final TimelineEventType type;
  final String? related;
  final String? fraudScamId;
}

class FraudChecklistItem {
  const FraudChecklistItem({
    required this.id,
    required this.shortTitle,
    required this.detail,
  });

  final String id;
  final String shortTitle;
  final String detail;
}

class FraudScamPattern {
  const FraudScamPattern({
    required this.id,
    required this.title,
    required this.summary,
    required this.detail,
    required this.signals,
  });

  final String id;
  final String title;
  final String summary;
  final String detail;
  final List<String> signals;
}

class GlossaryTerm {
  const GlossaryTerm({
    required this.term,
    required this.definition,
    required this.group,
    this.learnChapterHint,
    this.fraudScamId,
  });

  final String term;
  final String definition;
  final String group;
  final String? learnChapterHint;
  final String? fraudScamId;
}

class FlowOverview {
  const FlowOverview({
    required this.title,
    required this.steps,
  });

  final String title;
  final List<String> steps;
}

class ExternalResource {
  const ExternalResource({
    required this.title,
    required this.url,
    required this.description,
    this.note,
  });

  final String title;
  final String url;
  final String description;
  final String? note;
}

class LearnMapEntry {
  const LearnMapEntry({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}

/// 按概念出现时间排列的一节资料。正文复用已有年史、术语、流程和骗局。
class EraSection {
  const EraSection({
    required this.id,
    required this.sortYear,
    required this.when,
    required this.title,
    this.besidePath,
    this.eventYearMonths = const [],
    this.glossaryTerms = const [],
    this.flowTitles = const [],
    this.scamIds = const [],
    this.checklistIds = const [],
    this.stablecoin = false,
  });

  final String id;
  final int sortYear;
  final String when;
  final String title;
  final String? besidePath;
  final List<String> eventYearMonths;
  final List<String> glossaryTerms;
  final List<String> flowTitles;
  final List<String> scamIds;
  final List<String> checklistIds;
  final bool stablecoin;

  String get heading => '$when · $title';
}

abstract final class HomeContent {
  static const tagline = '从链、钱包到安全 — 系统学加密货币';

  // ── 警防诈骗：安全清单 ─────────────────────────────
  static const fraudChecklist = [
    FraudChecklistItem(
      id: 'mnemonic',
      shortTitle: '助记词 / 私钥绝不外泄',
      detail:
          '不要截图、不要发给任何人、不要填入网页或聊天工具。'
          'DigiPlayers 不会向你索要助记词。',
    ),
    FraudChecklistItem(
      id: 'phishing',
      shortTitle: '警惕钓鱼网站与假链接',
      detail:
          '核对域名拼写，优先使用书签访问；警惕「客服」「空投领取」等私信链接。',
    ),
    FraudChecklistItem(
      id: 'fake_app',
      shortTitle: '只从官方渠道安装钱包',
      detail: '假 App 可窃取密钥。请从官网或官方应用商店下载，勿信第三方安装包。',
    ),
    FraudChecklistItem(
      id: 'approve',
      shortTitle: '链上授权要看清额度与合约',
      detail:
          'Approve 不等于转账，但恶意合约可转走资产。'
          '定期在区块浏览器检查并撤销不再使用的授权。',
    ),
    FraudChecklistItem(
      id: 'investment',
      shortTitle: '拒绝保本高收益与带单话术',
      detail:
          '「稳赚」「内幕」「保本」既是赌博话术，也是诈骗话术。'
          '「稳赚不赔」「内部消息」「拉群带单」都与正规技术学习无关。',
    ),
    FraudChecklistItem(
      id: 'transfer',
      shortTitle: '转账前核对地址与网络',
      detail: '先小额试转；复制地址后核对首尾字符；确认链与代币合约一致。',
    ),
  ];

  static const fraudPreviewScamIds = ['fake_exchange', 'fake_airdrop', 'rug_pull'];

  static const fraudScamPatterns = [
    FraudScamPattern(
      id: 'fake_exchange',
      title: '假交易所 / 假平台',
      summary: '仿冒知名交易所界面，充值后无法提现。',
      detail:
          '骗子搭建与真站相似的网站，诱导注册充值。'
          '常见特征：域名多一个字母、仅支持「内部转账」、客服催促加大投入。',
      signals: ['无法链上验证余额归属', '提现需缴纳「保证金」', '客服仅通过 Telegram/微信'],
    ),
    FraudScamPattern(
      id: 'pig_butchering',
      title: '杀猪盘',
      summary: '长期培养信任后诱导投资虚假项目。',
      detail:
          '从交友、兼职群入手，展示虚假盈利截图，引导下载非官方 App 或转入私人地址。'
          '往往持续数周才要求大额入金。',
      signals: ['只进不出', '禁止向亲友透露', '强调「错过就没机会」'],
    ),
    FraudScamPattern(
      id: 'fake_airdrop',
      title: '假空投 / 假领取',
      summary: '以免费代币为饵，诱导连接钱包或输入助记词。',
      detail:
          '社交媒体、私信中的「点击领取」链接可能触发恶意授权或钓鱼表单。'
          '正规空投极少要求导入助记词。',
      signals: ['要求输入助记词', '未知网站要求 Connect Wallet', '时间紧迫的「最后名额」'],
    ),
    FraudScamPattern(
      id: 'impersonation',
      title: '冒充官方 / 名人',
      summary: '假客服、假创始人账号私信用户。',
      detail:
          'Twitter、Discord 上的高仿账号承诺翻倍返还、解冻账户等。'
          '官方几乎不会私信索要资产或密钥。',
      signals: ['主动私信', '要求先转账才能「处理」', '使用个人钱包收款'],
    ),
    FraudScamPattern(
      id: 'rug_pull',
      title: 'Rug Pull（撤池跑路）',
      summary: '项目方撤走流动性，代币价格崩盘。',
      detail:
          '常见于匿名团队、未审计合约、流动性未锁定的新项目。'
          '与概念速查中「山寨币生命周期」末期相关。',
      signals: ['团队匿名且无法验证', '流动性可随时被创建者移除', '承诺固定高收益'],
    ),
    FraudScamPattern(
      id: 'ponzi',
      title: '庞氏 / 资金盘',
      summary: '用新用户资金支付旧用户收益，直至崩盘。',
      detail:
          '宣称「量化」「套利」「节点分红」，强调拉人头与层级奖励。'
          '与区块链技术无必然关系，却常包装成 Web3 项目。',
      signals: ['拉人头奖励', '收益来源不透明', '无法独立审计链上逻辑'],
    ),
  ];

  static const fraudRecognitionSignals = [
    '「稳赚」「内幕」「保本」既是赌博话术，也是诈骗话术',
    '承诺保本、固定收益或「稳赚不赔」',
    '只进不出：充值容易、提现层层设障',
    '必须拉人头、发展下线才能获得收益',
    '无法在区块浏览器独立验证资金与合约逻辑',
    '催促立刻行动，制造 FOMO（怕错过）',
  ];

  static const fraudWhatToDo = [
    '立即停止转账，不要再追加资金',
    '保存聊天记录、网址、转账哈希等证据',
    '向当地反诈中心或警方报案（各国渠道不同，以官方为准）',
    '若仅泄露授权未泄露助记词，尽快撤销相关合约授权',
    '切勿相信「付费解冻」「黑客追回」等二次诈骗',
  ];

  // ── 发展年史 ─────────────────────────────────────
  static const timelineEvents = [
    TimelineEvent(
      yearMonth: '1998-xx',
      title: 'Wei Dai 提出 B-money（加密匿名、分布式电子现金设想）',
      type: TimelineEventType.tech,
    ),
    TimelineEvent(
      yearMonth: '2008-10',
      title: 'Satoshi Nakamoto 发布《Bitcoin: A Peer-to-Peer Electronic Cash System》',
      related: 'BTC',
      type: TimelineEventType.tech,
    ),
    TimelineEvent(
      yearMonth: '2009-01',
      title: '比特币创世块挖出',
      related: 'BTC',
      type: TimelineEventType.tech,
    ),
    TimelineEvent(
      yearMonth: '2011-10',
      title: 'Litecoin 等山寨链开始出现',
      related: 'LTC',
      type: TimelineEventType.tech,
    ),
    TimelineEvent(
      yearMonth: '2013-11',
      title: '比特币价格剧烈波动，中心化交易所兴起',
      type: TimelineEventType.market,
    ),
    TimelineEvent(
      yearMonth: '2014-02',
      title: 'Mt.Gox 交易所破产，大量 BTC 损失',
      type: TimelineEventType.security,
      fraudScamId: 'fake_exchange',
    ),
    TimelineEvent(
      yearMonth: '2015-07',
      title: '以太坊主网上线，智能合约时代开启',
      related: 'ETH',
      type: TimelineEventType.tech,
    ),
    TimelineEvent(
      yearMonth: '2017-08',
      title: 'ICO 热潮与山寨币浪潮',
      type: TimelineEventType.market,
    ),
    TimelineEvent(
      yearMonth: '2020-06',
      title: 'DeFi Summer：Compound、Uniswap 等爆发',
      related: 'DeFi',
      type: TimelineEventType.market,
    ),
    TimelineEvent(
      yearMonth: '2021-03',
      title: 'NFT 与元宇宙叙事达到舆论高峰',
      type: TimelineEventType.market,
    ),
    TimelineEvent(
      yearMonth: '2022-09',
      title: '以太坊 Merge，共识转向 PoS',
      related: 'ETH',
      type: TimelineEventType.tech,
    ),
    TimelineEvent(
      yearMonth: '2022-11',
      title: 'FTX 暴雷，中心化托管风险凸显',
      type: TimelineEventType.security,
      fraudScamId: 'fake_exchange',
    ),
    TimelineEvent(
      yearMonth: '2024-01',
      title: '美国现货比特币 ETF 获批（监管里程碑）',
      related: 'BTC',
      type: TimelineEventType.regulation,
    ),
  ];

  // ── 概念速查 ─────────────────────────────────────
  static const rhetoricPhrases = ['稳赚', '内幕', '保本'];

  static const rhetoricLabels = ['赌博话术', '诈骗话术'];

  static const anotherBetLine = '再来一笔改变不了已经发生的亏损';

  static const shitcoinLifecycleTitle = '山寨币的典型生命周期';

  static const shitcoinLifecycleSteps = [
    '诞生：分叉、改参数、换皮白皮书，靠叙事与上所预期吸引关注',
    '传播：社交媒体、KOL、社群拉群，流动性往往较浅',
    '高峰：偶尔的上涨是间歇性奖励，把人留在追涨里；情绪与交易量仍会短期见顶，常与大盘行情同步',
    '衰退：叙事耗尽、团队离场或流动性被撤走',
    '结局：链上可能仍存在，但难以变现 — 需警惕 Rug Pull 与庞氏盘',
  ];

  static const glossaryTerms = [
  GlossaryTerm(
    group: '链与账本',
    term: '区块',
    definition: '打包多笔交易的数据单元，按顺序链接成链。',
  ),
  GlossaryTerm(
    group: '链与账本',
    term: '共识',
    definition: '网络节点对账本状态达成一致的机制，如 PoW（工作量证明）、PoS（权益证明）。',
  ),
  GlossaryTerm(
    group: '链与账本',
    term: '确认数',
    definition: '交易被打包后，后续又新增了多少个区块；确认越多，篡改越难。',
  ),
  GlossaryTerm(
    group: '链与账本',
    term: 'UTXO',
    definition: '比特币使用的模型：余额由若干「未花费输出」组成，而非单一账户余额。',
    learnChapterHint: '学程 · 比特币基础',
  ),
  GlossaryTerm(
    group: '钱包与身份',
    term: '助记词',
    definition: '可读单词序列，可推导出私钥；丢失则无法恢复资产。',
  ),
  GlossaryTerm(
    group: '钱包与身份',
    term: 'Web3 钱包',
    definition: '本地保管密钥，对交易签名；连接 dApp 时不把私钥交给网站。',
  ),
  GlossaryTerm(
    group: 'Gas 与合约',
    term: 'Gas',
    definition: '以太坊上执行操作需支付的费用，用于防止滥用并激励验证者。',
  ),
  GlossaryTerm(
    group: 'Gas 与合约',
    term: '智能合约',
    definition: '部署在链上的程序，条件满足时自动执行，无需中心化服务器。',
  ),
  GlossaryTerm(
    group: 'DeFi 与 L2',
    term: 'DeFi',
    definition: '去中心化金融：借贷、交易、流动性等由智能合约完成。',
  ),
  GlossaryTerm(
    group: 'DeFi 与 L2',
    term: 'Layer 2',
    definition: '构建在主链之上的扩容方案，将大量交易汇总后再提交主链结算。',
  ),
  GlossaryTerm(
    group: '市场结构',
    term: 'CEX / DEX',
    definition: '中心化交易所托管用户资产；去中心化交易所通过智能合约撮合，用户自持资产。',
  ),
  ];

  // ── 流程速览 ─────────────────────────────────────
  static const flowOverviews = [
    FlowOverview(
      title: '链上转账的一生',
      steps: [
        '在钱包输入收款地址与金额',
        '钱包用私钥对交易签名',
        '交易广播到网络节点',
        '矿工/验证者打包进区块',
        '确认后收款方余额更新',
      ],
    ),
    FlowOverview(
      title: 'Web3 钱包在其中的位置',
      steps: [
        '助记词/私钥仅保存在设备本地',
        '派生地址用于收款与标识',
        '签名在本地完成，私钥不离开钱包',
        '已签名交易提交到网络',
      ],
    ),
    FlowOverview(
      title: '连接 dApp 时发生了什么',
      steps: [
        'dApp 请求连接钱包地址（只读可见）',
        '发起转账或合约调用时需你确认签名',
        '「连接」本身不等于转走资产',
        '代币授权（Approve）是另一项独立风险',
      ],
    ),
  ];

  static const learnMapEntries = [
    LearnMapEntry(title: '基础概念', description: '区块、共识、BTC 与 ETH 模型'),
    LearnMapEntry(title: '钱包与安全', description: '密钥、助记词、防钓鱼'),
    LearnMapEntry(title: '链上流程', description: '转账、Gas、浏览器查账'),
    LearnMapEntry(title: 'DeFi 入门', description: 'DEX、流动性、授权风险'),
  ];

  static const externalResources = [
    ExternalResource(
      title: '比特币（中文）',
      url: 'https://bitcoin.org/zh_CN/',
      description: '比特币官方中文站：基础概念与白皮书',
    ),
    ExternalResource(
      title: '以太坊 · DeFi',
      url: 'https://ethereum.org/zh/defi/',
      description: '以太坊基金会 DeFi 专题',
    ),
    ExternalResource(
      title: '以太坊开发者文档',
      url: 'https://ethereum.org/developers/docs/',
      description: '面向开发者的以太坊技术文档',
      note: '英文为主',
    ),
    ExternalResource(
      title: 'Bitcoin Wiki',
      url: 'https://en.bitcoin.it/wiki/Main_Page',
      description: '比特币技术维基',
      note: '英文为主',
    ),
  ];

  static FraudScamPattern? scamById(String id) {
    for (final s in fraudScamPatterns) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// 只这一节是新写的。锚定、储备、脱锚分开说，不提供购买或发行步骤。
  static const stablecoinParagraphs = [
    '稳定币出现在人们需要一个链上计价单位之后。它的价格被说成接近 1 美元，但「看起来像美元」和「就是美元」不是一回事。',
    '锚定是一个承诺：发行方或机制试图让 1 枚稳定币换回约 1 美元。储备是这个承诺拿什么撑住，例如现金、国债或其他资产。脱锚是这个承诺暂时或长期做不到，价格明显离开 1 美元。',
    '三件事要分开看：有人在报价，不代表储备随时兑得出来；储备存在，不代表你拿得走；价格回到 1 美元，也不表示中间没有人兑付失败。',
  ];

  static const eraSections = [
    EraSection(
      id: 'ledger',
      sortYear: 1998,
      when: '1998–2009',
      title: '共有的账本',
      besidePath: '第一节 · 共有的账本',
      eventYearMonths: ['1998-xx', '2008-10', '2009-01'],
      glossaryTerms: ['区块', 'UTXO'],
    ),
    EraSection(
      id: 'work',
      sortYear: 2009,
      when: '2009',
      title: '为什么要花算力',
      besidePath: '练习 · 哈希碰碰乐',
      glossaryTerms: ['共识'],
    ),
    EraSection(
      id: 'broadcast',
      sortYear: 2009,
      when: '2009',
      title: '一笔交易怎么被知道',
      besidePath: '练习 · 节点怎么传消息',
      glossaryTerms: ['确认数'],
      flowTitles: ['链上转账的一生'],
    ),
    EraSection(
      id: 'other_chains',
      sortYear: 2011,
      when: '2011–2013',
      title: '别的链和交易所',
      eventYearMonths: ['2011-10', '2013-11'],
    ),
    EraSection(
      id: 'custody',
      sortYear: 2014,
      when: '2014',
      title: '把钥匙交给别人',
      besidePath: '第二节 · 密码学入门',
      eventYearMonths: ['2014-02'],
      glossaryTerms: ['助记词', 'Web3 钱包'],
      flowTitles: ['Web3 钱包在其中的位置'],
      scamIds: ['fake_exchange', 'pig_butchering', 'impersonation'],
      checklistIds: ['mnemonic', 'phishing', 'fake_app'],
    ),
    EraSection(
      id: 'stablecoin',
      sortYear: 2014,
      when: '2014',
      title: '稳定币为什么看起来像美元',
      stablecoin: true,
    ),
    EraSection(
      id: 'contracts',
      sortYear: 2015,
      when: '2015–2020',
      title: '程序代替中间人',
      eventYearMonths: ['2015-07', '2020-06'],
      glossaryTerms: ['Gas', '智能合约', 'DeFi', 'Layer 2', 'CEX / DEX'],
      flowTitles: ['连接 dApp 时发生了什么'],
      scamIds: ['fake_airdrop'],
      checklistIds: ['approve', 'transfer'],
    ),
    EraSection(
      id: 'new_coins',
      sortYear: 2017,
      when: '2017–2021',
      title: '新币的一生',
      besidePath: '练习 · 反诈识别',
      eventYearMonths: ['2017-08', '2021-03'],
      scamIds: ['rug_pull', 'ponzi'],
      checklistIds: ['investment'],
    ),
    EraSection(
      id: 'custody_returns',
      sortYear: 2022,
      when: '2022–2024',
      title: '托管又回来了',
      eventYearMonths: ['2022-09', '2022-11', '2024-01'],
    ),
  ];

  static EraSection? eraById(String id) {
    for (final era in eraSections) {
      if (era.id == id) return era;
    }
    return null;
  }

  static List<TimelineEvent> eventsFor(EraSection era) {
    return [
      for (final event in timelineEvents)
        if (era.eventYearMonths.contains(event.yearMonth)) event,
    ];
  }

  static List<GlossaryTerm> termsFor(EraSection era) {
    return [
      for (final term in glossaryTerms)
        if (era.glossaryTerms.contains(term.term)) term,
    ];
  }

  static List<FlowOverview> flowsFor(EraSection era) {
    return [
      for (final flow in flowOverviews)
        if (era.flowTitles.contains(flow.title)) flow,
    ];
  }

  static List<FraudScamPattern> scamsFor(EraSection era) {
    return [
      for (final id in era.scamIds)
        if (scamById(id) != null) scamById(id)!,
    ];
  }

  static List<FraudChecklistItem> checklistFor(EraSection era) {
    return [
      for (final item in fraudChecklist)
        if (era.checklistIds.contains(item.id)) item,
    ];
  }

  static String timelineTypeLabel(TimelineEventType type) => switch (type) {
        TimelineEventType.tech => '技术',
        TimelineEventType.market => '市场',
        TimelineEventType.regulation => '监管',
        TimelineEventType.security => '安全',
      };
}
