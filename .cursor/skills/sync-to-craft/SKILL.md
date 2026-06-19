---
name: sync-to-craft
description: Sync current conversation content to Craft as a well-structured knowledge document, automatically classified into the 10-folder knowledge base system. Use this skill whenever the user says "同步到Craft", "保存到Craft", "写到Craft里", "sync to craft", "save to craft", "记录到Craft", "把这个对话存到Craft", "同步到craft", or any variation about saving, syncing, or recording the current conversation or discussion results into Craft. Also trigger when the user says "把刚才的内容存一下", "帮我记一下这个", or mentions wanting to preserve conversation insights in their notes.
---

# Sync to Craft

Extract key content from the current conversation and create a well-structured Craft document, then classify and file it into bryanpeng's 10-folder knowledge base system.

## Workflow

### Step 1: Analyze the conversation and extract content

Review the current conversation to identify what's worth preserving. Extract and organize content into a structured knowledge document.

#### What to extract

Depending on the conversation type, extract different elements:

**Bug fix / troubleshooting session:**
- Problem description and symptoms
- Root cause analysis
- Solution and code changes (include key code snippets)
- Lessons learned / prevention tips

**Feature development / implementation:**
- Requirements summary
- Technical approach and design decisions
- Key code implementation (important snippets, not every line)
- Trade-offs considered

**Technical research / learning:**
- Topic and context
- Key concepts and explanations
- Code examples
- References and links

**Architecture / design discussion:**
- Problem statement
- Options evaluated with pros/cons
- Final decision and rationale

**General discussion / brainstorming:**
- Main topic
- Key points and conclusions
- Action items (if any)

#### Content formatting principles

- Write for future retrieval — a reader (human or AI) should understand the document without conversation context
- Use clear headings and structure
- Include relevant code snippets in fenced code blocks with language tags
- Strip out conversational noise (greetings, confirmations, back-and-forth)
- Keep it concise but complete — aim for the "golden summary" that captures all essential information
- Add a date stamp at the top (today's date)

### Step 2: Generate title and content

**Title**: Create a concise, descriptive title that captures the core topic. Prefer the pattern `[Domain] Topic Summary`, e.g.:
- "Flutter 视频播放器横竖屏切换问题修复"
- "iOS WKWebView 内存泄漏排查"
- "营地监控 Galileo 埋点新增方案"
- "MVVM vs VIPER 架构选型分析"

**Content structure** (adapt based on conversation type):

```markdown
> 📅 YYYY-MM-DD | 来源：Cursor 会话同步

## 背景

[What prompted this discussion]

## 内容

[Main body — analysis, solution, key findings, etc.]

## 关键代码

[Important code snippets, if any]

## 总结

[Key takeaways, lessons learned, or decisions made]
```

### Step 3: Present the document to the user for confirmation

Before creating anything, show the user:
1. The proposed **title**
2. The proposed **content** (full markdown preview)
3. The proposed **target folder** (classification result — see Step 4)

Ask the user to confirm or request changes. The user may want to:
- Adjust the title
- Add/remove content
- Change the target folder
- Cancel the sync entirely

### Step 4: Classify the document

Use the same classification system as `craft-doc-organizer`. Read the classification mapping from the sibling skill:

```
/path/to/skills/craft-doc-organizer/references/folder-map.md
```

The skill directory path can be derived from this skill's own path by replacing `sync-to-craft` with `craft-doc-organizer`.

Match the document's title and content against the 10-folder classification rules:

1. **Tech-iOS** — iOS/ObjC/Swift topics
2. **Tech-Flutter** — Flutter/Dart topics
3. **Tech-Architecture** — Design patterns, architecture
4. **Tech-GameDev** — Unity, Shader, game dev
5. **Tech-Toolchain** — Xcode, Git, tools, CI
6. **Project-营地** — 王者营地 business
7. **Project-AI** — AI/LLM tools and practices
8. **Archive-工作记录** — Work logs (classify by year)
9. **Growth-方法论** — Learning, philosophy, coding insights
10. **Life-个人** — Personal, finance, health

#### If the document doesn't fit any existing category

If the document's topic genuinely doesn't belong to any of the 10 categories:

1. Propose a new top-level folder following the naming convention `Domain-中文描述`
2. Suggest 2-3 initial sub-folders
3. Explain why existing categories are insufficient
4. **Require user confirmation before creating**

Present this in the classification plan:

```
📁 建议新建一级目录：

**Tech-Backend** — 后端/服务端开发
- 建议子目录：数据库、API设计、部署与运维
- 原因：本次会话涉及 Node.js 服务端开发，现有分类均偏客户端

请确认是否创建，或指定归入现有目录。
```

### Step 5: Create the document in Craft

After user confirms both content and classification:

1. **Fetch folder structure**: Call `folders_list` to get current folder tree, match target folder by name to get its ID

2. **Create the document**: Use `documents_create` with the title, placing it directly in the target folder:
   ```
   documents_create({
     documents: [{ title: "..." }],
     destination: { folderId: "target-folder-id" }
   })
   ```

3. **Write content**: Use `markdown_add` to insert the formatted content:
   ```
   markdown_add({
     markdown: "...",
     position: "end",
     pageId: "document-id-from-step-2"
   })
   ```

4. **If a new folder was approved**: Create it first via `folders_create` (with sub-folders), then create the document in the new folder. Also update `craft-doc-organizer/references/folder-map.md` with the new category and keywords.

### Step 6: Confirm completion

Report to the user:
- Document title and Craft link (if available)
- Target folder path (e.g., `Tech-iOS / 多线程与性能`)
- New folders created (if any)

## Content Length Guidelines

- **Short conversations** (quick Q&A, single issue): 200-500 words
- **Medium conversations** (bug fix, feature implementation): 500-1500 words
- **Long conversations** (architecture discussion, multi-step investigation): 1500-3000 words
- Never exceed 3000 words — summarize aggressively for very long sessions
- Code snippets count toward the limit; include only the most critical ones

## Error Handling

- If `documents_create` fails, report the error and suggest the user try creating manually
- If `markdown_add` fails (e.g., content too long), try splitting into multiple `markdown_add` calls
- If folder lookup fails, create the document in Unsorted and tell the user

## Important Notes

- Always show the full document preview before creating — never create silently
- The document should stand alone as a knowledge article, not read like a chat log
- Strip all conversational artifacts (greetings, "sure", "let me check", etc.)
- Preserve technical accuracy — don't over-simplify code or lose important details
- New top-level folders require explicit user approval
- After creating a new category, update `craft-doc-organizer/references/folder-map.md` to keep both skills in sync
