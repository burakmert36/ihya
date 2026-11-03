/* İhya bitki motoru — türe özel evreler, sürekli büyüme. viewBox 0 0 100 120, zemin y=112 */
var BITKI = {
  menekse: { ad: 'Menekşe', tur: 'Çiçek', dk: 15, renk: '#8A4FE0', evre: [['Filiz', 0, 5], ['Tomurcuk', 5, 10], ['Menekşe', 10, 15]], not: 'Kısa oturumların çiçeği. Gölgede de açar; az zamanı bereketlendirmeyi hatırlatır.', kilit: 'Baştan açık' },
  lale: { ad: 'Lale', tur: 'Çiçek', dk: 20, renk: '#E8202A', evre: [['Soğan', 0, 5], ['Yaprak', 5, 10], ['Tomurcuk', 10, 15], ['Lâle-i Rûmî', 15, 20]], not: 'Osmanlı çini ve tezhibinin çiçeği. Arap harfleriyle lâle (لاله) ile Allah (الله) aynı harflerle yazılır.', kilit: 'Baştan açık' },
  reyhan: { ad: 'Reyhan', tur: 'Çiçek', dk: 20, renk: '#3FA34D', evre: [['Filiz', 0, 7], ['Fide', 7, 14], ['Reyhan', 14, 20]], not: 'Hz. Peygamber torunları Hasan ile Hüseyin için “Bu ikisi dünyadaki iki reyhanımdır” buyurdu (Buhârî, 3753).', kilit: '3 günlük seri' },
  sumbul: { ad: 'Sümbül', tur: 'Çiçek', dk: 25, renk: '#6A55F0', evre: [['Soğan', 0, 6], ['Yapraklar', 6, 14], ['Salkım', 14, 20], ['Açmış sümbül', 20, 25]], not: 'Kışın ortasında kokusuyla açan çiçek; sabrın meyvesi.', kilit: '5 dikim' },
  gul: { ad: 'Gül', tur: 'Çiçek', dk: 30, renk: '#E01848', evre: [['Filiz', 0, 10], ['Gonca', 10, 20], ['Gül', 20, 30]], not: 'Divan şiirinde gönlün ve muhabbetin sembolü. İlk 10 dk filiz, sonra gonca, son 10 dakikada açar.', kilit: 'Baştan açık' },
  lavanta: { ad: 'Lavanta', tur: 'Çiçek', dk: 35, renk: '#8E63E8', evre: [['Filiz', 0, 10], ['Gövde', 10, 22], ['Başaklar', 22, 35]], not: 'Uzun ve sakin okumaların çiçeği; kokusu tarlaya yayılır.', kilit: '10 saat odak' },
  badem: { ad: 'Badem', tur: 'Ağaç', dk: 35, renk: '#F29BB8', evre: [['Fidan', 0, 10], ['Tomurcuk', 10, 20], ['Çiçekli badem', 20, 35]], not: 'Kış bitmeden ilk çiçek açan ağaç. Fresh start: her yeni ayın ilk oturumunda tohumu verilir.', kilit: 'Ayın ilk günü' },
  servi: { ad: 'Servi', tur: 'Ağaç', dk: 40, renk: '#1F5A3A', evre: [['Fide', 0, 10], ['Fidan', 10, 25], ['Servi', 25, 40]], not: 'Osmanlı bahçelerinde dik duruşun, istikametin sembolü.', kilit: '7 günlük seri' },
  turunc: { ad: 'Turunç', tur: 'Ağaç', dk: 45, renk: '#FF9A1F', evre: [['Fide', 0, 10], ['Fidan', 10, 20], ['Çiçekli', 20, 35], ['Meyveli', 35, 45]], not: '“Kur’an okuyan mü’min turunç gibidir; tadı da güzel, kokusu da güzel.” (Buhârî, 5020). Kur’an oturumlarına özel.', kilit: 'İlk Kur’an oturumu' },
  nar: { ad: 'Nar', tur: 'Ağaç', dk: 50, renk: '#E2273A', evre: [['Fidan', 0, 10], ['Genç nar', 10, 25], ['Çiçekli', 25, 40], ['Meyveli', 40, 50]], not: '“İkisinde de meyveler, hurmalar ve narlar vardır.” (Rahmân 55:68)', kilit: '20 dikim' },
  zeytin: { ad: 'Zeytin', tur: 'Ağaç', dk: 60, renk: '#8FB07A', evre: [['Fide', 0, 10], ['Fidan', 10, 25], ['Genç zeytin', 25, 45], ['Meyveli', 45, 60]], not: 'Kur’an’da “mübarek bir ağaç” (Nûr 24:35) ve üzerine yemin edilen ağaç (Tîn 95:1).', kilit: 'Baştan açık' },
  hurma: { ad: 'Hurma', tur: 'Ağaç', dk: 90, renk: '#E07B1F', evre: [['Fide', 0, 15], ['Fidan', 15, 40], ['Genç hurma', 40, 70], ['Salkımlı', 70, 90]], not: '“Ağaçlar içinde yaprağı dökülmeyen bir ağaç vardır; o, müslümanın misalidir.” (Buhârî, 61)', kilit: '30 günlük seri' },
  cinar: { ad: 'Çınar', tur: 'Ağaç', dk: 120, renk: '#5DBB4C', evre: [['Fide', 0, 20], ['Fidan', 20, 50], ['Genç çınar', 50, 90], ['Ulu çınar', 90, 120]], not: '“Cennette bir ağaç vardır; binekli kimse gölgesinde yüz yıl yürür de onu geçemez.” (Buhârî, 3252)', kilit: '100 saat odak' }
};
var BITKI_SIRA = ['menekse', 'lale', 'reyhan', 'sumbul', 'gul', 'lavanta', 'badem', 'servi', 'turunc', 'nar', 'zeytin', 'hurma', 'cinar'];

function bitkiEvre(tur, dk, temel) {
  var b = BITKI[tur], ev = temel ? b.temel : b.evre, i = 0;
  for (var k = 0; k < ev.length; k++) { if (dk >= ev[k][1]) i = k; }
  var e = ev[i], p = Math.max(0, Math.min(1, (dk - e[1]) / (e[2] - e[1])));
  return { i: i, ad: e[0], p: p, kalan: Math.max(0, Math.ceil(e[2] - dk)), sonraki: ev[i + 1] ? ev[i + 1][0] : null, son: i === ev.length - 1, tamam: dk >= b.dk };
}

function bitkiTemel(tur, dk, seed, opt) {
  opt = opt || {};
  var lod = opt.lod || 1;
  var S = [];
  var r = rnd(seed || 7);
  var E = bitkiEvre(tur, Math.min(dk, BITKI[tur].dk - 0.001), true);
  var i = E.i, p = E.p, bol = opt.bolluk || 0;
  function f(n) { return Math.round(n * 10) / 10; }
  function add(d, fill, o, stroke, w) { S.push({ d: d, f: fill || 'none', s: stroke || 'none', w: w || 0, o: o == null ? 1 : o }); }
  function C(cx, cy, rr) { return 'M' + f(cx - rr) + ' ' + f(cy) + 'a' + f(rr) + ' ' + f(rr) + ' 0 1 0 ' + f(2 * rr) + ' 0a' + f(rr) + ' ' + f(rr) + ' 0 1 0 ' + f(-2 * rr) + ' 0Z'; }
  function El(cx, cy, rx, ry) { return 'M' + f(cx - rx) + ' ' + f(cy) + 'a' + f(rx) + ' ' + f(ry) + ' 0 1 0 ' + f(2 * rx) + ' 0a' + f(rx) + ' ' + f(ry) + ' 0 1 0 ' + f(-2 * rx) + ' 0Z'; }
  function leaf(x, y, a, len, w) {
    var tx = x + Math.cos(a) * len, ty = y + Math.sin(a) * len, mx = (x + tx) / 2, my = (y + ty) / 2, px = -Math.sin(a) * w, py = Math.cos(a) * w;
    return 'M' + f(x) + ' ' + f(y) + 'Q' + f(mx + px) + ' ' + f(my + py) + ' ' + f(tx) + ' ' + f(ty) + 'Q' + f(mx - px) + ' ' + f(my - py) + ' ' + f(x) + ' ' + f(y) + 'Z';
  }
  function rib(x, y, a, len) { return 'M' + f(x) + ' ' + f(y) + 'L' + f(x + Math.cos(a) * len * 0.82) + ' ' + f(y + Math.sin(a) * len * 0.82); }
  function Q(x0, y0, cx, cy, x1, y1) { return 'M' + f(x0) + ' ' + f(y0) + 'Q' + f(cx) + ' ' + f(cy) + ' ' + f(x1) + ' ' + f(y1); }
  function lerp(a, b, t) { return a + (b - a) * t; }
  function ease(t) { return 1 - Math.pow(1 - t, 2); }
  function shadow(rx) { add(El(50, 112, rx, rx * 0.22), 'url(#gGolge)', 1); }
  function mound(w) { add('M' + f(50 - w) + ' 112Q50 ' + f(112 - w * 0.42) + ' ' + f(50 + w) + ' 112Z', 'url(#gToprak)'); }
  function stem(x0, y0, x1, y1, bend, w, col) { add(Q(x0, y0, (x0 + x1) / 2 + bend, (y0 + y1) / 2, x1, y1), 'none', 1, col || '#3C8F45', w); }
  function canopy(cx, cy, R, n, grad, lgrad, ry) { // ışığı sol üstten alan küre kümeleri + yaprak dokusu
    ry = ry || 0.78;
    var pts = [];
    for (var k = 0; k < n; k++) { var a = r() * Math.PI * 2, d = Math.sqrt(r()) * R * 0.62; pts.push([cx + Math.cos(a) * d, cy + Math.sin(a) * d * ry, R * (0.36 + r() * 0.2)]); }
    pts.sort(function (A, B) { return (A[1] + A[0] * 0.3) - (B[1] + B[0] * 0.3); });
    add(El(cx + R * 0.08, cy + R * 0.12, R * 0.98, R * 0.98 * ry), grad, 0.55);
    pts.forEach(function (q) { add(C(q[0], q[1], q[2]), grad); });
    if (lod > 0.6) {
      var m = Math.round(n * 2.2 * lod);
      for (var k2 = 0; k2 < m; k2++) { var a2 = r() * Math.PI * 2, d2 = Math.sqrt(r()) * R * 0.9; var lx = cx + Math.cos(a2) * d2, ly = cy + Math.sin(a2) * d2 * ry; add(leaf(lx, ly, r() * 6.28, R * 0.26, R * 0.09), (ly < cy && lx < cx + R * 0.2) ? lgrad : grad, 0.9); }
    }
    add(El(cx - R * 0.35, cy - R * 0.38 * ry, R * 0.32, R * 0.2), 'url(#gParlak)', 0.55);
  }
  function trunk(x, y, h, w0, w1, bend, grad) {
    add('M' + f(x - w0) + ' ' + f(y) + 'Q' + f(x - w0 * 0.6 + bend) + ' ' + f(y - h * 0.5) + ' ' + f(x - w1 + bend) + ' ' + f(y - h) + 'L' + f(x + w1 + bend) + ' ' + f(y - h) + 'Q' + f(x + w0 * 0.6 + bend) + ' ' + f(y - h * 0.5) + ' ' + f(x + w0) + ' ' + f(y) + 'Z', grad || 'url(#gGovde)');
  }
  function branch(x0, y0, x1, y1, w, col) { add(Q(x0, y0, (x0 + x1) / 2, Math.min(y0, y1) + (Math.abs(y1 - y0)) * 0.2, x1, y1), 'none', 1, col || '#6E4A30', w); }
  function blossom(x, y, rr, grad, center) { for (var k = 0; k < 5; k++) { var a = k * 1.2566 - 1.57; add(C(x + Math.cos(a) * rr * 0.62, y + Math.sin(a) * rr * 0.62, rr * 0.55), grad); } add(C(x, y, rr * 0.3), center || '#FFC93C'); }
  function fruit(x, y, rr, grad) { add(C(x, y, rr), grad); add(C(x - rr * 0.35, y - rr * 0.35, rr * 0.28), '#FFFFFF', 0.55); }

  if (tur === 'gul') {
    shadow(14 + i * 4);
    if (i === 0) { var h0 = lerp(10, 26, ease(p)); stem(50, 112, 50, 112 - h0, 2, 1.8); add(leaf(50, 112 - h0 * 0.55, -2.6, 10, 3.6), 'url(#gYaprak)'); add(leaf(50, 112 - h0 * 0.8, -0.5, 10 * p + 4, 3.2), 'url(#gYaprakGenc)'); add(leaf(50, 112 - h0, -1.9, 6 * p + 3, 2.4), 'url(#gYaprakGenc)'); }
    else {
      var H = i === 1 ? lerp(30, 54, ease(p)) : 56, top = 112 - H;
      stem(50, 112, 50, top, 3, 2.4, '#2F7A3A');
      var lv = [[0.25, -2.6], [0.42, -0.5], [0.6, -2.4], [0.75, -0.7]];
      lv.forEach(function (q, k) { if (i === 1 && k > 1 + p * 3) return; var y = 112 - H * q[0], len = 13; add(leaf(50, y, q[1], len, 4.2), 'url(#gYaprak)'); add(rib(50, y, q[1], len), 'none', 0.5, '#1F5E2C', 0.5); add(leaf(50 + Math.cos(q[1]) * len * 0.55, y + Math.sin(q[1]) * len * 0.55, q[1] - 0.7, 6, 2.2), 'url(#gYaprak)'); add(leaf(50 + Math.cos(q[1]) * len * 0.55, y + Math.sin(q[1]) * len * 0.55, q[1] + 0.7, 6, 2.2), 'url(#gYaprak)'); });
      // dikenler
      for (var k = 0; k < 4; k++) { var ty = 112 - H * (0.2 + k * 0.17); add('M50 ' + f(ty) + 'l' + (k % 2 ? 2.2 : -2.2) + ' -1.4l' + (k % 2 ? -1.2 : 1.2) + ' 2.4Z', '#5E2A1E'); }
      if (i === 1) { // gonca
        var bs = lerp(3.4, 7, ease(p));
        add(leaf(50, top + 2, -1.57, bs * 2.3, bs * 0.95), 'url(#gGonca)');
        add(leaf(50, top + 2.5, -2.2, bs * 1.7, bs * 0.5), 'url(#gYaprak)'); add(leaf(50, top + 2.5, -0.95, bs * 1.7, bs * 0.5), 'url(#gYaprak)');
      } else { // açan gül
        var o = ease(Math.min(1, p * 1.25)), R = lerp(7, 13.5, o), cy = top - R * 0.35;
        add(leaf(50, top + 2, -2.5, 7, 2.2), 'url(#gYaprak)'); add(leaf(50, top + 2, -0.6, 7, 2.2), 'url(#gYaprak)');
        for (var k = 0; k < 6; k++) { var a = -1.57 + (k - 2.5) * (0.5 + o * 0.42); add(leaf(50, cy + R * 0.55, a, R * (1.05 + o * 0.2), R * 0.62), 'url(#gGulDis)'); }
        for (var k = 0; k < 5; k++) { var a2 = -1.57 + (k - 2) * (0.45 + o * 0.25); add(leaf(50, cy + R * 0.42, a2, R * 0.92, R * 0.55), 'url(#gGul)'); }
        add(El(50, cy, R * 0.62, R * 0.5), 'url(#gGul)');
        add('M' + f(50 - R * 0.45) + ' ' + f(cy) + 'Q50 ' + f(cy - R * 0.62) + ' ' + f(50 + R * 0.45) + ' ' + f(cy) + 'Q50 ' + f(cy + R * 0.25) + ' ' + f(50 - R * 0.2) + ' ' + f(cy - R * 0.1), 'url(#gGulIc)');
        add('M' + f(50 - R * 0.18) + ' ' + f(cy - R * 0.12) + 'Q50 ' + f(cy - R * 0.36) + ' ' + f(50 + R * 0.2) + ' ' + f(cy - R * 0.08), 'none', 0.8, '#6E0420', 0.8);
        add(El(50 - R * 0.3, cy - R * 0.3, R * 0.22, R * 0.12), '#FFFFFF', 0.35);
      }
    }
  } else if (tur === 'lale') {
    shadow(10 + i * 3);
    if (i === 0) { mound(10); var hb = lerp(1, 7, ease(p)); add(El(50, 111, 4.2, 3), 'url(#gSogan)'); if (p > 0.15) add(leaf(50, 109, -1.57, hb + 2, 1.6), 'url(#gYaprakGenc)'); }
    else {
      var Hs = i === 1 ? lerp(10, 26, ease(p)) : i === 2 ? lerp(28, 44, ease(p)) : 46;
      add(leaf(50, 112, -1.95, lerp(14, 30, i === 1 ? p : 1), 5.5), 'url(#gLaleYaprak)');
      add(leaf(50, 112, -1.2, lerp(12, 26, i === 1 ? p : 1), 5), 'url(#gLaleYaprak)');
      if (i >= 2) {
        stem(50, 112, 50, 112 - Hs, -1.5, 1.9, '#4C9A4A');
        var tb = 112 - Hs, op = i === 3 ? ease(p) : 0, sz = i === 2 ? lerp(4, 8, ease(p)) : 9;
        var col = i === 2 ? 'url(#gLaleTom)' : 'url(#gLale)';
        add(leaf(50, tb + 1, -1.57 - 0.22 - op * 0.34, sz * 2.4, sz * 0.72), col);
        add(leaf(50, tb + 1, -1.57 + 0.22 + op * 0.34, sz * 2.4, sz * 0.72), col);
        add(leaf(50, tb + 1.5, -1.57, sz * 2.55, sz * 0.62), i === 2 ? 'url(#gLaleTom)' : 'url(#gLaleOn)');
        if (i === 3) add(El(50 - 2, tb - sz * 1.5, 1, sz * 0.5), '#FFFFFF', 0.4);
      } else { stem(50, 112, 50, 112 - Hs * 0.5, 0, 1.4, '#4C9A4A'); }
    }
  } else if (tur === 'menekse') {
    shadow(12 + i * 2);
    var n0 = i === 0 ? 2 + Math.round(p * 2) : 6;
    for (var k = 0; k < n0; k++) { var a = -1.57 + (k - (n0 - 1) / 2) * 0.62; var L = i === 0 ? lerp(5, 10, p) : 12; add(leaf(50, 111, a, L, L * 0.55), 'url(#gYaprakKoyu)'); }
    if (i >= 1) {
      var fl = [[-9, 88], [0, 84], [9, 89], [-4, 93], [5, 94]];
      fl.forEach(function (q, k) {
        var x = 50 + q[0], y = q[1] + (i === 1 ? (1 - p) * 8 : 0);
        stem(50, 110, x, y, q[0] * 0.2, 1, '#3E7F3E');
        if (i === 1) add(leaf(x, y + 2, -1.57, 4 + p * 2, 1.6), 'url(#gMenekse)');
        else { var s = lerp(2.4, 4.4, ease(p)); add(leaf(x, y, -2.1, s * 1.5, s * 0.8), 'url(#gMenekse)'); add(leaf(x, y, -1.05, s * 1.5, s * 0.8), 'url(#gMenekse)'); add(leaf(x, y, 1.0, s * 1.3, s * 0.85), 'url(#gMenekse)'); add(leaf(x, y, 2.15, s * 1.3, s * 0.85), 'url(#gMenekse)'); add(leaf(x, y, 1.57, s * 1.5, s * 0.9), 'url(#gMenekse)'); add(C(x, y, s * 0.32), '#FFD43B'); }
      });
    }
  } else if (tur === 'reyhan') {
    add('M36 98L64 98L61 113L39 113Z', 'url(#gSaksi)'); add('M34.5 95.5h31v4h-31Z', 'url(#gSaksiAgiz)'); add(El(50, 97, 14, 1.6), '#5A3A26');
    var Hr = i === 0 ? lerp(4, 10, ease(p)) : i === 1 ? lerp(12, 24, ease(p)) : 28, nb = i === 0 ? 2 : i === 1 ? 6 + Math.round(p * 6) : 16;
    stem(50, 97, 50, 97 - Hr, 1, 1.6, '#3E8E43');
    for (var k = 0; k < nb; k++) { var t = k / Math.max(1, nb - 1), y = 97 - Hr * (0.2 + t * 0.75), side = k % 2 ? 1 : -1, a = side > 0 ? -0.5 - t * 0.5 : -2.6 + t * 0.5, L = lerp(9, 5, t) * (i === 0 ? 0.7 : 1); add(leaf(50 + side * 1, y, a, L, L * 0.48), k % 3 === 0 ? 'url(#gYaprakGenc)' : 'url(#gReyhan)'); }
    if (i === 2) { for (var k = 0; k < 7; k++) { add(C(50 + (k % 2 ? 1.2 : -1.2), 97 - Hr - 1 - k * 1.6 * ease(p), 1.1), '#FFFFFF'); } }
  } else if (tur === 'sumbul') {
    shadow(10 + i * 2);
    if (i === 0) { mound(10); add(El(50, 110.5, 5, 3.4), 'url(#gSoganMor)'); if (p > 0.2) add(leaf(50, 108, -1.57, 2 + p * 5, 1.8), 'url(#gYaprakGenc)'); }
    else {
      var lh = i === 1 ? lerp(10, 22, ease(p)) : 24;
      [-2.1, -1.8, -1.35, -1.05].forEach(function (a) { add(leaf(50, 112, a, lh, 3.4), 'url(#gLaleYaprak)'); });
      if (i >= 2) {
        var sh = i === 2 ? lerp(20, 36, ease(p)) : 38; stem(50, 112, 50, 112 - sh, 0, 2.6, '#4C9A4A');
        var rows = 9, open = i === 3 ? ease(p) : 0;
        for (var k = 0; k < rows; k++) { var y = 112 - sh + k * 2.4, w = 3.5 + Math.sin((k / rows) * 3.14) * 2.4; [-1, 0, 1].forEach(function (c) { var x = 50 + c * w * 0.75; if (open > 0.05) { for (var j = 0; j < 4; j++) { var a = j * 1.57 + 0.78; add(leaf(x, y, a, 1.6 + open * 1.6, 0.9 + open * 0.5), 'url(#gSumbul)'); } add(C(x, y, 0.7), '#FFFFFF', 0.8); } else add(C(x, y, 1.4), i === 2 ? 'url(#gSumbulTom)' : 'url(#gSumbul)'); }); }
      }
    }
  } else if (tur === 'lavanta') {
    shadow(14 + i * 4);
    var bushH = i === 0 ? lerp(5, 12, ease(p)) : i === 1 ? lerp(12, 22, ease(p)) : 22, cnt = i === 0 ? 5 : 12;
    for (var k = 0; k < cnt; k++) { var a = -1.57 + (k - (cnt - 1) / 2) * 0.16; add(leaf(50 + (k - cnt / 2) * 0.6, 112, a, bushH * (0.75 + r() * 0.35), 1.4), 'url(#gLavantaYaprak)'); }
    if (i >= 1) {
      var spikes = i === 1 ? 3 + Math.round(p * 4) : 9, sl = i === 1 ? lerp(10, 24, p) : 32, col = i === 2 ? 'url(#gLavanta)' : 'url(#gLavantaYaprak)';
      for (var k = 0; k < spikes; k++) { var a = -1.57 + (k - (spikes - 1) / 2) * 0.085, x1 = 50 + Math.cos(a) * sl, y1 = 110 + Math.sin(a) * sl * (0.85 + (k % 3) * 0.07); stem(50, 108, x1, y1, 0, 0.8, '#7E9A6E'); if (i === 2) { var g = ease(p); for (var j = 0; j < 7; j++) { add(El(x1 - Math.cos(a) * j * 1.5, y1 - Math.sin(a) * j * 1.5, 0.9 + g * 0.5, 1.3 + g * 0.4), j % 2 ? col : 'url(#gMenekse)'); } } }
    }
  } else if (tur === 'badem') {
    shadow(14 + i * 6);
    // Süre = boy: gövde ve dallar her evrede bir öncekinin bittiği yerden büyümeye devam eder (sıçrama/küçülme yok)
    var th = i === 0 ? lerp(16, 34, ease(p)) : i === 1 ? lerp(34, 40, ease(p)) : lerp(40, 46, ease(p)), tw = i === 0 ? 1.6 : lerp(2.4, 2.9, i === 1 ? p * 0.5 : 0.5 + p * 0.5);
    trunk(50, 112, th, tw, tw * 0.5, 1, 'url(#gGovdeKoyu)');
    var bs = i === 1 ? lerp(0.8, 0.92, ease(p)) : i === 2 ? lerp(0.92, 1, ease(p)) : 1;
    var br = i === 0 ? [[-8, 12], [7, 10]] : [[-16, 20], [-8, 26], [6, 27], [16, 18], [-2, 30]].map(function (q) { return [q[0] * bs, q[1] * bs]; });
    br.forEach(function (q) { branch(50, 112 - th * 0.75, 50 + q[0], 112 - th - q[1] * 0.5, i === 0 ? 1 : 1.6, '#4A2F22'); });
    if (i === 0) { br.forEach(function (q) { add(leaf(50 + q[0], 112 - th - q[1] * 0.5, -1.2, 5, 1.8), 'url(#gYaprakGenc)'); }); }
    else {
      var nfl = i === 1 ? 26 : 44;
      // Her çiçek için rastgele sayılar aynı sırayla çekilir: tomurcuk evresindeki ilk 26 nokta çiçek evresinde de aynı yerde açar
      for (var k = 0; k < nfl; k++) { var q = br[k % br.length], t = r(), jx = r(), jy = r(), js = r(), x = lerp(50, 50 + q[0], 0.4 + t * 0.6) + (jx - 0.5) * 8, y = lerp(112 - th * 0.75, 112 - th - q[1] * 0.5, 0.4 + t * 0.6) + (jy - 0.5) * 8;
        if (i === 1) { add(C(x, y, 0.9 + p * 0.8), p > 0.5 ? '#F6B3C8' : '#9C4E5A'); } else { var s = lerp(1.6, 2.8, ease(p)) * (0.8 + js * 0.4); blossom(x, y, s, k % 3 ? 'url(#gBadem)' : 'url(#gBeyaz)', '#D9466E'); } }
    }
  } else if (tur === 'servi') {
    shadow(9 + i * 3);
    var sh2 = i === 0 ? lerp(12, 26, ease(p)) : i === 1 ? lerp(30, 62, ease(p)) : lerp(66, 92, ease(p)), sw = sh2 * 0.17 + 3;
    trunk(50, 112, 8, 2, 1.6, 0, 'url(#gGovde)');
    var top2 = 106 - sh2;
    add('M50 ' + f(top2) + 'C' + f(50 + sw * 1.15) + ' ' + f(top2 + sh2 * 0.35) + ' ' + f(50 + sw) + ' ' + f(104) + ' 50 104C' + f(50 - sw) + ' 104 ' + f(50 - sw * 1.15) + ' ' + f(top2 + sh2 * 0.35) + ' 50 ' + f(top2) + 'Z', 'url(#gServi)');
    for (var k = 0; k < 9; k++) { var t = 0.12 + k * 0.095, yy = top2 + sh2 * t, ww = sw * Math.sin(Math.min(3.0, t * 3.2)) * 0.95; add(El(50 - ww * 0.7, yy, ww * 0.45, sh2 * 0.06), 'url(#gServi)'); add(El(50 + ww * 0.7, yy + 2, ww * 0.42, sh2 * 0.055), 'url(#gServi)'); }
    for (var k = 0; k < Math.round(10 * lod); k++) { var t = 0.15 + k * 0.08, y = top2 + sh2 * t, w = sw * Math.sin(t * 3.0) * 0.9; add(Q(50 - w, y + 3, 50, y - 1.5, 50 + w, y + 3), 'none', 0.35, '#0B2A1D', 0.8); }
    add('M' + f(50 - sw * 0.25) + ' ' + f(top2 + sh2 * 0.15) + 'C' + f(50 - sw * 0.75) + ' ' + f(top2 + sh2 * 0.4) + ' ' + f(50 - sw * 0.6) + ' ' + f(top2 + sh2 * 0.8) + ' ' + f(50 - sw * 0.35) + ' ' + f(top2 + sh2 * 0.92), 'none', 0.5, '#9FD9A0', 1.2);
  } else if (tur === 'turunc' || tur === 'nar' || tur === 'zeytin' || tur === 'cinar') {
    var cfg = { turunc: { th: [12, 22, 34, 36], R: [5, 10, 17, 18], g: 'url(#gKureKoyu)', lg: 'url(#gYaprakParlak)', bark: 'url(#gGovde)', ry: 0.86 },
      nar: { th: [12, 24, 34, 36], R: [5, 11, 17, 18], g: 'url(#gKureNar)', lg: 'url(#gYaprakParlak)', bark: 'url(#gGovde)', ry: 0.8 },
      zeytin: { th: [10, 22, 32, 34], R: [5, 11, 18, 20], g: 'url(#gKureZeytin)', lg: 'url(#gZeytinGumus)', bark: 'url(#gGovdeGri)', ry: 0.66 },
      cinar: { th: [12, 26, 38, 46], R: [5, 13, 21, 28], g: 'url(#gKureCinar)', lg: 'url(#gYaprakGenc)', bark: 'url(#gGovdeCinar)', ry: 0.72 } }[tur];
    var g0 = i === 0 ? ease(p) : 1, prev = Math.max(0, i - 1);
    var TH = lerp(i === 0 ? cfg.th[0] * 0.5 : cfg.th[prev], cfg.th[i], ease(p)), RR = lerp(i === 0 ? cfg.R[0] * 0.5 : cfg.R[prev], cfg.R[i], ease(p));
    shadow(RR * 0.9 + 4);
    if (i === 0) { stem(50, 112, 50, 112 - TH, 1.2, 1.6, '#5E4632'); for (var k = 0; k < 4; k++) add(leaf(50, 112 - TH + k * 2, k % 2 ? -0.5 : -2.6, 4 + RR * 0.6, 1.6 + RR * 0.25), tur === 'zeytin' ? 'url(#gZeytinGumus)' : 'url(#gYaprak)'); }
    else {
      var tw2 = { turunc: 2.4, nar: 2, zeytin: 3.2, cinar: 4.2 }[tur] * (0.6 + i * 0.2);
      var bend = tur === 'zeytin' ? 4 : 1;
      if (tur === 'nar') { trunk(48, 112, TH * 0.9, tw2 * 0.7, tw2 * 0.4, -3, cfg.bark); trunk(52, 112, TH, tw2 * 0.8, tw2 * 0.45, 3, cfg.bark); }
      else trunk(50, 112, TH, tw2, tw2 * 0.55, bend, cfg.bark);
      if (tur === 'zeytin') { add(Q(50 - tw2 * 0.3, 110, 47, 100, 50 + bend * 0.6, 112 - TH * 0.6), 'none', 0.55, '#3C352D', 0.9); add(El(50 + bend * 0.3, 112 - TH * 0.45, tw2 * 0.35, 1.6), '#3C352D', 0.6); }
      if (tur === 'cinar') { for (var k = 0; k < 6; k++) add(El(50 + (r() - 0.5) * tw2 * 1.2, 112 - TH * (0.15 + r() * 0.7), 1.4 + r(), 0.9 + r() * 0.6), r() > 0.5 ? '#E8DCC0' : '#9C8F70', 0.85); }
      branch(50 + bend, 112 - TH * 0.7, 50 - RR * 0.5, 112 - TH - RR * 0.2, tw2 * 0.45, '#5E4632'); branch(50 + bend, 112 - TH * 0.75, 50 + RR * 0.55, 112 - TH - RR * 0.25, tw2 * 0.4, '#5E4632');
      var cy0 = 112 - TH - RR * cfg.ry * 0.55;
      canopy(50 + bend * 0.5, cy0, RR, 8 + i * 3, cfg.g, cfg.lg, cfg.ry);
      if (tur === 'zeytin' && lod > 0.6) { for (var k = 0; k < 18 * lod; k++) { var a = r() * 6.28, d = Math.sqrt(r()) * RR * 0.9; add(leaf(50 + Math.cos(a) * d, cy0 + Math.sin(a) * d * cfg.ry, r() * 6.28, RR * 0.3, RR * 0.06), 'url(#gZeytinGumus)', 0.95); } }
      // çiçek ve meyveler
      var last = BITKI[tur].temel.length - 1;
      var fl2 = (tur === 'turunc' && i === 2) || (tur === 'nar' && i === 2), fr = (i === last && tur !== 'cinar');
      var nf = Math.round((fl2 ? 10 : 8) * (1 + bol * 1.6) * (fl2 || fr ? ease(Math.min(1, p * 1.4)) : 0));
      for (var k = 0; k < nf; k++) { var a = r() * 6.28, d = (0.35 + r() * 0.55) * RR, x = 50 + Math.cos(a) * d, y = cy0 + Math.sin(a) * d * cfg.ry;
        if (fl2) { if (tur === 'turunc') blossom(x, y, 1.6, 'url(#gBeyaz)', '#F4D35E'); else { add(leaf(x, y + 1, -1.57, 3.6, 1.6), 'url(#gNarCicek)'); add(El(x, y - 1.2, 1.6, 0.8), '#FF7A3D'); } }
        else if (tur === 'turunc') fruit(x, y, 2.3, 'url(#gTurunc)');
        else if (tur === 'nar') { fruit(x, y, 2.6, 'url(#gNar)'); add('M' + f(x - 0.8) + ' ' + f(y - 2.4) + 'l0.8 -1.2l0.8 1.2Z', '#8A0F22'); }
        else if (tur === 'zeytin') { add(El(x, y, 1.1, 1.5), k % 3 ? 'url(#gZeytinMeyve)' : 'url(#gZeytinYesil)'); }
      }
    }
  } else if (tur === 'hurma') {
    shadow(10 + i * 5);
    if (i === 0) { stem(50, 112, 50, 112 - lerp(4, 10, ease(p)), 0, 1.4, '#6B8E3A'); for (var k = 0; k < 3; k++) add(leaf(50, 112 - 6, -1.57 + (k - 1) * 0.5, 6 + p * 6, 1.3), 'url(#gHurmaYaprak)'); }
    else {
      var Ht = i === 1 ? lerp(8, 24, ease(p)) : i === 2 ? lerp(28, 58, ease(p)) : 62, fw = i === 1 ? 14 : i === 2 ? lerp(18, 28, ease(p)) : 30;
      var tt = 112 - Ht;
      add('M47.6 112Q49 ' + f(112 - Ht * 0.5) + ' 49.2 ' + f(tt) + 'L50.8 ' + f(tt) + 'Q51.6 ' + f(112 - Ht * 0.5) + ' 52.6 112Z', 'url(#gHurmaGovde)');
      for (var k = 0; k < Math.round(Ht / 3.2); k++) { var y = 111 - k * 3.2; add(Q(47.8 + k * 0.03, y, 50.2, y - 1.2, 52.4 - k * 0.04, y), 'none', 0.6, '#6B4A2A', 0.7); }
      var fr2 = [[-2.9, 1], [-2.4, 1], [-1.95, 0.95], [-1.57, 0.9], [-1.2, 0.95], [-0.75, 1], [-0.25, 1], [0.35, 0.85], [2.8, 0.85]];
      fr2.forEach(function (q, k) {
        var a = q[0], L = fw * q[1], ex = 50 + Math.cos(a) * L, ey = tt + Math.sin(a) * L * 0.75 + L * 0.28, cx = 50 + Math.cos(a) * L * 0.5, cy = tt + Math.sin(a) * L * 0.5 - 3;
        add(Q(50, tt, cx, cy, ex, ey), 'none', 1, '#557A2E', 0.9);
        var nl = Math.round(9 * lod + 3);
        for (var j = 1; j <= nl; j++) { var t = j / (nl + 1), px = (1 - t) * (1 - t) * 50 + 2 * (1 - t) * t * cx + t * t * ex, py = (1 - t) * (1 - t) * tt + 2 * (1 - t) * t * cy + t * t * ey; var ang = Math.atan2(ey - cy, ex - cx); var ll = (1 - t * 0.6) * L * 0.28; add(leaf(px, py, ang + 1.1, ll, ll * 0.16), 'url(#gHurmaYaprak)', 0.95); add(leaf(px, py, ang - 1.1, ll, ll * 0.16), 'url(#gHurmaYaprak)', 0.95); }
      });
      if (i === 3) { var gd = ease(p); [[-4, 5], [4, 6], [0, 7.5]].forEach(function (q) { for (var j = 0; j < 9; j++) { add(C(50 + q[0] + (j % 3 - 1) * 1.6, tt + q[1] + Math.floor(j / 3) * 1.7, 1.0 + gd * 0.35), 'url(#gHurmaMeyve)'); } }); }
    }
  }
  return S;
}

/* Süre = boy. Her türün tam formuna ulaştığı süreden sonra (en çok 120 dk) bitki büyümeye devam eder:
   çiçekler çoğalıp demet, tarh, bahçe olur; ağaçlar olgunlaşıp ulu ağaca döner. */
var BITKI_MAX = 120;
var BITKI_EK = { menekse: ['Menekşe tutamı', 'Menekşe yastığı', 'Menekşe tarhı'], lale: ['Lale demeti', 'Lale tarhı', 'Lale bahçesi'], reyhan: ['Reyhan demeti', 'Reyhan sırası', 'Reyhan bahçesi'], sumbul: ['Sümbül demeti', 'Sümbül tarhı', 'Sümbül bahçesi'], gul: ['Gül fidanı', 'Gül çalısı', 'Ulu gül çalısı'], lavanta: ['Lavanta tutamı', 'Lavanta tarhı', 'Lavanta tarlası'], badem: ['Olgun badem', 'Ulu badem'], servi: ['Olgun servi', 'Ulu servi'], turunc: ['Olgun turunç', 'Ulu turunç'], nar: ['Olgun nar', 'Ulu nar'], zeytin: ['Olgun zeytin', 'Asırlık zeytin'], hurma: ['Ulu hurma'], cinar: [] };
BITKI_SIRA.forEach(function (t) {
  var b = BITKI[t], ek = BITKI_EK[t], n = ek.length, span = (BITKI_MAX - b.dk) / Math.max(1, n);
  b.temel = b.evre.slice();
  b.evre = b.temel.concat(ek.map(function (ad, k) { return [ad, Math.round(b.dk + span * k), k === n - 1 ? BITKI_MAX : Math.round(b.dk + span * (k + 1))]; }));
});
var CLONE = [[0, 0, 1], [-17, -5, .86], [17, -5, .86], [-9, -11, .8], [9, -11, .8], [-28, 0, .78], [28, 0, .78], [-21, -15, .72], [21, -15, .72]];
function bitkiAdet(tur, dk) { var b = BITKI[tur]; if (b.tur === 'Ağaç' || dk <= b.dk) return 1; var e = Math.min(1, (dk - b.dk) / (BITKI_MAX - b.dk)); return e < 1 / 3 ? 1 + 6 * e : e < 2 / 3 ? 3 + 9 * (e - 1 / 3) : 6 + 9 * (e - 2 / 3); }
function bitkiOzet(tur, dk) {
  var b = BITKI[tur], E = bitkiEvre(tur, Math.max(0, Math.min(dk, BITKI_MAX) - 0.001));
  if (dk < b.dk) return E.ad + ' · ' + b.ad.toLowerCase() + ' ' + b.dk + ' dk’da tam formuna erer';
  if (b.tur === 'Ağaç') return E.ad + (dk >= BITKI_MAX ? ' · en büyük hâli' : '');
  var n = Math.floor(bitkiAdet(tur, dk) + 0.001); return E.ad + ' · ' + n + ' ' + (n === 1 ? 'çiçek' : 'öbek');
}
function yolDonustur(d, s, dx, dy) {
  var tok = d.match(/[MLQCTAZHVmlqctazhv]|-?\d*\.?\d+(?:e-?\d+)?/g) || [], out = [], cmd = '', k = 0, buf = [];
  function X(x) { return Math.round((50 + (x - 50) * s + dx) * 10) / 10; } function Y(y) { return Math.round((112 + (y - 112) * s + dy) * 10) / 10; } function R(v) { return Math.round(v * s * 100) / 100; }
  for (var i = 0; i < tok.length; i++) {
    var t = tok[i];
    if (/[A-Za-z]/.test(t)) { cmd = t; out.push(t); k = 0; continue; }
    var v = Number(t);
    if (cmd === 'M' || cmd === 'L' || cmd === 'Q' || cmd === 'C' || cmd === 'T') { out.push(k % 2 === 0 ? X(v) : Y(v)); }
    else if (cmd === 'a') { var m = k % 7; out.push(m === 0 || m === 1 || m === 5 || m === 6 ? R(v) : v); }
    else { out.push(R(v)); }
    k++;
  }
  return out.join(' ');
}
function bitkiDonustur(S, s, dx, dy, op) { return S.map(function (q) { return { d: yolDonustur(q.d, s, dx, dy), f: q.f, s: q.s, w: Math.round(q.w * s * 100) / 100, o: q.o * (op == null ? 1 : op) }; }); }
function bitkiCiz(tur, dk, seed, opt) {
  opt = opt || {}; var b = BITKI[tur];
  dk = Math.max(0, Math.min(BITKI_MAX, dk));
  if (dk <= b.dk) return bitkiTemel(tur, dk, seed, opt);
  var e = (dk - b.dk) / (BITKI_MAX - b.dk);
  if (b.tur === 'Ağaç') { var o2 = {}; for (var k in opt) o2[k] = opt[k]; o2.bolluk = e; return bitkiDonustur(bitkiTemel(tur, b.dk, seed, o2), 1 + 0.32 * e, 0, 0); }
  var n = bitkiAdet(tur, dk), full = Math.floor(n), frac = n - full, out = [], lod = (opt.lod || 1) * (n > 3 ? 0.6 : 0.85);
  var w = 14 + Math.min(9, Math.ceil(n)) * 3.2;
  out.push({ d: 'M' + (50 - w) + ' 112a' + w + ' ' + (w * 0.22) + ' 0 1 0 ' + (2 * w) + ' 0a' + w + ' ' + (w * 0.22) + ' 0 1 0 ' + (-2 * w) + ' 0Z', f: 'url(#gGolge)', s: 'none', w: 0, o: 1 });
  var idx = []; for (var j = 0; j < Math.min(9, Math.ceil(n)); j++) idx.push(j);
  idx.sort(function (a, c) { return CLONE[a][1] - CLONE[c][1]; });
  idx.forEach(function (j) {
    var c = CLONE[j], grow = j < full ? 1 : frac; if (grow <= 0.02) return;
    var sh = bitkiTemel(tur, b.dk, (seed || 7) + j * 13, { lod: lod }).filter(function (q) { return q.f !== 'url(#gGolge)'; });
    out = out.concat(bitkiDonustur(sh, c[2] * (0.35 + 0.65 * grow), c[0], c[1] * 0.6, j === 0 ? 1 : 0.98));
  });
  return out;
}

function rnd(a) { return function () { a |= 0; a = a + 0x6D2B79F5 | 0; var t = Math.imul(a ^ a >>> 15, 1 | a); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; }; }
