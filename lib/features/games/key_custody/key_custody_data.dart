/// G7 钥匙在谁手里：钉死「账户里显示有币 ≠ 链上地址由你控制」。
enum KeyBucket {
  /// 平台或托管方替你持有。
  exchange,

  /// 私钥/助记词在你手里。
  selfCustody,

  /// 资产或钥匙实际在对方控制下（含骗局地址）。
  counterparty,
}

String keyBucketLabel(KeyBucket bucket) {
  switch (bucket) {
    case KeyBucket.exchange:
      return '交易所 / 托管账户';
    case KeyBucket.selfCustody:
      return '自管地址（钥匙在你这）';
    case KeyBucket.counterparty:
      return '对方控制 / 骗局';
  }
}

class KeyCustodyCard {
  const KeyCustodyCard({
    required this.scene,
    required this.answer,
    required this.analysis,
  });

  final String scene;
  final KeyBucket answer;
  final String analysis;
}

const keyCustodyPassScore = 5;

const keyCustodyMechanism = '账户里显示有币 ≠ 链上地址由你控制。';

const keyCustodyCards = [
  KeyCustodyCard(
    scene: '交易所 App 显示「可用 2.5 BTC」，你从未导出过任何助记词。',
    answer: KeyBucket.exchange,
    analysis:
        '屏幕上的数字是平台账本余额。钥匙在平台手里；平台出事时，显示有币也不等于你能提到自己的地址。',
  ),
  KeyCustodyCard(
    scene: '硬件钱包生成的地址，助记词只刻在你保管的钢板上，从未拍照或上传。',
    answer: KeyBucket.selfCustody,
    analysis:
        '谁掌握助记词/私钥，谁就能控制同一套地址。这是自管：方便没了，备份与防骗责任也在你这。',
  ),
  KeyCustodyCard(
    scene: '「官方客服」私信：账户异常，请把币转到指定「安全冷钱包」完成验证。',
    answer: KeyBucket.counterparty,
    analysis:
        '正规流程不会让你把币转到陌生人地址「验证」。转过去的瞬间，控制权就到对方手里。',
  ),
  KeyCustodyCard(
    scene: '券商 App 里买入现货比特币 ETF 份额，持仓显示在普通证券账户。',
    answer: KeyBucket.exchange,
    analysis:
        '买到的是基金份额与托管安排，不是你手机里那串助记词。价格敞口在，钥匙归属仍是托管方。',
  ),
  KeyCustodyCard(
    scene: '手机钱包里的地址，助记词写在纸上锁进抽屉；你只用它给 dApp 签名，从未发给别人。',
    answer: KeyBucket.selfCustody,
    analysis:
        '自管不等于永远安全：签名与授权仍可能被骗。但「余额显示」对应的是你控制的链上地址，不是柜台账户名。',
  ),
  KeyCustodyCard(
    scene: '群友发来「平台冷钱包」地址，说充值后能挖矿翻倍，后台显示「已到账待解锁」。',
    answer: KeyBucket.counterparty,
    analysis:
        '对方地址上的到账，控制权在对方。后台「待解锁」只是话术；钥匙不在你这，显示再大也提不走。',
  ),
];

class KeyCustodyOutcome {
  const KeyCustodyOutcome({
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

/// 穿插的结局卡：Mt.Gox / FTX 式教训，仍是判断题。
const keyCustodyOutcomes = [
  KeyCustodyOutcome(
    headline:
        '大型交易平台突然无法提现。用户截图里账户仍显示有币，'
        '但链上对应地址早就对不上或无法兑付。最贴切的一句话是？',
    options: [
      '屏幕余额就是链上你的币',
      'Not your keys, not your coins：显示有币 ≠ 你控制地址',
      '只要还有报价，就一定能全额提出',
    ],
    answerIndex: 1,
    analysis:
        'Mt.Gox、FTX 等事件反复说明：托管便利与「平台倒了你是否还能提现」必须分开评估。',
  ),
];
