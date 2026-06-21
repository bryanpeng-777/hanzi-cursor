#!/usr/bin/env python3
"""
DSPy Optimizer 重训练脚本
从 training_data.jsonl 加载全部标注数据，重新跑 BootstrapFewShot，更新优化模型。

使用方式：
  python3 retrain.py                        # 用全部数据重新训练
  python3 retrain.py --add                  # 交互式添加一条新样本后重新训练
  python3 retrain.py --list                 # 查看当前训练集
"""

import os, sys, json, argparse
sys.path.insert(0, os.path.dirname(__file__))

SKILL_DIR     = os.path.dirname(__file__)
TRAIN_FILE    = os.path.join(SKILL_DIR, "training_data.jsonl")
OPTIMIZED_FILE = os.path.join(SKILL_DIR, "galileo_optimized.json")

import dspy
from dspy.teleprompt import BootstrapFewShot
from analyzer import GalileoAlertAnalysis


# ── metric 定义（与训练时一致）──────────────────────────
def galileo_metric(example, pred, trace=None):
    score = 0.0
    if hasattr(pred, "severity") and example.severity == pred.severity:
        score += 0.5
    if hasattr(pred, "root_cause") and example.module_name.lower() in pred.root_cause.lower():
        score += 0.3
    if hasattr(pred, "need_code_fix") and example.need_code_fix == pred.need_code_fix:
        score += 0.2
    return score


# ── 加载训练集 ───────────────────────────────────────────
def load_trainset():
    if not os.path.exists(TRAIN_FILE):
        print(f"❌ 训练文件不存在：{TRAIN_FILE}")
        sys.exit(1)
    examples = []
    with open(TRAIN_FILE) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            d = json.loads(line)
            examples.append(
                dspy.Example(**d).with_inputs("alert_text", "trace_logs")
            )
    return examples


# ── 追加新样本 ───────────────────────────────────────────
def append_example(data: dict):
    with open(TRAIN_FILE, "a") as f:
        f.write(json.dumps(data, ensure_ascii=False) + "\n")
    print(f"✅ 已追加到训练集（当前共 {count_examples()} 条）")


def count_examples():
    if not os.path.exists(TRAIN_FILE):
        return 0
    return sum(1 for line in open(TRAIN_FILE) if line.strip())


# ── 交互式添加 ───────────────────────────────────────────
def interactive_add():
    print("📝 添加新的训练样本（从最近一次分析结果复制过来）\n")
    data = {}
    data["alert_text"]   = input("alert_text（告警内容）：\n> ").strip()
    data["trace_logs"]   = input("trace_logs（日志片段，可留空）：\n> ").strip() or "（无）"
    data["root_cause"]   = input("root_cause（正确根因）：\n> ").strip()
    data["module_name"]  = input("module_name（模块名，如 OneApi）：\n> ").strip()
    data["severity"]     = input("severity（P0/P1/P2）：\n> ").strip().upper()
    data["impact_scope"] = input("impact_scope（影响范围）：\n> ").strip()
    data["action"]       = input("action（处置建议）：\n> ").strip()
    fix_input            = input("need_code_fix（y/n）：\n> ").strip().lower()
    data["need_code_fix"] = fix_input in ("y", "yes", "true", "1")

    print("\n📋 即将添加：")
    print(json.dumps(data, ensure_ascii=False, indent=2))
    confirm = input("\n确认添加？(y/n): ").strip().lower()
    if confirm == "y":
        append_example(data)
        return True
    else:
        print("已取消")
        return False


# ── 重新训练 ─────────────────────────────────────────────
def retrain():
    trainset = load_trainset()
    print(f"\n📚 加载训练集：{len(trainset)} 条")
    print("🚀 开始运行 BootstrapFewShot Optimizer...\n")

    dspy.configure(lm=dspy.LM("deepseek/deepseek-chat", cache=False))

    base = dspy.ChainOfThought(GalileoAlertAnalysis)
    optimizer = BootstrapFewShot(
        metric=galileo_metric,
        max_bootstrapped_demos=min(3, len(trainset)),
        max_labeled_demos=min(3, len(trainset)),
        max_rounds=1,
    )
    optimized = optimizer.compile(base, trainset=trainset)

    # 计算平均 metric
    scores = []
    for ex in trainset:
        pred = optimized(alert_text=ex.alert_text, trace_logs=ex.trace_logs)
        scores.append(galileo_metric(ex, pred))
    avg = sum(scores) / len(scores)

    optimized.save(OPTIMIZED_FILE)

    print(f"\n✅ 训练完成！")
    print(f"   样本数：{len(trainset)} 条")
    print(f"   平均 metric：{avg:.2f}")
    print(f"   已保存：{OPTIMIZED_FILE}")
    return avg


# ── 查看训练集 ───────────────────────────────────────────
def list_examples():
    trainset = load_trainset()
    print(f"\n📚 当前训练集（共 {len(trainset)} 条）：\n")
    for i, ex in enumerate(trainset, 1):
        first_line = ex.alert_text.split("\n")[0][:50]
        print(f"  [{i}] {ex.severity} | {ex.module_name} | {first_line}...")
    print()


# ── 主入口 ───────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(description="DSPy 告警分析器重训练工具")
    parser.add_argument("--add",  action="store_true", help="交互式添加新样本后重新训练")
    parser.add_argument("--list", action="store_true", help="查看当前训练集")
    args = parser.parse_args()

    if args.list:
        list_examples()
        return

    if args.add:
        added = interactive_add()
        if not added:
            return
        print()

    retrain()


if __name__ == "__main__":
    main()
