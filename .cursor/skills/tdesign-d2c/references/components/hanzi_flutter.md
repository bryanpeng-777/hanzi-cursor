# hanzi-cursor Flutter 组件映射（拼音学习 9-2）

| d2c 节点类型 | Flutter 组件 | configKey 前缀 |
|-------------|-------------|----------------|
| 全屏背景 / 切图 | `FigmaUiImage` → `CsImage` | `figma_pinyin_grid_*` |
| 拼音卡片 | `PinyinLearnGridCard` | 见 `PinyinLearnGrid9Cards` |
| 底部进度 | `PinyinLearnStatsBar` | `figma_pinyin_grid_03`～`14` |
| 详情模态 | `PinyinLearnDetailModal` | `figma_pinyin_detail_*` |

布局常量：`lib/constants/pinyin_learn_d2c_9_2_layout.dart`  
资源映射：`lib/constants/pinyin_learn_d2c_9_2_image_map.dart`
