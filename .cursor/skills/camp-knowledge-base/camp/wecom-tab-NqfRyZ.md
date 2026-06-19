---
source_url: https://doc.weixin.qq.com/smartsheet/s3_AN4ARwbdAFwCN7Lc86sbZQCihlLP0?tab=NqfRyZ
source_type: wecom-doc
scope: camp-problem-analyzer
slug: wecom-tab-NqfRyZ
title: 伽利略日常问题处理记录 — 新P0、P1告警记录
last_updated: 2026-04-27T18:00:00+08:00
ttl_days: 7
update_mode: overwrite
keep_fields: [告警问题, 处理人, 伽利略责任人, 发现日期, 问题类型, 没有告警原因/无法定位原因/问题原因, 优先级, 完成情况]
---

# 新P0、P1告警记录

| 告警问题 | 处理人 | 伽利略责任人 | 发现日期 | 问题类型 | 问题原因 | 优先级 | 完成情况 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Android 多游下载错误量级超过5000 | jasonmao(毛建伟) | heshengpeng(彭和胜) | 2026-04-16 |  | 下载失败均为飞鹰，反馈处理中，安装失败主要为低版本，暂时先屏蔽 | P0 | 已完成 |
| Android OneAPIResponse错误量级增加 |  | heshengpeng(彭和胜) | 2026-04-07 |  | getStorage等获取key不存在，符合预期，忽略掉 | P1 | 已完成 |
| Android Crash 周同比增加50% | heshengpeng(彭和胜), joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-04-07 |  | 节假日日活增加，Crash次数增加（Bugly同样增加），调高告警阈值到90% | P0 | 已完成 |
| Android 自更新开始安装失败量级增加 | magicwu(吴家庆) | heshengpeng(彭和胜) | 2026-04-07 |  | StartInstall 量级略微增加，符合预期，0415优化下 | P1 | 已完成 |
| user/synccampfriends 失败量级 8934（阈值 6000），1分钟波动 8.9%（阈值 5%） | bryanpeng(彭超) | bryanpeng(彭超) | 2026-04-07 | 告警成功 | 递归调用：无真实网络错误，连续高频触发导致，和user/getkingcalendar 类似，正常 |  | 已完成 |
| iOS【新P1】【错误指标】大流量-1h（>=6000）-单模块【start】【step】【end】量级对比前1m上涨5% | bryanpeng(彭超) | bryanpeng(彭超) | 2026-04-12 |  | chatserver/offline/singlemsg 接口失败量增加，错误码 -10002（Redis读取超时） | P1 | 已完成 |
| Android /gametoolbox/equip/herosuit/setbysync增加20% |  | heshengpeng(彭和胜) | 2026-04-15 |  | 1619383356单用户引起，-167:玩家当前不允许设置套装，屏蔽掉 | P1 | 已完成 |
| Android 多游下载周同比增加70% | jasonmao(毛建伟) | heshengpeng(彭和胜) | 2026-04-15 |  | ngr上线，预期内的错误量级，周同比告警正常，先静默 | P1 | 已完成 |
| Android OneApi错误量级增加 | jasonmao(毛建伟) | heshengpeng(彭和胜) | 2026-04-15 |  | 双端存在，getGameChannelId问题，H5没有判断版本，低版本终端无实现 | P1 | 进行中 |
| Android Flutter WebView Undefined 方法调用 |  | heshengpeng(彭和胜) | 2026-04-14 |  | 不需要告警监控，屏蔽掉 | P1 | 已完成 |
| Android 自更新下载失败量级周同比增加70% | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-04-13 |  | 1842213595单用户 onGetFullApkPathFailed | P1 | 挂起 |
| Android 网络请求失败增加/chatserver/offline/singlemsg | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-04-13 |  | 同样时间点ios也有 | P1 | 进行中 |
| Android 【多游】1h拉起游戏失败超过600次 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-04-13 |  | 2127256535单用户问题，面板只出现了一次，但是一直在launchGame | P0 | 进行中 |
| Android SuitSync（多游-装备面板）错误量级周同比增加70% | willazhuang(庄萧) | heshengpeng(彭和胜) | 2026-04-13 |  | 符合预期，-2表示用户手动关闭面板，0415优化下值 | P1 | 已完成 |
| Android 启动次数Crash率周同比增加50% | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2026-04-09 |  | 0401版本整体Crash上升，Crash率告警调高阈值到120% | P0 | 已完成 |
| Android Crash量级 周同比增加90% | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2026-04-09 |  | 0401版本整体Crash上升，量级告警先停用，Crash率告警调高阈值 | P0 | 已完成 |
| 【新P1】【同比】start\|step\|end失败率同比增加60% | bryanpeng(彭超) | bryanpeng(彭超) | 2026-04-09 |  | 正常路径随着更新推进越来越小，最终收敛到 100%，全是-1001 |  | 挂起 |
