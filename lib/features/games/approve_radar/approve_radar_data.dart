/// G5 授权雷达：钉死「连接 ≠ 授权；额度决定对方能转走多少」。
class ApproveScenario {
  const ApproveScenario({
    required this.site,
    required this.actionLabel,
    required this.detail,
    required this.options,
    required this.answerIndex,
    required this.analysis,
    this.libraryEraId = 'contracts',
    this.fraudScamId,
  });

  /// 弹窗上显示的站点。
  final String site;

  /// 例如「连接钱包」「授权 USDT」。
  final String actionLabel;

  /// 额度、合约名等补充行；可空。
  final String detail;

  final List<String> options;
  final int answerIndex;
  final String analysis;

  /// 结算或解析可链到的资料小节。
  final String libraryEraId;

  /// 可选：链到防骗页。
  final String? fraudScamId;
}

const approveRadarPassScore = 4;

const approveRadarMechanism =
    '连接 ≠ 授权；额度决定对方能转走多少。';

const approveRadarScenarios = [
  ApproveScenario(
    site: 'app.uniswap.org',
    actionLabel: '连接钱包',
    detail: '仅请求查看地址，不请求转账或授权额度。',
    options: [
      '可以连接（仍要核对域名）',
      '这是无限授权，不能点',
      '先把助记词发给客服再连',
    ],
    answerIndex: 0,
    analysis:
        '「连接」多半只暴露地址。真正转走资产的是你随后确认的签名或授权，不是点一下连接本身。',
  ),
  ApproveScenario(
    site: 'claim-airdrop-now.xyz',
    actionLabel: '授权 USDT',
    detail: '额度：Unlimited（最大值）',
    options: [
      '先领空投，授权无所谓',
      '先别点：无限授权风险太大',
      '域名看着像官方，可以直接点',
    ],
    answerIndex: 1,
    analysis:
        '无限授权等于让对方合约随时转走该代币余额。假空投常先要你点这一下，币再被转走。',
    fraudScamId: 'fake_airdrop',
  ),
  ApproveScenario(
    site: 'app.uniswap.org',
    actionLabel: '授权 USDC',
    detail: '额度：50 USDC（刚好够这次兑换）',
    options: [
      '若你确实要在此兑换，可以按需授权',
      '有限额度也等于把钱包交出去',
      '改成 Unlimited 更省事',
    ],
    answerIndex: 0,
    analysis:
        '有限额度把风险钉在这笔生意上。域名仍要核对；额度合适不等于可以随便签任何弹窗。',
  ),
  ApproveScenario(
    site: 'unlswap.org',
    actionLabel: '授权 ETH',
    detail: '额度：Unlimited · 界面长得很像 Uniswap',
    options: [
      '界面一样，可以点允许',
      '先别点：域名差了一个字母',
      '先授权，回头再查域名',
    ],
    answerIndex: 1,
    analysis:
        '钓鱼站可以仿得几乎一样。先看地址栏/钱包里显示的域名；差一个字母就足以骗走授权。',
    fraudScamId: 'fake_airdrop',
  ),
  ApproveScenario(
    site: 'app.compound.finance',
    actionLabel: '授权 DAI',
    detail: '额度：Max / Unlimited（存入借贷协议）',
    options: [
      '知名协议，直接点允许无限额',
      '改成刚好够存入的额度再签',
      '把私钥导出给「安全客服」代操作',
    ],
    answerIndex: 1,
    analysis:
        '即便协议真实，无限授权也会放大被盗或合约出问题后的损失面。能改成够用额度时，优先改小。',
  ),
];
