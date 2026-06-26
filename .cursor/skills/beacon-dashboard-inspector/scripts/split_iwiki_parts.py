#!/usr/bin/env python3
"""将 Markdown 报告切分为 iWiki MCP 可上传的分片，避免表格行中途断开。

iWiki 渲染限制（详见 beacon-dashboard-inspector SKILL「iWiki Markdown 兼容规范」）：
- 表格行紧接 ``---`` 时末行会脱离表格
- 单表行数过多（>6 行 × 宽列）时末行可能脱离
- saveDocumentParts 追加时在片边界插入空行，不可在单表中间分片

因此：按 ``##`` 章节打包；片边界对表格行补空行；万不得已按行切分时重复表头。
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import List, Sequence

# JSON 编码后字节上限（iWiki MCP 约 4KB）
DEFAULT_MAX_JSON_CHARS = 3900


def json_encoded_size(text: str) -> int:
    return len(json.dumps(text, ensure_ascii=False))


def is_table_line(line: str) -> bool:
    return line.lstrip().startswith("|")


def split_table_rows(lines: Sequence[str], max_json: int) -> List[str]:
    """将连续表格行切成多个子块，续块重复表头与分隔行。"""
    if not lines:
        return []
    if len(lines) == 1:
        return ["\n".join(lines)]

    header = lines[0]
    sep = lines[1] if len(lines) > 1 and is_table_line(lines[1]) else None
    data_start = 2 if sep else 1
    prefix = [header] + ([sep] if sep else [])

    chunks: List[str] = []
    current = list(prefix)

    for row in lines[data_start:]:
        candidate = "\n".join(current + [row])
        if json_encoded_size(candidate) > max_json and len(current) > len(prefix):
            chunks.append("\n".join(current))
            current = list(prefix) + [row]
        else:
            current.append(row)

    if current:
        chunks.append("\n".join(current))
    return chunks


def iter_blocks(text: str):
    """按行遍历，产出 (kind, content)；kind 为 'text' 或 'table'。"""
    lines = text.split("\n")
    i = 0
    while i < len(lines):
        if is_table_line(lines[i]):
            table_lines: List[str] = []
            while i < len(lines) and is_table_line(lines[i]):
                table_lines.append(lines[i])
                i += 1
            yield "table", table_lines
        else:
            text_lines: List[str] = []
            while i < len(lines) and not is_table_line(lines[i]):
                text_lines.append(lines[i])
                i += 1
            yield "text", text_lines


def blocks_to_string(blocks) -> str:
    parts: List[str] = []
    for kind, content in blocks:
        if kind == "table":
            parts.append("\n".join(content))
        else:
            parts.append("\n".join(content))
    return "\n".join(p for p in parts if p != "")


def split_oversized_section(section: str, max_json: int) -> List[str]:
    """单个看板段落仍超限时，在表格行边界切分。"""
    blocks = list(iter_blocks(section))
    parts: List[str] = []
    current_blocks = []

    def flush():
        nonlocal current_blocks
        if current_blocks:
            parts.append(blocks_to_string(current_blocks))
            current_blocks = []

    for kind, content in blocks:
        if kind == "table":
            table_text = "\n".join(content)
            if json_encoded_size(table_text) <= max_json:
                trial = blocks_to_string(current_blocks + [("table", content)])
                if current_blocks and json_encoded_size(trial) > max_json:
                    flush()
                current_blocks.append(("table", content))
            else:
                flush()
                for chunk in split_table_rows(content, max_json):
                    if json_encoded_size(chunk) <= max_json:
                        parts.append(chunk)
                    else:
                        raise ValueError(
                            f"单行表格仍超过上限 ({json_encoded_size(chunk)} chars JSON)，"
                            "请缩短处理建议列"
                        )
        else:
            text = "\n".join(content)
            if not text.strip():
                if current_blocks:
                    current_blocks.append(("text", content))
                continue
            trial = blocks_to_string(current_blocks + [("text", content)])
            if current_blocks and json_encoded_size(trial) > max_json:
                flush()
            current_blocks.append(("text", content))

    flush()
    return parts


def join_sections(left: str, right: str) -> str:
    """拼接段落，避免 ``| 末列 |---`` 粘在行尾。"""
    if not left:
        return right
    if not right:
        return left
    return left.rstrip("\n") + "\n" + right.lstrip("\n")


def subdivide_section(section: str, max_json: int, depth: int = 0) -> List[str]:
    """将过长段落按标题层级再拆，仍超限则按表格行切分。"""
    if json_encoded_size(section) <= max_json:
        return [section]
    if depth > 12:
        return split_oversized_section(section, max_json)

    for pattern in (r"(?=\n## )", r"(?=\n### )", r"(?=\n#### )"):
        chunks = [c for c in re.split(pattern, section) if c.strip()]
        if len(chunks) > 1:
            atomic: List[str] = []
            for chunk in chunks:
                atomic.extend(subdivide_section(chunk, max_json, depth + 1))
            return atomic

    return split_oversized_section(section, max_json)


def pack_sections(sections: List[str], max_json: int) -> List[str]:
    """贪心合并段落，保证每片不超限且不在表内断开。"""
    parts: List[str] = []
    current = ""

    for section in sections:
        if json_encoded_size(section) > max_json:
            if current:
                parts.append(current)
                current = ""
            parts.extend(subdivide_section(section, max_json))
            continue

        if not current:
            current = section
            continue

        joined = join_sections(current, section)
        if json_encoded_size(joined) <= max_json:
            current = joined
        else:
            parts.append(current)
            current = section

    if current:
        parts.append(current)
    return parts


def fix_iwiki_table_breaks(text: str) -> str:
    """表格行紧接 --- 时 iWiki 会断表，插入空行隔离。"""
    return re.sub(r"^(\|[^\n]+)\n---$", r"\1\n\n---", text, flags=re.MULTILINE)


def fix_part_boundaries(parts: List[str]) -> List[str]:
    """saveDocumentParts 追加时会在片间断表：前片以表格行结尾时补空行，后片前补空行。"""
    fixed: List[str] = []
    for i, p in enumerate(parts):
        body = p.strip("\n")
        if i > 0:
            body = "\n\n" + body.lstrip("\n")
        lines = body.split("\n")
        while lines and not lines[-1].strip():
            lines.pop()
        if i < len(parts) - 1 and lines and lines[-1].lstrip().startswith("|"):
            body = "\n".join(lines) + "\n\n\n"
        else:
            body = "\n".join(lines) + "\n"
        fixed.append(body)
    return fixed


def split_sections(text: str, max_json: int = DEFAULT_MAX_JSON_CHARS) -> List[str]:
    """按 ``##`` 章节切分并打包，避免在表格中间分片。"""
    text = fix_iwiki_table_breaks(text)
    # 优先按二级标题切（已移除 --- 分隔符）
    sections = [s for s in re.split(r"(?=\n## )", text) if s.strip()]
    if not sections:
        sections = [text]

    atomic: List[str] = []
    for section in sections:
        if json_encoded_size(section) <= max_json:
            atomic.append(section)
        else:
            atomic.extend(subdivide_section(section, max_json))

    return fix_part_boundaries(_normalize_parts(pack_sections(atomic, max_json), max_json))


def _normalize_parts(parts: List[str], max_json: int) -> List[str]:
    """去掉首尾多余空行；确保每片 JSON 不超限。"""
    normalized: List[str] = []
    for part in parts:
        cleaned = part.strip("\n")
        if not cleaned:
            continue
        size = json_encoded_size(cleaned)
        if size > max_json:
            raise ValueError(f"分片仍超限: {size} > {max_json}")
        normalized.append(cleaned + "\n")
    return normalized


def verify_parts(parts: List[str], max_json: int = DEFAULT_MAX_JSON_CHARS) -> List[str]:
    """返回警告列表（空表示通过基础检查）。"""
    warnings: List[str] = []
    for i, part in enumerate(parts):
        if json_encoded_size(part) >= max_json:
            warnings.append(f"part {i}: JSON 大小 {json_encoded_size(part)} >= {max_json}")
        for line in part.split("\n"):
            # 分隔行 |------| 也含 ---，只检测数据行末粘连 ``| — |---``
            if is_table_line(line) and not re.match(r"^\|[\s\-:|]+\|$", line.strip()):
                if re.search(r"\|---\s*$", line):
                    warnings.append(f"part {i}: 表格行末粘连 --- : {line[:80]}")
        lines = part.split("\n")
        for j in range(1, len(lines)):
            if is_table_line(lines[j - 1]) and lines[j].strip() == "" and j + 1 < len(lines):
                if is_table_line(lines[j + 1]):
                    warnings.append(
                        f"part {i} line {j + 1}: 表格行之间有空行，iWiki 可能断表"
                    )
    return warnings


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="切分 Markdown 供 iWiki 分批写入")
    parser.add_argument("input", type=Path, help="完整 Markdown 报告路径")
    parser.add_argument(
        "-o",
        "--output-dir",
        type=Path,
        default=Path("/tmp/beacon_inspector"),
        help="输出目录（写入 iwiki_parts.json 与 part_XX.md）",
    )
    parser.add_argument(
        "--max-json",
        type=int,
        default=DEFAULT_MAX_JSON_CHARS,
        help="单分片 json.dumps 字符上限",
    )
    args = parser.parse_args(argv)

    text = args.input.read_text(encoding="utf-8")
    parts = split_sections(text, args.max_json)
    warnings = verify_parts(parts, args.max_json)

    args.output_dir.mkdir(parents=True, exist_ok=True)
    for i, part in enumerate(parts):
        (args.output_dir / f"part_{i:02d}.md").write_text(part, encoding="utf-8")
    (args.output_dir / "iwiki_parts.json").write_text(
        json.dumps(parts, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    print(f"split into {len(parts)} parts, total chars {len(text)}")
    for i, part in enumerate(parts):
        print(f"  part {i}: {len(part)} chars, json={json_encoded_size(part)}")
    if warnings:
        for w in warnings:
            print(f"WARN: {w}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
