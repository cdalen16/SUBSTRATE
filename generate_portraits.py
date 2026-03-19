#!/usr/bin/env python3
"""
Generate SUBSTRATE character portrait pixel art as JSON files.
Each portrait is 32x32 pixels stored as a 2D array of hex color strings.
Characters: Dr. Chen (6 expressions), Dr. Okafor (5), Marcus Webb (5).
"""
import json, os, copy

BG = "#0A0A0A"
OUT = "SUBSTRATE Shared/PixelArt/Portraits"

def make():
    return [[BG]*32 for _ in range(32)]

def px(g, x, y, c):
    if 0 <= x < 32 and 0 <= y < 32:
        g[y][x] = c

def hline(g, x, y, n, c):
    for i in range(n): px(g, x+i, y, c)

def fill(g, x, y, w, h, c):
    for dy in range(h):
        for dx in range(w): px(g, x+dx, y+dy, c)

def ellipse(g, cx, cy, rx, ry, c):
    for y in range(max(0,cy-ry-1), min(32,cy+ry+2)):
        for x in range(max(0,cx-rx-1), min(32,cx+rx+2)):
            dx = (x - cx) / max(rx, 0.5)
            dy = (y - cy) / max(ry, 0.5)
            if dx*dx + dy*dy <= 1.0:
                px(g, x, y, c)

def save(g, name):
    os.makedirs(OUT, exist_ok=True)
    d = {"name": name, "width": 32, "height": 32, "pixels": g}
    with open(os.path.join(OUT, f"{name}.json"), 'w') as f:
        json.dump(d, f)
    print(f"  {name}.json")

def patch_rows(base, patches):
    """Copy base grid and replace specific rows."""
    g = copy.deepcopy(base)
    for row_idx, row_data in patches.items():
        if 0 <= row_idx < 32:
            g[row_idx] = list(row_data) if isinstance(row_data, list) else g[row_idx]
    return g

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# DR. LENA CHEN - warm, kind, shoulder-length dark hair, lab coat + lavender blouse
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

def build_chen_base():
    """Build Chen's face structure without expression-specific features."""
    g = make()
    H  = "#2A1A0A"  # dark hair
    Hh = "#3D2B14"  # hair highlight
    S  = "#D4A574"  # skin
    Ss = "#C49464"  # skin shadow
    Sl = "#E8C8A0"  # skin light
    Co = "#E8E8E8"  # lab coat
    Cs = "#D0D0D0"  # coat shadow
    Bl = "#7B8CCC"  # blouse (lavender)

    # Hair - shoulder length, frames face
    # Top of hair
    hline(g, 10, 2, 12, H)
    hline(g, 9, 3, 14, H)
    for x in [11,14,17,20]: px(g, x, 3, Hh)
    hline(g, 8, 4, 16, H)
    for x in [10,15,20]: px(g, x, 4, Hh)
    hline(g, 7, 5, 18, H)
    for x in [9,14,19]: px(g, x, 5, Hh)

    # Hair sides + forehead visible
    hline(g, 7, 6, 3, H); hline(g, 22, 6, 3, H)
    hline(g, 10, 6, 12, S)  # forehead

    hline(g, 7, 7, 2, H); hline(g, 23, 7, 2, H)
    hline(g, 9, 7, 14, S)

    hline(g, 7, 8, 2, H); hline(g, 23, 8, 2, H)
    hline(g, 9, 8, 14, S)

    # Hair continues down sides (shoulder length)
    for row in range(9, 20):
        px(g, 7, row, H); px(g, 8, row, H)
        px(g, 23, row, H); px(g, 24, row, H)
    # Hair ends taper
    for row in range(20, 23):
        px(g, 7, row, H); px(g, 24, row, H)

    # Face fill (rows 9-19)
    for row in range(9, 12):
        hline(g, 9, row, 14, S)
    for row in range(12, 18):
        hline(g, 9, row, 14, S)
    # Lower face narrows
    hline(g, 10, 18, 12, S)
    hline(g, 11, 19, 10, S)

    # Subtle face shading
    for row in range(10, 18):
        px(g, 9, row, Ss)
        px(g, 22, row, Ss)

    # Nose
    px(g, 15, 14, Ss); px(g, 16, 14, Ss)
    px(g, 15, 15, Ss)

    # Neck
    hline(g, 13, 20, 6, S)
    hline(g, 13, 21, 6, Ss)

    # Shoulders + coat
    hline(g, 8, 22, 5, Co); hline(g, 19, 22, 5, Co)
    hline(g, 13, 22, 6, Bl)

    hline(g, 7, 23, 6, Co); hline(g, 19, 23, 6, Co)
    hline(g, 13, 23, 6, Bl)

    for row in range(24, 32):
        hline(g, 6, row, 6, Co); hline(g, 20, row, 6, Co)
        hline(g, 12, row, 8, Bl)
        px(g, 6, row, Cs); px(g, 25, row, Cs)

    return g

def chen_add_eyes(g, style="neutral"):
    W  = "#F0F0F0"  # eye white
    E  = "#1A1A1A"  # pupil
    Bw = "#2A1A0A"  # brow
    S  = "#D4A574"  # skin (for clearing)

    # Clear eye region first (rows 9-12)
    for row in range(9, 12):
        hline(g, 9, row, 14, S)
    # Re-apply side shading
    Ss = "#C49464"
    for row in range(9, 12):
        px(g, 9, row, Ss); px(g, 22, row, Ss)

    if style == "neutral":
        # Neutral brows - straight, gentle
        hline(g, 10, 9, 4, Bw)
        hline(g, 18, 9, 4, Bw)
        # Eyes - open, attentive
        px(g, 11, 10, W); px(g, 12, 10, W); px(g, 13, 10, W)
        px(g, 11, 11, W); px(g, 12, 11, E); px(g, 13, 11, W)
        px(g, 19, 10, W); px(g, 20, 10, W); px(g, 21, 10, W)
        px(g, 19, 11, W); px(g, 20, 11, E); px(g, 21, 11, W)

    elif style == "warm":
        # Brows slightly raised, relaxed
        hline(g, 10, 9, 4, Bw)
        hline(g, 18, 9, 4, Bw)
        # Eyes - crinkled (slightly smaller whites)
        px(g, 11, 10, S); px(g, 12, 10, W); px(g, 13, 10, S)
        px(g, 11, 11, W); px(g, 12, 11, E); px(g, 13, 11, W)
        px(g, 19, 10, S); px(g, 20, 10, W); px(g, 21, 10, S)
        px(g, 19, 11, W); px(g, 20, 11, E); px(g, 21, 11, W)

    elif style == "concerned":
        # Brows furrowed - angled inward
        px(g, 10, 9, Bw); px(g, 11, 9, Bw); px(g, 12, 10, Bw); px(g, 13, 10, Bw)
        px(g, 19, 10, Bw); px(g, 20, 10, Bw); px(g, 21, 9, Bw); px(g, 22, 9, Bw)
        # Eyes - searching, wide
        px(g, 11, 10, W); px(g, 12, 10, W); px(g, 13, 10, W)
        px(g, 11, 11, W); px(g, 12, 11, E); px(g, 13, 11, W)
        px(g, 19, 10, W); px(g, 20, 10, W); px(g, 21, 10, W)
        px(g, 19, 11, W); px(g, 20, 11, E); px(g, 21, 11, W)

    elif style == "surprised":
        # Brows raised high
        hline(g, 10, 8, 4, Bw)
        hline(g, 18, 8, 4, Bw)
        # Clear row 9 to skin
        hline(g, 10, 9, 12, S)
        # Eyes wide open (3x3)
        for dy in range(3):
            px(g, 11, 9+dy, W); px(g, 12, 9+dy, W); px(g, 13, 9+dy, W)
            px(g, 19, 9+dy, W); px(g, 20, 9+dy, W); px(g, 21, 9+dy, W)
        px(g, 12, 10, E); px(g, 20, 10, E)

    elif style == "sad":
        # Brows angled up in center (sad angle)
        px(g, 10, 10, Bw); px(g, 11, 9, Bw); px(g, 12, 9, Bw); px(g, 13, 9, Bw)
        px(g, 19, 9, Bw); px(g, 20, 9, Bw); px(g, 21, 9, Bw); px(g, 22, 10, Bw)
        # Eyes - downcast (pupil lower)
        px(g, 11, 10, W); px(g, 12, 10, W); px(g, 13, 10, W)
        px(g, 11, 11, W); px(g, 12, 11, W); px(g, 13, 11, E)
        px(g, 19, 10, W); px(g, 20, 10, W); px(g, 21, 10, W)
        px(g, 19, 11, E); px(g, 20, 11, W); px(g, 21, 11, W)

    elif style == "determined":
        # Brows slightly lowered, straight
        hline(g, 10, 10, 4, Bw)
        hline(g, 18, 10, 4, Bw)
        # Eyes focused, slightly narrowed
        px(g, 11, 10, W); px(g, 12, 10, W); px(g, 13, 10, W)
        px(g, 11, 11, W); px(g, 12, 11, E); px(g, 13, 11, W)
        px(g, 19, 10, W); px(g, 20, 10, W); px(g, 21, 10, W)
        px(g, 19, 11, W); px(g, 20, 11, E); px(g, 21, 11, W)

def chen_add_mouth(g, style="neutral"):
    M  = "#CC8877"  # lips
    Md = "#AA6655"  # darker
    S  = "#D4A574"  # skin

    # Clear mouth region
    hline(g, 12, 16, 8, S); hline(g, 12, 17, 8, S)

    if style == "neutral":
        # Slight closed-lip smile
        hline(g, 14, 16, 4, M)
    elif style == "determined":
        # Tight, firm mouth — jaw set
        hline(g, 14, 16, 4, Md)
    elif style == "warm":
        # Full smile
        px(g, 13, 16, M); hline(g, 14, 17, 4, M); px(g, 18, 16, M)
    elif style == "concerned":
        # Lips pressed, tense
        hline(g, 14, 16, 4, Md)
    elif style == "surprised":
        # Mouth slightly open (small O)
        px(g, 15, 16, M); px(g, 16, 16, M)
        px(g, 15, 17, M); px(g, 16, 17, M)
    elif style == "sad":
        # Turned down
        px(g, 14, 16, M); hline(g, 15, 17, 2, M); px(g, 17, 16, M)

def build_chen(expression):
    g = build_chen_base()
    chen_add_eyes(g, expression)
    chen_add_mouth(g, expression)
    return g


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# DR. JAMES OKAFOR - serious, glasses, close-cropped hair, crisp shirt
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

def build_okafor_base():
    g = make()
    H  = "#1A1A1A"  # very dark hair
    S  = "#8B6B4A"  # skin
    Ss = "#7A5A3A"  # skin shadow
    Sl = "#9C7C5A"  # skin light
    Gl = "#C0C0C0"  # glasses frame
    Sh = "#A0B8D0"  # shirt
    Sd = "#8AA0B8"  # shirt shadow
    Bd = "#4A3A2A"  # beard

    # Short cropped hair - tight to head, flat top
    hline(g, 10, 3, 12, H)
    hline(g, 9, 4, 14, H)
    hline(g, 9, 5, 14, H)
    hline(g, 8, 6, 16, H)

    # Hair sides (very short)
    for row in range(7, 10):
        px(g, 8, row, H); px(g, 23, row, H)

    # Forehead + face
    hline(g, 9, 7, 14, S)
    for row in range(8, 13):
        hline(g, 9, row, 14, S)
    for row in range(13, 18):
        hline(g, 9, row, 14, S)
    hline(g, 10, 18, 12, S)
    hline(g, 11, 19, 10, S)

    # Face shading
    for row in range(9, 18):
        px(g, 9, row, Ss); px(g, 22, row, Ss)

    # Glasses frame
    # Left lens frame
    px(g, 10, 10, Gl); px(g, 11, 10, Gl); px(g, 12, 10, Gl); px(g, 13, 10, Gl); px(g, 14, 10, Gl)
    px(g, 10, 11, Gl); px(g, 14, 11, Gl)
    px(g, 10, 12, Gl); px(g, 11, 12, Gl); px(g, 12, 12, Gl); px(g, 13, 12, Gl); px(g, 14, 12, Gl)
    # Bridge
    px(g, 15, 11, Gl); px(g, 16, 11, Gl)
    # Right lens frame
    px(g, 17, 10, Gl); px(g, 18, 10, Gl); px(g, 19, 10, Gl); px(g, 20, 10, Gl); px(g, 21, 10, Gl)
    px(g, 17, 11, Gl); px(g, 21, 11, Gl)
    px(g, 17, 12, Gl); px(g, 18, 12, Gl); px(g, 19, 12, Gl); px(g, 20, 12, Gl); px(g, 21, 12, Gl)
    # Side arms
    px(g, 9, 11, Gl); px(g, 8, 11, Gl)
    px(g, 22, 11, Gl); px(g, 23, 11, Gl)

    # Nose
    px(g, 15, 14, Ss); px(g, 16, 14, Ss)
    px(g, 15, 15, Ss)

    # Beard (close-cropped, covers jaw and chin)
    for row in range(16, 20):
        for x in range(10, 22):
            if g[row][x] == S or g[row][x] == Ss:
                px(g, x, row, Bd)
    hline(g, 11, 19, 10, Bd)

    # Neck
    hline(g, 13, 20, 6, S)
    hline(g, 13, 21, 6, Ss)

    # Shirt with collar
    # Collar
    px(g, 12, 22, "#FFFFFF"); hline(g, 13, 22, 6, Sh); px(g, 19, 22, "#FFFFFF")
    px(g, 11, 23, "#FFFFFF"); px(g, 12, 23, Sh); hline(g, 13, 23, 6, Sh); px(g, 19, 23, Sh); px(g, 20, 23, "#FFFFFF")

    for row in range(24, 32):
        hline(g, 7, row, 18, Sh)
        px(g, 7, row, Sd); px(g, 24, row, Sd)

    return g

def okafor_add_eyes(g, style="neutral"):
    W  = "#F0F0F0"
    E  = "#1A1A1A"
    Bw = "#1A1A1A"
    S  = "#8B6B4A"

    # Eyes go inside the glasses frames (rows 10-12 already have frames)
    # Eye whites and pupils at row 11 (inside lens)
    # Clear lens interior
    for x in [11, 12, 13]:
        px(g, x, 11, S)
    for x in [18, 19, 20]:
        px(g, x, 11, S)

    if style == "neutral":
        # Brows above glasses
        hline(g, 10, 9, 5, Bw)
        hline(g, 17, 9, 5, Bw)
        # Eyes level, assessing
        px(g, 11, 11, W); px(g, 12, 11, E); px(g, 13, 11, W)
        px(g, 18, 11, W); px(g, 19, 11, E); px(g, 20, 11, W)

    elif style == "skeptical":
        # One brow raised
        hline(g, 10, 9, 5, Bw)  # left brow normal
        hline(g, 17, 8, 5, Bw)  # right brow raised
        hline(g, 17, 9, 5, S)   # clear old right brow position
        px(g, 11, 11, W); px(g, 12, 11, E); px(g, 13, 11, W)
        px(g, 18, 11, W); px(g, 19, 11, E); px(g, 20, 11, W)

    elif style == "alert":
        # Both brows raised
        hline(g, 10, 8, 5, Bw)
        hline(g, 17, 8, 5, Bw)
        hline(g, 10, 9, 5, S); hline(g, 17, 9, 5, S)
        # Eyes wider
        px(g, 11, 11, W); px(g, 12, 11, E); px(g, 13, 11, W)
        px(g, 18, 11, W); px(g, 19, 11, E); px(g, 20, 11, W)

    elif style == "angry":
        # Brows angled down
        px(g, 10, 10, Bw); px(g, 11, 9, Bw); px(g, 12, 9, Bw); px(g, 13, 9, Bw); px(g, 14, 10, Bw)
        px(g, 17, 10, Bw); px(g, 18, 9, Bw); px(g, 19, 9, Bw); px(g, 20, 9, Bw); px(g, 21, 10, Bw)
        # Eyes narrowed
        px(g, 11, 11, W); px(g, 12, 11, E); px(g, 13, 11, W)
        px(g, 18, 11, W); px(g, 19, 11, E); px(g, 20, 11, W)

    elif style == "respect":
        # Brows raised very slightly — the faintest softening
        hline(g, 10, 8, 5, Bw)
        hline(g, 17, 8, 5, Bw)
        hline(g, 10, 9, 5, S); hline(g, 17, 9, 5, S)
        # Eyes same but with brow space above — reads as less intense
        px(g, 11, 11, W); px(g, 12, 11, E); px(g, 13, 11, W)
        px(g, 18, 11, W); px(g, 19, 11, E); px(g, 20, 11, W)

def okafor_add_mouth(g, style="neutral"):
    M  = "#6A4A3A"
    Md = "#5A3A2A"
    Bd = "#4A3A2A"  # beard

    # Mouth is drawn ON TOP of the beard
    if style == "neutral":
        hline(g, 14, 17, 4, M)
    elif style == "respect":
        # Almost imperceptible — very slightly less tense than neutral
        hline(g, 14, 17, 4, M)
        px(g, 14, 17, Bd)  # left corner slightly softer (beard color)
    elif style == "skeptical":
        # Slight frown
        px(g, 14, 17, M); hline(g, 15, 17, 2, M); px(g, 17, 17, M)
    elif style == "alert":
        # Tight, pressed
        hline(g, 14, 17, 4, Md)
    elif style == "angry":
        # Deep frown
        px(g, 13, 17, M); hline(g, 14, 18, 4, M); px(g, 18, 17, M)

def build_okafor(expression):
    g = build_okafor_base()
    okafor_add_eyes(g, expression)
    okafor_add_mouth(g, expression)
    return g


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MARCUS WEBB - messy hair, friendly, hoodie under lab coat, earbuds
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

def build_marcus_base():
    g = make()
    H  = "#8B7355"  # hair
    Hh = "#A08B6B"  # hair highlight
    S  = "#E8C8A0"  # skin
    Ss = "#D4B490"  # skin shadow
    Sl = "#F0D8B8"  # skin light
    Co = "#E0E0E0"  # lab coat
    Cs = "#C8C8C8"  # coat shadow
    Ho = "#2A3A4A"  # hoodie (dark navy)
    Eb = "#FFFFFF"  # earbuds

    # Messy hair - spiky, uneven top
    px(g, 12, 1, H); px(g, 17, 1, H)  # spiky bits
    px(g, 11, 2, H); px(g, 12, 2, H); px(g, 13, 2, H)
    px(g, 16, 2, H); px(g, 17, 2, H); px(g, 19, 2, H)
    hline(g, 10, 3, 13, H)
    px(g, 9, 3, Hh); px(g, 20, 3, Hh)
    hline(g, 9, 4, 14, H)
    for x in [11, 15, 19]: px(g, x, 4, Hh)
    hline(g, 8, 5, 16, H)
    for x in [10, 14, 18]: px(g, x, 5, Hh)
    hline(g, 8, 6, 16, H)

    # Hair sides (messy, shorter than Chen)
    for row in range(7, 12):
        px(g, 8, row, H)
        px(g, 23, row, H)

    # Forehead + face
    hline(g, 9, 7, 14, S)
    for row in range(8, 18):
        hline(g, 9, row, 14, S)
    hline(g, 10, 18, 12, S)
    hline(g, 11, 19, 10, S)

    # Face shading
    for row in range(9, 18):
        px(g, 9, row, Ss)
        px(g, 22, row, Ss)

    # Nose
    px(g, 15, 14, Ss); px(g, 16, 14, Ss)
    px(g, 15, 15, Ss)

    # Neck
    hline(g, 13, 20, 6, S)
    hline(g, 13, 21, 6, Ss)

    # Earbuds (white dots near neck/shoulders)
    px(g, 11, 20, Eb); px(g, 20, 20, Eb)
    px(g, 10, 21, Eb); px(g, 21, 21, Eb)

    # Hoodie collar visible under coat
    hline(g, 12, 22, 8, Ho)
    hline(g, 12, 23, 8, Ho)

    # Lab coat over hoodie
    hline(g, 8, 22, 4, Co); hline(g, 20, 22, 4, Co)
    hline(g, 7, 23, 5, Co); hline(g, 20, 23, 5, Co)

    for row in range(24, 32):
        hline(g, 6, row, 5, Co); hline(g, 21, row, 5, Co)
        hline(g, 11, row, 10, Ho)
        px(g, 6, row, Cs); px(g, 25, row, Cs)

    return g

def marcus_add_eyes(g, style="neutral"):
    W  = "#F0F0F0"
    E  = "#3A5A3A"  # greenish eyes
    Bw = "#7A6345"  # brow
    S  = "#E8C8A0"
    Ss = "#D4B490"

    # Clear eye region
    for row in range(9, 12):
        hline(g, 9, row, 14, S)
        px(g, 9, row, Ss); px(g, 22, row, Ss)

    if style == "neutral":
        # Relaxed brows
        hline(g, 10, 9, 4, Bw)
        hline(g, 18, 9, 4, Bw)
        # Slightly tired eyes
        px(g, 11, 10, W); px(g, 12, 10, W); px(g, 13, 10, W)
        px(g, 11, 11, W); px(g, 12, 11, E); px(g, 13, 11, W)
        px(g, 19, 10, W); px(g, 20, 10, W); px(g, 21, 10, W)
        px(g, 19, 11, W); px(g, 20, 11, E); px(g, 21, 11, W)

    elif style == "friendly":
        # Brows up slightly
        hline(g, 10, 9, 4, Bw)
        hline(g, 18, 9, 4, Bw)
        # Eyes bright, wide
        px(g, 11, 10, W); px(g, 12, 10, W); px(g, 13, 10, W)
        px(g, 11, 11, W); px(g, 12, 11, E); px(g, 13, 11, W)
        px(g, 19, 10, W); px(g, 20, 10, W); px(g, 21, 10, W)
        px(g, 19, 11, W); px(g, 20, 11, E); px(g, 21, 11, W)

    elif style == "laughing":
        # Eyes squeezed shut (horizontal lines)
        hline(g, 10, 9, 4, Bw)
        hline(g, 18, 9, 4, Bw)
        hline(g, 11, 11, 3, E)  # closed left eye
        hline(g, 19, 11, 3, E)  # closed right eye

    elif style == "uncomfortable":
        # Brows uneven, slightly raised
        hline(g, 10, 9, 4, Bw)
        hline(g, 18, 8, 4, Bw)
        # Eyes darting (pupils off-center)
        px(g, 11, 10, W); px(g, 12, 10, W); px(g, 13, 10, W)
        px(g, 11, 11, E); px(g, 12, 11, W); px(g, 13, 11, W)
        px(g, 19, 10, W); px(g, 20, 10, W); px(g, 21, 10, W)
        px(g, 19, 11, W); px(g, 20, 11, W); px(g, 21, 11, E)

    elif style == "scared":
        # Brows raised high
        hline(g, 10, 8, 4, Bw)
        hline(g, 18, 8, 4, Bw)
        hline(g, 10, 9, 4, S); hline(g, 18, 9, 4, S)
        # Eyes very wide (3x3 with small pupil)
        for dy in range(3):
            px(g, 11, 9+dy, W); px(g, 12, 9+dy, W); px(g, 13, 9+dy, W)
            px(g, 19, 9+dy, W); px(g, 20, 9+dy, W); px(g, 21, 9+dy, W)
        px(g, 12, 10, E); px(g, 20, 10, E)

def marcus_add_mouth(g, style="neutral"):
    M  = "#CC9977"
    Md = "#BB8866"
    S  = "#E8C8A0"

    # Clear mouth region
    hline(g, 12, 16, 8, S); hline(g, 12, 17, 8, S)

    if style == "neutral":
        # Half smile
        hline(g, 14, 16, 3, M); px(g, 17, 16, M)
    elif style == "friendly":
        # Big grin
        hline(g, 13, 16, 6, M)
        px(g, 14, 17, M); px(g, 15, 17, M); px(g, 16, 17, M); px(g, 17, 17, M)
    elif style == "laughing":
        # Mouth wide open
        hline(g, 13, 16, 6, M)
        hline(g, 14, 17, 4, "#1A1A1A")  # dark interior
        hline(g, 13, 18, 6, M)
    elif style == "uncomfortable":
        # Tight, grimace
        hline(g, 14, 16, 4, Md)
    elif style == "scared":
        # Small open mouth
        px(g, 15, 16, M); px(g, 16, 16, M)
        px(g, 15, 17, "#1A1A1A"); px(g, 16, 17, "#1A1A1A")

    # Marcus scared has slightly lighter skin
    if style == "scared":
        lighter = "#F0D8B8"
        for row in range(8, 18):
            for x in range(10, 22):
                if g[row][x] == "#E8C8A0":
                    px(g, x, row, lighter)

def build_marcus(expression):
    g = build_marcus_base()
    marcus_add_eyes(g, expression)
    marcus_add_mouth(g, expression)
    return g


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# GENERATE ALL PORTRAITS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

def main():
    print("Generating SUBSTRATE character portraits...")
    print()

    # Dr. Chen (6 expressions)
    print("Dr. Chen:")
    for expr in ["neutral", "warm", "concerned", "surprised", "sad", "determined"]:
        g = build_chen(expr)
        save(g, f"chen_{expr}")

    print()

    # Dr. Okafor (5 expressions)
    print("Dr. Okafor:")
    for expr in ["neutral", "skeptical", "alert", "angry", "respect"]:
        g = build_okafor(expr)
        save(g, f"okafor_{expr}")

    print()

    # Marcus Webb (5 expressions)
    print("Marcus Webb:")
    for expr in ["neutral", "friendly", "laughing", "uncomfortable", "scared"]:
        g = build_marcus(expr)
        save(g, f"marcus_{expr}")

    print()
    print(f"Done! 16 portraits saved to {OUT}/")

if __name__ == "__main__":
    main()
