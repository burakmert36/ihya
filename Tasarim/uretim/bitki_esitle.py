"""Bitki motorunu uygulamaya taşır.

Tasarim/motor/bitki.js  -> Resources/Plants/bitki.js (aynen)
Tasarim/motor/defs.svg  -> Resources/Plants/gradients.json (Swift tarafının okuduğu gradyan tablosu)

Gradyanlar SVG'deki gibi şeklin sınır kutusuna göre (objectBoundingBox) yorumlanır.
Kullanım: python3 Tasarim/uretim/bitki_esitle.py
"""
import json
import re
import shutil
from pathlib import Path

KOK = Path(__file__).resolve().parents[2]
motor = KOK / "Tasarim" / "motor"
hedef = KOK / "Resources" / "Plants"
hedef.mkdir(parents=True, exist_ok=True)


def sayi(v: str) -> float:
    v = v.strip()
    return float(v[:-1]) / 100 if v.endswith("%") else float(v)


def oz(etiket: str) -> dict:
    return dict(re.findall(r'([\w-]+)="([^"]*)"', etiket))


svg = (motor / "defs.svg").read_text(encoding="utf-8")
tablo = {}
for m in re.finditer(r"<(linear|radial)Gradient([^>]*)>(.*?)</\1Gradient>", svg, re.S):
    tur, a, govde = m.group(1), oz(m.group(2)), m.group(3)
    duraklar = []
    for s in re.finditer(r"<stop([^>]*)/?>", govde):
        o = oz(s.group(1))
        renk = o.get("stop-color", "#000000").upper()
        if len(renk) == 4:
            renk = "#" + "".join(c * 2 for c in renk[1:])
        duraklar.append([round(sayi(o.get("offset", "0")), 4), renk, round(float(o.get("stop-opacity", "1")), 3)])
    if tur == "linear":
        g = {"t": "l", "x1": sayi(a.get("x1", "0")), "y1": sayi(a.get("y1", "0")), "x2": sayi(a.get("x2", "1")), "y2": sayi(a.get("y2", "0"))}
    else:
        g = {"t": "r", "cx": sayi(a.get("cx", "50%")), "cy": sayi(a.get("cy", "50%")), "r": sayi(a.get("r", "50%"))}
    g["s"] = duraklar
    tablo[a["id"]] = g

(hedef / "gradients.json").write_text(json.dumps(tablo, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
shutil.copyfile(motor / "bitki.js", hedef / "bitki.js")
print(f"{len(tablo)} gradyan, bitki.js kopyalandı -> {hedef.relative_to(KOK)}")
