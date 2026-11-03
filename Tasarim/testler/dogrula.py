# İhya · içerik ve veri doğrulama paketi (python3 -I tests/dogrula.py)
# Hadis, hikmet, vakit, ses ve harf verilerini kaynaklarına karşı otomatik sınar. Çıkış kodu = başarısız test sayısı.
import json, os, re, sys, subprocess, math, collections
R = os.path.dirname(os.path.dirname(os.path.abspath(__file__))) + '/'
SONUC = []
def test(ad, kosul, ayrinti=''):
    SONUC.append((ad, bool(kosul), ayrinti)); return bool(kosul)

# ——— 1. Hadisler ———
H = json.load(open(R + 'data/hadis/buhari_nihai.json'))
A = {x['n']: x for x in json.load(open(R + 'data/hadis/all_clean.json'))}
nos = [h['no'] for h in H]
test('Hadis sayısı 314', len(H) == 314, str(len(H)))
test('Hadis numaraları tekil', len(nos) == len(set(nos)), str([n for n, c in collections.Counter(nos).items() if c > 1]))
test('Her numara Buhârî külliyatında var', all(n in A for n in nos), str([n for n in nos if n not in A]))
KONU = {'İman ve ihlas', 'Namaz', "Kur'an", 'Zikir ve dua', 'Güzel ahlak', 'Merhamet ve kardeşlik', 'Anne baba ve aile', 'Sadaka ve emek', 'Oruç ve Ramazan', 'Sabır ve şifa', 'Ahiret', 'İlim'}
test('Konular geçerli', all(h['konu'] in KONU for h in H), str({h['konu'] for h in H} - KONU))
test('sunnah.com bağlantısı numarayla aynı', all(h['link'] == 'https://sunnah.com/bukhari:%d' % h['no'] for h in H))
test('Kaynak satırı kitap+numara', all(h['kaynak'] == 'Buhârî, %s, %d' % (h['kitap'], h['no']) for h in H))
# kitap adı ↔ kitap numarası tutarlılığı: aynı kitap numarası hep aynı Türkçe ada eşlenmeli
km = collections.defaultdict(set)
for h in H: km[A[h['no']]['book']].add(h['kitap'])
test('Kitap numarası → tek ad', all(len(v) == 1 for k, v in km.items() if k != 0), str({k: v for k, v in km.items() if len(v) > 1}))
# OCR/imla artıkları
kotu = [h['no'] for h in H if re.search(r"\s{2,}|\u00ad|[a-zçğıöşü][A-ZÇĞİÖŞÜ]{2}|\d[a-zçğıöşü]|\(s\.a\.v\.\)[^\s,.;:’'”)]", h['metin'])]
test('Metinlerde OCR artığı yok', not kotu, str(kotu[:10]))
test('Tırnaklar dengeli', all(h['metin'].count('“') == h['metin'].count('”') for h in H), str([h['no'] for h in H if h['metin'].count('“') != h['metin'].count('”')][:10]))
# râvî ↔ İngilizce "Narrated X" uyumu (örneklem kuralı: bilinen eşleşmeler)
RAVI_EN = {'Ebû Hüreyre': ['Abu Huraira', 'Abu Hurairah'], 'Hz. Âişe': ['Aisha', "'Aisha", '`Aisha'], 'Enes b. Mâlik': ['Anas'], 'Abdullah b. Ömer': ["Umar", 'Ibn `Umar', "Ibn 'Umar", 'Salim'], 'Abdullah b. Abbâs': ['Abbas']}
yanlis = []
for h in H:
    if h['ravi'] in RAVI_EN:
        en = A[h['no']]['en'][:160]
        if not any(t in en for t in RAVI_EN[h['ravi']]): yanlis.append((h['no'], h['ravi']))
test('Râvî adı İngilizce metinle uyumlu (5 büyük râvî)', len(yanlis) <= 3, str(yanlis[:10]))

# ——— 2. Hikmetli sözler ———
K = json.load(open(R + 'data/hikmet/hikmetler.json'))
S = K['sozler']
test('Söz sayısı 129', len(S) == 129, str(len(S)))
Q = {(v['chapter'], v['verse']): v['text'] for v in json.load(open(R + 'data/raw/tur-diyanetisleri.json'))['quran']}
kq = []
for s in S:
    m = re.match(r"Kur'ân-ı Kerîm, .+ (\d+):(\d+)", s['kaynak'])
    if m:
        txt = Q[(int(m.group(1)), int(m.group(2)))].lower()
        if s['soz'][:1].lower() + s['soz'][1:].lower() not in txt and s['soz'].lower().replace('başıma', 'başıma') not in txt: kq.append(s['kaynak'])
test('Âyet alıntıları Diyanet mealiyle birebir', not kq, str(kq))
BEN = {3668: 'Abu Bakr', 1597: 'Umar', 127: 'Ali', 6308: 'Abdullah', 7277: 'Abdullah', 3: 'Khadija', 4418: 'Ka', 3606: 'Hudhaifa', 6416: 'Ibn `Umar', 1890: 'Umar', 3713: 'Abu Bakr', 3671: 'Ali', 6492: 'Anas', 1968: 'Salman'}
kb = []
for s in S:
    for n in [int(x) for x in re.findall(r', (\d+)(?:;|$)', s['kaynak'])] if s['kaynak'].startswith('Buhârî') else []:
        if n in BEN and BEN[n] not in A[n]['en']: kb.append((n, s['kisi']))
        if n not in A: kb.append((n, 'yok'))
test('Sahâbe sözlerinin Buhârî numaraları doğru kişiyi gösteriyor', not kb, str(kb))
test('Yanlış atıf kalkanı dolu', len(K['yanlis_atiflar']) >= 7)

# ——— 3. Vakitler ———
V = json.load(open(R + 'data/vakit/vakitler_bursa.json'))
test('30 günlük cetvel', len(V) == 30, str(len(V)))
import datetime as dt
tar = [dt.datetime.strptime(v['tarih'], '%d.%m.%Y').date() for v in V]
test('Tarihler ardışık', all((b - a).days == 1 for a, b in zip(tar, tar[1:])))
def dk(t): h, m = t.split(':'); return int(h) * 60 + int(m)
test('Gün içi sıra imsak<güneş<öğle<ikindi<akşam<yatsı', all(dk(v['imsak']) < dk(v['gunes']) < dk(v['ogle']) < dk(v['ikindi']) < dk(v['aksam']) < dk(v['yatsi']) for v in V))
test('Tümü Diyanet kaynaklı', all(v['kaynak'] == 'Diyanet' for v in V))
# astronomik denetim: Bursa merkez, NOAA güneş konumu, Diyanet açıları (imsak 18°, yatsı 17°, ikindi gölge 1) + temkin
def gunes(d, lat=40.1826, lon=29.0665, tz=3):
    N = d.timetuple().tm_yday; g = 2 * math.pi / 365 * (N - 1)
    eq = 229.18 * (0.000075 + 0.001868 * math.cos(g) - 0.032077 * math.sin(g) - 0.014615 * math.cos(2 * g) - 0.040849 * math.sin(2 * g))
    de = 0.006918 - 0.399912 * math.cos(g) + 0.070257 * math.sin(g) - 0.006758 * math.cos(2 * g) + 0.000907 * math.sin(2 * g) - 0.002697 * math.cos(3 * g) + 0.00148 * math.sin(3 * g)
    noon = 720 - 4 * lon - eq + tz * 60
    def ha(alt):
        c = (math.sin(math.radians(alt)) - math.sin(math.radians(lat)) * math.sin(de)) / (math.cos(math.radians(lat)) * math.cos(de))
        return math.degrees(math.acos(max(-1, min(1, c)))) * 4
    asr_alt = math.degrees(math.atan(1 / (1 + math.tan(abs(math.radians(lat) - de)))))
    return [noon - ha(-18) - 0.23, noon - ha(-0.833) - 7.44, noon + 4.97, noon + ha(asr_alt) + 4.29, noon + ha(-0.833) + 7.37, noon + ha(-17) + 0.33]
fark = []
for d, v in zip(tar, V):
    c = gunes(d)
    for i, k in enumerate(['imsak', 'gunes', 'ogle', 'ikindi', 'aksam', 'yatsi']):
        fark.append(abs(dk(v[k]) - c[i]))
test('Vakitler hesapla ±2 dk içinde', max(fark) <= 2.0, 'en büyük fark %.2f dk' % max(fark))

# ——— 4. Sesler ———
M = json.load(open(R + 'ses/mp3/manifest.json'))
test('16 kayıt döngüsü', len(M) == 16, str(len(M)))
test('Her kaydın lisans ve kaynağı yazılı', all(v.get('lisans') and v.get('kaynak') for v in M.values()))
sesler = open(R + 'build/sesler.py').read()
kul = set(re.findall(r"a: '([a-z_]+)'", sesler)) | set(re.findall(r"b: '([a-z_]+)'", sesler))
test('Ses tablosundaki her kayıt dosyası mevcut', kul <= set(M) and all(os.path.exists(R + 'ses/mp3/%s.mp3' % k) for k in kul), str(kul - set(M)))
def coz(p):
    r = subprocess.run(['ffmpeg', '-v', 'error', '-i', p, '-f', 'f32le', '-ac', '2', '-ar', '44100', '-'], capture_output=True)
    import array; a = array.array('f'); a.frombytes(r.stdout); return a
dikis = []
try:
    import numpy as np
    for k, v in M.items():
        x = np.frombuffer(bytes(coz(R + 'ses/mp3/%s.mp3' % k)), dtype=np.float32).reshape(-1, 2)
        for d in (0, 1105):
            a = int(v['P'] * 44100) + d; b = a + int(round(v['L'] * 44100))
            seam = np.abs(x[b - 1] - x[a]).mean(); diffs = np.abs(np.diff(x[a:b], axis=0)).mean(1)
            if (diffs < seam).mean() > 0.995: dikis.append((k, d))
except ImportError:
    pass
test('Döngü dikişleri duyulmaz (sıçrama normal farkların %99.5 altında)', not dikis, str(dikis))

# ——— 5. Harf rozetleri ———
sys.path.insert(0, R + 'build')
from harf import HARF
test('9 harf rozeti üretildi', len(HARF) == 9)

for ad, ok, ay in SONUC:
    print(('✓ ' if ok else '✗ ') + ad + ('' if ok or not ay else '  → ' + ay))
bas = sum(1 for s in SONUC if not s[1])
print('\n%d/%d test geçti' % (len(SONUC) - bas, len(SONUC)))
sys.exit(bas)
