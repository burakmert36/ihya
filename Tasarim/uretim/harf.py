# Arapça harf rozetleri: Amiri (OFL) yazı tipinden harf dış hatları → SVG path.
# Harf, sınır kutusunun (bbox) merkezine göre kutunun tam ortasına yerleşir; taban çizgisi/yazı tipi
# metrikleri yüzünden oluşan "kayıklık" böylece ortadan kalkar.
import json, os
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.transformPen import TransformPen

B = os.path.dirname(os.path.dirname(os.path.abspath(__file__))) + '/'
F = TTFont(B + 'ext/font/Amiri-Bold.ttf')
GS = F.getGlyphSet(); CMAP = F.getBestCmap()

def harf(ch, kutu=24.0, doluluk=0.70):
    """ch harfini kutu×kutu alanın ortasına, en uzun kenarı kutu*doluluk olacak şekilde yerleştirir."""
    g = CMAP[ord(ch)]
    bp = BoundsPen(GS); GS[g].draw(bp)
    x0, y0, x1, y1 = bp.bounds
    w, h = x1 - x0, y1 - y0
    s = kutu * doluluk / max(w, h)
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    # y ekseni ters (yazı tipi yukarı, SVG aşağı); merkez → kutu/2
    t = (s, 0, 0, -s, kutu / 2 - s * cx, kutu / 2 + s * cy)
    sp = SVGPathPen(GS, ntos=lambda v: ('%.2f' % v).rstrip('0').rstrip('.'))
    GS[g].draw(TransformPen(sp, t))
    return sp.getCommands()

HARFLER = {'dua': 'د', 'hadis': 'ح', 'hikmet': 'ع', 'fikih': 'ف', 'esma': 'أ', 'kible': 'ق', 'gunler': 'ي', 'okuma': 'ن', 'kuran': 'ك'}
HARF = {k: harf(v) for k, v in HARFLER.items()}

if __name__ == '__main__':
    # Görsel merkez testi: her harfi 240×240 tuvale çizip mürekkep sınır kutusunun merkezini ölçer.
    import subprocess, tempfile
    svg = ''.join('<svg xmlns="http://www.w3.org/2000/svg" width="240" height="240" viewBox="0 0 24 24" style="display:block;background:#fff"><path d="%s" fill="#000"/></svg>' % d for d in HARF.values())
    open('/tmp/claude-0/-home-claude/c80d420a-8fe8-580b-b152-3f41d5b4ce41/scratchpad/render/harf_test.html', 'w').write('<html><body style="margin:0">' + svg + '</body></html>')
    print(json.dumps({k: len(v) for k, v in HARF.items()}))
