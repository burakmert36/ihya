# İhya · gerçek kayıtlardan dikişsiz döngüler (MP3, sarmalı pay ile)
# Dosya düzeni: [döngünün son P sn'si] + [döngü L sn] + [döngünün ilk P sn'si]
# Oynatıcı loopStart=P, loopEnd=P+L kullanır; çözücü başa sessizlik eklese bile
# (d < P) atlama noktası döngünün aynı fazına düşer → dikiş duyulmaz.
import subprocess, numpy as np, os, json, sys
SR = 44100
P = 0.5
HERE = os.path.dirname(os.path.abspath(__file__))
M = os.path.join(HERE, 'moodist/public/sounds/')
BL = os.path.join(HERE, 'blanket/repo/data/resources/sounds/')
OUT = os.path.join(HERE, 'mp3')
os.makedirs(OUT, exist_ok=True)

def dec(p):
    r = subprocess.run(['ffmpeg', '-v', 'error', '-i', p, '-f', 'f32le', '-ac', '2', '-ar', str(SR), '-'],
                       capture_output=True, check=True)
    return np.frombuffer(r.stdout, dtype=np.float32).reshape(-1, 2).copy()

def loop(x, L=60, X=4, start=3):
    n = len(x) / SR
    L = min(L, n - start - X - 0.5)
    s = int(start * SR); Ls = int(L * SR); Xs = int(X * SR)
    seg = x[s:s + Ls + Xs]
    out = seg[:Ls].copy()
    t = np.linspace(0, 1, Xs, dtype=np.float32)[:, None]
    # eşit güçlü çapraz geçiş: döngü sonu → başı
    out[:Xs] = seg[:Xs] * np.sqrt(t) + seg[Ls:Ls + Xs] * np.sqrt(1 - t)
    return out

def norm(x, db=-20, peak=0.95):
    rms = np.sqrt(np.mean(x ** 2)) + 1e-9
    y = x * (10 ** (db / 20) / rms)
    m = np.max(np.abs(y))
    if m > peak:
        y *= peak / m
    return y

def wrap(x):
    p = int(P * SR)
    return np.concatenate([x[-p:], x, x[:p]])

MAN = {}
def enc(x, name, src, lic):
    p = os.path.join(OUT, name + '.mp3')
    w = wrap(x)
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'f32le', '-ar', str(SR), '-ac', '2', '-i', '-',
                    '-c:a', 'libmp3lame', '-b:a', '112k', p],
                   input=w.astype(np.float32).tobytes(), check=True)
    MAN[name] = {'L': round(len(x) / SR, 6), 'P': P, 'kb': os.path.getsize(p) // 1024, 'kaynak': src, 'lisans': lic}
    print(name, round(len(x) / SR, 1), 's', os.path.getsize(p) // 1024, 'KB')

PX = 'Pixabay İçerik Lisansı / CC0 (Moodist)'
JOBS = {
    'yagmur_hafif':    ([(M + 'rain/light-rain.mp3', 1)], -21, 60, 'Moodist · light-rain', PX),
    'yagmur':          ([(M + 'rain/rain-on-leaves.mp3', 1)], -20, 36, 'Moodist · rain-on-leaves', PX),
    'yagmur_cam':      ([(M + 'rain/rain-on-window.mp3', 1)], -21, 27, 'Moodist · rain-on-window', PX),
    'yagmur_siddetli': ([(M + 'rain/heavy-rain.mp3', 1)], -20, 15, 'Moodist · heavy-rain', PX),
    'firtina':         ([(M + 'nature/howling-wind.mp3', 1)], -22, 48, 'Moodist · howling-wind', PX),
    'gokgurultusu':    ([(M + 'rain/thunder.mp3', 1)], -22, 60, 'Moodist · thunder', PX),
    'kamp_atesi':      ([(M + 'nature/campfire.mp3', 1)], -21, 60, 'Moodist · campfire', PX),
    'somine':          ([(BL + 'fireplace.ogg', 1)], -21, 18, 'Blanket · fireplace', 'Kamu malı (Blanket)'),
    'kafe':            ([(M + 'places/cafe.mp3', 1)], -21, 70, 'Moodist · cafe', PX),
    'kutuphane':       ([(M + 'places/library.mp3', 1)], -24, 70, 'Moodist · library', PX),
    'orman_ruzgar':    ([(M + 'nature/wind-in-trees.mp3', 1)], -23, 48, 'Moodist · wind-in-trees', PX),
    'kuslar':          ([(M + 'animals/birds.mp3', 1)], -22, 70, 'Moodist · birds', PX),
    'dere':            ([(BL + 'stream.ogg', 1)], -21, 70, 'Blanket · stream', 'CC0 (Blanket)'),
    'deniz':           ([(M + 'nature/waves.mp3', 1)], -21, 70, 'Moodist · waves', PX),
    'gece':            ([(M + 'animals/crickets.mp3', 1)], -24, 70, 'Moodist · crickets', PX),
    # Şadırvan: kesintisiz akan su (dere) + taş kurnaya düşen damlalar
    'sadirvan':        ([(BL + 'stream.ogg', 0.75), (M + 'nature/droplets.mp3', 0.55)], -21, 44,
                        'Blanket · stream + Moodist · droplets', 'CC0 (Blanket) + Pixabay/CC0 (Moodist)'),
}
only = set(sys.argv[1:])
for k, (srcs, db, L, src, lic) in JOBS.items():
    if only and k not in only:
        continue
    xs = [(dec(p), g) for p, g in srcs]
    n = min(len(x) for x, _ in xs)
    mix = sum(x[:n] * g for x, g in xs)
    enc(norm(loop(mix, L=L), db), k, src, lic)
man_p = os.path.join(OUT, 'manifest.json')
old = json.load(open(man_p)) if os.path.exists(man_p) else {}
old.update(MAN)
json.dump(old, open(man_p, 'w'), ensure_ascii=False, indent=1)
print('toplam', sum(v['kb'] for v in old.values()), 'KB')
