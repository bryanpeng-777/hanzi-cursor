---
name: unity-image-processor
description: Process images for Unity game development by removing backgrounds and resizing them to 50x50 pixels with PNG transparency support. Use when the user needs to remove image backgrounds, resize images for Unity, prepare sprites or icons for game assets, or create transparent background images for Unity textures or sprites.
---

# Unity Image Processor

Process images for Unity by removing backgrounds and resizing them with transparency support.

## Quick Start

Process an image (remove background + resize to 50x50):

```bash
python3 scripts/process_image.py input.png -o output.png
```

## Workflow

1. Verify dependencies are installed
2. Run the processing script with appropriate options
3. Use the output image in Unity project

## Dependencies

Install required Python packages:

```bash
pip3 install Pillow rembg
```

## Usage Patterns

### Full Process (Default)

Remove background and resize to 50x50:

```bash
python3 scripts/process_image.py input.png -o output.png
```

### Remove Background Only

When only transparency is needed:

```bash
python3 scripts/process_image.py input.png -o output.png --only-remove-bg
```

### Resize Only

When the background is already transparent:

```bash
python3 scripts/process_image.py input.png -o output.png --only-resize
```

### Custom Size

Specify different target size:

```bash
python3 scripts/process_image.py input.png -o output.png -s 64x64
```

### Automatic Naming

If no output is specified, generates `{input}_processed.png`:

```bash
python3 scripts/process_image.py input.png
# Creates: input_processed.png
```

## Parameters

- `input`: Input image file path (required)
- `-o, --output`: Output image file path (optional)
- `-s, --size`: Target size in WxH format (default: 50x50)
- `--only-remove-bg`: Only remove background, skip resizing
- `--only-resize`: Only resize, skip background removal

## Common Unity Use Cases

```bash
# Character sprite (50x50)
python3 scripts/process_image.py character.png -o character_sprite.png

# UI icon (64x64)
python3 scripts/process_image.py icon.png -o icon_64.png -s 64x64

# Large background element (128x128)
python3 scripts/process_image.py element.png -o element_128.png -s 128x128

# Just clean up background, keep original size
python3 scripts/process_image.py texture.png -o texture_clean.png --only-remove-bg
```

## Resources

### scripts/process_image.py

Python script that handles image processing with the following capabilities:
- Background removal using rembg (AI-based)
- High-quality image resizing using Pillow with LANCZOS resampling
- PNG output with alpha channel transparency
- Flexible processing modes (remove, resize, or both)
