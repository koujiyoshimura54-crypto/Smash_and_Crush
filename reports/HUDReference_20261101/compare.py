"""Analytical comparison only. Native capture tiles are never resampled."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).parent
CROP = (400, 610, 1480, 912)
for name, reference in (("initial", "ReferenceInitial.png"), ("half", "ReferenceHalf.png")):
    native = Image.new("RGB", (1080, 302))
    for row in range(2):
        for column in range(4):
            tile = Image.open(ROOT / f"tiles-{name}" / f"{column}-{row}.png")
            assert tile.size == (270, 151), tile.size
            native.paste(tile, (270 * column, 151 * row))
    native.save(ROOT / f"Native-{name}.png")
    ref = Image.open(ROOT / reference).convert("RGB").crop(CROP)
    combined = Image.new("RGB", (1080, 660), "#222222")
    combined.paste(ref, (0, 24))
    combined.paste(native, (0, 356))
    draw = ImageDraw.Draw(combined)
    draw.text((8, 5), "REFERENCE: original pixels, cropped at (400, 610). No resizing.", fill="white")
    draw.text((8, 335), "NATIVE COMPARISON PASS: before final item/stud/tint refinements. Auto Tap retained. See REPORT.md.", fill="white")
    combined.save(ROOT / f"Comparison-{name}.png")
