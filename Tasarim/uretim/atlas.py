from common import *

body = DEFS + '''
<div style="position: relative; width: 1270px; min-height: 1960px; font-family: Inter, -apple-system, system-ui, sans-serif; color: #10261A; background: radial-gradient(60% 40% at 10% 10%, rgba(120,220,160,.55), rgba(120,220,160,0)), radial-gradient(50% 35% at 90% 30%, rgba(255,190,120,.45), rgba(255,190,120,0)), radial-gradient(60% 40% at 30% 80%, rgba(150,170,255,.45), rgba(150,170,255,0)), radial-gradient(50% 40% at 85% 85%, rgba(255,140,170,.4), rgba(255,140,170,0)), #EEF6EE">
  <header style="padding: 40px 48px 20px; display: flex; align-items: flex-end; justify-content: space-between; gap: 24px">
    <div style="display: flex; flex-direction: column; gap: 8px; max-width: 820px">
      <span style="font-size: 13px; font-weight: 800; letter-spacing: 1.6px; color: #2E8B57">İHYA · BİTKİ ATLASI</span>
      <h1 style="margin: 0; font-size: 40px; line-height: 46px; font-weight: 800; letter-spacing: -.8px">Süre arttıkça bitki büyür: 13 tür, 10’dan 120 dakikaya</h1>
      <p style="margin: 0; font-size: 16px; line-height: 24px; color: #3D5A49">Hepsi aynı ölçekte çizildi. Her türün ilk evreleri kendine özel: gül ilk 10 dk filiz, sonraki 10 dk gonca, 30. dakikada açar. Tam formundan sonra büyüme durmaz; çiçekler çoğalıp demet, tarh ve bahçe olur, ağaçlar olgunlaşıp ulu ağaca döner. En büyük hâl 120 dakikadır.</p>
    </div>
    <button class="g27t bas" onClick="{{play}}" style="flex: none; height: 52px; padding: 0 24px; border-radius: 26px; font-size: 16px; font-weight: 800; letter-spacing: .4px">{{playLabel}}</button>
  </header>
  <div style="padding: 0 48px 48px; display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 18px">
    <sc-for list="{{cards}}" as="c">
      <article class="g27" style="height: 222px; border-radius: 30px; display: flex; gap: 14px; padding: 12px">
        <div style="position: relative; flex: none; width: 150px; height: 182px; border-radius: 22px; background: {{c.sky}}; overflow: hidden; box-shadow: inset 0 0 0 .5px rgba(255,255,255,.8)">
          <svg role="img" aria-label="{{c.alt}}" width="150" height="180" viewBox="-12 -24 124 149" style="position: absolute; left: 0; top: 2px"><g class="sal">''' + paths('c.big') + '''</g></svg>
          <span class="g27" style="position: absolute; left: 8px; top: 8px; min-height: 24px; max-width: 134px; padding: 4px 9px; border-radius: 12px; font-size: 10.5px; line-height: 13px; font-weight: 800; color: #0E4A2A; display: flex; align-items: center"><span style="position: relative">{{c.now}}</span></span>
        </div>
        <div style="position: relative; flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 6px; padding-top: 2px">
          <div style="display: flex; align-items: baseline; gap: 8px">
            <h2 style="margin: 0; font-size: 22px; font-weight: 800; letter-spacing: -.3px">{{c.ad}}</h2>
            <span style="font-size: 13px; font-weight: 700; color: {{c.renk}}">{{c.tur}} · tam formu {{c.dk}} dk</span>
            <span style="margin-left: auto; height: 24px; padding: 0 9px; border-radius: 12px; background: rgba(255,255,255,.6); font-size: 11px; font-weight: 700; color: #4A6656; display: flex; align-items: center; white-space: nowrap">{{c.kilit}}</span>
          </div>
          <div style="display: flex; gap: 3px">
            <sc-for list="{{c.stages}}" as="e">
              <div style="flex: 1; min-width: 0; display: flex; flex-direction: column; align-items: center; gap: 2px">
                <svg width="56" height="66" viewBox="-12 -24 124 149" aria-hidden="true" style="border-radius: 12px; background: linear-gradient(#E3F2FF, #F4FBEF)">''' + paths('e.mini') + '''</svg>
                <div style="width: 100%; height: 5px; border-radius: 3px; background: #E3ECE0; overflow: hidden"><div style="width: {{e.fill}}; height: 100%; background: linear-gradient(90deg, #57D67E, #1BA552)"></div></div>
                <span style="font-size: 11px; font-weight: 800">{{e.aralik}}</span>
                <span style="font-size: 9.5px; line-height: 11px; font-weight: 600; color: #3E5A49; text-align: center; max-width: 100%">{{e.ad}}</span>
              </div>
            </sc-for>
          </div>
          <p style="margin: 0; font-size: 12.5px; line-height: 17px; color: #31503D; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden">{{c.not}}</p>
        </div>
      </article>
    </sc-for>
  </div>
</div>
'''

script = r'''
var VB = { menekse: '20 52 60 72', lale: '14 34 72 86', reyhan: '16 40 68 82', sumbul: '16 40 68 82', gul: '12 30 76 90', lavanta: '10 32 80 90', badem: '6 14 88 104', servi: '6 4 88 108', turunc: '6 18 88 100', nar: '6 18 88 100', zeytin: '4 16 92 102', hurma: '0 4 100 112', cinar: '0 8 100 110' };
var SKY = { 'Çiçek': 'linear-gradient(180deg, #D9EEFF, #F6FBF0)', 'Ağaç': 'linear-gradient(180deg, #CDE8FF, #EEF8E8)' };
var ADIM = [10, 20, 30, 45, 60, 90, 120];
class Component extends DCLogic {
  constructor(p) {
    super(p); this.state = { t: 1, playing: false };
    var self = this; this.minis = {};
    BITKI_SIRA.forEach(function (k) { self.minis[k] = ADIM.map(function (m) { return bitkiCiz(k, m, 9, { lod: 0.45 }); }); });
  }
  componentWillUnmount() { clearInterval(this.iv); }
  renderVals() {
    var self = this, s = this.state;
    var cards = BITKI_SIRA.map(function (k) {
      var b = BITKI[k], dk = Math.max(0.5, s.t * BITKI_MAX);
      return { ad: b.ad, tur: b.tur, dk: b.dk, renk: b.renk, kilit: b.kilit, not: b.not, sky: SKY[b.tur], alt: b.ad + ', ' + bitkiOzet(k, dk),
        now: Math.round(dk) + ' dk · ' + bitkiOzet(k, dk).split(' · ')[0], big: bitkiCiz(k, dk, 9, { lod: 0.8 }),
        stages: ADIM.map(function (m, n) { var a = bitkiOzet(k, m).split(' · ')[0]; if (a.toLocaleLowerCase('tr').indexOf(b.ad.toLocaleLowerCase('tr') + ' ') === 0) { a = a.slice(b.ad.length + 1); a = a.charAt(0).toLocaleUpperCase('tr') + a.slice(1); } return { ad: a, aralik: m + ' dk', mini: self.minis[k][n], fill: dk >= m ? '100%' : Math.round(Math.max(0, (dk - (ADIM[n - 1] || 0)) / (m - (ADIM[n - 1] || 0))) * 100) + '%' }; }) };
    });
    return { cards: cards, playLabel: s.playing ? 'Büyüyor…' : '0’dan 120 dakikaya büyüt',
      play: function () { if (self.state.playing) return; self.setState({ t: 0, playing: true }); clearInterval(self.iv); self.iv = setInterval(function () { var t = self.state.t + 0.01; if (t >= 1) { clearInterval(self.iv); self.setState({ t: 1, playing: false }); } else self.setState({ t: t }); }, 120); } };
  }
}
'''
html = page("İhya · Bitki atlası", 1270, 1960, body, script)
open(OUT + 'BitkiAtlasi.dc.html', 'w').write(html)
print('ok', len(html))
