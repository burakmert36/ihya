# İhya 1.4 · Moodist'ten yeni dikişsiz döngüler (loop2.py yöntemi; 80 kbps)
import subprocess, numpy as np, os, sys, json
SR = 44100; P = 0.5
M = sys.argv[1]; OUT = sys.argv[2]
def dec(p):
    r = subprocess.run(['ffmpeg','-v','error','-i',p,'-f','f32le','-ac','2','-ar',str(SR),'-'], capture_output=True, check=True)
    return np.frombuffer(r.stdout, dtype=np.float32).reshape(-1,2).copy()
def loop(x, L, X, start):
    n = len(x)/SR
    L = min(L, n - start - X - 0.3)
    s=int(start*SR); Ls=int(L*SR); Xs=int(X*SR)
    seg = x[s:s+Ls+Xs]; out = seg[:Ls].copy()
    t = np.linspace(0,1,Xs,dtype=np.float32)[:,None]
    out[:Xs] = seg[:Xs]*np.sqrt(t) + seg[Ls:Ls+Xs]*np.sqrt(1-t)
    return out
def norm(x, db, peak=0.95):
    rms = np.sqrt(np.mean(x**2))+1e-9; y = x*(10**(db/20)/rms); m=np.max(np.abs(y))
    if m>peak: y*=peak/m
    return y
def wrap(x):
    p=int(P*SR); return np.concatenate([x[-p:], x, x[:p]])
JOBS = {
 'nehir': ('nature/river',40,-21), 'selale': ('nature/waterfall',19,-21), 'damlalar': ('nature/droplets',40,-22),
 'ruzgar': ('nature/wind',40,-22), 'tropik': ('nature/jungle',45,-22), 'kar_yuruyus': ('nature/walk-in-snow',32,-23),
 'yaprak_yuruyus': ('nature/walk-on-leaves',17,-23), 'cadir_yagmur': ('rain/rain-on-tent',40,-21),
 'semsiye_yagmur': ('rain/rain-on-umbrella',22,-21), 'araba_yagmur': ('rain/rain-on-car-roof',7.5,-21),
 'baykus': ('animals/owl',10,-24), 'kurbaga': ('animals/frog',40,-23), 'marti': ('animals/seagulls',38,-23),
 'agackakan': ('animals/woodpecker',12,-25), 'ari': ('animals/beehive',40,-24), 'kedi': ('animals/cat-purring',34,-22),
 'gece_koy': ('places/night-village',45,-23), 'su_alti': ('places/underwater',38,-21), 'saat': ('things/clock',12,-27),
 'sayfa': ('things/paper',14,-25), 'daktilo': ('things/typewriter',18,-25), 'ruzgar_cani': ('things/wind-chimes',40,-24),
 'vantilator': ('things/ceiling-fan',12,-23), 'tren': ('transport/inside-a-train',40,-22), 'yelkenli': ('transport/sailboat',45,-22),
 'kurek': ('transport/rowing-boat',21,-22),
}
man = {}
for k,(src,L,db) in JOBS.items():
    x = dec(os.path.join(M, src + '.mp3'))
    n = len(x)/SR
    X = 2.0 if n < 20 else 3.0
    start = 0.6 if n < 20 else 2.0
    y = norm(loop(x, L, X, start), db)
    p = os.path.join(OUT, k + '.mp3')
    subprocess.run(['ffmpeg','-v','error','-y','-f','f32le','-ar',str(SR),'-ac','2','-i','-','-c:a','libmp3lame','-b:a','80k',p],
                   input=wrap(y).astype(np.float32).tobytes(), check=True)
    man[k] = {'L': round(len(y)/SR,6), 'kaynak': 'Moodist · ' + src.split('/')[1], 'kb': os.path.getsize(p)//1024}
    print(k, man[k])
json.dump(man, open(os.path.join(OUT, '..', 'yeni_sesler.json'), 'w'), ensure_ascii=False, indent=1)
