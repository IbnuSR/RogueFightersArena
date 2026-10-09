#!/usr/bin/env python3
"""Membuat semua SFX dan BGM RogueFightersArena secara prosedural.
Output: assets/audio/*.wav (16-bit mono 22050 Hz). Tanpa library eksternal."""
import math
import os
import random
import struct
import wave

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "audio")
os.makedirs(OUT, exist_ok=True)
random.seed(7)


def save(name, samples):
    peak = max(1e-6, max(abs(s) for s in samples))
    scale = 0.85 / peak
    frames = struct.pack("<%dh" % len(samples),
                         *[int(max(-1.0, min(1.0, s * scale)) * 32767) for s in samples])
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(frames)
    print("OK %-12s %.2fs" % (name, len(samples) / SR))


def sine(f, t):
    return math.sin(2 * math.pi * f * t)


def noise():
    return random.uniform(-1.0, 1.0)


def lowpass(samples, alpha):
    y = 0.0
    out = []
    for x in samples:
        y += alpha * (x - y)
        out.append(y)
    return out


def sweep(f0, f1, dur, wave_fn=sine, vol=1.0, decay=0.0):
    n = int(SR * dur)
    phase = 0.0
    out = []
    for i in range(n):
        t = i / SR
        f = f0 + (f1 - f0) * (t / dur)
        phase += 2 * math.pi * f / SR
        env = math.exp(-t * decay) if decay else 1.0
        attack = min(1.0, t / 0.005)
        out.append(vol * attack * env * (math.sin(phase) if wave_fn == sine else (1.0 if math.sin(phase) > 0 else -1.0)))
    return out


def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for t in tracks:
        for i, s in enumerate(t):
            out[i] += s
    return out


def place(base, at_sec, samples):
    n = int(SR * at_sec)
    need = n + len(samples)
    if len(base) < need:
        base.extend([0.0] * (need - len(base)))
    for i, s in enumerate(samples):
        base[i + n] += s
    return base


# ---------- SFX ----------
# swing: desingan pedang
n = int(SR * 0.18)
sw = lowpass([noise() * math.exp(-i / SR * 22) for i in range(n)], 0.25)
save("swing", sw)

# hit: bogem mentah
hit = mix(sweep(150, 55, 0.25, decay=16, vol=1.0),
          [noise() * 0.35 * math.exp(-i / SR * 70) for i in range(int(SR * 0.25))])
save("hit", hit)

# block: "ting" metalik
n = int(SR * 0.3)
block = [0.5 * sine(1568, i / SR) * math.exp(-i / SR * 14)
         + 0.3 * sine(2093, i / SR) * math.exp(-i / SR * 16)
         + 0.2 * sine(2794, i / SR) * math.exp(-i / SR * 20) for i in range(n)]
save("block", block)

# jump
save("jump", sweep(280, 760, 0.18, decay=6))

# ko: ledakan jatuh
ko = mix(sweep(170, 32, 0.9, decay=4, vol=1.0),
         lowpass([noise() * math.exp(-i / SR * 6) for i in range(int(SR * 0.9))], 0.12))
save("ko", ko)

# bell: bel ronde
n = int(SR * 1.4)
bell = [0.5 * sine(659, i / SR) * math.exp(-i / SR * 3.2)
        + 0.35 * sine(880, i / SR) * math.exp(-i / SR * 4.0)
        + 0.2 * sine(1318, i / SR) * math.exp(-i / SR * 5.0) for i in range(n)]
save("bell", bell)

# ui_click
save("ui_click", sweep(1250, 900, 0.07, decay=60))

# countdown: bunyi "bip"
sq = sweep(520, 520, 0.22, wave_fn="square", decay=8)
save("countdown", sq)

# round_win: fanfare kecil C-E-G-C
fanfare = []
for f in (523.25, 659.25, 783.99, 1046.5):
    tone = [ (sine(f, i / SR) + 0.3 * sine(3 * f, i / SR)) * math.exp(-i / SR * 9)
             for i in range(int(SR * 0.24)) ]
    fanfare = place(fanfare, len(fanfare) / SR, tone)
save("round_win", fanfare)

# ---------- BGM ----------
def note(freq, dur, vol=0.5, decay=3.0, bright=0.25):
    n = int(SR * dur)
    return [(sine(freq, i / SR) + bright * sine(2 * freq, i / SR)) * vol * math.exp(-i / SR * decay)
            for i in range(n)]

# bgm_menu: arpeggio santai Am - F - C - G, 90 BPM, loop 8 bar
bpm = 90.0
beat = 60.0 / bpm
eighth = beat / 2.0
chords = [
    ("Am", [110.0, 220.0, 261.63, 329.63]),   # A2 A3 C4 E4
    ("F",  [87.31, 174.61, 220.0, 261.63]),   # F2 F3 A3 C4
    ("C",  [130.81, 196.0, 261.63, 329.63]),  # C3 G3 C4 E4
    ("G",  [98.0, 196.0, 246.94, 293.66]),    # G2 G3 B3 D4
]
menu = []
for _name, tones in chords:
    for bar in range(2):
        for e in range(8):
            f = tones[[0, 1, 2, 3, 2, 1, 2, 3][e]]
            menu = place(menu, len(menu) / SR, note(f, eighth * 0.95, vol=0.32, decay=5.0))
        menu = place(menu, (len(menu) / SR) - 8 * eighth, note(tones[0] / 2, 8 * eighth, vol=0.30, decay=1.2))
save("bgm_menu", menu)

# bgm_battle: 140 BPM, 16 bar loop, drum + bass + riff E minor
bpm = 140.0
beat = 60.0 / bpm
battle = []
bars = 16
kick = sweep(110, 42, 0.14, decay=22, vol=1.0)
snare = [noise() * 0.6 * math.exp(-i / SR * 30) for i in range(int(SR * 0.12))]
hat = [noise() * 0.25 * math.exp(-i / SR * 90) for i in range(int(SR * 0.04))]
bassline = [82.41, 82.41, 98.0, 82.41, 110.0, 82.41, 98.0, 123.47]  # E E G E A E G B (8th)
riff = [164.81, 196.0, 246.94, 196.0]  # E3 G3 B3 G3 power-stab
for bar in range(bars):
    base = bar * 4 * beat
    for b in range(4):
        battle = place(battle, base + b * beat, kick)
        if b in (1, 3):
            battle = place(battle, base + b * beat, snare)
        for h in range(2):
            battle = place(battle, base + b * beat + h * beat / 2, hat)
    for e in range(8):
        battle = place(battle, base + e * beat / 2, note(bassline[e], beat * 0.45, vol=0.42, decay=8.0))
    if bar % 2 == 1:
        for s in range(4):
            f = riff[s]
            stab = [(1.0 if sine(f, i / SR) > 0 else -1.0) * 0.20 * math.exp(-i / SR * 18)
                    + (1.0 if sine(1.5 * f, i / SR) > 0 else -1.0) * 0.12 * math.exp(-i / SR * 18)
                    for i in range(int(SR * 0.22))]
            battle = place(battle, base + s * beat, stab)
save("bgm_battle", battle)

print("Selesai:", OUT)
