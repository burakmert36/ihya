from common import *
from harf import HARF
# Kitaplık (İhya dili): harf rozetleri SVG yol olarak çizilir ve kutu merkezine bbox ile hizalanır.
H = json.load(open(B + 'data/hadis/buhari_nihai.json'))
KISA = [{'metin': h['metin'], 'kaynak': 'BUHÂRÎ, ' + h['kitap'].upper() + ', ' + str(h['no']), 'ravi': h['ravi']} for h in H if len(h['metin']) <= 64]
NK = len(json.load(open(B + 'data/hikmet/hikmetler.json'))['sozler'])

def rozet(key, c1, c2):
    return ('<span aria-hidden="true" style="flex: none; width: 38px; height: 38px; border-radius: 19px; background: linear-gradient(160deg, %s, %s); box-shadow: inset 0 1px 0 rgba(255,255,255,.55), 0 4px 12px rgba(0,0,0,.25); display: flex; align-items: center; justify-content: center">'
            '<svg width="22" height="22" viewBox="0 0 24 24" style="display: block"><path d="%s" fill="#FFFFFF"></path></svg></span>') % (c1, c2, HARF[key])

TILES = [
    ('dua', 'Dualar', 'Sabah · akşam', '#F7C548', '#D98E1F', None),
    ('hadis', 'Hadisler', '%d sahih hadis' % len(H), '#9B8CFF', '#5B4BD8', 'HadisHikmet.dc.html'),
    ('hikmet', 'Hikmet', '%d kaynaklı söz' % NK, '#FF9AB8', '#D9507E', 'HadisHikmet.dc.html'),
    ('okuma', 'Okuma modu', 'Göz yormayan', '#8FD6C8', '#2E8F7E', 'OkumaModu.dc.html'),
    ('fikih', 'İlmihal', 'Hanefî · Diyanet', '#7FDB8A', '#2A9C4A', None),
    ('esma', 'Esmâ-i Hüsnâ', '99 isim · ezber', '#FFA07A', '#D9573A', None),
    ('kible', 'Kıble', 'Bursa · 151° (GD)', '#7CC4FF', '#2F7FD1', None),
    ('gunler', 'Dinî günler', 'Kandiller · üç aylar', '#C9A2FF', '#8452D6', None),
]
tiles = ''
for key, ad, alt, c1, c2, href in TILES:
    tag_open = ('<a href="%s" class="g27k bas"' % href) if href else '<div class="g27k"'
    tag_close = '</a>' if href else '</div>'
    tiles += (tag_open + ' style="height: 60px; border-radius: 20px; padding: 0 10px; display: flex; align-items: center; gap: 10px; color: #F2F8FA">' + rozet(key, c1, c2) +
              '<span style="position: relative; min-width: 0; display: flex; flex-direction: column; gap: 2px"><span style="font-size: 14px; line-height: 17px; font-weight: 800; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">' + ad +
              '</span><span style="font-size: 11px; line-height: 14px; font-weight: 600; color: rgba(226,240,244,.66); white-space: nowrap; overflow: hidden; text-overflow: ellipsis">' + alt + '</span></span>' + tag_close + '\n')

body = '''
<div style="position: relative; width: 390px; height: 844px; overflow: hidden; font-family: Inter, -apple-system, system-ui, sans-serif; color: #F2F8FA; background: radial-gradient(120% 75% at 75% 0%, #23606A 0%, #133844 46%, #0A1A22 100%)">
  <div aria-hidden="true" style="position: absolute; left: -70px; top: 250px; width: 280px; height: 280px; border-radius: 140px; background: radial-gradient(circle, rgba(255,190,90,.30), rgba(255,190,90,0) 68%)"></div>
  <div aria-hidden="true" style="position: absolute; right: -80px; top: 470px; width: 300px; height: 300px; border-radius: 150px; background: radial-gradient(circle, rgba(150,120,255,.30), rgba(150,120,255,0) 68%)"></div>
  <div aria-hidden="true" style="position: absolute; left: 60px; top: 690px; width: 260px; height: 220px; border-radius: 130px; background: radial-gradient(circle, rgba(80,230,170,.24), rgba(80,230,170,0) 68%)"></div>

  <div style="position: absolute; left: 20px; right: 20px; top: 56px; display: flex; justify-content: space-between; align-items: flex-end">
    <h1 style="margin: 0; font-size: 34px; line-height: 40px; font-weight: 800; letter-spacing: -.6px">Kitaplık</h1>
    <span style="font-size: 12px; font-weight: 700; color: rgba(226,240,244,.62); padding-bottom: 6px">Hepsi telefonunda · çevrimdışı</span>
  </div>

  <label class="g27k" style="position: absolute; left: 16px; right: 16px; top: 110px; height: 46px; border-radius: 23px; display: flex; align-items: center; gap: 10px; padding: 0 16px">
    <svg width="18" height="18" viewBox="0 0 24 24" aria-hidden="true" style="position: relative; flex: none"><circle cx="10.5" cy="10.5" r="6.5" fill="none" stroke="rgba(226,240,244,.8)" stroke-width="2.2"></circle><path d="M15.5 15.5 21 21" stroke="rgba(226,240,244,.8)" stroke-width="2.2" stroke-linecap="round"></path></svg>
    <input type="search" placeholder="Dua, hadis, söz, ilmihal ara" aria-label="Kitaplıkta ara" style="position: relative; flex: 1; min-width: 0; height: 40px; border: 0; outline: 0; background: transparent; color: #F2F8FA; font: 600 15px Inter, system-ui, sans-serif">
  </label>

  <div style="position: absolute; left: 16px; right: 16px; top: 170px; bottom: 108px; display: flex; flex-direction: column; gap: 12px">
  <a href="HadisHikmet.dc.html" class="g27 bas" style="flex: none; border-radius: 28px; padding: 14px 18px 14px; display: flex; flex-direction: column; gap: 8px; background: linear-gradient(165deg, rgba(255,253,246,.92), rgba(247,240,224,.84)); color: #2A2416">
    <span style="position: relative; display: flex; align-items: center; gap: 8px">
      <span style="height: 22px; padding: 0 9px; border-radius: 11px; background: #2A2416; color: #FFE6A8; font-size: 10.5px; font-weight: 800; letter-spacing: 1px; display: flex; align-items: center">GÜNÜN HADİSİ</span>
      <span style="font-size: 11px; font-weight: 700; color: #7A6A48">{{g.ravi}}</span>
    </span>
    <span style="position: relative; font-family: Newsreader, Georgia, serif; font-size: 19px; line-height: 25px; font-weight: 500; color: #1E190E">“{{g.metin}}”</span>
    <span style="position: relative; font-size: 11.5px; font-weight: 800; letter-spacing: .6px; color: #9A6A00">{{g.kaynak}}</span>
  </a>

  <div style="flex: none; display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 10px">
''' + tiles + '''  </div>

  <section class="g27k" style="flex: none; height: 146px; border-radius: 28px; padding: 14px; display: flex; gap: 14px; align-items: center">
    <div aria-hidden="true" style="position: relative; flex: none; width: 128px; display: grid; grid-template-columns: repeat(11, minmax(0, 1fr)); gap: 3px">
      <sc-for list="{{dots}}" as="d"><span style="width: 8px; height: 8px; border-radius: 4px; background: {{d.bg}}; box-shadow: {{d.glow}}"></span></sc-for>
    </div>
    <div style="position: relative; flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 4px">
      <span style="font-size: 10.5px; font-weight: 800; letter-spacing: 1px; color: rgba(226,240,244,.62)">ESMÂ EZBERİ · {{learned}}/99</span>
      <span dir="rtl" lang="ar" style="font-family: Amiri, 'Amiri Quran', 'Geeza Pro', serif; font-size: 25px; line-height: 40px; color: #FFE08A; text-align: left; margin-top: -2px">{{nm.ar}}</span>
      <span style="font-size: 13.5px; font-weight: 800">{{nm.tr}} <span style="font-weight: 600; color: rgba(226,240,244,.7)">· {{nm.mean}}</span></span>
      <button onClick="{{ezber}}" class="g27t bas" style="margin-top: 2px; height: 34px; border-radius: 17px; font-size: 12.5px; font-weight: 800; letter-spacing: .5px"><span style="position: relative">EZBERLEDİM</span></button>
    </div>
  </section>
  </div>

''' + tabbar('Kitaplık', koyu=True) + '''
</div>
'''

script = r'''
var KISA = ''' + json.dumps(KISA, ensure_ascii=False) + r''';
var NAMES = [
  { ar: 'الْمُصَوِّرُ', tr: 'el-Musavvir', mean: 'şekil ve suret veren' },
  { ar: 'الْغَفَّارُ', tr: 'el-Gaffâr', mean: 'çokça bağışlayan' },
  { ar: 'الْقَهَّارُ', tr: 'el-Kahhâr', mean: 'her şeye galip gelen' },
  { ar: 'الْوَهَّابُ', tr: 'el-Vehhâb', mean: 'karşılıksız veren' },
  { ar: 'الرَّزَّاقُ', tr: 'er-Rezzâk', mean: 'rızık veren' },
  { ar: 'الْفَتَّاحُ', tr: 'el-Fettâh', mean: 'hayır kapılarını açan' }
];
class Component extends DCLogic {
  constructor(p) { super(p); var now = new Date(); this.gun = Math.floor((now - new Date(now.getFullYear(), 0, 0)) / 86400000); this.state = { learned: 12 }; }
  renderVals() {
    var self = this, s = this.state, g = KISA[this.gun % KISA.length];
    var dots = []; for (var i = 0; i < 99; i++) { var on = i < s.learned; dots.push({ bg: on ? '#FFD966' : 'rgba(255,255,255,.14)', glow: on ? '0 0 5px rgba(255,217,102,.7)' : 'none' }); }
    return {
      g: g,
      dots: dots, learned: s.learned, nm: NAMES[Math.min(s.learned - 12, NAMES.length - 1)],
      ezber: function () { self.setState({ learned: Math.min(99, self.state.learned + 1) }); }
    };
  }
}
'''
html = page('İhya · Kitaplık', 390, 844, body, script, head='<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Amiri:wght@400;700&amp;display=swap">\n').replace(ENGINE, '')
open(OUT + 'IhyaKitaplik.dc.html', 'w').write(html)
print('ok', len(html), len(KISA))
