from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCES = [
    Path(r"C:\Users\chens\Downloads\ChatGPT Image Aug 17, 2026, 11_48_15 AM (4).png"),
    Path(r"C:\Users\chens\Downloads\ChatGPT Image Aug 17, 2026, 11_48_16 AM (8).png"),
    Path(r"C:\Users\chens\Downloads\ChatGPT Image Aug 17, 2026, 11_48_16 AM (9).png"),
    Path(r"C:\Users\chens\Downloads\ChatGPT Image Aug 17, 2026, 11_48_17 AM (10).png"),
    Path(r"C:\Users\chens\Downloads\ChatGPT Image Aug 17, 2026, 11_48_15 AM (5).png"),
    Path(r"C:\Users\chens\Downloads\ChatGPT Image Aug 17, 2026, 11_48_15 AM (6).png"),
    Path(r"C:\Users\chens\Downloads\ChatGPT Image Aug 17, 2026, 11_48_16 AM (7).png"),
    Path(r"C:\Users\chens\Downloads\ChatGPT Image Aug 17, 2026, 11_48_14 AM (1).png"),
    Path(r"C:\Users\chens\Downloads\ChatGPT Image Aug 17, 2026, 11_48_14 AM (2).png"),
    Path(r"C:\Users\chens\Downloads\ChatGPT Image Aug 17, 2026, 11_48_15 AM (3).png"),
]


def main() -> None:
    cell_w = 300
    cell_h = 320
    sheet = Image.new("RGB", (cell_w * 5, cell_h * 2), "white")
    draw = ImageDraw.Draw(sheet)
    for index, source in enumerate(SOURCES, start=1):
        img = Image.open(source).convert("RGBA")
        img.thumbnail((220, 220), Image.Resampling.LANCZOS)
        x = ((index - 1) % 5) * cell_w + 40
        y = ((index - 1) // 5) * cell_h + 64
        bg = Image.new("RGBA", (220, 220), (245, 247, 252, 255))
        bg.alpha_composite(img, ((220 - img.width) // 2, (220 - img.height) // 2))
        sheet.paste(bg.convert("RGB"), (x, y))
        draw.text((x, y - 42), f"{index}: {source.name}", fill=(0, 0, 0))
    sheet.save(ROOT / "icon-reference-sheet.png")


if __name__ == "__main__":
    main()
