from common import *
rows = json.load(open(B + 'data/vakit/vakitler_bursa.json'))
meta = {"sehir": "Bursa · Yıldırım", "ilceId": 9335, "guncelleme": "2026-11-03", "sonraki": "2026-11-05"}

body = '''
<div style="position: relative; width: 390px; height: 844px; overflow: hidden; font-family: Inter, -apple-system, system-ui, sans-serif; color: #0F2233; background: linear-gradient(180deg, #F4B97A 0%, #F8D9B0 24%, #EADFF0 52%, #DCE6F5 100%)">
  <div aria-hidden="true" style="position: absolute; left: 50%; top: 40px; width: 260px; height: 260px; margin-left: -130px; border-radius: 130px; background: radial-gradient(circle, rgba(255,240,200,.9), rgba(255,210,140,0) 70%)"></div>
  <div aria-hidden="true" style="position: absolute; left: -70px; top: 380px; width: 260px; height: 260px; border-radius: 130px; background: radial-gradient(circle, rgba(255,150,90,.55), rgba(255,150,90,0) 68%)"></div>
  <div aria-hidden="true" style="position: absolute; right: -80px; top: 520px; width: 280px; height: 280px; border-radius: 140px; background: radial-gradient(circle, rgba(110,160,255,.5), rgba(110,160,255,0) 68%)"></div>
  <div aria-hidden="true" style="position: absolute; left: 60px; top: 700px; width: 240px; height: 240px; border-radius: 120px; background: radial-gradient(circle, rgba(140,220,170,.5), rgba(140,220,170,0) 68%)"></div>
  <div style="position: absolute; left: 20px; right: 20px; top: 56px; display: flex; justify-content: space-between; align-items: flex-end">
    <div style="display: flex; flex-direction: column; gap: 2px">
      <span style="font-size: 13px; font-weight: 700; color: rgba(15,34,51,.6)">{{sehir}} · Diyanet</span>
      <h1 style="margin: 0; font-size: 34px; line-height: 40px; font-weight: 800; letter-spacing: -.6px">Vakitler</h1>
    </div>
    <span class="g27" style="height: 34px; padding: 0 12px; border-radius: 17px; font-size: 12.5px; font-weight: 800; color: #6A3A00; display: flex; align-items: center; white-space: nowrap"><span style="position: relative">{{hicri}}</span></span>
  </div>

  <section class="g27" aria-label="Bugünün vakitleri" style="position: absolute; left: 16px; right: 16px; top: 128px; border-radius: 30px; padding: 16px">
    <div style="position: relative; display: flex; justify-content: space-between; align-items: baseline">
      <span style="font-size: 15px; font-weight: 800">{{nextName}} vaktine</span>
      <span style="font-size: 13px; font-weight: 700; color: #6A4A20">{{todayLabel}}</span>
    </div>
    <div style="position: relative; font-size: 46px; line-height: 54px; font-weight: 800; letter-spacing: -1px; font-variant-numeric: tabular-nums">{{countdown}}</div>
    <div style="position: relative; display: grid; grid-template-columns: repeat(6, minmax(0, 1fr)); gap: 4px; margin-top: 6px">
      <sc-for list="{{todayTimes}}" as="v">
        <div style="height: 58px; border-radius: 16px; background: {{v.bg}}; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 2px; box-shadow: {{v.sh}}">
          <span style="font-size: 10.5px; font-weight: 800; color: {{v.lc}}">{{v.ad}}</span>
          <span style="font-size: 14px; font-weight: 800; color: {{v.tc}}; font-variant-numeric: tabular-nums">{{v.saat}}</span>
        </div>
      </sc-for>
    </div>
  </section>

  <section aria-label="30 günlük cetvel" class="g27" style="position: absolute; left: 16px; right: 16px; top: 334px; bottom: 108px; border-radius: 28px; overflow: hidden">
    <div style="position: absolute; left: 0; right: 0; top: 0; z-index: 2; height: 38px; display: grid; border-bottom: .5px solid rgba(255,255,255,.7); -webkit-backdrop-filter: blur(12px); backdrop-filter: blur(12px); grid-template-columns: 62px repeat(6, minmax(0, 1fr)); align-items: center; padding: 0 10px; font-size: 10.5px; font-weight: 800; color: #4A5A6A; background: rgba(255,255,255,.45)">
      <span style="position: relative">Tarih</span><span style="position: relative; text-align: center">İmsak</span><span style="position: relative; text-align: center">Güneş</span><span style="position: relative; text-align: center">Öğle</span><span style="position: relative; text-align: center">İkindi</span><span style="position: relative; text-align: center">Akşam</span><span style="position: relative; text-align: center">Yatsı</span>
    </div>
    <div class="dikey" style="position: absolute; left: 0; right: 0; top: 38px; bottom: 0">
      <sc-for list="{{rows}}" as="r">
        <div style="height: 40px; display: grid; grid-template-columns: 62px repeat(6, minmax(0, 1fr)); align-items: center; padding: 0 10px; font-size: 12.5px; font-variant-numeric: tabular-nums; background: {{r.bg}}; border-bottom: .5px solid rgba(255,255,255,.55); color: {{r.c}}">
          <span style="display: flex; flex-direction: column; line-height: 14px"><b style="font-size: 12px">{{r.gun}}</b><span style="font-size: 9.5px; color: #7A8A9A">{{r.hg}}</span></span>
          <span style="text-align: center">{{r.imsak}}</span><span style="text-align: center">{{r.gunes}}</span><span style="text-align: center">{{r.ogle}}</span><span style="text-align: center">{{r.ikindi}}</span><span style="text-align: center">{{r.aksam}}</span><span style="text-align: center">{{r.yatsi}}{{r.mark}}</span>
        </div>
      </sc-for>
      <p style="margin: 0; padding: 12px 14px 16px; font-size: 11.5px; line-height: 16px; color: #3E4E5E">Kaynak: Diyanet İşleri Başkanlığı, Bursa merkez (ilçe no 9335; Yıldırım, Osmangazi ve Nilüfer bu cetvele dahil). Uygulama 30 günlük cetveli telefonda saklar, gün aşırı yeniler; internet yoksa Diyanet yöntemiyle hesaplar (±1 dk). * işaretli günler Diyanet yayımlayana kadar hesaplanmış değerdir.</p>
    </div>
  </section>

  <div style="position: absolute; left: 22px; right: 22px; top: 308px; display: flex; align-items: center; gap: 8px">
    <svg width="16" height="16" viewBox="0 0 22 22" aria-hidden="true"><circle cx="11" cy="11" r="9.5" fill="none" stroke="#1BA552" stroke-width="2"></circle><path d="M6.5 11.5l3 3 6-6.5" fill="none" stroke="#1BA552" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"></path></svg>
    <span style="flex: 1; min-width: 0; font-size: 11.5px; font-weight: 700; line-height: 15px; color: #1D3A2A; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">Güncellendi {{guncel}} · sonraki {{sonraki}} · {{kapsam}}</span>
  </div>
''' + tabbar('Vakit') + '''
</div>
'''

script = r'''
var VAKIT = /*VAKIT_JSON_START*/''' + json.dumps(rows, ensure_ascii=False) + r'''/*VAKIT_JSON_END*/;
var VMETA = /*VAKIT_META_START*/''' + json.dumps(meta, ensure_ascii=False) + r'''/*VAKIT_META_END*/;
var AD = ['İmsak', 'Güneş', 'Öğle', 'İkindi', 'Akşam', 'Yatsı'], KEY = ['imsak', 'gunes', 'ogle', 'ikindi', 'aksam', 'yatsi'];
var AY = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'], GUN = ['Paz', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt'];
function tr(d) { var p = d.split('.'); return new Date(Number(p[2]), Number(p[1]) - 1, Number(p[0])); }
function iso(s) { var p = s.split('-'); return Number(p[2]) + ' ' + AY[Number(p[1]) - 1]; }
function mins(h) { var p = h.split(':'); return Number(p[0]) * 60 + Number(p[1]); }
class Component extends DCLogic {
  constructor(p) { super(p); this.state = { now: Date.now() }; }
  componentDidMount() { var self = this; this.iv = setInterval(function () { self.setState({ now: Date.now() }); }, 30000); }
  componentWillUnmount() { clearInterval(this.iv); }
  renderVals() {
    var now = new Date(this.state.now), key = ('0' + now.getDate()).slice(-2) + '.' + ('0' + (now.getMonth() + 1)).slice(-2) + '.' + now.getFullYear();
    var idx = -1; for (var i = 0; i < VAKIT.length; i++) if (VAKIT[i].tarih === key) idx = i;
    var nowMin = now.getHours() * 60 + now.getMinutes();
    if (idx < 0) { idx = 0; nowMin = 7 * 60 + 29; }
    var T = VAKIT[idx], nx = -1;
    for (var k = 0; k < 6; k++) if (mins(T[KEY[k]]) > nowMin) { nx = k; break; }
    var diff = nx >= 0 ? mins(T[KEY[nx]]) - nowMin : (24 * 60 - nowMin) + mins((VAKIT[idx + 1] || T).imsak);
    var nextName = nx >= 0 ? AD[nx] : 'İmsak';
    var todayTimes = AD.map(function (a, k) { var on = k === nx; var past = nx >= 0 ? k < nx : true; return { ad: a, saat: T[KEY[k]], bg: on ? 'linear-gradient(180deg,#FFB347,#F07A1A)' : 'rgba(255,255,255,.4)', tc: on ? '#FFFFFF' : (past ? '#8A96A2' : '#0F2233'), lc: on ? 'rgba(255,255,255,.92)' : '#5A6A7A', sh: on ? '0 6px 16px rgba(240,122,26,.35), inset 0 1px 0 rgba(255,255,255,.6)' : 'inset 0 1px 0 rgba(255,255,255,.8)' }; });
    var rows = VAKIT.map(function (r, k) { var d = tr(r.tarih); var hp = r.hicri.split(' '); return { gun: d.getDate() + ' ' + AY[d.getMonth()] + ' ' + GUN[d.getDay()].slice(0, 2), hg: hp[0] + ' ' + ({ Cemaziyelevvel: 'C.evvel', Cemaziyelahir: 'C.âhir', Rebiulevvel: 'R.evvel', Rebiulahir: 'R.âhir' }[hp[1]] || hp[1]), imsak: r.imsak, gunes: r.gunes, ogle: r.ogle, ikindi: r.ikindi, aksam: r.aksam, yatsi: r.yatsi, mark: r.kaynak === 'Diyanet' ? '' : '*', bg: k === idx ? 'linear-gradient(90deg, rgba(255,179,71,.55), rgba(255,179,71,.2))' : (d.getDay() === 5 ? 'rgba(120,220,150,.18)' : 'transparent'), c: k < idx ? 'rgba(15,34,51,.4)' : '#0F2233' }; });
    var first = tr(VAKIT[0].tarih), last = tr(VAKIT[VAKIT.length - 1].tarih);
    var hp0 = T.hicri.split(' '); return { sehir: VMETA.sehir, hicri: hp0[0] + ' ' + ({ Cemaziyelevvel: 'Cemâziyelevvel', Cemaziyelahir: 'Cemâziyelâhir' }[hp0[1]] || hp0[1]), todayLabel: GUN[tr(T.tarih).getDay()] + ', ' + tr(T.tarih).getDate() + ' ' + AY[tr(T.tarih).getMonth()],
      nextName: nextName, countdown: Math.floor(diff / 60) + ' sa ' + (diff % 60) + ' dk', todayTimes: todayTimes, rows: rows,
      guncel: iso(VMETA.guncelleme), sonraki: iso(VMETA.sonraki), kapsam: VAKIT.length + ' gün telefonda' };
  }
}
'''
html = page('İhya · Vakit cetveli', 390, 844, body, script).replace(ENGINE, '')
open(OUT + 'VakitCetveli.dc.html', 'w').write(html)
print('ok', len(html))
