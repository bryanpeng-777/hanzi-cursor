# TikZ 学术论文图模板

TikZ 是 LaTeX 生态中的专业绘图工具，广泛用于顶级学术论文。适合绘制神经网络架构、模型结构、算法流程等。

## 检查 LaTeX 环境

```bash
# 检查是否已安装
pdflatex --version

# 如未安装，参考 SKILL.md 的 Prerequisites 部分
```

---

## 模板 1：神经网络（基础版）

```latex
% neural_network.tex
\documentclass[tikz,border=10pt]{standalone}
\usepackage{tikz}
\usetikzlibrary{positioning,arrows.meta,shapes.geometric,fit,backgrounds}

\begin{document}
\begin{tikzpicture}[
    node distance=1.5cm,
    layer/.style={rectangle, draw, minimum width=2cm, minimum height=0.8cm, align=center},
    arrow/.style={-{Stealth[scale=1.2]}, thick}
]

% 输入层
\node[layer, fill=blue!20] (input) {Input\\$x \in \mathbb{R}^{784}$};

% 隐藏层
\node[layer, fill=green!20, right=of input] (hidden1) {Hidden Layer\\ReLU, 256};
\node[layer, fill=green!20, right=of hidden1] (hidden2) {Hidden Layer\\ReLU, 128};

% 输出层
\node[layer, fill=red!20, right=of hidden2] (output) {Output\\Softmax, 10};

% 连接箭头
\draw[arrow] (input) -- (hidden1);
\draw[arrow] (hidden1) -- (hidden2);
\draw[arrow] (hidden2) -- (output);

\end{tikzpicture}
\end{document}
```

---

## 模板 2：Transformer 架构（V5 最佳实践）

```latex
% transformer_v5.tex - 完整 Encoder-Decoder 架构
\documentclass[tikz,border=15pt]{standalone}
\usepackage{tikz}
\usepackage{xcolor}
\usepackage{amsmath}
\usetikzlibrary{positioning,arrows.meta,shapes.geometric,fit,backgrounds,calc}

% ===== Material Design 配色 =====
\definecolor{orange1}{HTML}{FFB74D}   % Attention
\definecolor{blue1}{HTML}{64B5F6}     % FFN
\definecolor{green1}{HTML}{81C784}    % Norm
\definecolor{purple1}{HTML}{BA68C8}   % Embedding
\definecolor{pink1}{HTML}{F48FB1}     % Softmax
\definecolor{yellow1}{HTML}{FFF176}   % Positional
\definecolor{gray1}{HTML}{BDBDBD}     % Linear

\begin{document}
\begin{tikzpicture}[
    % ===== 样式系统：基础样式 + 继承 =====
    box/.style={
        rectangle, draw=black!70, line width=0.5pt,
        minimum width=2.4cm, minimum height=0.7cm,
        align=center, font=\footnotesize\sffamily, rounded corners=2pt,
    },
    attn/.style={box, fill=orange1},
    ffn/.style={box, fill=blue1},
    norm/.style={box, fill=green1!70, minimum height=0.55cm, font=\scriptsize\sffamily},
    emb/.style={box, fill=purple1!60},
    posenc/.style={box, fill=yellow1!80, minimum width=2cm, minimum height=0.5cm, font=\scriptsize\sffamily},
    lin/.style={box, fill=gray1},
    soft/.style={box, fill=pink1},
    addcircle/.style={circle, draw=black!70, fill=white, inner sep=0pt, minimum size=14pt, font=\scriptsize},
    % ===== 三级箭头系统 =====
    arr/.style={-{Stealth[length=5pt, width=4pt]}, line width=0.5pt, black!70},
    arrgray/.style={-{Stealth[length=4pt, width=3pt]}, line width=0.4pt, black!40},
    arrblue/.style={-{Stealth[length=5pt, width=4pt]}, line width=0.7pt, blue!60},
]

% ===== 间距变量 =====
\def\gap{0.45}
\def\biggap{0.7}

% ==================== ENCODER ====================
\node[font=\small\sffamily] (inputs) at (0, 0) {Inputs};
\node[emb, above=\biggap of inputs] (enc_emb) {Input Embedding};
\node[addcircle, above=\gap of enc_emb] (enc_add) {$+$};
\node[posenc, left=0.6cm of enc_add] (enc_pos) {\scriptsize Positional Encoding};

\node[attn, above=\biggap of enc_add] (enc_mha) {Multi-Head\\Attention};
\node[norm, above=\gap of enc_mha] (enc_n1) {Add \& Norm};
\node[ffn, above=\gap of enc_n1] (enc_ff) {Feed Forward};
\node[norm, above=\gap of enc_ff] (enc_n2) {Add \& Norm};

% Encoder 连线
\draw[arr] (inputs) -- (enc_emb);
\draw[arr] (enc_emb) -- (enc_add);
\draw[arr] (enc_pos) -- (enc_add);
\draw[arr] (enc_add) -- (enc_mha);
\draw[arr] (enc_mha) -- (enc_n1);
\draw[arr] (enc_n1) -- (enc_ff);
\draw[arr] (enc_ff) -- (enc_n2);

% Encoder 残差连接 (微偏移 + 左右交替)
\draw[arrgray] ($(enc_add.north)+(0.05,0)$) -- ++(0,0.25) -| ($(enc_mha.east)+(0.4,0)$) |- (enc_n1.east);
\draw[arrgray] ($(enc_n1.north)+(0.05,0)$) -- ++(0,0.15) -| ($(enc_ff.west)+(-0.4,0)$) |- (enc_n2.west);

% Encoder 框 (背景层 + 淡色)
\begin{scope}[on background layer]
\node[draw=black!40, line width=0.8pt, inner xsep=18pt, inner ysep=10pt, rounded corners=4pt, 
      fit=(enc_mha)(enc_n1)(enc_ff)(enc_n2)] (enc_box) {};
\end{scope}
\node[font=\scriptsize\sffamily, anchor=west] at ($(enc_box.north east)+(0.1,-0.1)$) {$\times N$};

% ==================== DECODER ====================
\begin{scope}[xshift=5.5cm]
\node[font=\small\sffamily, align=center] (outputs) at (0, 0) {Outputs\\[-3pt]{\tiny(shifted right)}};
\node[emb, above=\biggap of outputs] (dec_emb) {Output Embedding};
\node[addcircle, above=\gap of dec_emb] (dec_add) {$+$};
\node[posenc, right=0.6cm of dec_add] (dec_pos) {\scriptsize Positional Encoding};

\node[attn, above=\biggap of dec_add] (dec_mha1) {Masked\\Multi-Head Attention};
\node[norm, above=\gap of dec_mha1] (dec_n1) {Add \& Norm};
\node[attn, above=\gap of dec_n1] (dec_mha2) {Multi-Head\\Attention};
\node[norm, above=\gap of dec_mha2] (dec_n2) {Add \& Norm};
\node[ffn, above=\gap of dec_n2] (dec_ff) {Feed Forward};
\node[norm, above=\gap of dec_ff] (dec_n3) {Add \& Norm};

% Decoder 连线
\draw[arr] (outputs) -- (dec_emb);
\draw[arr] (dec_emb) -- (dec_add);
\draw[arr] (dec_pos) -- (dec_add);
\draw[arr] (dec_add) -- (dec_mha1);
\draw[arr] (dec_mha1) -- (dec_n1);
\draw[arr] (dec_n1) -- (dec_mha2);
\draw[arr] (dec_mha2) -- (dec_n2);
\draw[arr] (dec_n2) -- (dec_ff);
\draw[arr] (dec_ff) -- (dec_n3);

% Decoder 残差连接
\draw[arrgray] ($(dec_add.north)+(-0.05,0)$) -- ++(0,0.25) -| ($(dec_mha1.west)+(-0.4,0)$) |- (dec_n1.west);
\draw[arrgray] ($(dec_n1.north)+(-0.05,0)$) -- ++(0,0.15) -| ($(dec_mha2.east)+(0.4,0)$) |- (dec_n2.east);
\draw[arrgray] ($(dec_n2.north)+(-0.05,0)$) -- ++(0,0.15) -| ($(dec_ff.west)+(-0.4,0)$) |- (dec_n3.west);

% Decoder 框
\begin{scope}[on background layer]
\node[draw=black!40, line width=0.8pt, inner xsep=18pt, inner ysep=10pt, rounded corners=4pt, 
      fit=(dec_mha1)(dec_n1)(dec_mha2)(dec_n2)(dec_ff)(dec_n3)] (dec_box) {};
\end{scope}
\node[font=\scriptsize\sffamily, anchor=west] at ($(dec_box.north east)+(0.1,-0.1)$) {$\times N$};

% Output 层
\node[lin, above=\biggap of dec_n3] (linear) {Linear};
\node[soft, above=\gap of linear] (softmax) {Softmax};
\node[font=\small\sffamily, above=\gap of softmax] (outprob) {Output Probabilities};
\draw[arr] (dec_n3) -- (linear);
\draw[arr] (linear) -- (softmax);
\draw[arr] (softmax) -- (outprob);
\end{scope}

% ==================== Encoder → Decoder (蓝色高亮) ====================
\draw[arrblue] (enc_n2.north) -- ++(0,0.4) -| ++(1.8,0) |- (dec_mha2.west);

% 标签 (灰色淡化)
\node[font=\small\sffamily\bfseries, gray!80, above=0.15cm of enc_box.north] {Encoder};
\node[font=\small\sffamily\bfseries, gray!80, above=0.15cm of dec_box.north] {Decoder};

\end{tikzpicture}
\end{document}
```

**V5 设计要点**：
- **样式继承**: `attn/.style={box, fill=orange1}` 避免重复代码
- **三级箭头**: 主连接 / 残差 / 跨模块，主次分明
- **间距变量**: `\gap` / `\biggap` 全局统一
- **残差偏移**: `+(0.05,0)` 微偏移避免重叠，左右交替绕行
- **背景层框**: `on background layer` + `black!40` 淡色不抢眼

---

## 编译工作流

```bash
# 生成 PDF（矢量图，推荐，直接用于论文）
pdflatex neural_network.tex
```

### Python 自动化编译脚本

```python
import subprocess
import os

def compile_tikz(tex_file, output_dir="./pic/tikz"):
    """编译 TikZ 文件生成 PDF"""
    os.makedirs(output_dir, exist_ok=True)
    
    # 编译 LaTeX
    result = subprocess.run(
        ["pdflatex", "-output-directory", output_dir, tex_file],
        capture_output=True, text=True
    )
    
    if result.returncode != 0:
        print(f"LaTeX 编译失败:\n{result.stderr}")
        return None
    
    # 获取生成的 PDF 路径
    base_name = os.path.splitext(os.path.basename(tex_file))[0]
    pdf_path = os.path.join(output_dir, f"{base_name}.pdf")
    
    # 清理临时文件
    for ext in [".aux", ".log"]:
        tmp_file = os.path.join(output_dir, f"{base_name}{ext}")
        if os.path.exists(tmp_file):
            os.remove(tmp_file)
    
    return pdf_path

# 使用示例
# compile_tikz("neural_network.tex", "./pic/neural-net")
```

---

## matplotlib 快速替代方案（无需 LaTeX）

当用户选择快速方案时，使用 matplotlib 绘制学术风格图：

```python
import matplotlib.pyplot as plt
import matplotlib.patches as patches
import os

def draw_neural_network_matplotlib(output_dir="./pic/nn-matplotlib"):
    """使用 matplotlib 绘制神经网络架构图"""
    os.makedirs(output_dir, exist_ok=True)
    
    fig, ax = plt.subplots(figsize=(12, 6))
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 4)
    ax.axis('off')
    
    # 定义层的位置和颜色
    layers = [
        {"x": 1, "label": "Input\n784", "color": "#a8d5e5"},
        {"x": 3, "label": "Hidden\n256", "color": "#b8e0b8"},
        {"x": 5, "label": "Hidden\n128", "color": "#b8e0b8"},
        {"x": 7, "label": "Hidden\n64", "color": "#b8e0b8"},
        {"x": 9, "label": "Output\n10", "color": "#f5b8b8"},
    ]
    
    # 绘制层
    for layer in layers:
        rect = patches.FancyBboxPatch(
            (layer["x"] - 0.5, 1.5), 1, 1.5,
            boxstyle="round,pad=0.05,rounding_size=0.1",
            facecolor=layer["color"], edgecolor="black", linewidth=1.5
        )
        ax.add_patch(rect)
        ax.text(layer["x"], 2.25, layer["label"], ha='center', va='center', fontsize=10, fontweight='bold')
    
    # 绘制箭头
    for i in range(len(layers) - 1):
        ax.annotate('', xy=(layers[i+1]["x"] - 0.5, 2.25), xytext=(layers[i]["x"] + 0.5, 2.25),
                    arrowprops=dict(arrowstyle='->', color='gray', lw=1.5))
    
    plt.title("Neural Network Architecture", fontsize=14, fontweight='bold', pad=20)
    plt.tight_layout()
    plt.savefig(f"{output_dir}/neural_network.png", dpi=150, bbox_inches='tight', facecolor='white')
    plt.savefig(f"{output_dir}/neural_network.svg", bbox_inches='tight', facecolor='white')
    plt.close()
    
    return f"{output_dir}/neural_network.png"

# 使用示例
# draw_neural_network_matplotlib()
```
