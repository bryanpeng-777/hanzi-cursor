---
name: image-resizer
description: "Resize images to fit within 256x256 pixels while maintaining aspect ratio. Use when users need to resize a single image to 256x256, batch resize multiple images, scale images proportionally without distortion, or create uniformly sized images for sprites, avatars, or thumbnails. Supports JPG, PNG, and other common image formats. Automatically centers images and adds white padding to maintain aspect ratio. Automatically opens the output folder after resizing."
---

# Image Resizer

Resize images to fit within 256x256 pixels while maintaining aspect ratio.

## Quick Start

Resize a single image:
```bash
python3 scripts/resize_image.py <input_path>
```

Resize with custom output path:
```bash
python3 scripts/resize_image.py <input_path> <output_path>
```

Resize with custom size:
```bash
python3 scripts/resize_image.py <input_path> <output_path> <size>
```

Resize without opening folder:
```bash
python3 scripts/resize_image.py <input_path> <output_path> <size> false
```

## How It Works

1. Loads the input image
2. Calculates scaling factor to fit within target size (default 256x256)
3. Resizes image proportionally using high-quality LANCZOS resampling
4. Creates a square canvas (size x size) with white background
5. Centers and pastes the resized image
6. Saves to output path
7. **Opens the folder containing the resized image** (optional)

## Features

- **Aspect ratio preservation**: Images are never distorted
- **Automatic centering**: Resized images are centered on the canvas
- **White padding**: Adds white background for non-square images
- **RGBA support**: Handles transparent images by converting to RGB with white background
- **High quality**: Uses LANCZOS resampling for best results
- **Flexible sizing**: Default 256x256, but customizable
- **Auto-open folder**: Automatically opens the output folder in system file manager

## Examples

```bash
# Resize image.jpg to image_resized.jpg (256x256) and open folder
python3 scripts/resize_image.py image.jpg

# Resize to specific output path
python3 scripts/resize_image.py avatar.png output/avatar_256.png

# Resize to custom size (512x512)
python3 scripts/resize_image.py photo.jpg photo_512.jpg 512

# Resize without opening folder (useful for batch processing)
python3 scripts/resize_image.py photo.jpg photo_resized.jpg 256 false
```

## Parameters

- `input_path`: Path to input image (required)
- `output_path`: Path to output image (optional, defaults to `input_path_resized.ext`)
- `size`: Target size in pixels (optional, defaults to 256)
- `open_folder`: Open folder after resizing (optional, defaults to `true`)

## Return Values

- **Success**: Returns exit code 0, prints output path, opens folder
- **Failure**: Returns exit code 1, prints error message

## Requirements

- Python 3.x
- Pillow library (PIL): `pip install Pillow`
