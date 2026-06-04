# digi_players

A new Flutter DigiPlayers project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


## 一、项目概览
 
**应用名称**：DigiPlayers  
**定位**：面向开发者 / 币圈入门者的区块链知识学习 + 游戏化激励平台  
**技术栈**：Flutter（客户端）· Cloudflare Workers + D1 + KV + R2（后端）  
**多语言**：简体中文 · 繁体中文 · English
 
### 核心差异点
 
- 注册即获得去中心化身份（DID），无需邮箱/手机号
- 知识学习与游戏深度绑定，学完解锁关卡
- 积分体系为未来代币发行预留通道
- 全程无传统服务器，Cloudflare 边缘计算
---

## 二、已确认的关键决策
 
| 决策项 | 结论 |
|---|---|
| 目标用户 | 有技术基础的开发者 / 币圈入门者 |
| 身份体系 | did:key（Ed25519），设备本地生成，助记词备份 |
| 积分价值 | 先记录，后期对应代币发行 |
| 后端架构 | Cloudflare 无服务器（Workers + D1 + KV + R2） |
| 多语言 | zh_CN · zh_TW · en，ARB 文件管理 |
| 积分设计 | Phase 1 全部 base_points = 1，multiplier 预留 |
 
---

## 三、整体架构速览
 
```
┌─────────────────────────────────────────────┐
│         Flutter 客户端（iOS / Android）       │
│  DID模块 · 学习系统 · 游戏系统 · 积分展示      │
└────────────────┬────────────────────────────┘
                 │ HTTPS · DID 签名认证
┌────────────────▼────────────────────────────┐
│         Cloudflare Workers（Edge API）        │
│  /auth  /points  /content  /leaderboard     │
└──────┬──────────────┬────────────┬──────────┘
       │              │            │
  ┌────▼────┐   ┌─────▼─────┐ ┌───▼───┐
  │   D1    │   │    KV     │ │  R2   │
  │积分账本  │   │挑战码/缓存 │ │内容资源│
  │用户档案  │   │session    │ │游戏数据│
  └─────────┘   └───────────┘ └───────┘
```



后续开发：
加入一个各种稳定币的简介。
这些概念是联通的，而且有出现时间顺序，我们按照它们的出现时间来学习就好。比如那个概念是些出来的，那个概念是最新发布的




