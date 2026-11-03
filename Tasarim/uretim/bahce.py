from common import *

body = '''
''' + DEFS + '''
<div style="position: relative; width: 390px; height: 844px; overflow: hidden; font-family: Inter, -apple-system, system-ui, sans-serif; background: linear-gradient(180deg, #6FBDF2 0%, #A9DCFA 30%, #E4F5FF 52%, #F2FAEC 70%, #E6F2DF 100%); color: #10261A">
  <div aria-hidden="true" style="position: absolute; right: -40px; top: 40px; width: 220px; height: 220px; border-radius: 110px; background: radial-gradient(circle, rgba(255,250,215,1) 0%, rgba(255,236,160,.75) 18%, rgba(255,226,140,.18) 45%, rgba(255,226,140,0) 70%)"></div>
  <div aria-hidden="true" class="bulut" style="position: absolute; left: 22px; top: 150px; width: 120px; height: 34px; border-radius: 17px; background: rgba(255,255,255,.75); box-shadow: 34px -12px 0 6px rgba(255,255,255,.7)"></div>
  <div aria-hidden="true" class="bulut" style="position: absolute; left: 250px; top: 200px; width: 80px; height: 22px; border-radius: 11px; background: rgba(255,255,255,.6); box-shadow: 22px -8px 0 4px rgba(255,255,255,.55); animation-duration: 21s"></div>
  <svg aria-hidden="true" width="390" height="220" viewBox="0 0 390 220" style="position: absolute; left: 0; top: 190px">
    <path d="M0 120 Q70 60 150 98 T300 80 T390 96 V220 H0Z" fill="#BFE3D2" opacity=".7"></path>
    <path d="M0 150 Q90 100 190 136 T390 122 V220 H0Z" fill="#A6D7B4" opacity=".75"></path>
  </svg>

  <div aria-hidden="true" style="position: absolute; left: 0; right: 0; top: 440px; bottom: 0; background: linear-gradient(180deg, rgba(160,220,150,0), #B9E4A6 30%, #9FD58E 100%)"></div>
  <div aria-hidden="true" style="position: absolute; left: -30px; top: 520px; width: 170px; height: 170px; border-radius: 85px; background: radial-gradient(circle, rgba(255,120,150,.75), rgba(255,120,150,0) 68%)"></div>
  <div aria-hidden="true" style="position: absolute; left: 150px; top: 600px; width: 200px; height: 200px; border-radius: 100px; background: radial-gradient(circle, rgba(255,214,90,.8), rgba(255,214,90,0) 68%)"></div>
  <div aria-hidden="true" style="position: absolute; right: -50px; top: 470px; width: 190px; height: 190px; border-radius: 95px; background: radial-gradient(circle, rgba(120,170,255,.65), rgba(120,170,255,0) 68%)"></div>
  <div aria-hidden="true" style="position: absolute; left: 40px; top: 700px; width: 160px; height: 160px; border-radius: 80px; background: radial-gradient(circle, rgba(170,120,255,.6), rgba(170,120,255,0) 68%)"></div>

  <header style="position: absolute; left: 20px; right: 16px; top: 56px; display: flex; align-items: flex-end; justify-content: space-between">
    <div style="display: flex; flex-direction: column; gap: 2px">
      <span style="font-size: 13px; font-weight: 700; letter-spacing: .4px; color: rgba(16,38,26,.62)">SALI · 3 KASIM</span>
      <h1 style="margin: 0; font-size: 34px; line-height: 40px; font-weight: 800; letter-spacing: -.6px">Bahçem</h1>
    </div>
    <div style="display: flex; gap: 8px; padding-bottom: 4px">
      <a href="IhyaSeri.dc.html" class="g27 bas" aria-label="Dikim serisi 12 gün" style="height: 38px; padding: 0 12px; border-radius: 19px; display: flex; align-items: center; gap: 6px; font-size: 15px; font-weight: 800; color: #0E5A2C">
        <svg width="16" height="18" viewBox="0 0 16 18" aria-hidden="true"><path d="M8 17C3 17 1.5 13 2.5 10C3.5 7 6 6 6.5 2C9 4 9.5 6 9 8C10.5 7.5 11 6 11 5C13.5 7.5 14.5 11 13.5 13.5C12.6 15.8 10.6 17 8 17Z" fill="#22B35A"></path></svg>12
      </a>
      <div class="g27" aria-label="Rahmet yağmuru 2" style="height: 38px; padding: 0 12px; border-radius: 19px; display: flex; align-items: center; gap: 6px; font-size: 15px; font-weight: 800; color: #0B5C8A">
        <svg width="12" height="16" viewBox="0 0 12 16" aria-hidden="true"><path d="M6 1C6 1 1 7 1 10.5C1 13.5 3.3 15 6 15C8.7 15 11 13.5 11 10.5C11 7 6 1 6 1Z" fill="#2E9BEA"></path></svg>2
      </div>
    </div>
  </header>

  <svg role="img" aria-label="İzometrik bahçe: 23 bitki, 1 kuru dal, şadırvan ve fenerler" width="390" height="340" viewBox="0 0 390 340" style="position: absolute; left: 0; top: 156px; overflow: visible">
    <ellipse cx="195" cy="268" rx="170" ry="14" fill="url(#gAdaGolge)"></ellipse>
    <sc-for list="{{sides}}" as="t"><path d="{{t.d}}" fill="{{t.f}}"></path></sc-for>
    <sc-for list="{{tiles}}" as="t"><path d="{{t.d}}" fill="{{t.f}}" stroke="rgba(255,255,255,.18)" stroke-width=".6"></path></sc-for>
    <sc-for list="{{deco}}" as="t"><path d="{{t.d}}" fill="{{t.f}}" opacity="{{t.o}}" stroke="{{t.s}}" stroke-width="{{t.w}}" stroke-linecap="round"></path></sc-for>
    <g transform="{{sadirvan}}">
      <ellipse cx="0" cy="4" rx="22" ry="11" fill="#9FB4BE"></ellipse>
      <ellipse cx="0" cy="1" rx="22" ry="11" fill="#E9EEF0"></ellipse>
      <ellipse cx="0" cy="1" rx="17" ry="8.4" fill="url(#gSu)"></ellipse>
      <ellipse class="isil" cx="-5" cy="-1" rx="6" ry="2" fill="#FFFFFF" opacity=".6"></ellipse>
      <path d="M-3 0 V-16 H3 V0Z" fill="#DCE4E8"></path><ellipse cx="0" cy="-16" rx="7" ry="3" fill="#F4F7F8"></ellipse>
      <path d="M0 -17 Q-1 -24 0 -27 Q1 -24 0 -17" fill="#8FD3FF" class="isil"></path>
    </g>
    <sc-for list="{{plants}}" as="p">
      <g transform="{{p.tr}}" onClick="{{p.tap}}" style="cursor: pointer"><g class="{{p.cls}}">''' + paths('p.shapes') + '''</g></g>
    </sc-for>
    <sc-for list="{{lanterns}}" as="l">
      <g transform="{{l.tr}}">
        <ellipse cx="0" cy="-12" rx="11" ry="11" fill="{{l.glow}}" class="isil"></ellipse>
        <path d="M-1 0V-9h2V0Z" fill="#4A3A2A"></path><path d="M-4 -9h8l-1 -8h-6Z" fill="{{l.body}}" stroke="#5A4630" stroke-width=".8"></path><path d="M-4.5 -17h9l-4.5 -3.5Z" fill="#5A4630"></path>
      </g>
    </sc-for>
  </svg>

  <sc-if value="{{noSel}}">
    <section aria-label="Bugün" class="g27" style="position: absolute; left: 16px; right: 16px; top: 476px; border-radius: 28px; padding: 14px 16px; display: flex; flex-direction: column; gap: 10px">
      <div style="position: relative; display: flex; justify-content: space-between; align-items: baseline">
        <span style="font-size: 17px; font-weight: 800">Bugün</span>
        <span style="font-size: 13px; font-weight: 700; color: #3D6B4E">45 / 60 dk · 2 dikim</span>
      </div>
      <div style="position: relative; height: 8px; border-radius: 4px; background: rgba(255,255,255,.5); overflow: hidden"><div style="width: 75%; height: 100%; border-radius: 4px; background: linear-gradient(90deg, #57D67E, #1BA552)"></div></div>
      <div style="position: relative; display: flex; gap: 8px; flex-wrap: wrap">
        <span style="height: 28px; padding: 0 10px; border-radius: 14px; background: rgba(255,255,255,.6); color: #1D6B3A; font-size: 12.5px; font-weight: 700; display: flex; align-items: center">Gül · Yâsîn 30 dk</span>
        <span style="height: 28px; padding: 0 10px; border-radius: 14px; background: rgba(255,243,224,.75); color: #9A4A08; font-size: 12.5px; font-weight: 700; display: flex; align-items: center">Turunç · Kehf 15 dk sürüyor</span>
        <span style="height: 28px; padding: 0 10px; border-radius: 14px; background: rgba(255,248,214,.8); color: #7A5A00; font-size: 12.5px; font-weight: 700; display: flex; align-items: center">Fener 3 / 5</span>
      </div>
      <p style="position: relative; margin: 0; font-size: 12.5px; line-height: 18px; color: #2E4A3A">Bitkinin boyu ona verdiğin süreyi gösterir: 30 dk bir gül, 90 dk bir gül çalısı. Kuru dal aynı süreyle ihya edilir.</p>
    </section>
  </sc-if>

  <sc-if value="{{hasSel}}">
    <section class="g27 yuk" aria-live="polite" style="position: absolute; left: 12px; right: 12px; top: 470px; border-radius: 30px; padding: 16px; display: flex; flex-direction: column; gap: 10px">
      <div style="position: relative; display: flex; align-items: center; gap: 12px">
        <svg width="54" height="64" viewBox="-12 -24 124 149" aria-hidden="true" style="flex: none; border-radius: 16px; background: linear-gradient(#DDF1FF, #F4FBEF)">''' + paths('sel.mini') + '''</svg>
        <div style="flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 2px">
          <span style="font-size: 20px; font-weight: 800; letter-spacing: -.2px">{{sel.name}}</span>
          <span style="font-size: 13px; font-weight: 600; color: #3D5A49">{{sel.meta}}</span>
        </div>
        <button class="g27 bas" onClick="{{close}}" aria-label="Kapat" style="width: 36px; height: 36px; border-radius: 18px; font-size: 18px; font-weight: 700; color: #234">×</button>
      </div>
      <div style="position: relative; display: flex; gap: 4px">
        <sc-for list="{{sel.stages}}" as="e">
          <div style="flex: {{e.flex}}; display: flex; flex-direction: column; gap: 4px; min-width: 0">
            <div style="height: 6px; border-radius: 3px; background: {{e.bar}}"></div>
            <span style="font-size: 11px; font-weight: 800; color: #1D3A2A; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">{{e.ad}}</span>
            <span style="font-size: 10.5px; font-weight: 600; color: #4A6656">{{e.aralik}}</span>
          </div>
        </sc-for>
      </div>
      <p style="position: relative; margin: 0; font-size: 13px; line-height: 19px; color: #24402F">{{sel.note}}</p>
      <sc-if value="{{sel.dry}}">
        <a href="IhyaOdak.dc.html" class="g27t bas" style="height: 50px; border-radius: 25px; display: flex; align-items: center; justify-content: center; font-size: 16px; font-weight: 800; letter-spacing: .6px">İHYA ET · 30 dk</a>
      </sc-if>
    </section>
  </sc-if>

''' + tabbar('Bahçe') + '''
</div>
'''

script = r'''
var W = 64, H = 32, OX = 195, OY = 84, D = 26;
var MAP = ['ggggbb', 'gggggb', 'ggggpg', 'ggggpg', 'ggppwp', 'bggpgb'];
var PL = [
  [0, 0, 'cinar', 120, '2 Kasım · Kitap: İhyâ · 120 dk'], [1, 0, 'servi', 60, '28 Ekim · Kur’an · 40 dk'], [0, 1, 'servi', 60, '29 Ekim · Zikir · 40 dk'],
  [0, 2, 'hurma', 120, 'Ekim · 30 günlük seri ödülü'], [2, 0, 'zeytin', 60, '1 Kasım · Kur’an · 60 dk'], [1, 1, 'lale', 40, 'Bugün · Zikir · 20 dk'],
  [1, 2, 'gul', 30, 'Bugün · Kur’an (Yâsîn) · 30 dk'], [2, 1, 'gul', 30, '31 Ekim · Kitap · 30 dk'], [0, 3, 'lavanta', 45, '30 Ekim · Dinleme · 35 dk'],
  [3, 0, 'badem', 35, '1 Kasım · ayın ilk oturumu · 35 dk'], [2, 2, 'turunc', 45, '27 Ekim · Kur’an · 45 dk'], [3, 1, 'nar', 50, '26 Ekim · Kitap · 50 dk'],
  [1, 3, 'reyhan', 20, '25 Ekim · Zikir · 20 dk'], [3, 2, 'sumbul', 25, '24 Ekim · Kur’an · 25 dk'], [4, 0, 'menekse', 15, '23 Ekim · Serbest · 15 dk'],
  [3, 3, 'lale', 40, '22 Ekim · Kur’an · 20 dk'], [2, 3, 'gul', 30, '21 Ekim · Zikir · 30 dk'], [0, 4, 'zeytin', 90, '20 Ekim · Kitap · 60 dk'],
  [1, 4, 'menekse', 15, '19 Ekim · Serbest · 15 dk'], [4, 1, 'lale', 40, '18 Ekim · Kur’an · 20 dk'], [5, 1, 'reyhan', 20, '17 Ekim · Zikir · 20 dk'],
  [5, 2, 'gul', 30, '16 Ekim · Kur’an · 30 dk'], [5, 4, 'gul', 30, 'DRY'], [2, 5, 'sumbul', 25, '15 Ekim · Dinleme · 25 dk']
];
function cen(i, j) { return [OX + (i - j) * W / 2, OY + (i + j) * H / 2]; }
function fx(n) { return Math.round(n * 10) / 10; }
function diamond(i, j) { var c = cen(i, j); return 'M' + fx(c[0]) + ' ' + fx(c[1] - H / 2) + 'L' + fx(c[0] + W / 2) + ' ' + fx(c[1]) + 'L' + fx(c[0]) + ' ' + fx(c[1] + H / 2) + 'L' + fx(c[0] - W / 2) + ' ' + fx(c[1]) + 'Z'; }
class Component extends DCLogic {
  constructor(p) {
    super(p); this.state = { sel: -1 };
    var r = rnd(42), tiles = [], sides = [], deco = [];
    for (var i = 0; i < 6; i++) for (var j = 0; j < 6; j++) {
      var t = MAP[j][i], c = cen(i, j);
      var fill = t === 'b' ? 'url(#gKurak)' : t === 'p' ? 'url(#gTas)' : t === 'w' ? 'url(#gCimen2)' : ((i + j) % 2 ? 'url(#gCimen)' : 'url(#gCimen2)');
      tiles.push({ d: diamond(i, j), f: fill });
      if (j === 5) sides.push({ d: 'M' + fx(c[0] - W / 2) + ' ' + fx(c[1]) + 'L' + fx(c[0]) + ' ' + fx(c[1] + H / 2) + 'L' + fx(c[0]) + ' ' + fx(c[1] + H / 2 + D) + 'L' + fx(c[0] - W / 2) + ' ' + fx(c[1] + D) + 'Z', f: 'url(#gYanSol)' });
      if (i === 5) sides.push({ d: 'M' + fx(c[0]) + ' ' + fx(c[1] + H / 2) + 'L' + fx(c[0] + W / 2) + ' ' + fx(c[1]) + 'L' + fx(c[0] + W / 2) + ' ' + fx(c[1] + D) + 'L' + fx(c[0]) + ' ' + fx(c[1] + H / 2 + D) + 'Z', f: 'url(#gYanSag)' });
      if (t === 'g' || t === 'w') { for (var k = 0; k < 5; k++) { var x = c[0] + (r() - 0.5) * W * 0.6, y = c[1] + (r() - 0.5) * H * 0.55; deco.push({ d: 'M' + fx(x) + ' ' + fx(y) + 'l' + fx(-1 + r() * 2) + ' -' + fx(2.5 + r() * 2), f: 'none', o: 0.7, s: r() > 0.5 ? '#2E8B45' : '#8FDB6A', w: 1 }); } }
      if (t === 'p') { for (var k = 0; k < 4; k++) { var x2 = c[0] + (r() - 0.5) * W * 0.45, y2 = c[1] + (r() - 0.5) * H * 0.4; deco.push({ d: 'M' + fx(x2 - 5) + ' ' + fx(y2) + 'a5 2.4 0 1 0 10 0a5 2.4 0 1 0 -10 0Z', f: '#F2EBDD', o: 0.85, s: 'rgba(120,100,80,.35)', w: 0.6 }); } }
      if (t === 'b') { for (var k = 0; k < 3; k++) { var x3 = c[0] + (r() - 0.5) * W * 0.5, y3 = c[1] + (r() - 0.5) * H * 0.4; deco.push({ d: 'M' + fx(x3) + ' ' + fx(y3) + 'l4 1.5l3 -1', f: 'none', o: 0.55, s: '#9A7A55', w: 0.9 }); } }
    }
    this.tiles = tiles; this.sides = sides; this.deco = deco;
    var self = this;
    var items = PL.map(function (q, n) {
      var c = cen(q[0], q[1]), b = BITKI[q[2]], dry = q[4] === 'DRY', pdk = q[3];
      var shapes = bitkiCiz(q[2], pdk, n * 7 + 3, { lod: 0.6 });
      if (dry) shapes = shapes.map(function (s) { return { d: s.d, f: s.f === 'none' ? 'none' : (s.f.indexOf('Golge') > 0 ? s.f : 'url(#gKuru)'), s: s.s === 'none' ? 'none' : '#8E7A60', w: s.w, o: s.o * 0.92 }; });
      var sc = 0.6;
      return { i: q[0], j: q[1], z: q[0] + q[1], tr: 'translate(' + fx(c[0] - 50 * sc) + ' ' + fx(c[1] + 3 - 112 * sc) + ') scale(' + sc + ')', shapes: shapes, tur: q[2], meta: dry ? '23 Ekim’de kurudu · uygulamadan çıkıldı' : q[4].replace(/· \d+ dk$/, '') + ' · ' + pdk + ' dk', dk: pdk, dry: dry, cls: dry ? '' : (n % 2 ? 'sal' : '') };
    });
    items.sort(function (a, b) { return a.z - b.z; });
    this.items = items;
    var c0 = cen(4, 4); this.sadirvanTr = 'translate(' + fx(c0[0]) + ' ' + fx(c0[1]) + ')';
    this.lanterns = [[4, 2], [4, 3], [2, 4], [3, 4], [3, 5]].map(function (q, k) { var c = cen(q[0], q[1]); return { tr: 'translate(' + fx(c[0] + 14) + ' ' + fx(c[1] + 2) + ')', glow: k < 3 ? 'rgba(255,214,90,.45)' : 'rgba(255,214,90,0)', body: k < 3 ? '#FFD65A' : '#E9E2D2' }; });
  }
  renderVals() {
    var self = this, s = this.state;
    var plants = this.items.map(function (p, k) { return { tr: p.tr, shapes: p.shapes, cls: p.cls, tap: function () { self.setState({ sel: k }); } }; });
    var sel = null;
    if (s.sel >= 0) {
      var p = this.items[s.sel], b = BITKI[p.tur];
      sel = { name: p.dry ? 'Kuru dal · ' + b.ad : bitkiOzet(p.tur, p.dk).split(' · ')[0], meta: p.meta, dry: p.dry, note: p.dry ? 'Fidan kurudu ama kaybolmadı. Aynı süreyle (' + p.dk + ' dk) bir oturum onu yeniden yeşertir; ihya edilen bitki bahçede hafif bir nur haresiyle durur.' : b.not + ' Bu bitkiye ' + p.dk + ' dakika verildi; daha uzun oturumlar daha büyük bitki yetiştirir.',
        mini: bitkiCiz(p.tur, p.dk, 5, { lod: 0.6 }),
        stages: b.evre.filter(function (e) { return e[1] < p.dk; }).map(function (e) { var z = Math.min(e[2], p.dk); return { ad: e[0], aralik: e[1] + '–' + z + ' dk', flex: String(z - e[1]), bar: p.dry ? '#C9B79C' : 'linear-gradient(90deg,#57D67E,#1BA552)' }; }) };
    }
    return {
      tiles: this.tiles, sides: this.sides, deco: this.deco, plants: plants, sadirvan: this.sadirvanTr, lanterns: this.lanterns,
      sel: sel || { stages: [], mini: [] }, hasSel: !!sel, noSel: !sel, close: function () { self.setState({ sel: -1 }); }
    };
  }
}
'''
extra_defs = '''<svg width="0" height="0" style="position:absolute" aria-hidden="true"><defs>
<linearGradient id="gCimen" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#9BE36E"/><stop offset="1" stop-color="#56B954"/></linearGradient>
<linearGradient id="gCimen2" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#8ED866"/><stop offset="1" stop-color="#4AAE4E"/></linearGradient>
<linearGradient id="gKurak" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E9D5AE"/><stop offset="1" stop-color="#C9AE80"/></linearGradient>
<linearGradient id="gTas" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#E6DDCB"/><stop offset="1" stop-color="#C8BBA2"/></linearGradient>
<linearGradient id="gYanSol" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A6242"/><stop offset="1" stop-color="#5A3E28"/></linearGradient>
<linearGradient id="gYanSag" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#A97C55"/><stop offset="1" stop-color="#6E4C33"/></linearGradient>
<radialGradient id="gAdaGolge" cx="50%" cy="50%" r="50%"><stop offset="0" stop-color="#1E5A2E" stop-opacity=".28"/><stop offset="1" stop-color="#1E5A2E" stop-opacity="0"/></radialGradient>
<radialGradient id="gSu" cx="40%" cy="35%" r="70%"><stop offset="0" stop-color="#B8F0FF"/><stop offset=".6" stop-color="#3FB6E8"/><stop offset="1" stop-color="#1A7FB8"/></radialGradient>
</defs></svg>'''
body = body.replace(DEFS, DEFS + '\n' + extra_defs, 1)
body = body.replace('{{sadirvan}}', '{{sadirvan}}')
html = page('İhya · Bahçem', 390, 844, body, script)
open(OUT + 'IhyaBahce.dc.html', 'w').write(html)
print('ok', len(html))
