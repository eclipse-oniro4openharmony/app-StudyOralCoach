from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
MEDIA = ROOT / "entry" / "src" / "main" / "resources" / "base" / "media"
NAMES = [
    "ic_result",
    "ic_thesis",
    "ic_materials",
    "ic_history",
    "ic_code",
    "ic_os",
    "ic_network",
    "ic_mic",
    "ic_upload",
    "ic_target",
    "ic_home",
    "ic_practice",
]


def main() -> None:
    cell_w = 220
    cell_h = 250
    sheet = Image.new("RGB", (cell_w * 4, cell_h * 3), "white")
    draw = ImageDraw.Draw(sheet)
    for index, name in enumerate(NAMES):
        img = Image.open(MEDIA / f"{name}.png").convert("RGBA")
        img.thumbnail((150, 150), Image.Resampling.LANCZOS)
        x = (index % 4) * cell_w + 35
        y = (index // 4) * cell_h + 62
        bg = Image.new("RGBA", (150, 150), (245, 247, 252, 255))
        bg.alpha_composite(img, ((150 - img.width) // 2, (150 - img.height) // 2))
        sheet.paste(bg.convert("RGB"), (x, y))
        draw.text((x, y - 34), name, fill=(0, 0, 0))
    sheet.save(ROOT / "app-icon-sheet.png")


if __name__ == "__main__":
    main()
