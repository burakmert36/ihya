from common import *

body = DEFS + '''
<div style="position: relative; width: 390px; height: 844px; overflow: hidden; font-family: Inter, -apple-system, system-ui, sans-serif; color: #F2FFF6; background: radial-gradient(120% 60% at 50% 38%, #1F6B5A 0%, #11403A 45%, #08201E 100%)">
  <div aria-hidden="true" style="position: absolute; left: -60px; top: 120px; width: 300px; height: 300px; border-radius: 150px; background: radial-gradient(circle, rgba(90,255,190,.20), rgba(90,255,190,0) 70%)"></div>
  <div aria-hidden="true" style="position: absolute; right: -80px; top: 300px; width: 320px; height: 320px; border-radius: 160px; background: radial-gradient(circle, rgba(120,200,255,.16), rgba(120,200,255,0) 70%)"></div>

  <div style="position: absolute; left: 16px; right: 16px; top: 54px; display: flex; flex-direction: column; gap: 8px">
    <div role="tablist" aria-label="Oturum türü" class="g27k" style="height: 44px; border-radius: 22px; display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); padding: 4px">
      <sc-for list="{{acts}}" as="a">
        <button role="tab" aria-selected="{{a.on}}" onClick="{{a.pick}}" class="bas" style="position: relative; height: 36px; border-radius: 18px; background: {{a.bg}}; color: {{a.color}}; font-size: 13px; font-weight: 800; box-shadow: {{a.sh}}"><span style="position: relative">{{a.label}}</span></button>
      </sc-for>
    </div>
    <div style="display: flex; align-items: center; justify-content: space-between; gap: 8px">
      <span style="font-size: 12px; font-weight: 600; color: rgba(225,255,236,.8); flex: 1; min-width: 0; line-height: 15px">{{actNote}}</span>
      <a href="OdakSesleri.dc.html" class="g27k bas" aria-label="Odak sesleri" style="flex: none; height: 34px; padding: 0 12px; border-radius: 17px; display: flex; align-items: center; gap: 6px; font-size: 12.5px; font-weight: 800; color: #E8FFF0"><svg width="16" height="14" viewBox="0 0 16 14" aria-hidden="true" style="position: relative"><path d="M1 5h3l4-4v12L4 9H1Z" fill="#E8FFF0"></path><path d="M11 4c1.3 1.6 1.3 4.4 0 6M13.4 2c2.2 2.8 2.2 7.2 0 10" stroke="#9CF5BE" stroke-width="1.6" fill="none" stroke-linecap="round"></path></svg><span style="position: relative">Yağmurlu gece</span></a>
    </div>
  </div>

  <sc-if value="{{warn}}">
    <div class="g27k yuk" role="alert" style="position: absolute; left: 16px; right: 16px; top: 134px; z-index: 5; border-radius: 22px; padding: 10px 12px; display: flex; align-items: center; gap: 10px; background: rgba(120,40,20,.45)">
      <span style="position: relative; width: 34px; height: 34px; border-radius: 17px; background: #FF9A5A; color: #3A1200; font-size: 16px; font-weight: 800; display: flex; align-items: center; justify-content: center">{{warnLeft}}</span>
      <span style="position: relative; flex: 1; font-size: 13px; font-weight: 700; line-height: 17px">Uygulamadan çıktın. {{warnLeft}} sn içinde dönmezsen fidan kurur.</span>
      <button class="g27t bas" onClick="{{comeBack}}" style="height: 34px; padding: 0 12px; border-radius: 17px; font-size: 13px; font-weight: 800">Döndüm</button>
    </div>
  </sc-if>

  <div style="position: absolute; left: 50%; top: 146px; width: 250px; margin-left: -125px; height: 290px">
    <div aria-hidden="true" style="position: absolute; left: 0; top: 0; width: 250px; height: 270px; border-radius: 125px 125px 36px 36px; background: radial-gradient(70% 55% at 50% 60%, {{halo}}, rgba(120,255,180,0) 70%)"></div>
    <div class="g27k" aria-hidden="true" style="position: absolute; left: 14px; top: 8px; width: 222px; height: 254px; border-radius: 111px 111px 30px 30px; background: linear-gradient(180deg, rgba(255,255,255,.12), rgba(255,255,255,.03))"></div>
    <svg role="img" aria-label="{{plantLabel}}" width="200" height="240" viewBox="{{vb}}" style="position: absolute; left: 25px; top: 22px">
      <g class="{{swayCls}}">''' + paths('shapes') + '''</g>
    </svg>
    <div aria-hidden="true" style="position: absolute; left: 4px; top: 254px; width: 242px; height: 30px; border-radius: 15px; background: linear-gradient(180deg, #8A5E3C, #4A2F1E); box-shadow: inset 0 2px 1px rgba(255,220,180,.35), 0 10px 20px rgba(0,0,0,.4)"></div>
  </div>

  <div style="position: absolute; left: 16px; right: 16px; top: 440px; display: flex; flex-direction: column; align-items: center; gap: 2px">
    <span style="font-size: 13px; font-weight: 800; letter-spacing: 1.2px; color: #9CF5BE">{{stageTitle}}</span>
    <span class="g27k" style="font-size: 50px; line-height: 58px; font-weight: 800; letter-spacing: -1.5px; font-variant-numeric: tabular-nums; padding: 0 22px; border-radius: 29px; margin: 4px 0"><span style="position: relative">{{clock}}</span></span>
    <span style="font-size: 13px; font-weight: 600; color: rgba(225,255,236,.75)">{{nextText}}</span>
  </div>

  <div style="position: absolute; left: 20px; right: 20px; top: 560px; display: flex; gap: 4px">
    <sc-for list="{{stages}}" as="e">
      <div style="flex: {{e.flex}}; min-width: 0; display: flex; flex-direction: column; gap: 5px">
        <div style="height: 7px; border-radius: 4px; background: rgba(255,255,255,.14); overflow: hidden"><div style="width: {{e.fill}}; height: 100%; border-radius: 4px; background: linear-gradient(90deg, #7CF0A4, #22C463)"></div></div>
        <span style="font-size: 10.5px; font-weight: 800; color: {{e.color}}; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">{{e.ad}}</span>
        <span style="font-size: 10px; font-weight: 600; color: rgba(225,255,236,.6)">{{e.aralik}}</span>
      </div>
    </sc-for>
  </div>

  <sc-if value="{{idle}}">
    <div class="g27k" style="position: absolute; left: 12px; right: 12px; top: 612px; height: 50px; border-radius: 25px; display: flex; align-items: center; gap: 8px; padding: 0 6px">
      <button class="g27k bas" onClick="{{minus}}" aria-label="Süreyi 5 dakika azalt" style="width: 38px; height: 38px; border-radius: 19px; color: #F2FFF6; font-size: 20px; font-weight: 700"><span style="position: relative">−</span></button>
      <input type="range" min="10" max="120" step="5" value="{{durStr}}" onInput="{{setDur}}" aria-label="Oturum süresi" style="position: relative; flex: 1; accent-color: #3FE08A">
      <span style="position: relative; width: 58px; text-align: center; font-size: 16px; font-weight: 800; font-variant-numeric: tabular-nums">{{durStr}} dk</span>
      <button class="g27k bas" onClick="{{plus}}" aria-label="Süreyi 5 dakika artır" style="width: 38px; height: 38px; border-radius: 19px; color: #F2FFF6; font-size: 20px; font-weight: 700"><span style="position: relative">+</span></button>
    </div>
    <div class="g27k" style="position: absolute; left: 12px; right: 12px; top: 670px; height: 76px; border-radius: 26px; overflow: hidden">
     <div class="yatay" onWheel="{{yatayTeker}}" style="position: relative; height: 76px; padding: 6px; gap: 6px; scroll-padding-inline: 6px">
      <sc-for list="{{species}}" as="q">
        <button onClick="{{q.pick}}" aria-pressed="{{q.on}}" aria-label="{{q.label}}" class="bas" style="position: relative; flex: none; width: 58px; height: 64px; border-radius: 20px; background: {{q.bg}}; box-shadow: {{q.sh}}; opacity: {{q.op}}; display: flex; flex-direction: column; align-items: center; justify-content: flex-end; padding-bottom: 4px">
          <svg width="40" height="44" viewBox="{{q.vb}}" aria-hidden="true">''' + paths('q.mini') + '''</svg>
          <span style="font-size: 10px; font-weight: 800; color: #E8FFF0; position: relative">{{q.dk}}</span>
        </button>
      </sc-for>
     </div>
    </div>
  </sc-if>
  <sc-if value="{{notIdle}}">
    <div style="position: absolute; left: 16px; right: 16px; top: 624px; display: flex; flex-direction: column; gap: 8px; align-items: center">
      <input type="range" min="0" max="{{durStr}}" step="0.5" value="{{dkStr}}" onInput="{{scrub}}" aria-label="Önizleme: zamanı kaydır" style="width: 100%; accent-color: #3FE08A">
      <button onClick="{{leave}}" style="background: transparent; color: rgba(225,255,236,.7); font-size: 12px; font-weight: 700">Önizleme 60× · kaydır ya da uygulamadan çıkmayı dene</button>
    </div>
  </sc-if>

  <div style="position: absolute; left: 16px; right: 16px; bottom: 26px; display: flex; gap: 10px">
    <sc-for list="{{buttons}}" as="b">
      <a href="{{b.href}}" onClick="{{b.act}}" class="{{b.cls}} bas" style="flex: {{b.flex}}; height: 60px; border-radius: 30px; display: flex; align-items: center; justify-content: center; font-size: 16px; font-weight: 800; letter-spacing: .6px; color: #FFFFFF"><span style="position: relative">{{b.label}}</span></a>
    </sc-for>
  </div>
</div>
'''

script = YATAY_JS + r'''
var ACTS = [['Kur’an', 'Mushaf açık · 3 dk dokunmazsan duraklar', 'turunc'], ['Dinle', 'Ses arka planda çalar; dinlerken fidan kurumaz', 'lavanta'], ['Kitap', 'İhyâ · s. 212’den devam', 'zeytin'], ['Zikir', 'Her 33 tesbih fidana bir damla su', 'gul'], ['Serbest', 'Tefekkür, ders, ezber', 'lale']];
var LOCK = { hurma: '30 günlük seride açılır (18 gün kaldı)', cinar: '100 saat odakta açılır (54 saat kaldı)' };
var ICON = { menekse: '20 52 60 72', lale: '14 34 72 86', reyhan: '16 40 68 82', sumbul: '16 40 68 82', gul: '12 30 76 90', lavanta: '10 32 80 90', badem: '6 14 88 104', servi: '6 4 88 108', turunc: '6 18 88 100', nar: '6 18 88 100', zeytin: '4 16 92 102', hurma: '0 4 100 112', cinar: '0 8 100 110' };
var KUBBE = '-12 -24 124 149';
class Component extends DCLogic {
  constructor(p) { super(p); this.state = { act: 0, sp: 'gul', dur: 30, mode: 'idle', dk: 0, warnLeft: 10, revived: false }; this.minis = {}; var self = this; BITKI_SIRA.forEach(function (t) { self.minis[t] = bitkiTemel(t, BITKI[t].dk, 3, { lod: 0.35 }); }); }
  componentDidMount() {
    var self = this;
    this.timer = setInterval(function () { var s = self.state; if (s.mode === 'run' || s.mode === 'warn') { var d = s.dk + 0.1; if (d >= s.dur) self.setState({ dk: s.dur, mode: 'done' }); else self.setState({ dk: d }); } }, 100);
    this.warnTimer = setInterval(function () { var s = self.state; if (s.mode === 'warn') { if (s.warnLeft <= 1) self.setState({ mode: 'dry', warnLeft: 10 }); else self.setState({ warnLeft: s.warnLeft - 1 }); } }, 1000);
  }
  componentWillUnmount() { clearInterval(this.timer); clearInterval(this.warnTimer); }
  renderVals() {
    var self = this, s = this.state, b = BITKI[s.sp], dur = s.dur, dk = s.mode === 'idle' ? dur : s.dk;
    var E = bitkiEvre(s.sp, Math.min(dk, BITKI_MAX - 0.001));
    var shapes = bitkiCiz(s.sp, dk, 11, { lod: 1 });
    if (s.mode === 'dry') shapes = shapes.map(function (q) { return { d: q.d, f: q.f === 'none' ? 'none' : (q.f.indexOf('Golge') > 0 ? q.f : 'url(#gKuru)'), s: q.s === 'none' ? 'none' : '#8E7A60', w: q.w, o: q.o }; });
    var rem = Math.max(0, dur - dk), mm = Math.floor(rem), ss = Math.round((rem - mm) * 60); if (ss === 60) { mm += 1; ss = 0; }
    var clock = s.mode === 'idle' ? dur + ':00' : (mm + ':' + (ss < 10 ? '0' : '') + ss);
    var hedef = bitkiOzet(s.sp, dur);
    var stageTitle = s.mode === 'idle' ? (dur + ' DK SONUNDA · ' + hedef.split(' · ')[0].toLocaleUpperCase('tr')) : s.mode === 'dry' ? 'KURU DAL' : s.mode === 'done' ? (s.revived ? 'İHYA EDİLDİ' : 'BAHÇEYE HAZIR') : (E.ad.toLocaleUpperCase('tr') + ' · ' + Math.floor(dk) + '/' + dur + ' DK');
    var nextText = s.mode === 'idle' ? 'Süreyi artırdıkça bitki büyür: ' + hedef.split(' · ').slice(1).join(' · ') : s.mode === 'dry' ? 'Aynı süreyle bir oturum bu dalı yeniden yeşertir' : s.mode === 'done' ? hedef + ' · bahçende bir yer seç' : (E.sonraki && E.kalan > 0 && dur > dk + E.kalan - 0.01 ? E.sonraki + ' evresine ' + E.kalan + ' dk' : 'Hedef: ' + hedef.split(' · ')[0] + ' · ' + Math.ceil(rem) + ' dk');
    if (s.mode === 'idle' && hedef.indexOf('tam formuna') > 0) nextText = hedef.split(' · ')[1];
    var stages = b.evre.filter(function (e) { return e[1] < dur; }).map(function (e) { var a = e[1], z = Math.min(e[2], dur); var fill = s.mode === 'idle' ? 0 : Math.max(0, Math.min(1, (dk - a) / (z - a))); var cur = s.mode !== 'idle' && dk >= a && dk < z; return { ad: e[0], aralik: a + '–' + z + ' dk', flex: String(z - a), fill: Math.round(fill * 100) + '%', color: cur ? '#9CF5BE' : 'rgba(235,255,242,.85)' }; });
    var start = function () { self.setState({ mode: 'run', dk: 0, revived: s.mode === 'dry' }); };
    var buttons;
    if (s.mode === 'idle') buttons = [{ label: 'BAŞLAT · ' + dur + ' dk', cls: 'g27t', flex: '1', href: '#', act: start }];
    else if (s.mode === 'run') buttons = [{ label: 'Mola · 5 dk', cls: 'g27k', flex: '1', href: '#', act: function () { self.setState({ mode: 'pause' }); } }, { label: 'Bitir', cls: 'g27k', flex: '1', href: '#', act: function () { self.setState({ mode: 'dry' }); } }];
    else if (s.mode === 'pause') buttons = [{ label: 'DEVAM', cls: 'g27t', flex: '1.4', href: '#', act: function () { self.setState({ mode: 'run' }); } }, { label: 'Bitir', cls: 'g27k', flex: '1', href: '#', act: function () { self.setState({ mode: 'dry' }); } }];
    else if (s.mode === 'warn') buttons = [{ label: 'DÖNDÜM', cls: 'g27t', flex: '1', href: '#', act: function () { self.setState({ mode: 'run', warnLeft: 10 }); } }];
    else if (s.mode === 'dry') buttons = [{ label: 'İHYA ET · ' + dur + ' dk', cls: 'g27t', flex: '1.5', href: '#', act: start }, { label: 'Bahçe', cls: 'g27k', flex: '1', href: 'IhyaBahce.dc.html', act: function () {} }];
    else buttons = [{ label: 'BAHÇEYE DİK', cls: 'g27t', flex: '1', href: 'IhyaBahce.dc.html', act: function () {} }];
    buttons.forEach(function (x) { var a = x.act; x.act = function (ev) { if (x.href === '#' && ev && ev.preventDefault) ev.preventDefault(); a(); }; });
    var acts = ACTS.map(function (a, i) { var on = s.act === i; return { label: a[0], on: on ? 'true' : 'false', bg: on ? 'rgba(255,255,255,.92)' : 'transparent', color: on ? '#0D3B28' : '#E8FFF0', sh: on ? '0 2px 8px rgba(0,0,0,.25)' : 'none', pick: function () { if (self.state.mode === 'idle') self.setState({ act: i, sp: a[2] }); } }; });
    var species = BITKI_SIRA.map(function (t) { var on = s.sp === t, lk = LOCK[t]; return { label: BITKI[t].ad + (lk ? ', kilitli: ' + lk : ''), dk: lk ? 'kilitli' : BITKI[t].ad, mini: self.minis[t], vb: ICON[t], on: on ? 'true' : 'false', bg: on ? 'rgba(255,255,255,.26)' : 'rgba(255,255,255,.05)', sh: on ? 'inset 0 1px 0 rgba(255,255,255,.7), 0 0 0 1.5px #7CF0A4' : 'none', op: lk ? '0.45' : '1', pick: function () { if (!lk) self.setState({ sp: t }); } }; });
    function setDur(v) { v = Math.max(10, Math.min(120, Math.round(v / 5) * 5)); self.setState({ dur: v }); }
    return {
      yatayTeker: yatayTeker,
      acts: acts, actNote: ACTS[s.act][1],
      warn: s.mode === 'warn', warnLeft: s.warnLeft, comeBack: function () { self.setState({ mode: 'run', warnLeft: 10 }); },
      halo: s.mode === 'dry' ? 'rgba(200,170,120,.25)' : s.mode === 'done' || (s.mode !== 'idle' && rem < 2) ? 'rgba(170,255,200,.6)' : 'rgba(120,255,180,.28)',
      shapes: shapes, vb: KUBBE, swayCls: s.mode === 'dry' ? '' : 'sal', plantLabel: b.ad + ', ' + (s.mode === 'dry' ? 'kurumuş' : E.ad),
      stageTitle: stageTitle, clock: clock, nextText: nextText, stages: stages,
      idle: s.mode === 'idle', notIdle: s.mode !== 'idle', species: species, durStr: String(dur), dkStr: String(Math.round(dk * 2) / 2),
      minus: function () { setDur(self.state.dur - 5); }, plus: function () { setDur(self.state.dur + 5); }, setDur: function (ev) { setDur(Number(ev && ev.target ? ev.target.value : 30)); },
      scrub: function (ev) { var v = Number(ev && ev.target ? ev.target.value : 0); if (self.state.mode !== 'idle') self.setState({ dk: v, mode: v >= self.state.dur ? 'done' : (self.state.mode === 'done' ? 'run' : self.state.mode) }); },
      leave: function () { if (self.state.mode === 'run') self.setState({ mode: 'warn', warnLeft: 10 }); },
      buttons: buttons
    };
  }
}
'''
html = page('İhya · Odak', 390, 844, body, script)
open(OUT + 'IhyaOdak.dc.html', 'w').write(html)
print('ok', len(html))
