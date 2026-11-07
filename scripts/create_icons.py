"""Render Sumi's original geometric app mark at each platform's required size."""
from pathlib import Path
import json
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1] / "app"
icon = Image.new("RGB", (1024, 1024), "#FFF9F0")
d = ImageDraw.Draw(icon)
# Original soft cuttlefish mark, built as vector-like geometric primitives.
d.ellipse((185, 250, 840, 760), fill="#3EA9A0")
for x in (285, 395, 505, 615):
    d.rounded_rectangle((x, 540, x+120, 805), radius=60, fill="#34346B")
d.rounded_rectangle((260, 220, 765, 680), radius=225, fill="#34346B")
d.ellipse((470, 290, 535, 370), fill="#F47C65")
for x in (365, 595):
    d.ellipse((x-65, 415, x+65, 570), fill="#FFF5E7")
    d.ellipse((x-28, 450, x+35, 550), fill="#24304B")
    d.ellipse((x+3, 462, x+23, 482), fill="white")
d.arc((465, 550, 555, 625), 0, 180, fill="#F47C65", width=16)

def save(path, size):
    path.parent.mkdir(parents=True, exist_ok=True)
    icon.resize((size, size), Image.Resampling.LANCZOS).save(path)

save(root / "web/favicon.png", 64)
for size in (192, 512):
    for name in (f"Icon-{size}.png", f"Icon-maskable-{size}.png"):
        save(root / "web/icons" / name, size)
for density, size in (("mdpi",48),("hdpi",72),("xhdpi",96),("xxhdpi",144),("xxxhdpi",192)):
    save(root / "android/app/src/main/res" / f"mipmap-{density}/ic_launcher.png", size)
ios = root / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
data = json.loads((ios / "Contents.json").read_text(encoding="utf-8"))
for item in data["images"]:
    if item.get("filename"):
        size = round(float(item["size"].split("x")[0]) * float(item["scale"][:-1]))
        save(ios / item["filename"], size)
manifest = json.loads((root / "web/manifest.json").read_text(encoding="utf-8"))
manifest.update(name="Sumi · a little closer", short_name="Sumi",
    background_color="#FFF9F0", theme_color="#34346B",
    description="A thoughtful route from curiosity to something you can make.")
(root / "web/manifest.json").write_text(json.dumps(manifest, indent=2)+"\n", encoding="utf-8")
print("Original Sumi icons rendered for Android, iOS, and web.")
