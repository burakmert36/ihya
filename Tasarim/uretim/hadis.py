from common import *
H = json.load(open(B + 'data/hadis/buhari_nihai.json'))
H = [{k: h[k] for k in ('no', 'kitap', 'konu', 'ravi', 'metin', 'link')} for h in H]
K = json.load(open(B + 'data/hikmet/hikmetler.json'))

body = '''
<div style="position: relative; width: 390px; height: 844px; overflow: hidden; font-family: Inter, -apple-system, system-ui, sans-serif; color: #F3F1FF; background: radial-gradient(120% 70% at 30% 0%, #3B2E8C 0%, #1B1745 45%, #0E0C24 100%)">
  <div aria-hidden="true" style="position: absolute; right: -60px; top: 90px; width: 260px; height: 260px; border-radius: 130px; background: radial-gradient(circle, rgba(255,214,120,.22), rgba(255,214,120,0) 70%)"></div>
  <div style="position: absolute; left: 20px; right: 20px; top: 56px; display: flex; flex-direction: column; gap: 10px">
    <div style="display: flex; justify-content: space-between; align-items: flex-end">
      <h1 style="margin: 0; font-size: 34px; line-height: 40px; font-weight: 800; letter-spacing: -.6px">{{title}}</h1>
      <span style="display: flex; align-items: center; gap: 8px; padding-bottom: 2px"><span style="font-size: 12px; font-weight: 700; color: rgba(243,241,255,.6)">{{countLabel}}</span><a href="OkumaModu.dc.html" class="g27k bas" aria-label="Okuma modunda aç" style="width: 38px; height: 38px; border-radius: 19px; display: flex; align-items: center; justify-content: center; font-family: Newsreader, Georgia, serif; font-size: 16px; font-weight: 600; color: #F3F1FF"><span style="position: relative">Aa</span></a></span>
    </div>
    <div role="tablist" class="g27k" style="height: 44px; border-radius: 22px; display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); padding: 4px">
      <sc-for list="{{tabs}}" as="t">
        <button role="tab" aria-selected="{{t.on}}" onClick="{{t.pick}}" class="bas" style="position: relative; height: 36px; border-radius: 18px; background: {{t.bg}}; color: {{t.color}}; font-size: 13.5px; font-weight: 800">{{t.label}}</button>
      </sc-for>
    </div>
  </div>

  <sc-if value="{{isGun}}">
    <div aria-hidden="true" style="position: absolute; left: -40px; top: 360px; width: 240px; height: 240px; border-radius: 120px; background: radial-gradient(circle, rgba(255,120,170,.45), rgba(255,120,170,0) 68%)"></div>
    <div aria-hidden="true" style="position: absolute; right: -40px; top: 560px; width: 260px; height: 260px; border-radius: 130px; background: radial-gradient(circle, rgba(90,200,255,.4), rgba(90,200,255,0) 68%)"></div>
    <article class="g27 yuk" style="position: absolute; left: 16px; right: 16px; top: 172px; bottom: 30px; border-radius: 32px; background: linear-gradient(165deg, rgba(255,253,246,.93), rgba(247,240,224,.86)); color: #2A2416; padding: 20px 20px 16px; display: flex; flex-direction: column; gap: 12px">
      <div style="position: relative; display: flex; gap: 8px; align-items: center">
        <span style="height: 26px; padding: 0 10px; border-radius: 13px; background: #2A2416; color: #FFE6A8; font-size: 11px; font-weight: 800; letter-spacing: 1px; display: flex; align-items: center">GÜNÜN HADİSİ</span>
        <span style="height: 26px; padding: 0 10px; border-radius: 13px; background: rgba(154,106,0,.12); color: #6A5420; font-size: 11.5px; font-weight: 700; display: flex; align-items: center">{{g.konu}}</span>
        <svg width="26" height="26" viewBox="0 0 26 26" aria-hidden="true" style="margin-left: auto"><path d="M13 1l3.2 4.6L21.5 4l-1.6 5.3L25 13l-5.1 3.7 1.6 5.3-5.3-1.6L13 25l-3.2-4.6L4.5 22l1.6-5.3L1 13l5.1-3.7L4.5 4l5.3 1.6Z" fill="none" stroke="#C9A04A" stroke-width="1.3"></path><circle cx="13" cy="13" r="3" fill="#C9A04A"></circle></svg>
      </div>
      <div class="dikey" style="position: relative; flex: 1; min-height: 0; display: flex; align-items: center">
        <p style="margin: auto 0; font-family: Newsreader, Georgia, serif; font-size: {{gSize}}; line-height: 1.4; font-weight: 500; color: #1E190E">{{gText}}</p>
      </div>
      <div style="position: relative; height: 1px; background: linear-gradient(90deg, rgba(201,160,74,0), rgba(201,160,74,.7), rgba(201,160,74,0))"></div>
      <div style="position: relative; display: flex; flex-direction: column; gap: 3px">
        <span style="font-size: 13px; font-weight: 700; color: #4A3E22">Râvî: {{g.ravi}}</span>
        <span style="font-size: 12.5px; font-weight: 800; letter-spacing: .6px; color: #9A6A00">{{g.kaynak}}</span>
      </div>
      <div style="position: relative; display: flex; gap: 8px">
        <a href="{{g.link}}" target="_blank" rel="noopener" class="g27t bas" style="flex: 1; height: 48px; border-radius: 24px; font-size: 14px; font-weight: 800; display: flex; align-items: center; justify-content: center"><span style="position: relative">Kaynağı aç · sunnah.com</span></a>
        <button onClick="{{next}}" aria-label="Başka bir hadis" class="g27 bas" style="width: 48px; height: 48px; border-radius: 24px; color: #4A3E22; font-size: 19px; font-weight: 800"><svg width="20" height="20" viewBox="0 0 24 24" aria-hidden="true" style="position: relative; display: block; margin: 0 auto"><path d="M19 12a7 7 0 1 1-2.05-4.95M19 4.5v3.2h-3.2" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"></path></svg></button>
      </div>
      <p style="position: relative; margin: 0; font-size: 11px; line-height: 15px; color: #7A6A48">Yalnız Sahîh-i Buhârî ve yalnız Hz. Peygamber'in sözleri. Her hadis numarası Arapça ve İngilizce metinle tek tek karşılaştırıldı. Aa: koyu okuma modu.</p>
    </article>
  </sc-if>

  <sc-if value="{{isList}}">
    <div style="position: absolute; left: 0; right: 0; top: 168px; bottom: 0; display: flex; flex-direction: column">
      <div class="yatay" onWheel="{{yatayTeker}}" style="gap: 6px; padding: 4px 16px 10px; flex: none">
        <sc-for list="{{konular}}" as="k">
          <button onClick="{{k.pick}}" class="{{k.cls}} bas" style="flex: none; height: 34px; padding: 0 13px; border-radius: 17px; font-size: 12.5px; font-weight: 800; color: {{k.color}}; background: {{k.bg}}"><span style="position: relative">{{k.label}}</span></button>
        </sc-for>
      </div>
      <div class="dikey" style="flex: 1; padding: 0 16px 30px; display: flex; flex-direction: column; gap: 10px">
        <sc-for list="{{list}}" as="h">
          <article class="g27k" style="border-radius: 24px; padding: 14px; display: flex; flex-direction: column; gap: 6px; flex: none">
            <p style="position: relative; margin: 0; font-family: Newsreader, Georgia, serif; font-size: 16.5px; line-height: 22px; color: #F7F4FF">{{h.kisa}}</p>
            <a href="{{h.link}}" target="_blank" rel="noopener" style="position: relative; font-size: 11.5px; font-weight: 800; letter-spacing: .4px; color: #FFD27A">{{h.kaynak}} · {{h.ravi}}</a>
          </article>
        </sc-for>
        <button onClick="{{more}}" class="g27k bas" style="flex: none; height: 44px; border-radius: 22px; color: #F3F1FF; font-size: 13px; font-weight: 800">{{moreLabel}}</button>
      </div>
    </div>
  </sc-if>

  <sc-if value="{{isHikmet}}">
    <div style="position: absolute; left: 0; right: 0; top: 168px; bottom: 0; display: flex; flex-direction: column">
      <div style="display: flex; gap: 6px; padding: 4px 16px 10px; flex: none">
        <sc-for list="{{gruplar}}" as="k">
          <button onClick="{{k.pick}}" class="{{k.cls}} bas" style="flex: none; height: 34px; padding: 0 13px; border-radius: 17px; font-size: 12.5px; font-weight: 800; color: {{k.color}}; background: {{k.bg}}"><span style="position: relative">{{k.label}}</span></button>
        </sc-for>
      </div>
      <div class="dikey" style="flex: 1; padding: 0 16px 30px; display: flex; flex-direction: column; gap: 10px">
        <sc-for list="{{sozler}}" as="h">
          <article class="g27k" style="border-radius: 24px; padding: 14px; display: flex; flex-direction: column; gap: 6px; flex: none">
            <span style="position: relative; font-size: 12px; font-weight: 800; color: #B9AEFF">{{h.kisi}}</span>
            <p style="position: relative; margin: 0; font-family: Newsreader, Georgia, serif; font-size: 17px; line-height: 23px; color: #F7F4FF">“{{h.soz}}”</p>
            <span style="position: relative; font-size: 11.5px; font-weight: 700; color: #FFD27A">{{h.kaynak}}</span>
          </article>
        </sc-for>
        <section style="border-radius: 22px; background: rgba(255,120,90,.12); border: .5px solid rgba(255,160,130,.35); padding: 14px; display: flex; flex-direction: column; gap: 8px">
          <span style="font-size: 13px; font-weight: 800; color: #FFB49A">Yanlış atıf kalkanı · uygulamada yer almaz</span>
          <sc-for list="{{yanlis}}" as="y">
            <div style="display: flex; flex-direction: column; gap: 2px"><span style="font-size: 13px; font-weight: 700; color: #FFE6DC">{{y.soz}}</span><span style="font-size: 11.5px; line-height: 15px; color: rgba(255,230,220,.75)">{{y.not_}}</span></div>
          </sc-for>
        </section>
      </div>
    </div>
  </sc-if>
</div>
'''

script = YATAY_JS + r'''
var HADIS = ''' + json.dumps(H, ensure_ascii=False) + r''';
var HIKMET = ''' + json.dumps(K, ensure_ascii=False) + r''';
var KONU = ['Tümü', 'İman ve ihlas', 'Namaz', "Kur'an", 'Zikir ve dua', 'Güzel ahlak', 'Merhamet ve kardeşlik', 'Anne baba ve aile', 'Sadaka ve emek', 'Oruç ve Ramazan', 'Sabır ve şifa', 'Ahiret', 'Hikmet'];
var GRUP = ['Peygamberler', 'Sahâbe', 'Âlimler ve gönül ehli'];
class Component extends DCLogic {
  constructor(p) {
    super(p);
    var now = new Date(), start = new Date(now.getFullYear(), 0, 0), day = Math.floor((now - start) / 86400000);
    this.state = { tab: 0, gi: day % HADIS.length, konu: 0, n: 30, grup: 0 };
  }
  renderVals() {
    var self = this, s = this.state, g = HADIS[s.gi];
    var gText = g.metin;
    var tabs = ['Günün hadisi', 'Hadisler', 'Hikmet'].map(function (l, i) { var on = s.tab === i; return { label: l, on: on ? 'true' : 'false', bg: on ? 'rgba(255,255,255,.92)' : 'transparent', color: on ? '#1B1745' : '#EDEAFF', pick: function () { self.setState({ tab: i }); } }; });
    var filt = HADIS.filter(function (h) { return s.konu === 0 || h.konu === KONU[s.konu]; });
    var konular = KONU.map(function (k, i) { var on = s.konu === i; return { label: k, cls: on ? '' : 'g27k', bg: on ? '#FFD27A' : '', color: on ? '#2A2416' : '#F3F1FF', pick: function () { self.setState({ konu: i, n: 30 }); } }; });
    var list = filt.slice(0, s.n).map(function (h) { return { kisa: h.metin, link: h.link, ravi: h.ravi, kaynak: 'Buhârî, ' + h.kitap + ', ' + h.no }; });
    var gruplar = GRUP.map(function (k, i) { var on = s.grup === i; return { label: k, cls: on ? '' : 'g27k', bg: on ? '#B9AEFF' : '', color: on ? '#1B1745' : '#F3F1FF', pick: function () { self.setState({ grup: i }); } }; });
    return {
      yatayTeker: yatayTeker,
      title: ['Bugün', 'Hadisler', 'Hikmet'][s.tab], countLabel: s.tab === 2 ? HIKMET.sozler.length + ' söz · kaynaklı' : HADIS.length + ' hadis · yalnız Buhârî',
      tabs: tabs, isGun: s.tab === 0, isList: s.tab === 1, isHikmet: s.tab === 2,
      g: { konu: g.konu, ravi: g.ravi, link: g.link, kaynak: 'BUHÂRÎ, ' + g.kitap.toUpperCase() + ', ' + g.no }, gText: gText, gSize: gText.length > 380 ? '17px' : gText.length > 240 ? '19px' : gText.length > 120 ? '22px' : '26px',
      next: function () { self.setState({ gi: (self.state.gi + 37) % HADIS.length }); },
      konular: konular, list: list, more: function () { self.setState({ n: self.state.n + 30 }); }, moreLabel: list.length < filt.length ? 'Daha fazla (' + (filt.length - list.length) + ')' : filt.length + ' hadisin hepsi gösterildi',
      gruplar: gruplar, sozler: HIKMET.sozler.filter(function (h) { return h.grup === GRUP[s.grup]; }), yanlis: HIKMET.yanlis_atiflar
    };
  }
}
'''
html = page('İhya · Hadis ve hikmet', 390, 844, body, script).replace(ENGINE, '')
open(OUT + 'HadisHikmet.dc.html', 'w').write(html)
print('ok', len(html))
