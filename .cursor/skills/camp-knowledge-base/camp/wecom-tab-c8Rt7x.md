---
source_url: https://doc.weixin.qq.com/smartsheet/s3_AN4ARwbdAFwCN7Lc86sbZQCihlLP0?tab=c8Rt7x
source_type: wecom-doc
scope: camp-problem-analyzer
slug: wecom-tab-c8Rt7x
title: 伽利略日常问题处理记录 — NGR上线期间P0，P1
last_updated: 2026-04-27T18:00:00+08:00
ttl_days: 7
update_mode: overwrite
keep_fields: [告警问题, 处理人, 伽利略责任人, 发现日期, 问题类型, 没有告警原因/无法定位原因/问题原因, 优先级, 完成情况]
---

# NGR上线期间P0，P1

| 告警问题 | 处理人 | 伽利略责任人 | 发现日期 | 问题类型 | 问题原因 | 优先级 | 完成情况 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Android 网络请求失败增加 /operation/action/newsignin | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-04-19 |  | 同一个时间点 | P1 | 已完成 |
| 【新P1】user/synccampfriends iOS错误指标量级上涨5% |  | bryanpeng(彭超) | 2026-04-23 |  | 递归调用：无真实网络错误，连续高频触发导致，和user/getkingcalendar 类似，正常 | P1 | 挂起 |
| Android 网络请求失败增加 /game/allrolelistv3 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-04-27 |  | -30139，单用户352425194引起，有泄露 | P1 | 进行中 |
| Android FlutterErrorReport错误量级增加20% | magicwu(吴家庆) | heshengpeng(彭和胜) | 2026-04-27 |  | 895dd167e24507319f1f008110001cd1580b单用户引起，登录页打开失败 | P1 | 进行中 |
| Android 自动登录成功率低于94% |  | heshengpeng(彭和胜) | 2026-04-21 |  | 伽利略平台抖动导致，数据掉了1m | P0 | 挂起 |
| Android 多游启动失败1h超过600次 | joinyin(尹泽宇), jasonmao(毛建伟) | heshengpeng(彭和胜) | 2026-04-20 |  | 3794866单用户引起，和之前是同样的问题；暂时没有进展，日志太少，0429补充日志 | P0 | 进行中 |
| Android 手动登录成功率低于40% |  | heshengpeng(彭和胜) | 2026-04-20 |  | 伽利略平台抖动导致 | P0 | 挂起 |
| Android 自动登录成功率低于94%（二次） |  | heshengpeng(彭和胜) | 2026-04-20 |  | 伽利略平台抖动导致 | P0 | 挂起 |
| /game/authinfo errorMsg: -111:操作失败,请稍后重试 | bryanpeng(彭超) | bryanpeng(彭超) | 2026-04-20 | 告警成功 | 腾讯云db抖动导致：MySQL kohgame 数据库 max_prepared_stmt_count 达到上限（16382），导致 SQL 查询失败，进而引发 /game/authinfo 接口返回 -111 错误 | P1 | 挂起 |
| Android 多游下载-开始下载错误率对比前1周上涨70% | jasonmao(毛建伟) | heshengpeng(彭和胜) | 2026-04-17 |  | 符合预期，低频出现，H5安装状态更新不及时，触发了下载 | P1 | 已完成 |
| Android TGPA预下载失败周同比增加 | jasonmao(毛建伟) | heshengpeng(彭和胜) | 2026-04-17 |  |  | P1 | 已完成 |
| Android 多游授权失败增加 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-04-19 |  | 后台服务问题，跟/game/authinfo同一时间点 | P1 | 已完成 |
| Android 网络请求失败增加 /game/authinfo | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-04-19 |  | errorCode=-111, errorMsg=-111:操作失败，请稍后重试 | P1 | 已完成 |
| Android 网络请求失败增加 /game/rolelist | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-04-19 |  | errorCode=-109, errorMsg=-109:数据获取失败，请稍后重试 | P1 | 已完成 |
| Android 网络请求失败增加 /game/authorize | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-04-19 |  | 同一个时间点 | P1 | 已完成 |
