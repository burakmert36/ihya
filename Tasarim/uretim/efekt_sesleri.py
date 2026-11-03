"""Kısa bildirim tonlarını ve arayüz efekt seslerini sentezler (telifsiz, bu betikle üretilir).

Çıktı: Resources/Effects/*.wav (16 bit, 44,1 kHz, mono). Bildirim tonları 30 saniyeden kısadır (iOS sınırı).
Kullanım: python3 Tasarim/uretim/efekt_sesleri.py
"""
from pathlib import Path

import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, sosfilt

SR = 44100
KOK = Path(__file__).resolve().parents[2]
HEDEF = KOK / "Resources" / "Effects"
HEDEF.mkdir(parents=True, exist_ok=True)
rng = np.random.default_rng(7)


def t(sure):
    return np.arange(int(SR * sure)) / SR


def zarf(n, atak=0.005, sonum=1.0, sure=None):
    x = np.arange(n) / SR
    a = np.clip(x / max(atak, 1e-4), 0, 1)
    return a * np.exp(-x / sonum)


def can(f, sure=4.0, sonum=1.6, oran=(1, 2.76, 5.4, 8.93), guc=(1, 0.5, 0.25, 0.12)):
    x = t(sure)
    s = sum(g * np.sin(2 * np.pi * f * o * x) * np.exp(-x / (sonum / (1 + i * 0.7))) for i, (o, g) in enumerate(zip(oran, guc)))
    return s * np.clip(x / 0.004, 0, 1)


def ton(f, sure, atak=0.01, sonum=0.6, harm=(1, 0.3, 0.12)):
    x = t(sure)
    s = sum(g * np.sin(2 * np.pi * f * (i + 1) * x) for i, g in enumerate(harm))
    return s * zarf(len(x), atak, sonum)


def yerlestir(parcalar, sure):
    out = np.zeros(int(SR * sure))
    for bas, sinyal in parcalar:
        i = int(SR * bas)
        n = min(len(sinyal), len(out) - i)
        out[i:i + n] += sinyal[:n]
    return out


def yankı(s, gecikme=0.11, geri=0.35, kez=5):
    out = s.copy()
    for k in range(1, kez + 1):
        d = int(SR * gecikme * k)
        if d < len(s):
            out[d:] += s[:-d] * (geri ** k)
    return out


def yaz(ad, s, tepe=0.7):
    s = s / (np.max(np.abs(s)) + 1e-9) * tepe
    n = int(SR * 0.01)
    s[-n:] *= np.linspace(1, 0, n)
    wavfile.write(HEDEF / f"{ad}.wav", SR, (s * 32767).astype(np.int16))


nota = lambda m: 440 * 2 ** ((m - 69) / 12)

# ——— Bildirim tonları ———
yaz("bildirim_can", yankı(yerlestir([(0, can(nota(72))), (1.1, can(nota(67), 3.5))], 5.0), 0.13, 0.3))
yaz("bildirim_kristal", yankı(yerlestir([(0, ton(nota(88), 2, 0.004, 0.7, (1, 0.2))), (0.18, ton(nota(95), 2, 0.004, 0.7, (1, 0.2))), (0.36, ton(nota(100), 2.4, 0.004, 0.9, (1, 0.2)))], 3.2), 0.09, 0.4))
dam = lambda: (lambda x: np.sin(2 * np.pi * (900 + 1400 * (1 - np.exp(-x / 0.02))) * x) * zarf(len(x), 0.001, 0.07))(t(0.35))
yaz("bildirim_damla", yankı(yerlestir([(0, dam()), (0.45, dam() * 0.8), (0.75, dam() * 0.6)], 1.8), 0.07, 0.35))
yaz("bildirim_sabah", yankı(yerlestir([(i * 0.32, ton(nota(m), 2.2, 0.02, 0.9)) for i, m in enumerate((60, 64, 67, 72))], 3.6), 0.15, 0.3))
x = t(6.0)
ped = sum(np.sin(2 * np.pi * nota(m) * x + 0.3 * np.sin(2 * np.pi * 0.2 * x)) for m in (57, 61, 64, 69)) * np.minimum(x / 1.8, 1) * np.exp(-np.maximum(x - 3.5, 0) / 0.9)
yaz("bildirim_huzur", ped, 0.6)
x = t(5.0)
motif = [(0, 62, 1.0), (1.0, 64, 0.9), (1.9, 65, 1.1), (3.0, 64, 0.8), (3.8, 62, 1.2)]
nefes = np.zeros_like(x)
for bas, m, sure in motif:
    i0, i1 = int(SR * bas), int(SR * min(5.0, bas + sure))
    xx = x[i0:i1] - bas
    vib = 0.004 * np.sin(2 * np.pi * 5.2 * xx) * np.minimum(xx / 0.4, 1)
    nefes[i0:i1] += (np.sin(2 * np.pi * nota(m) * xx * (1 + vib)) + 0.15 * np.sin(4 * np.pi * nota(m) * xx)) * np.minimum(xx / 0.12, 1) * np.minimum((sure - xx) / 0.15, 1)
gurultu = sosfilt(butter(2, [700, 2600], btype="band", fs=SR, output="sos"), rng.standard_normal(len(x))) * 0.08
yaz("bildirim_esinti", yankı(nefes + gurultu * (np.abs(nefes) > 0.05), 0.18, 0.25), 0.6)

# ——— Arayüz efektleri ———
x = t(0.05)
tik = sosfilt(butter(2, [1500, 4200], btype="band", fs=SR, output="sos"), rng.standard_normal(len(x))) * np.exp(-x / 0.006)
tik += 0.6 * np.sin(2 * np.pi * 2300 * x) * np.exp(-x / 0.01)
yaz("tesbih_tik", tik, 0.8)
yaz("efekt_isilti", yankı(yerlestir([(i * 0.06, can(nota(m), 0.6, 0.18, guc=(1, 0.3, 0.1, 0.05)) * 0.6) for i, m in enumerate((91, 96, 100, 103))], 0.9), 0.05, 0.3))
yaz("efekt_kutlama", yankı(yerlestir([(i * 0.11, ton(nota(m), 1.2, 0.005, 0.5)) for i, m in enumerate((72, 76, 79, 84, 88))] + [(0.55, can(nota(96), 1.0, 0.4) * 0.4)], 1.8), 0.1, 0.3))
yaz("efekt_kilit", yankı(yerlestir([(i * 0.09, ton(nota(m), 1.0, 0.004, 0.45)) for i, m in enumerate((67, 71, 74, 79, 83, 86))] + [(0.6, can(nota(91), 1.2, 0.5) * 0.5), (0.75, can(nota(98), 1.0, 0.4) * 0.35)], 2.0), 0.08, 0.3))
x = t(0.3)
yaz("efekt_baslat", np.sin(2 * np.pi * (300 + 500 * x / 0.3) * x) * zarf(len(x), 0.005, 0.08), 0.6)
x = t(0.8)
yaz("efekt_vazgec", np.sin(2 * np.pi * (520 - 260 * x / 0.8) * x) * zarf(len(x), 0.01, 0.3), 0.5)
print(sorted(p.name for p in HEDEF.glob("*.wav")))
