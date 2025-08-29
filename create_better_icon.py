#!/usr/bin/env python3
"""
Better icon generator for Android adaptive icons
Creates proper foreground and background icons
"""

from PIL import Image, ImageDraw
import os

def create_better_icons():
    # Create foreground icon (the main icon that goes on top)
    size = 1024
    fg_img = Image.new('RGBA', (size, size), (255, 255, 255, 0))
    fg_draw = ImageDraw.Draw(fg_img)
    
    # Colors
    primary_color = (139, 69, 255)  # Purple
    secondary_color = (255, 107, 129)  # Pink
    white = (255, 255, 255)
    
    # Create a centered gift box that fits well in adaptive icon
    # Use only the center 70% of the image for the main icon
    icon_size = int(size * 0.6)
    icon_x = (size - icon_size) // 2
    icon_y = (size - icon_size) // 2
    
    # Main gift box
    fg_draw.rounded_rectangle(
        [icon_x, icon_y, icon_x + icon_size, icon_y + icon_size],
        radius=size//25,
        fill=primary_color,
        outline=None
    )
    
    # Gift box lid
    lid_height = int(icon_size * 0.15)
    fg_draw.rounded_rectangle(
        [icon_x - 15, icon_y - 8, icon_x + icon_size + 15, icon_y + lid_height],
        radius=size//30,
        fill=secondary_color,
        outline=None
    )
    
    # Vertical ribbon
    ribbon_width = int(icon_size * 0.12)
    ribbon_x = icon_x + (icon_size - ribbon_width) // 2
    fg_draw.rectangle(
        [ribbon_x, icon_y - 8, ribbon_x + ribbon_width, icon_y + icon_size],
        fill=secondary_color
    )
    
    # Horizontal ribbon
    ribbon_height = int(icon_size * 0.12)
    ribbon_y = icon_y + (icon_size - ribbon_height) // 2
    fg_draw.rectangle(
        [icon_x - 15, ribbon_y, icon_x + icon_size + 15, ribbon_y + ribbon_height],
        fill=secondary_color
    )
    
    # Bow on top
    bow_size = int(icon_size * 0.15)
    bow_x = (size - bow_size) // 2
    bow_y = icon_y - bow_size // 2
    
    # Left bow part
    fg_draw.ellipse(
        [bow_x - bow_size//3, bow_y, bow_x + bow_size//3, bow_y + bow_size//2],
        fill=secondary_color
    )
    
    # Right bow part  
    fg_draw.ellipse(
        [bow_x + bow_size//6, bow_y, bow_x + bow_size//2 + bow_size//3, bow_y + bow_size//2],
        fill=secondary_color
    )
    
    # Center knot
    knot_size = bow_size // 4
    fg_draw.ellipse(
        [bow_x + bow_size//4, bow_y + bow_size//6, bow_x + bow_size//4 + knot_size, bow_y + bow_size//6 + knot_size],
        fill=primary_color
    )
    
    # Heart symbol on the box
    heart_size = int(icon_size * 0.25)
    heart_x = (size - heart_size) // 2
    heart_y = icon_y + int(icon_size * 0.4)
    
    # Simple heart shape
    circle_radius = heart_size // 4
    
    # Left circle of heart
    fg_draw.ellipse(
        [heart_x, heart_y, heart_x + circle_radius * 2, heart_y + circle_radius * 2],
        fill=white
    )
    
    # Right circle of heart
    fg_draw.ellipse(
        [heart_x + circle_radius, heart_y, heart_x + circle_radius * 3, heart_y + circle_radius * 2],
        fill=white
    )
    
    # Bottom triangle of heart
    triangle_points = [
        (heart_x + circle_radius // 2, heart_y + circle_radius),
        (heart_x + heart_size - circle_radius // 2, heart_y + circle_radius),
        (heart_x + heart_size // 2, heart_y + heart_size)
    ]
    fg_draw.polygon(triangle_points, fill=white)
    
    # Create background icon (solid color with subtle pattern)
    bg_img = Image.new('RGBA', (size, size), (255, 255, 255, 255))
    bg_draw = ImageDraw.Draw(bg_img)
    
    # Add subtle pattern dots
    dot_color = (240, 240, 255, 100)  # Very light blue with transparency
    dot_size = size // 40
    
    for i in range(0, size, size // 8):
        for j in range(0, size, size // 8):
            bg_draw.ellipse(
                [i, j, i + dot_size, j + dot_size],
                fill=dot_color
            )
    
    # Save icons
    os.makedirs('assets/icons', exist_ok=True)
    fg_img.save('assets/icons/app_icon_foreground.png', 'PNG')
    bg_img.save('assets/icons/app_icon.png', 'PNG')
    
    print("✅ Better adaptive icons created!")
    print("📁 Created: assets/icons/app_icon.png (background)")
    print("📁 Created: assets/icons/app_icon_foreground.png (foreground)")
    print("\n🚀 Next steps:")
    print("1. Run: flutter pub run flutter_launcher_icons:main")
    print("2. Run: flutter clean")
    print("3. Run: flutter run")

if __name__ == "__main__":
    try:
        create_better_icons()
    except ImportError:
        print("❌ PIL (Pillow) not installed. Installing...")
        import subprocess
        subprocess.check_call(["pip3", "install", "Pillow"])
        create_better_icons()

