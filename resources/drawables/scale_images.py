#!/usr/bin/env python

from PIL import Image
from pathlib import Path

path_images = Path("images")
path_save = Path("processed")

path_save.mkdir(parents=True, exist_ok=True,)

for file in path_images.glob("*.bmp"):
    print(f"Processing {file}")
    img = Image.open(file)
    new_image = img.resize((260, 260))

    new_image.save(path_save / file.name)

