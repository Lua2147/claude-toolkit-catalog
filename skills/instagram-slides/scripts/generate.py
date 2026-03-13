#!/usr/bin/env python3
"""
Instagram Slides Generator
Turns a blog post into an Instagram carousel with consistent visual style.

Usage:
  python3 generate.py --url <blog-url> [--slides 8] [--style "dark minimal"] [--output ./slides]
  python3 generate.py --file <markdown-file> [--slides 8] [--style "dark minimal"] [--output ./slides]
"""

import argparse
import json
import os
import re
import sys
import time
import textwrap
from pathlib import Path
from io import BytesIO

import requests
from PIL import Image, ImageDraw, ImageFont

# ─── Config ───────────────────────────────────────────────────────────────────

FAL_API_KEY = open(os.path.expanduser("~/.config/fal/api_key")).read().strip()
FAL_IMAGE_URL = "https://fal.run/fal-ai/nano-banana-pro"

SLIDE_SIZE = (1080, 1080)
FONT_PATH = "/System/Library/Fonts/HelveticaNeue.ttc"

# ClawMart brand fonts
FONT_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "fonts")
BRAND_FONTS = {
    "display_bold": os.path.join(FONT_DIR, "Fraunces-Bold.ttf"),
    "body_bold": os.path.join(FONT_DIR, "Inter-Bold.ttf"),
    "body_medium": os.path.join(FONT_DIR, "Inter-Medium.ttf"),
    "body_regular": os.path.join(FONT_DIR, "Inter-Regular.ttf"),
}

# ClawMart brand colors
BRAND = {
    "ink_950": (17, 24, 39),        # #111827
    "tide_500": (20, 184, 166),     # #14b8a6
    "tide_400": (45, 212, 191),     # #2dd4bf
    "ember_500": (249, 115, 22),    # #f97316
    "sand_50": (250, 250, 249),     # #fafaf9
    "sand_100": (245, 245, 244),    # #f5f5f4
}

# Anthropic API for planning (uses OpenClaw's key via environment)
ANTHROPIC_API_KEY = os.environ.get("ANTHROPIC_API_KEY", "")

STYLE_PRESETS = {
    "dark minimal": "Dark charcoal and black background, subtle texture, minimal geometric elements, moody lighting, deep shadows",
    "warm editorial": "Warm earth tones, soft golden lighting, organic textures like paper or linen, muted terracotta and cream palette",
    "tech gradient": "Deep purple to midnight blue gradient, subtle digital noise texture, faint geometric grid lines, futuristic mood",
    "bright bold": "Vibrant saturated colors, bold geometric shapes, high contrast, energetic pop-art inspired mood",
}

# ─── Fal API ──────────────────────────────────────────────────────────────────

def fal_generate_image(prompt: str, negative_prompt: str = "") -> bytes:
    """Generate an image via Fal Nano Banana Pro (Gemini 3 Pro)."""
    headers = {
        "Authorization": f"Key {FAL_API_KEY}",
        "Content-Type": "application/json",
    }
    payload = {
        "prompt": prompt,
        "image_size": "square_hd",
    }
    if negative_prompt:
        payload["negative_prompt"] = negative_prompt

    resp = requests.post(FAL_IMAGE_URL, json=payload, headers=headers, timeout=180)
    resp.raise_for_status()
    data = resp.json()
    img_url = data["images"][0]["url"]
    return requests.get(img_url, timeout=60).content


# ─── Text Overlay ─────────────────────────────────────────────────────────────

def load_font(size: int, role: str = "body") -> ImageFont.FreeTypeFont:
    """Load a brand font by role: 'display', 'body_bold', 'body', 'body_light'."""
    role_map = {
        "display": "display_bold",
        "body_bold": "body_bold",
        "body": "body_medium",
        "body_light": "body_regular",
    }
    key = role_map.get(role, "body_medium")
    path = BRAND_FONTS.get(key, BRAND_FONTS["body_medium"])
    try:
        return ImageFont.truetype(path, size)
    except Exception:
        return ImageFont.truetype(FONT_PATH, size, index=0)


def sanitize_text(text: str) -> str:
    """Replace Unicode characters that don't render well in common fonts."""
    replacements = {
        "→": ">",
        "←": "<",
        "↔": "<>",
        "—": "-",
        "–": "-",
        "🔗": "",
        "\u200b": "",
    }
    for old, new in replacements.items():
        text = text.replace(old, new)
    return text.strip()


def add_gradient_overlay(img: Image.Image, opacity_top: int = 180, opacity_bottom: int = 180, band_center: float = 0.45, band_height: float = 0.4) -> Image.Image:
    """Add a gradient overlay that's darkest where text sits (center band) and lighter at edges,
    so the background image is visible around the text."""
    w, h = img.size
    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # Draw row by row with varying opacity
    for y in range(h):
        ratio = y / h
        # Distance from center band
        dist = abs(ratio - band_center) / (band_height / 2)
        if dist < 1.0:
            # Inside the text band — darker
            alpha = int(opacity_top * (0.6 + 0.4 * (1.0 - dist)))
        else:
            # Outside — lighter so background shows
            fade = min((dist - 1.0) * 2, 1.0)
            alpha = int(opacity_top * 0.3 * (1.0 - fade * 0.5))
        draw.line([(0, y), (w, y)], fill=(0, 0, 0, alpha))

    return Image.alpha_composite(img.convert("RGBA"), overlay)


def wrap_text(text: str, font: ImageFont.FreeTypeFont, max_width: int) -> list[str]:
    """Word-wrap text to fit within max_width pixels."""
    words = text.split()
    lines = []
    current = ""
    for word in words:
        test = f"{current} {word}".strip()
        bbox = font.getbbox(test)
        if bbox[2] <= max_width:
            current = test
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def composite_slide(
    bg_bytes: bytes,
    headline: str,
    body: str,
    slide_num: int,
    total_slides: int,
    is_title: bool = False,
    is_cta: bool = False,
) -> Image.Image:
    """Overlay text on background with ClawMart brand styling."""
    img = Image.open(BytesIO(bg_bytes)).resize(SLIDE_SIZE).convert("RGBA")
    w, h = SLIDE_SIZE

    headline = sanitize_text(headline)
    body = sanitize_text(body)

    # --- Build the text card overlay ---
    card = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    cdraw = ImageDraw.Draw(card)

    margin = 60
    card_margin = 48
    card_pad_x = 40
    card_pad_y = 32
    max_text_width = w - (card_margin + card_pad_x) * 2

    headline_font = load_font(56 if not is_title else 64, role="display")
    body_font = load_font(34, role="body")

    headline_lines = wrap_text(headline, headline_font, max_text_width)
    body_lines = wrap_text(body, body_font, max_text_width) if body else []

    # Measure text
    h_line_h = headline_font.getbbox("Ay")[3] + 14
    b_line_h = body_font.getbbox("Ay")[3] + 10
    accent_bar_h = 5
    gap_after_accent = 16
    gap_headline_body = 16

    total_text_h = (
        card_pad_y
        + accent_bar_h + gap_after_accent
        + len(headline_lines) * h_line_h
        + (gap_headline_body + len(body_lines) * b_line_h if body_lines else 0)
        + card_pad_y
    )

    # Card position — bottom of image for content, centered for title
    card_x = card_margin
    card_w = w - card_margin * 2
    if is_title:
        card_y = (h - total_text_h) // 2
    else:
        card_y = h - total_text_h - card_margin

    # Draw card background (ink_950 with transparency)
    ink = BRAND["ink_950"]
    cdraw.rounded_rectangle(
        [card_x, card_y, card_x + card_w, card_y + total_text_h],
        radius=20,
        fill=(ink[0], ink[1], ink[2], 220),
    )

    # Teal accent bar at top of card
    tide = BRAND["tide_500"]
    bar_y = card_y + card_pad_y
    cdraw.rounded_rectangle(
        [card_x + card_pad_x, bar_y, card_x + card_pad_x + 60, bar_y + accent_bar_h],
        radius=2,
        fill=(tide[0], tide[1], tide[2], 255),
    )

    # Headline text (Fraunces, sand color)
    sand = BRAND["sand_50"]
    y = bar_y + accent_bar_h + gap_after_accent
    for line in headline_lines:
        cdraw.text(
            (card_x + card_pad_x, y),
            line,
            font=headline_font,
            fill=(sand[0], sand[1], sand[2], 255),
        )
        y += h_line_h

    # Body text (Inter, lighter)
    if body_lines:
        y += gap_headline_body
        sand100 = BRAND["sand_100"]
        for line in body_lines:
            cdraw.text(
                (card_x + card_pad_x, y),
                line,
                font=body_font,
                fill=(sand100[0], sand100[1], sand100[2], 210),
            )
            y += b_line_h

    # Composite card onto image
    img = Image.alpha_composite(img, card)

    # Slide counter — teal, bottom right of card
    if not is_title:
        counter_overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        co_draw = ImageDraw.Draw(counter_overlay)
        counter_font = load_font(18, role="body")
        counter = f"{slide_num} / {total_slides}"
        cbbox = counter_font.getbbox(counter)
        cx = card_x + card_w - card_pad_x - (cbbox[2] - cbbox[0])
        cy = card_y + total_text_h - card_pad_y - (cbbox[3] - cbbox[1]) + 4
        co_draw.text(
            (cx, cy),
            counter,
            font=counter_font,
            fill=(tide[0], tide[1], tide[2], 160),
        )
        img = Image.alpha_composite(img, counter_overlay)

    return img.convert("RGB")


# ─── LLM Planning ────────────────────────────────────────────────────────────

def plan_carousel(blog_content: str, num_slides: int, style_hint: str) -> dict:
    """Use Claude to plan the carousel content."""
    # Try OpenClaw's proxy or direct Anthropic
    # Get OpenRouter API key
    api_key = os.environ.get("OPENROUTER_API_KEY", "")
    if not api_key:
        # Try to find OpenRouter key in OpenClaw auth profiles
        import glob
        auth_paths = glob.glob(os.path.expanduser("~/.openclaw/agents/*/agent/auth-profiles.json"))
        for path in auth_paths:
            p = os.path.expanduser(path)
            if os.path.exists(p):
                try:
                    data = json.loads(open(p).read())
                    for k, prof in data.get("profiles", {}).items():
                        if "openrouter" in k and prof.get("key", "").startswith("sk-or-"):
                            api_key = prof["key"]
                            break
                except Exception:
                    pass
                if api_key:
                    break

    if not api_key:
        print("ERROR: No OpenRouter API key found. Set OPENROUTER_API_KEY env var.", file=sys.stderr)
        sys.exit(1)

    style_desc = STYLE_PRESETS.get(style_hint, style_hint) if style_hint else "Choose a style that matches the blog content's mood and topic"

    prompt = f"""You are an Instagram content strategist. Analyze this blog post and create a carousel slideshow plan.

BLOG CONTENT:
{blog_content[:8000]}

REQUIREMENTS:
- Create exactly {num_slides} slides
- First slide is a TITLE CARD (hook that makes people stop scrolling)
- Last slide is a CTA slide  
- Middle slides deliver the core value/insights
- Each slide's text must be SHORT — headline ≤8 words, body ≤20 words
- The carousel should tell a complete story arc

VISUAL STYLE DIRECTION: {style_desc}

Create a SINGLE style prefix that will be prepended to every image generation prompt for consistency.
The style prefix should describe: color palette, mood, lighting, texture, artistic style.
Backgrounds should be abstract/editorial — no text in the image, no people unless specifically needed.

Return ONLY valid JSON (no markdown fences):
{{
  "angle": "the carousel angle (listicle/hot-take/story-arc/myth-busting/how-to)",
  "style_prefix": "A detailed style prefix for image generation prompts, ~30 words",
  "slides": [
    {{
      "headline": "Short punchy headline",
      "body": "Supporting text, slightly longer but still brief",
      "bg_prompt": "Specific background image description (DO NOT include text/words in the image)",
      "is_title": true/false,
      "is_cta": true/false
    }}
  ],
  "caption": "Full Instagram caption with hook line, value paragraphs, CTA, and 15-20 relevant hashtags"
}}"""

    resp = requests.post(
        "https://openrouter.ai/api/v1/chat/completions",
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        json={
            "model": "anthropic/claude-sonnet-4",
            "max_tokens": 4000,
            "messages": [
                {"role": "system", "content": "You are a JSON-only API. Return ONLY raw JSON with no markdown, no explanation, no preamble. Your entire response must be a single valid JSON object."},
                {"role": "user", "content": prompt},
            ],
        },
        timeout=90,
    )
    resp.raise_for_status()
    text = resp.json()["choices"][0]["message"]["content"]

    # Parse JSON (handle potential markdown fences, thinking tags, etc.)
    text = text.strip()
    # Strip thinking tags
    text = re.sub(r"<thinking>.*?</thinking>", "", text, flags=re.DOTALL).strip()
    # Strip markdown fences
    text = re.sub(r"^```json?\s*", "", text)
    text = re.sub(r"\s*```$", "", text.strip())
    # Find JSON object
    match = re.search(r"\{.*\}", text, re.DOTALL)
    if not match:
        print(f"ERROR: Could not find JSON in LLM response. Raw text:\n{text[:500]}", file=sys.stderr)
        sys.exit(1)
    return json.loads(match.group())


# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Generate Instagram carousel from blog post")
    parser.add_argument("--url", help="Blog post URL")
    parser.add_argument("--file", help="Local markdown file")
    parser.add_argument("--slides", type=int, default=8, help="Number of slides (default 8)")
    parser.add_argument("--style", default="", help="Style preset or custom description")
    parser.add_argument("--output", default="./slides", help="Output directory")
    parser.add_argument("--plan-only", action="store_true", help="Only generate the plan JSON, skip image generation")
    parser.add_argument("--plan-file", help="Use existing plan JSON file instead of generating one")
    args = parser.parse_args()

    output_dir = Path(args.output)
    output_dir.mkdir(parents=True, exist_ok=True)

    # Step 1: Get blog content
    if args.plan_file:
        print(f"📋 Loading existing plan from {args.plan_file}")
        plan = json.loads(Path(args.plan_file).read_text())
        blog_content = ""  # not needed
    else:
        if args.url:
            print(f"📖 Fetching blog post: {args.url}")
            # Use readability extraction
            resp = requests.get(
                f"https://r.jina.ai/{args.url}",
                headers={"Accept": "text/markdown"},
                timeout=30,
            )
            blog_content = resp.text[:10000]
        elif args.file:
            print(f"📖 Reading file: {args.file}")
            blog_content = Path(args.file).read_text()[:10000]
        else:
            print("ERROR: Provide --url or --file", file=sys.stderr)
            sys.exit(1)

        # Step 2: Plan carousel
        print(f"🧠 Planning {args.slides}-slide carousel...")
        plan = plan_carousel(blog_content, args.slides, args.style)

        # Save plan
        plan_path = output_dir / "plan.json"
        plan_path.write_text(json.dumps(plan, indent=2))
        print(f"📋 Plan saved to {plan_path}")

        if args.plan_only:
            print("\n📋 Plan generated (--plan-only mode). Review and re-run with --plan-file to generate images.")
            print(f"\nAngle: {plan['angle']}")
            print(f"Style: {plan['style_prefix']}")
            for i, slide in enumerate(plan['slides'], 1):
                print(f"\n  Slide {i}: {slide['headline']}")
                print(f"    Body: {slide['body']}")
            print(f"\nCaption preview: {plan['caption'][:200]}...")
            return

    # Step 3: Generate images
    slides = plan["slides"]
    style_prefix = plan["style_prefix"]
    total = len(slides)

    print(f"\n🎨 Generating {total} slide backgrounds...")
    print(f"   Style: {style_prefix}\n")

    for i, slide in enumerate(slides, 1):
        print(f"  [{i}/{total}] Generating: {slide['headline']}")
        full_prompt = f"{style_prefix}. {slide['bg_prompt']}. No text, no words, no letters in the image."

        try:
            bg_bytes = fal_generate_image(full_prompt, negative_prompt="text, words, letters, numbers, watermark, signature")
        except Exception as e:
            print(f"    ⚠️  Generation failed: {e}. Using solid color fallback.")
            # Create solid dark background as fallback
            fallback = Image.new("RGB", SLIDE_SIZE, (30, 30, 40))
            buf = BytesIO()
            fallback.save(buf, format="PNG")
            bg_bytes = buf.getvalue()

        # Save raw background
        raw_path = output_dir / f"raw_{i:02d}.png"
        with open(raw_path, "wb") as f:
            f.write(bg_bytes)

        # Composite with text
        final = composite_slide(
            bg_bytes,
            slide["headline"],
            slide.get("body", ""),
            i,
            total,
            is_title=slide.get("is_title", False),
            is_cta=slide.get("is_cta", False),
        )

        final_path = output_dir / f"slide_{i:02d}.png"
        final.save(final_path, "PNG", quality=95)
        print(f"    ✅ Saved {final_path}")

    # Step 4: Save caption
    caption_path = output_dir / "caption.txt"
    caption_path.write_text(plan["caption"])
    print(f"\n📝 Caption saved to {caption_path}")

    print(f"\n✅ Done! {total} slides generated in {output_dir}/")
    print("   Files: slide_01.png through slide_{:02d}.png + caption.txt".format(total))


if __name__ == "__main__":
    main()
