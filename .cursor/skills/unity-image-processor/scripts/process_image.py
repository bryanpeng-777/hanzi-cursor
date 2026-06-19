#!/usr/bin/env python3
"""
Unity Image Processor Script
Removes background from images and resizes them for Unity game development.
"""

import argparse
import os
from pathlib import Path
from PIL import Image
import rembg


def remove_background(input_path: str, output_path: str) -> None:
    """Remove background from an image using rembg."""
    with open(input_path, 'rb') as input_file:
        input_data = input_file.read()

    output_data = rembg.remove(input_data)

    with open(output_path, 'wb') as output_file:
        output_file.write(output_data)


def resize_image(input_path: str, output_path: str, size: tuple = (50, 50)) -> None:
    """Resize an image to the specified size."""
    with Image.open(input_path) as img:
        # Use high-quality resampling
        resized = img.resize(size, Image.Resampling.LANCZOS)
        resized.save(output_path, 'PNG')


def process_image(input_path: str, output_path: str, size: tuple = (50, 50)) -> None:
    """Remove background and resize an image in one step."""
    # First remove background
    temp_path = output_path.replace('.png', '_temp.png')
    remove_background(input_path, temp_path)

    # Then resize
    resize_image(temp_path, output_path, size)

    # Clean up temp file
    if os.path.exists(temp_path):
        os.remove(temp_path)


def main():
    parser = argparse.ArgumentParser(
        description='Process images for Unity: remove background and resize'
    )
    parser.add_argument(
        'input',
        help='Input image file path'
    )
    parser.add_argument(
        '-o', '--output',
        help='Output image file path (default: input_processed.png)',
        default=None
    )
    parser.add_argument(
        '-s', '--size',
        help='Target size (default: 50x50)',
        default='50x50'
    )
    parser.add_argument(
        '--only-remove-bg',
        action='store_true',
        help='Only remove background, do not resize'
    )
    parser.add_argument(
        '--only-resize',
        action='store_true',
        help='Only resize, do not remove background'
    )

    args = parser.parse_args()

    # Parse size
    try:
        w, h = map(int, args.size.split('x'))
        size = (w, h)
    except ValueError:
        print(f"Error: Invalid size format '{args.size}'. Use format 'WxH', e.g., '50x50'")
        return 1

    # Determine output path
    if args.output:
        output_path = args.output
    else:
        input_stem = Path(args.input).stem
        output_path = f"{input_stem}_processed.png"

    # Process image
    try:
        if args.only_remove_bg:
            remove_background(args.input, output_path)
            print(f"Background removed: {output_path}")
        elif args.only_resize:
            resize_image(args.input, output_path, size)
            print(f"Image resized to {size[0]}x{size[1]}: {output_path}")
        else:
            process_image(args.input, output_path, size)
            print(f"Image processed (BG removed + resized to {size[0]}x{size[1]}): {output_path}")
    except Exception as e:
        print(f"Error processing image: {e}")
        return 1

    return 0


if __name__ == '__main__':
    exit(main())
