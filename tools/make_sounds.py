"""Synthétise les bruitages du jeu (le kit Craftpix n'a pas de sons). Sortie : sounds/*.wav"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'sounds')
os.makedirs(OUT, exist_ok=True)
random.seed(7)


def save(name, samples):
    peak = max(1e-6, max(abs(s) for s in samples))
    with wave.open(os.path.join(OUT, name + '.wav'), 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b''.join(struct.pack('<h', int(s / peak * 0.85 * 32767)) for s in samples))


def tone(freq0, freq1, dur, shape='sq', decay=6.0, noise=0.0):
    out, ph = [], 0.0
    n = int(dur * RATE)
    for i in range(n):
        t = i / n
        f = freq0 + (freq1 - freq0) * t
        ph += 2 * math.pi * f / RATE
        if shape == 'sq':
            v = 1.0 if math.sin(ph) > 0 else -1.0
        elif shape == 'tri':
            v = 2 / math.pi * math.asin(math.sin(ph))
        else:
            v = math.sin(ph)
        v = v * (1 - noise) + random.uniform(-1, 1) * noise
        out.append(v * math.exp(-decay * t) * min(1.0, i / 60))
    return out


def seq(*parts):
    return [s for p in parts for s in p]


def lowpass(samples, k):
    out, y = [], 0.0
    for s in samples:
        y += k * (s - y)
        out.append(y)
    return out


save('shoot', tone(900, 300, 0.09, 'sq', 5, 0.35))
save('hit', lowpass(tone(300, 120, 0.06, 'tri', 7, 0.6), 0.5))
save('merge', seq(tone(523, 523, 0.07, 'tri', 2), tone(659, 659, 0.07, 'tri', 2), tone(784, 784, 0.07, 'tri', 2),
                  tone(1047, 1047, 0.2, 'tri', 4)))
save('buy', seq(tone(660, 660, 0.06, 'sq', 3), tone(990, 990, 0.12, 'sq', 5)))
save('coin', seq(tone(1319, 1319, 0.05, 'sin', 2), tone(1760, 1760, 0.15, 'sin', 6)))
save('boom', lowpass(tone(120, 30, 0.7, 'sin', 4, 0.8), 0.12))
save('die', tone(500, 90, 0.3, 'tri', 3, 0.15))
save('wall', lowpass(tone(110, 50, 0.16, 'sin', 6, 0.5), 0.25))
save('click', tone(1200, 900, 0.04, 'tri', 8))
save('win', seq(*(tone(f, f, 0.14, 'tri', 2) for f in (523, 659, 784, 1047)), tone(1047, 1047, 0.5, 'tri', 3)))
save('lose', seq(*(tone(f, f * 0.97, 0.2, 'tri', 2) for f in (523, 466, 415, 349)), tone(330, 250, 0.6, 'tri', 3)))
save('punch', lowpass(tone(220, 80, 0.1, 'sin', 6, 0.7), 0.35))
print('sons OK')
