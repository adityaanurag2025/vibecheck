#!/usr/bin/env bash
# Render report-card.html -> report-card.png (2x), auto-cropped to the card with a clean dark margin.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
TMP="$(mktemp -d)"

"$CHROME" --headless=new --disable-gpu --hide-scrollbars \
  --force-device-scale-factor=2 --window-size=1140,1600 \
  --user-data-dir="$TMP" --default-background-color=00000000 \
  --screenshot="$DIR/_raw.png" "file://$DIR/report-card.html" >/dev/null 2>&1

python3 - "$DIR/_raw.png" "$DIR/report-card.png" <<'PY'
import sys
from PIL import Image, ImageChops

raw, out = sys.argv[1], sys.argv[2]
img = Image.open(raw).convert("RGB")
bg = img.getpixel((2, 2))                       # outer page color
diff = ImageChops.difference(img, Image.new("RGB", img.size, bg))
bbox = diff.getbbox()
card = img.crop(bbox)

pad = 56                                         # uniform dark frame
canvas = Image.new("RGB", (card.width + 2*pad, card.height + 2*pad), (1, 4, 9))
canvas.paste(card, (pad, pad))
canvas.save(out)
print(f"wrote {out}  ({canvas.width}x{canvas.height})")
PY

rm -rf "$TMP" "$DIR/_raw.png"
