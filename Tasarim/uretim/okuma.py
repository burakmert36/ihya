from common import *
# Okuma modu: tüm okunabilir içerik (Kur'an, hadis, hikmet, kitap) göz yormayan temalarla.
QA = {(v['chapter'], v['verse']): v['text'] for v in json.load(open(B + 'data/raw/ara-quranuthmanihaf.json'))['quran']}
QT = {(v['chapter'], v['verse']): v['text'] for v in json.load(open(B + 'data/raw/tur-diyanetisleri.json'))['quran']}
FATIHA = [{'n': str(a), 'ar': QA[(1, a)], 'tr': QT[(1, a)].strip()} for a in range(1, 8)]
H = json.load(open(B + 'data/hadis/buhari_nihai.json'))
H = [{'metin': h['metin'], 'kaynak': 'Buhârî, ' + h['kitap'] + ', ' + str(h['no']), 'ravi': h['ravi']} for h in H]
K = json.load(open(B + 'data/hikmet/hikmetler.json'))['sozler']
YUNUS = [s for s in K if s['kisi'] == 'Yunus Emre']
SOZ = [s for s in K if s['kisi'] != 'Yunus Emre']
V = json.load(open(B + 'data/vakit/vakitler_bursa.json'))
VK = [{'t': v['tarih'], 'i': v['imsak'], 'a': v['aksam']} for v in V]

FONTS = '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Amiri+Quran&amp;family=Atkinson+Hyperlegible:wght@400;700&amp;display=swap">'

body = '''
<div style="position: relative; width: 390px; height: 844px; overflow: hidden; font-family: Inter, -apple-system, system-ui, sans-serif; background: {{bg}}; color: {{fg}}; transition: background .4s, color .4s">
  <div style="position: absolute; left: 14px; right: 14px; top: 52px; display: flex; align-items: center; gap: 8px; z-index: 3">
    <a href="IhyaKitaplik.dc.html" aria-label="Kitaplığa dön" class="bas" style="width: 40px; height: 40px; border-radius: 20px; display: flex; align-items: center; justify-content: center; background: {{chip}}; color: {{fg}}; font-size: 20px; font-weight: 700">‹</a>
    <div role="tablist" style="flex: 1; height: 40px; border-radius: 20px; padding: 3px; display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); background: {{chip}}">
      <sc-for list="{{tabs}}" as="t">
        <button role="tab" aria-selected="{{t.on}}" onClick="{{t.pick}}" class="bas" style="height: 34px; border-radius: 17px; font-size: 12.5px; font-weight: 800; background: {{t.bg}}; color: {{t.color}}">{{t.label}}</button>
      </sc-for>
    </div>
    <button onClick="{{togglePanel}}" aria-expanded="{{panelOn}}" aria-label="Görünüm ayarları" class="bas" style="width: 44px; height: 40px; border-radius: 20px; background: {{aaBg}}; color: {{aaFg}}; font-family: Newsreader, Georgia, serif; font-size: 18px; font-weight: 600">Aa</button>
  </div>

  <main class="dikey" style="position: absolute; left: 0; right: 0; top: 104px; bottom: {{mainBottom}}; padding: 8px {{kenar}} 40px">
    <div style="max-width: 34em; margin: 0 auto; font-family: {{font}}; font-size: {{boyut}}; line-height: {{satir}}">
      <p style="margin: 0 0 14px; font-family: Inter, system-ui, sans-serif; font-size: 11.5px; line-height: 16px; font-weight: 800; letter-spacing: 1.2px; color: {{muted}}">{{baslik}}</p>
      <sc-if value="{{isKuran}}">
        <sc-for list="{{fatiha}}" as="v">
          <section style="margin: 0 0 18px">
            <p dir="rtl" lang="ar" style="margin: 0 0 6px; font-family: 'Amiri Quran', Amiri, 'Geeza Pro', serif; font-size: {{arBoyut}}; line-height: 2.05; text-align: right; color: {{fg}}">{{v.ar}}</p>
            <div style="display: flex; gap: 10px; align-items: flex-start">
              <span style="flex: none; width: 24px; height: 24px; margin-top: 2px; border-radius: 12px; border: 1px solid {{rule}}; display: flex; align-items: center; justify-content: center; font-family: Inter, system-ui, sans-serif; font-size: 11px; line-height: 1; font-weight: 800; font-variant-numeric: tabular-nums; color: {{muted}}">{{v.n}}</span>
              <p style="margin: 0; color: {{fg2}}">{{v.tr}}</p>
            </div>
          </section>
        </sc-for>
        <p style="margin: 6px 0 0; font-family: Inter, system-ui, sans-serif; font-size: 11px; line-height: 15px; color: {{muted}}">Meal: Diyanet İşleri (Tanzil neşri) · Arapça: Hafs, Osmanlı hattı</p>
      </sc-if>
      <sc-if value="{{isHadis}}">
        <sc-for list="{{hadisler}}" as="h">
          <article style="margin: 0 0 22px; padding: 0 0 18px; border-bottom: 1px solid {{rule}}">
            <p style="margin: 0 0 8px">{{h.metin}}</p>
            <p style="margin: 0; font-family: Inter, system-ui, sans-serif; font-size: 12px; line-height: 16px; font-weight: 700; color: {{accent}}">{{h.kaynak}} · {{h.ravi}}</p>
          </article>
        </sc-for>
      </sc-if>
      <sc-if value="{{isHikmet}}">
        <sc-for list="{{sozler}}" as="h">
          <article style="margin: 0 0 22px; padding: 0 0 18px; border-bottom: 1px solid {{rule}}">
            <p style="margin: 0 0 4px; font-family: Inter, system-ui, sans-serif; font-size: 12px; font-weight: 800; color: {{muted}}">{{h.kisi}}</p>
            <p style="margin: 0 0 8px">“{{h.soz}}”</p>
            <p style="margin: 0; font-family: Inter, system-ui, sans-serif; font-size: 12px; line-height: 16px; font-weight: 700; color: {{accent}}">{{h.kaynak}}</p>
          </article>
        </sc-for>
      </sc-if>
      <sc-if value="{{isKitap}}">
        <sc-for list="{{beyitler}}" as="h">
          <p style="margin: 0 0 18px; white-space: pre-line">{{h.soz}}</p>
        </sc-for>
        <p style="margin: 6px 0 0; font-family: Inter, system-ui, sans-serif; font-size: 11px; line-height: 15px; color: {{muted}}">Yunus Emre Dîvânı'ndan seçmeler · günümüz imlâsı</p>
      </sc-if>
    </div>
  </main>

  <div aria-hidden="true" style="position: absolute; inset: 0; pointer-events: none; z-index: 4; mix-blend-mode: multiply; background: {{sicakRenk}}"></div>
  <div aria-hidden="true" style="position: absolute; inset: 0; pointer-events: none; z-index: 5; background: {{karartRenk}}"></div>

  <sc-if value="{{molaOn}}">
    <div role="status" style="position: absolute; left: 50%; top: 100px; transform: translateX(-50%); z-index: 6; height: 30px; padding: 0 12px; border-radius: 15px; display: flex; align-items: center; gap: 6px; background: {{chip}}; color: {{fg2}}; font-size: 11.5px; font-weight: 700; white-space: nowrap">20 dk oldu · 20 sn uzağa bak</div>
  </sc-if>

  <sc-if value="{{panelOn}}">
    <section aria-label="Görünüm ayarları" class="g27k" style="position: absolute; left: 10px; right: 10px; bottom: 14px; height: 372px; border-radius: 30px; z-index: 7; color: #F2EEE6; background: linear-gradient(180deg, rgba(40,38,34,.88), rgba(24,23,21,.94)); display: flex; flex-direction: column">
      <div style="position: relative; display: flex; align-items: center; justify-content: space-between; padding: 14px 16px 6px">
        <span style="font-size: 16px; font-weight: 800">Görünüm</span>
        <span style="font-size: 11.5px; font-weight: 700; color: rgba(242,238,230,.6)">{{otoDurum}}</span>
      </div>
      <div class="dikey" style="position: relative; flex: 1; padding: 4px 16px 16px; display: flex; flex-direction: column; gap: 12px">
        <div style="display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 8px; flex: none">
          <sc-for list="{{temalar}}" as="t">
            <button onClick="{{t.pick}}" aria-pressed="{{t.on}}" aria-label="{{t.ad}} teması" class="bas" style="height: 64px; border-radius: 18px; background: {{t.bg}}; color: {{t.fg}}; box-shadow: {{t.ring}}; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 2px">
              <span style="font-family: Newsreader, Georgia, serif; font-size: 20px; line-height: 22px; font-weight: 600">Aa</span>
              <span style="font-size: 10.5px; font-weight: 800">{{t.ad}}</span>
            </button>
          </sc-for>
        </div>
        <div style="display: flex; align-items: center; gap: 10px; flex: none">
          <span style="width: 74px; font-size: 12px; font-weight: 700; color: rgba(242,238,230,.7)">Yazı boyutu</span>
          <span style="font-family: Newsreader, Georgia, serif; font-size: 13px">A</span>
          <input type="range" min="15" max="30" step="1" value="{{boyutN}}" onInput="{{setBoyut}}" aria-label="Yazı boyutu" style="flex: 1; accent-color: #E8C77A">
          <span style="font-family: Newsreader, Georgia, serif; font-size: 21px">A</span>
        </div>
        <div style="display: flex; align-items: center; gap: 10px; flex: none">
          <span style="width: 74px; font-size: 12px; font-weight: 700; color: rgba(242,238,230,.7)">Satır arası</span>
          <div style="flex: 1; display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 6px">
            <sc-for list="{{satirlar}}" as="o"><button onClick="{{o.pick}}" aria-pressed="{{o.on}}" class="bas" style="height: 30px; border-radius: 15px; font-size: 11.5px; font-weight: 800; background: {{o.bg}}; color: {{o.color}}">{{o.label}}</button></sc-for>
          </div>
        </div>
        <div style="display: flex; align-items: center; gap: 10px; flex: none">
          <span style="width: 74px; font-size: 12px; font-weight: 700; color: rgba(242,238,230,.7)">Kenar</span>
          <div style="flex: 1; display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 6px">
            <sc-for list="{{kenarlar}}" as="o"><button onClick="{{o.pick}}" aria-pressed="{{o.on}}" class="bas" style="height: 30px; border-radius: 15px; font-size: 11.5px; font-weight: 800; background: {{o.bg}}; color: {{o.color}}">{{o.label}}</button></sc-for>
          </div>
        </div>
        <div style="display: flex; align-items: center; gap: 10px; flex: none">
          <span style="width: 74px; font-size: 12px; font-weight: 700; color: rgba(242,238,230,.7)">Yazı tipi</span>
          <div style="flex: 1; display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 6px">
            <sc-for list="{{fontlar}}" as="o"><button onClick="{{o.pick}}" aria-pressed="{{o.on}}" class="bas" style="height: 30px; border-radius: 15px; font-size: 11.5px; font-weight: 800; background: {{o.bg}}; color: {{o.color}}; font-family: {{o.ff}}">{{o.label}}</button></sc-for>
          </div>
        </div>
        <div style="display: flex; align-items: center; gap: 10px; flex: none">
          <span style="width: 74px; font-size: 12px; font-weight: 700; color: rgba(242,238,230,.7)">Sıcak ışık</span>
          <input type="range" min="0" max="100" value="{{sicak}}" onInput="{{setSicak}}" aria-label="Sıcak ışık (mavi ışığı azaltır)" style="flex: 1; accent-color: #FFB06B">
          <span style="width: 32px; text-align: right; font-size: 12px; font-weight: 800; font-variant-numeric: tabular-nums">{{sicak}}</span>
        </div>
        <div style="display: flex; align-items: center; gap: 10px; flex: none">
          <span style="width: 74px; font-size: 12px; font-weight: 700; color: rgba(242,238,230,.7)">Karartma</span>
          <input type="range" min="0" max="60" value="{{karart}}" onInput="{{setKarart}}" aria-label="Ekranı sistem parlaklığının altına karart" style="flex: 1; accent-color: #9FB4FF">
          <span style="width: 32px; text-align: right; font-size: 12px; font-weight: 800; font-variant-numeric: tabular-nums">{{karart}}</span>
        </div>
        <sc-for list="{{anahtarlar}}" as="o">
          <button onClick="{{o.tap}}" role="switch" aria-checked="{{o.on}}" style="flex: none; display: flex; align-items: center; gap: 12px; background: transparent; color: inherit; padding: 2px 0; text-align: left">
            <span style="flex: 1; display: flex; flex-direction: column; gap: 1px"><span style="font-size: 13px; font-weight: 800">{{o.ad}}</span><span style="font-size: 11px; line-height: 14px; color: rgba(242,238,230,.6)">{{o.alt}}</span></span>
            <span style="flex: none; width: 46px; height: 28px; border-radius: 14px; background: {{o.bg}}; position: relative"><span style="position: absolute; top: 2px; left: {{o.x}}; width: 24px; height: 24px; border-radius: 12px; background: #FFFFFF; box-shadow: 0 1px 3px rgba(0,0,0,.4); transition: left .2s"></span></span>
          </button>
        </sc-for>
      </div>
    </section>
  </sc-if>
</div>
'''

script = r'''
var FATIHA = ''' + json.dumps(FATIHA, ensure_ascii=False) + r''';
var HADIS = ''' + json.dumps(H, ensure_ascii=False) + r''';
var SOZ = ''' + json.dumps(SOZ, ensure_ascii=False) + r''';
var YUNUS = ''' + json.dumps(YUNUS, ensure_ascii=False) + r''';
var VRAW = /*VAKIT_JSON_START*/''' + json.dumps(V, ensure_ascii=False) + r'''/*VAKIT_JSON_END*/;
var VAKIT = VRAW.map(function (v) { return { t: v.tarih, i: v.imsak, a: v.aksam }; });
// Göz yormayan okuma temaları: saf siyah üstüne saf beyaz yok (hale/ışıma), kontrast 7:1–13:1 arası
var TEMA = [
  { ad: 'Gece', bg: '#161512', fg: '#E4DED2', fg2: '#CFC8BA', muted: '#8F887A', accent: '#D9B56A', chip: 'rgba(255,255,255,.07)', rule: 'rgba(255,255,255,.09)', dark: true },
  { ad: 'Sepya', bg: '#1F1A13', fg: '#E6D3B0', fg2: '#D3C09E', muted: '#998A70', accent: '#E0A85E', chip: 'rgba(255,230,190,.08)', rule: 'rgba(255,230,190,.10)', dark: true },
  { ad: 'Siyah', bg: '#000000', fg: '#C9C4BA', fg2: '#B5B0A6', muted: '#77726A', accent: '#C9A35A', chip: 'rgba(255,255,255,.08)', rule: 'rgba(255,255,255,.10)', dark: true },
  { ad: 'Gündüz', bg: '#F6F0E2', fg: '#2B261D', fg2: '#3D362A', muted: '#857A66', accent: '#9A6A00', chip: 'rgba(60,45,20,.07)', rule: 'rgba(60,45,20,.12)', dark: false }
];
var SEKME = ['Kur’an', 'Hadis', 'Hikmet', 'Kitap'];
var SATIR = [['Sık', '1.45'], ['Rahat', '1.7'], ['Geniş', '1.95']];
var KENAR = [['Dar', '16px'], ['Orta', '24px'], ['Geniş', '34px']];
var FONT = [['Serif', "Newsreader, Georgia, serif"], ['Sans', "Inter, system-ui, sans-serif"], ['Okunaklı', "'Atkinson Hyperlegible', Inter, sans-serif"]];
function dk(s) { var p = s.split(':'); return Number(p[0]) * 60 + Number(p[1]); }
function bugun() { var d = new Date(), t = ('0' + d.getDate()).slice(-2) + '.' + ('0' + (d.getMonth() + 1)).slice(-2) + '.' + d.getFullYear(); for (var i = 0; i < VAKIT.length; i++) if (VAKIT[i].t === t) return [VAKIT[i], VAKIT[i + 1] || VAKIT[i]]; return [VAKIT[0], VAKIT[1]]; }
class Component extends DCLogic {
  constructor(p) {
    super(p);
    var now = new Date(), day = Math.floor((now - new Date(now.getFullYear(), 0, 0)) / 86400000);
    this.gun = day;
    this.state = { sekme: 0, tema: 0, boyut: 19, satir: 1, kenar: 1, font: 0, sicak: 30, karart: 0, oto: true, mola: true, uyanik: true, panel: true, molaGoster: false };
  }
  componentDidMount() { var self = this; this.t0 = Date.now(); this.iv = setInterval(function () { if (self.state.mola && Date.now() - self.t0 > 20 * 60000) { self.t0 = Date.now(); self.setState({ molaGoster: true }); setTimeout(function () { self.setState({ molaGoster: false }); }, 20000); } }, 30000); }
  componentWillUnmount() { clearInterval(this.iv); }
  renderVals() {
    var self = this, s = this.state;
    var v = bugun(), now = new Date(), m = now.getHours() * 60 + now.getMinutes();
    var gece = m >= dk(v[0].a) || m < dk(v[0].i);
    var ti = s.tema; if (s.oto && gece && !TEMA[ti].dark) ti = 0;
    var T = TEMA[ti];
    var otoDurum = !s.oto ? 'Elle seçim' : gece ? 'Gece · imsak ' + v[1].i + '’e kadar koyu' : 'Akşam ' + v[0].a + '’de koyuya geçer';
    function seg(list, cur, key) { return list.map(function (o, i) { var on = cur === i; return { label: o[0], ff: o[1], on: on ? 'true' : 'false', bg: on ? '#F2EEE6' : 'rgba(255,255,255,.07)', color: on ? '#1A1814' : '#F2EEE6', pick: function () { var p = {}; p[key] = i; self.setState(p); } }; }); }
    var h0 = this.gun % HADIS.length;
    var anah = [
      ['oto', 'Akşamdan imsaka kendiliğinden koyu', 'Bursa vakitleri: akşam ' + v[0].a + ' → imsak ' + v[1].i],
      ['mola', '20-20-20 göz molası', 'Her 20 dakikada bir, 20 saniye uzağa bakmayı hatırlatır'],
      ['uyanik', 'Okurken ekran kapanmasın', 'Sayfa açıkken kilitlenme süresi işlemez']
    ].map(function (a) { var on = s[a[0]]; return { ad: a[1], alt: a[2], on: on ? 'true' : 'false', bg: on ? '#3FBF7F' : 'rgba(255,255,255,.18)', x: on ? '20px' : '2px', tap: function () { var p = {}; p[a[0]] = !self.state[a[0]]; self.setState(p); } }; });
    return {
      bg: T.bg, fg: T.fg, fg2: T.fg2, muted: T.muted, accent: T.accent, chip: T.chip, rule: T.rule,
      aaBg: s.panel ? T.fg : T.chip, aaFg: s.panel ? T.bg : T.fg,
      tabs: SEKME.map(function (l, i) { var on = s.sekme === i; return { label: l, on: on ? 'true' : 'false', bg: on ? T.fg : 'transparent', color: on ? T.bg : T.fg2, pick: function () { self.setState({ sekme: i }); } }; }),
      togglePanel: function () { self.setState({ panel: !self.state.panel }); }, panelOn: s.panel,
      mainBottom: s.panel ? '386px' : '0px', kenar: KENAR[s.kenar][1], font: FONT[s.font][1], boyut: s.boyut + 'px', boyutN: s.boyut, arBoyut: Math.round(s.boyut * 1.45) + 'px', satir: SATIR[s.satir][1],
      baslik: ['FÂTİHA SÛRESİ · 1:1–7', 'GÜNÜN HADİSLERİ · SAHÎH-İ BUHÂRÎ', 'HİKMET · KAYNAKLI SÖZLER', 'KİTAP · YUNUS EMRE DÎVÂNI'][s.sekme],
      isKuran: s.sekme === 0, isHadis: s.sekme === 1, isHikmet: s.sekme === 2, isKitap: s.sekme === 3,
      fatiha: FATIHA, hadisler: [HADIS[h0], HADIS[(h0 + 37) % HADIS.length], HADIS[(h0 + 74) % HADIS.length]],
      sozler: [SOZ[this.gun % SOZ.length], SOZ[(this.gun + 11) % SOZ.length], SOZ[(this.gun + 29) % SOZ.length]],
      beyitler: YUNUS.map(function (y) { return { soz: y.soz.replace(' / ', '\n') }; }),
      sicak: s.sicak, karart: s.karart,
      sicakRenk: 'rgba(255,152,64,' + (s.sicak / 100 * 0.34).toFixed(3) + ')', karartRenk: 'rgba(0,0,0,' + (s.karart / 100).toFixed(2) + ')',
      setBoyut: function (e) { self.setState({ boyut: Number(e.target.value) }); }, setSicak: function (e) { self.setState({ sicak: Number(e.target.value) }); }, setKarart: function (e) { self.setState({ karart: Number(e.target.value) }); },
      temalar: TEMA.map(function (t, i) { var on = s.tema === i; return { ad: t.ad, bg: t.bg, fg: t.fg, on: on ? 'true' : 'false', ring: on ? '0 0 0 2px #E8C77A, 0 6px 16px rgba(0,0,0,.4)' : 'inset 0 0 0 1px rgba(255,255,255,.14)', pick: function () { self.setState({ tema: i }); } }; }),
      satirlar: seg(SATIR, s.satir, 'satir'), kenarlar: seg(KENAR, s.kenar, 'kenar'), fontlar: seg(FONT, s.font, 'font'),
      anahtarlar: anah, otoDurum: otoDurum, molaOn: s.molaGoster
    };
  }
}
'''
html = page('İhya · Okuma modu', 390, 844, body, script, head=FONTS + '\n').replace(ENGINE, '')
open(OUT + 'OkumaModu.dc.html', 'w').write(html)
print('ok', len(html))
