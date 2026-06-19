#!/usr/bin/env python3
"""
Git 提交辅助脚本
用于分析代码变更，提取上一次提交的 TAPD ID，生成符合规范的提交信息
"""

import subprocess
import re
import sys
import os
from pathlib import Path


class GitCommitHelper:
    """Git 提交辅助类"""

    def __init__(self, repo_path=None):
        """初始化

        Args:
            repo_path: Git 仓库路径，如果为 None 则自动检测
        """
        self.repo_path = Path(repo_path) if repo_path else Path.cwd()
        self.validate_repo()

    def validate_repo(self):
        """验证是否在 Git 仓库中"""
        result = subprocess.run(
            ["git", "rev-parse", "--git-dir"],
            cwd=self.repo_path,
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            raise RuntimeError("Not in a git repository")

    def get_git_user(self):
        """获取当前 Git 用户信息

        Returns:
            dict: 包含用户信息的字典
                - name: 用户名
                - email: 用户邮箱
        """
        result = subprocess.run(
            ["git", "config", "user.name"],
            cwd=self.repo_path,
            capture_output=True,
            text=True
        )
        name = result.stdout.strip() if result.returncode == 0 else ""

        result = subprocess.run(
            ["git", "config", "user.email"],
            cwd=self.repo_path,
            capture_output=True,
            text=True
        )
        email = result.stdout.strip() if result.returncode == 0 else ""

        return {"name": name, "email": email}

    def get_last_commit_info(self):
        """获取当前登录用户的上一次提交信息

        Returns:
            dict: 包含提交信息的字典
                - hash: 提交哈希
                - subject: 提交标题
                - body: 提交正文
                - story_id: 提取的 story ID
                - bug_id: 提取的 bug ID
                - type: 提交类型 (feat/fix/其他)
                - author: 提交作者
        """
        # 获取当前用户信息
        user = self.get_git_user()

        # 使用 --author 参数过滤当前用户的提交
        author_filter = ""
        if user.get("email"):
            author_filter = f"--author={user['email']}"
        elif user.get("name"):
            author_filter = f"--author={user['name']}"

        result = subprocess.run(
            ["git", "log", "-1", author_filter, "--pretty=format:%H%n%s%n%b%n%an%n%ae"],
            cwd=self.repo_path,
            capture_output=True,
            text=True
        )

        if result.returncode != 0:
            return None

        lines = result.stdout.strip().split('\n')
        commit_hash = lines[0] if lines else ""
        subject = lines[1] if len(lines) > 1 else ""
        body = '\n'.join(lines[2:-2]) if len(lines) > 2 else ""
        author_name = lines[-2] if len(lines) >= 2 else ""
        author_email = lines[-1] if len(lines) >= 2 else ""

        # 提取提交类型
        commit_type = self._extract_commit_type(subject)

        # 提取 TAPD ID
        story_id = self._extract_tapd_id(body + "\n" + subject, "story")
        bug_id = self._extract_tapd_id(body + "\n" + subject, "bug")

        return {
            "hash": commit_hash,
            "subject": subject,
            "body": body,
            "story_id": story_id,
            "bug_id": bug_id,
            "type": commit_type,
            "author": f"{author_name} <{author_email}>"
        }

    def _extract_commit_type(self, subject):
        """从提交标题中提取类型

        Args:
            subject: 提交标题

        Returns:
            str: 提交类型 (feat/fix/其他)
        """
        # 匹配格式: "type(scope): description" 或 "type: description"
        match = re.match(r'^([a-z]+)(\([^)]+\))?:', subject)
        if match:
            return match.group(1)
        return "other"

    def _extract_tapd_id(self, text, id_type):
        """从文本中提取 TAPD ID

        Args:
            text: 文本内容
            id_type: ID 类型 ("story" 或 "bug")

        Returns:
            str: 提取的 ID，如果未找到则返回 None
        """
        # 匹配 --story=<id> 或 --bug=<id>
        pattern = rf'--{id_type}=(\d{{9,}})'
        match = re.search(pattern, text)
        if match:
            return match.group(1)
        return None

    def get_git_status(self):
        """获取 Git 状态

        Returns:
            dict: 包含状态信息的字典
                - staged: 已暂存的文件列表
                - unstaged: 未暂存的修改文件列表
                - untracked: 未跟踪的文件列表
        """
        result = subprocess.run(
            ["git", "status", "--porcelain"],
            cwd=self.repo_path,
            capture_output=True,
            text=True
        )

        if result.returncode != 0:
            return {"staged": [], "unstaged": [], "untracked": []}

        staged = []
        unstaged = []
        untracked = []

        for line in result.stdout.strip().split('\n'):
            if not line:
                continue

            status = line[:2]
            file_path = line[3:].strip()

            # 跳过特殊文件
            if self._should_ignore_file(file_path):
                continue

            if status[0] in ['M', 'A', 'D', 'R']:
                staged.append(file_path)
            elif status[0] == '?' and status[1] == '?':
                untracked.append(file_path)
            elif status[1] in ['M', 'D']:
                unstaged.append(file_path)

        return {
            "staged": staged,
            "unstaged": unstaged,
            "untracked": untracked
        }

    def _should_ignore_file(self, file_path):
        """判断是否应该忽略该文件

        Args:
            file_path: 文件路径

        Returns:
            bool: True 表示应该忽略
        """
        # 忽略 DS_Store 文件
        if ".DS_Store" in file_path:
            return True

        # 忽略以点开头的文件（隐藏文件）
        basename = os.path.basename(file_path)
        if basename.startswith('.'):
            return True

        return False

    def get_default_tapd_id(self, current_type):
        """根据当前提交类型获取默认的 TAPD ID

        Args:
            current_type: 当前提交类型 (feat/fix)

        Returns:
            dict: {"type": "story"/"bug", "id": "ID"} 或 None
        """
        last_commit = self.get_last_commit_info()
        if not last_commit:
            return None

        # 如果当前是 fix 类型
        if current_type == "fix":
            # 优先使用上一次的 bug ID（如果上一次也是 fix）
            if last_commit["type"] == "fix" and last_commit["bug_id"]:
                return {"type": "bug", "id": last_commit["bug_id"]}
            # 否则尝试从上一次提交的 body 中提取 bug ID
            elif last_commit["bug_id"]:
                return {"type": "bug", "id": last_commit["bug_id"]}
            # 如果上一次是 feat，尝试从 body 中提取 bug ID
            elif last_commit["type"] == "feat":
                # 重新提取 bug ID（可能在 body 中）
                bug_id = self._extract_tapd_id(last_commit["body"], "bug")
                if bug_id:
                    return {"type": "bug", "id": bug_id}
        else:
            # 当前是 feat 或其他类型，使用 story
            if last_commit["story_id"]:
                return {"type": "story", "id": last_commit["story_id"]}
            # 如果上一次是 fix，尝试从 body 中提取 story ID
            elif last_commit["type"] == "fix":
                story_id = self._extract_tapd_id(last_commit["body"], "story")
                if story_id:
                    return {"type": "story", "id": story_id}

        return None

    def analyze_changes(self):
        """分析代码变更，推荐提交类型和作用域

        Returns:
            dict: 分析结果
                - recommended_type: 推荐的提交类型
                - recommended_scope: 推荐的作用域
                - description_hint: 描述提示
        """
        status = self.get_git_status()
        all_files = status["staged"] + status["unstaged"] + status["untracked"]

        if not all_files:
            return None

        # 分析推荐类型
        recommended_type = self._analyze_commit_type(all_files)

        # 分析推荐作用域
        recommended_scope = self._analyze_scope(all_files)

        return {
            "recommended_type": recommended_type,
            "recommended_scope": recommended_scope,
            "files": all_files
        }

    def _analyze_commit_type(self, files):
        """根据文件变更分析推荐类型

        Args:
            files: 文件列表

        Returns:
            str: 推荐的提交类型，只返回 feat 或 fix
        """
        # 项目规范只允许 feat 和 fix 两种类型，统一返回 feat
        # fix 类型由用户根据实际修复内容主动选择
        return "feat"

    def _analyze_scope(self, files):
        """根据文件路径分析推荐作用域

        Args:
            files: 文件列表

        Returns:
            str: 推荐的作用域
        """
        # 检查依赖文件
        dep_files = ["pubspec.yaml", "pubspec.lock", "Podfile", "Podfile.lock", "Package.resolved"]
        if any(any(f.endswith(dep) for dep in dep_files) for f in files):
            return "dependency"

        # 检查数据库相关
        if any("database" in f for f in files):
            return "database"

        # 检查 UI 组件
        if any("camp_ui" in f for f in files):
            return "ui"

        # 检查路由
        if any("trouter" in f or "navigator" in f for f in files):
            return "router"

        # 检查网络
        if any("network" in f or "api" in f for f in files):
            return "network"

        return None


def main():
    """主函数"""
    try:
        helper = GitCommitHelper()

        # 获取当前用户信息
        user = helper.get_git_user()
        print("=== 当前 Git 用户 ===")
        if user["name"]:
            print(f"用户名: {user['name']}")
        if user["email"]:
            print(f"邮箱: {user['email']}")
        print()

        # 获取当前用户的上一次提交信息
        last_commit = helper.get_last_commit_info()
        print("=== 当前用户的上一次提交 ===")
        if last_commit:
            print(f"作者: {last_commit['author']}")
            print(f"提交: {last_commit['subject']}")
            print(f"类型: {last_commit['type']}")
            if last_commit['story_id']:
                print(f"Story ID: {last_commit['story_id']}")
            if last_commit['bug_id']:
                print(f"Bug ID: {last_commit['bug_id']}")
        else:
            print("当前用户没有找到提交记录")

        print()

        # 分析变更
        print("=== 当前变更 ===")
        status = helper.get_git_status()
        print(f"已暂存: {len(status['staged'])} 个文件")
        print(f"未暂存: {len(status['unstaged'])} 个文件")
        print(f"未跟踪: {len(status['untracked'])} 个文件")

        # 分析推荐
        analysis = helper.analyze_changes()
        if analysis:
            print()
            print("=== 推荐信息 ===")
            print(f"推荐类型: {analysis['recommended_type']}")
            if analysis['recommended_scope']:
                print(f"推荐作用域: {analysis['recommended_scope']}")

    except Exception as e:
        print(f"错误: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
