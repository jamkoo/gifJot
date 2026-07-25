#!/usr/bin/env python3
"""Generate the lightweight interaction GIFs used on the GifJot landing page."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


WIDTH = 640
HEIGHT = 400
FRAME_COUNT = 40
FRAME_DURATION_MS = 80

ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = ROOT / "public" / "demos"

FONT_REGULAR = "/System/Library/Fonts/Supplemental/Arial.ttf"
FONT_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"

INK = "#1D1D20"
MUTED = "#686871"
HAIRLINE = "#DADAE0"
SURFACE = "#FFFFFF"
CANVAS = "#F1F1F4"
INDIGO = "#6758E8"
INDIGO_DARK = "#5546D7"
INDIGO_TINT = "#EEECFF"
SUCCESS = "#2E7D4C"
SUCCESS_TINT = "#EAF6EE"
WARNING = "#B85E4B"
WARNING_TINT = "#FBEDE9"


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(FONT_BOLD if bold else FONT_REGULAR, size)


def ease(value: float) -> float:
    value = max(0.0, min(1.0, value))
    return 1 - (1 - value) ** 3


def phase(frame: int, start: int, end: int) -> float:
    if end <= start:
        return 1.0
    return ease((frame - start) / (end - start))


def lerp(start: float, end: float, amount: float) -> float:
    return start + (end - start) * amount


def base_frame(title: str) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    image = Image.new("RGBA", (WIDTH, HEIGHT), CANVAS)

    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        (35, 33, 605, 373),
        radius=22,
        fill=(29, 29, 32, 42),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(17))
    image.alpha_composite(shadow)

    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle(
        (28, 22, 612, 362),
        radius=20,
        fill=SURFACE,
        outline=HAIRLINE,
        width=1,
    )
    draw.line((28, 74, 612, 74), fill="#E8E8ED", width=1)

    for index, color in enumerate(("#FF5F57", "#FEBC2E", "#28C840")):
        x = 52 + index * 18
        draw.ellipse((x, 43, x + 10, 53), fill=color)

    title_box = draw.textbbox((0, 0), title, font=font(16, True))
    title_width = title_box[2] - title_box[0]
    draw.text(
        ((WIDTH - title_width) / 2, 40),
        title,
        fill=INK,
        font=font(16, True),
    )

    draw.rounded_rectangle((536, 39, 584, 57), radius=5, fill=INDIGO_TINT)
    draw.ellipse((546, 45, 552, 51), fill=INDIGO)
    draw.text((558, 42), "REC", fill=INDIGO_DARK, font=font(9, True))

    return image, draw


def panel(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    *,
    fill: str = "#FBFBFD",
    outline: str = HAIRLINE,
    radius: int = 10,
) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=1)


def label(draw: ImageDraw.ImageDraw, x: int, y: int, value: str) -> None:
    draw.text((x, y), value, fill=MUTED, font=font(11, True))


def cursor(
    image: Image.Image,
    x: float,
    y: float,
    *,
    click_amount: float = 0.0,
) -> None:
    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)

    if click_amount > 0:
        radius = 12 + click_amount * 14
        alpha = int(120 * (1 - click_amount))
        draw.ellipse(
            (x - radius, y - radius, x + radius, y + radius),
            outline=(103, 88, 232, alpha),
            width=3,
        )

    outer = [
        (x, y),
        (x + 3, y + 30),
        (x + 10, y + 23),
        (x + 18, y + 39),
        (x + 26, y + 35),
        (x + 18, y + 20),
        (x + 29, y + 18),
    ]
    inner = [
        (x + 3, y + 4),
        (x + 6, y + 24),
        (x + 11, y + 18),
        (x + 19, y + 34),
        (x + 22, y + 32),
        (x + 14, y + 16),
        (x + 23, y + 15),
    ]
    draw.polygon(outer, fill=(255, 255, 255, 255))
    draw.polygon(inner, fill=(29, 29, 32, 255))
    image.alpha_composite(layer)


def save_gif(frames: list[Image.Image], filename: str) -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    palette_source = Image.new("RGB", (WIDTH, HEIGHT * len(frames)), SURFACE)
    for index, frame in enumerate(frames):
        palette_source.paste(frame.convert("RGB"), (0, index * HEIGHT))
    shared_palette = palette_source.quantize(
        colors=128,
        method=Image.Quantize.MEDIANCUT,
    )
    palette_frames = [
        frame.convert("RGB").quantize(
            palette=shared_palette,
            dither=Image.Dither.NONE,
        )
        for frame in frames
    ]
    destination = OUTPUT_DIR / filename
    palette_frames[0].save(
        destination,
        save_all=True,
        append_images=palette_frames[1:],
        duration=FRAME_DURATION_MS,
        loop=0,
        disposal=2,
        optimize=False,
    )
    print(destination.relative_to(ROOT))


def bug_report_frames() -> list[Image.Image]:
    frames: list[Image.Image] = []

    for frame in range(FRAME_COUNT):
        image, draw = base_frame("Issue details")

        label(draw, 62, 98, "BUG REPORT")
        draw.text(
            (62, 119),
            "Priority selection does not stick",
            fill=INK,
            font=font(22, True),
        )

        panel(draw, (62, 168, 578, 226), fill=SURFACE)
        draw.text((80, 188), "Priority", fill=MUTED, font=font(14))

        menu_open = 12 <= frame <= 28
        bug_visible = frame >= 29
        selected_value = "Not set" if bug_visible else "Normal"
        draw.text((472, 186), selected_value, fill=INK, font=font(15, True))
        draw.line((548, 193, 553, 198), fill=MUTED, width=2)
        draw.line((553, 198, 558, 193), fill=MUTED, width=2)

        if menu_open:
            panel(draw, (366, 232, 578, 335), fill=SURFACE, radius=9)
            options = [("Normal", 247), ("High", 278), ("Critical", 309)]
            for value, y in options:
                if value == "High":
                    draw.rounded_rectangle(
                        (374, y - 4, 570, y + 23),
                        radius=6,
                        fill=INDIGO_TINT,
                    )
                    color = INDIGO_DARK
                else:
                    color = INK
                draw.text((390, y), value, fill=color, font=font(13, value == "High"))

        if bug_visible:
            draw.rounded_rectangle(
                (62, 250, 350, 306),
                radius=10,
                fill=WARNING_TINT,
            )
            draw.ellipse((79, 268, 95, 284), fill=WARNING)
            draw.text((84, 268), "!", fill="#FFFFFF", font=font(11, True))
            draw.text(
                (108, 261),
                "The choice disappeared.",
                fill=INK,
                font=font(14, True),
            )
            draw.text((108, 281), "The bug is visible.", fill=MUTED, font=font(11))

        if frame < 11:
            amount = phase(frame, 2, 10)
            x = lerp(522, 548, amount)
            y = lerp(312, 190, amount)
        elif frame < 22:
            amount = phase(frame, 14, 21)
            x = lerp(548, 474, amount)
            y = lerp(190, 282, amount)
        else:
            x = 474
            y = 282

        click_amount = 0.0
        if 22 <= frame <= 27:
            click_amount = (frame - 22) / 5
        cursor(image, x, y, click_amount=click_amount)
        frames.append(image)

    return frames


def product_update_frames() -> list[Image.Image]:
    frames: list[Image.Image] = []

    for frame in range(FRAME_COUNT):
        image, draw = base_frame("Customer requests")

        label(draw, 62, 98, "NEW FILTER")
        draw.text((62, 119), "Filter requests by status", fill=INK, font=font(22, True))

        active_open = frame >= 23
        chips = [("All", 62, 126), ("Open", 136, 221), ("Closed", 231, 332)]
        for value, left, right in chips:
            active = (value == "All" and not active_open) or (
                value == "Open" and active_open
            )
            draw.rounded_rectangle(
                (left, 165, right, 206),
                radius=8,
                fill=INDIGO_TINT if active else SURFACE,
                outline=INDIGO if active else HAIRLINE,
                width=2 if active else 1,
            )
            box = draw.textbbox((0, 0), value, font=font(13, active))
            width = box[2] - box[0]
            draw.text(
                (left + ((right - left) - width) / 2, 177),
                value,
                fill=INDIGO_DARK if active else MUTED,
                font=font(13, active),
            )

        requests = [
            ("Keyboard shortcuts", "Open", INDIGO),
            ("Export location", "Open", SUCCESS),
            ("Theme preference", "Closed", "#9A9AA3"),
        ]
        visible_requests = requests[:2] if active_open else requests

        for index, (title, status, color) in enumerate(visible_requests):
            y = 224 + index * 43
            panel(draw, (62, y, 578, y + 35), fill=SURFACE, radius=7)
            draw.ellipse((78, y + 14, 86, y + 22), fill=color)
            draw.text((98, y + 7), title, fill=INK, font=font(12, True))
            status_box = draw.textbbox((0, 0), status, font=font(10, True))
            status_width = status_box[2] - status_box[0]
            draw.text(
                (558 - status_width, y + 10),
                status,
                fill=MUTED,
                font=font(10, True),
            )

        if active_open:
            draw.rounded_rectangle((468, 111, 578, 139), radius=7, fill=SUCCESS_TINT)
            draw.text((484, 119), "2 OPEN", fill=SUCCESS, font=font(10, True))

        if frame < 18:
            amount = phase(frame, 3, 17)
            x = lerp(510, 183, amount)
            y = lerp(310, 178, amount)
        else:
            x = 183
            y = 178

        click_amount = 0.0
        if 18 <= frame <= 23:
            click_amount = (frame - 18) / 5
        cursor(image, x, y, click_amount=click_amount)
        frames.append(image)

    return frames


def support_reply_frames() -> list[Image.Image]:
    frames: list[Image.Image] = []

    for frame in range(FRAME_COUNT):
        image, draw = base_frame("GifJot Settings")

        label(draw, 62, 98, "CLIPBOARD")
        draw.text((62, 119), "Copy every finished GIF", fill=INK, font=font(22, True))

        panel(draw, (62, 168, 578, 234), fill=SURFACE)
        draw.text((82, 187), "Copy after recording", fill=INK, font=font(15, True))
        draw.text((82, 208), "Ready to paste as soon as recording ends.", fill=MUTED, font=font(11))

        toggle_on = frame >= 23
        toggle_amount = phase(frame, 20, 25) if toggle_on else 0
        toggle_color = INDIGO if toggle_on else "#B9B9C2"
        draw.rounded_rectangle((508, 186, 559, 214), radius=14, fill=toggle_color)
        knob_x = int(511 + 23 * toggle_amount)
        draw.ellipse((knob_x, 189, knob_x + 22, 211), fill=SURFACE)

        panel(draw, (62, 252, 578, 316), fill="#FBFBFD")
        draw.text((82, 271), "Save location", fill=INK, font=font(13, True))
        draw.text((82, 292), "~/GifJot", fill=MUTED, font=font(11))

        if toggle_on:
            draw.rounded_rectangle((379, 264, 558, 304), radius=9, fill=SUCCESS_TINT)
            draw.ellipse((393, 276, 409, 292), fill=SUCCESS)
            draw.text((397, 275), "✓", fill=SURFACE, font=font(11, True))
            draw.text((420, 276), "Copied automatically", fill=SUCCESS, font=font(12, True))

        if frame < 19:
            amount = phase(frame, 3, 18)
            x = lerp(492, 526, amount)
            y = lerp(317, 193, amount)
        else:
            x = 526
            y = 193

        click_amount = 0.0
        if 19 <= frame <= 24:
            click_amount = (frame - 19) / 5
        cursor(image, x, y, click_amount=click_amount)
        frames.append(image)

    return frames


def main() -> None:
    save_gif(bug_report_frames(), "bug-report.gif")
    save_gif(product_update_frames(), "product-update.gif")
    save_gif(support_reply_frames(), "support-reply.gif")


if __name__ == "__main__":
    main()
