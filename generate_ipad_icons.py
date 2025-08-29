#!/usr/bin/env python3

from PIL import Image
import os

# Path to the source icon and output directory
source_icon = "/Users/donnysmith/CC/printmyride/PrintMyRide/Assets.xcassets/AppIcon.appiconset/icon_1024x1024@1x.png"
output_dir = "/Users/donnysmith/CC/printmyride/PrintMyRide/Assets.xcassets/AppIcon.appiconset"

# Load the source icon
img = Image.open(source_icon)

# Define ALL the missing iPad icons with their sizes
ipad_icons = [
    ("icon_20x20@1x.png", 20),    # iPad Notifications 20pt @1x
    ("icon_20x20@2x.png", 40),    # iPad Notifications 20pt @2x (reuse iPhone icon)
    ("icon_29x29@1x.png", 29),    # iPad Settings 29pt @1x
    ("icon_29x29@2x.png", 58),    # iPad Settings 29pt @2x (reuse iPhone icon)
    ("icon_40x40@1x.png", 40),    # iPad Spotlight 40pt @1x
    ("icon_40x40@2x.png", 80),    # iPad Spotlight 40pt @2x (reuse iPhone icon)
    ("icon_76x76@2x.png", 152),   # iPad App 76pt @2x
    ("icon_83.5x83.5@2x.png", 167) # iPad Pro App 83.5pt @2x
]

for filename, size in ipad_icons:
    # Resize the image
    resized = img.resize((size, size), Image.LANCZOS)
    
    # Save the resized image
    output_path = os.path.join(output_dir, filename)
    resized.save(output_path, "PNG")
    print(f"Created {filename} ({size}x{size})")

print("\nAll iPad icons generated successfully!")