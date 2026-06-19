# Python 绘图库扩展能力

除 `diagrams` 库外，本 Skill 支持根据用户需求动态选择合适的 Python 绘图库。

## 库选择速查

| 场景 | 推荐库 | 安装命令 |
|------|--------|----------|
| 云架构图 | `diagrams` | `pip install diagrams` |
| 数据可视化 | `matplotlib` | `pip install matplotlib` |
| 统计图表 | `seaborn` | `pip install seaborn` |
| 交互式图表 | `plotly` | `pip install plotly` |
| 流程图/思维导图 | `graphviz` | `pip install graphviz` |
| 网络拓扑图 | `networkx` + `matplotlib` | `pip install networkx` |
| 甘特图/时序图 | `plotly` / `matplotlib` | — |

## 动态选择策略（在 Phase 1 根据关键词判断）

- **"架构图"、"系统图"、"云服务"** → 使用 `diagrams`
- **"数据图表"、"趋势图"、"统计"** → 使用 `matplotlib` / `seaborn`
- **"交互式"、"Web展示"、"可缩放"** → 使用 `plotly`
- **"流程图"、"状态图"、"决策树"** → 使用 `graphviz`
- **"关系图"、"网络拓扑"、"节点连接"** → 使用 `networkx`

---

## 示例：matplotlib 数据可视化

```python
import matplotlib.pyplot as plt
import os

output_dir = "./pic/data-chart"
os.makedirs(output_dir, exist_ok=True)

# 数据
months = ['Jan', 'Feb', 'Mar', 'Apr', 'May']
values = [100, 150, 200, 180, 250]

plt.figure(figsize=(10, 6))
plt.bar(months, values, color='steelblue')
plt.title('Monthly Sales')
plt.xlabel('Month')
plt.ylabel('Sales')
plt.savefig(f"{output_dir}/sales-chart.png", dpi=150, bbox_inches='tight')
plt.savefig(f"{output_dir}/sales-chart.svg", bbox_inches='tight')
plt.close()
```

---

## 示例：plotly 交互式图表

```python
import plotly.express as px
import os

output_dir = "./pic/interactive-chart"
os.makedirs(output_dir, exist_ok=True)

df = px.data.gapminder().query("year == 2007")
fig = px.scatter(df, x="gdpPercap", y="lifeExp", size="pop", color="continent",
                 hover_name="country", log_x=True, title="GDP vs Life Expectancy")
fig.write_html(f"{output_dir}/chart.html")
fig.write_image(f"{output_dir}/chart.png")
```

---

## 输出格式指南

| 格式 | 适用场景 | 工具支持 |
|------|---------|---------|
| **PNG** | 通用展示、PPT、网页 | 所有工具 |
| **SVG** | 网页嵌入、可缩放 | matplotlib, diagrams, plotly |
| **PDF** | 论文插图、打印 | TikZ（原生），matplotlib |
| **HTML** | 交互式展示 | plotly |

### 按需转换

```python
# PNG → 其他格式 (使用 Pillow)
from PIL import Image
img = Image.open("diagram.png")
img.save("diagram.jpg", quality=95)

# PDF → PNG (使用 pdf2image)
from pdf2image import convert_from_path
images = convert_from_path("diagram.pdf", dpi=300)
images[0].save("diagram.png", "PNG")

# SVG → PNG (使用 cairosvg)
import cairosvg
cairosvg.svg2png(url="diagram.svg", write_to="diagram.png", scale=2)
```
