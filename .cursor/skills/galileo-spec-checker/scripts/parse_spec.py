#!/usr/bin/env python3
"""
解析伽利略指标汇总 xlsx，提取指定 module 的规范定义。
用法：python parse_spec.py <xlsx_path> <module_keyword> [--sheet SHEET_NAME]
"""
import sys
import re
import argparse

try:
    import pandas as pd
except ImportError:
    print("ERROR: pandas not installed. Run: uv pip install pandas python-calamine --system")
    sys.exit(1)


def extract_camp_type_from_alias(alias: str, raw_params: str = '') -> str | None:
    if not alias or alias == '-' or str(alias).strip() == '-':
        return 'before/after'
    alias_lower = str(alias).lower()
    if '-start' in alias_lower:
        return 'start'
    if '-end' in alias_lower:
        return 'end'
    if '-step' in alias_lower or alias_lower.endswith('step'):
        return 'step'
    # 从参数列中提取 campType 作为兜底
    if raw_params:
        m = re.search(r'campType\s*=\s*(\w+)', str(raw_params))
        if m:
            return m.group(1).lower()
    return None


def extract_step_name(alias: str) -> str | None:
    """从指标别名中提取 step 名称，如 '手动登录-隐私协议-step' -> 'showPrivacy'"""
    return None  # step 名称从参数列中提取更准确


def extract_params(param_str: str) -> list[str]:
    """从参数列中提取参数 key 列表"""
    if not param_str or pd.isna(param_str):
        return []
    params = []
    lines = str(param_str).split('\n')
    for line in lines:
        line = line.strip()
        match = re.match(r'^([a-zA-Z_][a-zA-Z0-9_]*)\s*=', line)
        if match:
            key = match.group(1)
            if key not in ('moduleName', 'campType'):  # 通用参数不计入
                params.append(key)
    return params


def extract_step_value(param_str: str) -> str | None:
    """从参数列中提取 step 的具体值"""
    if not param_str or pd.isna(param_str):
        return None
    match = re.search(r'step\s*=\s*["\']?([^"\'\n\\]+)["\']?', str(param_str))
    if match:
        return match.group(1).strip().strip('"').strip("'")
    return None


def parse_spec(xlsx_path: str, keyword: str, sheet_name: str = '基础&核心指标') -> dict:
    """
    解析 xlsx，返回匹配 keyword 的 module 规范。
    keyword 可以是中文模块名或英文 moduleName。
    返回格式：
    {
        "module_name": "登录",
        "entries": [
            {
                "moduleName": "AutoLogin",
                "alias": "自动登录-start",
                "campType": "start",
                "params": ["loginSourceType", "newUserId"],
                "step": None,
                "raw_params": "...",
            },
            ...
        ]
    }
    """
    try:
        df = pd.read_excel(xlsx_path, sheet_name=sheet_name, engine='calamine')
    except Exception as e:
        print(f"ERROR reading xlsx: {e}")
        sys.exit(1)

    col_names = ['模块', '监控项名称', '子项', '指标别名', '上报名称', '参数', '描述', '监控+告警', '按天量级', '上线版本', '数据校验', '平台', '建设记录', '备注']
    df.columns = col_names[:len(df.columns)]

    df['模块'] = df['模块'].ffill()
    df['监控项名称'] = df['监控项名称'].ffill()
    df['上报名称'] = df['上报名称'].ffill()

    # 匹配：中文模块名 或 英文 moduleName
    keyword_lower = keyword.lower()
    mask = (
        df['模块'].astype(str).str.contains(keyword, case=False, na=False) |
        df['上报名称'].astype(str).str.lower().str.contains(keyword_lower, na=False)
    )
    matched = df[mask].copy()

    if matched.empty:
        print(f"未找到匹配 '{keyword}' 的 module，请检查关键词")
        sys.exit(1)

    module_name = matched['模块'].iloc[0]
    entries = []

    for _, row in matched.iterrows():
        alias = str(row.get('指标别名', '')) if pd.notna(row.get('指标别名')) else ''
        raw_params_val = str(row.get('参数', '')) if pd.notna(row.get('参数')) else ''
        camp_type = extract_camp_type_from_alias(alias, raw_params_val)
        params = extract_params(row.get('参数', ''))
        step_val = extract_step_value(row.get('参数', '')) if camp_type == 'step' else None
        module_name_code = str(row.get('上报名称', '')) if pd.notna(row.get('上报名称')) else ''
        platform = str(row.get('平台', '')) if pd.notna(row.get('平台')) else ''

        entries.append({
            'moduleName': module_name_code,
            'alias': alias,
            'campType': camp_type,
            'params': params,
            'step': step_val,
            'platform': platform,
            'raw_params': str(row.get('参数', '')) if pd.notna(row.get('参数')) else '',
            'description': str(row.get('描述', '')) if pd.notna(row.get('描述')) else '',
        })

    return {'module_name': module_name, 'entries': entries}


def print_spec(spec: dict):
    print(f"\n=== 模块：{spec['module_name']} ===\n")
    current_mn = None
    for e in spec['entries']:
        if e['moduleName'] != current_mn:
            current_mn = e['moduleName']
            print(f"【moduleName: {current_mn}】")

        camp = e['campType'] or '(未识别)'
        alias = e['alias'] or '-'
        params_str = ', '.join(e['params']) if e['params'] else '无额外参数'
        step_str = f" step=\"{e['step']}\"" if e['step'] else ''
        platform = f" [{e['platform']}]" if e['platform'] else ''

        print(f"  {camp}{step_str}{platform}")
        print(f"    别名: {alias}")
        print(f"    参数: {params_str}")
        if e['raw_params'] and e['raw_params'] != 'nan':
            raw_lines = [l.strip() for l in e['raw_params'].split('\n') if l.strip()]
            for l in raw_lines[:5]:
                print(f"      {l}")
        print()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('xlsx_path', help='xlsx 文件路径')
    parser.add_argument('keyword', help='模块名或 moduleName 关键词')
    parser.add_argument('--sheet', default='基础&核心指标', help='Sheet 名称')
    args = parser.parse_args()

    spec = parse_spec(args.xlsx_path, args.keyword, args.sheet)
    print_spec(spec)
