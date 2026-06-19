# L3 场景索引：内容编辑器 / 发布

> **所属域**：内容编辑器 / 发布 | **上级 L2**：L2_CONTENT.md  
> **主路径**：`lib/editor/` / `Features/Imps/WEGEditorImp.m`

---

## 场景 → 代码入口

| 用户描述的场景 | 关键词 | 入口文件 | 查找提示 |
|-------------|--------|---------|---------|
| 编辑器打不开 / crash | 发帖、写动态、编辑器 | `lib/editor/`<br>`WEGEditorImp.m` | 搜 EditorPage / `openEditor:` |
| 发布内容失败 / 提交按钮无响应 | 发布失败、提交 | `lib/editor/`（submit 子目录） | 搜 publishContent / submitPost |
| @联系人搜索无结果 | @联系人、@人 | `lib/at_contact/` | 搜 AtContactPage / searchContact |
| 图片选择失败 / 相册无法打开 | 图片选择、相册 | `lib/camp_business/album_picker/` | 搜 AlbumPicker / pickImage |
| 粘贴内容时出现异常弹窗 | 剪贴板、粘贴提示 | `Features/ShearPlateManager/` | 搜 ClipboardManager / pasteAlert |
| 编辑器模板加载失败 | 模板、editor 模板 | `lib/editor_template/` | 搜 EditorTemplatePage / fetchTemplates |
| 插入链接失败 | 链接、超链接 | `lib/editor_link/` | 搜 EditorLinkPage / insertLink |
| 文字链接点击无效 | 文字链接 | `lib/text_link/` | 搜 TextLinkWidget |
| 签到落地页打不开 | 签到落地页 | `lib/checkin_landing/` | 搜 CheckinLandingPage |
| 发布内容审核不通过 / 无提示 | 审核、内容违规 | `lib/editor/`（submit 子目录） | 搜 contentReview / publishError |

---

## 关键链路

```
用户点击发布入口
  → WEGEditorImp.m openEditor:（iOS 侧触发）
  → lib/editor/ EditorPage 打开
  → 用户输入内容（文字/图片/@人/链接）
  → 点击发布 → submit 逻辑
  → 调用发布接口 → 审核 → 成功/失败回调
```

---

## 排查起点建议

- **编辑器打不开**：先看 `WEGEditorImp.m` 的 openEditor: 参数，再看 `lib/editor/` 页面初始化
- **发布失败**：`lib/editor/` 的 submit 逻辑 + 接口错误码
- **图片选择**：`lib/camp_business/album_picker/` 独立模块，注意相册权限

*最后更新：2026-03-30*
