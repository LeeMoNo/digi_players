// lib/features/games/antiscam_game/antiscam_data.dart

class ScamQuestion {
  final String scenario;   // 情景描述
  final bool isScam;       // true = 诈骗
  final String analysis;   // 揭示答案后的解析

  const ScamQuestion({
    required this.scenario,
    required this.isScam,
    required this.analysis,
  });
}

const List<ScamQuestion> antiscamQuestions = [
  ScamQuestion(
    scenario:
        '私信："我是某知名交易所内部员工，有内幕消息，'
        '某代币下周会涨 300%，先买先赚，错过可惜！"',
    isScam: true,
    analysis:
        '典型"内幕消息"诈骗。真正的内幕交易是违法的，'
        '任何声称有内幕消息的人要么在撒谎，要么在诱导你。',
  ),
  ScamQuestion(
    scenario:
        '官方公告："本平台将于下周上线 BTC/USDT 合约交易，'
        '交易手续费前30天减免50%。"',
    isScam: false,
    analysis:
        '这是正常的平台运营公告。从官方渠道发布的优惠活动是正常的，'
        '关键是核实来源是否为官方网站或经过验证的账号。',
  ),
  ScamQuestion(
    scenario:
        '"发给我 1 个 ETH，我还你 2 个 ETH！这是马斯克举办的慈善活动，'
        '限时24小时，现在就转！"',
    isScam: true,
    analysis:
        '"发我 1 还你 2" 是币圈最经典的诈骗手法之一。'
        '没有任何人会凭空给你双倍回报，名人账号往往是被盗号或山寨账号。',
  ),
  ScamQuestion(
    scenario:
        '"您的钱包检测到异常，请立即点击链接，输入助记词完成安全验证。"',
    isScam: true,
    analysis:
        '索要助记词 = 100% 诈骗。助记词等于私钥，'
        '任何平台、任何人都不需要你的助记词来"验证安全"。',
  ),
  ScamQuestion(
    scenario:
        '"加入我们的流动性挖矿，年化收益稳定 200%，本金保底，随时赎回。"',
    isScam: true,
    analysis:
        '"稳定高收益+本金保底"是庞氏骗局的典型特征。'
        'DeFi 的真实年化收益会随流动性变化，没有任何协议能"保底"。',
  ),
  ScamQuestion(
    scenario:
        '"Uniswap 正式上线新版本 v4，请在官方网站 app.uniswap.org 连接钱包体验。"',
    isScam: false,
    analysis:
        '访问 DeFi 协议时，核心要点是核实域名是否正确。'
        'app.uniswap.org 是 Uniswap 的官方域名，这是正常的产品更新。',
  ),
  ScamQuestion(
    scenario:
        '"机器人自动套利，每天躺赚 3%，只需授权合约读取你的钱包。"',
    isScam: true,
    analysis:
        '"授权合约"若含有恶意权限，可以直接转走你的所有资产。'
        '"自动套利每天 3%"等于年化 1000%+，根本不可持续。',
  ),
  ScamQuestion(
    scenario:
        '"Ledger 硬件钱包官方提示：您的设备固件需要更新，'
        '请访问 Iedger-update.com 下载。"',
    isScam: true,
    analysis:
        '注意域名：Iedger（I 不是 L）是钓鱼网站。'
        '硬件钱包官方固件更新只通过官方 App（Ledger Live）推送，'
        '不会要求你访问第三方链接。',
  ),
  ScamQuestion(
    scenario:
        '"某 NFT 项目 Discord 公告：Mint 现已开放，每个地址限购 2 个，'
        '访问 opensea.io 查看详情。"',
    isScam: false,
    analysis:
        'OpenSea 是知名 NFT 交易平台，访问官方地址是安全的。'
        '真正需要警惕的是 Discord 里的假链接，永远在浏览器直接输入官方域名。',
  ),
  ScamQuestion(
    scenario:
        '"恭喜！您被选中参与某交易所上币投票，现在转入 0.1 BTC 作为投票押金，'
        '活动结束后自动退还并额外奖励 0.2 BTC。"',
    isScam: true,
    analysis:
        '"押金"换"更多回报"是经典骗局。正规交易所的社区投票绝不需要你转入任何资产，'
        '凡是需要先转币才能参与的"活动"，全是诈骗。',
  ),
];