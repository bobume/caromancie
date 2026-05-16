#!/usr/bin/env python3
"""
Resize public/images/hero_caromancie.png into multiple widths and produce JPEG and WebP variants.
Saves files in the same directory as the source.
"""

import os
import sys
import subprocess

try:
    from PIL import Image
except Exception:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "--user", "Pillow"]) 
    from PIL import Image

src = r"c:/Users/Christophe/Desktop/caromancie/public/images/hero_caromancie.png"
if not os.path.exists(src):
    print("Source not found:", src)
    sys.exit(2)

out_dir = os.path.dirname(src)
sizes = [480, 800, 1200, 1600]

img = Image.open(src)
orig_w, orig_h = img.size
print("Source size:", orig_w, "x", orig_h)
for w in sizes:
    h = max(1, int(orig_h * (w / orig_w)))
    resized = img.resize((w, h), Image.LANCZOS)
    # Save JPEG
    jpg_path = os.path.join(out_dir, f"hero-{w}.jpg")
    resized.convert("RGB").save(jpg_path, "JPEG", quality=85, optimize=True)
    # Save WebP
    webp_path = os.path.join(out_dir, f"hero-{w}.webp")
    resized.save(webp_path, "WEBP", quality=80, method=6)
    print("Saved:", jpg_path, webp_path)

print("Done.")
