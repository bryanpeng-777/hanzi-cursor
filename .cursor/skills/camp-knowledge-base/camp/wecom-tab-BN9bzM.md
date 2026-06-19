---
source_url: https://doc.weixin.qq.com/smartsheet/s3_AN4ARwbdAFwCN7Lc86sbZQCihlLP0?tab=BN9bzM
source_type: wecom-doc
scope: camp-problem-analyzer
slug: wecom-tab-BN9bzM
title: 伽利略日常问题处理记录 — 问题记录
last_updated: 2026-04-27T18:30:00+08:00
ttl_days: 7
update_mode: overwrite
keep_fields: [待告警问题/其他问题, 处理人, 伽利略责任人, 发现日期, 问题类型, 没有告警原因/无法定位原因/问题原因, 优先级, 完成情况]
---

# 问题记录（共 636 条）

| 待告警问题/其他问题 | 处理人 | 伽利略责任人 | 发现日期 | 问题类型 | 没有告警原因/无法定位原因/问题原因 | 优先级 | 完成情况 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ManualLogin 模块 step4（userLoginEnd）失败率同比 7 日增加 52.18% |  | bryanpeng(彭超) | 2026-03-23 | 告警成功 | 失败主要是 errorCode=-1001（网络超时） |  | 已完成 |
| iOS【基础-扫码】扫码Start量级连续2h低于16 |  | bryanpeng(彭超) | 2026-03-26 | 告警成功 | 凌晨低流量期量级绝对值自然低于阈值，成功率未恶化 |  | 已完成 |
| iOS：game/battlestoragestatus 接口告警 | bryanpeng(彭超) | bryanpeng(彭超) | 2026-03-26 | 告警成功 | ret_code=-10109 召唤师隐藏了战绩列表，无法查看 |  | 已完成 |
| ImageLoadFail-start (groupName:game-1255653016.file.myqcloud.com) 量级超阈值告警 | bryanpeng(彭超) | bryanpeng(彭超) | 2026-03-29 | 告警成功 | MBTI卡片图片URL构造Bug（/profile-card/template_XX/mbti/.png文件名为空，errorCode=2001） |  | 进行中 |
| OneApi-start 量级告警：getABConfig(exp_infotab_shuangpai) 持续 Call Exception | bryanpeng(彭超) | bryanpeng(彭超) | 2026-03-31 | 告警成功 | 放量触发，之前屏蔽失败了，再次屏蔽，以及0401代码层面保护 |  | 已完成 |
| 图片加载超时量级突增， | bryanpeng(彭超) | bryanpeng(彭超) | 2026-04-01 | 告警成功 | wzzsmanager-1255653016.file.myqcloud.com 在告警时段出现大量超时，但很快恢复了，没有明显的有错误的链接 |  | 已完成 |
| iOS，AutoLogin-end 量级超阈值告警 | bryanpeng(彭超) | bryanpeng(彭超) | 2026-03-30 | 告警成功 | 用户已登录账号的WeChat/QQ token过期，自动刷新token时返回-30003「登录态失效」，导致AutoLogin失败跳转到手动登录页 |  | 已完成 |
|  |  |  | 2026-04-02 | 告警成功 |  |  |  |
| user/synccampfriends 失败量级 8934（阈值 6000），1分钟波动 8.9%（阈值 5%） | bryanpeng(彭超) | bryanpeng(彭超) | 2026-04-07 | 告警成功 | 递归调用：无真实网络错误，连续高频触发导致，和user/getkingcalendar 类似，正常 |  | 已完成 |
| Android 启动游戏失败 | jasonmao(毛建伟), joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-04-02 | 告警成功 | 外部路由拉起游戏失败，一半是鸿蒙无法拉起，一半是找不到王者，鸿蒙更改判断为成功，不视为错误，找不到王者的问题补充信息 | P0 | 已完成 |
| Android 启动游戏失败 | joinyin(尹泽宇), qcxiang(向乾操) | heshengpeng(彭和胜) | 2026-03-30 | 告警成功 | 2个单用户引起的小突刺，游戏未安装属于预期，但打开弹窗后，一直重复拉起（非用户点击） | P0 | 进行中 |
| AppExitReason模块start失败率7日同比从0→100%触发 |  | bryanpeng(彭超) | 2026-03-24 | 告警成功 | exitReason为userKill，0318新增分类 |  | 已完成 |
| ManualLogin step4(userLoginEnd) 失败率7日同比增加53.77% |  | bryanpeng(彭超) | 2026-03-24 | 告警成功 | QQTicket登录请求超时（-1001，60%），属网络层原因，非新引入失败路径 |  | 已完成 |
| ImageLoadFail模块下钻接口 game-1255653016.file.myqcloud.com 图片加载失败量级触发告警 |  | bryanpeng(彭超) | 2026-03-23 | 告警成功 | 量级放量触发，错误率未恶化。两类错误：errorCode=11111，网络错误类-1009/-1003/-1001，预期内行为 |  | 已完成 |
| OutRouter 模块 tencentmsdk1104466820:// end 失败率同比 7 日增加 181% |  | bryanpeng(彭超) | 2026-03-23 | 告警成功 | vip/getprofilevipcareer 接口因用户未激活星会员（错误码 -30372，提示「对不起！您的星会员尚未激活」）导致业务失败，属于预期的业务逻辑返回， |  | 已完成 |
| Android 网络失败增加 /gametoolbox/equip/herosuit/setbysync | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-03-26 | 告警成功 | 单用户1608449557，-167:玩家当前不允许设置套装 补充日志，新版本排查 | P1 | 挂起 |
| Android 网络失败增加 /game/friends | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-03-24 | 告警成功 | 单用户引起，-30139，像是系统出bug了，导致APP首页一直resumed paused | P1 | 挂起 |
| Android 网络失败增加 /vip/getprofilevipcareer | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-03-23 | 告警成功 | 单用户引起 | P1 | 进行中 |
| Android 网络150ms多次请求 /chatserver/offacc/list | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-03-23 | 告警成功 | 少数用户引起的重复请求 | P0 | 进行中 |
| Android 网络失败增加 /vip/getprofilevipcareer |  | heshengpeng(彭和胜) | 2026-03-23 | 告警成功 | 平台影响 | P1 | 挂起 |
| Android【A-新P0】最近5m自动登录成功率低于90% |  | heshengpeng(彭和胜) | 2026-03-23 | 告警成功 | 平台日志转日志数据异常问题，所有数据都出现了这个问题，几分钟后恢复 | P0 | 已完成 |
| Android【A-新P0】【Crash】最近24h天同比增加50% |  | heshengpeng(彭和胜) | 2026-03-23 | 告警成功 | 调整告警对比，周同比没有这么高 | P0 | 已完成 |
| Android 手动登录失败 同比前一周增加80% |  | heshengpeng(彭和胜) | 2026-03-23 | 告警成功 | 用户网络问题，导致无法请求 | P1 | 进行中 |
| Android 手动登录失败 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-03-20 | 告警成功 | 用户网络问题，导致无法请求，后续切换网络后恢复正常 | P1 | 进行中 |
| Android 支付成功率低于15% |  | heshengpeng(彭和胜) | 2026-03-19 | 告警成功 | 用户cancel，对齐iOS cancel改为正常情况 |  | 已完成 |
| 【新P1】【同比】end失败率同比增加50% | bryanpeng(彭超) | bryanpeng(彭超) | 2026-03-17 | 告警成功 | 触发P1 oncall升级，一个是量级太小，一个是jsbridge//的跳转失败没有屏蔽 |  | 已完成 |
| OneApi  【错误指标】大流量-1h（10w+~100w）-单模块【start】【step】【error】量级对比前1m上涨2.5% | bryanpeng(彭超) | bryanpeng(彭超) | 2026-03-17 | 告警成功 | getABConfig,关闭的时候，返回字典报错，修复一下，跟0401 |  | 已完成 |
| Android 图片加载失败增加 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-03-17 | 告警成功 |  |  | Oncalling |
| Android 网络失败增加 /gametoolbox/equip/herosuit/setbysync | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-03-17 | 告警成功 | 单用户1619383356，-167:玩家当前不允许设置套装 |  | 进行中 |
|  |  |  | 2026-03-16 | 告警成功 |  |  |  |
| ios和android：3/16 15:50 几十条告警，应该是有大问题 |  | bryanpeng(彭超) | 2026-03-16 | 告警成功 | 扩容波动了 1min |  | 已完成 |
| 【错误指标】连续1次-大流量-1h（6k+~10w）-单模块start量级对比前1m分钟上涨8.5%  tags.groupName: app/txvideo/refresh |  | bryanpeng(彭超) | 2026-03-16 | 告警成功 | -30314：登录态参数不全。检查客户端在调用   /app/txvideo/refresh   时是否正确在请求头中注入了营地 App 的 token 字段. 登录阶段，可以忽略 |  | 已完成 |
| 【新P1】【同比】end失败率同比增加50%   tags.moduleName: H5Page |  | bryanpeng(彭超) | 2026-03-16 | 告警成功 | H5Page日常告警，排除P1 |  | 已完成 |
|  |  |  | 2026-03-11 | 告警成功 |  |  |  |
| Android 网络失败增加 /chatserver/sendsinglechatmessage |  | heshengpeng(彭和胜) | 2026-03-11 | 告警成功 | 单用户发言太积极 |  | 挂起 |
| Android 网络失败增加 /chatserver/sendsinglechatmessage | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-03-10 | 告警成功 | 458651735单用户发言太积极 |  | 挂起 |
| Android 网络失败增加 /gametoolbox/equip/herosuit/setbysync |  | heshengpeng(彭和胜) | 2026-03-09 | 告警成功 | 单用户1619383356，-167:玩家当前不允许设置套装 |  | 挂起 |
| Android 网络失败增加 /game/allrolelistv3 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-03-09 | 告警成功 | 单用户1611035488   -30139 |  | 进行中 |
| Android 启动量级增加 |  | heshengpeng(彭和胜) | 2026-01-29 | 告警成功 | 信鸽推送引起的大流量，再调高一点阈值 |  | 挂起 |
| Android 人机验证转化率波动 |  | heshengpeng(彭和胜) | 2026-01-29 | 告警成功 | 0128调整step定义引起，先静默 |  | 已完成 |
| Android 网络失败增加  /app/parsesharecode | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-02-05 | 告警成功 | 用户不聚集，普遍性问题，跟后台确认，是符合预期的错误码，屏蔽，运营没有配置游戏的口令 |  | 已完成 |
|  |  | bryanpeng(彭超) | 2026-02-09 | 告警成功 |  |  |  |
| 【核心业务】1小时内同一用户crash数超过5次 | ricoyang(杨鈜宇) | bryanpeng(彭超) | 2026-02-09 | 告警成功 | -[FWFWebViewPreloader _doPendingTasks](FWFWebViewPreloader.m:271),rico |  | 进行中 |
| Android 网络失败增加 /user/donatecoinstatus |  | heshengpeng(彭和胜) | 2026-02-26 | 告警成功 | 后台服务抖动 | P0 | 挂起 |
| Android AppStart量级增加 |  | heshengpeng(彭和胜) | 2026-02-26 | 告警成功 | 信鸽推送引起的超大流量 |  | 挂起 |
| Android 网络失败增加  /user/getcampfriendsonline |  | heshengpeng(彭和胜) | 2026-02-27 | 告警成功 | java.io.IOException: Canceled，终端有cancel | P0 | 挂起 |
| 【新P1】【敏捷告警】【错误指标-分版本】连续2次-大流量-1h（200+~600）-单模块start量级上涨50% |  | bryanpeng(彭超) | 2026-03-05 | 告警成功 | 输入证件格式不正确 |  | 进行中 |
| 【核心业务】1小时内同一用户crash数超过5次 |  | bryanpeng(彭超) | 2026-03-05 | 告警成功 | 已分配，i创作相关crash |  | 进行中 |
| Android 图片加载失败增加 |  | heshengpeng(彭和胜) | 2026-03-05 | 告警成功 | 99626371单用户突刺，1219 低版本 |  | 已完成 |
| ios 合理官方大图告警 |  | bryanpeng(彭超) | 2026-03-02 | 告警成功 | https://static.gametalk.qq.com/image/18/1772529471_ddda0ac582b59bc154af55d6808541fd.jpg |  | 挂起 |
| Android 内部路由转化率下降 |  | heshengpeng(彭和胜) | 2026-03-02 | 告警成功 | 误告，调整告警次数 |  | 已完成 |
| Android 图片加载失败增加 |  | heshengpeng(彭和胜) | 2026-03-02 | 告警成功 | 单用户1758304036 socket timeout，1126低版本 |  | 挂起 |
| Android AppExitReason量级增加 |  | heshengpeng(彭和胜) | 2026-03-02 | 告警成功 | 1m突刺，活动引起的用户集中打开APP，然后手动杀APP |  | 挂起 |
| Android 内部路由量级增加 |  | heshengpeng(彭和胜) | 2026-03-02 | 告警成功 | 推送引起的大流量，调高一点阈值 |  | 已完成 |
| Android intimacyGift转化率下降 |  | heshengpeng(彭和胜) | 2026-03-02 | 告警成功 |  |  | 挂起 |
| Android intimacyGift量级增加 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-03-02 | 告警成功 | 1761446848 单用户引起，看着是用户频繁操作，确认让继续观察 |  | 挂起 |
| chatserver/sendsinglechatmessage【敏捷告警】【错误指标-分版本】连续2次-大流量-1h（600+~6k）-单模块start量级对比前1m分钟上涨15% |  | bryanpeng(彭超) | 2026-02-27 | 告警成功 | 您发送的信息非法,请注意言行等。静默这类告警 |  | 挂起 |
| 视频广告crash的问题 |  | bryanpeng(彭超) | 2026-02-27 | 告警成功 | 可查看复盘报告 |  | 已完成 |
| ios【核心业务】1小时内同一用户crash数超过5次 |  | bryanpeng(彭超) | 2026-02-27 | 告警成功 | magi处理中 |  | 进行中 |
| Android 网络失败增加  /user/getcampfriendsonline |  | heshengpeng(彭和胜) | 2026-02-27 | 告警成功 | java.io.IOException: Canceled，终端有cancel |  | 挂起 |
| Android 网络失败增加  /user/getcampfriendsinfo |  | heshengpeng(彭和胜) | 2026-02-27 | 告警成功 | java.io.IOException: Canceled，终端有cancel | P0 | 挂起 |
| Android 内部路由量级增加 |  | heshengpeng(彭和胜) | 2026-02-26 | 告警成功 | 信鸽推送引起的超大流量 |  | 挂起 |
| Android 图片加载失败增加 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-02-26 | 告警成功 | 单用户1758304036 多个图片url 404，群聊里的（可能是非法图片） |  | 进行中 |
| Android QRScan转换率波动 |  | heshengpeng(彭和胜) | 2026-02-26 | 告警成功 | 扫码 流量突刺引起，成功次数增加 |  | 挂起 |
| Android 网络失败增加 /user/getchurnpred |  | heshengpeng(彭和胜) | 2026-02-26 | 告警成功 | 流量增加 | P0 | 挂起 |
| Android 网络失败增加  /game/watchBattle |  | heshengpeng(彭和胜) | 2026-02-26 | 告警成功 | 直播流量增加、直播结束 | P0 | 挂起 |
| Android 图片加载失败增加 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-02-26 | 告警成功 | 单用户1758304036 多个图片url 404，群聊里的（可能是非法图片） | P0 | 进行中 |
| Android 网络失败增加  /chatserver/sendsinglechatmessage |  | heshengpeng(彭和胜) | 2026-02-26 | 告警成功 | 单用户发言太积极，-30011 | P0 | 挂起 |
| Android 网络失败增加  /chatserver/offline/singlemsg |  | heshengpeng(彭和胜) | 2026-02-26 | 告警成功 | 阶段性出现，后台返回101和-10002，tcp client transport ReadFrame | P0 | 挂起 |
| Android PAGLoadFail量级增加 |  | heshengpeng(彭和胜) | 2026-02-26 | 告警成功 | socket超时，继续观察 | P0 | 挂起 |
| Android 手动登录成功率恢复 |  | heshengpeng(彭和胜) | 2026-02-11 | 告警成功 | 后台压测引起的登录态失效， |  | 挂起 |
| Android ManualLogin 量级增加和降低 |  | heshengpeng(彭和胜) | 2026-02-11 | 告警成功 | 凌晨4点34~4点46有一波陡增，后台压测引起的登录态失效，但因为3~5点静默所以没告警出来，6点的时候告警恢复正常 |  | 挂起 |
| 【敏捷告警】【错误指标-分版本】连续2次-大流量-1h（600+~6k）-单模块start量级对比前1m分钟上涨15% |  | bryanpeng(彭超) | 2026-02-09 | 告警成功 |  |  |  |
| Android ManualLogin 量级增加 |  | heshengpeng(彭和胜) | 2026-02-09 | 告警成功 | 后台服务抖动导致1分钟突刺，继续观察 | P0 | 挂起 |
| Android 连续3次-1h-Crash量级对比前1天增加80% | jasonmao(毛建伟), joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-02-09 | 告警成功 | 同一个堆栈引起 |  | 进行中 |
| Android 网络失败增加  /game/detailinfobbs | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-02-09 | 告警成功 | 1598431707单用户网络异常 IO Cancel，请求有点频繁，偶现，继续观察下 | P0 | 挂起 |
| Android 用户反馈数超过40次 |  | heshengpeng(彭和胜) | 2026-02-09 | 告警成功 | 97931383单用户持续反馈吐槽皮肤 |  | 挂起 |
| Android 用户反馈数超过40次 |  | heshengpeng(彭和胜) | 2026-02-09 | 告警成功 | 97931383单用户持续反馈吐槽皮肤 |  | 挂起 |
| Android AppExitReason 量级增加 |  | heshengpeng(彭和胜) | 2026-02-09 | 告警成功 | 新版本新增指标，先静默几天 | P0 | 已完成 |
| Android 网络失败增加  /game/receivedmessage | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-02-06 | 告警成功 | 1726829684 单用户socket timeout，网络不通，多次启动 | P0 | 挂起 |
| Android 视频播放失败增加 |  | heshengpeng(彭和胜) | 2026-02-05 | 告警成功 |  |  |  |
| Android 视频播放失败增加 | jasonmao(毛建伟) | heshengpeng(彭和胜) | 2026-02-05 | 告警成功 | h1257376ac2、z1257258wso、e12571nmzev | P0 | 进行中 |
| iOS 视频播放失败增加 |  | bryanpeng(彭超) | 2026-02-05 | 告警成功 | h1257376ac2  、z1257258wso 、e12571nmzev |  | 进行中 |
| 【错误指标】大流量-1h（6k+~10w）-单模块start量级对比前1m分钟上涨5%  告警数据时间: 2026-02-05 11:42:00  app/parsesharecode |  | bryanpeng(彭超) | 2026-02-05 | 告警成功 | 非法分享文案 |  | 进行中 |
| 敏捷告警】【错误指标-分版本】连续2次-大流量-1h(200+~600)-单模块start量 级对比前1m分钟上涨50% user/synccampfriends |  | bryanpeng(彭超) | 2026-02-05 | 告警成功 | 触发后台限流，确认合理 |  | 已完成 |
| Android 网络失败增加  /chatserver/sendsinglechatmessage | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-02-04 | 告警成功 | 单1809121467发言太积极-30011 |  | 进行中 |
| 【错误指标】连续1次-大流量-1h（6k+~10w）-单模块start量级对比前1m分钟上涨8.5% |  | bryanpeng(彭超) | 2026-02-03 | 告警成功 | -50000：QQ鉴权失败，请稍候再试；-30003：登录态失效；信鸽推送中，user/login |  |  |
| Android Crash增加 |  | heshengpeng(彭和胜) | 2026-01-30 | 告警成功 |  |  | 已完成 |
| 【错误指标-分版本】连续1次-大流量-1h（6k+~10w）-单模块start量级对比前1m分钟上涨8.5% |  | bryanpeng(彭超) | 2026-02-03 | 告警成功 | 信鸽推送中，-10107, 伽利略无法跳转排查中，user/synccampfriends |  | 已完成 |
| Android Crash增加 |  | heshengpeng(彭和胜) | 2026-01-30 | 告警成功 | launcher模块没有重新编译，导致伽利略上报方法找不到 | P0 | 已完成 |
| 【敏捷告警】【错误指标-分版本】连续2次-大流量-1h（600+~6k）-单模块start量级对比前1m分钟上涨15%。midas上报 |  | bryanpeng(彭超) | 2026-01-29 | 告警成功 | -5000上报，和后台同学确认中,新皮肤上线正常 |  | 已完成 |
| [异常] 【核心业务】1小时内同一用户crash数超过5次 |  | bryanpeng(彭超) | 2026-01-28 | 告警成功 | 库层面的一个崩溃 |  | 进行中 |
| 【敏捷告警】【错误指标-分版本】连续2次-大流量-1h（200+~600）-单模块start量级对比前1m分钟上涨50%  app/getappscreenads |  | bryanpeng(彭超) | 2026-01-28 | 告警成功 | 开屏广告22号都过期了  27号发布了appSvr  也没有兜底数据了。后续后台同学会处理 |  | 已完成 |
| 【错误指标-分系统】小流量-1h（600+~6k）-单模块start量级对比前1m上涨20% |  | bryanpeng(彭超) | 2026-01-27 | 告警成功 | 非法发言拦截 -30099 |  | 已完成 |
| Android H5Page 失败增加 |  | heshengpeng(彭和胜) | 2026-01-26 | 告警成功 | uid无聚集性，第三方H5错误 | P0 | 挂起 |
| Android 网络失败增加 /game/battleaianalyze/apply | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-01-26 | 告警成功 | uid无聚集性，后台返回-260:排队中，请稍后再试，ai容量不足 | P0 | 挂起 |
| Android 网络失败增加  /chatserver/sendsinglechatmessage | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-01-26 | 告警成功 | uid无聚集性，主要是HTTP 504 网关超时，剩下则是-30099、-30011，发送太快被限频了 | P0 | 已完成 |
| 告警数据时间: 2026-01-27 13:19:00 |  | bryanpeng(彭超) | 2026-01-27 | 告警成功 | crash超过5次，debug特有忽略https://bugly.woa.com/v2/exception/crash/issues/list?productId=ef14bfff8f&pid=2&token=12f9bd3a8d31ad4346e3ebabb48a6e5c |  | 进行中 |
| Android 人机验证转化率波动 |  | heshengpeng(彭和胜) | 2026-01-27 | 告警成功 | 小流量指标，并且step定义不太合理，0128重新调整 |  | 已完成 |
| 【敏捷告警】【错误指标-分版本】连续2次-大流量-1h（200+~600）-单模块start量级对比前1m分钟上涨50%  chatserver/sendsinglechatmessage |  | bryanpeng(彭超) | 2026-01-26 | 告警成功 | -30098（禁言）, -30099(发言非法), -30011（您太积极了，请稍后再发言） |  | 已完成 |
| 【敏捷告警】【错误指标-分版本】连续2次-大流量-1h（600+~6k）-单模块start量级对比前1m分钟上涨15%  game/battleaianalyze/apply |  | bryanpeng(彭超) | 2026-01-26 | 告警成功 | 后台限流 |  | 已完成 |
| Android SpanStatistic量级增加 |  | heshengpeng(彭和胜) | 2026-01-23 | 告警成功 | mall/coupon hippy参数变长，先屏蔽 |  | 已完成 |
| pay/getbalance【敏捷告警】【错误指标-分版本】连续2次-大流量-1h（600+~6k）-单模块start量级对比前1m分钟上涨15% |  | bryanpeng(彭超) | 2026-01-23 | 告警成功 | -50000，和后台同学对齐，新皮肤上架，大量访问，midas报错增加，前后台波动一致， |  |  |
| Android infodetail InnerRouter量级增加 |  | heshengpeng(彭和胜) | 2026-01-21 | 告警成功 | 信鸽推送，量级过大引起 |  | 挂起 |
| 【敏捷告警】【错误指标-分版本】连续2次-大流量-1h（200+~600）-单模块start量级对比前1m分钟上涨50%   h5.nes.smoba.qq.com | bobihuang(黄腾) | bryanpeng(彭超) | 2026-01-21 | 告警成功 | 具体的错误贴到问题截图中了，已反馈（赛宝这边上了一波量导致） |  | 进行中 |
| 不同量级的多个oneApi的报错，原因都一样【错误指标】连续1次-大流量-1h（6k+~10w）-单模块start量级对比前1m分钟上涨8.5%  告警数据时间: 2026-01-21 14:02:00 |  | bryanpeng(彭超) | 2026-01-21 | 告警成功 | rotateXX (静默 + 代码)修改 |  | 已完成 |
| Android 图片加载失败增加 |  | heshengpeng(彭和胜) | 2026-01-10 | 告警成功 |  |  | 进行中 |
| Android 网络失败增加 /role/match/getpopuserlist | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-01-10 | 告警成功 | 1729664294，1641830893 单用户引起 | P0 | 挂起 |
| Android Crash多次 |  | heshengpeng(彭和胜) | 2026-01-14 | 告警成功 | flutter 播放器Crash，毛神处理中 | P0 | 进行中 |
| 【核心业务】1分钟内同一用户crash数超过2次 |  | bryanpeng(彭超) | 2026-01-08 | 告警成功 | 一分钟crash两次  https://bugly.woa.com/v2/exception/crash/issues/list?productId=ef14bfff8f&pid=2&token=bf13fc38838771d3baf0edc06e51b659 |  | 挂起 |
| 【最新版本】【start量级波动】【路由和AppStart】【大流量】【1h】【6k~10w】对比前1m波动42% |  | bryanpeng(彭超) | 2026-01-11 | 告警成功 | 信鸽推送引起，正常 |  | 挂起 |
| Android 网络失败增加 /role/match/getpopuserlist |  | heshengpeng(彭和胜) | 2026-01-19 | 告警成功 |  |  | 挂起 |
| 【错误指标-分版本】小流量-1h（80+~600）-单模块start量级对比前1m上涨60%   chatserver/sendsinglechatmessage |  | bryanpeng(彭超) | 2026-01-20 | 告警成功 | 发言频率过高，已处理 |  | 已完成 |
| Android 图片加载失败增加 |  | heshengpeng(彭和胜) | 2026-01-19 | 告警成功 |  |  |  |
| Android 图片加载失败增加 |  | heshengpeng(彭和胜) | 2026-01-19 | 告警成功 | 529884190单用户引起，尝试修复一版加载失败 | P0 | 已完成 |
| 【错误指标-分系统】连续1次-大流量-1h（6k+~10w）-单模块start量级对比前1m分钟上涨8.5%  告警数据时间: 2026-01-18 22:25:00 | leviyin(尹恒宇) | bryanpeng(彭超) | 2026-01-19 | 告警成功 | 主要是登录的几个OneApi报错突增，这几个都是图灵盾自动获取当前手机号的错误码，静默 |  | 已完成 |
| 【敏捷告警】【错误指标-分版本】连续2次-大流量-1h（600+~6k）-单模块start量级对比前1m分钟上涨15%  h5.nes.smoba.qq.com |  | bryanpeng(彭超) | 2026-01-20 | 告警成功 | 看起来也是promise的报错，看看是否需要关注 |  | 进行中 |
| 【核心业务】1小时内同一用户crash数超过10次 | elioyin(银川) | bryanpeng(彭超) | 2026-01-19 | 告警成功 | 单用户10次崩溃 https://bugly.woa.com/v2/exception/crash/issues/detail?productId=ef14bfff8f&pid=2&token=c0d15669396059e4696de521921e129b&feature=C9D6FBEB9E36D507ABCE9DF1600BAC09&cId=A904E6A9-0A9A-4ED6-82A8-D210922951D5 |  | 进行中 |
| 【敏捷告警】【错误指标-分版本】连续2次-大流量-1h（600+~6k）-单模块start量级对比前1m分钟上涨15% | bobihuang(黄腾) | bryanpeng(彭超) | 2026-01-19 | 告警成功 | （promise 异常）,不影响展示 |  | 进行中 |
| Android 图片加载失败增加 |  | heshengpeng(彭和胜) | 2026-01-16 | 告警成功 |  |  | 已完成 |
| 【App不可用】【暂时屏蔽】整个App指标全面报错，可能是服务器全挂了或者某个业务超高频率失败 |  | bryanpeng(彭超) | 2026-01-15 | 告警成功 | H5Page报错(MSDK服务挂了)，群里已反馈 https://pvp.qq.com/mall/m/index.html?biz=yxzj&ADTAG=pvp.helper.ydmall.link&_source=mall#/ |  | 进行中 |
| 【start量级波动】【路由和AppStart】【新版本】【大流量】【1h】【10w~100w】对比前1m波动5% | bryanpeng(彭超) | bryanpeng(彭超) | 2026-01-15 | 告警成功 | 调整新版本版本号(0114)引起 |  | 已完成 |
| Android H5Page 失败增加 |  | heshengpeng(彭和胜) | 2026-01-15 | 告警成功 | H5Page报错，已反馈处理中；MSDK服务挂了一会 | P0 | 已完成 |
| Android 图片加载失败增加 |  | heshengpeng(彭和胜) | 2026-01-15 | 告警成功 | 3个用户引起的突刺，socket timeout、reset；直播间聊天预请求图片 | P0 | 挂起 |
| 【App不可用】【暂时屏蔽】整个App指标全面报错，可能是服务器全挂了或者某个业务超高频率失败 | bryanpeng(彭超) | bryanpeng(彭超) | 2026-01-14 | 告警成功 | 新上线新增的H5Page ModuleEnd没有区分warning和error，导致报错突增 |  | 已完成 |
| 【核心业务】视频播放失败1小时超过500次 | bryanpeng(彭超) | bryanpeng(彭超) | 2026-01-14 | 告警成功 | 直播过期 http://openhls-hw.douyucdn2.cn/live/3014399r4sgj9CDb.m3u8?txSecret=0256b1e2d2cee11d0f386b114e51fbb3&txTime=6960d693&token=cpg-tengxun-0-3014399-ba0a8bd7fc8c56ca7eeccf63a02f3a79&did=&origin=dy&vhost=play2&sid=425233912&tp=36a6dbf4&ll=wzyd |  | 已完成 |
| Android 网络失败增加 /user/addfriend | joinyin(尹泽宇), dozhai(翟东) | heshengpeng(彭和胜) | 2026-01-14 | 告警成功 | 1571372991单用户引起 | P0 | 进行中 |
| Android 网络失败增加 /user/getcampfriendsonline | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-01-13 | 告警成功 | 用户触发授权，导致页面刷新，正常流程 |  | 挂起 |
| Android 图片加载失败增加 |  | heshengpeng(彭和胜) | 2026-01-08 | 告警成功 | 404，老问题没屏蔽掉 |  | 已完成 |
| Android 图片加载失败增加 |  | heshengpeng(彭和胜) | 2026-01-08 | 告警成功 | 1774038683单用户引起，404，老问题没屏蔽掉 | P0 | 已完成 |
| Android H5Page 失败增加 |  | heshengpeng(彭和胜) | 2026-01-08 | 告警成功 | 是不是要屏蔽掉，都是JS错误，Android量级相比iOS大一些，到达阈值告警；干扰太大了 | P0 | 已完成 |
| Android 扫码转化率波动 |  | heshengpeng(彭和胜) | 2026-01-08 | 告警成功 | 中间的突刺引发了两次波动告警；用户分散不集中，部分是扫码王者赛宝的二维码，大部分没有扫码结果，主动退出，行为正常 |  | 已完成 |
| Android 大图告警  https://static.gametalk.qq.com/image/18/1767776015_d2b5ca33bd970f64a6301fa75ae2eb22.png https://static.gametalk.qq.com/image/18/1767775985_d2b5ca33bd970f64a6301fa75ae2eb22.png |  | heshengpeng(彭和胜) | 2026-01-08 | 告警成功 | 运营配置大图 | P0 | 挂起 |
| [异常] 【核心业务】大图加载1小时大于100次 |  | bryanpeng(彭超) | 2026-01-07 | 告警成功 | 合理 https://static.gametalk.qq.com/image/18/1767170232_790ecca04d0341f3e2454813f9e97bda.jpg |  | iOS已完成 |
| Android 150ms内多次发起请求：/supergroupchat/getmsgnotice |  | heshengpeng(彭和胜) | 2026-01-07 | 告警成功 | 1893639511单用户引起 |  | 进行中 |
| 【核心业务】1分钟内同一用户crash数超过2次 |  | bryanpeng(彭超) | 2026-01-06 | 告警成功 | 键盘连续崩溃 https://bugly.woa.com/v2/exception/crash/issues/detail?productId=ef14bfff8f&pid=2&token=30a362a6ed2887fd998e1132f178f0f8&feature=AA990E86F1695BB8D97FF431B10229AE&cId=3AF741A1-32FF-460F-9D83-CBB37F217F69 |  |  |
| Android 大图告警 https://static.gametalk.qq.com/image/18/1767665369_d2b5ca33bd970f64a6301fa75ae2eb22.png https://static.gametalk.qq.com/image/18/1767665359_d2b5ca33bd970f64a6301fa75ae2eb22.png https://static.gametalk.qq.com/image/18/1767669088_d2b5ca33bd970f64a6301fa75ae2eb22.png https://static.gametalk.qq.com/image/18/1767170232_790ecca04d0341f3e2454813f9e97bda.jpg |  | heshengpeng(彭和胜) | 2026-01-06 | 告警成功 | 运营配置大图 | P0 | 挂起 |
| Android 150ms内多次发起请求：/app/button/list | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-01-06 | 告警成功 | native请求，请求参数一致 |  | 进行中 |
| Android 图片加载失败增加 | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2026-01-06 | 告警成功 | 1831680504单用户引起，单图片 |  | 进行中 |
| Android 图片加载失败增加 | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2026-01-06 | 告警成功 | 2125899431单用户引起，unknownHost， |  | 进行中 |
| 用户1分钟连续crash （1219） | bryanpeng(彭超) | bryanpeng(彭超) | 2026-01-05 | 告警成功 | Flutter std::_fl::__function::__func<skia::textlayout::TextLine::getGlyphPositionAtCoordinate https://bugly.woa.com/v2/exception/crash/issues/detail?productId=ef14bfff8f&pid=2&token=c02bd1532766bc82d6c355b65e2dd3a1&feature=678CDE3C2FD581BE29308F9F2AB9AFA1&cId=22600776-78A5-45BA-9DD1-CF907380EF01 |  | 挂起 |
| Android 上报指标报错陡增，APP自升级下载失败 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-11-17 | 告警成功 | 获取新版本APK文件的路径失败，差量合成失败并且全量下载也失败时才会触发 | P0 | 挂起 |
| user/realnamecheck 协议报错陡增（小流量） | bryanpeng(彭超) | bryanpeng(彭超) | 2025-11-17 | 告警成功 | -52007, msg:输入的证件格式不正确 :-52001, msg:当日验证次数已用完，请明日再试 -52003, msg:当前提交信息和账号实名认证信息不匹配 |  | 已完成 |
| Android 网络请求失败增加 /game/morebattlelist | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-11-17 | 告警成功 | 后台返回码-91004，战绩拉取失败，datamore那边的架构缺陷导致，历史问题：每天凌晨两点左右，会有短暂的战绩列表超时 |  | 挂起 |
| Android 网络请求失败增加 /game/watchBattle | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-11-17 | 告警成功 | 直播观战结束，复合预期 |  | 挂起 |
| Android SpanStatistic按版本告警 | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-11-17 | 告警成功 | 版本升级上量 |  | 挂起 |
| Android 内部路由成功flutter?url=/game_partner 陡降 | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-11-17 | 告警成功 | 伽利略平台问题导致数据异常导致告警 |  | 挂起 |
| Android AutoLogin按版本告警 | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-11-17 | 告警成功 | 版本升级上量，这种情况加个限制，前60分钟>=20 |  | 挂起 |
| game/morebattlelist 协议报错陡增 | bryanpeng(彭超) | bryanpeng(彭超) | 2025-11-17 | 告警成功 | datamore那边的架构缺陷导致，历史问题：每天凌晨两点左右，会有短暂的战绩列表超时 |  | 已完成 |
| 【核心业务】1分钟内同一用户crash数超过2次 （ipad上PAG的连续崩溃） | bryanpeng(彭超) | bryanpeng(彭超) | 2025-11-17 | 告警成功 | https://bugly.woa.com/v2/exception/crash/issues/detail?productId=ef14bfff8f&pid=2&token=b5940c22402419c25b0404ba65f66c9d&feature=6DF7E517ED5FE52BEC03384C0E3E8034&cId=139168F7-514E-400F-96D9-A3C2A195EA22 |  | 挂起 |
| Android Crash陡增告警 | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-11-14 | 告警成功 | 单用户Crash引起，Crash上报没过滤，因为有延迟，导致同一次进程出现多次上报 |  | 已完成 |
| Android 单用户连续Crash 5次 | joinyin(尹泽宇), jasonmao(毛建伟) | heshengpeng(彭和胜) | 2025-11-14 | 告警成功 | https://bugly.woa.com/v2/exception/crash/issues/detail?productId=a8b16c44b9&pid=1&token=a275454be75dca582ee6847483d9350b&feature=6633490CD475FF56E1912EE5FA3B341F&cId=5fa27f72-0eda-41a7-ba0e-ea341f790721 |  | 挂起 |
| Android 单用户连续Crash 3次 | joinyin(尹泽宇), jasonmao(毛建伟) | heshengpeng(彭和胜) | 2025-11-14 | 告警成功 | https://bugly.woa.com/v2/exception/crash/issues/detail?productId=a8b16c44b9&pid=1&token=f21982fe9f43675bffb1209760861a76&feature=78D2F23EA2E214870D0ECACAEE569216&cId=17f3f932-69d2-4223-9b23-25adcf7a35da |  | 挂起 |
| iOS -1001抖动报错，很奇怪（game/authinfo），客户端请求发送失败，没到后台 |  | bryanpeng(彭超) | 2025-11-13 | 告警成功 | -1001，有一波剧烈抖动报错，继续观察下 |  | 挂起 |
| 1分钟内同一用户crash数超过2次,这个例子里是多次（tgfx::GLGpu::submitToGpu(bool)(） | bryanpeng(彭超) | bryanpeng(彭超) | 2025-11-13 | 告警成功 | PAG的连续崩溃 https://bugly.woa.com/v2/exception/crash/issues/detail?productId=ef14bfff8f&pid=2&token=0e130c73bed1b6f5ecf67d1c1c180308&feature=6DF7E517ED5FE52BEC03384C0E3E8034 |  | 挂起 |
| iOS图片加载失败 https://camp.qq.com/star-member/avatar/star-member-avatar1.png | jsagsagwen(温昊昱) | bryanpeng(彭超) | 2025-11-13 | 告警成功 | 未能找到使用指定主机名的服务器 |  |  |
| Android 信鸽注册失败陡增 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-11-12 | 告警成功 | tpns后台服务问题，已恢复 |  | 挂起 |
| 1分钟内同一用户crash数超过2次, 视频编辑相关 | qmwang(王清明) | bryanpeng(彭超) | 2025-11-10 | 告警成功 | 连续崩溃 https://bugly.woa.com/v2/exception/crash/issues/detail?productId=ef14bfff8f&pid=2&token=370e9804a783faedb0a10a8b769d39d3&feature=97974C3CFEA080296270C6601D5DD04D&cId=1B624B3E-0D2E-448A-9B3A-82FC4DF3FA43 |  |  |
| 1分钟内同一用户crash数超过2次,这个例子里是多次（Flutter(search_initial_page)相关,进一步和oneApi参数非法有关） | leihongchen(陈鹏翔), xinyuming(明新宇) | bryanpeng(彭超) | 2025-11-10 | 告警成功 | 连续崩溃https://bugly.woa.com/v2/exception/crash/issues/list?productId=ef14bfff8f&pid=2&token=c4bf9a0192ad21ea845b81e340ea1dbf |  | 已完成 |
| 大量接口出现量级波动：【start量级波动】【错误】【15min】环比波动100% | bryanpeng(彭超) | bryanpeng(彭超) | 2025-11-10 | 告警成功 | 伽利略上报日志本身掉了很多数据 |  | 挂起 |
| iOS图片加载失败 https://camp.qq.com/battle/profile/starsV2/0-0.png | jsagsagwen(温昊昱) | bryanpeng(彭超) | 2025-11-10 | 告警成功 | 已反馈后台上传图片处理 |  | 已完成 |
| Android 网络请求失败增加 /game/morebattlelist | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-11-10 | 告警成功 | 后台返回码-91004，datamore那边的架构缺陷导致，历史问题：每天凌晨两点左右，会有短暂的战绩列表超时 |  | 挂起 |
| Android 启动量级增加 |  | heshengpeng(彭和胜) | 2025-11-10 | 告警成功 | 闪屏广告配置， |  | 挂起 |
| Android 网络请求失败增加 /app/txvideo/refresh |  | heshengpeng(彭和胜) | 2025-11-10 | 告警成功 | 伽利略服务引起 |  | 挂起 |
| Android 网络请求失败增加 /pay/getbalance | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-11-10 | 告警成功 | KPL决赛 |  | 挂起 |
| Android 网络请求失败陡增 /chatserver/sendsinglechatmessage | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-11-10 | 告警成功 | 单个用户非法发言引起的失败，errorCode=-30099, errorMsg='您发送的信息非法,请注意言行' | P0 | 挂起 |
| Android 网络请求失败陡增 /app/txvideo/login |  | heshengpeng(彭和胜) | 2025-11-10 | 告警成功 | -140444:登陆失败；QQ票据过期，导致腾讯视频鉴权失败 | P0 | 挂起 |
| Android 自动登录量级突降 |  | heshengpeng(彭和胜) | 2025-11-10 | 告警成功 | 双端这个时间点上报量级都有下降，游戏内电视台总决赛流量突增，导致伽利略公网服务出现异常导致数据丢失 | P0 | 挂起 |
| iOS 网络请求失败增加 /pay/getbalance | bryanpeng(彭超) | bryanpeng(彭超) | 2025-11-10 | 告警成功 | -50000，midas token失效 |  | 挂起 |
| iOS【App不可用】【暂时屏蔽】整个App指标全面报错，可能是服务器全挂了或者某个业务超高频率失败,3min后大波告警即将来袭 | leviyin(尹恒宇) | bryanpeng(彭超) | 2025-11-10 | 告警成功 | 还是Hippy的social模块启动报错占大头；抓日志排查中，groupName = social暂时关闭 |  | 进行中 |
| iOS 网络请求失败增加 role/setlogingametag | bryanpeng(彭超) | bryanpeng(彭超) | 2025-11-10 | 告警成功 | 后台保护锁，正常 |  | 挂起 |
| iOS 网络请求失败增加 game/morebattlelist | bryanpeng(彭超) | bryanpeng(彭超) | 2025-11-10 | 告警成功 | 偶现，主要客户端不稳定 |  | 挂起 |
| iOS 网络请求失败增加 app/txvideo/login | bryanpeng(彭超) | bryanpeng(彭超) | 2025-11-10 | 告警成功 | 下游不稳定，-140444 |  | 挂起 |
| Android 启动量级增加 |  | heshengpeng(彭和胜) | 2025-11-10 | 告警成功 | KPL决赛 | P0 | 挂起 |
| Android 图片加载失败陡增 |  | heshengpeng(彭和胜) | 2025-11-10 | 告警成功 | 重复问题，处理中，1029优化一波 | P0 | 挂起 |
| 误报：同一用户10次crash | bryanpeng(彭超) | bryanpeng(彭超) | 2025-11-06 | 告警成功 | userId为空的情况进行保护，误报 |  | 已完成 |
| 触发了一分钟两次crash的告警,flutter sdk的告警 | ricoyang(杨鈜宇) | bryanpeng(彭超) | 2025-11-06 | 告警成功 | https://bugly.woa.com/v2/exception/crash/issues/list?productId=ef14bfff8f&pid=2&token=ca15981fe60cea145af31b3e48932efa | P0 | 挂起 |
| 平台出问题，grokAlarmType字段筛选不出来，会暂时影响依赖该字段的各告警 | bryanpeng(彭超) | bryanpeng(彭超) | 2025-11-06 | 告警成功 | 已拉群跟进 | P0 | 已完成 |
| Android 网络请求失败告警 /user/login |  | heshengpeng(彭和胜) | 2025-11-06 | 告警成功 | 后台DB问题导致告警，已恢复 |  | 挂起 |
| Android 异常Span量级SpanStatistic突增告警 |  | heshengpeng(彭和胜) | 2025-11-06 | 告警成功 | 后台DB问题导致告警，已恢复 |  | 挂起 |
| Android Crash突增告警 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-11-06 | 告警成功 | 后台DB问题导致告警，已恢复；终端需要兼容处理下，防止数据解析Crash | P0 | 已完成 |
| Android 网络请求失败告警 /game/friends | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-11-06 | 告警成功 | 后台DB问题导致告警，已恢复 | P0 | Oncalling |
| Android 网络请求失败告警 /game/friends | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-11-05 | 告警成功 | 压测引起 | P0 | 挂起 |
| iOS 150ms内多次请求 user/genrandname | leviyin(尹恒宇) | bryanpeng(彭超) | 2025-11-04 | 存量优化 | 用户每次输入后就会发接口请求，应该要加防抖 |  | 已完成 |
| iOS 150ms内多次请求 supergroup/getmylist | elioyin(银川) | bryanpeng(彭超) | 2025-11-04 | 存量优化 | 有地方出现较多次的调用，见图 |  | 已完成 |
| iOS 150ms内多次请求 info/getmgamecardsreserve | jimwzhou(周维), ryzenwwang(王睿) | bryanpeng(彭超) | 2025-11-04 | 存量优化 | 次数很多，外加还有报错 |  | 已完成 |
| iOS 150ms内多次请求 esports/getuserlatestmatch | jimwzhou(周维), ryzenwwang(王睿) | bryanpeng(彭超) | 2025-11-04 | 存量优化 | 次数很多，可重点看看 |  | 已完成 |
| iOS 150ms内多次请求 user/registeruserinfo | magicwu(吴家庆) | bryanpeng(彭超) | 2025-11-03 | 存量优化 | 用户每次输入后就会发接口请求，应该要加防抖 |  | 符合预期 |
| iOS 150ms内多次请求  user/getprivacymenu | xinyuming(明新宇) | bryanpeng(彭超) | 2025-11-03 | 存量优化 | 次数很多，可重点看看 |  | 符合预期 |
| iOS 150ms内多次请求 role/match/heartbeat | owenncwang(汪年成) | bryanpeng(彭超) | 2025-11-03 | 存量优化 | 可确认下是否正常 |  | 已完成 |
| 瞬时出现大量Hippy的social module报错 | leviyin(尹恒宇) | bryanpeng(彭超) | 2025-11-03 | 告警成功 | 暂未定位到问题。 |  | 进行中 |
| game/battlestoragestatus 一小时报错超过5000次 | bryanpeng(彭超) | bryanpeng(彭超) | 2025-11-03 | 告警成功 | -10109, 客态战绩隐藏，可排除 |  | 已完成 |
| game/curseasonpage 一小时报超过5000次 | bryanpeng(彭超) | bryanpeng(彭超) | 2025-11-03 | 告警成功 | -30408，主态战绩隐藏，可排除 |  | 已完成 |
| iOS 150ms内多次请求 info/live/recommend | jimwzhou(周维) | bryanpeng(彭超) | 2025-11-03 | 存量优化 | 多次调用，比较严重 |  | 已完成 |
| iOS 150ms内多次请求 campcontent/gallery/getgallerylistv2 | owenncwang(汪年成) | bryanpeng(彭超) | 2025-11-03 | 存量优化 | 多次调用，比较严重 |  | 符合预期 |
| iOS 150ms内多次请求 gametoolbox/game/accelerator/info  (启动游戏面板） | owenncwang(汪年成) | bryanpeng(彭超) | 2025-11-03 | 存量优化 | 多次调用，比较严重 |  | 未完成 |
| iOS 150ms内多次请求 supergroupchat/getchatroomofflinemessagedown | elioyin(银川) | bryanpeng(彭超) | 2025-11-03 | 存量优化 | 多次调用，比较严重，需要确认下是否合理 |  | 已完成 |
| iOS 150ms内多次请求 moment/gethomepagesubjectlist | jimwzhou(周维) | bryanpeng(彭超) | 2025-11-03 | 存量优化 | 多次调用 |  | 已完成 |
| iOS 150ms内多次请求 user/getusernearbyuserid | leihongchen(陈鹏翔) | bryanpeng(彭超) | 2025-11-03 | 存量优化 | 多次调用 |  | 已完成 |
| iOS 150ms内多次请求 user/getprivacymenu | xinyuming(明新宇) | bryanpeng(彭超) | 2025-11-03 | 存量优化 | 连续调用多次，比较严重 |  | 符合预期 |
| iOS 150ms内多次请求 user/getbevisitsbygo | qcxiang(向乾操) | bryanpeng(彭超) | 2025-11-03 | 存量优化 | 连续调用 |  | 已完成 |
| iOS 150ms内多次请求 role/match/interactive/quit | owenncwang(汪年成) | bryanpeng(彭超) | 2025-11-03 | 存量优化 | 连续调用 |  | 已完成 |
| iOS 150ms内多次请求 user/checklogin | jsagsagwen(温昊昱) | bryanpeng(彭超) | 2025-11-03 | 存量优化 | 概率会连续checklogin |  | 挂起 |
| iOS 150ms内多次请求 app/game/setting | jsagsagwen(温昊昱) | bryanpeng(彭超) | 2025-11-03 | 存量优化 | 登录页有时候会连续调用两次 |  | 符合预期 |
| iOS 150ms内多次请求 game/infotopbanner | jimwzhou(周维), ryzenwwang(王睿) | bryanpeng(彭超) | 2025-11-03 | 存量优化 | 看起来比较严重 |  | 已完成 |
| iOS 150ms内多次请求 supergroup/position/getpositionlist | jsagsagwen(温昊昱) | bryanpeng(彭超) | 2025-11-03 | 存量优化 | 有地方会连续调用n次，需要确认下是否正常 |  | 符合预期 |
| iOS 150ms内多次请求 supergroup/entersupergroup | jsagsagwen(温昊昱) | bryanpeng(彭超) | 2025-11-03 | 存量优化 | 有地方会连续调用n次，需要确认下是否正常 |  | 符合预期 |
| iOS 150ms内多次请求 a/getanniversaryconf | jsagsagwen(温昊昱) | bryanpeng(彭超) | 2025-11-03 | 存量优化 | 打开个人主页会访问两次 |  |  |
| iOS 150ms内多次请求 game/curseasonpage | jimwzhou(周维), jobswu(吴晗) | bryanpeng(彭超) | 2025-11-03 | 存量优化 | 看了下战绩列表页打开的时候会访问两次 |  | 符合预期 |
| Android 网络请求失败告警 /game/morebattlelist | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-11-03 | 告警成功 | -91004:战绩列表拉取失败，看着是后台服务问题， join确认下呢 |  | 挂起 |
| Android 图片加载失败陡增 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-11-03 | 告警成功 | 用户没有聚类 |  |  |
| [__NSArrayM objectAtIndexedSubscript:]: index 3 beyond bounds [0 .. 2] | elioyin(银川) | bryanpeng(彭超) | 2025-10-29 | 告警成功 | 看起来是系统键盘的一个崩溃，目前没有好办法 同一个用户短时间崩溃3次。键盘相关。聊天https://galileo.woa.com/service/session?module_name=camp-app&platform=iOS&moduleId=-13533164&timeRange=now%2Fd~now%2Fd&env=2&orgId=tencent&combinedFields=%7B%22other_tags%22%3A%5B%7B%22filter_type%22%3A1%2C%22name%22%3A%22uid%22%2C%22values%22%3A%5B%221560923389%22%5D%2C%22type%22%3A%22uid%22%7D%5D%7D | P0 | 挂起 |
| Android 用户反馈每日福利加载不出来 | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-11-06 | 代码有bug | 没有触发loadUrl，webView没有加载，中间信息丢失，需要再补充些信息 |  | 已完成 |
| iOS网络相关的告警逻辑之前的ret_code，logic_code，server_code,local_code之间组合有问题 | bryanpeng(彭超) | bryanpeng(彭超) | 2025-10-29 | 代码有bug | 部分网络报错上报不准确，或者会漏掉一些（1029上） |  | 已完成 |
| Android tenthAnniversaryWeb上报量级陡降 |  | heshengpeng(彭和胜) | 2025-10-29 | 告警成功 | 预期，和join沟通，周年庆功能下线 | P0 | 挂起 |
| Android  /game/battledetail 部分预加载请求参数错误 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-27 | 告警成功 | 复现路径：启动后，打开战绩详情页，会出现部分预加载请求参数错误 |  |  |
| 外部路由跳转pvp.qq.com和camp.qq.com失败 | bryanpeng(彭超) | bryanpeng(彭超) | 2025-10-27 | 告警成功 | 和前端确认没有pvp.qq.com和camp.qq.com，少部分系统（13，14）机型重定向影响. 已关闭 | P0 | 已完成 |
| 跳转外部路由camp.qq.com失败 |  | bryanpeng(彭超) | 2025-10-20 | 告警成功 | camp.qq.com直接点击也打不开，这个是什么场景？并且跳转这个就没有成功的，一定失败，一条成功的都没有 |  | 已完成 |
| Android 150ms内多次发起请求：/user/donateprop | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-27 | 告警成功 | 增加click 点击间隔 | P0 | 已完成 |
| Android 网络请求失败突增  /info/getrecommendbycontentid | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-26 | 告警成功 | 晚会开始，流量突增 | P0 | 挂起 |
| Android 网络请求失败突增 /search/getassociate | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-26 | 告警成功 | 搜索服务问题，后台已处理 | P0 | 已完成 |
| Android 网络请求失败突增 /moment/getsubjectfeedlist | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-26 | 告警成功 | 晚会开始，流量突增 | P0 | 挂起 |
| Android 网络请求失败突增 /app/txvideo/login | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-26 | 告警成功 | 晚会开始，流量突增 | P0 | 挂起 |
| Android 网络请求失败突增 /app/getappscreenads | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-26 | 告警成功 | 晚会开始，流量突增 | P0 | 挂起 |
| Android 网络请求失败突增 /game/battledetail | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-25 | 告警成功 | 后台数据库异常导致，只有Android受影响，同时这个请求还存在150ms频繁请求的问题 | P0 | 已完成 |
| Android 网络请求失败突增 /user/getfriendmgamerolelist | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-25 | 告警成功 | 请求被cancel了，符合预期，后台db 扩容 |  | 挂起 |
| Android 网络请求失败突增 /user/getfriendallrolelist | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-25 | 告警成功 | 请求被cancel了，符合预期，后台db 扩容 |  | 挂起 |
| Android 网络请求失败突增 /esports/getuserlatestmatch | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-25 | 告警成功 | 符合预期，后台db 扩容 |  | 挂起 |
| Android 网络请求失败突增 /game/rolelist | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-25 | 告警成功 | 符合预期，后台db 扩容 | P0 | 挂起 |
| Android 网络请求失败突增 /game/authorize | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-25 | 告警成功 | 符合预期，后台db 扩容 | P0 | 挂起 |
| Android 网络请求失败突增 /game/authinfo | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-25 | 告警成功 | 符合预期，后台db 扩容 | P0 | 挂起 |
| Android 网络请求失败突增 /operation/lotterygetgift |  | heshengpeng(彭和胜) | 2025-10-25 | 告警成功 | 符合预期，后台db 扩容 | P0 | 挂起 |
| Android 外部路由拉起游戏陡增 |  | heshengpeng(彭和胜) | 2025-10-25 | 告警成功 | 周年庆，启动进入游戏，复合预期 | P0 | 挂起 |
| 异常Span上报量增加 | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-10-25 | 告警成功 | 网络请求失败陡增导致携带请求参数 |  | 挂起 |
| Android 网络请求响应过大告警 /game/itempage/skinlist | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-25 | 告警成功 | 网络响应过大（预期的），请求量上升 |  | 挂起 |
| Android 150ms内多次发起请求：/mall/lobby | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-25 | 告警成功 |  |  |  |
| Android 150ms内多次发起请求：/game/checkallreddot | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-25 | 告警成功 | 属于正常表现，一次请求关注红点 ，一次请求首页红点 ，一共两次 |  | 挂起 |
| Android 150ms内多次发起请求：/mall/coupon/getdjccoupon | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-25 | 告警成功 | 同个接口，不同请求参数 |  | 挂起 |
| Android 网络请求失败突增 /userprofile/managementprofile | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-25 | 告警成功 | 符合预期，网络请求数量飙升导致后台压力巨大 | P0 | 挂起 |
| Android 网络请求失败突增 /user/getphoneusers | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-25 | 告警成功 | 符合预期，网络请求数量飙升导致后台压力巨大 | P0 | 挂起 |
| Android 网络请求失败突增 /pay/getbalance | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-25 | 告警成功 | 符合预期，网络请求数量飙升导致后台压力巨大 | P0 | 挂起 |
| Android 网络请求失败突增 /esports/getuserlatestmatch | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-25 | 告警成功 | 周年庆陡增 | P0 |  |
| Android 外部路由拉起游戏陡增 |  | heshengpeng(彭和胜) | 2025-10-25 | 告警成功 | 过0点，拉起游戏进活动 | P0 | 挂起 |
| Android 网络请求失败突增 /game/authinfo | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-25 | 告警成功 | 周年庆徒增，后续需要优化多tab 调用问题 | P0 | 进行中 |
| Android tenthAnniversaryWeb 陡增 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-25 | 告警成功 | 周年庆相关上报，25号零点开始放开，导致突增 | P0 | 挂起 |
| Android 图片加载失败陡增 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-24 | 告警成功 | 有地方配置了url为空，导致失败陡增 图片1: https://static.gametalk.qq.com/image/18/1761296030_72dc78d0e1bcf6b574f417af8391706f.jpg 图片2: https://static.gametalk.qq.com/image/18/1760444886_a69ca94c30f5134cabc98f6a813c0202.jpg | P0 | 挂起 |
| Android 150ms内多次发起请求：/game/getreserve | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-24 | 告警成功 | flutter oneApi过来的请求，目前看参数一致 |  |  |
| Android 网络请求失败突增 /info/getmgamecardsreserve | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-24 | 告警成功 | -115227:不支持该渠道；运营配置有问题，重新配置 | P0 | 已完成 |
| Android 图片加载失败下降 | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-10-24 | 告警成功 | 双端这个时间点上报量级都有波动，确认是伽利略平台问题 | P0 | 挂起 |
| Android 路由download_manager陡增 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-23 | 告警成功 | OS白名单下发，触发游戏下载导致上涨 |  | 挂起 |
| Android 图片加载失败陡增 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-23 | 告警成功 | 图片url无法访问 | P0 | 挂起 |
| Android 网络请求失败突增 /user/getcampfriendsinfo |  | heshengpeng(彭和胜) | 2025-10-22 | 告警成功 | 压测引起 |  | 挂起 |
| Android 网络请求失败突增 /user/getcampfriendsinfo |  | heshengpeng(彭和胜) | 2025-10-22 | 告警成功 | 压测引起 |  | 挂起 |
| Android 网络请求失败突增 /user/getfriendmgamerolelist |  | heshengpeng(彭和胜) | 2025-10-22 | 告警成功 | 压测引起 |  | 挂起 |
| Android 网络请求失败突增 /game/authinfo |  | heshengpeng(彭和胜) | 2025-10-22 | 告警成功 | 压测引起 |  | 挂起 |
| Android 网络请求失败突增 /game/friends |  | heshengpeng(彭和胜) | 2025-10-21 | 告警成功 | 压测引起 |  | 挂起 |
| 自动登录失败在凌晨4点30分有一波突增 |  | bryanpeng(彭超) | 2025-10-21 | 告警成功 | （压测）自动登录失败突增。主要是一个-50000的errorCode（后台压测） |  | 已完成 |
| mall/package/querycampitemrecord 【敏捷波动p0】告警 |  | bryanpeng(彭超) | 2025-10-21 | 告警成功 | 连续请求，严重。 单用户请求了200多次 | P0 | 已完成 |
| 大图告警 https://static.gametalk.qq.com/image/18/1760513114_25a0f66550f76485fb460d6cb420846e.jpg |  | bryanpeng(彭超) | 2025-10-21 | 告警成功 | 无需处理，合理的大图 |  | 已完成 |
| iOS跳转前端有时候正常，有时候异常，有时候时间对不上的问题 | bryanpeng(彭超) | bryanpeng(彭超) | 2025-10-20 | 告警成功 | 新方式：参数带到链接里面给了！ 客户端有cookie且能够对上哦 https://galileo.woa.com/service/session?module_name=camp-app&platform=iOS&moduleId=-13533164&timeRange=now%2Fd~now%2Fd&q=ff096929bff322a721921f93 |  | 已完成 |
| BackGroundKill连续上报 | bryanpeng(彭超) | bryanpeng(彭超) | 2025-10-20 | 告警成功 | 这个问题量级降低到之前的20分之一左右，还在持续下降，但还有一些零散的场景；飞机包会上报这个但是不会kill，被宏隔开了；实际改到没待继续观察 |  | 已完成 |
| Android 150ms内多次发起请求：/info/episode/report | jasonmao(毛建伟) | heshengpeng(彭和胜) | 2025-10-20 | 告警成功 | TVK上报时长，有点像代码上的bug 历史代码： InfoTVKFullScreenPlayerActivityLand TVKPlayerFragment 两个地方有同时触发暂停和播放时长上报，暂停上报内部又会触发播放时长上报 |  | 挂起 |
| Android 150ms内多次发起请求：/moment/usermoments | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-20 | 告警成功 | 1829506152用户操作引起 | P0 | 已完成 |
| Android 150ms内多次发起请求：/user/setprivacy | magicwu(吴家庆) | heshengpeng(彭和胜) | 2025-10-20 | 告警成功 | 1862037117用户操作引起 | P0 | 挂起 |
| Android 150ms内多次发起请求：/moment/usermoments | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-20 | 告警成功 | 1857365392用户操作引起 | P0 | 已完成 |
| Android 网络请求失败突增 /operation/lotterygetgift | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-20 | 告警成功 | 运营活动，用户抢购商品，导致用户在相同时间点触发 | P0 | 挂起 |
| Android 网络请求失败突增 /chatserver/sendsinglechatmessage | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-20 | 告警成功 | 用户连续发送笑话消息，造成了请求频繁，未做限频可连续点击 | P0 | 挂起 |
| （iOS）150ms内多次发起请求：game/getuserselffeedlist（7天过期，后面分批次重开解决） |  | bryanpeng(彭超) | 2025-10-17 | 告警成功 | user/getkingcalendar\ | user/getusernoticesetting\ | operation/seqloginsigninfo\ |
| （iOS）150ms内多次发起请求：user/getphoneusers（7天过期，后面分批次重开解决） |  | bryanpeng(彭超) | 2025-10-17 | 告警成功 |  |  | 挂起 |
| （iOS）150ms内多次发起请求：operation/seqloginsigninfo（7天过期，后面分批次重开解决） |  | bryanpeng(彭超) | 2025-10-17 | 告警成功 |  |  | 挂起 |
| （iOS）150ms内多次发起请求：user/getusernoticesetting（7天过期，后面分批次重开解决） |  | bryanpeng(彭超) | 2025-10-17 | 告警成功 |  |  | 挂起 |
| （iOS）150ms内多次发起请求：game/setsinglechathavereadmsg（7天过期，后面分批次重开解决） |  | bryanpeng(彭超) | 2025-10-16 | 告警成功 |  |  | 挂起 |
| （iOS）150ms内多次发起请求：user/getkingcalendar（7天过期，后面分批次重开解决） |  | bryanpeng(彭超) | 2025-10-16 | 告警成功 |  |  | 挂起 |
| （iOS）150ms内多次发起请求：game/authinfo（7天过期，后面分批次重开解决） |  | bryanpeng(彭超) | 2025-10-16 | 告警成功 | game/getuserselffeedlist\ | chatserver/offacc/list\ | game/authinfo |
| （iOS）150ms内多次发起请求：chatserver/offacc/list（7天过期，后面分批次重开解决） |  | bryanpeng(彭超) | 2025-10-16 | 告警成功 |  |  | 挂起 |
| （iOS）150ms内多次发起请求：app/txvideo/refresh （7天过期，后面分批次重开解决） |  | bryanpeng(彭超) | 2025-10-16 | 告警成功 |  |  | 挂起 |
| （iOS）150ms内多次发起请求：game/getuserselffeedlist（7天过期，后面分批次重开解决） |  | bryanpeng(彭超) | 2025-10-16 | 告警成功 |  |  | 挂起 |
| Android 网络请求失败突增 /operation/urlwhitelist | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-16 | 告警成功 | 继续观察 |  | 挂起 |
| （iOS）/game/checkallreddot  红点连续请求问题 |  | bryanpeng(彭超) | 2025-10-16 | 告警成功 | 发现这个接口连续调用几十次 |  | 挂起 |
| （iOS）150ms内多次发起请求：game/morebattlelist（7天过期，后面分批次重开解决） |  | bryanpeng(彭超) | 2025-10-16 | 告警成功 | supergroupchat/getmsgnotice\ | user/synccampfriends\ | play/gettaskconditiondata\ |
| （iOS）150ms内多次发起请求：supergroupchat/getmsgnotice（7天过期，后面分批次重开解决） |  | bryanpeng(彭超) | 2025-10-16 | 告警成功 | 先静默至1115. |  | 挂起 |
| （iOS）150ms内多次发起请求：user/getfriendallrolelist （7天过期，后面分批次重开解决） |  | bryanpeng(彭超) | 2025-10-16 | 告警成功 | 先静默1115 |  | 挂起 |
| （iOS）150ms内多次发起请求：user/synccampfriends（7天过期，后面分批次重开解决） | elioyin(银川) | bryanpeng(彭超) | 2025-10-16 | 告警成功 | 先静默1115 |  | 挂起 |
| （iOS）150ms内多次发起请求：play/gettaskconditiondata（7天过期，后面分批次重开解决） |  | bryanpeng(彭超) | 2025-10-16 | 告警成功 | 合理的直接屏蔽 |  | 挂起 |
| （iOS）150ms内多次发起请求：app/button/get（7天过期，后面分批次重开解决） |  | bryanpeng(彭超) | 2025-10-16 | 告警成功 | 先静默1115 |  | 挂起 |
| （iOS）150ms内多次发起请求：app/easyconf/getjson（7天过期，后面分批次重开解决） |  | bryanpeng(彭超) | 2025-10-16 | 告警成功 | 先静默1115 |  | 挂起 |
| （iOS）150ms内多次发起请求：app/redpoint/get（7天过期，后面分批次重开解决） |  | bryanpeng(彭超) | 2025-10-16 | 告警成功 | 先静默1115 |  | 挂起 |
| （iOS）150ms内多次发起请求：game/video/manage（7天过期，后面分批次重开解决） |  | bryanpeng(彭超) | 2025-10-16 | 告警成功 | 先静默1115 |  | 挂起 |
| （iOS）150ms内多次发起请求：app/txvideo/vipinfo（7天过期，后面分批次重开解决） |  | bryanpeng(彭超) | 2025-10-16 | 告警成功 | 先静默1115 |  | 挂起 |
| （iOS）150ms内多次发起请求：app/txvideo/login（7天过期，后面分批次重开解决） |  | bryanpeng(彭超) | 2025-10-16 | 告警成功 | 先静默 |  | 挂起 |
| （iOS）150ms内多次发起请求：user/getcampfriendsinfo（7天过期，后面分批次重开解决） |  | bryanpeng(彭超) | 2025-10-16 | 告警成功 | 先静默 |  | 挂起 |
| Android 网络请求失败突增 /esports/getuserlatestmatch |  | heshengpeng(彭和胜) | 2025-10-16 | 告警成功 | 限时活动，引发流量激增 |  | 挂起 |
| 网络请求start 上报监控：补上报或现有的Span能不能转成指标、后台网关能不能做到监控 |  |  | 2025-11-20 | 新增未建设 | 转伽利略需求； | P0 | 进行中 |
| OneApi error需要支持告警，调整为告警上报 |  | heshengpeng(彭和胜), bryanpeng(彭超) | 2025-11-03 | 新增未建设 |  | P0 | 已完成 |
| Android  伽利略SDK会支持上报数据压缩 |  | heshengpeng(彭和胜) | 2025-10-16 | 新增未建设 | 伽利略排期在建设；Android 1112更新SDK，支持 gzip | P0 | 已完成 |
| 如果启动就Crash 伽利略信息丢失的问题 |  | bryanpeng(彭超), heshengpeng(彭和胜) | 2025-10-16 | 新增未建设 | 考虑伽利略初始化提前、 | P0 | 已完成 |
| iOS延时上报功能不全，需要接入上报模块和手动初始化(灰度上) |  | bryanpeng(彭超) | 2025-10-15 | 新增未建设 | 暂时对我们影响不大，可以先不接入 |  | 挂起 |
| Android 150ms内多次发起请求：/info/bullet/get | jasonmao(毛建伟) | heshengpeng(彭和胜) | 2025-10-16 | 告警成功 | 放映-剧集页面内可以切换视频，每次切换视频都会重新监听播放进度并尝试拉取弹幕接口，多次切换后会产生多个监听者。 | P0 | 已完成 |
| Android 150ms内多次发起请求：/game/infosubcomments | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-16 | 告警成功 | 接口返回hasMore总是true导致，后端说暂时不用处理 | P0 | 挂起 |
| SmobaHelper.WEGGangUpMatchManager【核心业务】1小时内同一用户crash数超过10次 | owenncwang(汪年成) | bryanpeng(彭超) | 2025-10-14 | 告警成功 | 很不错！！！，修改配置，这边立即告警了，避免了范围内的crash，这个很不错 |  | 已完成 |
| Feedback上报的数据并未正常出现在水晶平台？？？ |  | bryanpeng(彭超) | 2025-10-14 | 告警成功 | 有两层block，一层是黑名单，有些ifeedback平台都不知道被block了 |  | 已完成 |
| Android 网络请求突增 /game/reportvideoplayv2，-20011 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-14 | 告警成功 |  |  | 挂起 |
| label_limited_gmzz图片加载失败 |  | bryanpeng(彭超) | 2025-10-14 | 告警成功 |  |  | 挂起 |
| 信鸽推送infodetail时，app打开量级上涨，图片加载失败也上涨 |  | heshengpeng(彭和胜) | 2025-10-14 | 告警成功 | 用户头像加载为空string，兼容下 |  | 已完成 |
| 精简Trace参数，优化成本。1. 串联后台的trace报的全参数导致的问题，已经优化 2. 精简优化所有参数 | bryanpeng(彭超) | bryanpeng(彭超) | 2025-10-11 | 新增未建设 | 成功降低整个成本的3分之一 |  | 已完成 |
| 新的更清晰的Trace堆栈模式 | bryanpeng(彭超) | bryanpeng(彭超) | 2025-10-11 | 新增未建设 |  |  | 已完成 |
| 整理下目前的错误指标，Top的是否要优化 |  |  | 2026-04-02 | 存量优化 |  |  |  |
|  |  |  | 2026-04-02 | 存量优化 |  |  |  |
| crash日志上报域名优化 |  |  | 2025-12-25 | 存量优化 |  |  | 已完成 |
| 维度治理期间，告警了大概20条左右 | bryanpeng(彭超) | bryanpeng(彭超) | 2025-12-24 | 存量优化 | 日50w+降到了20w左右 |  | 已完成 |
| iOS内部路由rawUri长度大于1w优化 |  | bryanpeng(彭超) | 2025-12-18 | 存量优化 | 推荐人列表都带在router里，已知合理 |  | iOS已完成 |
| Android 内部路由rawUri长度大于1w优化 | leviyin(尹恒宇) | heshengpeng(彭和胜) | 2025-12-18 | 存量优化 | 设计如此， 集中在flutter?url=/info_detail和gallerydetail两个路由，带了其他参数在uri上 |  | 挂起 |
| Android 150ms内多次发起请求：/game/getreserve（目前的Top1了） | joinyin(尹泽宇), wolfhuang(黄鑫) | heshengpeng(彭和胜) | 2025-12-04 | 存量优化 | 前端优化中；flutter oneApi过来的请求，参数一致 |  | 已完成 |
| Android 内部路由uri为空（其他场景） | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-12-04 | 存量优化 |  |  | 进行中 |
| iOS 150ms内多次发起请求：game/rolecard | qcxiang(向乾操) | bryanpeng(彭超) | 2025-12-03 | 存量优化 |  |  |  |
| iOS 150ms内多次发起请求：info/infohotsubject | jimwzhou(周维) | bryanpeng(彭超) | 2025-12-03 | 存量优化 |  |  |  |
| iOS 150ms内多次发起请求：user/getmostviewuserlistflutter | leihongchen(陈鹏翔) | bryanpeng(彭超) | 2025-12-03 | 存量优化 |  |  |  |
| iOS 150ms内多次发起请求：mall/coupon/getdjccoupon | jimwzhou(周维) | bryanpeng(彭超) | 2025-12-03 | 存量优化 |  |  |  |
| iOS 150ms内多次发起请求：app/getmetadata | jsagsagwen(温昊昱) | bryanpeng(彭超) | 2025-12-03 | 存量优化 |  |  |  |
| iOS 150ms内多次发起请求：gametoolbox/equip/herosuit/getbysync | jimwzhou(周维) | bryanpeng(彭超) | 2025-12-03 | 存量优化 |  |  |  |
| iOS 150ms内多次发起请求：game/refreshvideo | elioyin(银川) | bryanpeng(彭超) | 2025-12-03 | 存量优化 | feeds卡的符合预期，精彩时刻的转给川哥看 |  | 已完成 |
| iOS 150ms内多次发起请求：user/reqnoticeinfo | elioyin(银川) | bryanpeng(彭超) | 2025-12-03 | 存量优化 |  |  |  |
| iOS 150ms内多次发起请求：user/findfriends | jsagsagwen(温昊昱) | bryanpeng(彭超) | 2025-12-03 | 存量优化 |  |  |  |
| iOS 150ms内多次发起请求：user/setprivacy | qcxiang(向乾操) | bryanpeng(彭超) | 2025-12-03 | 存量优化 |  |  |  |
| iOS 150ms内多次发起请求：game/likeBattleVideo | bryanpeng(彭超) | bryanpeng(彭超) | 2025-12-03 | 存量优化 | 点赞没有限制频率，2s累加后上报 |  | 已完成 |
| iOS 150ms内多次发起请求：user/getchurnpred | jsagsagwen(温昊昱) | bryanpeng(彭超) | 2025-12-02 | 存量优化 |  |  |  |
| iOS 150ms内多次发起请求：user/mgame/getfriendallchatsetting | jsagsagwen(温昊昱) | bryanpeng(彭超) | 2025-12-02 | 存量优化 |  |  |  |
| iOS 150ms内多次发起请求：user/checkaccesstoken | jsagsagwen(温昊昱) | bryanpeng(彭超) | 2025-12-02 | 存量优化 |  |  |  |
| iOS 150ms内多次发起请求：game/ongoingBattleInfo | jsagsagwen(温昊昱) | bryanpeng(彭超) | 2025-12-02 | 存量优化 |  |  |  |
| iOS 150ms内多次发起请求：game/koh/profile | jsagsagwen(温昊昱) | bryanpeng(彭超) | 2025-12-02 | 存量优化 |  |  |  |
| iOS 150ms内多次发起请求：user/getkingcalendar | qcxiang(向乾操) | bryanpeng(彭超) | 2025-12-02 | 存量优化 | 符合预期 |  |  |
| iOS 150ms内多次发起请求：moment/getsubjectfeedlist | jimwzhou(周维) | bryanpeng(彭超) | 2025-12-02 | 存量优化 |  |  |  |
| iOS 150ms内多次发起请求：user/getmgameprivacymenu | qcxiang(向乾操) | bryanpeng(彭超) | 2025-12-02 | 存量优化 |  |  |  |
| iOS 150ms内多次发起请求：moment/getaccesscredentials | jsagsagwen(温昊昱) | bryanpeng(彭超) | 2025-12-02 | 存量优化 |  |  |  |
| 上报shiply 任务id时，发现会命中NGR等相关的配置项 |  | heshengpeng(彭和胜) | 2025-11-27 | 存量优化 | 等启动器下个版本发布后，再做清理 | P0 | Oncalling |
| Android 150ms内多次发起请求：/user/getbefriendsbygo | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-11-24 | 存量优化 | 请求参数一样，预请求和oneApi同时触发了，预请求不合理 |  | 进行中 |
| Android 150ms内多次发起请求：/info/infohotsubject | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-11-24 | 存量优化 | OneApi请求，请求参数都是一样的 |  | 进行中 |
| Android 150ms内多次发起请求：/user/getcampfriendsinfo | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-11-24 | 存量优化 | 请求参数不一致，屏蔽 |  | 已完成 |
| Android 150ms内多次发起请求：/game/roleinfo | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-11-24 | 存量优化 | 待观察，看着是云通讯的调用 |  | 挂起 |
| Android 150ms内多次发起请求：/game/video/manage | elioyin(银川) | heshengpeng(彭和胜) | 2025-11-24 | 存量优化 | OneApi请求，请求参数相差一个status字段，确认是否符合预期 |  | 已完成 |
| Android 150ms内多次发起请求：/game/koh/profile | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-11-24 | 存量优化 | 跟前端沟通属于正常表现，在切游戏 |  | 挂起 |
| Android 150ms内多次发起请求：/supergroupchat/getmysupergroupmuteinfo | kitli(李汶婷) | heshengpeng(彭和胜) | 2025-11-24 | 存量优化 | 请求参数一样 |  | 已完成 |
| Android 150ms内多次发起请求：/game/getuserselffeedlist | xinyuming(明新宇) | heshengpeng(彭和胜) | 2025-11-24 | 存量优化 | 个人主页在陆续放量了，不在对老的做处理了 |  | 挂起 |
| Android 150ms内多次发起请求：/chatserver/chatsessionheart | kitli(李汶婷) | heshengpeng(彭和胜) | 2025-11-24 | 存量优化 | 请求参数一样 |  | 挂起 |
| Android 聊天页面图片加载url为空 | kitli(李汶婷) | heshengpeng(彭和胜) | 2025-11-24 | 存量优化 | 随机看了几个用户，看着都是在聊天页下的 |  | 已完成 |
| Android OneApi 找不到问题处理（确认是否需要处理） | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-11-24 | 存量优化 | 部分oneapi 已经修复1126版本，剩余1210 版本修复 |  | 已完成 |
| Android Flutter页面多次error上报确认是否符合预期 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-11-21 | 存量优化 | 一个OneApi的，一个是flutterFrament里的 |  | 已完成 |
| Android 150ms内多次发起请求：/app/getappscreenads | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-11-18 | 存量优化 | 启动场景会概率性命中，请求两次, 启动还存在 |  | 进行中 |
| Android 150ms内多次发起请求：/app/button/get | joinyin(尹泽宇), wolfhuang(黄鑫), bobihuang(黄腾) | heshengpeng(彭和胜) | 2025-11-18 | 存量优化 | OneApi请求，请求参数都是一样的，必现，前端bug |  | 进行中 |
| Android 150ms内多次发起请求：/game/morebattlelist | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-11-18 | 存量优化 | OneApi请求，请求参数不一样，过滤掉 |  | 已完成 |
| Android 150ms内多次发起请求：/play/gettaskconditiondata | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-11-18 | 存量优化 | 用户快速切tab触发上报导致，快速操作可复现，非必现 |  | 已完成 |
| Android 150ms内多次发起请求：/app/easyconf/getjson | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-11-17 | 存量优化 | native请求，请求参数不一样，过滤掉 |  | 已完成 |
| Android 150ms内多次发起请求：/user/getuserinfo | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-11-17 | 存量优化 | native请求，云通信消息 触发 |  | 挂起 |
| Android 150ms内多次发起请求：/user/getuserphonegroup | joinyin(尹泽宇), xinyuming(明新宇) | heshengpeng(彭和胜) | 2025-11-17 | 存量优化 | OneApi请求，请求参数都是一样的，本地切换账号能复现 |  | 待讨论 |
| Android 150ms内多次发起请求：/operation/seqloginsigninfo | joinyin(尹泽宇), xinyuming(明新宇) | heshengpeng(彭和胜) | 2025-11-17 | 存量优化 | OneApi请求，请求参数都是一样的，本地切换账号能复现 |  | 待讨论 |
| Android 150ms内多次发起请求：/user/getphoneusers | joinyin(尹泽宇), xinyuming(明新宇) | heshengpeng(彭和胜) | 2025-11-17 | 存量优化 | OneApi请求，请求参数都是一样的，本地切换账号能复现 |  | 待讨论 |
| Android 150ms内多次发起请求：/app/redpoint/get | joinyin(尹泽宇), leihongchen(陈鹏翔) | heshengpeng(彭和胜) | 2025-11-17 | 存量优化 | native发起的请求，请求参数是一样的，估计有泄露 |  | 进行中 |
| Android 150ms内多次发起请求：/game/authinfo | joinyin(尹泽宇), xinyuming(明新宇) | heshengpeng(彭和胜) | 2025-11-17 | 存量优化 | 切换/添加账号出现，本地能复现，估计有泄露 |  | 待讨论 |
| Android 图片加载失败 量级较大，url为空string |  | heshengpeng(彭和胜) | 2025-10-11 | 存量优化 | 继续推动处理中，1112修复电视台下降不少 |  | 已完成 |
| 外部路由成功率下降，拉起游戏APP失败 |  | heshengpeng(彭和胜) | 2025-10-10 | 告警成功 |  |  |  |
| 告警异常case统一屏蔽处理，可通过管道在一个地方配置 | bryanpeng(彭超), heshengpeng(彭和胜) | bryanpeng(彭超), heshengpeng(彭和胜) | 2025-10-09 | 新增未建设 |  |  | 已完成 |
| 告警分级 | bryanpeng(彭超), heshengpeng(彭和胜) | bryanpeng(彭超), heshengpeng(彭和胜) | 2025-10-09 | 新增未建设 |  |  | 已完成 |
| PAG 加载失败增量告警 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-09 | 告警成功 | Socket超时+DNS解析失败 |  |  |
| Android 网络请求失败突增 /esports/getuserlatestmatch | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-09 | 告警成功 |  |  |  |
| Android 网络请求失败突增 /user/getfriendmgamerolelist | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-09 | 告警成功 |  |  |  |
| Android 网络请求失败突增 /game/getreserve |  | heshengpeng(彭和胜) | 2025-10-09 | 告警成功 | 前端+OneApi  bug，oneApi改动未向前兼容，后台拉起oncall已转需求处理 | P0 | Oncalling |
| Android 150ms内多次发起请求：/user/donatecoin | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-09 | 告警成功 |  |  |  |
| Android 150ms内多次发起请求：/moment/getsubjectfeedlist | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-10-20 | 告警成功 | 推送信鸽会触发量级上升，Hippy请求，请求间隔相差几十ms；属于预期，hippy会一次性加载2个tab导致2次请求 | P0 | 挂起 |
| Android 150ms内多次发起请求：/role/match/getpopuserlist | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-09 | 告警成功 |  |  |  |
| Android 150ms内多次发起请求：/moment/getsubcommentlist | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-10-09 | 告警成功 |  |  | 已完成 |
| Android 150ms内多次发起请求：/mall/package/querycampitemrecord | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-09-28 | 告警成功 |  |  |  |
| 新增网络变化的Trace上报 | bryanpeng(彭超), heshengpeng(彭和胜) | bryanpeng(彭超) | 2025-10-09 | 新增未建设 |  |  | 已完成 |
| Android 线上用户自动/手动登录 失败 32.5w个设备，失败率10%左右，需要分析下 | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-11-27 | 存量优化 |  |  |  |
| Android 150ms内多次发起请求：/game/infohotcomments  推送信鸽后重复请求导致告警，前端OneAPi请求 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-09-28 | 告警成功 | 代码bug，已优化 |  | 已完成 |
| [首次异常] 1小时内同一用户crash数超过两次（TGA横屏转屏，引导在26上出现） |  | bryanpeng(彭超) | 2025-09-28 | 代码有bug | 成功告警发现问题 |  | 已完成 |
| 伽利略提供时间线的能力，可以更方便的看span发生的前后顺序 |  | bryanpeng(彭超) | 2025-09-28 | 伽利略需求/使用问题 |  |  | 挂起 |
| 外部路由短时间内出现较多报错 |  | bryanpeng(彭超) | 2025-09-28 | 告警成功 |  |  | 已完成 |
| 短时间登录出现大量微信token刷新失败的报错。 注意：图中-1不全是登录的，但-2都是 |  | bryanpeng(彭超) | 2025-09-28 | 存量优化 | 是那天压测的问题 |  | 已完成 |
| hero-hot-list Hippy加载报错量较大(hippy上报本身也有问题0917才上修复版本)，等10月下旬再看看 | bryanpeng(彭超) | bryanpeng(彭超) | 2025-09-28 | 代码有bug |  |  | 已完成 |
| 网络请求失败存在是一些path是pvp视频、图片下载失败，导致基数高 | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-09-24 | 存量优化 | 目前上报失败是包括了所有的原生请求，所以从日志管道处理下，降低基数 |  | 已完成 |
| Android 150ms内多次发起请求：/game/likeBattleVideo  告警成功 | bryanpeng(彭超) | heshengpeng(彭和胜) | 2025-09-24 | 告警成功 |  |  | 已完成 |
| Shiply上报优化（尝试上报taskId、精简configValue，减少成本） | heshengpeng(彭和胜), bryanpeng(彭超) | heshengpeng(彭和胜), bryanpeng(彭超) | 2025-09-25 | 存量优化 |  |  | 已完成 |
| 伽利略平台使用问题 提诉求 |  | bryanpeng(彭超) | 2025-09-25 | 伽利略需求/使用问题 |  |  | 已完成 |
| Android 150ms内多次发起请求：/supergroupchat/clearnotice  告警成功 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-09-25 | 告警成功 |  |  | 进行中 |
| Android 150ms内多次发起请求：/user/isinwhitelist | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-12-04 | 存量优化 | 代码设计问题，可以优化；问题还存在 |  | 进行中 |
| Android 150ms内多次发起请求：/play/getsmobaassists | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-09-23 | 存量优化 | 首页AppStartEventDispatcher泄露，添加账号和切换账号多次回调导致频繁请求 |  | 已完成 |
| Android 150ms内多次发起请求：/supergroupchat/clearnotice | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-12-04 | 存量优化 | 问题还存在 |  | 进行中 |
| 150ms内多次发起请求：/user/getbevisitsbygo 误报 | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-09-23 | 代码有bug | 预加载请求导致，按callStart开始检测，没有真正发起请求，1029修复下 |  | 已完成 |
| Android 150ms内多次发起请求：/app/redpoint/get （概率性出现，150ms 2次） | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-09-23 | 存量优化 | 首页-我（个人面板） |  | 挂起 |
| Android 150ms内多次发起请求：/game/receivedmessage | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-09-23 | 存量优化 | 接收消息时候会给服务器上报 一条当前状态已读 |  | 挂起 |
| 【 end结束前指标-end转化率波动超过2.5 】同类问题 1. smobagamehelper://flutter?url=/flutter_privacy_switch_route 2. smobagamehelper://flutter?url=/friend_apply_detail | bryanpeng(彭超) | bryanpeng(彭超) | 2025-09-22 | 告警成功 | start不对，0917已修复 |  | 已完成 |
| 【 end结束前指标-end转化率波动超过2.5 】smobagamehelper://flutter?url=/webview&props=https://camp.qq.com/h5/webdist/welfare-center/index.html | bryanpeng(彭超) | bryanpeng(彭超) | 2025-09-22 | 告警成功 | 最新版本start1000，end只有10了。start取了替换后的，end反而反向取了替换前的 |  | 已完成 |
| App耗电问题,后台长期运行消耗用户电量 | grassxiao(肖友), bryanpeng(彭超) | bryanpeng(彭超) | 2025-09-22 | 告警成功 | 个人主页的视频的问题 |  | 已完成 |
| 出现了两个版本都是isLatestApp，出现了告警，是否还有必要最新版本的监控？，会出现很多误告警（没重启的用户） |  | bryanpeng(彭超) | 2025-09-22 | 新增未建设 | 流程变化：通过管道来定义新版本，排除干扰，只是在发版当天需要手动修改这个值（流程变化） |  | 已完成 |
| https://camp.qq.com/game-zone/imgs/left-arrow-new.png?imageView2/format/webp |  | bryanpeng(彭超) | 2025-09-22 | 告警成功 |  |  | Oncalling |
| label_limited_common |  | bryanpeng(彭超) | 2025-09-22 | 告警成功 |  |  | Oncalling |
| https://game-1255653016.file.myqcloud.com/profile/master/wings/1.png |  | bryanpeng(彭超) | 2025-09-22 | 告警成功 |  |  | Oncalling |
| https://camp.qq.com/game-zone/imgs/right-arrow-new.png?imageView2/format/webp |  | bryanpeng(彭超) | 2025-09-22 | 告警成功 |  |  | Oncalling |
| 图片加载失败 label_limited_FMVP |  | bryanpeng(彭超) | 2025-09-22 | 告警成功 | 非url的一个图片加载失败，需要具体排查 |  | Oncalling |
| 图片加载失败https://camp.qq.com/battle/profile/starsV2/0-0.png |  | bryanpeng(彭超) | 2025-09-22 | 告警成功 | 看起来是图片在server上已经没有了 |  | Oncalling |
| 获取名片素材接口异常，耗时非常高 | bryanpeng(彭超) | bryanpeng(彭超) | 2025-09-22 | 代码有bug | 这里开黑有退后台的动作，应该是较慢的接口如果退台就会出现这种情况，应该算合理，但也可以优化，如果要优化，需要拉对应业务同学 |  | 已完成 |
| 0917 OneEvent事件存在没有接收者的情况 | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-09-18 | 存量优化 | 可能是合理的 |  | 挂起 |
| 打开采样后，转换率抖动变大 | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-09-18 | 代码有bug | 采样是针对单次上报，容易对转化率造成抖动；改为对启动采样和用户采样 |  | 已完成 |
| Android内部路由报错，uri为空 | heshengpeng(彭和胜), joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-09-17 | 存量优化 | 订阅号界面的，ButtonHandler |  | 已完成 |
| 伽利略告警 通知点击 认领或者静默后，能否针对当前告警的维度进行，而非整个策略 | bryanpeng(彭超), heshengpeng(彭和胜) | bryanpeng(彭超), heshengpeng(彭和胜) | 2025-09-18 | 伽利略需求/使用问题 |  |  | 进行中 |
| Splash这种类型的波动告警应该怎么来处理？正向告警？ | heshengpeng(彭和胜), bryanpeng(彭超) | bryanpeng(彭超), heshengpeng(彭和胜) | 2025-09-17 | 新增未建设 | 阶段性指标从大盘监控排除，单独监控项建立告警 |  | 挂起 |
| end结束前指标-end转化率波动超过0.85  AppUpgrade，splash，信鸽合理？（阶段性的问题，大盘排除，可能info功能） |  | bryanpeng(彭超) | 2025-09-17 | 新增未建设 | 和信鸽一样，看起来是合理的。有波动反而正常？？ |  | 已完成 |
| 1.InnerRouter 的 default  2.smobagamehelper://web?url=://pagedoo.pay.qq.com/s2/one | bryanpeng(彭超) | bryanpeng(彭超) | 2025-09-17 | 代码有bug | 部分内部路由start缺失，只有replace和end' |  | 已完成 |
| smobagamehelper://hippy?modulename=personal； smobagamehelper://flutter?url=/medal  tags.groupName: smobagamehelper://hippy?modulename=battle   等2个问题 | bryanpeng(彭超) | bryanpeng(彭超) | 2025-09-17 | 代码有bug | 中间换链了，走了jsReplace或者locationReplace，处理应该上报原始的 |  | 已完成 |
| 内部路由转换率报错  https://camp.qq.com | bryanpeng(彭超) | bryanpeng(彭超) | 2025-09-15 | 存量优化 | router的start和end不一致导致的问题，非换链;所有camp.qq.com等开头的都存在类似问题 |  | 已完成 |
| 外部路由报错 https://help.wechat.com | jsagsagwen(温昊昱), bryanpeng(彭超) | bryanpeng(彭超) | 2025-09-15 | 存量优化 | 跳转外部路由，end status报错 （登录点击weixin登录，拉起微信时，没weixin会报；原因 微信安装状态做了缓存）,阈值升级解决 |  | 挂起 |
| 外部路由报错 weixin://dl | jsagsagwen(温昊昱), bryanpeng(彭超) | bryanpeng(彭超) | 2025-09-15 | 存量优化 | 跳转外部路由，end status报错（没weixin会报），阈值升级解决 |  | 挂起 |
| Android /app/txvideo/refresh错误优化 | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-09-10 | 存量优化 | qq或者wx票据失效，目前qq没有主动刷新能力；要不要优化为每次启动后校验票据，失效则拉起重新授权 |  | 挂起 |
| 注册指标end口径调整，昵称不合法可能一直重试 | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-09-11 | 代码有bug | 0917 end的时机改为注册页dispose，但实际测下来跳转原生时可能不执行 | P0 | 已完成 |
| 大图 |  | bryanpeng(彭超) | 2025-09-11 | 存量优化 |  |  | 已完成 |
| 图片加载报错存在很多url都是空的情况 | jsagsagwen(温昊昱) | bryanpeng(彭超) | 2025-09-11 | 存量优化 |  |  | 已完成 |
| Android 出现部分内部路由rawUri参数不合法 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-09-10 | 存量优化 | 先观察；内部会将url重定向为web的，但就是会报一次路由失败 |  | 挂起 |
| Flutter 基础&核心指标 建设 |  | bryanpeng(彭超) | 2026-02-05 | 新增未建设 |  |  | 进行中 |
| 基础&核心指标  补全step异常情况，一定要补全所有情况 |  |  | 2026-01-22 | 新增未建设 |  |  | 已完成 |
| 路由指标特殊，end只报异常 |  |  | 2026-01-22 | 新增未建设 | iOS看成本情况，如果不报end，会有一些span没有 |  | android已完成 |
| 单点的status状态不全，需要建设 |  |  | 2026-01-21 | 新增未建设 | 看板建好了，关注下数据 |  | 已完成 |
| Android 使用cookie串联存在bug的问题，要不要也切换到url的形式 |  | heshengpeng(彭和胜) | 2026-01-08 | 新增未建设 | Android切换url风险太大，保留cookie模式，优化cookie匹配问题 |  | 已完成 |
| php请求后台看不到参数，终端补参数，开关控制，默认关 |  | heshengpeng(彭和胜), bryanpeng(彭超) | 2025-11-27 | 新增未建设 |  | P0 | 已完成 |
| 聊天消息Socket  msgId支持跟对账 | bryanpeng(彭超), heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-11-24 | 新增未建设 | 补充消息对账上报，信息少一点，对账够用就行 |  |  |
| jsbridge外部跳转的问题 | grassxiao(肖友) | bryanpeng(彭超) | 2025-09-11 | 告警成功 | 暂不处理 |  | 挂起 |
| pvp.qq.com | bryanpeng(彭超) | bryanpeng(彭超) | 2025-09-10 | 存量优化 | Router跳转失败,需补充一些信息; web有些无法跳转无法使用前端串联的能力 |  | 已完成 |
| case：用户点击一次扫码登录，但是打开了2次扫码页面（偶现）；如何监控这类问题，类似的问题（用户短时间多条重复的指标上报）如何监控； |  | heshengpeng(彭和胜), bryanpeng(彭超) | 2026-03-26 | 告警未覆盖 | 兜底方案：在伽利略底层总入口处添加频率检查，让每个模块都有检测短时间重复上报的能力，需要检测到参数这一级，要检测哪些参数名都需要支持配置 |  |  |
| 新版本、阶段性、小流量： 新版本：人均指标量级，新旧版本差值对比，试行中（新旧版本短期手动更新，长期Lego触发更新） 阶段性：H5Page、游戏下载 小流量： 归0判断：连续2h归0告警 |  | heshengpeng(彭和胜) | 2026-02-05 | 告警未覆盖 | 1. 人均上报次数（模块量级/版本用户数），环比上一个版本（两周前），moduleName陡增、陡降几倍 2. AB组同量级用户对比，A组灰度用户，B组线上用户 |  | 进行中 |
| 战绩列表一直loadMore，Android没有正常发起请求，上报量级的监控功能 |  | heshengpeng(彭和胜), bryanpeng(彭超) | 2025-11-18 | 告警未覆盖 | 网络请求的Case目前没有告警能力，只做了失败的；同时暴露其他已有指标针对版本的环比（新版本字段没有使用）；按版本告警目前只针对Top5进行；环比上一周？目前都是同比前1m | P0 | 挂起 |
| 一分钟一次Crash告警没有监控到 | heshengpeng(彭和胜), bryanpeng(彭超) | heshengpeng(彭和胜) | 2025-09-10 | 告警未覆盖 | 目前只配了1m连续2次Crash告警，未覆盖到 | P0 | 已完成 |
| game/itempage/herolist 2130/h | bryanpeng(彭超) | bryanpeng(彭超) | 2025-09-10 | 存量优化 | 网络响应过大 1.49M |  | 挂起 |
| game/itempage/skinlist	7881/h | bryanpeng(彭超) | bryanpeng(彭超) | 2025-09-10 | 存量优化 | 网络响应过大 1.48M |  | 挂起 |
| game/battledetail 910/h（不能正确跳转span，需要看看，协议span和trace没完全对齐1017） |  | bryanpeng(彭超) | 2025-09-10 | 存量优化 | 之前上报有问题不准确，后续重新抓取，接口报错 （-1001，-900001） |  | 挂起 |
| game/checkallreddot 928/h |  | bryanpeng(彭超) | 2025-09-10 | 存量优化 | 之前上报有问题不准确，后续重新抓取，接口报错（-1005，-1001，-90001，-1017） |  | 挂起 |
| app/txvideo/refresh 1075/h | bryanpeng(彭超) | bryanpeng(彭超) | 2025-09-10 | 存量优化 | 之前上报有问题不准确，后续重新抓取，接口报错（见后面地址），1. 走cache的时候逻辑不正常 2. 修复App刚启动网络不可用的保护和重试逻辑 |  | 已完成 |
| app/easyconf/batchgetjson 1190/h |  | bryanpeng(彭超) | 2025-09-10 | 存量优化 | 之前上报有问题不准确，后续重新抓取，接口报错（见后面地址） |  | 挂起 |
| chatserver/offline/singlemsg 1243/h |  | bryanpeng(彭超) | 2025-09-10 | 存量优化 | 之前上报有问题不准确，后续重新抓取，接口报错（见后面地址） |  | 挂起 |
| game/authinfo 1295/h | jsagsagwen(温昊昱) | bryanpeng(彭超) | 2025-09-10 | 存量优化 | 之前上报有问题不准确，后续重新抓取，接口报错（-1001、-1009、-1005、-1005） |  | 挂起 |
| app/easyconf/getjson 1305/h |  | bryanpeng(彭超) | 2025-09-10 | 存量优化 | 之前上报有问题不准确，后续重新抓取，接口报错（见后面地址） |  | 挂起 |
| play/gettaskconditiondata 1790/h | jsagsagwen(温昊昱) | bryanpeng(彭超) | 2025-09-10 | 存量优化 | 之前上报有问题不准确，后续重新抓取，接口报错（-1001、-1009、-1005、-1005） |  | 挂起 |
| app/redpoint/get	1930/h | jsagsagwen(温昊昱) | bryanpeng(彭超) | 2025-09-10 | 存量优化 | 之前上报有问题不准确，后续重新抓取，接口报错（-1001、-1009、-1005、-1005） |  | 挂起 |
| user/getclientip 2614/h | grassxiao(肖友) | bryanpeng(彭超) | 2025-09-09 | 存量优化 | 接口报错（见后面地址） |  | 挂起 |
| 长链接换链失败（/app/urlshorten） | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-08-18 | 告警未覆盖 | 小流量告警之前确实没有做 iOS：7天总共63次报错上报 Android：8月16日按分钟级看有明显的业务失败异常，但是没达到告警的条件，目前告警条件是对比前1分钟失败次数陡增100 & 1分钟内的量级> 100 | P0 | 已完成 |
| 大王卡状态获取报错告警 | bryanpeng(彭超) | bryanpeng(彭超) | 2025-08-18 | 新增未建设 | 直接调用的AFHTTPSessionManager，没有走通用逻辑 | P1 | 已完成 |
| R群新增路由跳转不生效 | bryanpeng(彭超), heshengpeng(彭和胜) | bryanpeng(彭超) | 2025-08-18 | 新增未建设 | 之前Router的End没有上报，这类告警暂时告不出来 | P0 | 已完成 |
| 0820 版本网络测试，/info/listinfov2接口触发2次请求，非必现 | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-08-18 | 代码有bug | 网络库拦截器catch范围过广，网络IO异常被提前catch住，无法获取真实的errorMsg，导致上报到灯塔和伽利略后，只知道失败，不知道为啥失败 | P1 | 已完成 |
| Android 网络请求失败无法细分具体错误类型 | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-08-21 | 代码有bug | 网络请求失败没有做过错误码细分 | P0 | 已完成 |
| 伽利略网络请求和后台对账 | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-08-25 | 新增未建设 | 目前只上报了失败，所有网络请求待放开 | P0 | 已完成 |
| Router：camp.qq.com跳转失败问题 | bryanpeng(彭超) | bryanpeng(彭超) | 2025-08-25 | 告警成功 | router替换导致start和end的groupName不一样，修改逻辑 |  | 已完成 |
| Router：chat_new跳转失败 |  | bryanpeng(彭超) | 2025-08-27 | 告警成功 |  |  | 已完成 |
| H5打开失败 | bryanpeng(彭超), heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-09-03 | 新增未建设 | 容器的关键信息预埋还没建设 | P0 | 已完成 |
| 登录相关的场景没有覆盖全；用户登录问题定位 | bryanpeng(彭超), heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-09-03 | 新增未建设 | 重新登录的触发场景有很多（用户主动登录、接口返回登录态失效、js返回Token失效、强制下线等），需要陆续覆盖 | P0 | 已完成 |
| tencent-daojucheng://webpage | bryanpeng(彭超), nbiepu(蒲以均) | bryanpeng(彭超) | 2025-09-05 | 告警成功 |  |  | 挂起 |
| smobagamehelper://web?url=://camp.qq.com/h5/webdist/wallet-order/index.html | bryanpeng(彭超) | bryanpeng(彭超) | 2025-09-18 | 代码有bug | Flutter web的，1.只走了start，部分没有走end，router问题 |  | 已完成 |
| 用户反馈，荣耀榜页面报错 | heshengpeng(彭和胜), bryanpeng(彭超) | heshengpeng(彭和胜) | 2025-11-24 | 新增未建设 | 目前没有上报页面出错，后续补一下。UI报错页面 | P0 |  |
| 周年庆相关  关键信息、指标预埋 | heshengpeng(彭和胜), bryanpeng(彭超) | heshengpeng(彭和胜) | 2025-09-15 | 新增未建设 |  | P0 | 已完成 |
| Android网络响应过大的问题 | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-09-10 | 存量优化 |  |  | 挂起 |
| 图片加载失败尝试增加page信息做细分 |  | bryanpeng(彭超), heshengpeng(彭和胜) | 2026-01-29 | 告警未覆盖 |  |  | 已完成 |
| 告警通知如果根据ModuleName进行不同的分发和通知 |  | bryanpeng(彭超) | 2026-01-22 | 告警未覆盖 | 1.和伽利略同学沟通讨论支持 2. 回调到lego支持？ |  | 进行中 |
| H5Page类型的告警需要单独告警到群里 |  | bryanpeng(彭超), heshengpeng(彭和胜) | 2026-01-22 | 告警未覆盖 |  |  | 已完成 |
| 归0告警新增 |  | bryanpeng(彭超) | 2026-01-15 | 告警未覆盖 |  |  | 已完成 |
| start类的指标延迟上报span处理，同时需要避免内存泄漏 |  | bryanpeng(彭超) | 2026-01-15 | 告警未覆盖 |  |  | 已完成 |
| 伽利略支持Span转指标做告警 |  | heshengpeng(彭和胜) | 2025-11-21 | 伽利略需求/使用问题 | 探索其他方式，开发成本过大 |  | 进行中 |
| Android 伽利略Span节点有丢失问题排查 | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-11-19 | 伽利略需求/使用问题 | 未查到具体原因，1224升级版本，优化压缩能力，打开延迟上报，减少丢失风险，继续观察 |  | 进行中 |
| 伽利略支持更丰富的数据预处理，目前日志管道能力不够丰富 | bryanpeng(彭超), heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-11-17 | 伽利略需求/使用问题 | 有个python脚本处理的能力，白名单已开放 |  | 已完成 |
| iOS成本压缩 |  | bryanpeng(彭超) | 2025-11-13 | 伽利略需求/使用问题 |  |  | 进行中 |
| 伽利略平台告警历史支持搜索过滤 |  | heshengpeng(彭和胜) | 2025-11-13 | 伽利略需求/使用问题 |  |  | 进行中 |
| 1分钟内同一用户crash数超过2次,聊天相关 | elioyin(银川) | bryanpeng(彭超) | 2025-11-14 | 告警成功 | https://bugly.woa.com/v2/exception/crash/issues/list?productId=ef14bfff8f&pid=2&token=3744cce4f0979bc0858bb47d89ba0e50 |  | 已完成 |
| Android 150ms内多次发起请求：/game/getreserve | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-12-01 | 告警成功 | 请求参数一样，native请求 |  | 挂起 |
| Android 内部路由量级增加 |  | heshengpeng(彭和胜) | 2025-12-01 | 告警成功 | 运营活动引起，复合预期的告警 |  | 挂起 |
| OneApi报错陡增 Request: api: getABConfig from: Hippy params: { "key" : "easterEggFlag" } ⬅️ Response: code: 4 message: Call Exception data: nil |  | bryanpeng(彭超) | 2025-12-03 | 告警成功 | easterEggFlag告警陡增。没有下发，屏蔽+下发 |  | 已完成 |
| Android 启动量级增加 |  | heshengpeng(彭和胜) | 2025-12-03 | 告警成功 | 信鸽推送，优化告警规则 | P0 | 已完成 |
| Android 网络请求失败增加 /app/txvideo/refresh |  | heshengpeng(彭和胜) | 2025-12-03 | 告警成功 | 信鸽推送，优化告警规则 | P0 | 已完成 |
| Android DeviceInfo量级增加 |  | heshengpeng(彭和胜) | 2025-12-03 | 告警成功 | 信鸽推送，日活有个明显陡增，优化告警规则 | P0 | 已完成 |
| 周三压测大量告警 user/synccampfriends | bryanpeng(彭超) | bryanpeng(彭超) | 2025-12-03 | 告警成功 |  |  | 已完成 |
| Android 网络请求失败增加 /user/synccampfriends |  | heshengpeng(彭和胜) | 2025-12-03 | 告警成功 | 后台压测 |  | 挂起 |
| -[FlutterDarwinContextMetalImpeller init:](FlutterDarwinContextMetalImpeller.mm:) | ricoyang(杨鈜宇) | bryanpeng(彭超) | 2025-12-03 | 告警成功 | (Flutter SDK版本)单用户连续crash https://bugly.woa.com/v2/exception/crash/issues/list?productId=ef14bfff8f&pid=2&token=c8f5e7ff6f959eb7a5e4a5b4ff613472 |  | 已完成 |
| Android 150ms内多次发起请求：/game/likeBattleVideo | bryanpeng(彭超) | heshengpeng(彭和胜) | 2025-12-03 | 告警成功 | 个别用户引起 |  | 已完成 |
| Android 150ms内多次发起请求：/a/getconf |  | heshengpeng(彭和胜) | 2025-12-02 | 告警成功 | 上报信息不足，不能排查，1210补充信息 |  | 挂起 |
| 【重要】P0：a/getconf【敏捷告警】【错误指标-分版本】连续2次-大流量-1h（600~6k）-单模块start量级对比前1m分钟上涨15% | bryanpeng(彭超) | bryanpeng(彭超) | 2025-12-02 | 告警成功 | -1011，服务器报错（后台db问题，排查中）dba 这边说 刚刚gcsdns这边抖动了下。easyconfig |  | 已完成 |
| 【敏捷告警】【错误指标-分版本】连续2次-大流量-1h（600~6k）-单模块start量级对比前1m分钟上涨15%chatserver/sendsinglechatmessage | bryanpeng(彭超) | bryanpeng(彭超) | 2025-12-02 | 告警成功 | 用户发送非法消息 |  | 已完成 |
| Android APP自升级中间步骤失败增加 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-12-01 | 告警成功 | 单用户下载失败导致告警，挂起待后续日志观察 |  | 挂起 |
| Android 网络请求失败增加 /app/txvideo/refresh |  | heshengpeng(彭和胜) | 2025-12-01 | 告警成功 | 运营活动导致的量级上升，优化告警规则 | P0 | 已完成 |
| Android 内部路由量级增加 |  | heshengpeng(彭和胜) | 2025-12-01 | 告警成功 | 运营活动导致的量级上升，优化告警规则 | P0 | 已完成 |
| Android 150ms内多次发起请求：/game/likeBattleVideo | bryanpeng(彭超) | heshengpeng(彭和胜) | 2025-12-01 | 告警成功 | 413268281 单用户引起 | P0 | 已完成 |
| Android 网络请求失败增加 /game/allrolelistv3 | joinyin(尹泽宇), jasonmao(毛建伟) | heshengpeng(彭和胜) | 2025-12-01 | 告警成功 | -30139，单用户引起1746859495，继续观察 | P0 | 进行中 |
| Android 网络请求失败增加 /game/morebattlelist |  | heshengpeng(彭和胜) | 2025-12-01 | 告警成功 | 后台返回码-91004，战绩拉取失败，datamore那边的架构缺陷导致，历史问题：每天凌晨两点左右，会有短暂的战绩列表超时 |  | 挂起 |
| Android 外部路由量级增加 |  | heshengpeng(彭和胜) | 2025-12-01 | 告警成功 | 信鸽推送，优化告警规则 |  | 已完成 |
| Android 内部路由量级增加 |  | heshengpeng(彭和胜) | 2025-12-01 | 告警成功 | 信鸽推送，优化告警规则 |  | 已完成 |
| Android 外部路由量级陡增 |  | heshengpeng(彭和胜) | 2025-12-01 | 告警成功 | 信鸽推送，优化告警规则 | P0 | 已完成 |
| Android 内部路由量级增加 |  | heshengpeng(彭和胜) | 2025-11-28 | 告警成功 | H5活动引起 |  | 挂起 |
| Android SpanStatistic陡增 |  | heshengpeng(彭和胜) | 2025-11-28 | 告警成功 | H5打开增多，有上报cookie，可以先忽略掉 | P0 | 已完成 |
| 大图加载 https://static.gametalk.qq.com/image/18/1763636226_28647f10743701940523df0bb9ca9428.jpg |  | bryanpeng(彭超) | 2025-11-27 | 告警成功 | 大图告警，大长图合理 |  | 挂起 |
| 大图加载https://static.gametalk.qq.com/image/18/1763361870_d2b5ca33bd970f64a6301fa75ae2eb22.png |  | bryanpeng(彭超) | 2025-11-27 | 告警成功 | 大图告警，非大长图 |  | 进行中 |
| Android 内部路由量级增加 |  | heshengpeng(彭和胜) | 2025-11-27 | 告警成功 | 信鸽推送导致 |  | 挂起 |
| Android 启动量级增加 |  | heshengpeng(彭和胜) | 2025-11-27 | 告警成功 | 信鸽推送导致 |  | 挂起 |
| Android 网络请求失败陡增 /app/txvideo/refresh |  | heshengpeng(彭和胜) | 2025-11-27 | 告警成功 | 信鸽推送导致启动量级增加，碰上QQ票据过期，后恢复 | P0 | 挂起 |
| Android 150ms内多次发起请求：/game/refreshvideo | elioyin(银川) | heshengpeng(彭和胜) | 2025-11-27 | 告警成功 | 526350240单用户引起， | P0 | 已完成 |
| [WEGVoiceHelper isVoiceNotPlay:] | bryanpeng(彭超), elioyin(银川) | bryanpeng(彭超) | 2025-11-26 | 告警成功 | https://bugly.woa.com/v2/exception/crash/issues/detail?productId=ef14bfff8f&pid=2&token=aec949309b6f48c58953e38c7ea12bb2&feature=2B494378B8A27BE4BE76B5D7D47A1794&cId=A2FF704C-1377-4789-A2DC-973DC0E4CC7F |  | 已完成 |
| 单用户崩溃21次 SmobaHelper $s12app_settings17AppSettingsPluginC8register4withySo07FlutterE9Registrar_p_tFZ |  | bryanpeng(彭超) | 2025-11-26 | 告警成功 | debug包 https://bugly.woa.com/v2/exception/crash/issues/detail?productId=ef14bfff8f&pid=2&token=1e022d7cfe7ea1ab663a96e892221006&feature=471D0F77CB8417295A0FEDC48E18FFCA&cId=F6B53277-F2AE-4443-8730-3135B206A7F7 |  | 已完成 |
| Android 外部路由成功率下降7% |  | heshengpeng(彭和胜) | 2025-11-26 | 告警成功 | 路由end status=-1增加，可能是游戏没安装，补充字段区分 |  | 已完成 |
| Android 网络请求失败增加 /role/reserve | joinyin(尹泽宇), qcxiang(向乾操) | heshengpeng(彭和胜) | 2025-11-26 | 告警成功 | 1865526272单用户引起，141903:对方游戏不在线 | P0 | 挂起 |
| Android 网络请求失败陡增 /chatserver/sendsinglechatmessage |  | heshengpeng(彭和胜) | 2025-11-25 | 告警成功 | 单用户引起的突刺 | P0 | 挂起 |
| 多协议告警陡增，esports/getuserlatestmatch， info/getmgamecardsreserve，  info/listinfov2等多个协议出现告警陡增 |  | bryanpeng(彭超) | 2025-11-25 | 告警成功 | 多个协议出现告警陡增。-1003，找不到主机。（腾讯云多个域名受影响） |  | 已完成 |
| Android 其他小流量接口接口网络请求失败陡增 /chatserver/offline/singlemsg、 /game/mgame/conflist |  | heshengpeng(彭和胜) | 2025-11-25 | 告警成功 | -100,超时、cancel、unknownHost、 | P0 | 已完成 |
| Android 网络请求失败陡增 /game/authinfo |  | heshengpeng(彭和胜) | 2025-11-25 | 告警成功 | -100,超时、cancel、unknownHost、 | P0 | 已完成 |
| Android 网络请求失败陡增 /app/easyconf/getjson |  | heshengpeng(彭和胜) | 2025-11-25 | 告警成功 | -100,超时、cancel、unknownHost、 | P0 | 已完成 |
| Android 网络请求失败陡增 /app/redpoint/get |  | heshengpeng(彭和胜) | 2025-11-25 | 告警成功 | -100,超时、cancel、unknownHost、 | P0 | 已完成 |
| Android PAG加载失败陡增 |  | heshengpeng(彭和胜) | 2025-11-25 | 告警成功 | 超时、403、unknownHost | P0 | 已完成 |
| Android 网络请求失败陡增 /app/getappscreenads |  | heshengpeng(彭和胜) | 2025-11-25 | 告警成功 | -100, -30003，超时、cancel、unknownHost、 | P0 | 已完成 |
| 1分钟内同一用户crash数超过2次 |  | bryanpeng(彭超) | 2025-11-24 | 告警成功 | 键盘相关 https://bugly.woa.com/v2/exception/crash/issues/detail?productId=ef14bfff8f&pid=2&token=1d3ff25d0b83eebf78697581830eff24&feature=AA990E86F1695BB8D97FF431B10229AE&cId=6ED46C1D-4AB5-44E9-998C-94665A34D315 |  | 进行中 |
| Android 非法日志/Span量级增加20% | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-11-24 | 告警成功 | 伽利略平台发布bug导致日志转指标异常 |  | 挂起 |
| Android 网络请求失败陡增 /role/reserve | joinyin(尹泽宇), qcxiang(向乾操) | heshengpeng(彭和胜) | 2025-11-24 | 告警成功 | 480482679 单用户引起，继续观察 |  | 挂起 |
| iOS user/addlike 连续2次-大流量-1h（200~600）-单模块start量级对比前1m分钟上涨50% | bryanpeng(彭超) | bryanpeng(彭超) | 2025-11-24 | 告警成功 | -30139 用户操作频率过高 |  | 已完成 |
| Android 150ms内多次发起请求：/supergroup/getlivingroomlist/v1 | joinyin(尹泽宇), kitli(李汶婷) | heshengpeng(彭和胜) | 2025-11-24 | 告警成功 | 看后台的请求参数，有一样的，也有不一样的，确认下 |  | 挂起 |
| game/watchBattle 单接口请求失败1小时超过10000次 | bryanpeng(彭超) | bryanpeng(彭超) | 2025-11-24 | 告警成功 | -1008，观战人数过多，超载了 |  | 已完成 |
| Android 150ms内多次发起请求：/supergroupchat/clearnotice | joinyin(尹泽宇), kitli(李汶婷) | heshengpeng(彭和胜) | 2025-11-24 | 告警成功 | 这个1029优化过，还有，确认下是否修复 |  | 已完成 |
| Android 网络请求失败增加 /game/morebattlelist |  | heshengpeng(彭和胜) | 2025-11-24 | 告警成功 | 后台返回码-91004，战绩拉取失败，datamore那边的架构缺陷导致，历史问题：每天凌晨两点左右，会有短暂的战绩列表超时 |  | 挂起 |
| iOS 连续崩溃 SmobaHelper -[TPPlayerMgr setUpcInfoWithUpc:upcState:](TPPlayerMgr.m:) | bryanpeng(彭超) | bryanpeng(彭超) | 2025-11-20 | 告警成功 | 1112已验证 |  | 已完成 |
| Android 150ms内多次发起请求：/game/infohotcomments  推送信鸽后重复请求导致告警，前端OneAPi请求 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-11-20 | 告警成功 | 新版本还是会告警，继续关注下 |  | 挂起 |
| iOS 网络请求失败增加 user/synccampfriends |  | bryanpeng(彭超) | 2025-11-20 | 告警成功 | 压测：-10107.当前登录人数太多，请稍候再试. |  | 挂起 |
| iOS 网络请求失败增加 supergroupchat/getmsgnotice | elioyin(银川) | bryanpeng(彭超) | 2025-11-18 | 告警成功 |  |  | 已完成 |
| Android 网络请求失败增加 /game/friends、/play/gettaskconditiondata、/user/login | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-11-18 | 告警成功 | 后台服务抖动，1m陡增，已恢复 | P0 | 挂起 |
| Android 网络请求失败增加 /role/match/getpopuserlist | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-11-18 | 告警成功 | 单用户引起的，无网络怎么还会一直请求？ |  | 已完成 |
| Android 启动量级增加 |  | heshengpeng(彭和胜) | 2025-12-03 | 告警成功 | 信鸽推送，优化告警规则 |  | 已完成 |
| 【核心业务】1分钟内同一用户crash数超过2次 1817361224 | qcxiang(向乾操) | bryanpeng(彭超) | 2025-12-04 | 告警成功 | 新个人主页crash https://bugly.woa.com/v2/exception/crash/issues/detail?productId=ef14bfff8f&pid=2&token=746006501a454e8f87a58aeb16a1ec41&feature=AC0C0CD7249BD6D3394EB4BDA45F2E7C&cId=8A02F912-3BA0-48D3-966E-AA8829618D1F |  | 进行中 |
| 大图加载 https://static.gametalk.qq.com/image/18/1763636226_28647f10743701940523df0bb9ca9428.jpg | bryanpeng(彭超) | bryanpeng(彭超) | 2025-12-12 | 告警成功 | 合理大图 |  | 已完成 |
| oneApi 【错误指标-分系统】小流量-1h（600~6k）-单模块start量级对比前1m上涨20% | leviyin(尹恒宇) | bryanpeng(彭超) | 2025-12-12 | 告警成功 | oneApi报错，所有用户都是18.1.1系统！！！登录相关等（OneAPI Callback Info: ➡️ Request: api: campLogin from: Flutter params: { "method" : "commonLogin", "data" : { "loginSourceType" : "login", "phone" : "", "type" : "wx", "loginedUserId" : "" } } ⬅️ Response: code: -130001 message: data: nil） |  | 进行中 |
| 大图告警静默 https://static.gametalk.qq.com/image/18/1765785685_3073a326675f2ac6b44cc2486e0d3df2.jpg |  | bryanpeng(彭超) | 2025-12-19 | 告警成功 | 合理的运营长图 |  | 已完成 |
| iOS H5Page错误告警增加 | bobihuang(黄腾) | bryanpeng(彭超) | 2025-12-19 | 告警成功 | 后台返回数据有空，前端没做空判断导致的，已经告知相关开发团队，排查处理中 | P0 | 进行中 |
| 【核心业务】1小时内同一用户crash数超过10次 |  | bryanpeng(彭超) | 2025-12-22 | 告警成功 | Flutter连续崩溃 https://bugly.woa.com/v2/exception/crash/issues/list?productId=ef14bfff8f&pid=2&token=b433490194dd04dd60674cbb4ccca6bc |  | 挂起 |
| Android 图片加载失败增加 | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2026-01-05 | 告警成功 | 图片url 404, 1566976365单用户引起，运营配置问题，先静默 | P0 | 进行中 |
| Android AppUpgrade失败增加 |  | heshengpeng(彭和胜) | 2026-01-05 | 告警成功 | 后续优化，先静默 |  | 挂起 |
| Android 150ms内多次发起请求：/user/getbackpackpropinfo |  | heshengpeng(彭和胜) | 2026-01-05 | 告警成功 | 低版本告警，继续关注 |  | 挂起 |
| Android 网络失败增加 /role/match/getpopuserlist | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-01-05 | 告警成功 | 349658980等少数用户引起，设备判定无网，APP在后台一定无网请求 |  | 进行中 |
| Android 150ms内多次发起请求：/user/getbackpackpropinfo | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-01-05 | 告警成功 | 1714751530单用户引起，native请求，请求参数一致，每分钟40次，新版本原生已下 | P0 | 挂起 |
| Android 150ms内多次发起请求：/role/match/getpopuserlist |  | heshengpeng(彭和胜) | 2026-01-05 | 告警成功 | 无网请求，一直失败一直重试 |  | 挂起 |
| Android 150ms内多次发起请求：/play/getbbssignstatus | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2026-01-05 | 告警成功 | 1862653146单用户引起，OneApi请求，后台无trace，待放开php参数观察 | P0 | 进行中 |
| Android 150ms内多次发起请求：/supergroup/getlivingroomlist/v1 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-01-05 | 告警成功 | 484340374单用户引起，请求参数部分一样，部分不一样，但3m 600次不太正常 | P0 | 进行中 |
| Android 网络失败增加 /mall/order/buy |  | heshengpeng(彭和胜) | 2026-01-05 | 告警成功 | -6421、-30003， 符合预期的返回码 |  | 挂起 |
| Android 150ms内多次发起请求：/operation/urlwhitelist | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2026-01-05 | 告警成功 | native 2次请求，uid没有聚集性 |  | 进行中 |
| Android tenthAnniversaryWeb量级增加 |  | heshengpeng(彭和胜) | 2026-01-05 | 告警成功 | 新功能上线 |  | 挂起 |
| Android tenthAnniversaryWeb量级增加 |  | heshengpeng(彭和胜) | 2026-01-05 | 告警成功 | 新功能上线 | P0 | 挂起 |
| Android 图片加载失败增加 |  | heshengpeng(彭和胜) | 2025-12-31 | 告警成功 | 单用户引起的突刺，低版本 | P0 | 已完成 |
| Android 自动更新失败量级增加 |  | heshengpeng(彭和胜) | 2025-12-31 | 告警成功 |  |  |  |
| Android H5Page 失败增加 |  | heshengpeng(彭和胜) | 2025-12-31 | 告警成功 | 告警太频繁了，又没有实际的处理，先静默掉这一个pvp | P0 | 挂起 |
| Android H5Page 失败增加 |  | heshengpeng(彭和胜) | 2025-12-30 | 告警成功 | H5报错告警， JS加载错误 |  | 挂起 |
| Android 自动更新失败量级增加 |  | heshengpeng(彭和胜) | 2025-12-30 | 告警成功 | SDK老问题，先静默一段时间，后续处理 |  | 挂起 |
| Android 150ms内多次发起请求：/moment/getsubcommentlist | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-12-30 | 告警成功 | 低版本单用户引起，新版本已经处理了 |  | 已完成 |
| Android 图片加载失败增加 |  | heshengpeng(彭和胜) | 2025-12-30 | 告警成功 | 1649037626单用户引起的突刺，低版本 | P0 | 已完成 |
| 【错误指标】大流量-1h（6k~10w）-单模块start量级对比前1m分钟上涨5%    H5Page | bobihuang(黄腾) | bryanpeng(彭超) | 2025-12-29 | 告警成功 | H5报错告警， JS加载错误 |  | 挂起 |
| 【大流量】end结束前指标-end转化率波动超过2.2 （Hippy-tv，Hippy-gameZone） | bryanpeng(彭超) | bryanpeng(彭超) | 2025-12-29 | 告警成功 | 信鸽引流去到该界面，懒加载 + 去到改界面转换率提高 |  | 已完成 |
| Android 网络失败增加 /game/reportvideoplayv2 |  | heshengpeng(彭和胜) | 2025-12-29 | 告警成功 | -20011，后台推流导致 | P0 | 挂起 |
| Android 网络失败增加 /user/login |  | heshengpeng(彭和胜) | 2025-12-29 | 告警成功 | -30003 | P0 | 挂起 |
| Android 网络失败增加 /app/txvideo/refresh |  | heshengpeng(彭和胜) | 2025-12-29 | 告警成功 | -100，后台推流导致 | P0 | 挂起 |
| Android 网络失败增加 /play/gettaskconditiondata |  | heshengpeng(彭和胜) | 2025-12-29 | 告警成功 | -30003 | P0 | 挂起 |
| Android 网络失败增加 /app/game/setting |  | heshengpeng(彭和胜) | 2025-12-29 | 告警成功 | -140445 | P0 | 挂起 |
| Android H5Page 失败增加 |  | heshengpeng(彭和胜) | 2025-12-29 | 告警成功 |  | P0 | 挂起 |
| Android 注册成功率下降 |  | heshengpeng(彭和胜) | 2025-12-29 | 告警成功 | 用户在反复提交用户信息，用户操作引起 |  | 挂起 |
| Android 150ms内多次发起请求：/user/getunlockcardmodule | xinyuming(明新宇), joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-12-29 | 告警成功 |  |  | 进行中 |
| Android 150ms内多次发起请求：/user/getunlockcardmodule | xinyuming(明新宇), joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-12-29 | 告警成功 | native多次请求 |  | 进行中 |
| Android 150ms内多次发起请求：/game/receivedmessage |  | heshengpeng(彭和胜) | 2025-12-29 | 告警成功 | 低版本1015从ignore中取TopK取到了，导致误告 |  | 挂起 |
| Android 150ms内多次发起请求：/app/redpoint/get |  | heshengpeng(彭和胜) | 2025-12-29 | 告警成功 | 低版本1015从ignore中取TopK取到了，导致误告 |  | 挂起 |
| Android 150ms内多次发起请求：/game/getreserve |  | heshengpeng(彭和胜) | 2025-12-29 | 告警成功 | 都是1015版本，先静默掉，新版本已修复 |  | 已完成 |
| Android H5Page 失败增加 |  | heshengpeng(彭和胜) | 2025-12-29 | 告警成功 | 27号下午6点 |  | 挂起 |
| Android 网络失败增加 /game/reportvideoplayv2 |  | heshengpeng(彭和胜) | 2025-12-29 | 告警成功 | 后台推流导致 |  | 挂起 |
| Android 150ms内多次发起请求：/info/episode/report | heshengpeng(彭和胜) | heshengpeng(彭和胜) | 2025-12-29 | 告警成功 | 请求参数不一样，新版本屏蔽掉 |  | 已完成 |
| Android 150ms内多次发起请求：/game/infohotcomments | jimwzhou(周维) | heshengpeng(彭和胜) | 2025-12-29 | 告警成功 |  |  | 进行中 |
| Android H5Page 失败增加 | bobihuang(黄腾) | heshengpeng(彭和胜) | 2025-12-29 | 告警成功 | 少数几个用户引起大量的js异常， | P0 | 挂起 |
| Android 图片加载失败 |  | heshengpeng(彭和胜) | 2025-12-29 | 告警成功 | 少数用户 大量请求超时和加载问题 | P0 | 挂起 |
| 【大流量】start-step1转化率波动超过2.2  ManualLogin报错 | leviyin(尹恒宇), bryanpeng(彭超) | bryanpeng(彭超) | 2025-12-26 | 告警成功 | 正常！用户不愿进去！用户跳转过去发现登录态失效，直接杀端；所以信鸽有效性是不是应该用这个值？ |  | 已完成 |
| user/login报错 【错误指标】大流量-1h（6k~10w）-单模块start量级对比前1m分钟上涨5% | leviyin(尹恒宇), bryanpeng(彭超) | bryanpeng(彭超) | 2025-12-26 | 告警成功 | （用户跳转过去发现登录态失效，直接杀端）登录user/login接口大波报错，-50000，-30003合理需要排查（这两个当作合理的排除下）静默 |  | 已完成 |
| Android 150ms内多次发起请求：/game/infohotcomments | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-12-26 | 告警成功 | H5发起的重复请求，请求参数一样 |  | 进行中 |
| 【App不可用】【暂时屏蔽】整个App指标全面报错，可能是服务器全挂了或者某个业务超高频率失败 | bryanpeng(彭超) | bryanpeng(彭超) | 2025-12-26 | 告警成功 | 信鸽推送用户点开大量的登录态失败导致登录的step报错，这个还不太好屏蔽或者联动，有可能是真的登录有问题呢？？？ |  | 挂起 |
| Android 150ms内多次发起请求：/user/getkingcalendar | qcxiang(向乾操) | heshengpeng(彭和胜) | 2025-12-26 | 告警成功 | 符合预期，iOS也存在，待优化 |  | 挂起 |
| oneApi 【错误指标-分系统】连续1次-大流量-1h（6k~10w）-单模块start量级对比前1m分钟上涨8.5% | leviyin(尹恒宇), bryanpeng(彭超) | bryanpeng(彭超) | 2025-12-26 | 告警成功 | 1. 手机号获取超时 2.oneApi返回拉去不到AB信息，可能太快了，看下怎么调整（调整代码，无需报错） |  |  |
| Flutter std::_fl::__next_prime(unsigned long)(hash.cpp:) [inlined: std::_fl::__throw_overflow_error[abi:v15000](char const*)(stdexcept:) | bryanpeng(彭超) | bryanpeng(彭超) | 2025-12-26 | 告警成功 | https://bugly.woa.com/v2/exception/crash/issues/detail?productId=ef14bfff8f&pid=2&token=7f6ad1b066e432e67794d6b34ec7f268&feature=4BF4DAAD4F43DAD55F1A277162A5FB8D&cId=AB4C1F97-D6F9-450C-BC99-E5B9852107E6 |  | 进行中 |
| Android 150ms内多次请求/user/addlike | heshengpeng(彭和胜), joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-12-25 | 告警成功 | 1795282728单用户引起，等php配置打开再观察 | P0 | 进行中 |
| Android 注册成功率上升 |  | heshengpeng(彭和胜) | 2025-12-25 | 告警成功 | 有几分钟end高于start导致，上报抖动导致，调整下阈值 |  | 已完成 |
| Android download_manager路由增加 | jasonmao(毛建伟) | heshengpeng(彭和胜) | 2025-12-25 | 告警成功 | 下载通知栏进度更新会一直获取路由 |  | 进行中 |
| Android 150ms内多次发起请求：/game/likeBattleVideo |  | heshengpeng(彭和胜) | 2025-12-25 | 告警成功 | 低版本告警，静默掉 |  | 挂起 |
| Android H5Page 失败增加 |  | heshengpeng(彭和胜) | 2025-12-25 | 告警成功 | 活动方H5问题 | P0 | 已完成 |
| Android 人机验证成功率提升 |  | heshengpeng(彭和胜) | 2025-12-24 | 告警成功 | 11点50左右有个量级上涨的突刺，继续观察 |  | 挂起 |
| Android H5Page 失败增加 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-12-24 | 告警成功 | 活动方H5问题 |  | 已完成 |
| Android download_manager路由增加 | jasonmao(毛建伟) | heshengpeng(彭和胜) | 2025-12-24 | 告警成功 | OS推送新版本下载，通知栏进度更新会一直获取路由 |  | 进行中 |
| Android H5Page 失败增加 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-12-24 | 告警成功 | 活动方H5问题 | P0 | 已完成 |
| Android 150ms内多次发起请求：/game/likeBattleVideo |  | heshengpeng(彭和胜) | 2025-12-24 | 告警成功 | 低版本告警，静默掉 |  | 已完成 |
| 【核心业务】1小时内同一用户crash数超过10次 |  | bryanpeng(彭超) | 2025-12-22 | 告警成功 | 该用户进App必崩，safariBrowse相关的一个crash,先禁用这个检测(看起来和FWF的预加载有关系，Flutter web预热？)  https://bugly.woa.com/v2/exception/crash/issues/list?productId=ef14bfff8f&pid=2&token=6e3afe9126cc6cb88bf5b79827a6587d |  | 挂起 |
| 个人主页game/refreshvideo存在多次调用 | qcxiang(向乾操) | bryanpeng(彭超) | 2025-12-22 | 告警成功 | 个人主页多个视频产生的多次调用 |  | 已完成 |
| Android 150ms内多次发起请求：/game/likeBattleVideo |  | heshengpeng(彭和胜) | 2025-12-22 | 告警成功 | 低版本告警，静默掉 |  | 已完成 |
| Android 图片加载失败增加 |  | heshengpeng(彭和胜) | 2025-12-19 | 告警成功 | 1830637255单用户加载失败，DNS解析失败 |  | 挂起 |
| ]【核心业务】1分钟内同一用户crash数超过2次 |  | bryanpeng(彭超) | 2025-12-19 | 告警成功 | 老问题 |  | 进行中 |
| Android H5Page 失败增加 |  | heshengpeng(彭和胜) | 2025-12-18 | 告警成功 | script 加载失败，反馈处理 | P0 | 已完成 |
| Android 150ms内多次发起请求：/play/getbbssignstatus | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-12-18 | 告警成功 | 346908616单用户引起，OneApi，无法查看到后台链路；OneEvent引起的bug | P0 | 已完成 |
| Android 图片加载失败增加 |  | heshengpeng(彭和胜) | 2025-12-18 | 告警成功 | 1830637255单用户加载失败，DNS解析失败 | P0 | 挂起 |
| Android 图片加载失败增加 |  | heshengpeng(彭和胜) | 2025-12-18 | 告警成功 | 213562044单用户加载失败，超时+DNS解析失败 | P0 | 挂起 |
| Android 图片加载失败增加 |  | heshengpeng(彭和胜) | 2025-12-18 | 告警成功 | 484097172单用户加载失败，DNS解析失败 | P0 | 挂起 |
| iOS 12月17日11：30分开始到14：00维度容量超过上线，告警出错（用户头像图片报错引起） |  | bryanpeng(彭超) | 2025-12-17 | 告警成功 |  |  | 已完成 |
| iOS vip/getprofilevipcareer，接口请求高失败率 | qcxiang(向乾操) | bryanpeng(彭超) | 2025-12-17 | 告警成功 | 看起来是个人主页相关，-30207 |  | 进行中 |
| Android 注册成功率下降 | magicwu(吴家庆) | heshengpeng(彭和胜) | 2025-12-17 | 告警成功 | start增加end没变，分析用户的确是进入注册页面就退出了，然后再重新进 |  | 挂起 |
| Android 注册成功率下降 | magicwu(吴家庆) | heshengpeng(彭和胜) | 2025-12-16 | 告警成功 | 出现几分钟start增加，但end没变，可能是用户操作退出了，继续关注 |  | 挂起 |
| Android H5Page量级增加 |  | heshengpeng(彭和胜) | 2025-12-16 | 告警成功 | 1210全量，上量，新增上报 |  | 挂起 |
| Android H5Page量级增加 |  | heshengpeng(彭和胜) | 2025-12-16 | 告警成功 | 1210全量，上量，新增上报 | P0 | 挂起 |
| ios 网络请求失败增加 game/battledetail | bryanpeng(彭超) | bryanpeng(彭超) | 2025-12-16 | 告警成功 | -900001：请求超时。后台确认是数据库抖动 |  | 已完成 |
| Android 150ms内多次发起请求：/supergroupchat/getmsgnotice | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-12-15 | 告警成功 | 327741476，reqId：1031和1033 |  | 挂起 |
| Android 150ms内多次发起请求：/supergroup/getlivingroomlist/v1 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-12-15 | 告警成功 | 2118097798,reqId：3055和3059 |  | 挂起 |
| Android 网络请求失败增加 /game/battledetail |  | heshengpeng(彭和胜) | 2025-12-15 | 告警成功 | -10461:数据库异常:获取对战详情失败; |  | 挂起 |
| Android 网络请求失败增加 /game/battledetail |  | heshengpeng(彭和胜) | 2025-12-15 | 告警成功 | -10461:数据库异常:获取对战详情失败; 下游 Datamore 有异常 | P0 | 挂起 |
| Android 网络请求失败增加 /role/match/getpopuserlist |  | heshengpeng(彭和胜) | 2025-12-15 | 告警成功 | 1742697522单用户引起，1210已修复，继续关注 | P0 | 已完成 |
| Android 网络请求失败增加 /game/morebattlelist |  | heshengpeng(彭和胜) | 2025-12-15 | 告警成功 | -91004:历史问题，datamore那边的架构缺陷导致 |  | 挂起 |
| Android 图片加载失败增加 |  | heshengpeng(彭和胜) | 2025-12-12 | 告警成功 | 加载的url为空，头像加载，低版本告警，1029修复 | P0 | 已完成 |
| Android APP自升级下载失败增加 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-12-12 | 告警成功 | 老问题，发灰度的时候，个别用户会命中获取apk失败 |  | 挂起 |
| ios 压测和datamore问题这里就不再登记了 |  | bryanpeng(彭超) | 2025-12-12 | 告警成功 | 占位 |  | 已完成 |
| Android 图片加载失败增加 |  | heshengpeng(彭和胜) | 2025-12-12 | 告警成功 | 数据波动，算是误告警，优化告警规则 | P0 | 已完成 |
| Android 150ms内多次发起请求：/role/match/getpopuserlist | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-12-11 | 告警成功 | 两个少量用户引起，1210修复过，后续观察 | P0 | 挂起 |
| Android 150ms内多次发起请求：/game/likeBattleVideo | bryanpeng(彭超) | heshengpeng(彭和胜) | 2025-12-10 | 告警成功 | 单用户引起 | P0 | 已完成 |
| Android 150ms内多次发起请求：/game/infohotcomments | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-12-10 | 告警成功 |  |  | 已完成 |
| Android 150ms内多次发起请求：/game/likeBattleVideo | bryanpeng(彭超) | heshengpeng(彭和胜) | 2025-12-10 | 告警成功 | 1846746639单用户引起 | P0 | 已完成 |
| Android 图片加载失败陡增 | joinyin(尹泽宇), jasonmao(毛建伟) | heshengpeng(彭和胜) | 2025-12-10 | 告警成功 | 535023302单用户引起 | P0 | 进行中 |
| Android 网络请求失败增加 /app/txvideo/refresh |  | heshengpeng(彭和胜) | 2025-12-09 | 告警成功 | 信鸽推送，导致日活突增导致，复合预期 | P0 | 挂起 |
| Android 网络请求失败增加 /game/morebattlelist |  | heshengpeng(彭和胜) | 2025-12-08 | 告警成功 | -91004:历史问题，datamore那边的架构缺陷导致 |  | 挂起 |
| Android 网络请求失败增加 /chatserver/sendsinglechatmessage |  | heshengpeng(彭和胜) | 2025-12-05 | 告警成功 | 单用户发言过多导致失败 |  | 挂起 |
| Android 150ms内多次发起请求：/chatserver/sendsinglechatmessage | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-12-05 | 告警成功 | 358209176单用户引起 |  |  |
| Android 150ms内多次发起请求：/moment/getsubcommentlist | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-12-05 | 告警成功 | 537207329单用户引起 | P0 | 已完成 |
| Android 网络请求失败增加  /pay/getbalance |  | heshengpeng(彭和胜) | 2025-12-04 | 告警成功 | 后台返回-50000 |  |  |
| Android SpanStatistic量级增加 |  | heshengpeng(彭和胜) | 2025-12-04 | 告警成功 | 后台返回-50000触发了refreshToken |  |  |
| 【敏捷告警】【错误指标-分版本】连续2次-大流量-1h（600~6k）-单模块start量级对比前1m分钟上涨15%  pay/getbalance |  | bryanpeng(彭超) | 2025-12-04 | 告警成功 | -50000是米大师那边登录态校验失败，看起来过一会儿恢复了 |  | 已完成 |
| Android 150ms内多次发起请求：/game/infohotcomments |  | heshengpeng(彭和胜) | 2025-12-03 | 告警成功 | 老问题处理中 |  | 已完成 |
| Android 网络请求失败增加 /game/reportvideoplayv2 | joinyin(尹泽宇) | heshengpeng(彭和胜) | 2025-12-03 | 告警成功 | -20011 |  | 已完成 |
| 商城-伽利略上报 |  |  | 2026-04-23 | 业务需求上报 |  |  | 待开始 |
| 随机头像 |  |  | 2025-12-04 | 业务需求上报 | 线上少量上报 |  | 已完成 |
| Android 游戏预下载 |  |  | 2025-12-04 | 业务需求上报 |  |  | 已评审 |
| 好友亲密度 |  |  | 2025-12-04 | 业务需求上报 |  |  | 已完成 |
| 二代登录超时上报 |  |  | 2025-12-04 | 业务需求上报 |  |  | 已评审 |
| 通过游戏昵称 搜索游戏好友 |  |  | 2026-01-29 | 业务需求上报 |  |  | 已评审 |
| 伽利略trace、log过载，针对春节是否再调高阈值（影响成本） |  | heshengpeng(彭和胜), bryanpeng(彭超) | 2026-02-05 | 伽利略需求/使用问题 | 联系平台调高阈值到800w条/min |  | 已完成 |
