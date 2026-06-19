# Nature — 自然绿主题设计规范

## 风格定位
翡翠绿调色板，来自 shadcn/ui 自定义主题（oklch 色彩空间精确转换）。
适合：健康、自然、环保、专业类应用。

## 色彩 Token（OKLCH 原始值）

### Light Mode
| Token | OKLCH | Hex（Flutter） |
|---|---|---|
| background | oklch(0.9934, 0.0017, 174.535) | #FCFDFB |
| foreground | oklch(0.2464, 0.0358, 168.983) | #0D261E |
| card | oklch(1.0, 0, 0) | #FFFFFF |
| primary | oklch(0.6373, 0.1362, 162.517) | #0EA471 |
| primary-foreground | oklch(0.9915, 0.0116, 174.243) | #F5FFFA |
| secondary | oklch(0.9593, 0.0088, 174.319) | #ECF4F0 |
| secondary-foreground | oklch(0.4406, 0.0740, 167.512) | #20604A |
| muted | oklch(0.9572, 0.0053, 174.426) | #EDF2EF |
| muted-foreground | oklch(0.5836, 0.0427, 172.235) | #628478 |
| accent | oklch(0.9498, 0.0187, 174.004) | #E2F3EC |
| accent-foreground | oklch(0.4575, 0.0843, 166.157) | #1A664C |
| destructive | oklch(0.6356, 0.2082, 25.378) | #EF4342 |
| destructive-foreground | oklch(0.9848, 0, 0) | #FAFAF9 |
| border | oklch(0.9161, 0.0142, 174.131) | #DAE7E1 |
| input | oklch(0.9161, 0.0142, 174.131) | #DAE7E1 |
| ring / primary | — | #0EA471 |

### Dark Mode
| Token | OKLCH | Hex（Flutter） |
|---|---|---|
| background | oklch(0.1396, 0.0125, 174.689) | #050B09 |
| foreground | oklch(0.9861, 0.0023, 174.518) | #F9FBF9 |
| card | oklch(0.1700, 0.0170, 171.555) | #08120E |
| popover | oklch(0.1551, 0.0146, 172.768) | #060E0B |
| primary | oklch(0.7678, 0.1655, 162.189) | #12D392 |
| primary-foreground | oklch(0.9915, 0.0116, 174.243) | #F5FFFA |
| secondary | oklch(0.2539, 0.0230, 171.579) | #172621 |
| secondary-foreground | oklch(0.9302, 0.0118, 174.214) | #E0EBE6 |
| muted | oklch(0.2295, 0.0197, 171.755) | #13201B |
| muted-foreground | oklch(0.7443, 0.0320, 173.270) | #98B3A9 |
| accent | oklch(0.2990, 0.0371, 170.119) | #19342A |
| destructive | oklch(0.4344, 0.1466, 25.781) | #912221 |
| border | oklch(0.2852, 0.0226, 172.014) | #1F2E29 |
| ring / primary | — | #12D392 |

## 规格参数
- **圆角**：`BorderRadius.circular(10)`（来自 `--radius: 0.6rem`）
- **按钮高度**：40px
- **字体**：Inter（系统 sans-serif）
- **字间距**：`-0.01em`（略微紧缩）

## ShadThemeData 代码片段

```dart
// nature_theme.dart 中已完整实现，枚举值：CsThemeStyle.nature
// 切换方式：在 cs_app_theme.dart 中改为：
// static const CsThemeStyle activeStyle = CsThemeStyle.nature;
```
