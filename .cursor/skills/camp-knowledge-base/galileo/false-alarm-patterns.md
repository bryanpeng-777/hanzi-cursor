# 伽利略误报模式知识库

常见告警误报场景汇总。遇到「建议屏蔽」结论时，由 galileo-assistant 自动积累和更新。

---

<!-- 新条目示例格式：

## 模式名称（如：流量放量导致量级超阈值误报）

- **现象**：xxx（如：量级骤增但错误率与昨日持平）
- **根因**：xxx
- **判断依据**：xxx（如：错误率未恶化，仅流量放量）
- **屏蔽建议**：静默 / 调整阈值至 xxx
- **首次记录**：yyyy-mm-dd
- **最后更新**：yyyy-mm-dd

-->

## NetRequest-start 短频检测误报（user/synccampfriends）

- **现象**：`user/synccampfriends` 接口的 NetRequest-start 量级超阈值，85%+ 日志 `netReqType=shortfrequency`，`status=-1`，无 `ret_code`，`grokAlarmType=statusError`，`requestCount=2`
- **根因**：登录初始化阶段多个模块（社交、聊天、游戏角色）并发触发好友同步接口，在 0.15s 内触发 ≥2 次请求，被 WEGShortFrequencyMonitor 标记为 error，但 API 实际成功（Trace 验证 status=OK）
- **判断依据**：`netReqType=shortfrequency` + 无 `ret_code` + Trace 中 `/user/synccampfriends` status=OK；真实网络错误（-1001）仅少量且与昨日持平
- **量级特征**：新版本（10.112.0415）放量时量级会大幅上涨（如 1711→5456），但错误率不变
- **处置建议**：建议屏蔽 — 与 `user/getkingcalendar` 属同类短频误报，可将 `user/synccampfriends` 加入 WEGShortFrequencyMonitor 白名单彻底根治
- **首次记录**：2026-04-22
- **最后更新**：2026-04-22
