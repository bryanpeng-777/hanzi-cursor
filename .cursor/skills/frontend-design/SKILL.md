---
name: frontend-design
description: Create distinctive, production-grade frontend interfaces with high design quality. Use this skill when the user asks to build web components, pages, artifacts, posters, or applications (examples include websites, landing pages, dashboards, React components, HTML/CSS layouts, or when styling/beautifying any web UI). Generates creative, polished code and UI design that avoids generic AI aesthetics.
license: Complete terms in LICENSE.txt
---

This skill guides creation of distinctive, production-grade frontend interfaces that avoid generic "AI slop" aesthetics. Implement real working code with exceptional attention to aesthetic details and creative choices.

The user provides frontend requirements: a component, page, application, or interface to build. They may include context about the purpose, audience, or technical constraints.

## 模式选择

收到请求后，先判断用户需要哪种模式：

| 触发词 | 模式 |
|--------|------|
| 「只设计」「设计方案」「视觉方向」「不写代码」「design only」 | **Design-Only 模式**：只输出设计规格文档，不写任何实现代码 |
| 其他（直接描述要构建的界面） | **Full 模式**：Design Thinking + 实现代码 |

### Design-Only 模式输出格式

```
## 设计方向
[一句话核心美学定位]

## 色彩
- 主色：[色值 + 使用场景]
- 辅色：[色值 + 使用场景]
- 背景：[色值或描述]

## 字体
- 标题：[字体名 + 理由]
- 正文：[字体名 + 理由]

## 动效基调
[描述整体动效风格，关键交互点的动效设计]

## 空间 & 布局
[布局风格：对称/非对称、密度、负空间处理]

## 视觉细节
[背景处理、阴影、边框、纹理等氛围营造]

## 记忆点
[这个界面让人印象深刻的一个核心设计决策]
```

---

## Design Thinking

Before coding, understand the context and commit to a BOLD aesthetic direction:
- **Purpose**: What problem does this interface solve? Who uses it?
- **Tone**: Pick an extreme: brutally minimal, maximalist chaos, retro-futuristic, organic/natural, luxury/refined, playful/toy-like, editorial/magazine, brutalist/raw, art deco/geometric, soft/pastel, industrial/utilitarian, etc. There are so many flavors to choose from. Use these for inspiration but design one that is true to the aesthetic direction.
- **Constraints**: Technical requirements (framework, performance, accessibility).
- **Differentiation**: What makes this UNFORGETTABLE? What's the one thing someone will remember?

**CRITICAL**: Choose a clear conceptual direction and execute it with precision. Bold maximalism and refined minimalism both work - the key is intentionality, not intensity.

Then implement working code (HTML/CSS/JS, React, Vue, etc.) that is:
- Production-grade and functional
- Visually striking and memorable
- Cohesive with a clear aesthetic point-of-view
- Meticulously refined in every detail

## Frontend Aesthetics Guidelines

Focus on:
- **Typography**: Choose fonts that are beautiful, unique, and interesting. Avoid generic fonts like Arial and Inter; opt instead for distinctive choices that elevate the frontend's aesthetics; unexpected, characterful font choices. Pair a distinctive display font with a refined body font.
- **Color & Theme**: Commit to a cohesive aesthetic. Use CSS variables for consistency. Dominant colors with sharp accents outperform timid, evenly-distributed palettes.
- **Motion**: Use animations for effects and micro-interactions. Prioritize CSS-only solutions for HTML. Use Motion library for React when available. Focus on high-impact moments: one well-orchestrated page load with staggered reveals (animation-delay) creates more delight than scattered micro-interactions. Use scroll-triggering and hover states that surprise.
- **Spatial Composition**: Unexpected layouts. Asymmetry. Overlap. Diagonal flow. Grid-breaking elements. Generous negative space OR controlled density.
- **Backgrounds & Visual Details**: Create atmosphere and depth rather than defaulting to solid colors. Add contextual effects and textures that match the overall aesthetic. Apply creative forms like gradient meshes, noise textures, geometric patterns, layered transparencies, dramatic shadows, decorative borders, custom cursors, and grain overlays.

NEVER use generic AI-generated aesthetics like overused font families (Inter, Roboto, Arial, system fonts), cliched color schemes (particularly purple gradients on white backgrounds), predictable layouts and component patterns, and cookie-cutter design that lacks context-specific character.

Interpret creatively and make unexpected choices that feel genuinely designed for the context. No design should be the same. Vary between light and dark themes, different fonts, different aesthetics. NEVER converge on common choices (Space Grotesk, for example) across generations.

**IMPORTANT**: Match implementation complexity to the aesthetic vision. Maximalist designs need elaborate code with extensive animations and effects. Minimalist or refined designs need restraint, precision, and careful attention to spacing, typography, and subtle details. Elegance comes from executing the vision well.

Remember: Claude is capable of extraordinary creative work. Don't hold back, show what can truly be created when thinking outside the box and committing fully to a distinctive vision.

---

## Flutter Extension

当目标平台是 Flutter 时，Design Thinking 原则不变，实现层替换如下：

### 字体
- 使用 `google_fonts` 包引入个性字体，避免默认 Roboto
- 示例：`GoogleFonts.playfairDisplay()`（衬线优雅）、`GoogleFonts.spaceGrotesk()` 仅在有意为之时用

### 色彩 & 主题
- 用 `ThemeData` + `ColorScheme.fromSeed()` 或手工 `ColorScheme` 统一管理
- 用 `Theme.of(context).colorScheme.xxx` 保证全局一致，避免硬编码颜色

### 动效
- 简单动效：`AnimatedContainer`、`AnimatedOpacity`、`TweenAnimationBuilder`
- 复杂序列：`AnimationController` + `CurvedAnimation`
- 推荐第三方：`flutter_animate`（链式 API，类似 Motion 库体验）
- 页面切换：自定义 `PageRouteBuilder` 替代默认的滑入效果

### 背景 & 视觉特效
- 渐变：`BoxDecoration(gradient: LinearGradient(...))` 或 `RadialGradient`
- 噪点/纹理：`CustomPainter` 绘制，或用 `ImageFilter` 加模糊
- 阴影与深度：`BoxShadow` 多层叠加，`Material` elevation
- 玻璃拟态：`BackdropFilter` + `ImageFilter.blur`

### 布局
- 非常规布局：`Stack` + `Positioned`、`CustomMultiChildLayout`
- 网格：`GridView` 或 `Wrap`，需要破格时用 `Stack` 叠加
- 负空间控制：`Padding`、`SizedBox`、`Spacer` 精确调节

### 关键原则
- **不要**直接把 HTML/CSS 翻译成 Flutter，而是用 Flutter 原生惯用法实现同等视觉效果
- Widget 树嵌套深时，拆分为命名 Widget 而非内联，保持可读性
- 优先用 `const` 构造，减少不必要重绘
