#!/usr/bin/env python3
"""
Simple script to create a placeholder PNG for the splash screen.
Requires PIL/Pillow: pip install Pillow
"""

try:
    from PIL import Image, ImageDraw, ImageFont
    
    # Create a 512x512 transparent image
    size = 512
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Draw a simple car icon
    # Car body (rounded rectangle)
    car_color = (33, 150, 243, 255)  # Blue
    car_outline = (25, 118, 210, 255)  # Darker blue
    
    # Main car body
    draw.rounded_rectangle(
        [(100, 200), (412, 340)],
        radius=20,
        fill=car_color,
        outline=car_outline,
        width=8
    )
    
    # Car top/cabin
    draw.rounded_rectangle(
        [(160, 140), (352, 210)],
        radius=15,
        fill=car_color,
        outline=car_outline,
        width=8
    )
    
    # Windows
    window_color = (144, 202, 249, 200)
    draw.rounded_rectangle(
        [(175, 155), (240, 200)],
        radius=8,
        fill=window_color
    )
    draw.rounded_rectangle(
        [(272, 155), (337, 200)],
        radius=8,
        fill=window_color
    )
    
    # Wheels
    wheel_color = (66, 66, 66, 255)
    wheel_rim = (117, 117, 117, 255)
    
    # Left wheel
    draw.ellipse([(130, 310), (190, 370)], fill=wheel_color, outline=(33, 33, 33, 255), width=6)
    draw.ellipse([(145, 325), (175, 355)], fill=wheel_rim)
    
    # Right wheel
    draw.ellipse([(322, 310), (382, 370)], fill=wheel_color, outline=(33, 33, 33, 255), width=6)
    draw.ellipse([(337, 325), (367, 355)], fill=wheel_rim)
    
    # Notification badge
    badge_color = (255, 87, 34, 255)  # Orange/Red
    draw.ellipse([(360, 120), (420, 180)], fill=badge_color)
    
    # Exclamation mark
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 50)
    except:
        font = ImageFont.load_default()
    
    draw.text((390, 135), "!", fill='white', font=font, anchor="mm")
    
    # Save the image
    img.save('assets/splash_logo.png', 'PNG')
    print("✓ Splash logo created: assets/splash_logo.png")
    
except ImportError:
    print("⚠ PIL/Pillow not installed. Creating a simple colored square instead.")
    print("To create a better logo, install Pillow: pip3 install Pillow")
    
    # Create a very simple fallback
    import struct
    
    # Create a simple 512x512 PNG with a blue circle
    size = 512
    # This is a minimal PNG - in practice you'd want to use a proper library
    print("Please create assets/splash_logo.png manually or install Pillow.")
