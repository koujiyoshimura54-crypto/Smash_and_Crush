"""Compare supplied reference with unchanged MCP pixels. Never enlarge the native capture."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
root = Path(__file__).resolve().parents[1]
ref = Image.open(root / "reports/DumbbellInventory_Reference_20261103.png").convert("RGB")
live = Image.open(root / "reports/DumbbellInventory_Normal_20261103.jpg").convert("RGB")
font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 18)
small = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 14)
canvas = Image.new("RGB", (1080, 730), "#24202d")
draw = ImageDraw.Draw(canvas)
draw.text((18, 14), "Dumbbell inventory: measured reference / native rendered result", font=font, fill="white")
draw.text((18, 43), "Reference crops uniformly reduced to 53.6%. Native MCP crops remain 1:1 (no stretching).", font=small, fill="#dddddd")
draw.text((18, 66), "Full originals: reference 1586x992; MCP raster 1029x579 from viewport 1279x720 / GUI 1279x662.", font=small, fill="#dddddd")
regions = [
 ("Equipped", (92,350,514,936), (138,235,368,551), 18, 108),
 ("Card", (526,350,846,674), (376,236,544,406), 542, 108),
 ("Sell panel (Owned row intentionally omitted)", (527,668,1071,960), (376,402,670,542), 342, 478),
]
for name, rb, lb, x, y in regions:
    a, b = ref.crop(rb), live.crop(lb)
    a = a.resize((round(a.width * .536), round(a.height * .536)), Image.Resampling.LANCZOS)
    draw.text((x,y), name, font=small, fill="white")
    draw.text((x,y+24), "Reference", font=small, fill="#cba0ff")
    draw.text((x+a.width+20,y+24), "Native", font=small, fill="#cba0ff")
    canvas.paste(a, (x,y+46))
    canvas.paste(b, (x+a.width+20,y+46))
draw.text((18, 684), "Preserved asset differences: existing dumbbell/bag art, square-stud texture, existing Win button material.", font=small, fill="#dddddd")
draw.text((18, 706), "Japanese Equip/Equipped uses the existing fallback glyphs; no claim of exact 1586x992 render equivalence.", font=small, fill="#dddddd")
canvas.save(root / "reports/DumbbellInventory_Compare_20261103.png")
