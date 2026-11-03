from common import *

body = '''
<div style="position: relative; width: 390px; height: 844px; overflow: hidden; font-family: Inter, -apple-system, system-ui, sans-serif; color: #F1F7FF; background: linear-gradient(180deg, #0D1B2E 0%, #142B45 40%, #0B1626 100%)">
  <div aria-hidden="true" style="position: absolute; left: -80px; top: 60px; width: 300px; height: 300px; border-radius: 150px; background: radial-gradient(circle, rgba(80,160,255,.45), rgba(80,160,255,0) 68%)"></div>
  <div aria-hidden="true" style="position: absolute; right: -90px; top: 260px; width: 320px; height: 320px; border-radius: 160px; background: radial-gradient(circle, rgba(255,140,60,.38), rgba(255,140,60,0) 68%)"></div>
  <div aria-hidden="true" style="position: absolute; left: 20px; top: 560px; width: 300px; height: 300px; border-radius: 150px; background: radial-gradient(circle, rgba(90,230,160,.30), rgba(90,230,160,0) 68%)"></div>
  <sc-for list="{{drops}}" as="d"><div aria-hidden="true" class="damla" style="position: absolute; left: {{d.x}}; top: -40px; width: 1.5px; height: {{d.h}}; border-radius: 1px; background: linear-gradient(rgba(170,210,255,0), rgba(170,210,255,.55)); animation-duration: {{d.t}}; animation-delay: {{d.dl}}; opacity: {{rainOp}}"></div></sc-for>

  <div style="position: absolute; left: 16px; right: 16px; top: 54px; display: flex; align-items: center; gap: 10px">
    <a href="IhyaOdak.dc.html" class="g27k bas" aria-label="Odağa dön" style="width: 40px; height: 40px; border-radius: 20px; display: flex; align-items: center; justify-content: center; font-size: 20px; font-weight: 700"><span style="position: relative">‹</span></a>
    <div style="display: flex; flex-direction: column"><h1 style="margin: 0; font-size: 28px; line-height: 32px; font-weight: 800; letter-spacing: -.4px">Odak sesleri</h1><span style="font-size: 12px; font-weight: 600; color: rgba(225,238,255,.7)">Uygulamadan çıksan, ekran kilitlense de çalar</span></div>
  </div>

  <section class="g27k" style="position: absolute; left: 16px; right: 16px; top: 112px; border-radius: 30px; padding: 14px 16px; display: flex; flex-direction: column; gap: 12px">
    <div style="position: relative; display: flex; align-items: center; gap: 12px">
      <button onClick="{{toggle}}" class="g27t bas" aria-label="{{playAria}}" style="width: 62px; height: 62px; border-radius: 31px; display: flex; align-items: center; justify-content: center; flex: none">
        <svg width="22" height="24" viewBox="0 0 22 24" aria-hidden="true" style="position: relative"><path d="{{playIcon}}" fill="#FFFFFF"></path></svg>
      </button>
      <div style="flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 2px">
        <span style="font-size: 19px; font-weight: 800; white-space: nowrap; overflow: hidden; text-overflow: ellipsis">{{sceneName}}</span>
        <span style="font-size: 12.5px; font-weight: 600; color: rgba(225,238,255,.75)">{{mixInfo}}</span>
      </div>
    </div>
    <div style="position: relative; display: flex; align-items: center; gap: 10px">
      <svg width="16" height="14" viewBox="0 0 16 14" aria-hidden="true"><path d="M1 5h3l4-4v12L4 9H1Z" fill="#CFE3FF"></path></svg>
      <input type="range" min="0" max="100" value="{{master}}" onInput="{{setMaster}}" aria-label="Ana ses seviyesi" style="flex: 1; accent-color: #6FD3FF">
      <span style="width: 36px; text-align: right; font-size: 13px; font-weight: 800; font-variant-numeric: tabular-nums">{{master}}</span>
    </div>
    <div style="position: relative; display: flex; gap: 6px">
      <sc-for list="{{timers}}" as="t"><button onClick="{{t.pick}}" class="bas" style="flex: 1; height: 30px; border-radius: 15px; font-size: 11.5px; font-weight: 800; background: {{t.bg}}; color: {{t.color}}">{{t.label}}</button></sc-for>
    </div>
  </section>

  <div class="yatay" onWheel="{{yatayTeker}}" style="position: absolute; left: 0; right: 0; top: 314px; gap: 8px; padding: 0 16px 6px; scroll-padding-inline: 16px">
    <sc-for list="{{scenes}}" as="c">
      <button onClick="{{c.pick}}" class="{{c.cls}} bas" style="flex: none; height: 38px; padding: 0 13px; border-radius: 19px; font-size: 13px; font-weight: 800; color: {{c.color}}; display: flex; align-items: center; gap: 6px"><svg width="16" height="16" viewBox="0 0 24 24" aria-hidden="true" style="position: relative; display: block"><path d="{{c.ik}}" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"></path></svg><span style="position: relative">{{c.ad}}</span></button>
    </sc-for>
  </div>

  <div class="dikey" style="position: absolute; left: 0; right: 0; top: 364px; bottom: 108px; padding: 4px 16px 16px">
    <div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 10px">
      <sc-for list="{{layers}}" as="l">
        <div class="{{l.cls}}" style="border-radius: 22px; padding: 10px 12px; display: flex; flex-direction: column; gap: 6px; min-height: 96px">
          <button onClick="{{l.tap}}" aria-pressed="{{l.on}}" style="position: relative; display: flex; align-items: center; gap: 8px; background: transparent; color: inherit; padding: 0; text-align: left">
            <span style="width: 32px; height: 32px; border-radius: 16px; background: {{l.dot}}; display: flex; align-items: center; justify-content: center; flex: none"><svg width="18" height="18" viewBox="0 0 24 24" aria-hidden="true" style="display: block"><path d="{{l.ik}}" fill="none" stroke="#F1F7FF" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"></path></svg></span>
            <span style="display: flex; flex-direction: column; gap: 1px; min-width: 0"><span style="font-size: 13.5px; font-weight: 800; line-height: 16px">{{l.ad}}</span><span style="font-size: 9.5px; font-weight: 700; letter-spacing: .2px; color: {{l.dColor}}">{{l.durum}}</span></span>
          </button>
          <div style="position: relative; display: flex; align-items: center; gap: 6px"><span style="font-size: 10px; font-weight: 700; color: rgba(225,238,255,.7); width: 34px">Ses</span><input type="range" min="0" max="100" value="{{l.v}}" onInput="{{l.setV}}" aria-label="{{l.ad}} ses seviyesi" style="flex: 1; min-width: 0; accent-color: #6FD3FF"></div>
          <sc-if value="{{l.hasI}}"><div style="position: relative; display: flex; align-items: center; gap: 6px"><span style="font-size: 10px; font-weight: 700; color: rgba(255,214,160,.85); width: 34px">{{l.iLabel}}</span><input type="range" min="0" max="100" value="{{l.i}}" onInput="{{l.setI}}" aria-label="{{l.ad}} {{l.iLabel}}" style="flex: 1; min-width: 0; accent-color: #FFB86B"></div></sc-if>
        </div>
      </sc-for>
    </div>
    <p style="margin: 12px 4px 0; font-size: 11px; line-height: 15px; color: rgba(225,238,255,.62)">Yağmur, ateş, kafe, kütüphane, kuş, dere, deniz, şadırvan ve gece böcekleri <b style="color: rgba(240,248,255,.85)">gerçek doğa kayıtlarıdır</b>: dikişsiz döngü, cihazda çalar. Beyaz, pembe ve kahverengi gürültü cihazda üretilir. Kayıt açılamazsa katman kendiliğinden sentez sese geçer.</p>
    <p style="margin: 6px 4px 0; font-size: 10px; line-height: 14px; color: rgba(225,238,255,.45)">Kaynak: Moodist (Pixabay İçerik Lisansı / CC0) · Blanket (CC0 ve kamu malı kayıtlar).</p>
  </div>

  <div class="g27k" style="position: absolute; left: 12px; right: 12px; bottom: 24px; height: 72px; border-radius: 26px; display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 6px; padding: 8px">
    <sc-for list="{{opts}}" as="o">
      <button onClick="{{o.tap}}" aria-pressed="{{o.on}}" class="bas" style="position: relative; border-radius: 18px; background: {{o.bg}}; color: {{o.color}}; font-size: 11px; font-weight: 800; line-height: 13px; padding: 0 6px">{{o.label}}</button>
    </sc-for>
  </div>
</div>
'''

css = '''
@keyframes damla{0%{transform:translateY(0)}100%{transform:translateY(900px)}}
.damla{animation:damla linear infinite}
'''

script = YATAY_JS + r'''
var DOSYA = __DOSYA__;
var IK = {"yagmur": "M7.5 13h9.5a3.2 3.2 0 0 0 .4-6.4 4.6 4.6 0 0 0-8.9-1A3.7 3.7 0 0 0 7.5 13ZM8.5 16l-1 3M12.5 16l-1 3M16.5 16l-1 3", "yagmurHafif": "M7.5 13h9.5a3.2 3.2 0 0 0 .4-6.4 4.6 4.6 0 0 0-8.9-1A3.7 3.7 0 0 0 7.5 13ZM9 16.6v.4M13 18.4v.4M16.5 16.6v.4", "yagmurCam": "M5 4h14v16H5ZM12 4v16M5 12h14M8.5 6.8v1.6M15.5 14.6v1.6", "firtina": "M3 8h11a3 3 0 1 0-3-3M3 12h15a3 3 0 1 1-3 3M3 16h8", "gokgurultusu": "M7.5 13h9.5a3.2 3.2 0 0 0 .4-6.4 4.6 4.6 0 0 0-8.9-1A3.7 3.7 0 0 0 7.5 13ZM12.8 14.5l-2.2 3.6h3l-2.2 3.6", "kampAtesi": "M12 3c1 3.5 5 5.5 5 9.6a5 5 0 0 1-10 0c0-2.4 1.4-3.7 2.4-4.9.3 1.7 1 2.7 2 3.1C11 8.6 11 6 12 3ZM5 21.2l14-3M5 18.2l14 3", "somine": "M4 21V8h16v13M3 8h18M5 8l1.5-4h11L19 8M8 21v-5a4 4 0 0 1 8 0v5M12 19.6c-1.1 0-1.9-.8-1.9-1.9 0-1.2.9-1.7 1.9-2.9 1 1.2 1.9 1.7 1.9 2.9 0 1.1-.8 1.9-1.9 1.9Z", "kafe": "M5 9h11v5a5 5 0 0 1-5 5h-1a5 5 0 0 1-5-5ZM16 10.2h1.4a2.4 2.4 0 0 1 0 4.8H16M8.5 3.5c-.8 1 .8 2 0 3M12 3.5c-.8 1 .8 2 0 3", "kutuphane": "M4.5 4h3.2v16H4.5ZM9.6 4h3.2v16H9.6ZM14.6 5.3l3-.8 3.7 15.3-3 .8Z", "orman": "M12 3l5.5 7.6h-3l4 6.2h-13l4-6.2h-3ZM12 16.8V21", "kuslar": "M3 10.5c1.6-1.6 3.4-1.6 5 0 1.6-1.6 3.4-1.6 5 0M11 15.5c1.6-1.6 3.4-1.6 5 0 1.6-1.6 3.4-1.6 5 0", "dere": "M3 8c2 0 2.2-1.5 4.5-1.5S9.8 8 12 8s2.2-1.5 4.5-1.5S19 8 21 8M3 13c2 0 2.2-1.5 4.5-1.5S9.8 13 12 13s2.2-1.5 4.5-1.5S19 13 21 13M3 18c2 0 2.2-1.5 4.5-1.5S9.8 18 12 18s2.2-1.5 4.5-1.5S19 18 21 18", "sadirvan": "M12 3.5v8M12 6c-3 0-5 2-5.5 5M12 6c3 0 5 2 5.5 5M4 14h16l-1.6 4H5.6ZM8 18v3h8v-3", "deniz": "M2 16c3 0 3.5-2.5 6-2.5S11 16 14 16s3.5-2.5 6-2.5M2 20.2c3 0 3.5-2.5 6-2.5s3 2.5 6 2.5 3.5-2.5 6-2.5M5 12.4c0-4 3-7 7-7 2.5 0 4 1.5 4 3.2 0 1.6-1.3 2.8-2.8 2.8", "gece": "M19.5 14.6A7.8 7.8 0 1 1 9.4 4.5a6.3 6.3 0 0 0 10.1 10.1ZM17.5 3.5v2.6M16.2 4.8h2.6", "gurultu": "M3 12h2.2l1.6-4 2 8 2-10.5 2.2 13 2-9 1.6 4.5 1.4-2H21"};
var KATMAN = [
  ['yagmurHafif', 'Hafif yağmur', 'yagmurHafif', 'Yakınlık', 'rgba(120,180,255,.35)', { a: 'yagmur_hafif', mod: 'yakin' }],
  ['yagmur', 'Yağmur', 'yagmur', 'Şiddet', 'rgba(100,160,255,.35)', { a: 'yagmur', b: 'yagmur_siddetli', mod: 'karis' }],
  ['yagmurCam', 'Cama vuran yağmur', 'yagmurCam', 'Yakınlık', 'rgba(140,190,255,.32)', { a: 'yagmur_cam', mod: 'yakin' }],
  ['firtina', 'Fırtına rüzgârı', 'firtina', 'Şiddet', 'rgba(150,170,210,.35)', { a: 'firtina', mod: 'siddet' }],
  ['gokgurultusu', 'Gök gürültüsü', 'gokgurultusu', 'Derinlik', 'rgba(190,170,255,.35)', { a: 'gokgurultusu', mod: 'derin' }],
  ['kampAtesi', 'Kamp ateşi', 'kampAtesi', 'Çıtırtı', 'rgba(255,140,60,.38)', { a: 'kamp_atesi', mod: 'citir' }],
  ['somine', 'Şömine', 'somine', 'Çıtırtı', 'rgba(255,170,90,.35)', { a: 'somine', mod: 'citir' }],
  ['kafe', 'Kafe', 'kafe', 'Yakınlık', 'rgba(210,160,110,.38)', { a: 'kafe', mod: 'yakin' }],
  ['kutuphane', 'Kütüphane', 'kutuphane', 'Yakınlık', 'rgba(200,180,140,.34)', { a: 'kutuphane', mod: 'yakin' }],
  ['orman', 'Ağaçlarda rüzgâr', 'orman', 'Şiddet', 'rgba(90,220,140,.35)', { a: 'orman_ruzgar', mod: 'siddet' }],
  ['kuslar', 'Kuş cıvıltısı', 'kuslar', 'Yakınlık', 'rgba(150,230,120,.34)', { a: 'kuslar', mod: 'yakin' }],
  ['dere', 'Dere', 'dere', 'Yakınlık', 'rgba(90,200,230,.35)', { a: 'dere', mod: 'yakin' }],
  ['sadirvan', 'Şadırvan', 'sadirvan', 'Yakınlık', 'rgba(120,220,255,.35)', { a: 'sadirvan', mod: 'yakin' }],
  ['deniz', 'Deniz dalgaları', 'deniz', 'Yakınlık', 'rgba(70,170,230,.35)', { a: 'deniz', mod: 'yakin' }],
  ['gece', 'Gece böcekleri', 'gece', 'Yakınlık', 'rgba(160,150,255,.3)', { a: 'gece', mod: 'yakin' }],
  ['beyaz', 'Beyaz gürültü', 'gurultu', null, 'rgba(255,255,255,.25)', null],
  ['pembe', 'Pembe gürültü', 'gurultu', null, 'rgba(255,170,200,.3)', null],
  ['kahverengi', 'Kahverengi gürültü', 'gurultu', null, 'rgba(190,140,100,.35)', null]
];
var KAT = {}; KATMAN.forEach(function (k) { KAT[k[0]] = k; });
// sahne: [ad, simge, ses seviyeleri, (isteğe bağlı) yoğunluklar]
var SAHNE = [
  ['Yağmurlu gece', 'yagmur', { yagmur: 55, gokgurultusu: 22, gece: 14 }, { yagmur: 35 }],
  ['Hafif yağmur', 'yagmurHafif', { yagmurHafif: 70 }],
  ['Pencere kenarı', 'yagmurCam', { yagmurCam: 68, somine: 22 }],
  ['Yağmur', 'yagmur', { yagmur: 70 }, { yagmur: 45 }],
  ['Fırtınalı yağmur', 'firtina', { yagmur: 78, firtina: 52, gokgurultusu: 32 }, { yagmur: 85, firtina: 70 }],
  ['Gök gürültülü yağmur', 'gokgurultusu', { yagmur: 64, gokgurultusu: 58 }, { yagmur: 60 }],
  ['Kamp ateşi', 'kampAtesi', { kampAtesi: 75, gece: 22 }],
  ['Kamp ateşi ve yağmur', 'kampAtesi', { kampAtesi: 70, yagmurHafif: 52 }],
  ['Şömine başı', 'somine', { somine: 75, yagmurCam: 28 }],
  ['Kafe', 'kafe', { kafe: 75 }],
  ['Kütüphane', 'kutuphane', { kutuphane: 72, yagmurCam: 15 }],
  ['Doğa', 'orman', { orman: 50, kuslar: 55, dere: 35 }],
  ['Şadırvan avlusu', 'sadirvan', { sadirvan: 66, kuslar: 30 }, { kuslar: 45 }],
  ['Deniz kenarı', 'deniz', { deniz: 70, firtina: 10 }],
  ['Yaz gecesi', 'gece', { gece: 62, orman: 18 }],
  ['Beyaz gürültü', 'gurultu', { beyaz: 55 }],
  ['Derin odak', 'gurultu', { kahverengi: 60 }]
];
var AC = null, MASTER = null, NOISE = {}, LIVE = {};
function ses() { if (!AC) { var K = window.AudioContext || window.webkitAudioContext; if (!K) return null; AC = new K(); MASTER = AC.createGain(); MASTER.connect(AC.destination); gurultu(); } if (AC.state === 'suspended') AC.resume(); return AC; }
function gurultu() { var n = AC.sampleRate * 3; ['w', 'p', 'b'].forEach(function (k) { var buf = AC.createBuffer(2, n, AC.sampleRate); for (var ch = 0; ch < 2; ch++) { var d = buf.getChannelData(ch), b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0, last = 0; for (var i = 0; i < n; i++) { var w = Math.random() * 2 - 1; if (k === 'w') d[i] = w * 0.4; else if (k === 'p') { b0 = 0.99886 * b0 + w * 0.0555179; b1 = 0.99332 * b1 + w * 0.0750759; b2 = 0.969 * b2 + w * 0.153852; b3 = 0.8665 * b3 + w * 0.3104856; b4 = 0.55 * b4 + w * 0.5329522; b5 = -0.7616 * b5 - w * 0.016898; d[i] = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + w * 0.5362) * 0.1; b6 = w * 0.115926; } else { last = (last + 0.02 * w) / 1.02; d[i] = last * 3.2; } } } NOISE[k] = buf; }); }
function kaynak(k) { var s = AC.createBufferSource(); s.buffer = NOISE[k]; s.loop = true; s.start(0, Math.random() * 2.5); return s; }
function filtre(t, f, q) { var x = AC.createBiquadFilter(); x.type = t; x.frequency.value = f; if (q) x.Q.value = q; return x; }
function zincir(a) { for (var i = 0; i < a.length - 1; i++) a[i].connect(a[i + 1]); return a; }
function patla(out, dur, t, f, q, vol, k) { var s = AC.createBufferSource(); s.buffer = NOISE[k || 'w']; var fl = filtre(t, f, q), g = AC.createGain(), n = AC.currentTime; g.gain.setValueAtTime(0.0001, n); g.gain.linearRampToValueAtTime(vol, n + Math.min(0.01, dur / 4)); g.gain.exponentialRampToValueAtTime(0.0001, n + dur); zincir([s, fl, g, out]); s.start(n, Math.random() * 2.5); s.stop(n + dur + 0.05); }
function cik(out, f0, f1, dur, vol) { var o = AC.createOscillator(), g = AC.createGain(), n = AC.currentTime; o.frequency.setValueAtTime(f0, n); o.frequency.exponentialRampToValueAtTime(f1, n + dur); g.gain.setValueAtTime(0.0001, n); g.gain.linearRampToValueAtTime(vol, n + 0.01); g.gain.exponentialRampToValueAtTime(0.0001, n + dur); zincir([o, g, out]); o.start(n); o.stop(n + dur + 0.05); }
function lfo(hz, amt, param) { var o = AC.createOscillator(), g = AC.createGain(); o.frequency.value = hz; g.gain.value = amt; o.connect(g); g.connect(param); o.start(); return o; }
var SENTEZ_ESLE = { yagmurCam: 'yagmurHafif', kutuphane: 'kafe', kuslar: 'orman', orman: 'firtina' };
function sentez(L, id0) {
  var id = SENTEZ_ESLE[id0] || id0; L.bed = AC.createGain(); L.bed.connect(L.out);
  var B = L.bed;
  if (id === 'yagmurHafif') { zincir([kaynak('p'), filtre('highpass', 900), filtre('lowpass', 5000), B]); B.gain.value = 0.55; L.ev = function (i) { if (Math.random() < 0.15 + 0.6 * i) patla(L.out, 0.015 + Math.random() * 0.03, 'bandpass', 2500 + Math.random() * 4500, 4, 0.25 * Math.random()); }; }
  else if (id === 'yagmur') { var lp = filtre('lowpass', 6000); zincir([kaynak('w'), lp, filtre('highpass', 350), B]); B.gain.value = 0.7; L.set = function (i) { lp.frequency.value = 3500 + 5000 * i; B.gain.value = 0.45 + 0.6 * i; }; L.ev = function (i) { for (var k = 0; k < 1 + i * 3; k++) if (Math.random() < 0.5) patla(L.out, 0.02, 'bandpass', 1200 + Math.random() * 5000, 2, 0.18); }; }
  else if (id === 'firtina') { var bp = filtre('bandpass', 500, 0.9); zincir([kaynak('p'), bp, B]); B.gain.value = 1.4; L.nodes.push(lfo(0.07, 320, bp.frequency)); L.nodes.push(lfo(0.11, 0.5, B.gain)); L.set = function (i) { B.gain.value = 0.8 + 1.2 * i; }; }
  else if (id === 'gokgurultusu') { L.ev = function (i) { if (Math.random() < 0.0025 + 0.012 * i) { var s = kaynak('b'), f = filtre('lowpass', 140 + Math.random() * 120), g = AC.createGain(), n = AC.currentTime; g.gain.setValueAtTime(0.0001, n); g.gain.linearRampToValueAtTime(2.2, n + 0.25 + Math.random() * 0.4); g.gain.exponentialRampToValueAtTime(0.0001, n + 4 + Math.random() * 3); zincir([s, f, g, L.out]); s.stop(n + 8); } }; }
  else if (id === 'kampAtesi' || id === 'somine') { var deep = id === 'somine'; zincir([kaynak('b'), filtre('lowpass', deep ? 260 : 420), B]); B.gain.value = deep ? 0.9 : 0.6; L.ev = function (i) { if (Math.random() < (deep ? 0.12 : 0.25) + (deep ? 0.3 : 0.55) * i) patla(L.out, 0.003 + Math.random() * 0.012, 'highpass', 1800 + Math.random() * 2500, 0.7, (deep ? 0.35 : 0.6) * Math.random()); if (Math.random() < 0.02 + 0.04 * i) patla(L.out, 0.04, 'lowpass', 700, 1, 0.5, 'p'); }; }
  else if (id === 'kafe') { var m = AC.createGain(); zincir([kaynak('b'), filtre('bandpass', 420, 0.6), B]); zincir([kaynak('p'), filtre('bandpass', 1100, 1.4), m, B]); B.gain.value = 0.9; L.ev = function (i) { m.gain.value = 0.25 + Math.random() * (0.4 + 0.8 * i); if (Math.random() < 0.008 + 0.02 * i) cik(L.out, 3000 + Math.random() * 1500, 2900, 0.5, 0.05); }; }
  else if (id === 'beyaz') { zincir([kaynak('w'), B]); B.gain.value = 0.5; }
  else if (id === 'pembe') { zincir([kaynak('p'), B]); B.gain.value = 0.8; }
  else if (id === 'kahverengi') { zincir([kaynak('b'), B]); B.gain.value = 0.9; }
  else if (id === 'orman') { zincir([kaynak('p'), filtre('highpass', 2200), B]); B.gain.value = 0.12; L.ev = function (i) { if (Math.random() < 0.01 + 0.05 * i) { var f = 2600 + Math.random() * 2200, n = 2 + Math.floor(Math.random() * 3); for (var k = 0; k < n; k++) (function (k) { setTimeout(function () { if (AC) cik(L.out, f, f * (1.2 + Math.random() * 0.3), 0.07 + Math.random() * 0.05, 0.07); }, k * 110); })(k); } }; }
  else if (id === 'dere' || id === 'sadirvan') { var g2 = AC.createGain(); zincir([kaynak('w'), filtre('bandpass', id === 'dere' ? 1100 : 1900, 0.8), g2, B]); B.gain.value = id === 'dere' ? 0.9 : 0.8; L.ev = function (i) { g2.gain.value = 0.5 + Math.random() * (0.3 + 0.5 * i); if (Math.random() < 0.3) patla(L.out, 0.03 + Math.random() * 0.05, 'bandpass', (id === 'dere' ? 500 : 2600) + Math.random() * 1200, 3, 0.15); }; }
  else if (id === 'deniz') { var wg = AC.createGain(); wg.gain.value = 0.55; zincir([kaynak('p'), filtre('lowpass', 900), wg, B]); B.gain.value = 1.3; L.nodes.push(lfo(0.085, 0.5, wg.gain)); L.set = function (i) { B.gain.value = 0.8 + 1 * i; }; }
  else if (id === 'gece') { var o = AC.createOscillator(), am = AC.createGain(), gate = AC.createGain(); o.type = 'square'; o.frequency.value = 4400; am.gain.value = 0; gate.gain.value = 0; zincir([o, filtre('bandpass', 4400, 9), am, gate, B]); o.start(); L.nodes.push(o); L.nodes.push(lfo(28, 0.5, am.gain)); B.gain.value = 0.25; L.ev = function () { gate.gain.value = Math.random() < 0.6 ? 1 : 0; }; }
  L.tur = 'sentez';
  return L;
}

// ——— Gerçek kayıt motoru: fetch → decodeAudioData → dikişsiz döngü (loopStart=P, loopEnd=P+L) ———
var BUF = {};
function adaylar(f) { var u = ['ses/' + f]; try { u.push(new URL('project/ses/' + f, window.parent.location.href).href); } catch (e) {} try { u.push(new URL('project/ses/' + f, window.top.location.href).href); } catch (e) {} return u; }
function coz(ab) { return new Promise(function (ok, no) { try { var p = AC.decodeAudioData(ab, ok, no); if (p && p.then) p.then(ok, no); } catch (e) { no(e); } }); }
function getir(f) {
  if (BUF[f]) return BUF[f];
  var list = adaylar(f + '.mp3'), i = 0;
  BUF[f] = new Promise(function (ok, no) { (function dene() { if (i >= list.length) { delete BUF[f]; return no(new Error('kayıt yok')); } fetch(list[i++]).then(function (r) { if (!r.ok) throw new Error(r.status); return r.arrayBuffer(); }).then(coz).then(ok, dene); })(); });
  return BUF[f];
}
function dongu(buf, f) { var m = DOSYA[f], s = AC.createBufferSource(); s.buffer = buf; s.loop = true; s.loopStart = m.P; s.loopEnd = m.P + m.L; s.start(0, m.P + Math.random() * m.L * 0.9); return s; }
function kayitKur(L, spec, bufs) {
  var head = AC.createGain(), ga = AC.createGain(), gb = null, fl = null, n = AC.currentTime;
  dongu(bufs[0], spec.a).connect(ga); ga.connect(head);
  if (spec.b) { gb = AC.createGain(); dongu(bufs[1], spec.b).connect(gb); gb.connect(head); }
  if (spec.mod === 'yakin' || spec.mod === 'siddet') { fl = AC.createBiquadFilter(); fl.type = 'lowpass'; fl.Q.value = 0.5; }
  else if (spec.mod === 'citir') { fl = AC.createBiquadFilter(); fl.type = 'highshelf'; fl.frequency.value = 2400; }
  else if (spec.mod === 'derin') { fl = AC.createBiquadFilter(); fl.type = 'lowshelf'; fl.frequency.value = 180; }
  if (fl) { head.connect(fl); fl.connect(L.out); } else head.connect(L.out);
  L.set = function (i) {
    var t = AC.currentTime;
    if (spec.mod === 'karis') { ga.gain.setTargetAtTime(Math.cos(i * Math.PI / 2), t, 0.3); gb.gain.setTargetAtTime(Math.sin(i * Math.PI / 2), t, 0.3); }
    else if (spec.mod === 'yakin') fl.frequency.setTargetAtTime(700 * Math.pow(26, i), t, 0.2);
    else if (spec.mod === 'siddet') { fl.frequency.setTargetAtTime(1100 * Math.pow(13, i), t, 0.25); head.gain.setTargetAtTime(0.55 + 0.75 * i, t, 0.3); }
    else if (spec.mod === 'citir') fl.gain.setTargetAtTime(-14 + 24 * i, t, 0.2);
    else if (spec.mod === 'derin') fl.gain.setTargetAtTime(-6 + 16 * i, t, 0.2);
  };
  L.tur = 'kayit';
}
function kur(id, bitti) {
  var k = KAT[id], L = { out: AC.createGain(), ev: null, nodes: [], tur: 'yukleniyor' }; L.out.gain.value = 0; L.out.connect(MASTER);
  var spec = k[5];
  if (!spec) { sentez(L, id); return L; }
  var fs = [spec.a]; if (spec.b) fs.push(spec.b);
  var ac = AC;
  Promise.all(fs.map(getir)).then(function (bufs) { if (AC !== ac) return; kayitKur(L, spec, bufs); bitti(); }, function () { if (AC !== ac) return; sentez(L, id); bitti(); });
  return L;
}

class Component extends DCLogic {
  constructor(p) {
    super(p); var v = {}, it = {}; KATMAN.forEach(function (k) { v[k[0]] = 0; it[k[0]] = k[3] === 'Yakınlık' ? 75 : 50; });
    var s0 = SAHNE[0][2], i0 = SAHNE[0][3] || {}; for (var k in s0) v[k] = s0[k]; for (var q in i0) it[q] = i0[q];
    this.state = { play: false, master: 80, v: v, it: it, sahne: 0, sure: 0, opt: [true, true, true] };
    this.drops = []; for (var i = 0; i < 28; i++) this.drops.push({ x: Math.round(Math.random() * 390) + 'px', h: Math.round(30 + Math.random() * 40) + 'px', t: (0.7 + Math.random() * 0.6).toFixed(2) + 's', dl: (-Math.random() * 2).toFixed(2) + 's' });
  }
  componentDidMount() { var self = this; this.iv = setInterval(function () { if (!AC || !self.state.play) return; for (var id in LIVE) { var L = LIVE[id]; if (L.ev && self.state.v[id] > 0) L.ev(self.state.it[id] / 100); } }, 50); }
  componentWillUnmount() { clearInterval(this.iv); if (AC) { AC.close(); AC = null; LIVE = {}; } }
  uygula(s) {
    if (!AC) return; var self = this;
    MASTER.gain.setTargetAtTime(s.play ? Math.pow(s.master / 100, 2) : 0, AC.currentTime, 0.2);
    KATMAN.forEach(function (k) { var id = k[0], v = s.v[id]; if (v > 0 && !LIVE[id]) LIVE[id] = kur(id, function () { self.setState({ yt: (self.state.yt || 0) + 1 }); }); var L = LIVE[id]; if (!L) return; L.out.gain.setTargetAtTime(Math.pow(v / 100, 2) * 0.9, AC.currentTime, 0.25); if (L.set) L.set(s.it[id] / 100); });
  }
  setState(p) { var m = Object.assign({}, this.state, p); DCLogic.prototype.setState.call(this, p); this.uygula(m); }
  renderVals() {
    var self = this, s = this.state;
    var aktif = KATMAN.filter(function (k) { return s.v[k[0]] > 0; });
    var layers = KATMAN.map(function (k) { var id = k[0], on = s.v[id] > 0; var L = LIVE[id], tur = L ? L.tur : (k[5] ? 'kayit0' : 'sentez0'); var durum = tur === 'kayit' ? 'Gerçek kayıt · ' + Math.round(DOSYA[k[5].a].L) + ' sn döngü' : tur === 'yukleniyor' ? 'Kayıt yükleniyor…' : tur === 'sentez' ? (k[5] ? 'Sentez ses (kayıt açılamadı)' : 'Cihazda üretilir') : (k[5] ? 'Gerçek kayıt' : 'Cihazda üretilir');
      return { ad: k[1], ik: IK[k[2]], hasI: !!k[3], iLabel: k[3] || '', durum: durum, dColor: tur === 'sentez' && k[5] ? 'rgba(255,200,140,.85)' : 'rgba(170,230,255,.75)', v: s.v[id], i: s.it[id], on: on ? 'true' : 'false', cls: on ? 'g27' : 'g27k', dot: k[4],
      tap: function () { var v = Object.assign({}, self.state.v); v[id] = v[id] > 0 ? 0 : 60; ses(); self.setState({ v: v, sahne: -1, play: true }); },
      setV: function (ev) { var v = Object.assign({}, self.state.v); v[id] = Number(ev.target.value); ses(); self.setState({ v: v, sahne: -1 }); },
      setI: function (ev) { var it = Object.assign({}, self.state.it); it[id] = Number(ev.target.value); self.setState({ it: it }); } }; });
    var scenes = SAHNE.map(function (c, n) { var on = s.sahne === n; return { ad: c[0], ik: IK[c[1]], cls: on ? 'g27t' : 'g27k', color: '#FFFFFF', pick: function () { var v = {}, it = Object.assign({}, self.state.it); KATMAN.forEach(function (k) { v[k[0]] = c[2][k[0]] || 0; it[k[0]] = (c[3] && c[3][k[0]] != null) ? c[3][k[0]] : (k[3] === 'Yakınlık' ? 75 : 50); }); ses(); self.setState({ v: v, it: it, sahne: n, play: true }); } }; });
    var TS = ['Oturumla', '30 dk', '60 dk', 'Sınırsız'];
    var timers = TS.map(function (t, n) { var on = s.sure === n; return { label: t, bg: on ? 'rgba(255,255,255,.9)' : 'rgba(255,255,255,.08)', color: on ? '#0D1B2E' : '#E6F0FF', pick: function () { self.setState({ sure: n }); } }; });
    var OL = ['Bitince yavaşça kıs', 'Ezan vaktinde sustur', 'Kur’an dinlerken kıs'];
    var opts = OL.map(function (t, n) { var on = s.opt[n]; return { label: t, on: on ? 'true' : 'false', bg: on ? 'rgba(111,211,255,.28)' : 'rgba(255,255,255,.05)', color: on ? '#FFFFFF' : 'rgba(225,238,255,.6)', tap: function () { var o = self.state.opt.slice(); o[n] = !o[n]; self.setState({ opt: o }); } }; });
    var yagmurV = Math.max(s.v.yagmur, s.v.yagmurHafif, s.v.yagmurCam);
    return {
      yatayTeker: yatayTeker,
      drops: this.drops, rainOp: s.play && yagmurV > 0 ? String(0.25 + yagmurV / 140) : '0',
      toggle: function () { ses(); self.setState({ play: !self.state.play }); }, playAria: s.play ? 'Durdur' : 'Çal',
      playIcon: s.play ? 'M4 2h5v20H4ZM13 2h5v20h-5Z' : 'M5 2l15 10L5 22Z',
      sceneName: s.sahne >= 0 ? SAHNE[s.sahne][0] : 'Benim karışımım', mixInfo: aktif.length + ' katman · ' + (s.play ? 'çalıyor' : 'duraklatıldı') + ' · ' + aktif.map(function (k) { return k[1].split(' ')[0]; }).join(', '),
      master: s.master, setMaster: function (ev) { ses(); self.setState({ master: Number(ev.target.value) }); },
      timers: timers, scenes: scenes, layers: layers, opts: opts
    };
  }
}
'''
man = json.load(open(B + 'ses/mp3/manifest.json'))
DOS = {k: {'L': v['L'], 'P': v['P']} for k, v in man.items()}
script = script.replace('__DOSYA__', json.dumps(DOS))
html = page('İhya · Odak sesleri', 390, 844, body, script, css).replace(ENGINE, '')
open(OUT + 'OdakSesleri.dc.html', 'w').write(html)
print('ok', len(html))
