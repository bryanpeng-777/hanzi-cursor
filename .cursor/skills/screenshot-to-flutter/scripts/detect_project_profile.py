#!/usr/bin/env python3
"""Detect Flutter project stack for screenshot-to-flutter skill."""

from __future__ import annotations

import json
import sys
from pathlib import Path


def read_pubspec(project_root: Path) -> str:
    pubspec = project_root / "pubspec.yaml"
    if not pubspec.exists():
        return ""
    return pubspec.read_text(encoding="utf-8")


def detect_profile(project_root: Path) -> dict:
    root = project_root.resolve()
    pubspec = read_pubspec(root)
    name = root.name

    has_cs_ui = "cs_ui" in pubspec
    has_riverpod = "flutter_riverpod" in pubspec or "riverpod" in pubspec
    has_go_router = "go_router" in pubspec
    has_screenutil = "flutter_screenutil" in pubspec
    has_google_fonts = "google_fonts" in pubspec

    hanzi_spec = root / "lib/design/hanzi_design_spec.dart"
    is_hanzi = "hanzi" in name.lower() or hanzi_spec.exists()

    if is_hanzi:
        profile = "hanzi-cursor"
    elif has_cs_ui:
        profile = "cs-flutter"
    else:
        profile = "flutter-material"

    design_files: list[str] = []
    for candidate in [
        "lib/design/hanzi_design_spec.dart",
        "lib/design/hanzi_shared_widgets.dart",
        "lib/utils/app_theme.dart",
    ]:
        if (root / candidate).exists():
            design_files.append(candidate)

    return {
        "project_root": str(root),
        "project_name": name,
        "profile": profile,
        "stack": {
            "cs_ui": has_cs_ui,
            "riverpod": has_riverpod,
            "go_router": has_go_router,
            "screenutil": has_screenutil,
            "google_fonts": has_google_fonts,
        },
        "design_files": design_files,
        "stack_doc": "references/flutter-stack.md",
        "profile_doc": "references/project-profiles.md",
    }


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: detect_project_profile.py <project_root>", file=sys.stderr)
        sys.exit(1)

    result = detect_profile(Path(sys.argv[1]))
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
