---
name: craft-doc-organizer
description: Automatically classify and organize unclassified Craft documents into the established 10-folder knowledge base system. Use this skill whenever the user mentions "归类文档", "整理笔记", "整理文档", "classify documents", "organize notes", "分类新文档", "文档整理", "归档笔记", or when the user has new Craft documents that need to be filed into the existing folder hierarchy. Also trigger when the user says things like "帮我整理一下Craft", "新建的笔记帮我归类", "把这些文档分一下类", or anything about organizing, sorting, or filing Craft documents.
---

# Craft Document Organizer

Automatically classify unclassified Craft documents and move them into bryanpeng's established 10-folder knowledge base system.

## Knowledge Base Structure Overview

The system has 10 top-level folders, each with semantic sub-folders:

| Top-Level Folder | Domain |
|---|---|
| **Tech-iOS** | iOS/ObjC/Swift development |
| **Tech-Flutter** | Flutter/Dart development |
| **Tech-Architecture** | Design patterns, architecture, code quality |
| **Tech-GameDev** | Unity, Shader, game development |
| **Tech-Toolchain** | Xcode, Git, CocoaPods, tools |
| **Project-营地** | 王者营地 business modules |
| **Project-AI** | AI tools, pipelines, practices |
| **Archive-工作记录** | Work logs, OKRs, summaries by year |
| **Growth-方法论** | Learning methods, coding insights, life philosophy |
| **Life-个人** | Finance, health, personal records |

Read `references/folder-map.md` (in the skill directory) to get the full sub-folder breakdown with classification keywords before starting classification.

## Workflow

### Step 1: Discover unclassified documents

Determine where unclassified documents live. Common sources:
- **Unsorted**: Craft's built-in unsorted location — check first via `documents_list` with `location: "unsorted"`
- **Specific folder**: If the user specifies a source folder, list documents there via `documents_list` with `folderIds`
- **Root-level stray documents**: User may point to specific documents

If the user doesn't specify a source, check Unsorted first. If empty, ask the user where the new documents are.

### Step 2: Fetch folder structure

Call Craft MCP `folders_list` to get the current folder tree with IDs. Match folder names against the known structure to build a name-to-ID lookup table. This ensures correct folder IDs even if they change in the future.

### Step 3: Read and classify each document

For each unclassified document:

1. **Read the title** from the `documents_list` result — often sufficient for classification
2. **If the title is ambiguous**, read the first few blocks of content via `blocks_get` (with `id` = document ID, `maxDepth: 1`, `format: "markdown"`) to understand the topic
3. **Match against classification rules** (see `references/folder-map.md`) to determine the target sub-folder

Classification priority:
- Exact keyword match in title → high confidence
- Content-based classification → medium confidence
- If still ambiguous → flag for user decision

#### Handling documents that don't fit existing categories

If one or more documents genuinely don't belong to any of the 10 existing top-level categories — not even loosely — group them by their common theme and propose a **new top-level folder**. This typically happens when the user starts exploring a new domain (e.g., backend development, product management, hardware/IoT).

Criteria for proposing a new folder:
- At least 2 documents share a common theme that doesn't map to any existing category
- The theme is distinct enough that shoehorning documents into an existing folder would hurt retrieval quality
- A single orphan document should be flagged as "需确认" rather than immediately proposing a new category — the user may prefer to place it manually

When proposing a new folder:
- Follow the existing naming convention: `Domain-中文描述` (e.g., `Tech-Backend`, `Product-产品`, `Tech-Embedded`)
- Suggest 2-3 initial sub-folders based on the documents at hand
- Clearly explain why existing categories are insufficient

### Step 4: Present classification plan

Before moving anything, present a clear summary table to the user:

```
| # | Document Title | Target Folder | Confidence |
|---|----------------|---------------|------------|
| 1 | RunLoop详解 | Tech-iOS / 多线程与性能 | High |
| 2 | 新笔记 | (需确认) | Low |
```

If new folders are proposed, add a separate section **before** the document table:

```
📁 建议新建以下一级目录：

1. **Tech-Backend** — 后端/服务端开发
   - 建议子目录：数据库、API设计、部署与运维
   - 原因：发现 3 篇文档涉及 Node.js/MySQL/Redis，现有分类均偏客户端
   - 涉及文档：「MySQL索引优化」「Redis缓存策略」「REST API设计」

请确认是否创建，或指定归入现有目录。
```

Ask the user to confirm or adjust. Only proceed after confirmation.

### Step 5: Create new folders (if approved)

If the user confirmed creating new top-level folders:

1. Use Craft MCP `folders_create` to create the top-level folder (omit `parentFolderId` for root level)
2. Create sub-folders under it using `folders_create` with `parentFolderId` set to the new folder's ID
3. Update the name-to-ID lookup table with the newly created folders
4. After creating, also update `references/folder-map.md` in the skill directory to include the new category with its keywords — this ensures future classification runs recognize the new domain

If the user declines, handle those documents per their instructions (move to an existing folder, skip, etc.).

### Step 6: Execute moves

Use Craft MCP `documents_move` to move documents in batches:
- Group documents by target folder
- Move each batch with `documentIds` array and `destination: { folderId: "xxx" }`
- Report results after each batch

### Step 7: Summary

After all moves complete, provide a summary:
- Total documents processed
- Documents moved (by category)
- New folders created (if any)
- Any documents skipped or needing manual review

## Classification Rules Summary

The detailed mapping is in `references/folder-map.md`. Here's the quick decision tree:

1. **Is it about iOS/ObjC/Swift?** → `Tech-iOS` (pick sub-folder by topic: UI, networking, threading, etc.)
2. **Is it about Flutter/Dart?** → `Tech-Flutter` (Dart syntax, framework, 营地实践, or 视频模块)
3. **Is it about design patterns, SOLID, architecture?** → `Tech-Architecture`
4. **Is it about Unity, Shader, game dev?** → `Tech-GameDev`
5. **Is it about dev tools (Xcode, Git, CocoaPods, CI)?** → `Tech-Toolchain`
6. **Is it about 王者营地 business (视频, 开黑, 大同, 监控)?** → `Project-营地`
7. **Is it about AI/LLM/ChatGPT/Cursor/Midjourney?** → `Project-AI`
8. **Is it a work log, OKR, weekly report, meeting note?** → `Archive-工作记录` (sort by year)
9. **Is it about learning methods, life philosophy, coding insights?** → `Growth-方法论`
10. **Is it about personal life, finance, health, passwords?** → `Life-个人`

## Error Handling

- If a document move fails, log the error and continue with remaining documents
- If a target folder is not found by name, warn the user and skip those documents
- If `folders_list` returns an unexpected structure, stop and ask the user to verify

## Important Notes

- Always confirm with the user before moving documents
- Never delete documents — only move them
- When in doubt about classification, ask the user rather than guessing
- Documents with very short or empty titles need content-based classification via `blocks_get`
- New top-level folders require explicit user approval — never create them silently
- After creating a new category, update `references/folder-map.md` so future runs can classify into it
- Prefer fitting documents into existing categories; only propose new folders when the domain is genuinely new and distinct
