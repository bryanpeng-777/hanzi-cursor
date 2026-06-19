#!/usr/bin/env python3
"""
Image resizer script that proportionally scales images to fit within 256x256 pixels.
Maintains aspect ratio and adds padding if needed.
"""

import sys
import os
import platform
import subprocess
from PIL import Image

def open_file_directory(file_path):
    """
    Open the folder containing the file in the system's file manager.
    Works on macOS, Windows, and Linux.
    """
    try:
        folder_path = os.path.dirname(file_path)

        if not folder_path:
            folder_path = '.'

        system = platform.system()

        if system == 'Darwin':  # macOS
            subprocess.run(['open', folder_path])
        elif system == 'Windows':
            subprocess.run(['explorer', folder_path])
        else:  # Linux and others
            subprocess.run(['xdg-open', folder_path])

        return True
    except Exception as e:
        print(f"Warning: Could not open folder: {e}", file=sys.stderr)
        return False

def resize_image(input_path, output_path=None, size=256, open_folder=True):
    """
    Resize image to fit within size x size pixels while maintaining aspect ratio.

    Args:
        input_path: Path to input image
        output_path: Path to output image (optional, defaults to input_path with _resized suffix)
        size: Target size (default 256)
        open_folder: Whether to open the folder containing the output image (default True)
    """
    try:
        # Open the image
        img = Image.open(input_path)

        # Convert RGBA to RGB if necessary
        if img.mode == 'RGBA':
            # Create a white background for transparent images
            background = Image.new('RGB', img.size, (255, 255, 255))
            background.paste(img, mask=img.split()[3])  # Use alpha channel as mask
            img = background
        elif img.mode not in ('RGB', 'L'):
            img = img.convert('RGB')

        # Get original dimensions
        original_width, original_height = img.size

        # Calculate scaling factor to fit within size x size
        ratio = min(size / original_width, size / original_height)
        new_width = int(original_width * ratio)
        new_height = int(original_height * ratio)

        # Resize the image using high-quality resampling
        resized_img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)

        # Create a new image with the target size and paste the resized image in the center
        final_img = Image.new('RGB', (size, size), (255, 255, 255))

        # Calculate position to paste the resized image (center it)
        paste_x = (size - new_width) // 2
        paste_y = (size - new_height) // 2

        final_img.paste(resized_img, (paste_x, paste_y))

        # Determine output path
        if output_path is None:
            base, ext = os.path.splitext(input_path)
            output_path = f"{base}_resized{ext}"

        # Save the result
        final_img.save(output_path, quality=95)

        # Open the folder containing the output image
        if open_folder:
            open_file_directory(output_path)

        return True, output_path

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return False, str(e)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 resize_image.py <input_path> [output_path] [size] [open_folder]")
        print("Example: python3 resize_image.py photo.jpg")
        print("Example: python3 resize_image.py photo.jpg photo_resized.jpg")
        print("Example: python3 resize_image.py photo.jpg photo_resized.jpg 512")
        print("Example: python3 resize_image.py photo.jpg photo_resized.jpg 256 false")
        sys.exit(1)

    input_path = sys.argv[1]
    output_path = sys.argv[2] if len(sys.argv) > 2 else None
    size = int(sys.argv[3]) if len(sys.argv) > 3 else 256
    open_folder = sys.argv[4].lower() == 'true' if len(sys.argv) > 4 else True

    success, result = resize_image(input_path, output_path, size, open_folder)

    if success:
        print(f"✅ Image resized successfully: {result}")
        if open_folder:
            print(f"📂 Opening folder...")
        sys.exit(0)
    else:
        print(f"❌ Failed to resize image: {result}")
        sys.exit(1)
