"""Convertit le kit Craftpix (PNG image par image) en planches WebP légères + atlas JSON.

Usage : python3 tools/build_assets.py <dossier Png du kit>
Sortie : assets/ (sprites, ui, bg) et assets/atlas.json
"""
import json
import math
import os
import sys

from PIL import Image

SRC = sys.argv[1]
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'assets')
for sub in ('sprites', 'ui', 'bg'):
    os.makedirs(os.path.join(OUT, sub), exist_ok=True)

atlas = {}


def frames_of(folder, step):
    files = sorted(f for f in os.listdir(folder) if f.endswith('.png'))
    return [os.path.join(folder, f) for f in files[::step]]


def sheet(name, folder, scale, step=1, quality=82):
    """Rogne toutes les images sur leur boîte commune, les réduit et les range en grille.
    L'ancre est le centre bas (pieds) : ox/oy sont les décalages depuis cette ancre."""
    paths = frames_of(os.path.join(SRC, folder), step)
    imgs = [Image.open(p).convert('RGBA') for p in paths]
    bb = None
    for im in imgs:
        b = im.getbbox() or (0, 0, 1, 1)
        bb = b if bb is None else (min(bb[0], b[0]), min(bb[1], b[1]), max(bb[2], b[2]), max(bb[3], b[3]))
    W = imgs[0].width
    fw = max(1, round((bb[2] - bb[0]) * scale))
    fh = max(1, round((bb[3] - bb[1]) * scale))
    cols = math.ceil(math.sqrt(len(imgs)))
    rows = math.ceil(len(imgs) / cols)
    out = Image.new('RGBA', (cols * fw, rows * fh))
    for i, im in enumerate(imgs):
        fr = im.crop(bb).resize((fw, fh), Image.LANCZOS)
        out.paste(fr, ((i % cols) * fw, (i // cols) * fh))
    out.save(os.path.join(OUT, 'sprites', name + '.webp'), 'WEBP', quality=quality, method=6)
    atlas[name] = {
        'src': f'res://assets/sprites/{name}.webp', 'fw': fw, 'fh': fh, 'cols': cols, 'n': len(imgs),
        'ox': round((bb[0] - W / 2) * scale), 'oy': -fh,
    }


def image(name, rel, dest, max_w=None, quality=85):
    im = Image.open(os.path.join(SRC, rel)).convert('RGBA')
    if max_w and im.width > max_w:
        im = im.resize((max_w, round(im.height * max_w / im.width)), Image.LANCZOS)
    path = f'assets/{dest}/{name}.webp'
    im.save(os.path.join(ROOT, path), 'WEBP', quality=quality, method=6)
    atlas[name] = {'src': 'res://' + path, 'w': im.width, 'h': im.height}


# Chats jouables : niveau 1 à 15
for i in range(1, 16):
    sheet(f'cat{i}_idle', f'Characters/C{i}/Idle', 0.95, step=2)
    sheet(f'cat{i}_shoot', f'Characters/C{i}/Shoot', 0.95)

# Ennemis : 8 réguliers, 7 boss
for kind, count, scale in (('Reg', 8, 1.1), ('Boss', 7, 1.2)):
    for i in range(1, count + 1):
        key = f'{kind.lower()}{i}'
        base = f'Enemies/Enemy {kind} {i}'
        sheet(f'{key}_walk', base + '/Walk', scale, step=3)
        sheet(f'{key}_attack', base + '/Attack', scale, step=2)
        sheet(f'{key}_dead', base + '/Dead', scale, step=4)

# Renforts (add-ons)
sheet('guardian_idle', 'Cat Guardian/Idle', 1.0, step=2)
sheet('guardian_attack', 'Cat Guardian/Attack', 1.0, step=2)
sheet('boxing_idle', 'CatBoxing/Idle', 1.1, step=2)
sheet('boxing_attack', 'CatBoxing/Attack', 1.1, step=2)

# Effets
sheet('explosion', 'Explosion', 0.55, quality=78)
sheet('shootfx', 'ShootFx', 0.45)
for i, f in enumerate(('Artboard 1.png', 'Artboard 1 copy.png', 'Artboard 1 copy 2.png')):
    image(f'bullet{i + 1}', f'Bullets/{f}', 'sprites')

# Décors
for i in range(1, 6):
    image(f'area{i}', f'Area/Area{i}.png', 'bg', quality=80)
image('landing', 'Ui/LandingScreen.png', 'bg', max_w=1920, quality=78)


# Interface
UI = ['Logo', 'CoinBar', 'CoinIcon', 'WaveBar', 'SettingBtn', 'BtnGreen', 'BtnGreenPressed', 'BtnOrange',
      'BtnOrangePressed', 'BtnShopDisable', 'WinPopUp', 'LosePopUp', 'BgPaused', 'BtnMusic', 'BtnMusicOff',
      'BtnSound', 'BtnSound Off', 'Icon_home', 'Icon_Cat', 'WallIcon', 'YellowBox', 'AddonBoxGrey',
      'AddonBoxNumber', 'AddonIcon5', 'AddonIcon6', 'AddonIcon7', 'AddonIcon8', 'OrangeLvl', 'GreenLevel',
      'LockedLevel', 'TitleRibbon', 'SelectedBorder', 'GemsIcon', 'Up0', 'BtnHelp']
for n in UI:
    image(n.replace(' ', ''), f'Ui/{n}.png', 'ui', max_w=1100)
for i in range(1, 16):
    image(f'uplogo{i}', f'Ui/Uplogo{i}.png', 'ui')

with open(os.path.join(OUT, 'atlas.json'), 'w') as f:
    json.dump(atlas, f, separators=(',', ':'))
print(len(atlas), 'entrées')
