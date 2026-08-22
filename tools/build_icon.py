# -*- coding: utf-8 -*-
"""Generate the Android launcher icon from the same mark the app draws in Dart.

The mark is defined once, on a 48-unit grid, exactly as `LogoMark` draws it in
`lib/ui/widgets/logo.dart` -- a bar with a plate at each end. Keeping the two in
sync by construction means the splash screen and the launcher icon can never
drift apart.

Three artefacts come out of this, because Android needs all three to look right
across launchers:

  ic_launcher            legacy square, for pre-API-26 launchers
  ic_launcher_foreground adaptive foreground, masked to whatever shape the
                         launcher wants (Nothing OS included)
  ic_launcher_monochrome themed-icon layer for Android 13+, which Nothing OS
                         leans on heavily

Run: python tools/build_icon.py
"""
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, 'app', 'android', 'app', 'src', 'main', 'res')

# Near-black, the same value as FColors.primary. The icon is monochrome on
# purpose: the app itself is greyscale with colour reserved for meaning, and a
# black-and-white mark reads as deliberate next to a screen of colourful icons.
BG = (24, 24, 27, 255)
FG = (250, 250, 250, 255)

# Supersample everything, then downsample once. PIL has no antialiased drawing,
# and a 48px icon drawn directly would have visibly ragged plate corners.
SS = 8

# Density buckets: (folder, legacy icon px, adaptive canvas px).
# Adaptive canvases are 108dp; legacy are 48dp.
DENSITIES = [
    ('mipmap-mdpi', 48, 108),
    ('mipmap-hdpi', 72, 162),
    ('mipmap-xhdpi', 96, 216),
    ('mipmap-xxhdpi', 144, 324),
    ('mipmap-xxxhdpi', 192, 432),
]


def draw_mark(canvas_px, mark_px, colour):
    """Render the Forge mark, centred, on a transparent canvas.

    `mark_px` is the size of the 48-unit grid box; the ink inside it spans 36
    units wide and 22 tall, so the visible mark is smaller than the box.
    """
    size = canvas_px * SS
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    k = mark_px * SS / 48.0
    offset = (size - mark_px * SS) / 2.0

    def px(x, y):
        return (offset + x * k, offset + y * k)

    # Heavier than the in-app stroke (3/48). A launcher icon is looked at
    # around 40px on a busy home screen, where a hairline simply disappears.
    weight = 4.0 * k
    half = weight / 2.0

    # -- Bar, with round caps to match StrokeCap.round in the Dart painter ---
    x0, y0 = px(6, 24)
    x1, _ = px(42, 24)
    draw.rectangle([x0, y0 - half, x1, y0 + half], fill=colour)
    for cx in (x0, x1):
        draw.ellipse([cx - half, y0 - half, cx + half, y0 + half], fill=colour)

    # -- Plates -------------------------------------------------------------
    # Solid, unlike the outlined plates the app animates on the splash screen.
    # At 8 grid units wide the outline's inner hole is barely two pixels on a
    # home screen, which reads as mud rather than as a plate. A launcher icon
    # is a silhouette seen at a glance, so it gets the silhouette version.
    for left in (11, 29):
        a = px(left, 13)
        b = px(left + 8, 35)
        draw.rounded_rectangle([a[0], a[1], b[0], b[1]], radius=3 * k, fill=colour)

    return img.resize((canvas_px, canvas_px), Image.LANCZOS)


def legacy_icon(px):
    """Full-bleed rounded square, for launchers that do not mask."""
    size = px * SS
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(img).rounded_rectangle(
        [0, 0, size - 1, size - 1], radius=size * 0.22, fill=BG
    )
    img = img.resize((px, px), Image.LANCZOS)
    # Sized to match the adaptive icon's *visible* weight. The adaptive mark is
    # 0.56 of a 108dp canvas but launchers only show the central 72dp, so it
    # reads far larger than the same fraction of this un-cropped tile would.
    img.alpha_composite(draw_mark(px, int(px * 0.82), FG))
    return img


def adaptive_foreground(px, colour):
    """Adaptive layer on a 108dp canvas.

    Only the central 72dp is guaranteed visible and the safe area is a 66dp
    circle, so the mark is sized to sit inside that circle whatever shape the
    launcher masks to. At this scale the ink spans roughly 49dp corner to
    corner -- comfortably inside 66dp, with room for aggressive masks.
    """
    return draw_mark(px, int(px * 0.56), colour)


def main():
    for folder, legacy_px, adaptive_px in DENSITIES:
        out = os.path.join(RES, folder)
        os.makedirs(out, exist_ok=True)

        legacy_icon(legacy_px).save(os.path.join(out, 'ic_launcher.png'))
        adaptive_foreground(adaptive_px, FG).save(
            os.path.join(out, 'ic_launcher_foreground.png'))
        # The system tints the monochrome layer itself, so it ships as flat
        # white and relies on alpha alone.
        adaptive_foreground(adaptive_px, (255, 255, 255, 255)).save(
            os.path.join(out, 'ic_launcher_monochrome.png'))
        print('%-22s legacy %3dpx   adaptive %3dpx' % (folder, legacy_px, adaptive_px))

    # -- Adaptive descriptor -------------------------------------------------
    anydpi = os.path.join(RES, 'mipmap-anydpi-v26')
    os.makedirs(anydpi, exist_ok=True)
    with open(os.path.join(anydpi, 'ic_launcher.xml'), 'w', encoding='utf-8') as f:
        f.write('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
</adaptive-icon>
''')

    values = os.path.join(RES, 'values')
    os.makedirs(values, exist_ok=True)
    with open(os.path.join(values, 'ic_launcher_background.xml'), 'w',
              encoding='utf-8') as f:
        f.write('''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Matches FColors.primary, the app's primary action colour. -->
    <color name="ic_launcher_background">#18181B</color>
</resources>
''')

    print('\\nwrote mipmap-anydpi-v26/ic_launcher.xml and the background colour')


if __name__ == '__main__':
    main()
