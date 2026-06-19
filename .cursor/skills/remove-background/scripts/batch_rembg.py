#!/usr/bin/env python3
"""batch_rembg.py - 批量去除图片背景（封装 rembg，创建单一 session 复用）
用法: python3 batch_rembg.py <input_dir> [output_dir]
              [--model u2net|isnet-general-use|birefnet-general]
              [--alpha-matting]
              [--ext png|jpg]  （输出格式，默认 png 保留透明通道）
输出: 处理结果统计（stderr），输出路径（stdout）
"""

import sys
import os
import argparse

try:
    from rembg import remove, new_session
    from PIL import Image
except ImportError:
    print("错误：依赖未安装", file=sys.stderr)
    print("请运行: pip install 'rembg[cli]' Pillow", file=sys.stderr)
    sys.exit(1)


SUPPORTED_EXTS = {".png", ".jpg", ".jpeg", ".bmp", ".webp"}


def process_batch(input_dir: str, output_dir: str, model: str,
                  alpha_matting: bool, out_ext: str) -> tuple[int, int]:
    """批量处理图片，返回 (成功数, 失败数)"""
    os.makedirs(output_dir, exist_ok=True)

    files = [f for f in os.listdir(input_dir)
             if os.path.splitext(f)[1].lower() in SUPPORTED_EXTS]

    if not files:
        print(f"警告：{input_dir} 中没有找到支持的图片文件", file=sys.stderr)
        return 0, 0

    print(f"发现 {len(files)} 张图片，模型：{model}，alpha-matting：{alpha_matting}", file=sys.stderr)

    # 关键：创建 session 一次，所有图片复用（避免重复加载模型）
    session = new_session(model)

    ok, fail = 0, 0
    for i, filename in enumerate(files, 1):
        input_path = os.path.join(input_dir, filename)
        base = os.path.splitext(filename)[0]
        output_filename = f"{base}_nobg.{out_ext}"
        output_path = os.path.join(output_dir, output_filename)

        try:
            img = Image.open(input_path)
            output = remove(img, session=session, alpha_matting=alpha_matting)

            if out_ext != "png":
                # 非 PNG 格式需要合并透明通道到白色背景
                bg = Image.new("RGBA", output.size, (255, 255, 255, 255))
                bg.paste(output, mask=output.split()[3] if output.mode == "RGBA" else None)
                output = bg.convert("RGB")

            output.save(output_path)
            ok += 1
            if i % 10 == 0 or i == len(files):
                print(f"  进度：{i}/{len(files)}  ✓ {filename}", file=sys.stderr)
        except Exception as e:
            print(f"  ✗ {filename}：{e}", file=sys.stderr)
            fail += 1

    return ok, fail


def main():
    parser = argparse.ArgumentParser(description="批量去除图片背景")
    parser.add_argument("input_dir", help="输入图片目录")
    parser.add_argument("output_dir", nargs="?", help="输出目录（默认：input_dir_nobg）")
    parser.add_argument("--model", default="u2net",
                        choices=["u2net", "isnet-general-use", "birefnet-general", "sam"],
                        help="去背景模型（默认 u2net）")
    parser.add_argument("--alpha-matting", action="store_true",
                        help="启用 alpha matting（边缘更精细，速度更慢）")
    parser.add_argument("--ext", default="png", choices=["png", "jpg"],
                        help="输出格式（默认 png，保留透明通道）")
    args = parser.parse_args()

    input_dir = os.path.abspath(args.input_dir)
    if not os.path.isdir(input_dir):
        print(f"错误：目录不存在 {input_dir}", file=sys.stderr)
        sys.exit(1)

    output_dir = args.output_dir or f"{input_dir.rstrip('/')}_nobg"
    output_dir = os.path.abspath(output_dir)

    print(f"输入：{input_dir}", file=sys.stderr)
    print(f"输出：{output_dir}", file=sys.stderr)

    ok, fail = process_batch(input_dir, output_dir, args.model, args.alpha_matting, args.ext)

    print(f"\n完成！成功：{ok}  失败：{fail}", file=sys.stderr)
    print(output_dir)  # stdout 只输出路径，方便管道使用


if __name__ == "__main__":
    main()
