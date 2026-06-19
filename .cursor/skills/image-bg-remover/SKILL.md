---
name: image-bg-remover
description: 'Remove white background from images by making all white pixels transparent. Use when users need to remove solid white backgrounds from sprite/character images, create transparent PNG assets for Unity 2D sprites, process scene elements with white backgrounds, or convert images with white backgrounds to transparent sprites. Simple and fast algorithm that identifies white pixels by RGB threshold.'
---

# Image Background Remover

Remove white backgrounds from images by making all white pixels transparent. Ideal for Unity sprites and game assets.

## Quick Start

To remove white background from an image:

```bash
python scripts/remove_background.py <input_image> <output_image.png>
```

Example:
```bash
python scripts/remove_background.py character.png character_transparent.png
```

## How It Works

The script uses a simple, efficient algorithm:
1. Scans every pixel in the image
2. Identifies "white" pixels (where R, G, and B values are all above a threshold)
3. Sets those pixels to transparent (alpha = 0)
4. Outputs a PNG with transparent background

This approach is fast, predictable, and works great for solid white backgrounds.

### Key Features

- **Simple and fast**: Direct pixel-by-pixel white detection
- **Predictable results**: Easy to tune with a single threshold parameter
- **Preserves details**: Won't remove non-white content
- **Optimized for Unity**: Outputs PNG format with proper alpha channel

## Parameters

### Basic Usage
```bash
python scripts/remove_background.py INPUT OUTPUT
```

- `INPUT`: Path to source image (PNG, JPG, etc.)
- `OUTPUT`: Path for output PNG (will have transparency)

### Optional Parameters

```bash
python scripts/remove_background.py INPUT OUTPUT --threshold 233
```

- `--threshold`: Whiteness threshold (0-255, default: 240)
  - Pixels where R, G, and B are **all ≥ threshold** become transparent
  - **Higher values (240-250)**: Only remove pure white pixels (conservative)
  - **Medium values (230-240)**: Remove white and near-white pixels (balanced)
  - **Lower values (220-230)**: Remove more off-white pixels (aggressive)

## Best Practices for Unity Assets

### Game Characters/Sprites
- Use threshold 235-240 for characters with dark colors
- Use threshold 230-235 for characters with light colors
- Test in Unity Scene View to verify edges look good

### Scene Elements (Trees, Buildings, Props)
- Use threshold 230-240 for elements on white backgrounds
- Check if element has white highlights - adjust threshold to preserve them
- Consider manual touch-up for complex cases

### Troubleshooting

#### White Background Not Fully Removed
- Decrease `--threshold` by 2-5 at a time (try 235, 230, 225)
- Off-white backgrounds need lower threshold values

#### Foreground Pixels Being Removed
- Increase `--threshold` to be more conservative (try 245, 250)
- Check if your sprite has white/light areas that should be preserved

#### Edges Look Too Hard/Jagged
- This is a limitation of the simple threshold approach
- For smooth anti-aliased edges, consider using professional tools
- Or manually touch up edges in image editing software

## Algorithm Comparison

This skill uses a **simple white pixel detection** algorithm:
- ✅ Fast and efficient
- ✅ Predictable and tunable
- ✅ Great for solid white backgrounds
- ❌ Not suitable for colored/gradient backgrounds
- ❌ May have hard edges (no anti-aliasing)

For complex backgrounds or smooth edges, consider professional tools like:
- Photoshop's "Select Color Range"
- GIMP's "Color to Alpha"
- AI-based services (remove.bg, etc.)

## Requirements

The script requires:
- Python 3.6+
- Pillow: `pip install Pillow`

Install dependencies:
```bash
pip install Pillow numpy
```

## Example Output

```bash
$ python scripts/remove_background.py sprite.png sprite_transparent.png --threshold 233

✅ White background removed successfully!
   Whiteness threshold: 233
   Pixels removed: 643427 (61.4%)
   Output saved to: sprite_transparent.png
```
