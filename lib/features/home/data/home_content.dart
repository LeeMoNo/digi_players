// 首页与子页静态内容（产品文案定稿）

enum TimelineEventType { tech, market, regulation, security }

class TimelineEvent {
  const TimelineEvent({
    required this.yearMonth,
    required this.title,
    required this.type,
    this.related,
    this.fraudScamId,
    this.blurb,
  });

  final String yearMonth;
  final String title;
  final TimelineEventType type;
  final String? related;
  final String? fraudScamId;

  /// 事件相关说明：不只报标题，补一句「这意味着什么」。
  final String? blurb;
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
    this.context,
  });

  final String term;
  final String definition;
  final String group;
  final String? learnChapterHint;
  final String? fraudScamId;

  /// 概念出现的背景或易混点，可选。
  final String? context;
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
    this.paragraphs = const [],
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

  /// 本节导读：概念为何出现、和前后有何关系。
  final List<String> paragraphs;
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
    FraudChecklistItem(
      id: 'verify_device',
      shortTitle: '硬件屏上核对真实交易',
      detail:
          '电脑或网页上「看起来正确」不够。'
          '用硬件钱包签名时，以设备屏幕显示的地址、金额与操作为准；对不上就拒绝。',
    ),
    FraudChecklistItem(
      id: 'token_not_share',
      shortTitle: '股票代币不是上市公司股东',
      detail:
          '交易所上的股票代币多半只跟踪价格表现，通常没有投票权，也不等于直接持有公司股份。'
          '发行方、托管与地域限制都要分开看，不要当成「上链就等于真股票」。',
    ),
    FraudChecklistItem(
      id: 'exchange_license',
      shortTitle: '选交易所先看牌照与法域',
      detail:
          '欧盟 MiCA 等规则要求加密服务商持牌才能继续面向当地用户。'
          '没有牌照不等于立刻被盗，但可能限业务、要求搬家甚至关户；'
          '有牌照也不等于「不会出事」，只说明有人审过运营与客户资产隔离要求。',
    ),
    FraudChecklistItem(
      id: 'delisting_risk',
      shortTitle: '山寨币随时可能被下架',
      detail:
          '上架不是背书，下架也不等于项目从链上消失。'
          '合规趋严后，交易所上新更挑、下架更勤：流动性变差时，'
          '「账上有币」和「还能按合理价格卖出」不是一回事。',
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
    FraudScamPattern(
      id: 'masked_signing',
      title: '被篡改的签名界面',
      summary: '屏幕上看着是普通转账，真正签出去的是换合约或掏空钱包。',
      detail:
          '攻击者可污染多签网页或前端，让签字人看到「正常转账」，'
          '硬件设备却收到另一笔恶意数据。冷钱包、多签都不能代替「设备屏核对」。'
          '2025 年 Bybit 冷钱包被盗，就是这类提醒。'
          '它和 2026 年币安热钱包签名基础设施被控是不同路径：前者骗签字人，后者攻内部系统。',
      signals: [
        '只看电脑弹窗、不看硬件屏',
        '催促「例行转账快点签」',
        '无法独立复述交易在做什么',
      ],
    ),
    FraudScamPattern(
      id: 'supply_chain_recruit',
      title: '假招聘 / 供应链入侵',
      summary: '用假面试、恶意安装包渗透员工设备，再打进交易所或项目内部系统。',
      detail:
          '2026 年币安约 63 亿美元被盗案中，公开调查描述攻击者曾用虚假招聘面试、'
          '篡改开发工具等方式潜伏数月，最终触达热钱包签名服务。'
          '普通用户也可能遇到「远程兼职先装软件」一类变体：目标不是你账户密码，是你的电脑权限。',
      signals: [
        '陌生人安排「线上面试作业」并要求安装不明软件',
        '开源工具、插件来源可疑却催你立刻安装',
        '强调「急招、高薪、先跑通代码」',
      ],
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
      blurb:
          '还没有比特币，但问题已经提出：如何在互不信任的人之间记账，又不交给单一银行。',
    ),
    TimelineEvent(
      yearMonth: '2008-10',
      title: 'Satoshi Nakamoto 发布《Bitcoin: A Peer-to-Peer Electronic Cash System》',
      related: 'BTC',
      type: TimelineEventType.tech,
      blurb:
          '白皮书把「点对点电子现金」写成可实现的协议：交易广播、打包成块、用工作量证明排序。',
    ),
    TimelineEvent(
      yearMonth: '2009-01',
      title: '比特币创世块挖出',
      related: 'BTC',
      type: TimelineEventType.tech,
      blurb:
          '账本从第 0 块开始连续生长。之后每一块都挂在前一块哈希上，改历史就要重算后面所有块。',
    ),
    TimelineEvent(
      yearMonth: '2011-10',
      title: 'Litecoin 等山寨链开始出现',
      related: 'LTC',
      type: TimelineEventType.tech,
      blurb:
          '有人复制比特币再改出块时间、算法或总量。名称不同，不等于安全模型或社区一定更好。',
    ),
    TimelineEvent(
      yearMonth: '2013-11',
      title: '比特币价格剧烈波动，中心化交易所兴起',
      type: TimelineEventType.market,
      blurb:
          '多数人通过网站买卖币，把币留在交易所账户里。方便的同时，钥匙实际在平台手里。',
    ),
    TimelineEvent(
      yearMonth: '2014-02',
      title: 'Mt.Gox 交易所破产，大量 BTC 损失',
      type: TimelineEventType.security,
      fraudScamId: 'fake_exchange',
      blurb:
          '当时全球最大比特币交易所之一无法兑付客户资产。'
          '「账户里显示有币」不等于链上地址真由你控制。',
    ),
    TimelineEvent(
      yearMonth: '2015-07',
      title: '以太坊主网上线，智能合约时代开启',
      related: 'ETH',
      type: TimelineEventType.tech,
      blurb:
          '不只转账：合约可以按规则自动执行。程序本身也要付 Gas，滥用会被费用挡住。',
    ),
    TimelineEvent(
      yearMonth: '2017-08',
      title: 'ICO 热潮与山寨币浪潮',
      type: TimelineEventType.market,
      blurb:
          '项目用发新币募资，白皮书与社群叙事先行。'
          '后来大量项目无法兑现承诺，催生「先上所预期、再兑现」的投机节奏。',
    ),
    TimelineEvent(
      yearMonth: '2020-06',
      title: 'DeFi Summer：Compound、Uniswap 等爆发',
      related: 'DeFi',
      type: TimelineEventType.market,
      blurb:
          '借贷与兑换更多由合约完成，用户自持资产进池子。'
          '收益来自协议规则与市场，也来自智能合约与预言机风险。',
    ),
    TimelineEvent(
      yearMonth: '2021-03',
      title: 'NFT 与元宇宙叙事达到舆论高峰',
      type: TimelineEventType.market,
      blurb:
          '链上凭证被用来标记图片、门票等稀缺性。'
          '叙事升温时，要分清「链上所有权记录」和「版权或线下权利」不是一回事。',
    ),
    TimelineEvent(
      yearMonth: '2022-09',
      title: '以太坊 Merge，共识转向 PoS',
      related: 'ETH',
      type: TimelineEventType.tech,
      blurb:
          '出块从比算力改为质押权益。能耗下降，但验证者作恶与罚没（slashing）成为新的安全讨论点。',
    ),
    TimelineEvent(
      yearMonth: '2022-11',
      title: 'FTX 暴雷，中心化托管风险凸显',
      type: TimelineEventType.security,
      fraudScamId: 'fake_exchange',
      blurb:
          '大型平台客户资产与自营混用、准备金不足的问题再次公开化。'
          '托管便利与「平台倒了你是否还能提现」必须分开评估。',
    ),
    TimelineEvent(
      yearMonth: '2024-01',
      title: '美国现货比特币 ETF 获批（监管里程碑）',
      related: 'BTC',
      type: TimelineEventType.regulation,
      blurb:
          '传统券商通道可间接暴露比特币价格。'
          '买的是基金份额，不是你自己控制的链上私钥；托管方在牌照框架内。',
    ),
    TimelineEvent(
      yearMonth: '2025-02',
      title: 'Bybit 冷钱包多签被骗签，约 15 亿美元 ETH 被盗',
      related: 'ETH',
      type: TimelineEventType.security,
      fraudScamId: 'masked_signing',
    ),
    TimelineEvent(
      yearMonth: '2025-05',
      title: 'Cetus（Sui DEX）合约数学漏洞，约 2 亿美元流动性被抽走',
      related: 'DeFi',
      type: TimelineEventType.security,
    ),
    TimelineEvent(
      yearMonth: '2025-06',
      title: '代币化美股上所交易扩散（如 xStocks）；Coinbase 等取得欧盟 MiCA 牌照',
      type: TimelineEventType.regulation,
    ),
    TimelineEvent(
      yearMonth: '2026-06',
      title: '币安等推出股票代币（如 bStocks）；交易所上新更挑、下架更勤',
      type: TimelineEventType.market,
    ),
    TimelineEvent(
      yearMonth: '2026-07',
      title: '欧盟 MiCA 过渡期结束：未持牌服务商须收缩或退出当地业务',
      type: TimelineEventType.regulation,
    ),
    TimelineEvent(
      yearMonth: '2026-10',
      title:
          '币安热钱包签名基础设施被入侵，约 63 亿美元资产受影响（公开报道中的史上最大加密盗窃）',
      related: 'CEX',
      type: TimelineEventType.security,
      fraudScamId: 'supply_chain_recruit',
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
    context:
        '每个块头含前一块哈希。改旧交易会扯断后面整条链，这是「不可随意篡改」的直观来源。',
  ),
  GlossaryTerm(
    group: '链与账本',
    term: '共识',
    definition: '网络节点对账本状态达成一致的机制，如 PoW（工作量证明）、PoS（权益证明）。',
    context:
        '没有中心裁判时，节点必须对「下一笔合法账」吵出同一答案；规则不同，攻击成本与能耗也不同。',
  ),
  GlossaryTerm(
    group: '链与账本',
    term: '确认数',
    definition: '交易被打包后，后续又新增了多少个区块；确认越多，篡改越难。',
    context:
        '交易所常等多个确认才入账。确认多不是「绝对安全」，而是重写历史的算力/权益成本更高。',
  ),
  GlossaryTerm(
    group: '链与账本',
    term: 'UTXO',
    definition: '比特币使用的模型：余额由若干「未花费输出」组成，而非单一账户余额。',
    learnChapterHint: '学程 · 比特币基础',
    context:
        '花钱时要选若干输出作输入，找零会生成新的输出。和银行「一个账户一个数字」的直觉不一样。',
  ),
  GlossaryTerm(
    group: '钱包与身份',
    term: '助记词',
    definition: '可读单词序列，可推导出私钥；丢失则无法恢复资产。',
    context:
        '谁掌握助记词，谁就能推导出同一套钥匙。截图、云同步、发给「客服」都等于交出账本控制权。',
  ),
  GlossaryTerm(
    group: '钱包与身份',
    term: 'Web3 钱包',
    definition: '本地保管密钥，对交易签名；连接 dApp 时不把私钥交给网站。',
    context:
        '「连接钱包」多半只暴露地址；真正转走资产的是你确认的签名或授权。网站本身不应拿到助记词。',
  ),
  GlossaryTerm(
    group: 'Gas 与合约',
    term: 'Gas',
    definition: '以太坊上执行操作需支付的费用，用于防止滥用并激励验证者。',
    context:
        '复杂合约吃更多 Gas。网络拥堵时单价升高，失败交易也可能已扣部分费用，要先看预估再签名。',
  ),
  GlossaryTerm(
    group: 'Gas 与合约',
    term: '智能合约',
    definition: '部署在链上的程序，条件满足时自动执行，无需中心化服务器。',
    context:
        '代码公开可查，不代表没有漏洞；一旦部署，漏洞也会被自动执行。授权给合约前要弄清它能做什么。',
  ),
  GlossaryTerm(
    group: 'DeFi 与 L2',
    term: 'DeFi',
    definition: '去中心化金融：借贷、交易、流动性等由智能合约完成。',
    context:
        '少了交易所柜台，多了合约、预言机与清算规则。收益和风险都写在链上逻辑里，而不是客服承诺里。',
  ),
  GlossaryTerm(
    group: 'DeFi 与 L2',
    term: 'Layer 2',
    definition: '构建在主链之上的扩容方案，将大量交易汇总后再提交主链结算。',
    context:
        '手续费与速度通常更好，但提回主链有等待与桥接风险；「在 L2 上有余额」和「已回到主链地址」要分开看。',
  ),
  GlossaryTerm(
    group: '市场结构',
    term: 'CEX / DEX',
    definition: '中心化交易所托管用户资产；去中心化交易所通过智能合约撮合，用户自持资产。',
    context:
        'CEX 像把币寄存在柜台；DEX 像自己进自动做市池。前者怕平台跑路或被盗，后者怕合约与滑点。',
  ),
  GlossaryTerm(
    group: '钱包与身份',
    term: '多签',
    definition:
        '一笔操作需要多把钥匙中的若干把共同批准。能降低单点失窃，'
        '但不能防止签字人被骗、或签名界面被篡改。',
    fraudScamId: 'masked_signing',
  ),
  GlossaryTerm(
    group: '钱包与身份',
    term: '冷钱包',
    definition:
        '私钥尽量离线保管的做法。它降低联网木马风险，'
        '但仍要在签名设备上核对真实交易；「冷」不等于绝对安全。',
    fraudScamId: 'masked_signing',
  ),
  GlossaryTerm(
    group: '钱包与身份',
    term: '热钱包',
    definition:
        '为了随时出金而保持在线的钱包或签名服务。交易所常用热钱包处理提现；'
        '便利伴随暴露面更大。2026 年币安大案指向的是热钱包侧签名基础设施，'
        '公开材料称当时未发现私钥本身被整包盗走。',
    fraudScamId: 'supply_chain_recruit',
  ),
  GlossaryTerm(
    group: '市场结构',
    term: '代币化股票',
    definition:
        '把股票价格敞口做成链上代币。多数产品由发行方与托管安排支持，'
        '持有人通常没有上市公司投票权，也不等于直接持有公司股份。',
  ),
  GlossaryTerm(
    group: '市场结构',
    term: '持牌经营',
    definition:
        '交易所等加密服务商须取得监管授权，才能在当地合法展业。'
        '欧盟 MiCA 把这类主体称为 CASP：过渡期结束后，无牌照者往往只能收缩或退出。'
        '持牌审的是治理与客户资产规则，不是「保证永不被盗」。',
  ),
  GlossaryTerm(
    group: '市场结构',
    term: '上架 / 下架',
    definition:
        '交易所决定某个代币能否在本所交易对上买卖。'
        '合规趋严后，上新审查更长、下架更常见；下架会抽走订单簿流动性，'
        '不等于智能合约被销毁，也不等于项目方一定跑路。',
  ),
  GlossaryTerm(
    group: '市场结构',
    term: '储备证明',
    definition:
        '交易所公布储备与负债对照，试图证明客户资产有对应支持。'
        '它是快照与审计方法问题，不是实时担保；'
        '平台宣布「用自有资金回填被盗缺口」时，也常会配发新一轮储备证明供用户核对。',
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
    FlowOverview(
      title: '签一笔多签前该看什么',
      steps: [
        '弄清这笔操作在做什么：转账、换合约，还是改权限',
        '在硬件设备屏幕上核对地址、金额与合约，不要只信电脑弹窗',
        '对不上或看不懂就拒绝；例行转账也可以停下来复述一遍',
        '多签降低单点失窃，挡不住集体被同一块假界面骗签',
      ],
    ),
    FlowOverview(
      title: '大型交易所被盗后，几件事要分开看',
      steps: [
        '链上流出了多少：被盗规模，例如 2026 年 10 月币安案公开数字约 63 亿美元',
        '谁承担缺口：平台是否用自有资金 / 安全基金回填客户账本',
        '追回进度：稳定币发行方冻结、执法机关扣押，与「账上已补齐」不是同一步',
        '你自己能核对什么：提现是否恢复、储备证明是否更新、所在法域服务是否还在',
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

  /// 2025–2026 专节：最大所、牌照、上下架与大额被盗。只讲机制，不提供买卖建议。
  static const recentRiskParagraphs = [
    '现货比特币 ETF 之后，市场重心从「能不能买到币」转向三件事：最大交易所是否扛得住极端安全事件、各国是否要求持牌才能营业，以及山寨币上架是否还像以前那样随便。',
    '2025 年 2 月，Bybit 冷钱包多签被骗签，约 15 亿美元 ETH 被盗——教训是签字人看见的界面可以是假的。2025 年 5 月，Cetus 等 DeFi 池子因合约数学漏洞被抽走约 2 亿美元流动性——教训是「链上可验证」不等于「代码无错」。',
    '2026 年 10 月 29 日前后，全球成交量最大的加密货币交易所币安发生公开报道中的史上最大加密盗窃：热钱包侧签名基础设施被入侵，约 63 亿美元资产受影响。公开材料描述攻击者曾用虚假招聘、恶意软件等供应链手法潜伏数月，并利用账户委托类机制绕开正常提现审批；币安称当时未发现私钥被整包盗走，并宣布用公司资金与安全基金等回填客户资产，同时配合冻结与执法追回。要把「链上被转走」「账上已补齐」「被盗币是否追回」分成三件事看。',
    '同一时期，监管把「能不能继续开交易所」写进规则。欧盟 MiCA 过渡期在 2026 年 7 月结束：取得 CASP 等牌照的服务商可继续面向当地用户，未持牌者往往须收缩或退出。持牌审的是治理与客户资产规则，不是永不被盗的保险单；无牌照则可能直接失去合法展业入口。',
    '上架与下架也变了。合规与风控成本上升后，交易所对新币更挑、对存量更勤于下架；「交易对还在」不等于「随时能按合理价格卖出」。另有股票代币（如 xStocks、bStocks）把股价敞口搬上链：多数只跟踪价格，通常没有上市公司投票权。本节不教你买卖，只帮你读懂新闻里的最大所、牌照和上下架在说什么。',
  ];

  static const eraSections = [
    EraSection(
      id: 'ledger',
      sortYear: 1998,
      when: '1998–2009',
      title: '共有的账本',
      besidePath: '第一节 · 共有的账本',
      paragraphs: [
        '在比特币出现之前，电子现金的难题是：两个人互不信任时，谁来保证同一笔钱没有被花两次。银行可以当裁判，但那就又回到中心化账本。',
        '比特币把交易广播给全网，再按块打包、用哈希串成链。谁想改旧账，就要同时改后面所有块——这就是「共有账本」比单机数据库难篡改的地方。',
        '创世块是这条链的起点。读本节时，先抓住三样东西：交易、区块、以及「前一块哈希」如何把时间顺序钉死。',
      ],
      eventYearMonths: ['1998-xx', '2008-10', '2009-01'],
      glossaryTerms: ['区块', 'UTXO'],
    ),
    EraSection(
      id: 'work',
      sortYear: 2009,
      when: '2009',
      title: '为什么要花算力',
      besidePath: '练习 · 哈希碰碰乐',
      paragraphs: [
        '有了共有账本，还要解决「下一秒该听谁的块」。若人人都能随便出块，历史就会分叉到无法统一。',
        '工作量证明让出块变成猜哈希：难度调高时，平均要试很多次才出一块。攻击者想改历史，就要持续投入比诚实网络更多的算力。',
        '花费算力不是为了「浪费电」本身，而是给「谁有权追加账本」标出可验证的成本。后来权益证明换了一种成本：质押与罚没。',
      ],
      glossaryTerms: ['共识'],
    ),
    EraSection(
      id: 'broadcast',
      sortYear: 2009,
      when: '2009',
      title: '一笔交易怎么被知道',
      besidePath: '练习 · 节点怎么传消息',
      paragraphs: [
        '钱包签名之后，交易并不会自动出现在所有人手机里。它要先进入节点的内存池，再被邻居节点Gossip式传开。',
        '「我本地看见这笔交易」和「它已经被打包进块、后面又叠了几个确认」不是同一步。交易所入账往往要等确认数，就是在等历史更难被改写。',
        '网络分区或拥堵时，同一笔交易可能迟迟进不了块，或费率不足被挤掉。广播成功不等于结算完成。',
      ],
      glossaryTerms: ['确认数'],
      flowTitles: ['链上转账的一生'],
    ),
    EraSection(
      id: 'other_chains',
      sortYear: 2011,
      when: '2011–2013',
      title: '别的链和交易所',
      paragraphs: [
        '比特币跑通之后，出现大量「改参数再发一条链」的尝试：出块更快、总量不同、算法不同。它们被笼统叫山寨链，并不自动更安全或更有用。',
        '同一时期，普通人开始在网站上买卖币。中心化交易所把撮合、托管和出入金放在一起，降低了使用门槛，也把「钥匙在谁手里」这个问题推回了前台。',
        '读到价格暴涨暴跌的新闻时，先分清两件事：链上协议有没有变，以及你的币是在自己地址里，还是在交易所账户名下。',
      ],
      eventYearMonths: ['2011-10', '2013-11'],
      glossaryTerms: ['CEX / DEX'],
    ),
    EraSection(
      id: 'custody',
      sortYear: 2014,
      when: '2014',
      title: '把钥匙交给别人',
      besidePath: '第二节 · 密码学入门',
      paragraphs: [
        'Mt.Gox 破产让一句口号变得具体：Not your keys, not your coins。账户余额可以显示很大，链上却可能早就对不上。',
        '自托管把控制权拿回来，也把备份与防骗责任拿回来。助记词是恢复整套钥匙的种子；谁拿到词，谁就能在另一台设备上打开同一份资产。',
        '后来的假交易所、杀猪盘、冒充客服，许多都建立在「劝你交出钥匙或把币转到对方控制的地址」上。技术名词会变，这一步动机很少变。',
      ],
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
      paragraphs: stablecoinParagraphs,
      stablecoin: true,
    ),
    EraSection(
      id: 'contracts',
      sortYear: 2015,
      when: '2015–2020',
      title: '程序代替中间人',
      paragraphs: [
        '以太坊把「可编程」带进账本：不只谁付给谁，还可以写清「满足条件就执行」。借贷、兑换、流动性挖矿，许多都可以没有传统柜台。',
        'Gas 是执行的计价与刹车。复杂逻辑更贵；网络忙时，失败交易也可能已经消耗费用。签名前要看清授权额度，而不是只看「连接成功」。',
        '2020 年前后 DeFi 放大了「自持资产进合约」的规模。少了交易所破产这一层，却多了合约漏洞、预言机与清算规则——风险换了形态，没有消失。',
      ],
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
      paragraphs: [
        'ICO 与山寨币浪潮把「发一个新代币」变成高频事件。叙事、社群和上所预期，往往比已上线的产品更早吸引资金。',
        '新币可以是实验，也可以是撤池跑路或资金盘的外壳。下面的生命周期不是预言每个项目，而是帮你认出常见阶段：诞生、传播、高峰、衰退与结局。',
        '「稳赚」「内幕」「保本」在这里既像赌博话术，也像诈骗话术。再加一笔，改变不了已经发生的亏损。',
      ],
      eventYearMonths: ['2017-08', '2021-03'],
      scamIds: ['rug_pull', 'ponzi'],
      checklistIds: ['investment'],
    ),
    EraSection(
      id: 'custody_returns',
      sortYear: 2022,
      when: '2022–2024',
      title: '托管又回来了',
      paragraphs: [
        '以太坊 Merge 之后，主网共识从比算力改为质押。能耗争论降温，机构与产品讨论开始更多谈「如何合规地替客户持有」。',
        'FTX 暴雷再次证明：把币放在大型平台，享受的是柜台体验，承担的是平台偿付与混用客户资产的风险。自托管与托管不是道德高低，是风险清单不同。',
        '2024 年初美国现货比特币 ETF 获批，传统账户也能间接暴露价格。买到的是基金份额与托管安排，不是你手机里那串助记词。托管以新的、受监管的形式「回来了」。',
      ],
      eventYearMonths: ['2022-09', '2022-11', '2024-01'],
      glossaryTerms: ['共识', 'CEX / DEX'],
    ),
    EraSection(
      id: 'recent_risks',
      sortYear: 2025,
      when: '2025–2026',
      title: '最大所、牌照与上下架',
      paragraphs: recentRiskParagraphs,
      eventYearMonths: [
        '2025-02',
        '2025-05',
        '2025-06',
        '2026-06',
        '2026-07',
        '2026-10',
      ],
      glossaryTerms: [
        '热钱包',
        '冷钱包',
        '多签',
        '持牌经营',
        '上架 / 下架',
        '储备证明',
        '代币化股票',
        'CEX / DEX',
      ],
      flowTitles: [
        '大型交易所被盗后，几件事要分开看',
        '签一笔多签前该看什么',
      ],
      scamIds: [
        'supply_chain_recruit',
        'masked_signing',
        'fake_exchange',
      ],
      checklistIds: [
        'exchange_license',
        'delisting_risk',
        'verify_device',
        'token_not_share',
        'approve',
      ],
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
