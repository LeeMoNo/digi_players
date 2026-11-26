/// 应用内法律文案。正式外链 URL 日后可替换；本步不依赖外网。
const legalContactEmail = 'support@digiplayers.example';

enum LegalDoc { privacy, terms }

String legalTitle(LegalDoc doc) => switch (doc) {
  LegalDoc.privacy => '隐私政策',
  LegalDoc.terms => '用户协议',
};

/// 分段正文，便于页面渲染与测试核对关键词。
List<LegalSection> legalSections(LegalDoc doc) => switch (doc) {
  LegalDoc.privacy => _privacySections,
  LegalDoc.terms => _termsSections,
};

class LegalSection {
  const LegalSection(this.heading, this.body);

  final String heading;
  final String body;
}

const _privacySections = [
  LegalSection(
    '我们是谁',
    'DigiPlayers 是一款区块链知识学习与反诈练习应用。'
    '本政策说明我们如何处理与你的学习账号相关的信息。',
  ),
  LegalSection(
    '收集什么',
    '我们可能处理：去中心化身份标识（DID）；学习进度与已读卡片；'
    '积分与完成行为记录；你设置的昵称与头像；可选的二次验证（TOTP）相关数据。'
    '当前版本不提供广场聊天，因此不会为此收集聊天内容。'
    '助记词与私钥只保存在你的设备本地安全存储中，我们不会上传助记词。',
  ),
  LegalSection(
    '存在哪里',
    '本机：身份密钥与助记词存放在系统安全存储（如 Keychain / Keystore）中；'
    '部分进度缓存可存放在本机。'
    '服务端：Cloudflare Workers 及关联的 D1 等边缘存储，用于登录会话、进度同步、'
    '积分与个人资料。',
  ),
  LegalSection(
    '用途',
    '用于验证登录、同步与展示学习进度、排行榜与个人资料，以及提供你主动使用的功能。'
    '我们不会把这些数据出售给第三方广告商。',
  ),
  LegalSection(
    '不能收款',
    '本产品里的身份只用来标识学习进度。它不能收款，请不要往这个身份转币或充值。'
    '任何声称「DigiPlayers 要你转账 / 索要助记词」的页面或私信都不是我们。',
  ),
  LegalSection(
    '你的选择',
    '你可以在设置中查看助记词（需通过校验）、退出登录，以及删除账号（见设置说明）。'
    '删除账号后，服务端与该身份关联的进度、积分与资料将按当时实现予以清除。',
  ),
  LegalSection(
    '联系我们',
    '有关隐私的问题可联系：$legalContactEmail\n'
    '（此邮箱为占位，上线前请替换为真实联系方式。）',
  ),
];

const _termsSections = [
  LegalSection(
    '服务内容',
    'DigiPlayers 提供区块链相关的学习内容、练习与反诈教育材料，仅供学习与参考，'
    '不构成投资、法律或财务建议。',
  ),
  LegalSection(
    '账号',
    '账号由你在本机生成的密钥与助记词标识。助记词是恢复该学习账号的依据；'
    '丢失助记词可能导致无法恢复本机以外的访问。'
    '把助记词交给他人，对方即可使用同一账号下的进度与资料。',
  ),
  LegalSection(
    '使用规范',
    '请勿利用本应用从事违法违规活动。'
    '当前版本不提供广场或开放聊天；若日后重新提供交流功能，'
    '禁止发布欺诈、骚扰、违法或侵权内容，我们保留处理违规内容与限制使用的权利。',
  ),
  LegalSection(
    '身份与资产',
    '本应用中的学习身份不能用于收款或链上转账。请勿向该身份转入加密货币或其他资产。',
  ),
  LegalSection(
    '删除账号',
    '你可以在设置中申请删除账号。删除后，与该身份相关的服务端进度、积分与个人资料'
    '将按产品当时的删除流程处理，且通常无法用助记词恢复已删数据。',
  ),
  LegalSection(
    '协议变更',
    '我们可能更新本协议；更新后继续使用即视为接受修订后的条款。'
    '当前版本可在应用内随时查阅，无需联网。',
  ),
  LegalSection(
    '联系我们',
    '有关本协议的问题可联系：$legalContactEmail',
  ),
];
