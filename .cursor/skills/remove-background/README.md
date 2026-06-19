# Remove Background Skill

AI-powered background removal skill for images and sprite sheets.

## Overview

This skill helps you remove backgrounds from images using the Rembg library, which leverages state-of-the-art deep learning models (U²-Net, ISNet, BiRefNet) for automatic background removal.

## Features

- ✂️ Single image background removal
- 📦 Batch processing for multiple images
- 🎮 Sprite sheet extraction and processing
- 🎨 Multiple model options for different quality needs
- ⚡ Optimized for performance with session reuse
- 🔧 Alpha matting for high-quality edges
- 🎯 Support for precise control with SAM model

## Quick Start

1. **Install rembg**:
   ```bash
   pip install "rembg[cli]"
   ```

2. **Remove background from a single image**:
   ```bash
   rembg i input.png output.png
   ```

3. **Batch process multiple images** (Python):
   ```python
   from rembg import remove, new_session
   from PIL import Image
   import os
   
   session = new_session("u2net")
   
   for filename in os.listdir("input_folder"):
       if filename.endswith('.png'):
           img = Image.open(f"input_folder/{filename}")
           output = remove(img, session=session)
           output.save(f"output_folder/{filename}")
   ```

## Attribution

Based on the [Rembg](https://github.com/danielgatis/rembg) project by Daniel Gatis (17.8k+ ⭐).

## License

MIT License - Knowledge encoded from open source project.
