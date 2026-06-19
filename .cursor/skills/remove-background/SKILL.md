---
name: remove-background
description: Remove backgrounds from images and sprite sheets using AI-powered neural networks
model: sonnet
---

# Remove Background

Automatically remove backgrounds from images and sprite sheets using the Rembg library, which leverages pre-trained deep learning models (U2-Net, ISNet, BiRefNet) for high-quality background removal.

**Attribution**: This skill is based on the [Rembg](https://github.com/danielgatis/rembg) project by Daniel Gatis (17.8k+ stars).

## When to Use

- Remove background from single images (photos, product images, icons)
- Batch process multiple images
- Extract sprites from sprite sheets with backgrounds
- Create transparent PNG images
- Prepare images for compositing or further editing

## Prerequisites Check

Before processing, verify that rembg is installed:

```bash
python3 -c "import rembg; print('rembg is installed')"
```

If not installed, guide the user through installation:

### Installation Options

**For CPU (recommended for most users):**
```bash
pip install "rembg[cli]"
```

**For GPU acceleration (requires NVIDIA GPU + CUDA):**
```bash
# Check system compatibility first at https://onnxruntime.ai
pip install "rembg[gpu,cli]"
```

**Note**: Models (~300-500MB) will be automatically downloaded to `~/.u2net/` on first use.

## 脚本分工 / Script Division

> **脚本全自动处理**：创建 session、批量处理、输出路径（`scripts/batch_rembg.py`）
> **AI 处理**：理解任务类型（单图/批量/精灵表）、模型选择建议、输出质量评估

```bash
# 批量去除背景（默认 u2net 模型）
python3 scripts/batch_rembg.py <input_dir>

# 指定模型和输出目录
python3 scripts/batch_rembg.py <input_dir> <output_dir> --model isnet-general-use

# 启用 alpha matting（边缘更精细）
python3 scripts/batch_rembg.py <input_dir> --alpha-matting
```

**关键优化**：脚本创建 session 一次复用，避免每张图重复加载模型（批量处理性能差异 10x+）。

---

## Core Workflow

### Step 1: Understand the Task

Clarify with the user:
- **Input**: Single image, multiple images, or sprite sheet?
- **Output format**: Transparent PNG (default) or mask only?
- **Quality needs**: Standard or high-quality (with alpha matting)?
- **Batch processing**: How many images?

### Step 2: Choose the Right Model

Recommend model based on use case:

| Model | Best For | Command Flag |
|-------|----------|--------------|
| `u2net` | General use, balanced speed/quality (default) | `-m u2net` |
| `isnet-general-use` | Higher quality, slightly slower | `-m isnet-general-use` |
| `birefnet-general` | Latest model, best quality | `-m birefnet-general` |
| `sam` | Precise control with point prompts | `-m sam` |

**Default recommendation**: Start with `u2net`. Upgrade to `isnet-general-use` or `birefnet-general` if quality is insufficient.

### Step 3: Process Images

#### A. Single Image (Command Line)

Basic usage:
```bash
rembg i input.png output.png
```

With specific model:
```bash
rembg i -m isnet-general-use input.png output.png
```

With alpha matting for better quality:
```bash
rembg i -a input.png output.png
```

#### B. Single Image (Python)

**Simple approach:**
```python
from rembg import remove
from PIL import Image

input_image = Image.open('input.png')
output_image = remove(input_image)
output_image.save('output.png')
```

**With model selection:**
```python
from rembg import remove, new_session
from PIL import Image

# Create session with specific model
session = new_session("isnet-general-use")

input_image = Image.open('input.png')
output_image = remove(input_image, session=session)
output_image.save('output.png')
```

**With alpha matting:**
```python
from rembg import remove
from PIL import Image

input_image = Image.open('input.png')
output_image = remove(
    input_image,
    alpha_matting=True,
    alpha_matting_foreground_threshold=270,
    alpha_matting_background_threshold=20,
    alpha_matting_erode_size=11
)
output_image.save('output.png')
```

#### C. Batch Processing (CRITICAL for Performance)

**IMPORTANT**: For multiple images, create a session ONCE and reuse it. This avoids re-initializing the model for each image, which is very slow.

```python
from rembg import remove, new_session
from PIL import Image
import os

# Create session ONCE
session = new_session("u2net")

input_dir = "input_images"
output_dir = "output_images"
os.makedirs(output_dir, exist_ok=True)

# Process all images with the same session
for filename in os.listdir(input_dir):
    if filename.lower().endswith(('.png', '.jpg', '.jpeg')):
        input_path = os.path.join(input_dir, filename)
        output_path = os.path.join(output_dir, f"{os.path.splitext(filename)[0]}_nobg.png")
        
        img = Image.open(input_path)
        output = remove(img, session=session)
        output.save(output_path)
        print(f"Processed: {filename}")
```

#### D. Sprite Sheet Processing

For sprite sheets, extract individual sprites first, then remove backgrounds:

```python
from rembg import remove, new_session
from PIL import Image
import os

def process_sprite_sheet(input_path, sprite_width, sprite_height, output_dir):
    """
    Extract sprites from a sprite sheet and remove backgrounds.
    
    Args:
        input_path: Path to sprite sheet image
        sprite_width: Width of each sprite in pixels
        sprite_height: Height of each sprite in pixels
        output_dir: Directory to save processed sprites
    """
    # Load sprite sheet
    sheet = Image.open(input_path)
    sheet_width, sheet_height = sheet.size
    
    # Calculate grid dimensions
    cols = sheet_width // sprite_width
    rows = sheet_height // sprite_height
    
    os.makedirs(output_dir, exist_ok=True)
    
    # Create session once for all sprites
    session = new_session("u2net")
    
    sprite_count = 0
    for row in range(rows):
        for col in range(cols):
            # Extract sprite
            left = col * sprite_width
            top = row * sprite_height
            right = left + sprite_width
            bottom = top + sprite_height
            
            sprite = sheet.crop((left, top, right, bottom))
            
            # Remove background
            sprite_nobg = remove(sprite, session=session)
            
            # Save
            output_path = os.path.join(output_dir, f"sprite_{row}_{col}.png")
            sprite_nobg.save(output_path)
            sprite_count += 1
    
    print(f"Processed {sprite_count} sprites from sprite sheet")
    return sprite_count

# Usage example
process_sprite_sheet(
    "character_spritesheet.png",
    sprite_width=64,
    sprite_height=64,
    output_dir="sprites_nobg"
)
```

### Step 4: Quality Enhancement (Optional)

If the output quality is not satisfactory, try:

1. **Use a better model**: Switch to `isnet-general-use` or `birefnet-general`
2. **Enable alpha matting**: Add `-a` flag or `alpha_matting=True`
3. **Get mask only**: Use `only_mask=True` to inspect what the model detected
4. **Adjust image**: Ensure good lighting and contrast in the input image

### Step 5: Verify Output

Always check the output:
- Open the generated image(s) in an image viewer
- Verify transparency is preserved (check with a checkerboard background)
- Look for edge artifacts or missed areas

## Advanced Features

### Get Mask Only

To see what the model detected as foreground:
```python
output = remove(input_image, only_mask=True)
```

### Custom Background Color

To replace with a color instead of transparency:
```python
output = remove(input_image, bgcolor=(255, 255, 255, 255))  # White background
```

### Process with Point Prompts (SAM model)

For precise control:
```bash
rembg i -m sam -x '{"sam_prompt": [{"type": "point", "data": [724, 740], "label": 1}]}' input.jpg output.png
```

## Common Issues & Solutions

### Issue: "ModuleNotFoundError: No module named 'rembg'"
**Solution**: Install rembg using `pip install "rembg[cli]"`

### Issue: Slow processing
**Solution**: 
- For single images: This is normal on first run (model download)
- For multiple images: MUST use session reuse (see Batch Processing section)
- Consider GPU acceleration if you have NVIDIA GPU

### Issue: Poor quality edges
**Solution**: Enable alpha matting with `-a` flag or `alpha_matting=True`

### Issue: GPU not being used
**Solution**: 
- Verify CUDA and cudnn-devel are installed
- Use `pip install "rembg[gpu,cli]"` instead of CPU version
- Check NVIDIA compatibility at https://onnxruntime.ai

### Issue: Model download fails
**Solution**: 
- Check internet connection
- Ensure `~/.u2net/` directory is writable
- Try downloading model manually from GitHub

## Best Practices

1. **Session Reuse**: Always create a session once and reuse for batch processing
2. **Model Selection**: Start with default `u2net`, upgrade only if needed
3. **Output Format**: Always save as PNG to preserve transparency
4. **Batch Size**: Process in reasonable batches (100-1000 images) to avoid memory issues
5. **Quality Check**: Inspect a few samples before processing large batches

## Example Complete Workflow

```python
from rembg import remove, new_session
from PIL import Image
import os

def remove_backgrounds(input_folder, output_folder, model="u2net", use_alpha_matting=False):
    """
    Complete workflow for batch background removal.
    """
    # Setup
    os.makedirs(output_folder, exist_ok=True)
    session = new_session(model)
    
    # Get all image files
    image_files = [f for f in os.listdir(input_folder) 
                   if f.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp', '.webp'))]
    
    print(f"Found {len(image_files)} images to process")
    print(f"Using model: {model}")
    print(f"Alpha matting: {use_alpha_matting}")
    
    # Process each image
    processed = 0
    failed = 0
    
    for filename in image_files:
        try:
            input_path = os.path.join(input_folder, filename)
            output_filename = f"{os.path.splitext(filename)[0]}_nobg.png"
            output_path = os.path.join(output_folder, output_filename)
            
            # Load and process
            img = Image.open(input_path)
            if use_alpha_matting:
                output = remove(img, session=session, alpha_matting=True)
            else:
                output = remove(img, session=session)
            
            # Save
            output.save(output_path)
            processed += 1
            
            if processed % 10 == 0:
                print(f"Progress: {processed}/{len(image_files)}")
                
        except Exception as e:
            print(f"Failed to process {filename}: {e}")
            failed += 1
    
    print(f"\nComplete! Processed: {processed}, Failed: {failed}")
    return processed, failed

# Usage
remove_backgrounds(
    input_folder="input_images",
    output_folder="output_images",
    model="u2net",
    use_alpha_matting=False
)
```

## Important Notes

1. **Not a tool wrapper**: This skill encodes knowledge about background removal techniques, not just command syntax
2. **Model files**: First run downloads ~300-500MB of model files to `~/.u2net/`
3. **Processing time**: Expect 1-3 seconds per image on CPU, faster on GPU
4. **Input formats**: Supports PNG, JPG, JPEG, BMP, WebP
5. **Output format**: Always save as PNG to preserve transparency

## Credit

This skill is built on knowledge from the [Rembg](https://github.com/danielgatis/rembg) project by Daniel Gatis, which uses U²-Net, ISNet, and BiRefNet neural networks for salient object detection and background removal.
