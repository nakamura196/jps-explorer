#!/usr/bin/env python3
"""
Generate marketing screenshots for App Store listing.
Creates promotional images with backgrounds, titles, and device frames.

Usage:
    python3 scripts/generate_marketing_screenshots.py
    python3 scripts/generate_marketing_screenshots.py --input-iphone DIR --input-ipad DIR --output DIR
"""

import argparse
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os

# Constants
IPHONE_SIZE = (1290, 2796)  # iPhone 6.7"
IPAD_SIZE = (2048, 2732)    # iPad 12.9"

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)

# Font paths (macOS)
FONT_BOLD = "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc"
FONT_REGULAR = "/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc"

# Font paths (macOS) - English
FONT_BOLD_EN = "/System/Library/Fonts/Helvetica.ttc"
FONT_REGULAR_EN = "/System/Library/Fonts/Helvetica.ttc"

# Themes per language
THEMES_JA = [
    {
        "bg_top": (41, 98, 255),       # Blue
        "bg_bottom": (0, 48, 135),
        "title": "日本の文化資源を探索",
        "subtitle": "3,200万件以上のコレクション",
    },
    {
        "bg_top": (153, 0, 51),        # Crimson
        "bg_bottom": (102, 0, 34),
        "title": "写真で似た文化資源を発見",
        "subtitle": "撮影するだけ、AIが検索",
    },
    {
        "bg_top": (0, 102, 68),        # Teal
        "bg_bottom": (0, 68, 45),
        "title": "マップで近くの資源を探す",
        "subtitle": "歩きながら文化財に出会う",
    },
    {
        "bg_top": (123, 44, 191),      # Purple
        "bg_bottom": (66, 15, 120),
        "title": "キュレーションを閲覧",
        "subtitle": "専門家が選んだコレクション",
    },
    {
        "bg_top": (230, 81, 0),        # Orange
        "bg_bottom": (153, 51, 0),
        "title": "本日の一品",
        "subtitle": "毎日ランダムな文化資源を紹介",
    },
]

THEMES_EN = [
    {
        "bg_top": (41, 98, 255),
        "bg_bottom": (0, 48, 135),
        "title": "Explore Japan's Heritage",
        "subtitle": "Over 32 million cultural resources",
    },
    {
        "bg_top": (153, 0, 51),
        "bg_bottom": (102, 0, 34),
        "title": "Find Similar by Photo",
        "subtitle": "Just snap a photo, AI searches",
    },
    {
        "bg_top": (0, 102, 68),
        "bg_bottom": (0, 68, 45),
        "title": "Discover Nearby on Map",
        "subtitle": "Cultural resources around you",
    },
    {
        "bg_top": (123, 44, 191),
        "bg_bottom": (66, 15, 120),
        "title": "Browse Curated Galleries",
        "subtitle": "Collections selected by experts",
    },
    {
        "bg_top": (230, 81, 0),
        "bg_bottom": (153, 51, 0),
        "title": "Today's Pick",
        "subtitle": "A random cultural resource each day",
    },
]

# Priority order: which screenshot files to use
SCREENSHOT_PRIORITY = ["02_search", "03_detail", "04_map", "05_gallery", "01_explore"]


def create_gradient(size, color_top, color_bottom):
    """Create a vertical gradient image."""
    img = Image.new("RGB", size)
    draw = ImageDraw.Draw(img)
    w, h = size
    for y in range(h):
        ratio = y / h
        r = int(color_top[0] + (color_bottom[0] - color_top[0]) * ratio)
        g = int(color_top[1] + (color_bottom[1] - color_top[1]) * ratio)
        b = int(color_top[2] + (color_bottom[2] - color_top[2]) * ratio)
        draw.line([(0, y), (w, y)], fill=(r, g, b))
    return img


def add_rounded_corners(img, radius):
    """Add rounded corners to an image."""
    mask = Image.new("L", img.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), img.size], radius=radius, fill=255)
    result = img.copy()
    result.putalpha(mask)
    return result


def add_device_frame(screenshot, corner_radius, is_ipad=False):
    """Add a device frame (bezel) around the screenshot."""
    bezel = int(corner_radius * 0.35)  # bezel thickness relative to corner radius
    frame_radius = corner_radius + bezel

    frame_w = screenshot.width + bezel * 2
    frame_h = screenshot.height + bezel * 2

    # Create frame with dark bezel
    frame = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
    frame_draw = ImageDraw.Draw(frame)

    # Outer bezel (dark)
    frame_draw.rounded_rectangle(
        [(0, 0), (frame_w - 1, frame_h - 1)],
        radius=frame_radius,
        fill=(30, 30, 30, 255)
    )

    # Subtle highlight on inner edge
    frame_draw.rounded_rectangle(
        [(bezel - 1, bezel - 1), (frame_w - bezel, frame_h - bezel)],
        radius=corner_radius + 1,
        fill=(50, 50, 50, 255)
    )

    # Paste screenshot inside
    frame.paste(screenshot, (bezel, bezel), screenshot)

    return frame


def add_shadow(img, offset=(0, 20), blur_radius=40, shadow_color=(0, 0, 0, 80)):
    """Add a drop shadow to an image with alpha channel."""
    total_w = img.width + abs(offset[0]) + blur_radius * 2
    total_h = img.height + abs(offset[1]) + blur_radius * 2

    shadow = Image.new("RGBA", (total_w, total_h), (0, 0, 0, 0))
    shadow_base = Image.new("RGBA", img.size, shadow_color)
    if img.mode == "RGBA":
        shadow_base.putalpha(img.split()[3])
    shadow.paste(shadow_base,
                 (blur_radius + max(offset[0], 0),
                  blur_radius + max(offset[1], 0)))
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur_radius))
    shadow.paste(img,
                 (blur_radius + max(-offset[0], 0),
                  blur_radius + max(-offset[1], 0)),
                 img if img.mode == "RGBA" else None)
    return shadow


def create_marketing_image(screenshot_path, theme, output_size, lang="ja"):
    """Create a single marketing screenshot."""
    w, h = output_size
    is_ipad = w / h > 0.6  # iPad ~0.75, iPhone ~0.46

    # Device-specific parameters
    if is_ipad:
        title_font_pct = 0.055
        sub_font_pct = 0.030
        max_scale_w_pct = 0.82
        bleed_fraction = 0.35
    else:
        title_font_pct = 0.065
        sub_font_pct = 0.035
        max_scale_w_pct = 0.88
        bleed_fraction = 0.35

    # Language-specific fonts
    if lang == "en":
        font_bold_path = FONT_BOLD_EN
        font_regular_path = FONT_REGULAR_EN
    else:
        font_bold_path = FONT_BOLD
        font_regular_path = FONT_REGULAR

    # Create gradient background
    bg = create_gradient(output_size, theme["bg_top"], theme["bg_bottom"])
    bg = bg.convert("RGBA")

    # --- Calculate text layout first ---
    try:
        font_title = ImageFont.truetype(font_bold_path, int(w * title_font_pct))
        font_subtitle = ImageFont.truetype(font_regular_path, int(w * sub_font_pct))
    except OSError:
        font_title = ImageFont.load_default()
        font_subtitle = ImageFont.load_default()

    draw = ImageDraw.Draw(bg)

    title_bbox = draw.textbbox((0, 0), theme["title"], font=font_title)
    title_h = title_bbox[3] - title_bbox[1]
    sub_bbox = draw.textbbox((0, 0), theme["subtitle"], font=font_subtitle)
    sub_h = sub_bbox[3] - sub_bbox[1]

    title_y = int(h * 0.10)
    sub_y = title_y + title_h + int(h * 0.012)
    text_bottom = sub_y + sub_h

    # --- Load and scale screenshot to fill available space ---
    screenshot = Image.open(screenshot_path).convert("RGBA")

    ss_y = text_bottom + int(h * 0.03)
    desired_visible_h = h - ss_y
    desired_total_h = desired_visible_h / (1.0 - bleed_fraction)
    scale_factor = desired_total_h / screenshot.height
    scale_w = int(screenshot.width * scale_factor)
    scale_h = int(screenshot.height * scale_factor)

    # Cap width so it doesn't exceed the canvas
    max_w = int(w * max_scale_w_pct)
    if scale_w > max_w:
        scale_w = max_w
        scale_h = int(screenshot.height * (scale_w / screenshot.width))

    screenshot = screenshot.resize((scale_w, scale_h), Image.LANCZOS)

    corner_radius = int(scale_w * 0.05)
    screenshot = add_rounded_corners(screenshot, corner_radius)

    # Add device frame
    framed = add_device_frame(screenshot, corner_radius, is_ipad=is_ipad)

    # Position: centered horizontally, pushed down more for breathing room
    ss_x = (w - framed.width) // 2
    ss_y = ss_y + int(h * 0.06)  # extra space below subtitle

    bg.paste(framed, (ss_x, ss_y), framed)

    # --- Draw text on top ---
    title_w = title_bbox[2] - title_bbox[0]
    title_x = (w - title_w) // 2
    draw.text((title_x, title_y), theme["title"], fill=(255, 255, 255), font=font_title)

    sub_w = sub_bbox[2] - sub_bbox[0]
    sub_x = (w - sub_w) // 2
    draw.text((sub_x, sub_y), theme["subtitle"],
              fill=(255, 255, 255, 220), font=font_subtitle)

    # Convert back to RGB
    final = Image.new("RGB", output_size, (0, 0, 0))
    final.paste(bg, (0, 0), bg)
    return final


def find_best_screenshots(input_dir, count=5):
    """Find the best screenshots in priority order."""
    all_files = sorted([f for f in os.listdir(input_dir) if f.endswith(".png")])
    selected = []

    # Try priority order first
    for prefix in SCREENSHOT_PRIORITY:
        for f in all_files:
            if f.startswith(prefix) and f not in selected:
                selected.append(f)
                break
        if len(selected) >= count:
            break

    # Fill remaining from whatever is available
    for f in all_files:
        if f not in selected:
            selected.append(f)
        if len(selected) >= count:
            break

    return [os.path.join(input_dir, f) for f in selected]


def generate_for_lang(lang, themes, iphone_screenshots, ipad_screenshots, output_dir):
    """Generate marketing images for a single language."""
    os.makedirs(output_dir, exist_ok=True)
    print(f"\n=== {lang.upper()} ===")

    for i, (ss_path, theme) in enumerate(zip(iphone_screenshots, themes)):
        fname = f"marketing_{i+1:02d}_iphone.png"
        output_path = os.path.join(output_dir, fname)
        print(f"Generating {fname}...")
        img = create_marketing_image(ss_path, theme, IPHONE_SIZE, lang=lang)
        img.save(output_path, "PNG")
        print(f"  Saved: {output_path} ({img.size[0]}x{img.size[1]})")

    for i, (ss_path, theme) in enumerate(zip(ipad_screenshots, themes)):
        fname = f"marketing_{i+1:02d}_ipad.png"
        output_path = os.path.join(output_dir, fname)
        print(f"Generating {fname}...")
        img = create_marketing_image(ss_path, theme, IPAD_SIZE, lang=lang)
        img.save(output_path, "PNG")
        print(f"  Saved: {output_path} ({img.size[0]}x{img.size[1]})")


def main():
    parser = argparse.ArgumentParser(description="Generate marketing screenshots")
    parser.add_argument("--input-iphone", default=os.path.join(PROJECT_DIR, "screenshots", "resized"),
                        help="Directory with iPhone screenshots")
    parser.add_argument("--input-ipad", default=None,
                        help="Directory with iPad screenshots (optional)")
    parser.add_argument("--output", default=os.path.join(PROJECT_DIR, "screenshots", "marketing"),
                        help="Output directory")
    parser.add_argument("--lang", default=None, choices=["ja", "en"],
                        help="Generate for a single language (default: both)")
    args = parser.parse_args()

    # iPhone screenshots
    iphone_screenshots = find_best_screenshots(args.input_iphone)
    if len(iphone_screenshots) < 3:
        print(f"Error: Need at least 3 screenshots in {args.input_iphone}, found {len(iphone_screenshots)}")
        return

    print(f"Selected {len(iphone_screenshots)} iPhone screenshots:")
    for s in iphone_screenshots:
        print(f"  {os.path.basename(s)}")

    # iPad screenshots
    ipad_input = args.input_ipad or args.input_iphone
    ipad_screenshots = find_best_screenshots(ipad_input)

    # Generate for specified language(s)
    langs = [args.lang] if args.lang else ["ja", "en"]
    for lang in langs:
        themes = THEMES_JA if lang == "ja" else THEMES_EN
        generate_for_lang(lang, themes, iphone_screenshots, ipad_screenshots,
                          os.path.join(args.output, lang))

    print(f"\nDone! Marketing screenshots generated in {args.output}")


if __name__ == "__main__":
    main()
