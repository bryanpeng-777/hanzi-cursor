# 伽利略域常识参考

平台固定参数、机制说明、字段含义、已知特殊行为等背景知识。内容自由格式，由 galileo-assistant 在分析过程中自动积累。

---

<!-- 写入格式示例（自由 Markdown，不强制结构）：

## 平台参数

- iOS target：`iOS.camp-app`
- Android target：`Android.camp-app`
- namespace 生产环境：`Production`

## 已知特殊行为

### user/getkingcalendar 短频误报
NetRequest level=error（netReqType=3）属正常行为。日历功能按时间切片并发多个请求，
触发 WEGShortFrequencyMonitor 短频检测（阈值 2次/0.15s），上报 cmd_short_frequency_exceeded。
Galileo 中 errorCode 永远为空，遇到此告警可直接忽略。

### user/synccampfriends 短频误报（2026-04-22 新增）
与 user/getkingcalendar 同属 WEGShortFrequencyMonitor 触发误报。
登录初始化时多模块并发调用好友同步接口，`netReqType=shortfrequency`，`requestCount=2`，`status=-1`，无 ret_code。
Trace 验证实际 API 全部成功（status=OK）。新版本放量时量级会大幅上涨但错误率不变。
遇到此告警可直接忽略，长期可将该接口加入 WEGShortFrequencyMonitor 白名单。

## 字段说明

### groupName 下钻告警
若 alert_labels 中存在 tags.groupName，说明告警针对具体接口而非模块整体。
后续所有 get_log_data 查询必须加 AND tags.groupName=<groupName>，否则数据会混入整个模块所有接口。

-->

<!-- 知识库初始为空，由 galileo-assistant 在实际使用中自动积累 -->
