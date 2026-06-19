#!/usr/bin/env python3
"""
Flutter Deps Search — 在 Flutter 项目的三方依赖库源码中搜索符号/关键词。

用法：
  python3 flutter_deps_search.py <关键词> [--project <项目路径>] [--regex] [--all-files] [--limit 500]

支持：
  - hosted 包（pub.dev / 腾讯镜像）
  - git 包（含 monorepo 子包）
  - sdk 包（Flutter SDK 内置）
  - path 包（本地路径依赖）
  - FVM 多版本 pub-cache 自动检测
"""

import argparse
import os
import re
import sys
import yaml
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

MAX_RESULTS = 500
CONCURRENCY = 20


# ─────────────────────────────────────────────
# pubspec.lock 解析
# ─────────────────────────────────────────────

def parse_lock(lock_path: Path) -> list[dict]:
    """解析 pubspec.lock，返回所有包的描述信息列表。"""
    with open(lock_path, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f)

    packages = []
    for name, info in data.get("packages", {}).items():
        desc = info.get("description", {})
        source = info.get("source", "")
        version = info.get("version", "")

        pkg = {"name": name, "version": version, "source": source}

        if source == "git":
            pkg["resolved_ref"] = desc.get("resolved-ref") if isinstance(desc, dict) else None
            pkg["git_url"] = desc.get("url") if isinstance(desc, dict) else None
            pkg["git_path"] = desc.get("path", ".") if isinstance(desc, dict) else "."
        elif source == "path":
            if isinstance(desc, dict):
                pkg["path_value"] = desc.get("path", "")
                pkg["path_relative"] = desc.get("relative", True)
            else:
                pkg["path_value"] = str(desc) if desc else ""
                pkg["path_relative"] = True

        packages.append(pkg)

    return packages


# ─────────────────────────────────────────────
# pub-cache 路径解析
# ─────────────────────────────────────────────

def get_pub_cache_subdirs(sub: str) -> list[Path]:
    """收集所有候选 pub-cache 下指定子目录（hosted/git）。FVM 优先，标准路径降级。"""
    home = Path.home()
    paths = []

    for fvm_root in [home / ".fvm" / "versions", home / "fvm" / "versions"]:
        if fvm_root.exists():
            for ver_dir in fvm_root.iterdir():
                candidate = ver_dir / ".pub-cache" / sub
                if candidate.exists():
                    paths.append(candidate)

    standard = home / ".pub-cache" / sub
    if standard.exists():
        paths.append(standard)

    return paths


def get_flutter_sdk_roots() -> list[Path]:
    """收集所有候选 Flutter SDK 根目录。"""
    home = Path.home()
    roots = []

    for versions_dir in [home / "fvm" / "versions", home / ".fvm" / "versions"]:
        if versions_dir.exists():
            for ver_dir in versions_dir.iterdir():
                if (ver_dir / "packages" / "flutter").exists():
                    roots.append(ver_dir)

    for fvm_default in [home / "fvm" / "default", home / ".fvm" / "default"]:
        if (fvm_default / "packages" / "flutter").exists():
            try:
                real = fvm_default.resolve()
                if not any(r.resolve() == real for r in roots):
                    roots.append(fvm_default)
            except Exception:
                roots.append(fvm_default)

    standard = home / "flutter"
    if (standard / "packages" / "flutter").exists():
        roots.append(standard)

    return roots


def repo_name_from_url(url: str) -> str:
    """从 git URL 推导仓库名（去掉 .git 后缀）。"""
    last = url.rstrip("/").split("/")[-1]
    return re.sub(r"\.git$", "", last, flags=re.IGNORECASE)


# ─────────────────────────────────────────────
# 本地路径定位
# ─────────────────────────────────────────────

def find_hosted_path(name: str, version: str, hosted_roots: list[Path]) -> Path | None:
    dir_name = f"{name}-{version}"
    for hosted_root in hosted_roots:
        try:
            for mirror in hosted_root.iterdir():
                candidate = mirror / dir_name
                if candidate.exists():
                    return candidate
        except Exception:
            pass
    return None


def find_git_path(name: str, resolved_ref: str, git_url: str | None,
                  git_sub_path: str, git_roots: list[Path]) -> Path | None:
    repo_names = []
    if git_url:
        from_url = repo_name_from_url(git_url)
        repo_names.append(from_url)
        if from_url != name:
            repo_names.append(name)
    else:
        repo_names.append(name)

    for git_root in git_roots:
        for repo_name in repo_names:
            candidate = git_root / f"{repo_name}-{resolved_ref}"
            if git_sub_path and git_sub_path != ".":
                candidate = candidate / git_sub_path
            if candidate.exists():
                return candidate
    return None


def find_sdk_path(name: str, sdk_roots: list[Path]) -> Path | None:
    sub_paths = [
        Path("packages") / name,
        Path("bin") / "cache" / "pkg" / name,
        Path("bin") / "cache" / "dart-sdk" / "pkg" / name,
    ]
    for sdk_root in sdk_roots:
        for sub in sub_paths:
            candidate = sdk_root / sub
            if candidate.exists():
                return candidate
    return None


def resolve_packages(lock_path: Path, workspace_root: Path) -> list[dict]:
    """解析所有依赖包并定位本地路径，返回 {name, version, local_path} 列表。"""
    packages = parse_lock(lock_path)
    hosted_roots = get_pub_cache_subdirs("hosted")
    git_roots = get_pub_cache_subdirs("git")
    sdk_roots = get_flutter_sdk_roots()

    resolved = []
    for pkg in packages:
        name, version, source = pkg["name"], pkg["version"], pkg["source"]
        local_path = None

        if source == "git" and pkg.get("resolved_ref"):
            local_path = find_git_path(
                name, pkg["resolved_ref"], pkg.get("git_url"), pkg.get("git_path", "."), git_roots
            )
        elif source == "hosted":
            local_path = find_hosted_path(name, version, hosted_roots)
        elif source == "sdk":
            local_path = find_sdk_path(name, sdk_roots)
        elif source == "path" and pkg.get("path_value"):
            raw = pkg["path_value"]
            if pkg.get("path_relative", True):
                candidate = (workspace_root / raw).resolve()
            else:
                candidate = Path(raw)
            if candidate.exists():
                local_path = candidate

        if local_path:
            resolved.append({"name": name, "version": version, "local_path": local_path})

    return resolved


# ─────────────────────────────────────────────
# 搜索引擎
# ─────────────────────────────────────────────

def walk_dir(directory: Path, dart_only: bool):
    """递归遍历目录，跳过隐藏目录，yield 文件路径。"""
    try:
        entries = list(directory.iterdir())
    except Exception:
        return
    for entry in entries:
        if entry.name.startswith("."):
            continue
        if entry.is_dir():
            yield from walk_dir(entry, dart_only)
        elif entry.is_file():
            if not dart_only or entry.suffix == ".dart":
                yield entry


def search_file(file_path: Path, pkg: dict, matcher, results: list, max_results: int) -> bool:
    """在单个文件中搜索，匹配行追加到 results。返回 True 表示已达上限。"""
    try:
        content = file_path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return False

    rel = file_path.relative_to(pkg["local_path"])
    rel_str = str(rel)

    # 文件名匹配
    if matcher(rel_str):
        results.append({
            "package": pkg["name"],
            "version": pkg["version"],
            "file": rel_str,
            "line": 1,
            "text": f"[文件名] {file_path.name}",
        })
        if len(results) >= max_results:
            return True

    lines = content.split("\n")
    for i, raw_line in enumerate(lines):
        line = raw_line.rstrip("\r")
        if matcher(line):
            results.append({
                "package": pkg["name"],
                "version": pkg["version"],
                "file": rel_str,
                "line": i + 1,
                "text": line.strip(),
            })
            if len(results) >= max_results:
                return True

    return False


def search_package(pkg: dict, dart_only: bool, matcher, max_results: int) -> list:
    """在单个包目录中搜索，返回匹配结果列表。"""
    results = []
    for file_path in walk_dir(pkg["local_path"], dart_only):
        if search_file(file_path, pkg, matcher, results, max_results):
            break
    return results


def search(packages: list[dict], query: str, is_regex: bool, dart_only: bool,
           max_results: int = MAX_RESULTS) -> tuple[list, bool]:
    """并发搜索所有包，返回 (结果列表, 是否被截断)。"""
    if len(query.strip()) < 2:
        return [], False

    if is_regex:
        try:
            pattern = re.compile(query, re.IGNORECASE)
            matcher = lambda line: bool(pattern.search(line))
        except re.error as e:
            print(f"[错误] 正则表达式无效: {e}", file=sys.stderr)
            return [], False
    else:
        lower_q = query.lower()
        matcher = lambda line: lower_q in line.lower()

    all_results = []
    truncated = False

    with ThreadPoolExecutor(max_workers=CONCURRENCY) as executor:
        futures = {
            executor.submit(search_package, pkg, dart_only, matcher, max_results): pkg
            for pkg in packages
        }
        for future in as_completed(futures):
            try:
                pkg_results = future.result()
                all_results.extend(pkg_results)
                if len(all_results) >= max_results:
                    truncated = True
                    # 取消剩余任务（尽力而为）
                    for f in futures:
                        f.cancel()
                    break
            except Exception as e:
                pkg = futures[future]
                print(f"[警告] 搜索包 {pkg['name']} 时出错: {e}", file=sys.stderr)

    if truncated:
        all_results = all_results[:max_results]

    return all_results, truncated


# ─────────────────────────────────────────────
# 输出格式化
# ─────────────────────────────────────────────

def format_results(results: list, truncated: bool, query: str) -> str:
    if not results:
        return f"未找到包含 '{query}' 的结果。"

    # 按包分组
    groups: dict[str, list] = {}
    for r in results:
        key = f"{r['package']} {r['version']}"
        groups.setdefault(key, []).append(r)

    lines = [f"搜索 '{query}' — 共 {len(results)} 条结果，涉及 {len(groups)} 个包\n"]

    for pkg_key, items in groups.items():
        lines.append(f"📦 {pkg_key}  ({len(items)} 条)")
        for item in items:
            prefix = f"  {item['file']}:{item['line']}"
            text_preview = item['text'][:120]
            lines.append(f"    {prefix}")
            lines.append(f"      {text_preview}")
        lines.append("")

    if truncated:
        lines.append(f"⚠️  结果已截断（上限 {MAX_RESULTS} 条），请细化关键词。")

    return "\n".join(lines)


# ─────────────────────────────────────────────
# 入口
# ─────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="在 Flutter 项目三方依赖库源码中搜索符号/关键词"
    )
    parser.add_argument("query", help="搜索关键词（至少 2 个字符）")
    parser.add_argument("--project", "-p", default=".", help="Flutter 项目根目录（含 pubspec.lock）")
    parser.add_argument("--regex", "-r", action="store_true", help="将关键词作为正则表达式处理")
    parser.add_argument("--all-files", "-a", action="store_true",
                        help="搜索所有文件类型（默认只搜 .dart 文件）")
    parser.add_argument("--limit", "-l", type=int, default=MAX_RESULTS,
                        help=f"结果上限（默认 {MAX_RESULTS}）")
    parser.add_argument("--json", action="store_true", help="以 JSON 格式输出结果")

    args = parser.parse_args()

    project_root = Path(args.project).resolve()
    lock_path = project_root / "pubspec.lock"

    if not lock_path.exists():
        print(f"[错误] 未找到 pubspec.lock：{lock_path}", file=sys.stderr)
        print("请先运行 flutter pub get", file=sys.stderr)
        sys.exit(1)

    print(f"正在解析依赖包...", file=sys.stderr)
    packages = resolve_packages(lock_path, project_root)
    print(f"找到 {len(packages)} 个依赖包，开始搜索...", file=sys.stderr)

    dart_only = not args.all_files
    results, truncated = search(packages, args.query, args.regex, dart_only, args.limit)

    if args.json:
        import json
        print(json.dumps({
            "query": args.query,
            "total": len(results),
            "truncated": truncated,
            "results": results
        }, ensure_ascii=False, indent=2))
    else:
        # 将 Path 对象序列化为字符串（JSON 输出时才用，这里直接打印）
        print(format_results(results, truncated, args.query))


if __name__ == "__main__":
    main()
