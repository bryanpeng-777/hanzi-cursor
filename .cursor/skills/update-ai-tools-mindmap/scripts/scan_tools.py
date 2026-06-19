#!/usr/bin/env python3
"""
扫描所有 agent 和 skill 文件，提取名称 + 描述，输出 JSON。
"""
import os
import re
import json
from pathlib import Path

HOME = Path.home()

def strip_frontmatter(content: str) -> str:
    """去掉 YAML frontmatter，返回正文。"""
    if content.startswith('---'):
        end = content.find('\n---', 3)
        if end != -1:
            return content[end + 4:].lstrip('\n')
    return content

def extract_desc(path: Path) -> str:
    """从 SKILL.md 或 agent .md 文件提取第一句有意义的描述。"""
    try:
        content = path.read_text(encoding='utf-8')
    except Exception:
        return ''

    body = strip_frontmatter(content)
    for line in body.splitlines():
        line = line.strip()
        if not line:
            continue
        # 跳过标题、表格、代码块、列表
        if line.startswith('#') or line.startswith('|') or line.startswith('```') or line.startswith('---'):
            continue
        # 跳过纯链接行
        if line.startswith('[') or line.startswith('http'):
            continue
        # 去掉 markdown 粗体
        line = re.sub(r'\*\*(.+?)\*\*', r'\1', line)
        # 去掉 markdown 斜体
        line = re.sub(r'\*(.+?)\*', r'\1', line)
        # 去掉内联代码
        line = re.sub(r'`(.+?)`', r'\1', line)
        # 截到合理长度
        return line[:200]
    return ''

def scan_agents() -> dict:
    agents_dir = HOME / '.claude' / 'agents'
    result = {}
    if not agents_dir.exists():
        return result
    for f in sorted(agents_dir.glob('*.md')):
        name = f.stem
        desc = extract_desc(f)
        result[name] = {'desc': desc, 'type': 'agent', 'path': str(f)}
    return result

def scan_skills() -> dict:
    result = {}

    # Claude skills: 直接子目录
    skills_dir = HOME / '.claude' / 'skills'
    if skills_dir.exists():
        for d in sorted(skills_dir.iterdir()):
            skill_md = d / 'SKILL.md'
            if skill_md.exists() and d.is_dir():
                name = d.name
                # 跳过已废弃的和纯子集目录
                if name in ('cs-plugins', 'camp', 'skill-from-masters', 'mydrawio'):
                    # 还要扫描它们的子目录
                    for sub in sorted(d.iterdir()):
                        sub_md = sub / 'SKILL.md'
                        if sub_md.exists():
                            sub_name = f"{name}/{sub.name}"
                            result[sub_name] = {
                                'desc': extract_desc(sub_md),
                                'type': 'skill',
                                'path': str(sub_md),
                            }
                    continue
                result[name] = {
                    'desc': extract_desc(skill_md),
                    'type': 'skill',
                    'path': str(skill_md),
                }

    # Cursor skills
    cursor_skills = HOME / '.cursor' / 'skills-cursor'
    if cursor_skills.exists():
        for d in sorted(cursor_skills.iterdir()):
            skill_md = d / 'SKILL.md'
            if skill_md.exists() and d.is_dir():
                name = d.name
                result[f'cursor/{name}'] = {
                    'desc': extract_desc(skill_md),
                    'type': 'cursor',
                    'path': str(skill_md),
                }

    # Superpowers
    sp_base = HOME / '.cursor' / 'plugins' / 'cache' / 'cursor-public' / 'superpowers'
    if sp_base.exists():
        for ver_dir in sorted(sp_base.iterdir()):
            sp_skills = ver_dir / 'skills'
            if sp_skills.exists():
                for d in sorted(sp_skills.iterdir()):
                    skill_md = d / 'SKILL.md'
                    if skill_md.exists():
                        name = d.name
                        result[f'superpower/{name}'] = {
                            'desc': extract_desc(skill_md),
                            'type': 'superpower',
                            'path': str(skill_md),
                        }

    return result

def extract_canvas_items(canvas_path: Path) -> dict:
    """从 canvas TSX 文件中提取所有 { id, name, desc } 节点。"""
    if not canvas_path.exists():
        return {}
    content = canvas_path.read_text(encoding='utf-8')
    # 匹配 { id: 'xxx', name: 'yyy', ... desc: 'zzz' ... }
    # 每个节点通常是单行或多行
    items = {}
    # 简单提取所有 name + desc 对
    node_pattern = re.compile(
        r"id:\s*'([^']+)'.*?name:\s*'([^']+)'.*?desc:\s*'([^']*)'",
        re.DOTALL
    )
    for m in node_pattern.finditer(content):
        node_id, name, desc = m.group(1), m.group(2), m.group(3)
        items[node_id] = {'name': name, 'desc': desc}
    return items

def main():
    canvas_path = HOME / '.claude' / 'knowledge' / 'ai-tools-mindmap.canvas.tsx'

    agents = scan_agents()
    skills = scan_skills()
    canvas_items = extract_canvas_items(canvas_path)

    # 合并所有工具
    all_tools = {}
    for name, info in agents.items():
        all_tools[name] = info
    for name, info in skills.items():
        all_tools[name] = info

    # 找出 canvas 中的 name → 从 all_tools 找对应描述
    # canvas name 可能包含 assistant 名、(master-assistant) 等
    updates = []   # {id, name, old_desc, new_desc}
    in_canvas_names = {v['name']: (k, v) for k, v in canvas_items.items() if not v.get('xref')}

    # 简化 canvas name 用于匹配
    def normalize(n: str) -> str:
        # 去掉括号里的内容，取最后的 identifier
        n = re.sub(r'\s*\([^)]*\)', '', n).strip()
        return n.lower()

    for tool_name, tool_info in all_tools.items():
        simple = tool_name.split('/')[-1]  # e.g. camp/code-locator → code-locator
        # 在 canvas 中查找匹配的节点
        for canvas_name, (cid, cinfo) in in_canvas_names.items():
            if normalize(canvas_name) == normalize(simple) or normalize(canvas_name) == normalize(tool_name):
                old_desc = cinfo['desc']
                new_desc = tool_info['desc']
                if new_desc and old_desc != new_desc:
                    updates.append({
                        'id': cid,
                        'name': canvas_name,
                        'old_desc': old_desc,
                        'new_desc': new_desc,
                    })
                break

    # 找出在 all_tools 中但不在 canvas 中的工具（新增）
    canvas_all_names = {normalize(v['name']) for v in canvas_items.values()}
    new_tools = []
    for tool_name, tool_info in all_tools.items():
        simple = normalize(tool_name.split('/')[-1])
        full = normalize(tool_name)
        if simple not in canvas_all_names and full not in canvas_all_names:
            # 过滤掉已废弃技能
            deprecated_keywords = ['deprecated', 'backup', 'mistake-', 'go-to-dir', 'using-superpowers',
                                    'cs-framework-onboarding', 'cs-stack-onboarding', 'cs-stack-checker',
                                    'cs-image-manager', 'cs-lottie-manager', 'cs-video-manager',
                                    'cs-ui-onboarding', 'galileo-auto-recorder', 'bugly-auto-recorder',
                                    'skill-creator.backup']
            if not any(kw in tool_name for kw in deprecated_keywords):
                new_tools.append({'name': tool_name, 'type': tool_info['type'], 'desc': tool_info['desc']})

    output = {
        'updates': updates,
        'new_tools': new_tools,
        'total_agents': len(agents),
        'total_skills': len([k for k in skills if not k.startswith('superpower/')]),
        'canvas_items': len(canvas_items),
    }
    print(json.dumps(output, ensure_ascii=False, indent=2))

if __name__ == '__main__':
    main()
