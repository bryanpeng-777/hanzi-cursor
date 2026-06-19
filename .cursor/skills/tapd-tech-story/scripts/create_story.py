#!/usr/bin/env python3
"""create_story.py - 生成 TAPD 技术需求五段式 HTML 描述
用法:
  交互式: python3 create_story.py
  命令行: python3 create_story.py --bg "背景" --content "需求" --platform "双端（iOS + 安卓）"
                                  --test "验收标准1,验收标准2" [--switch "无"]
  JSON:   python3 create_story.py ... --json   （输出 {"description": "<html>"}）
"""

import sys
import json
import argparse

TEMPLATE = """\
<p>1、背景：</p>
<p>{background}</p>
{background_list}\
<p>2、需求内容：</p>
<p>{content}</p>
{content_list}\
<p>3、平台（如：单端【安卓 or iOS】、双端、创作者中台、纯后台）：</p>
<p>{platform}</p>
<p>4、测试内容（提供路径和图片）：</p>
{test_list}\
<p>5、包含开关测试（开关预期表现）：</p>
<p>{switch_desc}</p>"""

PLATFORM_OPTIONS = [
    "单端【iOS】",
    "单端【安卓】",
    "双端（iOS + 安卓）",
    "创作者中台",
    "纯后台",
]


def make_ul(items: list) -> str:
    if not items:
        return ""
    li = "".join(f"<li>{item}</li>" for item in items)
    return f"<ul>{li}</ul>\n"


def build_html(background: str, content: str, platform: str,
               test_items: list, switch_desc: str,
               background_items: list = None,
               content_items: list = None) -> str:
    test_list = make_ul(test_items) if test_items else "<ul><li>（待填）</li></ul>\n"
    return TEMPLATE.format(
        background=background,
        background_list=make_ul(background_items or []),
        content=content,
        content_list=make_ul(content_items or []),
        platform=platform,
        test_list=test_list,
        switch_desc=switch_desc,
    )


def interactive_mode() -> dict:
    print("=== TAPD 技术需求五段式 HTML 生成器 ===\n")

    bg = input("1. 背景描述: ").strip()
    bg_items_str = input("   背景要点（逗号分隔，可留空）: ").strip()
    bg_items = [i.strip() for i in bg_items_str.split(",") if i.strip()]

    content = input("2. 需求内容/目标: ").strip()
    content_items_str = input("   方案要点（逗号分隔，可留空）: ").strip()
    content_items = [i.strip() for i in content_items_str.split(",") if i.strip()]

    print(f"   平台选项: {' / '.join(PLATFORM_OPTIONS)}")
    platform = input("3. 平台: ").strip()

    test_items_str = input("4. 测试验收标准（逗号分隔）: ").strip()
    test_items = [i.strip() for i in test_items_str.split(",") if i.strip()]

    switch_desc = input("5. 开关测试（无则直接回车）: ").strip() or "无"

    return {
        "background": bg,
        "background_items": bg_items,
        "content": content,
        "content_items": content_items,
        "platform": platform,
        "test_items": test_items,
        "switch_desc": switch_desc,
    }


def main():
    parser = argparse.ArgumentParser(description="生成 TAPD 五段式 HTML description")
    parser.add_argument("--bg", help="背景描述")
    parser.add_argument("--content", help="需求内容")
    parser.add_argument("--platform", default="双端（iOS + 安卓）", help="平台")
    parser.add_argument("--test", help="测试内容（逗号分隔）")
    parser.add_argument("--switch", default="无", help="开关测试（默认：无）")
    parser.add_argument("--json", action="store_true", help="输出 JSON 格式")
    args = parser.parse_args()

    if not args.bg:
        data = interactive_mode()
    else:
        test_items = [t.strip() for t in args.test.split(",")] if args.test else []
        data = {
            "background": args.bg,
            "background_items": [],
            "content": args.content or "",
            "content_items": [],
            "platform": args.platform,
            "test_items": test_items,
            "switch_desc": args.switch,
        }

    html = build_html(**data)

    if args.json:
        print(json.dumps({"description": html}, ensure_ascii=False, indent=2))
    else:
        print("\n=== 生成的 TAPD description HTML ===\n")
        print(html)
        print("\n=== 复制以上内容作为 create_story_or_task 的 description 参数 ===")


if __name__ == "__main__":
    main()
