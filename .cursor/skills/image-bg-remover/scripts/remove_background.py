#!/usr/bin/env python3
"""
Remove white/white-ish background by making all white pixels transparent.
Simple and effective for solid white backgrounds.
"""

import argparse
import sys
from pathlib import Path
import numpy as np

try:
    from PIL import Image
except ImportError:
    print("Error: Required packages not installed.")
    print("Please install: pip install Pillow")
    sys.exit(1)


def remove_white_background(input_path, output_path, whiteness_threshold=240):
    """
    Remove white/white-ish background by making all white pixels transparent.

    Args:
        input_path: Path to input image
        output_path: Path to output PNG
        whiteness_threshold: Minimum brightness to consider a pixel white (0-255)
                           Pixels where R, G, and B are all >= this value become transparent
    """
    # Read image
    img = Image.open(input_path).convert('RGBA')
    img_array = np.array(img)
    height, width = img_array.shape[:2]

    # Create mask for white pixels
    # A pixel is considered white if all RGB channels are above the threshold
    r, g, b, a = img_array[:,:,0], img_array[:,:,1], img_array[:,:,2], img_array[:,:,3]

    # Find white pixels (all RGB channels >= threshold)
    white_mask = (r >= whiteness_threshold) & (g >= whiteness_threshold) & (b >= whiteness_threshold)

    # Apply mask - set white pixels to transparent
    result_array = img_array.copy()
    result_array[white_mask, 3] = 0  # Set alpha to 0 for white pixels

    # Save output
    output_img = Image.fromarray(result_array, 'RGBA')
    output_img.save(output_path, 'PNG', optimize=True)

    return np.sum(white_mask)


def main():
    parser = argparse.ArgumentParser(
        description='Remove white background by making all white pixels transparent'
    )
    parser.add_argument('input', help='Input image path')
    parser.add_argument('output', help='Output PNG path')
    parser.add_argument(
        '--threshold',
        type=int,
        default=240,
        help='Whiteness threshold (0-255, default: 240). Pixels with R,G,B all >= this value become transparent.'
    )

    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Error: Input file not found: {input_path}")
        sys.exit(1)

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    try:
        bg_pixels = remove_white_background(
            input_path,
            output_path,
            whiteness_threshold=args.threshold
        )
        img = Image.open(input_path)
        total_pixels = img.size[0] * img.size[1]
        bg_percentage = (bg_pixels / total_pixels) * 100

        print(f"✅ White background removed successfully!")
        print(f"   Whiteness threshold: {args.threshold}")
        print(f"   Pixels removed: {bg_pixels} ({bg_percentage:.1f}%)")
        print(f"   Output saved to: {output_path}")
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
