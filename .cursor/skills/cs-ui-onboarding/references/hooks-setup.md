# Cursor Hooks 图片管理系统

Step 0 需要创建的全部文件内容。每个文件检查是否已存在，存在则跳过。

## `.cursor/hooks.json`

```json
{
  "version": 1,
  "hooks": {
    "afterFileEdit": [
      {
        "command": ".cursor/hooks/sync-image-manifest.sh"
      }
    ]
  }
}
```

---

## `.cursor/hooks/sync-image-manifest.sh`

```bash
#!/bin/bash
# sync-image-manifest.sh
# afterFileEdit hook：dart 文件保存后，增量同步 CsImage configKey 到 image_manifest.json

input=$(cat)

file_path=$(python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    path = (data.get('path') or
            data.get('tool_input', {}).get('path') or
            data.get('file_path') or '')
    print(path)
except Exception:
    print('')
" <<< "$input" 2>/dev/null)

if [[ "$file_path" != *.dart ]]; then
    echo '{}'
    exit 0
fi

workspace_root="$(pwd)"
sync_script="$workspace_root/aiworkspace/sync_image_manifest.py"

if [[ ! -f "$sync_script" ]]; then
    echo '{}'
    exit 0
fi

python3 "$sync_script" "$file_path" "$workspace_root" &

echo '{}'
exit 0
```

创建后执行：
```bash
chmod +x .cursor/hooks/sync-image-manifest.sh
```

---

## `aiworkspace/sync_image_manifest.py`

不要在文档里维护一份“可能过期”的完整脚本副本。请直接从 **`cs` 仓库复制最新实现**到产品项目的 `aiworkspace/sync_image_manifest.py`：

- 本地大仓路径示例：`cs/aiworkspace/sync_image_manifest.py`
- 或 raw：`https://raw.githubusercontent.com/bryanpeng-777/cs/main/aiworkspace/sync_image_manifest.py`（以你实际托管分支为准）

**行为约定（以脚本为准）**：
- 默认把图片台账写入：`~/.claude/knowledge/ui-assistant/{project}/image_manifest.json`
- `{project}`：默认取 `workspace_root` 最后一级目录名；若以 `-cursor` 结尾则去尾缀；也可用 `UI_ASSISTANT_PROJECT` / `IMAGE_MANIFEST_PROJECT` 显式指定
- 可用 `IMAGE_MANIFEST_PATH` 绝对路径覆盖；仅在特殊兼容场景使用 `CS_IMAGE_MANIFEST_LEGACY_PATH=1` 回退旧路径

> 因此：**无需**再在业务仓库创建 `aiworkspace/image_manifest.json`；首次需要时会自动在 knowledge 路径初始化。

---

## 完成后汇报

```
✅ 图片管理系统初始化完成
   .cursor/hooks.json                     ← afterFileEdit hook 已注册
   .cursor/hooks/sync-image-manifest.sh   ← hook 脚本已创建
   aiworkspace/sync_image_manifest.py       ← 增量同步脚本已创建（写入 knowledge 台账）

图片台账路径（默认）：
   ~/.claude/knowledge/ui-assistant/{project}/image_manifest.json

之后每次保存含 CsImage 的 dart 文件，新 configKey 会自动追加到 knowledge 台账。
```
