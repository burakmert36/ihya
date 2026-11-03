from common import *
# Bugün (İhya dili): sıradaki vakit + gün çizgisi, beş vakit takibi, bugünkü odak bahçesi, günün sözü, hızlı geçişler.
V = json.load(open(B + 'data/vakit/vakitler_bursa.json'))
VK = [{'t': v['tarih'], 'h': v['hicri'], 'v': [v['imsak'], v['gunes'], v['ogle'], v['ikindi'], v['aksam'], v['yatsi']]} for v in V]
K = json.load(open(B + 'data/hikmet/hikmetler.json'))['sozler']
SOZ = [{'soz': s['soz'], 'kisi': s['kisi'], 'kaynak': s['kaynak']} for s in K if len(s['soz']) <= 80]

body = DEFS + '''
<div style="position: relative; width: 390px; height: 844px; overflow: hidden; font-family: Inter, -apple-system, system-ui, sans-serif; color: #12302A; background: linear-gradient(180deg, #8FD0F7 0%, #CBE9FB 32%, #F2F7FF 62%, #FFF1DE 100%)">
  <div aria-hidden="true" style="position: absolute; right: -50px; top: 30px; width: 230px; height: 230px; border-radius: 115px; background: radial-gradient(circle, rgba(255,250,215,1) 0%, rgba(255,232,150,.55) 36%, rgba(255,232,150,0) 70%)"></div>
  <div aria-hidden="true" style="position: absolute; left: -60px; top: 380px; width: 260px; height: 260px; border-radius: 130px; background: radial-gradient(circle, rgba(120,230,170,.45), rgba(120,230,170,0) 68%)"></div>
  <div aria-hidden="true" style="position: absolute; right: -70px; top: 560px; width: 280px; height: 280px; border-radius: 140px; background: radial-gradient(circle, rgba(255,160,120,.40), rgba(255,160,120,0) 68%)"></div>

  <div style="position: absolute; left: 20px; right: 20px; top: 52px; display: flex; justify-content: space-between; align-items: flex-end">
    <div style="display: flex; flex-direction: column; gap: 2px">
      <span style="font-size: 12px; font-weight: 800; letter-spacing: 1px; color: rgba(18,48,42,.62)">{{tarih}}</span>
      <h1 style="margin: 0; font-size: 34px; line-height: 40px; font-weight: 800; letter-spacing: -.6px">{{selam}}</h1>
    </div>
    <span class="g27" style="height: 32px; padding: 0 12px; border-radius: 16px; display: flex; align-items: center; gap: 6px; font-size: 13px; font-weight: 800; color: #0E6A33"><svg width="14" height="14" viewBox="0 0 24 24" aria-hidden="true" style="position: relative"><path d="M12 21.2v-8.4" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"></path><path d="M12 14.4C12 9.8 9 7.2 4 7.2c0 4.6 3 7.2 8 7.2Z" fill="currentColor"></path><path d="M12 11.6c0-4.8 3-7.8 8-7.8 0 4.8-3 7.8-8 7.8Z" fill="currentColor"></path></svg><span style="position: relative">12 gün seri</span></span>
  </div>

  <div style="position: absolute; left: 16px; right: 16px; top: 112px; bottom: 108px; display: flex; flex-direction: column; gap: 12px">
  <a href="VakitCetveli.dc.html" class="g27 bas" style="flex: none; border-radius: 30px; padding: 16px 18px 14px; display: flex; flex-direction: column; gap: 12px; color: #12302A">
    <span style="position: relative; display: flex; justify-content: space-between; align-items: baseline">
      <span style="font-size: 13px; font-weight: 800; color: rgba(18,48,42,.66)">Sıradaki vakit · <span style="color: #0E6A33">{{sonraki}}</span></span>
      <span style="font-size: 12px; font-weight: 700; color: rgba(18,48,42,.55)">{{sonrakiSaat}} · Bursa</span>
    </span>
    <span style="position: relative; font-size: 46px; line-height: 50px; font-weight: 800; letter-spacing: -1px; font-variant-numeric: tabular-nums">{{geri}}</span>
    <span style="position: relative; display: grid; grid-template-columns: repeat(6, minmax(0, 1fr)); gap: 4px">
      <sc-for list="{{cizgi}}" as="c">
        <span style="display: flex; flex-direction: column; align-items: center; gap: 4px">
          <span style="width: 100%; height: 6px; border-radius: 3px; background: {{c.bar}}"></span>
          <span style="font-size: 10.5px; font-weight: 800; color: {{c.color}}">{{c.ad}}</span>
          <span style="font-size: 10.5px; font-weight: 600; font-variant-numeric: tabular-nums; color: rgba(18,48,42,.58)">{{c.saat}}</span>
        </span>
      </sc-for>
    </span>
  </a>

  <section aria-label="Beş vakit takibi" class="g27" style="flex: none; border-radius: 26px; padding: 12px 14px; display: flex; flex-direction: column; gap: 10px">
    <span style="position: relative; display: flex; justify-content: space-between; align-items: baseline"><span style="font-size: 15px; font-weight: 800">Namazlarım</span><span style="font-size: 12px; font-weight: 800; color: #0E6A33">{{kilinan}}/5 kılındı</span></span>
    <div style="position: relative; display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); gap: 6px">
      <sc-for list="{{farz}}" as="f">
        <button onClick="{{f.tap}}" role="checkbox" aria-checked="{{f.on}}" aria-label="{{f.ad}} namazı" class="bas" style="height: 54px; border-radius: 18px; background: {{f.bg}}; color: {{f.color}}; box-shadow: {{f.sh}}; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 3px">
          <svg width="16" height="16" viewBox="0 0 24 24" aria-hidden="true"><path d="{{f.ikon}}" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"></path></svg>
          <span style="font-size: 11px; font-weight: 800">{{f.ad}}</span>
        </button>
      </sc-for>
    </div>
  </section>

  <a href="IhyaBahce.dc.html" class="g27 bas" style="flex: none; height: 104px; border-radius: 26px; padding: 12px 14px; display: flex; align-items: center; gap: 12px; color: #12302A">
    <span style="position: relative; flex: none; display: flex; gap: 2px; align-items: flex-end">
       <svg width="58" height="68" viewBox="6 22 88 103" aria-hidden="true">''' + paths('m1') + '''</svg>
       <svg width="58" height="68" viewBox="6 22 88 103" aria-hidden="true">''' + paths('m2') + '''</svg>
    </span>
    <span style="position: relative; flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 6px">
      <span style="display: flex; justify-content: space-between; align-items: baseline"><span style="font-size: 15px; font-weight: 800">Bugünkü bahçe</span><span style="font-size: 12px; font-weight: 800; color: rgba(18,48,42,.6)">45 / 60 dk</span></span>
      <span style="height: 8px; border-radius: 4px; background: rgba(18,48,42,.10); overflow: hidden"><span style="display: block; width: 75%; height: 8px; border-radius: 4px; background: linear-gradient(90deg, #57D67E, #1BA552)"></span></span>
      <span style="font-size: 12px; line-height: 16px; font-weight: 600; color: rgba(18,48,42,.7)">Gül · Yâsîn 30 dk, Turunç · Kehf 15 dk. 15 dk daha ile hedef tamam.</span>
    </span>
  </a>

  <a href="HadisHikmet.dc.html" class="g27 bas" style="flex: none; border-radius: 26px; padding: 14px 16px; display: flex; flex-direction: column; gap: 6px; background: linear-gradient(165deg, rgba(255,253,246,.9), rgba(247,240,224,.8)); color: #2A2416">
    <span style="position: relative; font-size: 10.5px; font-weight: 800; letter-spacing: 1px; color: #9A6A00">GÜNÜN SÖZÜ · {{s.kisi}}</span>
    <span style="position: relative; font-family: Newsreader, Georgia, serif; font-size: 18px; line-height: 24px; font-weight: 500; color: #1E190E">“{{s.soz}}”</span>
    <span style="position: relative; font-size: 11px; font-weight: 700; color: #7A6A48">{{s.kaynak}}</span>
  </a>

  <div style="flex: none; display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 8px">
    <a href="IhyaOdak.dc.html" class="g27 bas" style="height: 46px; border-radius: 23px; display: flex; align-items: center; justify-content: center; gap: 6px; font-size: 13px; font-weight: 800; color: #0E6A33"><span style="position: relative">Odaklan</span></a>
    <a href="OdakSesleri.dc.html" class="g27 bas" style="height: 46px; border-radius: 23px; display: flex; align-items: center; justify-content: center; gap: 6px; font-size: 13px; font-weight: 800; color: #1F4E8C"><span style="position: relative">Sesler</span></a>
    <a href="OkumaModu.dc.html" class="g27 bas" style="height: 46px; border-radius: 23px; display: flex; align-items: center; justify-content: center; gap: 6px; font-size: 13px; font-weight: 800; color: #5A3A10"><span style="position: relative">Oku</span></a>
  </div>
  </div>

''' + tabbar('Bugün') + '''
</div>
'''

script = r'''
var VRAW = /*VAKIT_JSON_START*/''' + json.dumps(V, ensure_ascii=False) + r'''/*VAKIT_JSON_END*/;
var VAKIT = VRAW.map(function (v) { return { t: v.tarih, h: v.hicri, v: [v.imsak, v.gunes, v.ogle, v.ikindi, v.aksam, v.yatsi] }; });
var SOZ = ''' + json.dumps(SOZ, ensure_ascii=False) + r''';
var AD = ['İmsak', 'Güneş', 'Öğle', 'İkindi', 'Akşam', 'Yatsı'];
var FARZ = [['Sabah', 0], ['Öğle', 2], ['İkindi', 3], ['Akşam', 4], ['Yatsı', 5]];
var GUN = ['PAZAR', 'PAZARTESİ', 'SALI', 'ÇARŞAMBA', 'PERŞEMBE', 'CUMA', 'CUMARTESİ'], AY = ['OCAK', 'ŞUBAT', 'MART', 'NİSAN', 'MAYIS', 'HAZİRAN', 'TEMMUZ', 'AĞUSTOS', 'EYLÜL', 'EKİM', 'KASIM', 'ARALIK'];
function tkey(d) { return ('0' + d.getDate()).slice(-2) + '.' + ('0' + (d.getMonth() + 1)).slice(-2) + '.' + d.getFullYear(); }
function bul(d) { var k = tkey(d); for (var i = 0; i < VAKIT.length; i++) if (VAKIT[i].t === k) return i; return 0; }
function sn(s) { var p = s.split(':'); return Number(p[0]) * 3600 + Number(p[1]) * 60; }
function hkisa(h) { var p = h.split(' '); return p[0] + ' ' + ({ Cemaziyelevvel: 'C.EVVEL', Cemaziyelahir: 'C.ÂHİR', Rebiulevvel: 'R.EVVEL', Rebiulahir: 'R.ÂHİR' }[p[1]] || p[1].toLocaleUpperCase('tr-TR')) + ' ' + p[2]; }
function iki(n) { return ('0' + n).slice(-2); }
function siradaki(d) { var g = VAKIT[bul(d)], t = d.getHours() * 3600 + d.getMinutes() * 60 + d.getSeconds(); for (var j = 0; j < 6; j++) if (sn(g.v[j]) > t) return j; return -1; }
class Component extends DCLogic {
  constructor(p) { super(p); var k0 = siradaki(new Date()); this.state = { now: Date.now(), kildi: FARZ.map(function (f, n) { return k0 < 0 ? n < 4 : f[1] + 1 < k0; }) }; var d = new Date(); this.gun = Math.floor((d - new Date(d.getFullYear(), 0, 0)) / 86400000); }
  componentDidMount() { var self = this; this.iv = setInterval(function () { self.setState({ now: Date.now() }); }, 1000); }
  componentWillUnmount() { clearInterval(this.iv); }
  renderVals() {
    var self = this, s = this.state, d = new Date(s.now), i = bul(d), g = VAKIT[i], yarin = VAKIT[Math.min(i + 1, VAKIT.length - 1)];
    var t = d.getHours() * 3600 + d.getMinutes() * 60 + d.getSeconds();
    var k = -1; for (var j = 0; j < 6; j++) if (sn(g.v[j]) > t) { k = j; break; }
    var hedef = k >= 0 ? sn(g.v[k]) : 86400 + sn(yarin.v[0]), kalan = Math.max(0, hedef - t);
    var cizgi = AD.map(function (a, j) { var gecti = k < 0 || j < k, cur = j === k; return { ad: a, saat: g.v[j], bar: gecti ? 'linear-gradient(90deg,#57D67E,#1BA552)' : cur ? 'linear-gradient(90deg,#FFC65C,#FF9F43)' : 'rgba(18,48,42,.12)', color: cur ? '#C25E00' : gecti ? '#0E6A33' : 'rgba(18,48,42,.6)' }; });
    var farz = FARZ.map(function (f, n) { var on = s.kildi[n], vakti = k < 0 || f[1] < k; return { ad: f[0], on: on ? 'true' : 'false', bg: on ? 'linear-gradient(180deg, rgba(96,236,150,.95), rgba(20,158,82,.92))' : 'rgba(255,255,255,.45)', color: on ? '#FFFFFF' : vakti ? '#C25E00' : 'rgba(18,48,42,.55)', sh: on ? 'inset 0 1px 0 rgba(255,255,255,.8), 0 6px 14px rgba(20,150,70,.3)' : 'inset 0 0 0 1px rgba(18,48,42,.08)', ikon: on ? 'M5 12.5l4.2 4.2L19 7' : 'M12 5.6a6.4 6.4 0 1 1 0 12.8a6.4 6.4 0 1 1 0-12.8Z', tap: function () { var a = self.state.kildi.slice(); a[n] = !a[n]; self.setState({ kildi: a }); } }; });
    var h = d.getHours(), selam = h < 5 ? 'Hayırlı geceler' : h < 11 ? 'Hayırlı sabahlar' : h < 17 ? 'Hayırlı günler' : h < 21 ? 'Hayırlı akşamlar' : 'Hayırlı geceler';
    var soz = SOZ[this.gun % SOZ.length];
    return {
      tarih: GUN[d.getDay()] + ' · ' + d.getDate() + ' ' + AY[d.getMonth()] + ' · ' + hkisa(g.h), selam: selam,
      sonraki: k >= 0 ? AD[k] : 'İmsak (yarın)', sonrakiSaat: k >= 0 ? g.v[k] : yarin.v[0], geri: iki(Math.floor(kalan / 3600)) + ':' + iki(Math.floor(kalan % 3600 / 60)) + ':' + iki(kalan % 60),
      cizgi: cizgi, farz: farz, kilinan: s.kildi.filter(Boolean).length, s: soz,
      m1: bitkiCiz('gul', 30, 3, { lod: 0.7 }), m2: bitkiCiz('turunc', 15, 7, { lod: 0.7 })
    };
  }
}
'''
html = page('İhya · Bugün', 390, 844, body, script)
open(OUT + 'IhyaBugun.dc.html', 'w').write(html)
print('ok', len(html), len(SOZ))
