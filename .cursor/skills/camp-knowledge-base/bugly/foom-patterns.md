# Bugly FOOM 排查经验知识库

常见 FOOM 场景和排查经验汇总。由 bugly-assistant 在分析过程中自动积累和更新。

---

<!-- 新条目示例格式：

## 模式名称

- **现象**：xxx（如：特定页面内存持续增长不释放）
- **根因**：xxx
- **处置方式**：建议修复 / 建议屏蔽 + 一句话理由
- **关联 Feature ID / stage**：（可选）
- **首次记录**：yyyy-mm-dd
- **最后更新**：yyyy-mm-dd

-->

## Flutter 热更系统（Conch）引发 FOOM

- **现象**：版本上线后 FOOM 从 200 次暴增至 12,000+ 次（63 倍增幅），从发布第一天起即高发，99% 为无堆栈问题；有堆栈的 issue 全部显示 `CoreFoundation RunLoop Timer 回调 + Flutter 引擎`，内存峰值 P90 达 2~3.28 GB
- **根因**：引入 Conch 动态热更系统（`flutter_conch_loader` + `flutter_conch_plugin`），配置了 `enableDevirtualization: true`（还原 Dart VM 优化），补丁加载后内存水位大幅上升；同期升级 `page_embed` 也可能有内存回归
- **处置方式**：建议修复 —— 临时可通过关闭 Conch（`kDisableConchKey` SharedPreferences）验证 FOOM 是否回落；长期需排查 patch 加载后的内存清理机制和 `enableDevirtualization` 带来的内存影响
- **典型版本**：10.112.0520（对比 10.112.0429）
- **主责人**：skylerpfli（Conch 系统负责人）
- **首次记录**：2026-06-08
- **最后更新**：2026-06-08

## FOOM 99% 无堆栈说明

- **现象**：FOOM issue 列表中「无堆栈问题」占 99%+
- **根因**：iOS FOOM 机制固有限制，系统 OOM kill 时无法捕获完整调用栈，只有 3 帧采样快照且多为系统框架帧（CoreFoundation / UIKit）
- **处置方式**：无需修复 —— 属于 iOS 机制，分析 FOOM 时应关注有堆栈的少数 issue + 代码变更对比
- **首次记录**：2026-06-08
- **最后更新**：2026-06-08
