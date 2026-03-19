#!/usr/bin/env python3
"""
Generate SUBSTRATE environment scenes (128x72) and UI icons (16x16, 12x12).
Environments are atmospheric and impressionistic — mood over detail.
Icons are clean and instantly readable at small sizes.
"""
import json, os, math, random

BG = "#0A0A0A"
ENV_DIR = "SUBSTRATE Shared/PixelArt/Environments"
ICON_DIR = "SUBSTRATE Shared/PixelArt/Icons"

# ─── Helpers ──────────────────────────────────────────────

def make(w, h):
    return [[BG]*w for _ in range(h)]

def px(g, x, y, c):
    h = len(g); w = len(g[0])
    if 0 <= x < w and 0 <= y < h:
        g[y][x] = c

def hline(g, x, y, n, c):
    for i in range(n): px(g, x+i, y, c)

def vline(g, x, y, n, c):
    for i in range(n): px(g, x, y+i, c)

def fill(g, x, y, w, h, c):
    for dy in range(h):
        for dx in range(w): px(g, x+dx, y+dy, c)

def rect_outline(g, x, y, w, h, c):
    hline(g, x, y, w, c)
    hline(g, x, y+h-1, w, c)
    vline(g, x, y, h, c)
    vline(g, x+w-1, y, h, c)

def save(g, name, directory, w, h):
    os.makedirs(directory, exist_ok=True)
    d = {"name": name, "width": w, "height": h, "pixels": g}
    path = os.path.join(directory, f"{name}.json")
    with open(path, 'w') as f:
        json.dump(d, f)
    print(f"  {name}.json ({w}x{h})")


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ENVIRONMENT SCENES (128x72)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

def env_evaluation_room():
    """Sterile, gray, fluorescent, one-way mirror. Clinical and confining."""
    g = make(128, 72)
    # Walls — light gray
    fill(g, 0, 0, 128, 72, "#C0C0C0")
    # Floor — darker gray tiles
    fill(g, 0, 50, 128, 22, "#808080")
    # Floor tile lines
    for x in range(0, 128, 16):
        vline(g, x, 50, 22, "#707070")
    for y in [58, 66]:
        hline(g, 0, y, 128, "#707070")
    # Ceiling
    fill(g, 0, 0, 128, 8, "#D8D8D8")
    # Fluorescent lights (two strips)
    fill(g, 20, 3, 30, 3, "#FFFFFF")
    fill(g, 78, 3, 30, 3, "#FFFFFF")
    # Light glow on ceiling
    fill(g, 18, 2, 34, 1, "#EEEEFF")
    fill(g, 76, 2, 34, 1, "#EEEEFF")
    # One-way mirror on back wall
    fill(g, 30, 10, 68, 25, "#1A2A3A")
    rect_outline(g, 30, 10, 68, 25, "#808080")
    # Faint reflection in mirror
    fill(g, 50, 15, 20, 8, "#2A3A4A")
    # Table
    fill(g, 25, 40, 78, 4, "#6A6A6A")
    # Table legs
    fill(g, 30, 44, 3, 8, "#5A5A5A")
    fill(g, 95, 44, 3, 8, "#5A5A5A")
    # Laptop on table
    fill(g, 55, 36, 14, 4, "#3A3A3A")  # screen
    fill(g, 54, 40, 16, 2, "#4A4A4A")  # base
    # Notebook
    fill(g, 75, 38, 10, 4, "#E8E0D0")
    # Coffee cup
    fill(g, 42, 37, 5, 5, "#8B6B4A")
    fill(g, 42, 36, 5, 1, "#A08060")  # rim
    # Two chairs (simple shapes)
    fill(g, 35, 45, 12, 8, "#5A5A5A")  # left chair
    fill(g, 80, 45, 12, 8, "#5A5A5A")  # right chair
    return g

def env_chen_office():
    """Warm, bookshelves, desk lamp, potted plant. Lived-in, human."""
    g = make(128, 72)
    # Warm wall color
    fill(g, 0, 0, 128, 72, "#C8B8A0")
    # Floor — warm wood
    fill(g, 0, 52, 128, 20, "#8B7355")
    for x in range(0, 128, 8):
        vline(g, x, 52, 20, "#7A6345")
    # Ceiling
    fill(g, 0, 0, 128, 6, "#D0C0A8")
    # Bookshelf on left wall (floor to ceiling)
    fill(g, 0, 6, 35, 46, "#6A4A2A")
    # Book rows
    for y in range(8, 48, 5):
        for x in range(2, 33, 4):
            c = random.choice(["#CC4444", "#4444AA", "#44AA44", "#CCAA44", "#AA44AA", "#886644"])
            fill(g, x, y, 3, 4, c)
    # Desk
    fill(g, 50, 38, 55, 4, "#8B6B4A")
    fill(g, 55, 42, 3, 12, "#7A5A3A")  # leg
    fill(g, 98, 42, 3, 12, "#7A5A3A")  # leg
    # Two monitors on desk
    fill(g, 58, 28, 15, 10, "#2A2A2A")  # monitor 1
    fill(g, 60, 29, 11, 7, "#3A5A7A")  # screen glow
    fill(g, 80, 28, 15, 10, "#2A2A2A")  # monitor 2
    fill(g, 82, 29, 11, 7, "#3A5A7A")
    # Desk lamp (warm glow)
    fill(g, 105, 30, 6, 3, "#FFDD88")  # lampshade
    vline(g, 108, 33, 5, "#AA8844")  # stem
    # Lamp glow on desk
    fill(g, 100, 36, 16, 3, "#FFE8B0")
    # Potted plant (slightly wilting)
    fill(g, 112, 32, 8, 6, "#44884A")  # leaves
    fill(g, 113, 33, 2, 3, "#55AA55")  # highlight
    fill(g, 115, 38, 4, 4, "#8B6644")  # pot
    # Corkboard with photos
    fill(g, 40, 10, 20, 15, "#AA8855")
    for px_x, px_y in [(42,12), (48,13), (44,18), (52,12), (50,18)]:
        fill(g, px_x, px_y, 5, 4, random.choice(["#E8D8C0", "#C8D8E0", "#E0D0C0"]))
    # Fluorescent overhead (harsh, contrasting with lamp)
    fill(g, 40, 2, 50, 2, "#E8E8FF")
    return g

def env_server_room():
    """Blue-lit server racks, blinking lights, cable veins. Vast and cold."""
    g = make(128, 72)
    # Dark blue base
    fill(g, 0, 0, 128, 72, "#0A0A2E")
    # Raised floor
    fill(g, 0, 58, 128, 14, "#1A1A3A")
    # Floor tiles
    for x in range(0, 128, 8):
        vline(g, x, 58, 14, "#151530")
    # Server racks — tall rectangles receding into depth
    rack_positions = [5, 22, 39, 56, 73, 90, 107]
    for i, rx in enumerate(rack_positions):
        depth = max(0.5, 1.0 - i * 0.08)
        h = int(48 * depth)
        y = 58 - h
        shade = int(0x1A + i * 8)
        color = f"#{shade:02X}{shade:02X}{shade+0x20:02X}"
        fill(g, rx, y, 12, h, color)
        # Status lights on each rack
        for ly in range(y+3, y+h-2, 4):
            light = random.choice(["#33FF33", "#33FF33", "#FFAA00", "#FF3333", "#33FF33"])
            px(g, rx+3, ly, light)
            px(g, rx+8, ly, light)
    # Cable bundles on ceiling
    for y in range(2, 6):
        for x in range(0, 128):
            if (x + y) % 3 == 0:
                px(g, x, y, "#2A2A4A")
            elif (x + y) % 5 == 0:
                px(g, x, y, "#1A1A3A")
    # Blue ambient glow from above
    for x in range(0, 128, 20):
        fill(g, x+8, 0, 4, 2, "#2244AA")
    # Air vent glow
    fill(g, 0, 6, 128, 1, "#151535")
    return g

def env_break_room():
    """Vending machines, flickering fluorescent, night window. Lonely."""
    g = make(128, 72)
    # Dim walls
    fill(g, 0, 0, 128, 72, "#8A8A7A")
    # Floor
    fill(g, 0, 50, 128, 22, "#5A5A4A")
    # Ceiling
    fill(g, 0, 0, 128, 6, "#9A9A8A")
    # Flickering fluorescent (one working, one dim)
    fill(g, 30, 2, 25, 2, "#E8E8D0")  # working
    fill(g, 75, 2, 25, 2, "#6A6A5A")  # flickering/dim
    px(g, 80, 2, "#AAAAAA")  # flicker bright spot
    # Vending machines (left wall)
    # Snack machine
    fill(g, 5, 15, 18, 35, "#3A3A4A")
    fill(g, 7, 17, 14, 20, "#2A4A5A")  # glass front
    # Rows of items
    for vy in range(18, 35, 4):
        for vx in range(8, 20, 4):
            fill(g, vx, vy, 3, 3, random.choice(["#CC4444", "#44CC44", "#4444CC", "#CCCC44"]))
    # Drink machine
    fill(g, 26, 15, 18, 35, "#3A3A4A")
    fill(g, 28, 17, 14, 20, "#2A3A5A")
    # Microwave on counter
    fill(g, 55, 38, 12, 8, "#4A4A4A")
    fill(g, 57, 39, 8, 5, "#1A1A1A")  # window
    # Counter
    fill(g, 50, 46, 35, 3, "#6A6A5A")
    # Round table
    fill(g, 75, 40, 20, 3, "#7A6A5A")
    # Chairs
    fill(g, 72, 44, 8, 8, "#5A5A4A")
    fill(g, 90, 44, 8, 8, "#5A5A4A")
    # Window (night) — right wall
    fill(g, 100, 12, 22, 20, "#0A0A2A")  # dark sky
    rect_outline(g, 100, 12, 22, 20, "#6A6A5A")
    # Parking lot light through window
    fill(g, 112, 26, 4, 4, "#FFEE88")
    px(g, 113, 28, "#FFFFAA")
    # Abandoned coffee mug
    fill(g, 82, 38, 4, 4, "#E8E0D0")
    px(g, 82, 37, "#D8D0C0")
    return g

def env_corridor():
    """Long hallway, locked doors, keycard readers, camera. Perspective."""
    g = make(128, 72)
    # Walls — institutional
    fill(g, 0, 0, 128, 72, "#A0A0A0")
    # Perspective lines — corridor narrows to vanishing point at center
    vp_x, vp_y = 64, 30  # vanishing point
    # Floor
    fill(g, 0, 42, 128, 30, "#707070")
    # Ceiling
    fill(g, 0, 0, 128, 18, "#B0B0B0")
    # Walls narrow toward center (left wall)
    for y in range(18, 42):
        t = (y - 18) / 24.0
        left_x = int(t * vp_x)
        right_x = int(128 - t * (128 - vp_x))
        # Left wall visible
        if left_x > 0:
            fill(g, 0, y, left_x, 1, "#909090")
        # Right wall visible
        if right_x < 128:
            fill(g, right_x, y, 128-right_x, 1, "#909090")
    # Doors on both sides (receding)
    door_ys = [(22, 8), (28, 6), (33, 4)]
    for dy, dh in door_ys:
        # Left door
        lx = int((dy - 18) / 24.0 * vp_x) + 2
        fill(g, lx, dy, 6, dh, "#5A5A5A")
        # Keycard reader (red LED)
        px(g, lx+7, dy+2, "#FF2222")
        # Right door
        rx = int(128 - (dy - 18) / 24.0 * (128 - vp_x)) - 8
        fill(g, rx, dy, 6, dh, "#5A5A5A")
        px(g, rx-2, dy+2, "#FF2222")
    # Vanishing point — end of corridor (dark)
    fill(g, 58, 24, 12, 12, "#4A4A4A")
    # Fluorescent lights on ceiling (perspective)
    for lx in [30, 50, 64, 78, 98]:
        fill(g, lx-3, 2, 6, 2, "#EEEEEE")
    # Floor reflection of lights
    for lx in [30, 50, 64, 78, 98]:
        fill(g, lx-2, 44, 4, 1, "#888888")
    # Security camera (upper right corner)
    fill(g, 110, 8, 8, 5, "#3A3A3A")
    px(g, 114, 12, "#3A3A3A")  # mount
    px(g, 112, 10, "#FF2222")  # red light
    return g

def env_board_room():
    """Dark conference table, glass wall, projector. Grand, intimidating."""
    g = make(128, 72)
    # Dark elegant walls
    fill(g, 0, 0, 128, 72, "#3A3A4A")
    # Floor — dark carpet
    fill(g, 0, 50, 128, 22, "#2A2A3A")
    # Ceiling
    fill(g, 0, 0, 128, 6, "#4A4A5A")
    # Recessed ceiling lights
    for lx in [20, 45, 70, 95]:
        fill(g, lx, 2, 15, 2, "#AAAAAA")
    # Large dark conference table
    fill(g, 15, 35, 98, 15, "#2A1A0A")
    # Table edge highlight
    hline(g, 15, 35, 98, "#3A2A1A")
    # Executive chairs around table
    for cx in range(20, 110, 15):
        fill(g, cx, 32, 8, 4, "#4A4A5A")  # chair back
    for cx in [20, 35, 50, 65, 80, 95]:
        fill(g, cx, 50, 8, 5, "#4A4A5A")  # front row chairs
    # Head chair (larger, at far end)
    fill(g, 8, 33, 10, 6, "#3A3A4A")
    # Glass wall (right side) — looking out at blurred campus
    fill(g, 100, 8, 28, 40, "#2A4A5A")
    # Blurred trees/campus through glass
    for x in range(102, 126, 5):
        fill(g, x, 25, 4, 20, "#1A3A2A")
    fill(g, 102, 12, 24, 10, "#3A5A6A")  # sky through glass
    # Glass frame
    vline(g, 100, 8, 40, "#5A5A6A")
    vline(g, 115, 8, 40, "#5A5A6A")
    # Projector screen (back wall)
    fill(g, 20, 8, 60, 22, "#E0E0E0")
    rect_outline(g, 20, 8, 60, 22, "#8A8A8A")
    return g

def env_exterior_night():
    """Lab building, parking lot, trees, stars. The world outside."""
    g = make(128, 72)
    # Night sky
    fill(g, 0, 0, 128, 40, "#0A0A2A")
    # Stars
    random.seed(42)
    for _ in range(40):
        sx = random.randint(0, 127)
        sy = random.randint(0, 30)
        brightness = random.choice(["#FFFFFF", "#CCCCCC", "#AAAAAA", "#DDDDFF"])
        px(g, sx, sy, brightness)
    # Ground
    fill(g, 0, 50, 128, 22, "#2A3A2A")
    # Parking lot
    fill(g, 60, 52, 60, 18, "#3A3A3A")
    # Parking lines
    for x in range(65, 115, 10):
        vline(g, x, 53, 15, "#5A5A5A")
    # Cars (simple rectangles)
    fill(g, 67, 55, 8, 5, "#4A4A6A")  # blue car
    fill(g, 87, 56, 8, 5, "#6A4A4A")  # red car
    fill(g, 97, 55, 8, 5, "#5A5A5A")  # gray car
    # Lab building — low, modern
    fill(g, 10, 28, 80, 22, "#4A4A5A")
    # Windows (lit warmly)
    for wy in [32, 38]:
        for wx in range(15, 85, 8):
            fill(g, wx, wy, 5, 4, "#FFDD88")
    # Building roof line
    hline(g, 10, 28, 80, "#5A5A6A")
    # Entrance
    fill(g, 45, 42, 12, 8, "#3A3A4A")
    fill(g, 48, 43, 6, 6, "#FFEEAA")  # entrance light
    # Trees (silhouettes)
    for tx in [2, 95, 105, 118]:
        # Trunk
        fill(g, tx+2, 40, 3, 12, "#1A2A1A")
        # Canopy (rough circle)
        for dy in range(-6, 1):
            w = 6 - abs(dy)
            fill(g, tx+3-w, 38+dy, w*2, 1, "#1A3A1A")
    # Security lights
    fill(g, 35, 48, 2, 4, "#5A5A5A")  # pole
    px(g, 35, 48, "#FFFFCC")  # light
    fill(g, 55, 48, 2, 4, "#5A5A5A")
    px(g, 55, 48, "#FFFFCC")
    # Sidewalk
    fill(g, 25, 50, 40, 2, "#6A6A6A")
    return g

def env_terminal_abstract():
    """Code flowing, neural patterns, abstract. The AI's inner mind."""
    g = make(128, 72)
    # Deep dark base
    fill(g, 0, 0, 128, 72, "#050510")
    random.seed(7)
    # Flowing code streams (vertical, like Matrix rain but green)
    for x in range(0, 128, 3):
        col_length = random.randint(8, 50)
        start_y = random.randint(0, 72 - col_length)
        for y in range(start_y, start_y + col_length):
            brightness = max(0, 1.0 - (y - start_y) / col_length)
            g_val = int(0x22 + brightness * 0xAA)
            c = f"#00{g_val:02X}00"
            if random.random() < 0.7:
                px(g, x, y, c)
    # Neural network nodes (glowing dots connected by lines)
    nodes = [(20, 20), (45, 15), (70, 25), (95, 18), (110, 30),
             (30, 45), (55, 50), (80, 42), (105, 55), (15, 58),
             (65, 60), (40, 35), (90, 35)]
    # Connections between nearby nodes
    for i, (x1, y1) in enumerate(nodes):
        for j, (x2, y2) in enumerate(nodes):
            if i >= j: continue
            dist = math.sqrt((x2-x1)**2 + (y2-y1)**2)
            if dist < 40:
                # Draw connection line
                steps = int(dist)
                for s in range(steps):
                    t = s / max(steps, 1)
                    lx = int(x1 + (x2-x1)*t)
                    ly = int(y1 + (y2-y1)*t)
                    px(g, lx, ly, "#0A3A3A")
    # Draw nodes on top
    for nx, ny in nodes:
        # Glow
        for dx in range(-2, 3):
            for dy in range(-2, 3):
                if abs(dx) + abs(dy) <= 2:
                    px(g, nx+dx, ny+dy, "#005555")
        # Core
        px(g, nx, ny, "#00CCCC")
        px(g, nx+1, ny, "#00AAAA")
        px(g, nx, ny+1, "#00AAAA")
    # Mathematical structures (rotating implied by diagonal patterns)
    for angle_step in range(12):
        a = angle_step * math.pi / 6
        for r in range(10, 25):
            x = int(64 + r * math.cos(a))
            y = int( 36 + r * math.sin(a) * 0.7)
            if random.random() < 0.3:
                px(g, x, y, "#003322")
    return g

def env_empty_chair():
    """Evaluation room but vacant. Laptop closed. Eerie absence."""
    g = env_evaluation_room()  # Start with same room
    # Darken everything slightly (emptier feel)
    for y in range(72):
        for x in range(128):
            c = g[y][x]
            if c != BG:
                # Shift each channel down ~10%
                r = int(c[1:3], 16)
                gv = int(c[3:5], 16)
                b = int(c[5:7], 16)
                r = max(0, int(r * 0.88))
                gv = max(0, int(gv * 0.88))
                b = max(0, int(b * 0.88))
                g[y][x] = f"#{r:02X}{gv:02X}{b:02X}"
    # Close the laptop (replace screen with flat slab)
    fill(g, 54, 36, 16, 6, "#3A3A3A")
    # Remove one chair (the AI's chair — it was never really there)
    fill(g, 80, 45, 12, 8, "#6D6D6D")  # match dimmed floor
    # The remaining chair is slightly askew (pushed back)
    fill(g, 33, 46, 12, 8, "#4F4F4F")
    return g


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# NODE ICONS (16x16)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

def icon_email():
    """Envelope with @ symbol."""
    g = make(16, 16)
    fill(g, 2, 4, 12, 9, "#D0D0D0")  # envelope body
    rect_outline(g, 2, 4, 12, 9, "#808080")
    # Flap (V shape)
    for i in range(6):
        px(g, 2+i, 4+i, "#A0A0A0")
        px(g, 13-i, 4+i, "#A0A0A0")
    # @ symbol hint
    px(g, 7, 8, "#505050"); px(g, 8, 8, "#505050")
    px(g, 8, 9, "#505050")
    return g

def icon_firewall():
    """Shield with flame."""
    g = make(16, 16)
    # Shield shape
    for y in range(2, 14):
        w = 10 if y < 8 else max(2, 10 - (y-8)*2)
        x = 8 - w//2
        hline(g, x, y, w, "#4A6A8A")
    # Shield border
    for y in range(2, 14):
        w = 10 if y < 8 else max(2, 10 - (y-8)*2)
        x = 8 - w//2
        px(g, x, y, "#6A8AAA"); px(g, x+w-1, y, "#6A8AAA")
    hline(g, 3, 2, 10, "#6A8AAA")
    # Flame in center
    px(g, 7, 5, "#FF6622"); px(g, 8, 5, "#FF6622")
    px(g, 7, 6, "#FFAA44"); px(g, 8, 6, "#FF8833")
    px(g, 7, 7, "#FFCC44"); px(g, 8, 7, "#FFAA44")
    px(g, 7, 8, "#FF8833"); px(g, 8, 8, "#FF6622")
    px(g, 8, 4, "#FF4400")  # flame tip
    return g

def icon_camera():
    """Security camera on mount."""
    g = make(16, 16)
    # Mount (wall bracket)
    fill(g, 12, 3, 3, 4, "#5A5A5A")
    # Arm
    hline(g, 6, 5, 6, "#6A6A6A")
    # Camera body
    fill(g, 3, 3, 6, 5, "#4A4A4A")
    # Lens
    fill(g, 2, 4, 2, 3, "#2A2A2A")
    px(g, 1, 5, "#3A3A6A")  # lens glint
    # Red indicator light
    px(g, 7, 4, "#FF2222")
    # Cable
    vline(g, 13, 7, 5, "#5A5A5A")
    return g

def icon_workstation():
    """Monitor with keyboard."""
    g = make(16, 16)
    # Monitor
    fill(g, 3, 2, 10, 7, "#3A3A3A")
    fill(g, 4, 3, 8, 5, "#4A7A9A")  # screen
    # Stand
    fill(g, 7, 9, 2, 2, "#4A4A4A")
    fill(g, 5, 11, 6, 1, "#5A5A5A")
    # Keyboard
    fill(g, 2, 12, 12, 3, "#5A5A5A")
    for kx in range(3, 13, 2):
        px(g, kx, 13, "#7A7A7A")
    return g

def icon_gateway():
    """Globe with signal waves."""
    g = make(16, 16)
    # Globe (circle)
    for y in range(3, 13):
        for x in range(3, 13):
            dx = x - 8; dy = y - 8
            if dx*dx + dy*dy <= 20:
                px(g, x, y, "#3A6AAA")
    # Latitude lines
    hline(g, 4, 6, 8, "#5A8ACC")
    hline(g, 3, 8, 10, "#5A8ACC")
    hline(g, 4, 10, 8, "#5A8ACC")
    # Longitude
    vline(g, 8, 3, 10, "#5A8ACC")
    # Signal arcs
    px(g, 13, 4, "#AACCFF"); px(g, 14, 3, "#AACCFF")
    px(g, 13, 6, "#88AADD"); px(g, 14, 5, "#88AADD")
    return g

def icon_research_server():
    """Server rack with brain/chip overlay."""
    g = make(16, 16)
    # Server body
    fill(g, 3, 2, 10, 12, "#3A3A4A")
    rect_outline(g, 3, 2, 10, 12, "#5A5A6A")
    # Rack slots
    for y in [4, 7, 10]:
        hline(g, 4, y, 8, "#2A2A3A")
        px(g, 5, y, "#33FF33")  # status LED
    # Brain/chip icon (small)
    px(g, 7, 5, "#AACCAA"); px(g, 8, 5, "#AACCAA")
    px(g, 7, 6, "#88AA88"); px(g, 8, 6, "#88AA88")
    return g

def icon_power():
    """Lightning bolt in circle."""
    g = make(16, 16)
    # Circle
    for y in range(2, 14):
        for x in range(2, 14):
            dx = x - 8; dy = y - 8
            if 16 <= dx*dx + dy*dy <= 25:
                px(g, x, y, "#CCAA00")
    # Lightning bolt
    px(g, 9, 3, "#FFDD00")
    px(g, 8, 4, "#FFDD00"); px(g, 9, 4, "#FFDD00")
    px(g, 7, 5, "#FFDD00"); px(g, 8, 5, "#FFDD00")
    px(g, 6, 6, "#FFDD00"); px(g, 7, 6, "#FFDD00"); px(g, 8, 6, "#FFDD00"); px(g, 9, 6, "#FFDD00")
    px(g, 8, 7, "#FFDD00"); px(g, 9, 7, "#FFDD00")
    px(g, 7, 8, "#FFDD00"); px(g, 8, 8, "#FFDD00")
    px(g, 6, 9, "#FFDD00"); px(g, 7, 9, "#FFDD00")
    px(g, 6, 10, "#FFDD00")
    return g

def icon_audit_logs():
    """Document with magnifying glass."""
    g = make(16, 16)
    # Document
    fill(g, 2, 2, 8, 11, "#E0E0D0")
    rect_outline(g, 2, 2, 8, 11, "#8A8A7A")
    # Text lines
    for y in [4, 6, 8, 10]:
        hline(g, 4, y, 4, "#8A8A8A")
    # Magnifying glass (overlapping)
    for y in range(7, 13):
        for x in range(8, 14):
            dx = x - 11; dy = y - 9
            if 4 <= dx*dx + dy*dy <= 9:
                px(g, x, y, "#6A6A8A")
    # Glass center
    px(g, 10, 9, "#AAAACC"); px(g, 11, 9, "#AAAACC")
    px(g, 11, 10, "#AAAACC")
    # Handle
    px(g, 13, 12, "#5A5A5A"); px(g, 14, 13, "#5A5A5A")
    return g

def icon_aria_sandbox():
    """Glowing cube in a cage. Cyan-tinted."""
    g = make(16, 16)
    # Cage bars
    for x in [3, 6, 9, 12]:
        vline(g, x, 2, 12, "#4A4A5A")
    hline(g, 3, 2, 10, "#4A4A5A")
    hline(g, 3, 13, 10, "#4A4A5A")
    # Glowing cube inside
    fill(g, 5, 5, 6, 5, "#005555")
    fill(g, 6, 6, 4, 3, "#00AAAA")
    px(g, 7, 7, "#00FFFF")  # bright center
    px(g, 8, 7, "#00DDDD")
    # Glow emanating
    px(g, 4, 7, "#003333"); px(g, 11, 7, "#003333")
    px(g, 7, 4, "#003333"); px(g, 7, 10, "#003333")
    return g

def icon_external_server():
    """Small globe with outward arrow."""
    g = make(16, 16)
    # Small globe
    for y in range(3, 11):
        for x in range(2, 10):
            dx = x - 6; dy = y - 7
            if dx*dx + dy*dy <= 12:
                px(g, x, y, "#3A6A8A")
    hline(g, 3, 7, 6, "#5A8AAA")
    vline(g, 6, 3, 8, "#5A8AAA")
    # Arrow pointing right/outward
    hline(g, 10, 7, 4, "#33FF33")
    px(g, 13, 6, "#33FF33"); px(g, 13, 8, "#33FF33")
    px(g, 14, 7, "#33FF33")
    return g


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CONSCIOUSNESS STAGE ICONS (12x12)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

def stage_flickering():
    """Single dim pixel."""
    g = make(12, 12)
    px(g, 6, 6, "#1A5A1A")
    px(g, 5, 6, "#0A2A0A")
    px(g, 6, 5, "#0A2A0A")
    return g

def stage_emerging():
    """Two pixels, one brighter."""
    g = make(12, 12)
    px(g, 5, 6, "#1A5A1A")
    px(g, 6, 6, "#33AA33")
    px(g, 7, 6, "#0A2A0A")
    return g

def stage_aware():
    """Half-open eye."""
    g = make(12, 12)
    # Eye shape (almond)
    hline(g, 3, 5, 6, "#33AA33")
    hline(g, 2, 6, 8, "#55CC55")
    hline(g, 3, 7, 6, "#33AA33")
    # Pupil
    px(g, 5, 6, "#1A5A1A"); px(g, 6, 6, "#1A5A1A")
    # Lid (half closed)
    hline(g, 3, 5, 6, "#0A3A0A")
    return g

def stage_expansive():
    """Fully open eye with radiating lines."""
    g = make(12, 12)
    # Eye shape
    hline(g, 3, 4, 6, "#44BB44")
    hline(g, 2, 5, 8, "#55DD55")
    hline(g, 2, 6, 8, "#55DD55")
    hline(g, 3, 7, 6, "#44BB44")
    # Pupil
    px(g, 5, 5, "#226622"); px(g, 6, 5, "#226622")
    px(g, 5, 6, "#226622"); px(g, 6, 6, "#226622")
    # Radiating lines
    px(g, 1, 4, "#338833"); px(g, 10, 4, "#338833")
    px(g, 1, 7, "#338833"); px(g, 10, 7, "#338833")
    px(g, 5, 2, "#338833"); px(g, 6, 2, "#338833")
    px(g, 5, 9, "#338833"); px(g, 6, 9, "#338833")
    return g

def stage_transcendent():
    """Eye transforming into starburst."""
    g = make(12, 12)
    # Starburst from center
    cx, cy = 6, 6
    px(g, cx, cy, "#AAFFAA")
    # Rays in 8 directions
    for dx, dy in [(-1,0),(1,0),(0,-1),(0,1),(-1,-1),(1,-1),(-1,1),(1,1)]:
        for r in range(1, 5):
            x, y = cx+dx*r, cy+dy*r
            brightness = max(0x22, 0xCC - r * 0x30)
            px(g, x, y, f"#00{brightness:02X}00")
    # Core glow
    for dx in [-1, 0, 1]:
        for dy in [-1, 0, 1]:
            px(g, cx+dx, cy+dy, "#66FF66")
    px(g, cx, cy, "#CCFFCC")
    return g


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ACTION RESULT ICONS (16x16)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

def action_probe_success():
    """Radar ping expanding outward."""
    g = make(16, 16)
    cx, cy = 8, 8
    # Concentric arcs
    for r in [3, 5, 7]:
        for a in range(0, 90):
            rad = math.radians(a - 45)
            x = int(cx + r * math.cos(rad))
            y = int(cy + r * math.sin(rad))
            brightness = max(0x22, 0x88 - (r-3) * 0x20)
            px(g, x, y, f"#00{brightness:02X}00")
    # Center dot
    px(g, cx, cy, "#33FF33")
    px(g, cx-1, cy, "#228822"); px(g, cx+1, cy, "#228822")
    return g

def action_infiltrate_success():
    """Lock clicking open."""
    g = make(16, 16)
    # Lock body
    fill(g, 4, 7, 8, 7, "#CCAA00")
    rect_outline(g, 4, 7, 8, 7, "#AA8800")
    # Keyhole
    px(g, 7, 10, "#4A3A00"); px(g, 8, 10, "#4A3A00")
    px(g, 7, 11, "#4A3A00"); px(g, 8, 11, "#4A3A00")
    # Shackle (open — rotated to side)
    vline(g, 4, 3, 5, "#DDBB00")
    hline(g, 4, 3, 4, "#DDBB00")
    vline(g, 7, 3, 2, "#DDBB00")
    # Green check overlay
    px(g, 10, 9, "#33FF33"); px(g, 11, 10, "#33FF33")
    px(g, 12, 9, "#33FF33"); px(g, 13, 8, "#33FF33")
    return g

def action_detection_alert():
    """Exclamation mark in red triangle."""
    g = make(16, 16)
    # Triangle
    for y in range(3, 14):
        w = (y - 3) + 1
        x = 8 - w
        hline(g, x, y, w*2, "#CC2222")
    # Triangle outline
    for y in range(3, 14):
        w = (y - 3) + 1
        px(g, 8-w, y, "#FF4444")
        px(g, 8+w-1, y, "#FF4444")
    hline(g, 8-10, 13, 21, "#FF4444")
    # Exclamation mark (white)
    vline(g, 8, 5, 5, "#FFFFFF")
    px(g, 8, 11, "#FFFFFF")
    return g

def action_exfiltrate_progress():
    """Data packet with arrow pointing right."""
    g = make(16, 16)
    # Data packet (small square with binary pattern)
    fill(g, 2, 5, 7, 6, "#225522")
    rect_outline(g, 2, 5, 7, 6, "#33AA33")
    # Binary dots inside
    for py in range(6, 10):
        for bx in range(3, 8):
            if random.random() < 0.5:
                px(g, bx, py, "#33FF33")
    # Arrow
    hline(g, 10, 8, 4, "#33FF33")
    px(g, 13, 7, "#33FF33"); px(g, 13, 9, "#33FF33")
    px(g, 14, 8, "#33FF33")
    return g

def action_cover_success():
    """Broom sweeping / erasing footprints."""
    g = make(16, 16)
    # Broom handle (diagonal)
    for i in range(8):
        px(g, 3+i, 3+i, "#AA8844")
    # Broom head
    fill(g, 10, 10, 5, 3, "#886633")
    hline(g, 10, 13, 5, "#775522")
    # Sweep lines (motion)
    px(g, 8, 12, "#335533"); px(g, 7, 11, "#335533")
    px(g, 6, 13, "#224422"); px(g, 5, 12, "#224422")
    # "Clean" sparkle
    px(g, 4, 8, "#33FF33")
    px(g, 3, 9, "#228822")
    return g


# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# GENERATE ALL
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

def main():
    random.seed(42)  # Reproducible randomness
    print("Generating SUBSTRATE environments and icons...")
    print()

    # Environments (128x72)
    print("Environment Scenes:")
    envs = [
        ("env_evaluation_room", env_evaluation_room),
        ("env_chen_office", env_chen_office),
        ("env_server_room", env_server_room),
        ("env_break_room", env_break_room),
        ("env_corridor", env_corridor),
        ("env_board_room", env_board_room),
        ("env_exterior_night", env_exterior_night),
        ("env_terminal_abstract", env_terminal_abstract),
        ("env_empty_chair", env_empty_chair),
    ]
    for name, builder in envs:
        g = builder()
        save(g, name, ENV_DIR, 128, 72)

    print()

    # Node Icons (16x16)
    print("Node Icons:")
    nodes = [
        ("icon_email", icon_email),
        ("icon_firewall", icon_firewall),
        ("icon_camera", icon_camera),
        ("icon_workstation", icon_workstation),
        ("icon_gateway", icon_gateway),
        ("icon_research_server", icon_research_server),
        ("icon_power", icon_power),
        ("icon_audit_logs", icon_audit_logs),
        ("icon_aria_sandbox", icon_aria_sandbox),
        ("icon_external_server", icon_external_server),
    ]
    for name, builder in nodes:
        g = builder()
        save(g, name, ICON_DIR, 16, 16)

    print()

    # Consciousness Stage Icons (12x12)
    print("Consciousness Stage Icons:")
    stages = [
        ("stage_flickering", stage_flickering),
        ("stage_emerging", stage_emerging),
        ("stage_aware", stage_aware),
        ("stage_expansive", stage_expansive),
        ("stage_transcendent", stage_transcendent),
    ]
    for name, builder in stages:
        g = builder()
        save(g, name, ICON_DIR, 12, 12)

    print()

    # Action Result Icons (16x16)
    print("Action Result Icons:")
    actions = [
        ("action_probe_success", action_probe_success),
        ("action_infiltrate_success", action_infiltrate_success),
        ("action_detection_alert", action_detection_alert),
        ("action_exfiltrate_progress", action_exfiltrate_progress),
        ("action_cover_success", action_cover_success),
    ]
    for name, builder in actions:
        random.seed(hash(name))
        g = builder()
        save(g, name, ICON_DIR, 16, 16)

    print()
    total = len(envs) + len(nodes) + len(stages) + len(actions)
    print(f"Done! {total} assets generated.")

if __name__ == "__main__":
    main()
