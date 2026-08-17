from pathlib import Path

from collections import deque

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(r"C:\Users\chens\Downloads\ChatGPT Image Aug 17, 2026, 11_32_35 AM.png")
ICON_SOURCES = {
    "result": Path(r"C:\Users\chens\Downloads\ChatGPT Image Aug 17, 2026, 11_48_15 AM (4).png"),
    "thesis": Path(r"C:\Users\chens\Downloads\ChatGPT Image Aug 17, 2026, 11_48_16 AM (8).png"),
    "materials": Path(r"C:\Users\chens\Downloads\ChatGPT Image Aug 17, 2026, 11_48_16 AM (9).png"),
    "history": Path(r"C:\Users\chens\Downloads\ChatGPT Image Aug 17, 2026, 11_48_17 AM (10).png"),
    "code": Path(r"C:\Users\chens\Downloads\ChatGPT Image Aug 17, 2026, 11_48_15 AM (5).png"),
    "os": Path(r"C:\Users\chens\Downloads\ChatGPT Image Aug 17, 2026, 11_48_15 AM (6).png"),
    "network": Path(r"C:\Users\chens\Downloads\ChatGPT Image Aug 17, 2026, 11_48_16 AM (7).png"),
    "mic": Path(r"C:\Users\chens\Downloads\ChatGPT Image Aug 17, 2026, 11_48_14 AM (1).png"),
    "upload": Path(r"C:\Users\chens\Downloads\ChatGPT Image Aug 17, 2026, 11_48_14 AM (2).png"),
    "target": Path(r"C:\Users\chens\Downloads\ChatGPT Image Aug 17, 2026, 11_48_15 AM (3).png"),
    "home": Path(r"C:\Users\chens\Downloads\ChatGPT Image Aug 17, 2026, 01_44_03 PM.png"),
}


def rounded_rect(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], radius: int, fill: tuple[int, int, int, int]) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill)


def save_icon(path: Path, size: int) -> None:
    src = Image.open(SOURCE).convert("RGBA")
    src = src.resize((size, size), Image.Resampling.LANCZOS)
    path.parent.mkdir(parents=True, exist_ok=True)
    src.save(path)


def save_rounded_icon(path: Path, size: int) -> None:
    src = Image.open(SOURCE).convert("RGBA").resize((size, size), Image.Resampling.LANCZOS)
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size - 1, size - 1), radius=int(size * 0.22), fill=255)
    src.putalpha(mask)
    path.parent.mkdir(parents=True, exist_ok=True)
    src.save(path)


def save_background(path: Path, size: int) -> None:
    img = Image.open(SOURCE).convert("RGBA").resize((size, size), Image.Resampling.LANCZOS)
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)


def save_foreground(path: Path, size: int) -> None:
    src = Image.open(SOURCE).convert("RGBA").resize((size, size), Image.Resampling.LANCZOS)
    alpha = Image.new("L", (size, size), 0)
    src_px = src.load()
    alpha_px = alpha.load()
    for y in range(size):
        for x in range(size):
            r, g, b, _ = src_px[x, y]
            brightness = (r + g + b) // 3
            whiteness = min(r, g, b) - max(abs(r - g), abs(g - b), abs(r - b))
            if brightness > 205 and whiteness > 155:
                alpha_px[x, y] = 255
            elif brightness > 170 and whiteness > 115:
                alpha_px[x, y] = 160
    alpha = alpha.filter(ImageFilter.GaussianBlur(radius=max(1, size // 160)))
    fg = Image.new("RGBA", (size, size), (255, 255, 255, 255))
    fg.putalpha(alpha)
    path.parent.mkdir(parents=True, exist_ok=True)
    fg.save(path)


def save_ui_symbol(path: Path, glyph: str, bg: tuple[int, int, int, int]) -> None:
    size = 160
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    has_bg = bg[3] > 0
    if has_bg:
        draw.rounded_rectangle((8, 8, 152, 152), radius=36, fill=bg)
    white = (255, 255, 255, 255)
    blue = (35, 74, 235, 255)
    ink = white if has_bg else blue
    if glyph == "mic":
        draw.rounded_rectangle((68, 34, 92, 88), radius=12, fill=ink)
        draw.arc((48, 58, 112, 122), start=0, end=180, fill=ink, width=8)
        draw.line((80, 118, 80, 136), fill=ink, width=8)
        draw.line((60, 136, 100, 136), fill=ink, width=8)
    elif glyph == "upload":
        draw.arc((30, 74, 78, 122), 145, 350, fill=blue, width=7)
        draw.arc((56, 48, 112, 104), 190, 355, fill=blue, width=7)
        draw.arc((98, 70, 138, 118), 210, 35, fill=blue, width=7)
        draw.line((42, 108, 118, 108), fill=blue, width=7)
        draw.line((80, 48, 80, 96), fill=blue, width=7)
        draw.line((62, 66, 80, 48), fill=blue, width=7)
        draw.line((98, 66, 80, 48), fill=blue, width=7)
    elif glyph == "home":
        draw.line((42, 82, 80, 44), fill=blue, width=8)
        draw.line((118, 82, 80, 44), fill=blue, width=8)
        draw.rectangle((54, 82, 106, 124), outline=blue, width=8)
    elif glyph == "history":
        draw.ellipse((42, 42, 118, 118), outline=blue, width=8)
        draw.line((80, 80, 80, 54), fill=blue, width=7)
        draw.line((80, 80, 104, 92), fill=blue, width=7)
    elif glyph == "materials":
        draw.rectangle((48, 42, 112, 118), outline=ink, width=8)
        draw.line((62, 66, 98, 66), fill=ink, width=6)
        draw.line((62, 82, 98, 82), fill=ink, width=6)
        draw.line((62, 98, 94, 98), fill=ink, width=6)
    elif glyph == "network":
        draw.ellipse((44, 44, 116, 116), outline=ink, width=8)
        draw.line((44, 80, 116, 80), fill=ink, width=6)
        draw.arc((60, 44, 100, 116), 90, 270, fill=ink, width=6)
        draw.arc((60, 44, 100, 116), 270, 90, fill=ink, width=6)
    elif glyph == "target":
        draw.ellipse((44, 44, 116, 116), outline=ink, width=8)
        draw.ellipse((62, 62, 98, 98), outline=ink, width=7)
        draw.ellipse((76, 76, 84, 84), fill=ink)
    else:
        draw.line((48, 78, 72, 58), fill=ink, width=8)
        draw.line((48, 82, 72, 102), fill=ink, width=8)
        draw.line((112, 78, 88, 58), fill=ink, width=8)
        draw.line((112, 82, 88, 102), fill=ink, width=8)
        draw.line((78, 112, 90, 48), fill=ink, width=8)
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)


def remove_edge_background(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    width, height = rgba.size
    pixels = rgba.load()
    samples = [
        pixels[0, 0],
        pixels[width - 1, 0],
        pixels[0, height - 1],
        pixels[width - 1, height - 1],
    ]
    bg = tuple(sum(sample[channel] for sample in samples) // len(samples) for channel in range(3))
    seen = set()
    queue: deque[tuple[int, int]] = deque()
    for x in range(width):
        queue.append((x, 0))
        queue.append((x, height - 1))
    for y in range(height):
        queue.append((0, y))
        queue.append((width - 1, y))

    while queue:
        x, y = queue.popleft()
        if x < 0 or y < 0 or x >= width or y >= height or (x, y) in seen:
            continue
        r, g, b, a = pixels[x, y]
        distance = abs(r - bg[0]) + abs(g - bg[1]) + abs(b - bg[2])
        if a == 0 or distance <= 58:
            seen.add((x, y))
            pixels[x, y] = (r, g, b, 0)
            queue.append((x + 1, y))
            queue.append((x - 1, y))
            queue.append((x, y + 1))
            queue.append((x, y - 1))
    return rgba


def save_external_icon(path: Path, source: Path, size: int = 512) -> None:
    img = remove_edge_background(Image.open(source))
    alpha_bbox = img.getchannel("A").getbbox()
    if alpha_bbox is not None:
        img = img.crop(alpha_bbox)
    img.thumbnail((int(size * 0.98), int(size * 0.98)), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(img, ((size - img.width) // 2, (size - img.height) // 2))
    path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(path)


def main() -> None:
    for base in [
        ROOT / "AppScope" / "resources" / "base" / "media",
        ROOT / "entry" / "src" / "main" / "resources" / "base" / "media",
    ]:
        save_background(base / "background.png", 1024)
        save_foreground(base / "foreground.png", 1024)
        save_rounded_icon(base / "app_icon_full.png", 1024)
    save_rounded_icon(ROOT / "entry" / "src" / "main" / "resources" / "base" / "media" / "startIcon.png", 1024)

    media = ROOT / "entry" / "src" / "main" / "resources" / "base" / "media"
    save_external_icon(media / "ic_result.png", ICON_SOURCES["result"])
    save_external_icon(media / "ic_mic.png", ICON_SOURCES["mic"])
    save_external_icon(media / "ic_practice.png", ICON_SOURCES["mic"])
    save_external_icon(media / "ic_upload.png", ICON_SOURCES["upload"])
    save_external_icon(media / "ic_materials.png", ICON_SOURCES["materials"])
    save_external_icon(media / "ic_history.png", ICON_SOURCES["history"])
    save_external_icon(media / "ic_code.png", ICON_SOURCES["code"])
    save_external_icon(media / "ic_os.png", ICON_SOURCES["os"])
    save_external_icon(media / "ic_network.png", ICON_SOURCES["network"])
    save_external_icon(media / "ic_thesis.png", ICON_SOURCES["thesis"])
    save_external_icon(media / "ic_target.png", ICON_SOURCES["target"])
    save_external_icon(media / "ic_home.png", ICON_SOURCES["home"])


if __name__ == "__main__":
    main()
