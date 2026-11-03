// İhya · tarayıcı doğrulama paketi (node tests/tarayici.js)
// Her İhya ekranını gerçek Chromium'da açar: JS hatası, taşma, kesilen yazı, kaydırma kuralı, bağlantılar,
// bitki büyüme tekdüzeliği ve harf rozeti ortalaması. Çıkış kodu = başarısız test sayısı.
const { chromium } = require('playwright');
const fs = require('fs'), path = require('path');
const R = path.join(__dirname, '..'), P = path.join(R, 'mihrap', 'project'), OUT = path.join(R, 'render');
const EKRAN = ['IhyaBugun', 'IhyaBahce', 'IhyaOdak', 'OdakSesleri', 'IhyaKitaplik', 'HadisHikmet', 'OkumaModu', 'VakitCetveli', 'IhyaSeri', 'BitkiAtlasi'];
const sonuc = [];
const test = (ad, ok, ay) => { sonuc.push([ad, !!ok, ay || '']); };
(async () => {
  const b = await chromium.launch();
  for (const n of EKRAN) {
    fs.copyFileSync(path.join(P, n + '.dc.html'), path.join(OUT, n + '.html'));
    const big = n === 'BitkiAtlasi';
    const p = await b.newPage({ viewport: { width: big ? 1270 : 390, height: big ? 1960 : 844 } });
    const hatalar = [];
    p.on('pageerror', e => hatalar.push(e.message));
    await p.goto('file://' + path.join(OUT, n + '.html'));
    await p.waitForTimeout(900);
    test(n + ' · JS hatası yok', hatalar.length === 0, hatalar.slice(0, 3).join(' | '));
    const r = await p.evaluate((big) => {
      const W = big ? 1270 : 390, out = { tasma: [], kesik: [], yatay: [], dikey: [], link: [] };
      const gizli = el => el.closest('[aria-hidden="true"]');
      for (const el of document.querySelectorAll('body *')) {
        const cs = getComputedStyle(el);
        if (el.classList.contains('yatay')) out.yatay.push({ oy: cs.overflowY, ta: cs.touchAction, ob: cs.overscrollBehaviorX });
        if (el.classList.contains('dikey')) out.dikey.push({ ox: cs.overflowX, ta: cs.touchAction });
        if (el.tagName === 'A') { const h = el.getAttribute('href') || ''; if (/\.dc\.html$/.test(h)) out.link.push(h); }
        if (gizli(el) || el.closest('.yatay')) continue;
        const t = [...el.childNodes].some(c => c.nodeType === 3 && c.textContent.trim());
        if (!t) continue;
        const rc = el.getBoundingClientRect();
        if (rc.width && (rc.right > W + 1 || rc.left < -1)) out.tasma.push(el.textContent.trim().slice(0, 40));
        if (cs.textOverflow === 'ellipsis' && el.scrollWidth > el.clientWidth + 1) out.kesik.push(el.textContent.trim().slice(0, 40));
      }
      return out;
    }, big);
    test(n + ' · yazı ekran dışına taşmıyor', r.tasma.length === 0, r.tasma.slice(0, 4).join(' | '));
    test(n + ' · kesilen (…) yazı yok', r.kesik.length === 0, r.kesik.slice(0, 4).join(' | '));
    if (r.yatay.length) test(n + ' · yatay şeritler yön kilitli (' + r.yatay.length + ')', r.yatay.every(y => y.oy === 'hidden' && y.ta === 'pan-x' && y.ob === 'contain'), JSON.stringify(r.yatay[0]));
    if (r.dikey.length) test(n + ' · dikey listeler yalnız dikey (' + r.dikey.length + ')', r.dikey.every(y => y.ox === 'hidden' && y.ta === 'pan-y'), JSON.stringify(r.dikey[0]));
    const yok = [...new Set(r.link)].filter(h => !fs.existsSync(path.join(P, h)));
    test(n + ' · bağlantılar mevcut ekranlara gidiyor', yok.length === 0, yok.join(', '));
    await p.close();
  }
  // Bitki büyümesi: her tür için çizimin yüksekliği ve alanı süre arttıkça azalmamalı
  {
    const p = await b.newPage();
    await p.setContent('<svg id="s" width="400" height="480" viewBox="-12 -24 124 149"></svg><script>' + fs.readFileSync(path.join(R, 'engine', 'bitki.js'), 'utf8') + '</script>');
    const r = await p.evaluate(() => {
      const s = document.getElementById('s'), sonuc = {};
      for (const t of Object.keys(BITKI)) {
        const seri = [];
        for (let dk = 10; dk <= 120; dk += 5) {
          s.innerHTML = '';
          for (const q of bitkiCiz(t, dk, 5, {})) { const e = document.createElementNS('http://www.w3.org/2000/svg', 'path'); e.setAttribute('d', q.d); s.appendChild(e); }
          const bb = s.getBBox(); seri.push([dk, +(bb.height).toFixed(2), +(bb.width * bb.height).toFixed(1)]);
        }
        let bozuk = [];
        for (let i = 1; i < seri.length; i++) if (seri[i][1] < seri[i - 1][1] * 0.985 || seri[i][2] < seri[i - 1][2] * 0.97) bozuk.push(seri[i - 1][0] + '→' + seri[i][0]);
        sonuc[t] = { bozuk, h10: seri[0][1], h120: seri[seri.length - 1][1] };
      }
      return sonuc;
    });
    for (const [t, v] of Object.entries(r)) test('Bitki · ' + t + ' süre arttıkça küçülmüyor (boy ' + v.h10 + '→' + v.h120 + ')', v.bozuk.length === 0 && v.h120 > v.h10, v.bozuk.join(', '));
    await p.close();
  }
  // Harf rozetleri: mürekkep sınır kutusunun merkezi kutu merkezinde (±1 px / 240 px)
  {
    const p = await b.newPage({ viewport: { width: 240, height: 2400 } });
    await p.goto('file://' + path.join(OUT, 'harf_test.html'));
    const r = await p.evaluate(async () => {
      const out = [];
      for (const svg of document.querySelectorAll('svg')) {
        const img = new Image(); img.src = URL.createObjectURL(new Blob([svg.outerHTML], { type: 'image/svg+xml' })); await img.decode();
        const c = document.createElement('canvas'); c.width = c.height = 240; const x = c.getContext('2d'); x.fillStyle = '#fff'; x.fillRect(0, 0, 240, 240); x.drawImage(img, 0, 0);
        const d = x.getImageData(0, 0, 240, 240).data; let x0 = 240, y0 = 240, x1 = 0, y1 = 0;
        for (let y = 0; y < 240; y++) for (let i = 0; i < 240; i++) if (d[(y * 240 + i) * 4] < 128) { x0 = Math.min(x0, i); x1 = Math.max(x1, i); y0 = Math.min(y0, y); y1 = Math.max(y1, y); }
        out.push([(x0 + x1 + 1) / 2 - 120, (y0 + y1 + 1) / 2 - 120]);
      }
      return out;
    });
    test('Harf rozetleri ortalı (' + r.length + ' harf)', r.length === 9 && r.every(([a, c]) => Math.abs(a) <= 1 && Math.abs(c) <= 1), JSON.stringify(r));
    await p.close();
  }
  await b.close();
  for (const [ad, ok, ay] of sonuc) console.log((ok ? '✓ ' : '✗ ') + ad + (ok || !ay ? '' : '  → ' + ay));
  const bas = sonuc.filter(s => !s[1]).length;
  console.log('\n' + (sonuc.length - bas) + '/' + sonuc.length + ' test geçti');
  process.exit(bas);
})();
