"""Generate static, deterministic texture overlays (run once; outputs are committed).

public/textures/paper.png        near-white paper grain for a multiply overlay
public/textures/memory-edge.png  irregular soft paper-edge vignette for memories (RGBA)
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "public" / "textures"
OUT.mkdir(parents=True, exist_ok=True)
W, H = 1920, 1080
rng = np.random.default_rng(1217)


def smooth_noise(scale: int, seed: int) -> np.ndarray:
    r = np.random.default_rng(seed)
    small = r.random((H // scale + 2, W // scale + 2)).astype(np.float32)
    img = Image.fromarray((small * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC)
    return np.asarray(img, dtype=np.float32) / 255.0


# paper: blotches + grain + faint fibres
blotch = smooth_noise(160, 1) * 0.5 + smooth_noise(40, 2) * 0.3 + smooth_noise(12, 3) * 0.2
grain = rng.normal(0, 1, (H, W)).astype(np.float32)
grain_img = Image.fromarray(np.clip(128 + grain * 40, 0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.6))
grain = (np.asarray(grain_img, dtype=np.float32) - 128) / 40
paper = 1.0 - (0.05 * (blotch - 0.5) + 0.028 * grain + 0.035)
fib = Image.new("L", (W, H), 0)
from PIL import ImageDraw

d = ImageDraw.Draw(fib)
for _ in range(900):
    x, y = rng.random() * W, rng.random() * H
    ang = rng.random() * np.pi
    ln = 8 + rng.random() * 30
    d.line([(x, y), (x + np.cos(ang) * ln, y + np.sin(ang) * ln)], fill=int(30 + rng.random() * 40), width=1)
fib = np.asarray(fib.filter(ImageFilter.GaussianBlur(0.7)), dtype=np.float32) / 255.0
paper = np.clip(paper - fib * 0.09, 0, 1)
rgb = np.stack([paper * 1.0, paper * 0.985, paper * 0.955], axis=-1)
Image.fromarray((np.clip(rgb, 0, 1) * 255).astype(np.uint8)).save(OUT / "paper.png", optimize=True)

# memory edge: alpha rises toward an irregular border
yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
dx = np.minimum(xx, W - 1 - xx) / W
dy = np.minimum(yy, H - 1 - yy) / H
dist = np.minimum(dx * 1.6, dy * 1.6 * (W / H) * 0.62)
wob = smooth_noise(60, 7) * 0.05 + smooth_noise(14, 8) * 0.02
edge = np.clip(1 - (dist - wob) / 0.075, 0, 1) ** 1.6
alpha = (edge * 235).astype(np.uint8)
col = np.zeros((H, W, 4), dtype=np.uint8)
col[..., 0], col[..., 1], col[..., 2] = 52, 36, 24
col[..., 3] = alpha
Image.fromarray(col, "RGBA").save(OUT / "memory-edge.png", optimize=True)
print("textures written:", sorted(p.name for p in OUT.iterdir()))
