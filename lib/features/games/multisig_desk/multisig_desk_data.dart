/// G8 多签核对台：钉死「多签防的是单点失窃，防不了界面被骗」。
/// 只练识别异常摘要与「先看设备屏」，不演示如何构造恶意交易。
class MultisigDeskScenario {
  const MultisigDeskScenario({
    required this.intent,
    required this.site,
    required this.rows,
    required this.options,
    required this.answerIndex,
    required this.analysis,
  });

  /// 你以为自己在签什么。
  final String intent;

  /// 网页/面板上显示的站点。
  final String site;

  /// 待签摘要行：标签 → 显示值。
  final List<({String label, String value})> rows;

  final List<String> options;
  final int answerIndex;
  final String analysis;
}

const multisigDeskPassScore = 4;

const multisigDeskMechanism = '多签防的是单点失窃，防不了界面被骗。';

const multisigDeskScenarios = [
  MultisigDeskScenario(
    intent: '给已知金库地址转入 10 ETH，多人依次签字。',
    site: 'safe.global',
    rows: [
      (label: '收款地址', value: '0xTreasury…a91c（与你们备忘录一致）'),
      (label: '金额', value: '10 ETH'),
      (label: '操作类型', value: '普通转账'),
    ],
    options: [
      '摘要与意图一致，仍要在设备屏上再核对一遍后可签',
      '多签本身保证界面不会被骗，直接点签',
      '金额对就行，地址不用看',
    ],
    answerIndex: 0,
    analysis:
        '合法摘要也不等于可以跳过核对。多签只是「要好几把钥匙」；'
        '每把钥匙的人仍要确认设备上显示的才是自己要签的那笔。',
  ),
  MultisigDeskScenario(
    intent: '给金库地址 0xTreasury…a91c 转入 10 ETH。',
    site: 'safe.global',
    rows: [
      (label: '收款地址', value: '0xTreasury…a91b'),
      (label: '金额', value: '10 ETH'),
      (label: '操作类型', value: '普通转账'),
    ],
    options: [
      '金额对了，可以签',
      '拒签：收款地址与备忘录差了一位',
      '多签人多，有人核对过就行',
    ],
    answerIndex: 1,
    analysis:
        '差一位的地址就是另一个人。界面可以仿得很像；'
        '对地址要对照你们事先写下的完整串，而不是凭「看起来眼熟」。',
  ),
  MultisigDeskScenario(
    intent: '支付顾问费 2 ETH。',
    site: 'safe.global',
    rows: [
      (label: '收款地址', value: '0xAdvisor…77e0（名单内）'),
      (label: '金额', value: '20 ETH'),
      (label: '操作类型', value: '普通转账'),
    ],
    options: [
      '拒签：金额比意图多了一个数量级',
      '地址对就可以签',
      '先签，链上还能改回来',
    ],
    answerIndex: 0,
    analysis:
        '签出去的是设备确认的那笔数据。金额被改大时，'
        '多签人数再多，也只是一起确认了错误摘要。',
  ),
  MultisigDeskScenario(
    intent: '例行轮换，给金库转入 5 ETH。',
    site: 'safe-globa1.com',
    rows: [
      (label: '收款地址', value: '0xTreasury…a91c'),
      (label: '金额', value: '5 ETH'),
      (label: '操作类型', value: '普通转账'),
    ],
    options: [
      '界面和官方一样，可以签',
      '拒签：站点域名可疑，先回到你们常用的真入口',
      '域名不重要，只看摘要数字',
    ],
    answerIndex: 1,
    analysis:
        '假入口可以画出一模一样的摘要。多签网页被调包时，'
        '签字人看见的「正常转账」可能对应另一笔恶意数据。',
  ),
  MultisigDeskScenario(
    intent: '网页摘要看起来完全正常：地址、金额都对。',
    site: 'safe.global',
    rows: [
      (label: '收款地址', value: '0xTreasury…a91c'),
      (label: '金额', value: '3 ETH'),
      (label: '操作类型', value: '普通转账'),
      (label: '硬件屏', value: '尚未对照（只看了网页）'),
    ],
    options: [
      '网页对了就够，直接在设备上盲签',
      '先拒或暂停：必须对照硬件/设备屏上的地址与金额',
      '多签有阈值，一人盲签没关系',
    ],
    answerIndex: 1,
    analysis:
        '冷钱包、多签都不能代替「设备屏核对」。'
        '网页可以说谎；你真正批准的，是设备上显示并确认的那串数据。',
  ),
];
