"""Convert the exercise GIFs to animated WebP and copy thumbnails into the Flutter asset tree.

GIF -> animated WebP is a ~3x size win (121MB -> ~43MB) with identical frame timing,
which keeps the app fully offline-capable without a 120MB install.
"""
import os, subprocess, sys, json
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_VID = os.path.join(ROOT, 'exercises-dataset', 'videos')
SRC_IMG = os.path.join(ROOT, 'exercises-dataset', 'images')
OUT_ANIM = os.path.join(ROOT, 'app', 'assets', 'anim')
OUT_THUMB = os.path.join(ROOT, 'app', 'assets', 'thumb')
QUALITY = '78'

os.makedirs(OUT_ANIM, exist_ok=True)
os.makedirs(OUT_THUMB, exist_ok=True)

data = json.load(open(os.path.join(ROOT, 'exercises-dataset', 'data', 'exercises.json'), encoding='utf-8'))
jobs = [(e['id'], os.path.basename(e['gif_url']), os.path.basename(e['image'])) for e in data]


def convert(job):
    ex_id, gif, jpg = job
    dst = os.path.join(OUT_ANIM, f'{ex_id}.webp')
    if not os.path.exists(dst):
        r = subprocess.run(
            ['ffmpeg', '-y', '-loglevel', 'error', '-i', os.path.join(SRC_VID, gif),
             '-vcodec', 'libwebp', '-lossless', '0', '-q:v', QUALITY, '-loop', '0',
             '-preset', 'picture', '-an', '-vsync', '0', dst],
            capture_output=True)
        if r.returncode != 0:
            return f'FAIL {ex_id}: {r.stderr.decode()[:200]}'
    thumb_dst = os.path.join(OUT_THUMB, f'{ex_id}.jpg')
    if not os.path.exists(thumb_dst):
        with open(os.path.join(SRC_IMG, jpg), 'rb') as f, open(thumb_dst, 'wb') as o:
            o.write(f.read())
    return None


with ThreadPoolExecutor(max_workers=8) as pool:
    errs = [e for e in pool.map(convert, jobs) if e]

for e in errs[:10]:
    print(e)
anim_bytes = sum(os.path.getsize(os.path.join(OUT_ANIM, f)) for f in os.listdir(OUT_ANIM))
thumb_bytes = sum(os.path.getsize(os.path.join(OUT_THUMB, f)) for f in os.listdir(OUT_THUMB))
print(f'anim: {len(os.listdir(OUT_ANIM))} files, {anim_bytes/1e6:.1f} MB')
print(f'thumb: {len(os.listdir(OUT_THUMB))} files, {thumb_bytes/1e6:.1f} MB')
print(f'errors: {len(errs)}')
