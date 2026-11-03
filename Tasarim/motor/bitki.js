/* İhya bitki motoru v2 — 54 tür, türe özel evreler, sürekli büyüme (süre = boy).
   Çizim alanı 0 0 100 120, zemin y=112. Yollar yalnız M L Q C Z ve göreli l h v komutlarını kullanır (yay yok):
   böylece aynı motor tarayıcıda (SVG) ve uygulamada (JavaScriptCore + SwiftUI Path) birebir aynı çizer.
   sinif: baslangic (ücretsiz) · siradan · yeni · nadide.  fiyat: kilit açma bedeli (tohum). */
var BITKI = {
  // ——— Çiçekler ———
  karahindiba: { ad: 'Karahindiba', tur: 'Çiçek', dk: 10, renk: '#F2B705', sinif: 'baslangic', fiyat: 0, evre: [['Filiz', 0, 4], ['Yaprak', 4, 7], ['Karahindiba', 7, 10]], not: 'Her yerde biten mütevazı çiçek. İlk odaklarının tohumu.' },
  papatya: { ad: 'Papatya', tur: 'Çiçek', dk: 15, renk: '#E8C33A', sinif: 'baslangic', fiyat: 0, evre: [['Filiz', 0, 5], ['Gövde', 5, 10], ['Papatya', 10, 15]], not: 'Sade ve beyaz; kısa bir odağın ilk ödülü.' },
  menekse: { ad: 'Menekşe', tur: 'Çiçek', dk: 15, renk: '#8A4FE0', sinif: 'siradan', fiyat: 6, evre: [['Filiz', 0, 5], ['Tomurcuk', 5, 10], ['Menekşe', 10, 15]], not: 'Kısa oturumların çiçeği. Gölgede de açar; az zamanı bereketlendirmeyi hatırlatır.' },
  reyhan: { ad: 'Reyhan', tur: 'Çiçek', dk: 20, renk: '#3FA34D', sinif: 'siradan', fiyat: 8, evre: [['Filiz', 0, 7], ['Fide', 7, 14], ['Reyhan', 14, 20]], not: 'Hz. Peygamber torunları Hasan ile Hüseyin için “Bu ikisi dünyadaki iki reyhanımdır” buyurdu (Buhârî, 3753).' },
  lale: { ad: 'Lale', tur: 'Çiçek', dk: 20, renk: '#E8202A', sinif: 'siradan', fiyat: 10, evre: [['Soğan', 0, 5], ['Yaprak', 5, 10], ['Tomurcuk', 10, 15], ['Lâle-i Rûmî', 15, 20]], not: 'Osmanlı çini ve tezhibinin çiçeği. Arap harfleriyle lâle (لاله) ile Allah (الله) aynı harflerle yazılır.' },
  gelincik: { ad: 'Gelincik', tur: 'Çiçek', dk: 15, renk: '#F2261B', sinif: 'siradan', fiyat: 12, evre: [['Filiz', 0, 5], ['Eğik tomurcuk', 5, 10], ['Gelincik', 10, 15]], not: 'Tarla kenarlarının kırmızısı; bir sabah açar, kısa ömrüyle zamanın kıymetini hatırlatır.' },
  karanfil: { ad: 'Karanfil', tur: 'Çiçek', dk: 20, renk: '#E5254F', sinif: 'siradan', fiyat: 12, evre: [['Filiz', 0, 6], ['Gövde', 6, 12], ['Tomurcuk', 12, 16], ['Karanfil', 16, 20]], not: 'Tırtıklı yapraklarıyla Osmanlı nakışlarının sevilen çiçeği.' },
  sumbul: { ad: 'Sümbül', tur: 'Çiçek', dk: 25, renk: '#6A55F0', sinif: 'siradan', fiyat: 12, evre: [['Soğan', 0, 6], ['Yapraklar', 6, 14], ['Salkım', 14, 20], ['Açmış sümbül', 20, 25]], not: 'Kışın ortasında kokusuyla açan çiçek; sabrın meyvesi.' },
  kardelen: { ad: 'Kardelen', tur: 'Çiçek', dk: 15, renk: '#DDE8E0', sinif: 'yeni', fiyat: 20, evre: [['Soğan', 0, 5], ['Yaprak', 5, 10], ['Kardelen', 10, 15]], not: 'Karı delip çıkan ilk çiçek; zorluğun ardındaki kolaylık.' },
  lavanta: { ad: 'Lavanta', tur: 'Çiçek', dk: 35, renk: '#8E63E8', sinif: 'siradan', fiyat: 14, evre: [['Filiz', 0, 10], ['Gövde', 10, 22], ['Başaklar', 22, 35]], not: 'Uzun ve sakin okumaların çiçeği; kokusu tarlaya yayılır.' },
  nergis: { ad: 'Nergis', tur: 'Çiçek', dk: 20, renk: '#FFC21F', sinif: 'siradan', fiyat: 14, evre: [['Soğan', 0, 6], ['Yaprak', 6, 13], ['Nergis', 13, 20]], not: 'Beyaz taç yaprakları ve altın kadehiyle divan şiirinin gözü.' },
  gul: { ad: 'Gül', tur: 'Çiçek', dk: 30, renk: '#E01848', sinif: 'siradan', fiyat: 16, evre: [['Filiz', 0, 10], ['Gonca', 10, 20], ['Gül', 20, 30]], not: 'Divan şiirinde gönlün ve muhabbetin sembolü. İlk 10 dk filiz, sonra gonca, son 10 dakikada açar.' },
  aycicegi: { ad: 'Ayçiçeği', tur: 'Çiçek', dk: 35, renk: '#FFC107', sinif: 'siradan', fiyat: 16, evre: [['Filiz', 0, 8], ['Gövde', 8, 20], ['Tabla', 20, 28], ['Ayçiçeği', 28, 35]], not: 'Yüzünü hep ışığa çeviren çiçek.' },
  zambak: { ad: 'Zambak', tur: 'Çiçek', dk: 30, renk: '#F3B6C8', sinif: 'yeni', fiyat: 18, evre: [['Filiz', 0, 8], ['Gövde', 8, 18], ['Tomurcuk', 18, 24], ['Zambak', 24, 30]], not: 'Uzun gövdesinde açan beyaz yıldız; temizlik ve vakar.' },
  kina: { ad: 'Kına', tur: 'Çiçek', dk: 30, renk: '#E2481E', sinif: 'yeni', fiyat: 20, evre: [['Filiz', 0, 8], ['Çalı', 8, 20], ['Çiçekli kına', 20, 30]], not: 'Yaprakları kına olur; küçük turuncu çiçekleriyle sıcak bir çalı.' },
  corekotu: { ad: 'Çörek otu', tur: 'Çiçek', dk: 25, renk: '#8CB8F2', sinif: 'yeni', fiyat: 22, evre: [['Filiz', 0, 7], ['Tüylü yaprak', 7, 16], ['Çörek otu', 16, 25]], not: '“Çörek otunda ölüm dışında her derde şifa vardır.” (Buhârî, 5688)' },
  yasemin: { ad: 'Yasemin', tur: 'Çiçek', dk: 35, renk: '#F4F1EA', sinif: 'yeni', fiyat: 24, evre: [['Filiz', 0, 10], ['Sarmaşık', 10, 24], ['Yasemin', 24, 35]], not: 'Akşamları kokusu artan beyaz yıldızlar.' },
  sakayik: { ad: 'Şakayık', tur: 'Çiçek', dk: 40, renk: '#FF8FB4', sinif: 'yeni', fiyat: 26, evre: [['Filiz', 0, 10], ['Çalı', 10, 24], ['Top tomurcuk', 24, 32], ['Şakayık', 32, 40]], not: 'Katmer katmer açan iri pembe çiçek.' },
  frezya: { ad: 'Frezya', tur: 'Çiçek', dk: 30, renk: '#FFC83D', sinif: 'yeni', fiyat: 26, evre: [['Filiz', 0, 8], ['Kavisli sap', 8, 20], ['Frezya', 20, 30]], not: 'Kavisli sapı boyunca sıra sıra açan kokulu huniler.' },
  ortanca: { ad: 'Ortanca', tur: 'Çiçek', dk: 45, renk: '#8E96F2', sinif: 'yeni', fiyat: 28, evre: [['Filiz', 0, 10], ['Çalı', 10, 26], ['Yeşil top', 26, 36], ['Ortanca', 36, 45]], not: 'Yüzlerce minik çiçekten bir top; birlikte güzelliğin çiçeği.' },
  nilufer: { ad: 'Nilüfer', tur: 'Çiçek', dk: 40, renk: '#FF9EC4', sinif: 'yeni', fiyat: 30, evre: [['Yüzen yaprak', 0, 12], ['Tomurcuk', 12, 28], ['Nilüfer', 28, 40]], not: 'Bulanık suyun üstünde tertemiz açan çiçek.' },
  kamelya: { ad: 'Kamelya', tur: 'Çiçek', dk: 45, renk: '#F0567E', sinif: 'yeni', fiyat: 32, evre: [['Filiz', 0, 10], ['Parlak çalı', 10, 28], ['Kamelya', 28, 45]], not: 'Parlak koyu yapraklar arasında katmerli pembe çiçekler.' },
  begonvil: { ad: 'Begonvil', tur: 'Çiçek', dk: 50, renk: '#E0219C', sinif: 'yeni', fiyat: 36, evre: [['Filiz', 0, 10], ['Sarmaşık', 10, 30], ['Begonvil', 30, 50]], not: 'Akdeniz kapılarını saran mor-pembe kâğıt çiçekler.' },
  terslale: { ad: 'Ters lale', tur: 'Çiçek', dk: 75, renk: '#F06A12', sinif: 'nadide', fiyat: 80, evre: [['Soğan', 0, 15], ['Gövde', 15, 40], ['Taç yaprak', 40, 60], ['Ters lale', 60, 75]], not: 'Hakkari dağlarının nadir çiçeği; çanları başı eğik açar. Rivayete göre hep ağlayan gelin.' },
  yesim: { ad: 'Yeşim sarmaşığı', tur: 'Çiçek', dk: 90, renk: '#46E0C0', sinif: 'nadide', fiyat: 95, evre: [['Filiz', 0, 20], ['Sarmaşık', 20, 50], ['Salkım tomurcuğu', 50, 72], ['Yeşim sarmaşığı', 72, 90]], not: 'Filipin ormanlarının yeşim renkli pençe çiçekleri; dünyanın en nadir renklerinden.' },
  rafflesia: { ad: 'Rafflesia', tur: 'Çiçek', dk: 105, renk: '#B8301E', sinif: 'nadide', fiyat: 110, evre: [['Gizli tomurcuk', 0, 35], ['Lahana tomurcuk', 35, 75], ['Rafflesia', 75, 105]], not: 'Dünyanın en büyük çiçeği; aylarca gizli büyür, birkaç gün açar.' },
  orkide: { ad: 'Hayalet orkide', tur: 'Çiçek', dk: 120, renk: '#E6F0EA', sinif: 'nadide', fiyat: 130, evre: [['Kökler', 0, 40], ['Sap', 40, 80], ['Tomurcuk', 80, 100], ['Hayalet orkide', 100, 120]], not: 'Yapraksız, havada süzülür gibi açan beyaz çiçek; bulması en zor orkide.' },
  // ——— Ağaçlar ———
  cam: { ad: 'Çam', tur: 'Ağaç', dk: 25, renk: '#1F6A3E', sinif: 'baslangic', fiyat: 0, evre: [['Fide', 0, 8], ['Fidan', 8, 16], ['Çam', 16, 25]], not: 'Sade, her mevsim yeşil; ilk ağacın.' },
  kavak: { ad: 'Kavak', tur: 'Ağaç', dk: 25, renk: '#7EBE4A', sinif: 'baslangic', fiyat: 0, evre: [['Fide', 0, 8], ['Fidan', 8, 16], ['Kavak', 16, 25]], not: 'Göğe doğru uzanan sade ağaç.' },
  servi: { ad: 'Servi', tur: 'Ağaç', dk: 40, renk: '#1F5A3A', sinif: 'siradan', fiyat: 22, evre: [['Fide', 0, 10], ['Fidan', 10, 25], ['Servi', 25, 40]], not: 'Osmanlı bahçelerinde dik duruşun, istikametin sembolü.' },
  badem: { ad: 'Badem', tur: 'Ağaç', dk: 35, renk: '#F29BB8', sinif: 'siradan', fiyat: 26, evre: [['Fidan', 0, 10], ['Tomurcuk', 10, 20], ['Çiçekli badem', 20, 35]], not: 'Kış bitmeden ilk çiçek açan ağaç.' },
  elma: { ad: 'Elma', tur: 'Ağaç', dk: 50, renk: '#E52A2A', sinif: 'siradan', fiyat: 28, evre: [['Fide', 0, 10], ['Fidan', 10, 25], ['Çiçekli', 25, 38], ['Elmalı', 38, 50]], not: 'Bahar çiçeği, yaz meyvesi; sabrın tatlı sonu.' },
  incir: { ad: 'İncir', tur: 'Ağaç', dk: 50, renk: '#6E3A7E', sinif: 'siradan', fiyat: 30, evre: [['Fide', 0, 10], ['Fidan', 10, 25], ['Genç incir', 25, 40], ['Meyveli', 40, 50]], not: '“Andolsun incire ve zeytine.” (Tîn 95:1)' },
  asma: { ad: 'Asma', tur: 'Ağaç', dk: 55, renk: '#6A3AB0', sinif: 'siradan', fiyat: 32, evre: [['Çubuk', 0, 12], ['Filizlenen asma', 12, 30], ['Çardak', 30, 45], ['Üzümlü', 45, 55]], not: 'Çardağı saran bağ; gölgesi de meyvesi de cömert.' },
  turunc: { ad: 'Turunç', tur: 'Ağaç', dk: 45, renk: '#FF9A1F', sinif: 'siradan', fiyat: 34, evre: [['Fide', 0, 10], ['Fidan', 10, 20], ['Çiçekli', 20, 35], ['Meyveli', 35, 45]], not: '“Kur’an okuyan mü’min turunç gibidir; tadı da güzel, kokusu da güzel.” (Buhârî, 5020)' },
  ihlamur: { ad: 'Ihlamur', tur: 'Ağaç', dk: 55, renk: '#88BE4E', sinif: 'siradan', fiyat: 36, evre: [['Fide', 0, 10], ['Fidan', 10, 25], ['Genç ıhlamur', 25, 42], ['Çiçekli ıhlamur', 42, 55]], not: 'Kalp biçimli yaprakları, bal kokulu çiçekleriyle gölgeli ağaç.' },
  nar: { ad: 'Nar', tur: 'Ağaç', dk: 50, renk: '#E2273A', sinif: 'siradan', fiyat: 38, evre: [['Fidan', 0, 10], ['Genç nar', 10, 25], ['Çiçekli', 25, 40], ['Meyveli', 40, 50]], not: '“İkisinde de meyveler, hurmalar ve narlar vardır.” (Rahmân 55:68)' },
  erguvan: { ad: 'Erguvan', tur: 'Ağaç', dk: 55, renk: '#D648A8', sinif: 'yeni', fiyat: 40, evre: [['Fide', 0, 10], ['Fidan', 10, 25], ['Tomurcuklu', 25, 40], ['Erguvan', 40, 55]], not: 'Baharda İstanbul’u mora boyayan ağaç.' },
  misvak: { ad: 'Misvak ağacı', tur: 'Ağaç', dk: 45, renk: '#9CC27A', sinif: 'yeni', fiyat: 42, evre: [['Fide', 0, 10], ['Çalı', 10, 25], ['Misvak ağacı', 25, 45]], not: '“Ümmetime zor gelmeseydi her namazda misvak kullanmalarını emrederdim.” (Buhârî, 887)' },
  akcaagac: { ad: 'Akçaağaç', tur: 'Ağaç', dk: 60, renk: '#E8461E', sinif: 'yeni', fiyat: 46, evre: [['Fide', 0, 10], ['Fidan', 10, 28], ['Genç akçaağaç', 28, 45], ['Kızıl akçaağaç', 45, 60]], not: 'Güzün alev renklerine bürünen ağaç.' },
  zeytin: { ad: 'Zeytin', tur: 'Ağaç', dk: 60, renk: '#8FB07A', sinif: 'yeni', fiyat: 48, evre: [['Fide', 0, 10], ['Fidan', 10, 25], ['Genç zeytin', 25, 45], ['Meyveli', 45, 60]], not: 'Kur’an’da “mübarek bir ağaç” (Nûr 24:35) ve üzerine yemin edilen ağaç (Tîn 95:1).' },
  sogut: { ad: 'Salkım söğüt', tur: 'Ağaç', dk: 65, renk: '#8CC25A', sinif: 'yeni', fiyat: 50, evre: [['Fide', 0, 12], ['Fidan', 12, 30], ['Genç söğüt', 30, 48], ['Salkım söğüt', 48, 65]], not: 'Suya eğilen dallarıyla tevazunun ağacı.' },
  sedir: { ad: 'Sedir', tur: 'Ağaç', dk: 70, renk: '#3E8A72', sinif: 'yeni', fiyat: 52, evre: [['Fide', 0, 12], ['Fidan', 12, 32], ['Genç sedir', 32, 52], ['Sedir', 52, 70]], not: 'Toros dağlarının kat kat dallı, asırlık ağacı.' },
  manolya: { ad: 'Manolya', tur: 'Ağaç', dk: 60, renk: '#D879A8', sinif: 'yeni', fiyat: 54, evre: [['Fide', 0, 10], ['Fidan', 10, 28], ['Tomurcuklu', 28, 44], ['Manolya', 44, 60]], not: 'Yapraktan önce açan iri, lale biçimli çiçekler.' },
  sakura: { ad: 'Sakura', tur: 'Ağaç', dk: 60, renk: '#FFB7CF', sinif: 'yeni', fiyat: 56, evre: [['Fide', 0, 10], ['Fidan', 10, 28], ['Tomurcuklu', 28, 44], ['Sakura', 44, 60]], not: 'Bir haftalık çiçeğiyle dünyanın geçiciliğini hatırlatan kiraz.' },
  sidre: { ad: 'Sidre', tur: 'Ağaç', dk: 75, renk: '#7E9E46', sinif: 'yeni', fiyat: 60, evre: [['Fide', 0, 12], ['Dikenli fidan', 12, 32], ['Genç sidre', 32, 56], ['Meyveli sidre', 56, 75]], not: 'Sidretü’l-müntehâ (Necm 53:14) adını taşıyan dikenli, küçük meyveli ağaç.' },
  jakaranda: { ad: 'Jakaranda', tur: 'Ağaç', dk: 70, renk: '#9478E8', sinif: 'yeni', fiyat: 64, evre: [['Fide', 0, 12], ['Fidan', 12, 30], ['Genç jakaranda', 30, 52], ['Jakaranda', 52, 70]], not: 'Bütün tacı lavanta mavisine dönen ağaç.' },
  hurma: { ad: 'Hurma', tur: 'Ağaç', dk: 90, renk: '#E07B1F', sinif: 'yeni', fiyat: 70, evre: [['Fide', 0, 15], ['Fidan', 15, 40], ['Genç hurma', 40, 70], ['Salkımlı', 70, 90]], not: '“Ağaçlar içinde yaprağı dökülmeyen bir ağaç vardır; o, müslümanın misalidir.” (Buhârî, 61)' },
  cinar: { ad: 'Çınar', tur: 'Ağaç', dk: 120, renk: '#5DBB4C', sinif: 'yeni', fiyat: 85, evre: [['Fide', 0, 20], ['Fidan', 20, 50], ['Genç çınar', 50, 90], ['Ulu çınar', 90, 120]], not: '“Cennette bir ağaç vardır; binekli kimse gölgesinde yüz yıl yürür de onu geçemez.” (Buhârî, 3252)' },
  sigla: { ad: 'Sığla ağacı', tur: 'Ağaç', dk: 90, renk: '#F08A2A', sinif: 'nadide', fiyat: 105, evre: [['Fide', 0, 15], ['Fidan', 15, 40], ['Genç sığla', 40, 66], ['Güz sığlası', 66, 90]], not: 'Muğla’nın endemik, nesli tehlikedeki ağacı; yıldız yaprakları güzde rengârenk olur.' },
  baobab: { ad: 'Baobab', tur: 'Ağaç', dk: 100, renk: '#C8AE90', sinif: 'nadide', fiyat: 120, evre: [['Fide', 0, 15], ['Fidan', 15, 45], ['Şişkin gövde', 45, 75], ['Baobab', 75, 100]], not: 'Gövdesinde ton ton su saklayan, binlerce yıl yaşayan ağaç.' },
  ejder: { ad: 'Ejder kanı ağacı', tur: 'Ağaç', dk: 110, renk: '#3E8A3E', sinif: 'nadide', fiyat: 140, evre: [['Fide', 0, 18], ['Fidan', 18, 48], ['Çatallanan dallar', 48, 82], ['Ejder kanı', 82, 110]], not: 'Sokotra adasının şemsiye biçimli, kırmızı reçineli nadir ağacı.' },
  okaliptus: { ad: 'Gökkuşağı okaliptüsü', tur: 'Ağaç', dk: 110, renk: '#9A5AD0', sinif: 'nadide', fiyat: 160, evre: [['Fide', 0, 18], ['Fidan', 18, 46], ['Soyulan kabuk', 46, 80], ['Gökkuşağı okaliptüsü', 80, 110]], not: 'Kabuğu soyuldukça yeşil, mavi, mor ve turuncu çizgilerle boyanan ağaç.' },
  sekoya: { ad: 'Dev sekoya', tur: 'Ağaç', dk: 120, renk: '#C2643A', sinif: 'nadide', fiyat: 180, evre: [['Fide', 0, 20], ['Fidan', 20, 50], ['Genç sekoya', 50, 90], ['Dev sekoya', 90, 120]], not: 'Dünyanın en büyük canlılarından; gövdesi binlerce yılın sabrıdır.' }
};
var BITKI_SIRA = ['karahindiba', 'papatya', 'menekse', 'reyhan', 'lale', 'gelincik', 'karanfil', 'sumbul', 'kardelen', 'lavanta', 'nergis', 'gul', 'aycicegi', 'zambak', 'kina', 'corekotu', 'yasemin', 'sakayik', 'frezya', 'ortanca', 'nilufer', 'kamelya', 'begonvil', 'terslale', 'yesim', 'rafflesia', 'orkide',
  'cam', 'kavak', 'servi', 'badem', 'elma', 'incir', 'asma', 'turunc', 'ihlamur', 'nar', 'erguvan', 'misvak', 'akcaagac', 'zeytin', 'sogut', 'sedir', 'manolya', 'sakura', 'sidre', 'jakaranda', 'hurma', 'cinar', 'sigla', 'baobab', 'ejder', 'okaliptus', 'sekoya'];

function bitkiEvre(tur, dk, temel) {
  var b = BITKI[tur], ev = temel ? b.temel : b.evre, i = 0;
  for (var k = 0; k < ev.length; k++) { if (dk >= ev[k][1]) i = k; }
  var e = ev[i], p = Math.max(0, Math.min(1, (dk - e[1]) / (e[2] - e[1])));
  return { i: i, ad: e[0], p: p, kalan: Math.max(0, Math.ceil(e[2] - dk)), sonraki: ev[i + 1] ? ev[i + 1][0] : null, son: i === ev.length - 1, tamam: dk >= b.dk };
}

function elYol(cx, cy, rx, ry, f) {
  var k = 0.5523, ox = rx * k, oy = ry * k;
  return 'M' + f(cx - rx) + ' ' + f(cy) + 'C' + f(cx - rx) + ' ' + f(cy - oy) + ' ' + f(cx - ox) + ' ' + f(cy - ry) + ' ' + f(cx) + ' ' + f(cy - ry) +
    'C' + f(cx + ox) + ' ' + f(cy - ry) + ' ' + f(cx + rx) + ' ' + f(cy - oy) + ' ' + f(cx + rx) + ' ' + f(cy) +
    'C' + f(cx + rx) + ' ' + f(cy + oy) + ' ' + f(cx + ox) + ' ' + f(cy + ry) + ' ' + f(cx) + ' ' + f(cy + ry) +
    'C' + f(cx - ox) + ' ' + f(cy + ry) + ' ' + f(cx - rx) + ' ' + f(cy + oy) + ' ' + f(cx - rx) + ' ' + f(cy) + 'Z';
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
  function El(cx, cy, rx, ry) { return elYol(cx, cy, rx, ry, f); }
  function C(cx, cy, rr) { return elYol(cx, cy, rr, rr, f); }
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
  // ——— v2 yardımcıları ———
  function sv(arr) { var prev = i === 0 ? arr[0] * 0.45 : arr[i - 1]; return lerp(prev, arr[i], ease(p)); }
  function rosette(n, L, W, grad, spread, y0) { for (var k = 0; k < n; k++) { var a = -1.57 + (k - (n - 1) / 2) * (spread || 0.5); add(leaf(50, y0 || 111, a, L * (0.82 + (k % 2) * 0.18), W), grad); } }
  function petals(x, y, n, len, wid, grad, rot, o, st) { for (var k = 0; k < n; k++) add(leaf(x, y, (rot || 0) + k * 6.2832 / n, len, wid), grad, o, st, st ? 0.25 : 0); }
  function boyunca(x0, y0, cx, cy, x1, y1, t) { var u = 1 - t; return [u * u * x0 + 2 * u * t * cx + t * t * x1, u * u * y0 + 2 * u * t * cy + t * t * y1]; }
  function bud(x, y, s, grad) { add(leaf(x, y + s * 0.3, -1.57, s * 2.2, s * 0.8), grad); }
  function strip(x0, y0, x1, y1, w, grad) { var a = Math.atan2(y1 - y0, x1 - x0), L = Math.sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0)); add(leaf(x0, y0, a, L, w), grad); }
  function dots(cx, cy, R, n, rr, col, o) { for (var k = 0; k < n; k++) { var a = r() * 6.28, d = Math.sqrt(r()) * R; add(C(cx + Math.cos(a) * d, cy + Math.sin(a) * d * 0.8, rr), col, o); } }
  function fide(h, grad) { stem(50, 112, 50, 112 - h, 1.2, 1.4, '#5E4632'); for (var k = 0; k < 4; k++) add(leaf(50, 112 - h + k * 2, k % 2 ? -0.5 : -2.6, 4 + h * 0.25, 1.6 + h * 0.06), grad || 'url(#gYaprak)'); }
  // Yuvarlak taçlı ağaç: 4 evre (fide, fidan, genç, olgun); çiçek ve meyve türe göre
  function yuvarlak(cfg) {
    var prev = Math.max(0, i - 1);
    var TH = lerp(i === 0 ? cfg.th[0] * 0.5 : cfg.th[prev], cfg.th[i], ease(p)), RR = lerp(i === 0 ? cfg.R[0] * 0.5 : cfg.R[prev], cfg.R[i], ease(p));
    shadow(RR * 0.9 + 4);
    if (i === 0) { fide(TH, cfg.fideG); return; }
    var tw = (cfg.tw || 2.6) * (0.6 + i * 0.2), bend = cfg.bend || 1, bark = cfg.bark || 'url(#gGovde)';
    if (cfg.cokGovde) { trunk(47, 112, TH * 0.85, tw * 0.6, tw * 0.35, -3, bark); trunk(53, 112, TH * 0.9, tw * 0.6, tw * 0.35, 3, bark); trunk(50, 112, TH, tw * 0.7, tw * 0.4, 0.5, bark); }
    else trunk(50, 112, TH, tw, tw * 0.55, bend, bark);
    branch(50 + bend, 112 - TH * 0.7, 50 - RR * 0.5, 112 - TH - RR * 0.2, tw * 0.45, cfg.dal || '#5E4632'); branch(50 + bend, 112 - TH * 0.75, 50 + RR * 0.55, 112 - TH - RR * 0.25, tw * 0.4, cfg.dal || '#5E4632');
    var ry = cfg.ry || 0.78, cy0 = 112 - TH - RR * ry * 0.55, cx0 = 50 + bend * 0.5;
    var taç = cfg.tac ? cfg.tac(i) : cfg.g;
    canopy(cx0, cy0, RR, 8 + i * 3, taç, cfg.lg || 'url(#gYaprakGenc)', ry);
    if (cfg.ekle) cfg.ekle(cx0, cy0, RR, ry);
    var son = BITKI[tur].temel.length - 1;
    var cicek = cfg.cicekEvre != null && i === cfg.cicekEvre, meyve = cfg.meyve && i === son;
    var nf = Math.round((cfg.adet || 10) * (1 + bol * 1.6) * ((cicek || meyve) ? ease(Math.min(1, p * 1.4)) : 0));
    if (cfg.hepCicek && i >= cfg.hepCicek) nf = Math.round((cfg.adet || 10) * (1 + bol * 1.6) * (i > cfg.hepCicek ? 1 : ease(Math.min(1, p * 1.4))));
    for (var k = 0; k < nf; k++) { var a = r() * 6.28, d = (0.3 + r() * 0.62) * RR, x = cx0 + Math.cos(a) * d, y = cy0 + Math.sin(a) * d * ry;
      if ((cicek || (cfg.hepCicek && i >= cfg.hepCicek)) && !meyve) cfg.cicek(x, y, k); else if (meyve) cfg.meyve(x, y, k); }
  }
  function koni(H, W, grad, katlar, koyu) { // çam, sekoya: üst üste üçgen katlar
    for (var k = 0; k < katlar; k++) { var t = k / katlar, y1 = 112 - 8 - H * t * 0.92, w = W * (1 - t * 0.78), h = H / katlar * 1.55;
      add('M' + f(50 - w) + ' ' + f(y1) + 'Q50 ' + f(y1 - h * 0.25) + ' ' + f(50 + w) + ' ' + f(y1) + 'L' + f(50 + w * 0.12) + ' ' + f(y1 - h) + 'L' + f(50 - w * 0.12) + ' ' + f(y1 - h) + 'Z', grad);
      if (lod > 0.6) add(Q(50 - w * 0.8, y1 - 0.6, 50, y1 - h * 0.35, 50 + w * 0.8, y1 - 0.6), 'none', 0.35, koyu || '#0B3A20', 0.7); }
    add('M50 ' + f(112 - 8 - H * 0.92 - H / katlar * 1.2) + 'L' + f(50 + W * 0.08) + ' ' + f(112 - 8 - H * 0.84) + 'L' + f(50 - W * 0.08) + ' ' + f(112 - 8 - H * 0.84) + 'Z', grad);
  }

  var YENI = {
    karahindiba: function () {
      shadow(10 + i * 2);
      var L = sv([5, 10, 12]);
      rosette(i === 0 ? 3 : 8, L, L * 0.26, 'url(#gYaprak)', 0.36);
      for (var k = 0; k < (i === 0 ? 0 : 6); k++) { var a = -1.57 + (k - 2.5) * 0.36; add(leaf(50 + Math.cos(a) * L * 0.55, 111 + Math.sin(a) * L * 0.55, a - 0.6, L * 0.22, L * 0.07), 'url(#gYaprak)'); }
      if (i >= 1) { var hs = i === 1 ? lerp(4, 13, ease(p)) : lerp(13, 20, ease(p)), x = 51, y = 111 - hs; stem(50, 111, x, y, 1.5, 1.1, '#5E9E3E');
        if (i === 1) bud(x, y, 1 + p * 1.1, 'url(#gYaprakGenc)');
        else { var o = ease(p), R = lerp(2.6, 6, o); add(leaf(x, y + 1, -1.57, 2.4, 1.3), 'url(#gYaprakGenc)'); petals(x, y, 22, R, R * 0.2, 'url(#gSari)'); petals(x, y, 14, R * 0.62, R * 0.18, 'url(#gSari)', 0.12); add(C(x, y, R * 0.24), '#E89A00'); } }
    },
    papatya: function () {
      shadow(10 + i * 3);
      rosette(i === 0 ? 3 : 6, sv([5, 9, 11]), 1.5, 'url(#gYaprakGenc)', 0.42);
      if (i >= 1) {
        var H = i === 1 ? lerp(8, 24, ease(p)) : lerp(24, 30, ease(p));
        [[0, 1], [-7, 0.8], [7, 0.86]].forEach(function (q, k) { if (i === 1 && k > 0) return; var x = 50 + q[0], y = 111 - H * q[1]; stem(50, 111, x, y, q[0] * 0.3, 0.9, '#5A9E44');
          if (i === 1) bud(x, y, 1.1 + p * 0.6, 'url(#gYaprakGenc)'); else { var R = lerp(2.4, 5.2, ease(p)) * (k ? 0.85 : 1); petals(x, y, 14, R, R * 0.27, 'url(#gBeyazYaprak)', 0.1, 1, '#C9D3C0'); add(C(x, y, R * 0.36), 'url(#gSari)'); add(C(x - R * 0.12, y - R * 0.12, R * 0.12), '#FFF6C0', 0.8); } });
      }
    },
    gelincik: function () {
      shadow(9 + i * 3);
      rosette(i === 0 ? 2 : 5, sv([5, 8, 9]), 1.6, 'url(#gGriYaprak)', 0.5);
      if (i >= 1) {
        var H = i === 1 ? lerp(10, 22, ease(p)) : lerp(22, 30, ease(p));
        [[0, 1], [-8, 0.78], [8, 0.86]].forEach(function (q, k) { if (i === 1 && k > 0) return; var x = 50 + q[0], y = 111 - H * q[1];
          if (i === 1) { stem(50, 111, x + 2, y + 3, 4, 0.8, '#5E8E4A'); add(leaf(x + 2, y + 3, 1.2, 4.2, 1.6), 'url(#gGriYaprak)'); }
          else { stem(50, 111, x, y, q[0] * 0.3, 0.8, '#5E8E4A'); var R = lerp(2.4, 5.4, ease(p)) * (k ? 0.82 : 1); [[-2.4, 1], [-0.75, 1], [0.6, 0.9], [2.4, 0.9]].forEach(function (pt) { add(El(x + Math.cos(pt[0]) * R * 0.5, y + Math.sin(pt[0]) * R * 0.42, R * 0.62 * pt[1], R * 0.55 * pt[1]), 'url(#gGelincik)'); }); add(C(x, y, R * 0.3), '#1A1210'); for (var j = 0; j < 8; j++) add(C(x + Math.cos(j * 0.785) * R * 0.38, y + Math.sin(j * 0.785) * R * 0.38, R * 0.06), '#1A1210'); add(El(x - R * 0.35, y - R * 0.3, R * 0.25, R * 0.14), '#FFFFFF', 0.35); } });
      }
    },
    karanfil: function () {
      shadow(10 + i * 2);
      var H = sv([8, 18, 26, 30]);
      for (var k = 0; k < 6; k++) add(leaf(50, 111, -1.57 + (k - 2.5) * 0.34, 8 + (k % 2) * 3, 1.1), 'url(#gGriYaprak)');
      if (i >= 1) {
        (i >= 2 ? [[0, 1], [-6, 0.86], [6, 0.9]] : [[0, 1]]).forEach(function (q, k) { var x = 50 + q[0], y = 111 - H * q[1]; stem(50, 111, x, y, q[0] * 0.2, 1, '#6E9A7A'); add(leaf(x, y + H * 0.45, -2.4, 4, 0.8), 'url(#gGriYaprak)');
          if (i === 1) bud(x, y, 1, 'url(#gGriYaprak)');
          else if (i === 2) { bud(x, y, 1.5 + p * 0.8, 'url(#gGriYaprak)'); if (p > 0.4) add(El(x, y - 2.6, 1.1, 0.9), 'url(#gKaranfil)'); }
          else { var R = lerp(3, 5.4, ease(p)); add(leaf(x, y + 1.5, -1.57, 3.4, 1.4), 'url(#gGriYaprak)'); for (var j = 0; j < 11; j++) { var a = -1.57 + (j - 5) * 0.21 * (0.7 + ease(p) * 0.5); add(leaf(x, y, a, R * (0.95 + (j % 2) * 0.22), R * 0.34), 'url(#gKaranfil)'); }
            for (var j2 = 0; j2 < 7; j2++) { var a2 = -1.57 + (j2 - 3) * 0.3, tx = x + Math.cos(a2) * R * 1.05, ty = y + Math.sin(a2) * R * 1.05; add('M' + f(tx - 0.7) + ' ' + f(ty) + 'L' + f(tx) + ' ' + f(ty - 0.9) + 'L' + f(tx + 0.7) + ' ' + f(ty) + 'Z', '#FFC2D0', 0.9); } }
        });
      }
    },
    kardelen: function () {
      shadow(8 + i * 2);
      if (i === 0) { mound(8); add(El(50, 110.5, 3.4, 2.6), 'url(#gSogan)'); if (p > 0.2) add(leaf(50, 109, -1.57, 2 + p * 4, 1.2), 'url(#gYaprakGenc)'); return; }
      var Lh = sv([6, 16, 20]);
      [[0, 1, 1], [-7, 0.8, 0.82], [7, 0.72, 0.76]].forEach(function (q, k) {
        if (i === 1 && k > 0) return;
        var bx = 50 + q[0]; add(leaf(bx - 1, 112, -1.75, Lh * q[1], 1.6), 'url(#gGriYaprak)'); add(leaf(bx + 1, 112, -1.4, Lh * q[1] * 0.9, 1.5), 'url(#gGriYaprak)');
        var H = (i === 1 ? lerp(8, 20, ease(p)) : 24) * q[1], tx = bx + 3 * q[2], ty = 112 - H;
        add(Q(bx, 112, bx, 112 - H * 0.6, tx, ty), 'none', 1, '#5E8E6A', 0.9);
        if (i === 1) { bud(tx, ty + 1, 0.9 + p * 0.5, 'url(#gBeyazYaprak)'); return; }
        var o = ease(p), s = lerp(2.2, 4.4, o) * q[2]; add(C(tx, ty + 0.6, 0.8 * q[2]), '#6EA46E');
        add(leaf(tx, ty + 1, 1.57 - 0.5 * o, s * 2, s * 0.62), 'url(#gBeyazYaprak)', 1, '#B9CBBE', 0.3); add(leaf(tx, ty + 1, 1.57 + 0.5 * o, s * 2, s * 0.62), 'url(#gBeyazYaprak)', 1, '#B9CBBE', 0.3);
        add(leaf(tx, ty + 1, 1.57, s * 1.6, s * 0.5), 'url(#gZambak)', 1, '#B9CBBE', 0.3); add(El(tx, ty + s * 1.5, s * 0.25, s * 0.18), '#7FC07A', 0.9);
      });
    },
    nergis: function () {
      shadow(10 + i * 2);
      if (i === 0) { mound(9); add(El(50, 110.5, 4, 3), 'url(#gSogan)'); if (p > 0.2) add(leaf(50, 108, -1.57, 2 + p * 5, 1.3), 'url(#gYaprakGenc)'); return; }
      var Lh = sv([8, 18, 26]); [-1.85, -1.65, -1.45, -1.25].forEach(function (a) { add(leaf(50, 112, a, Lh * (0.85 + Math.abs(a + 1.55) * 0.4), 1.6), 'url(#gLaleYaprak)'); });
      if (i === 2) { [[0, 30], [-5, 25]].forEach(function (q, k) { var H = lerp(q[1] * 0.8, q[1], ease(p)), x = 50 + q[0] + 2, y = 112 - H; add(Q(50 + q[0] * 0.3, 112, 50 + q[0] * 0.6, y + 4, x, y), 'none', 1, '#4C9A4A', 1.1);
        var R = lerp(2.4, 5, ease(p)); petals(x, y, 6, R, R * 0.42, 'url(#gBeyazYaprak)', -0.2); add(C(x, y, R * 0.42), 'url(#gNergisTac)'); add(C(x, y, R * 0.22), '#E87A00'); }); }
    },
    zambak: function () {
      shadow(10 + i * 3);
      var H = sv([8, 22, 34, 38]);
      stem(50, 112, 50, 112 - H, 1, 1.5, '#4C8E44');
      for (var k = 0; k < 8 && k < 2 + i * 2; k++) { var y = 112 - H * (0.12 + k * 0.1); add(leaf(50, y, k % 2 ? -0.45 : -2.7, 7, 1.6), 'url(#gYaprak)'); }
      var x = 50, y = 112 - H;
      if (i === 2) { bud(x, y, 1.4 + p * 1.4, 'url(#gZambak)'); bud(x + 4, y + 4, 1 + p, 'url(#gYaprakGenc)'); }
      if (i === 3) { var o = ease(p), R = lerp(6, 11, o); for (var j = 0; j < 6; j++) { var a = -1.57 + (j - 2.5) * (0.42 + o * 0.38); add(leaf(x, y, a, R, R * 0.28), 'url(#gZambak)', 1, '#E7B9C6', 0.25); add(rib(x, y, a, R * 0.8), 'none', 0.5, '#E89AB0', 0.5); }
        for (var j2 = 0; j2 < 5; j2++) { var a2 = -1.57 + (j2 - 2) * 0.32; add(Q(x, y, x + Math.cos(a2) * R * 0.4, y + Math.sin(a2) * R * 0.4 - 1, x + Math.cos(a2) * R * 0.7, y + Math.sin(a2) * R * 0.7), 'none', 1, '#C8902A', 0.4); add(El(x + Math.cos(a2) * R * 0.7, y + Math.sin(a2) * R * 0.7, 0.6, 0.35), '#C2541E'); }
        bud(x + 5, y + 5, 1.6, 'url(#gZambak)'); }
    },
    aycicegi: function () {
      shadow(10 + i * 3);
      var H = sv([10, 30, 46, 52]);
      stem(50, 112, 50.5, 112 - H, 1.5, 2.2 + i * 0.4, '#5E9A3A');
      for (var k = 0; k < 2 + i * 2 && k < 8; k++) { var y = 112 - H * (0.15 + k * 0.1); add(leaf(50, y, k % 2 ? -0.35 : -2.8, 8 + i, 4), 'url(#gYaprak)'); add(rib(50, y, k % 2 ? -0.35 : -2.8, 8 + i), 'none', 0.5, '#2E6A2A', 0.5); }
      var x = 50.5, y = 112 - H;
      if (i === 2) { var s = lerp(2, 5, ease(p)); petals(x, y, 10, s, s * 0.45, 'url(#gYaprakGenc)'); add(C(x, y, s * 0.6), '#7A9A3A'); }
      if (i === 3) { var o = ease(p), R = lerp(6, 11, o); petals(x, y, 20, R, R * 0.2, 'url(#gAyYaprak)'); petals(x, y, 14, R * 0.75, R * 0.2, 'url(#gSari)', 0.1); add(C(x, y, R * 0.48), 'url(#gAyCekirdek)'); if (lod > 0.6) dots(x, y, R * 0.4, 12, 0.3, '#2A1608', 0.7); }
    },
    kina: function () {
      shadow(12 + i * 4);
      var H = sv([6, 16, 22]), n = i === 0 ? 3 : 7;
      for (var k = 0; k < n; k++) { var a = -1.57 + (k - (n - 1) / 2) * 0.32, x1 = 50 + Math.cos(a) * H, y1 = 112 + Math.sin(a) * H; stem(50, 112, x1, y1, 0, 0.9, '#7A5A3A');
        for (var j = 1; j <= 3; j++) { var t = j / 4, lx = 50 + (x1 - 50) * t, ly = 112 + (y1 - 112) * t; add(leaf(lx, ly, a + (j % 2 ? 0.9 : -0.9), 3.4, 1.3), 'url(#gYaprak)'); }
        if (i === 2) { var o = ease(p); for (var j3 = 0; j3 < 4; j3++) add(C(x1 + (r() - 0.5) * 3, y1 + (r() - 0.5) * 3, 0.7 + o * 0.6), j3 % 2 ? 'url(#gKina)' : '#FF8A4A'); } }
    },
    corekotu: function () {
      shadow(10 + i * 3);
      var H = sv([6, 16, 22]);
      for (var k = 0; k < (i === 0 ? 4 : 10); k++) { var a = -1.57 + (k - 4.5) * 0.22, L = H * (0.5 + (k % 3) * 0.15); add(Q(50, 112, 50 + Math.cos(a) * L * 0.5 + (k % 2 ? 2 : -2), 112 + Math.sin(a) * L * 0.5, 50 + Math.cos(a) * L, 112 + Math.sin(a) * L), 'none', 0.9, '#6EA85A', 0.5); }
      if (i >= 1) [[0, 1], [-6, 0.82], [6, 0.88]].forEach(function (q, k) { if (i === 1 && k > 0) return; var x = 50 + q[0], y = 112 - H * q[1]; stem(50, 112, x, y, 0, 0.8, '#5E8E4A');
        if (i === 1) bud(x, y, 0.9 + p * 0.6, 'url(#gYaprakGenc)'); else { var R = lerp(2, 4.6, ease(p)); petals(x, y, 5, R, R * 0.48, 'url(#gMaviCicek)', -1.57); add(C(x, y, R * 0.3), '#3E6E4A'); for (var j = 0; j < 5; j++) add(Q(x, y, x + Math.cos(j * 1.256) * R * 0.3, y + Math.sin(j * 1.256) * R * 0.3 - 1, x + Math.cos(j * 1.256) * R * 0.55, y + Math.sin(j * 1.256) * R * 0.55 - 1.2), 'none', 0.9, '#2E5E3A', 0.4); } });
    },
    yasemin: function () {
      shadow(12 + i * 4);
      var H = sv([7, 20, 26]), n = i === 0 ? 3 : 7, dal = [];
      for (var k = 0; k < n; k++) { // tabandan kavisli yükselen ince dallar, karşılıklı küçük yapraklar
        var a = -1.57 + (k - (n - 1) / 2) * 0.34, L = H * (0.8 + (k % 3) * 0.12), ex = 50 + Math.cos(a) * L * 1.1, ey = 112 + Math.sin(a) * L, cx = 50 + Math.cos(a) * L * 0.3, cy = 112 + Math.sin(a) * L * 0.95 - 2;
        dal.push([cx, cy, ex, ey]); add(Q(50, 112, cx, cy, ex, ey), 'none', 1, '#5E7A3A', 0.8);
        var nl = 2 + i * 2, ang = Math.atan2(ey - cy, ex - cx);
        for (var j = 1; j <= nl; j++) { var q = boyunca(50, 112, cx, cy, ex, ey, j / (nl + 1)); add(leaf(q[0], q[1], ang + 0.9, 2.6, 0.9), 'url(#gYaprakKoyu)'); add(leaf(q[0], q[1], ang - 0.9, 2.6, 0.9), 'url(#gYaprakKoyu)'); }
        add(leaf(ex, ey, ang, 2.8, 0.9), 'url(#gYaprakKoyu)');
      }
      if (i === 2) { var o = ease(p); for (var j2 = 0; j2 < 14; j2++) { var d = dal[j2 % n], q2 = boyunca(50, 112, d[0], d[1], d[2], d[3], 0.45 + r() * 0.55), x2 = q2[0] + (r() - 0.5) * 3, y2 = q2[1] + (r() - 0.5) * 3;
        if (j2 % 4 === 3) { add(El(x2, y2, 0.6, 1.1), '#F0B6C8'); continue; }
        var s = 1.3 + o * 1.2; petals(x2, y2, 5, s, s * 0.42, 'url(#gBeyazYaprak)', r(), 1, '#D6BFCB'); add(C(x2, y2, s * 0.2), '#F4E2A0'); } }
    },
    sakayik: function () {
      shadow(13 + i * 4);
      var H = sv([6, 16, 22, 24]);
      for (var k = 0; k < (i === 0 ? 3 : 9); k++) { var a = -1.57 + (k - 4) * 0.34, L = H * 0.75; add(leaf(50, 112, a, L, L * 0.3), 'url(#gYaprakKoyu)'); add(leaf(50 + Math.cos(a) * L * 0.6, 112 + Math.sin(a) * L * 0.6, a + 0.6, L * 0.4, L * 0.14), 'url(#gYaprakKoyu)'); }
      if (i >= 2) [[0, 1], [-8, 0.8], [8, 0.84]].forEach(function (q, k) { var x = 50 + q[0], y = 112 - H * q[1] - 3;
        if (i === 2) add(C(x, y, 1.6 + p * 1.6 - k * 0.3), 'url(#gSakayik)'); else { var R = lerp(3.4, 7, ease(p)) * (k ? 0.82 : 1); for (var j = 0; j < 9; j++) { var a2 = j * 0.698 + r() * 0.3; add(C(x + Math.cos(a2) * R * 0.55, y + Math.sin(a2) * R * 0.45, R * 0.48), 'url(#gSakayik)'); } for (var j2 = 0; j2 < 5; j2++) { var a3 = j2 * 1.256; add(C(x + Math.cos(a3) * R * 0.25, y + Math.sin(a3) * R * 0.2 - R * 0.1, R * 0.32), '#FFB6CF'); } add(C(x, y - R * 0.15, R * 0.22), '#FFE3EC'); } });
    },
    frezya: function () {
      shadow(10 + i * 3);
      var H = sv([6, 22, 30]);
      [-1.95, -1.7, -1.4].forEach(function (a) { add(leaf(50, 112, a, H * 0.8, 1.6), 'url(#gLaleYaprak)'); });
      if (i >= 1) { var ex = 50 + H * 0.45, ey = 112 - H; add(Q(50, 112, 47, 112 - H * 1.05, ex, ey), 'none', 1, '#5E9A4A', 1);
        var n = i === 1 ? 3 : 6; for (var k = 0; k < n; k++) { var t = 0.55 + k * 0.08, x = (1 - t) * (1 - t) * 50 + 2 * (1 - t) * t * 47 + t * t * ex, y = (1 - t) * (1 - t) * 112 + 2 * (1 - t) * t * (112 - H * 1.05) + t * t * ey;
          if (i === 1 || k > n * ease(p)) bud(x, y - 1, 0.8, 'url(#gYaprakGenc)'); else { var s = 2.4 + (n - k) * 0.25; add(leaf(x, y, -1.2, s * 1.8, s * 0.7), 'url(#gFrezya)'); add(leaf(x, y, -1.9, s * 1.5, s * 0.55), 'url(#gFrezya)'); add(C(x + 0.6, y - s * 0.6, s * 0.25), '#F08A2A', 0.8); } } }
    },
    ortanca: function () {
      shadow(14 + i * 5);
      var H = sv([6, 16, 22, 24]);
      for (var k = 0; k < (i === 0 ? 3 : 8); k++) { var a = -1.57 + (k - 3.5) * 0.36, L = H * 0.7; add(leaf(50, 112, a, L, L * 0.38), 'url(#gYaprak)'); add(rib(50, 112, a, L), 'none', 0.4, '#1E5E30', 0.5); }
      if (i >= 2) [[0, 1], [-9, 0.78], [9, 0.82]].forEach(function (q, k) { var x = 50 + q[0], y = 112 - H * q[1] - 2, R = lerp(3, 7, ease(i === 3 ? 1 : p)) * (k ? 0.85 : 1);
        if (i === 2) add(C(x, y, R * 0.8), 'url(#gYaprakGenc)'); else { var g = k === 1 ? 'url(#gOrtancaPembe)' : 'url(#gOrtanca)'; add(C(x, y, R), g, 0.9); var m = Math.round(16 * lod + 4); for (var j = 0; j < m; j++) { var a2 = r() * 6.28, d = Math.sqrt(r()) * R * 0.85, px = x + Math.cos(a2) * d, py = y + Math.sin(a2) * d; petals(px, py, 4, 1.1 * ease(p) + 0.3, 0.55, g, r()); add(C(px, py, 0.25), '#FFFFFF', 0.8); } } });
    },
    nilufer: function () {
      add(El(50, 110, 30, 6.5), 'url(#gSu)', 0.95); add(El(44, 108.6, 9, 1.4), '#FFFFFF', 0.25);
      var n = i === 0 ? 2 : 3 + Math.round(bol * 3), R = sv([5, 8, 9]), ped = [];
      for (var k = 0; k < n; k++) { var x = 50 + (k - (n - 1) / 2) * Math.min(13, 46 / n), y = 110 + (k % 2 ? 1.5 : -0.5); ped.push([x, y]); add('M' + f(x) + ' ' + f(y) + 'L' + f(x + R * 0.9) + ' ' + f(y - R * 0.12) + 'C' + f(x + R) + ' ' + f(y + R * 0.3) + ' ' + f(x + R * 0.4) + ' ' + f(y + R * 0.32) + ' ' + f(x - R * 0.2) + ' ' + f(y + R * 0.3) + 'C' + f(x - R) + ' ' + f(y + R * 0.25) + ' ' + f(x - R) + ' ' + f(y - R * 0.25) + ' ' + f(x - R * 0.2) + ' ' + f(y - R * 0.3) + 'C' + f(x + R * 0.3) + ' ' + f(y - R * 0.32) + ' ' + f(x + R * 0.7) + ' ' + f(y - R * 0.28) + ' ' + f(x) + ' ' + f(y) + 'Z', 'url(#gNiluferYaprak)'); }
      var cx = 50, cy = 106;
      if (i === 1) { stem(50, 110, cx, cy - 3, 0, 0.8, '#4E8A3E'); bud(cx, cy - 4, 1.2 + p * 1.5, 'url(#gNilufer)'); }
      function cicek(fx, fy, L) { for (var j = 0; j < 7; j++) { var a = -1.57 + (j - 3) * (0.38 + ease(p) * 0.12); add(leaf(fx, fy, a, L * (j === 3 ? 1.05 : 0.95), L * 0.34), 'url(#gNilufer)'); } for (var j2 = 0; j2 < 5; j2++) { var a2 = -1.57 + (j2 - 2) * 0.32; add(leaf(fx, fy + 0.5, a2, L * 0.7, L * 0.28), '#FFE3EE'); } add(El(fx, fy - L * 0.25, L * 0.18, L * 0.12), '#FFD23F'); }
      if (i === 2) { var L0 = lerp(5, 9, ease(p)), ek = Math.round(bol * 3); for (var e2 = 0; e2 < ek; e2++) { var pd = ped[(e2 * 2) % n]; if (Math.abs(pd[0] - cx) > 4) cicek(pd[0], pd[1] - 3, L0 * 0.7); } cicek(cx, cy, L0); }
    },
    kamelya: function () {
      shadow(14 + i * 5);
      var H = sv([8, 22, 30]);
      trunk(50, 112, H * 0.3, 1.2, 0.8, 0, 'url(#gGovdeKoyu)');
      canopy(50, 112 - H * 0.6, H * 0.45, 7 + i * 2, 'url(#gKureKoyu)', 'url(#gYaprakParlak)', 0.85);
      if (i === 2) { var o = ease(p); for (var k = 0; k < 7; k++) { var a = r() * 6.28, d = Math.sqrt(r()) * H * 0.38, x = 50 + Math.cos(a) * d, y = 112 - H * 0.6 + Math.sin(a) * d * 0.8, R = 1.6 + o * 1.8; for (var j = 0; j < 7; j++) add(C(x + Math.cos(j * 0.9) * R * 0.5, y + Math.sin(j * 0.9) * R * 0.45, R * 0.55), 'url(#gKamelya)'); add(C(x, y, R * 0.38), '#FFB8C8'); add(C(x, y, R * 0.14), '#FFD23F'); } }
    },
    begonvil: function () {
      shadow(22);
      // sabit bahçe kemeri; iki sarmaşık direklerden tırmanıp kemerde buluşur
      add('M29.4 112L30.2 72L31.8 72L32.6 112Z', 'url(#gGovde)'); add('M67.4 112L68.2 72L69.8 72L70.6 112Z', 'url(#gGovde)'); add(Q(31, 72, 50, 50, 69, 72), 'none', 1, '#8A6A4A', 1.8);
      var G = i === 0 ? 0.3 * ease(p) + 0.04 : i === 1 ? 0.3 + 0.7 * ease(p) : 1;
      function yer(u, sag) { var x, y; if (u < 0.5) { x = 31; y = 112 - u / 0.5 * 40; } else { var q = boyunca(31, 72, 50, 50, 69, 72, (u - 0.5)); x = q[0]; y = q[1]; } return [sag ? 100 - x : x, y]; }
      [false, true].forEach(function (sag) {
        var d = '', m = Math.max(2, Math.round(G * 14)); for (var k = 0; k <= m; k++) { var q = yer(G * k / m, sag); d += (k ? 'L' : 'M') + f(q[0] + Math.sin(k * 1.7) * 0.8) + ' ' + f(q[1]); }
        add(d, 'none', 1, '#6E4A2E', 1.2);
        var nl = Math.round(G * 16) + 2; for (var k2 = 0; k2 < nl; k2++) { var q2 = yer(G * (k2 + 0.5) / nl, sag); add(leaf(q2[0], q2[1], r() * 6.28, 3.2, 1.3), k2 % 3 ? 'url(#gYaprak)' : 'url(#gYaprakGenc)'); }
      });
      if (i === 2) { var o = ease(p), nf = Math.round((24 + bol * 30) * Math.min(1, 0.25 + o)); for (var k3 = 0; k3 < nf; k3++) { var q3 = yer(0.25 + r() * 0.75, k3 % 2 === 1), x2 = q3[0] + (r() - 0.5) * 6, y2 = q3[1] + (r() - 0.3) * 5, s = 1.2 + o * 1.4; for (var j = 0; j < 3; j++) add(leaf(x2, y2, j * 2.094 + r(), s * 1.4, s * 0.8), 'url(#gBegonvil)'); add(C(x2, y2, 0.4), '#FFF2C0'); } }
    },
    terslale: function () {
      shadow(10 + i * 3);
      if (i === 0) { mound(10); add(El(50, 110.5, 4.6, 3.2), 'url(#gSogan)'); if (p > 0.3) add(leaf(50, 108, -1.57, 2 + p * 4, 1.6), 'url(#gYaprakGenc)'); return; }
      var H = sv([8, 34, 50, 56]);
      for (var k = 0; k < 6; k++) add(leaf(50, 112, -1.57 + (k - 2.5) * 0.3, 10 + (k % 2) * 3, 2), 'url(#gLaleYaprak)');
      stem(50, 112, 50, 112 - H, 0, 2.2, '#5E8E44');
      var top = 112 - H;
      if (i >= 2) { var n2 = 7; for (var j = 0; j < n2; j++) { var a = -1.57 + (j - 3) * 0.32; add(leaf(50, top, a, 7 + (i === 3 ? 2 : 0), 1.8), 'url(#gYaprakGenc)'); } }
      if (i >= 2) { var bells = 6, o = i === 3 ? ease(p) : 0; for (var b2 = 0; b2 < bells; b2++) { var a2 = 0.5 + b2 * 0.42, bx = 50 + Math.cos(a2) * 5.5 * (b2 % 2 ? 1 : -1) * 0.9, by = top + 4 + (b2 % 3) * 0.6; add(Q(50, top + 1, bx, top + 1, bx, by - 1), 'none', 1, '#5E8E44', 0.6);
        if (i === 2) add(El(bx, by + 1, 1.2 + p * 0.5, 1.6 + p * 0.6), 'url(#gYaprakGenc)'); else { var s = 2.2 + o * 1.4; add('M' + f(bx - s * 0.6) + ' ' + f(by) + 'Q' + f(bx - s * 0.8) + ' ' + f(by + s * 1.6) + ' ' + f(bx - s * 0.3) + ' ' + f(by + s * 2.1) + 'L' + f(bx + s * 0.3) + ' ' + f(by + s * 2.1) + 'Q' + f(bx + s * 0.8) + ' ' + f(by + s * 1.6) + ' ' + f(bx + s * 0.6) + ' ' + f(by) + 'Z', 'url(#gTersLale)'); add(C(bx, by + s * 2.1, 0.35), '#FFF6C0'); } } }
    },
    yesim: function () {
      shadow(24);
      // sabit çardak; sarmaşık soldaki direkten tırmanıp üst kirişte yayılır, salkımlar kirişten sarkar
      var Y0 = 64; add('M27.4 112L28.2 ' + Y0 + 'L29.8 ' + Y0 + 'L30.6 112Z', 'url(#gGovde)'); add('M69.4 112L70.2 ' + Y0 + 'L71.8 ' + Y0 + 'L72.6 112Z', 'url(#gGovde)'); add('M25 ' + (Y0 - 1) + 'L75 ' + (Y0 - 1) + 'L75 ' + (Y0 + 1) + 'L25 ' + (Y0 + 1) + 'Z', 'url(#gGovde)');
      var G = i === 0 ? 0.35 * ease(p) + 0.04 : i === 1 ? 0.35 + 0.65 * ease(p) : 1;
      function yer(u) { return u < 0.45 ? [29, 112 - u / 0.45 * (112 - Y0)] : [29 + (u - 0.45) / 0.55 * 43, Y0]; }
      var d = '', m = Math.max(2, Math.round(G * 16)); for (var k = 0; k <= m; k++) { var q = yer(G * k / m); d += (k ? 'L' : 'M') + f(q[0] + Math.sin(k * 1.9) * 0.9) + ' ' + f(q[1] + Math.cos(k * 1.3) * 0.6); } add(d, 'none', 1, '#4E6A2E', 1.2);
      var nl = Math.round(G * 20) + 2; for (var k2 = 0; k2 < nl; k2++) { var q2 = yer(G * (k2 + 0.5) / nl); for (var j0 = 0; j0 < 3; j0++) add(leaf(q2[0], q2[1], 1.57 + (j0 - 1) * 0.9 + (r() - 0.5) * 0.6, 3.6, 1.2), 'url(#gYaprakKoyu)'); }
      if (i >= 2) { var xs = [37, 47, 57, 66].concat(bol > 0.3 ? [42, 52, 62] : []); xs.forEach(function (x, kk) { var len = (i === 2 ? lerp(4, 14, ease(p)) : 16) * (kk % 2 ? 0.85 : 1); add('M' + f(x) + ' ' + f(Y0) + 'L' + f(x) + ' ' + f(Y0 + len), 'none', 1, '#3E5A2E', 0.7);
        var n = Math.round(len / 1.6); for (var j = 0; j < n; j++) { var y = Y0 + 2 + j * 1.6, side = j % 2 ? 1 : -1, s = 1.4 + (i === 3 ? ease(p) * 1.2 : 0);
          if (i === 2) add(El(x + side * 1.2, y, 0.6, 0.9), '#7FCFA8'); else add('M' + f(x) + ' ' + f(y) + 'Q' + f(x + side * s * 1.8) + ' ' + f(y - s * 0.4) + ' ' + f(x + side * s * 1.6) + ' ' + f(y + s * 1.2) + 'Q' + f(x + side * s * 0.6) + ' ' + f(y + s * 0.4) + ' ' + f(x) + ' ' + f(y) + 'Z', 'url(#gYesim)'); } }); }
    },
    rafflesia: function () {
      shadow(18 + i * 6);
      add(Q(30, 112, 40, 104, 50, 110), 'none', 0.9, '#6E4A2E', 1.4); add(Q(70, 112, 62, 105, 52, 110), 'none', 0.9, '#6E4A2E', 1.2);
      if (i < 2) { var R = sv([3, 9, 12]); add(El(50, 112 - R * 0.6, R, R * 0.75), i === 0 ? '#8A4A2E' : 'url(#gRafflesia)'); for (var k = 0; k < 6 && i === 1; k++) add(leaf(50, 112 - R * 0.2, -1.57 + (k - 2.5) * 0.45, R * 1.15, R * 0.42), '#7A2E1E', 0.9); add(El(50 - R * 0.3, 112 - R * 0.9, R * 0.25, R * 0.12), '#FFFFFF', 0.25); return; }
      var o = ease(p), R2 = lerp(12, 20, o), cy = 108;
      for (var j = 0; j < 5; j++) { var a = -1.57 + j * 1.2566; add(El(50 + Math.cos(a) * R2 * 0.55, cy + Math.sin(a) * R2 * 0.28, R2 * 0.42, R2 * 0.24), 'url(#gRafflesia)'); for (var w = 0; w < 6 * lod; w++) add(C(50 + Math.cos(a) * R2 * (0.4 + r() * 0.35) + (r() - 0.5) * 3, cy + Math.sin(a) * R2 * 0.24 + (r() - 0.5) * 2, 0.5 + r() * 0.5), '#F6E6D6', 0.85); }
      add(El(50, cy - 1, R2 * 0.36, R2 * 0.16), '#5E140E'); add(El(50, cy - 1.6, R2 * 0.26, R2 * 0.1), '#2A0806'); add(El(50, cy - 3.4, R2 * 0.32, R2 * 0.06), '#8E2A1A', 0.8);
    },
    orkide: function () {
      // yosunlu dal parçasına sarılan kökler; yapraksız ince sap; uzun kuyruklu beyaz çiçek
      add(El(50, 109, 17, 3.4), 'url(#gGovdeKoyu)'); add(El(45, 107.4, 10, 1.3), '#8EA070', 0.8); add(El(57, 107.8, 5, 0.9), '#A6B87E', 0.7);
      var nk = i === 0 ? 3 + Math.round(p * 4) : 7;
      for (var k = 0; k < nk; k++) { var sx = 46 + k * 1.4, side = k % 2 ? 1 : -1, ex = sx + side * (6 + (k % 3) * 3); add(Q(sx, 106.5, sx + side * 4, 105 + (k % 3), ex, 110.5 + (k % 2)), 'none', 0.95, '#A9BCA2', 0.9); add(C(ex, 110.5 + (k % 2), 0.45), '#D8E6CF'); }
      add(El(50, 106, 2.8, 1.5), '#7E9A7A');
      if (i >= 1) {
        var H = i === 1 ? lerp(4, 24, ease(p)) : i === 2 ? lerp(24, 32, ease(p)) : 32, tx = 50 + H * 0.22, ty = 106 - H;
        add(Q(50, 106, 47, 106 - H * 0.6, tx, ty), 'none', 1, '#7E9A6E', 0.8);
        if (i === 2) bud(tx, ty, 1 + p * 1.2, 'url(#gOrkide)');
        if (i === 3) {
          var o = ease(p), s = lerp(4, 7.5, o), cy = ty + s * 0.4, st = '#9FC6AE';
          add(El(tx, cy + s * 0.6, s * 3, s * 3), 'url(#gHale)', 0.9);
          add(leaf(tx, cy, -1.57, s * 1.4, s * 0.3), 'url(#gOrkide)', 1, st, 0.3);
          add(leaf(tx, cy, -2.55, s * 1.25, s * 0.28), 'url(#gOrkide)', 1, st, 0.3); add(leaf(tx, cy, -0.59, s * 1.25, s * 0.28), 'url(#gOrkide)', 1, st, 0.3);
          [-1, 1].forEach(function (sd) { var bx = tx + sd * s * 0.35, by = cy + s * 0.8; add(Q(bx, by, tx + sd * s * 1.7, cy + s * 2.1, tx + sd * s * 1.0, cy + s * (1.4 + 2.4 * o)), 'none', 1, st, 1.5); add(Q(bx, by, tx + sd * s * 1.7, cy + s * 2.1, tx + sd * s * 1.0, cy + s * (1.4 + 2.4 * o)), 'none', 1, '#F7FCF8', 0.9); });
          add(El(tx, cy + s * 0.55, s * 0.62, s * 0.45), 'url(#gOrkide)', 1, st, 0.3); add(C(tx, cy + s * 0.1, s * 0.16), '#D6F0C0');
        }
      }
    },
    // ——— Ağaçlar ———
    cam: function () { var H = sv([8, 20, 36]), W = H * 0.32 + 3; shadow(W * 0.9); trunk(50, 112, 9, 1.6 + i * 0.5, 1.2, 0, 'url(#gGovde)'); if (i === 0) { fide(H * 0.7, 'url(#gCam)'); return; } koni(H, W, 'url(#gCam)', 3 + i * 2); },
    kavak: function () { var H = sv([8, 28, 46]), W = 3 + H * 0.12; shadow(W + 3); trunk(50, 112, 10 + H * 0.15, 1.4 + i * 0.4, 0.8, 0, 'url(#gGovdeGri)'); if (i === 0) { fide(H * 0.7); return; }
      var top = 112 - 8 - H; add(El(50, top + H * 0.5, W, H * 0.52), 'url(#gKavak)', 0.65); for (var k = 0; k < 10 + i * 4; k++) { var t = r(), y = top + H * (0.08 + t * 0.85), w = W * Math.sin(Math.max(0.2, Math.min(3, (0.1 + t * 0.9) * 3.1))); add(C(50 + (r() - 0.5) * w * 1.3, y, w * 0.45 + 0.8), 'url(#gKavak)'); } add(El(50 - W * 0.35, top + H * 0.25, W * 0.25, H * 0.12), 'url(#gParlak)', 0.45); },
    elma: function () { yuvarlak({ th: [12, 22, 30, 32], R: [5, 11, 16, 17], g: 'url(#gKureNar)', lg: 'url(#gYaprakParlak)', ry: 0.82, cicekEvre: 2, adet: 12, cicek: function (x, y) { blossom(x, y, 1.6, 'url(#gBadem)', '#FFD23F'); }, meyve: function (x, y) { fruit(x, y, 2.2, 'url(#gElma)'); add(Q(x, y - 2.2, x + 0.3, y - 3, x + 0.8, y - 3.2), 'none', 1, '#4A2F1E', 0.4); } }); },
    incir: function () { yuvarlak({ th: [10, 18, 26, 28], R: [5, 12, 17, 18], g: 'url(#gIncir)', lg: 'url(#gYaprakGenc)', ry: 0.72, tw: 3, bark: 'url(#gGovdeGri)', adet: 11,
      ekle: function (cx, cy, R, ry) { if (lod > 0.6) for (var k = 0; k < 8; k++) { var a = r() * 6.28, d = Math.sqrt(r()) * R * 0.85, x = cx + Math.cos(a) * d, y = cy + Math.sin(a) * d * ry; for (var j = 0; j < 3; j++) add(leaf(x, y, -1.57 + (j - 1) * 0.9, R * 0.22, R * 0.09), 'url(#gIncir)'); } },
      meyve: function (x, y) { add('M' + f(x) + ' ' + f(y - 2.6) + 'Q' + f(x + 2.4) + ' ' + f(y) + ' ' + f(x) + ' ' + f(y + 1.8) + 'Q' + f(x - 2.4) + ' ' + f(y) + ' ' + f(x) + ' ' + f(y - 2.6) + 'Z', 'url(#gIncirMeyve)'); } }); },
    asma: function () {
      var H = sv([10, 26, 38, 40]); shadow(14 + i * 5);
      add('M47.5 112L48.2 ' + f(112 - H) + 'L51.8 ' + f(112 - H) + 'L52.5 112Z', 'url(#gGovdeKoyu)');
      add('M28 112L28.6 ' + f(112 - 40) + 'L30.4 ' + f(112 - 40) + 'L31 112Z', 'url(#gGovde)', 0.95); add('M69 112L69.6 72L71.4 72L72 112Z', 'url(#gGovde)', 0.95); add('M26 72L74 72L74 74L26 74Z', 'url(#gGovde)', 0.95);
      if (i === 0) { for (var k = 0; k < 3; k++) add(leaf(50, 112 - H + k * 3, k % 2 ? -0.6 : -2.5, 4, 2), 'url(#gYaprakGenc)'); return; }
      var span = i === 1 ? ease(p) * 0.6 : i === 2 ? 0.6 + ease(p) * 0.4 : 1;
      add(Q(50, 112 - H, 40, 70, 50 - 22 * span, 72), 'none', 1, '#5A3A24', 1.2); add(Q(50, 112 - H, 60, 70, 50 + 22 * span, 72), 'none', 1, '#5A3A24', 1.2);
      var n = Math.round((6 + i * 8) * span + 3); for (var k2 = 0; k2 < n; k2++) { var x = 50 + (r() - 0.5) * 46 * span, y = 72 + (r() - 0.6) * 9, s = 3.4; for (var j = 0; j < 3; j++) add(leaf(x, y, -1.57 + (j - 1) * 1.1, s, s * 0.55), r() > 0.4 ? 'url(#gYaprak)' : 'url(#gYaprakGenc)'); }
      if (i === 3) { var o = ease(p); for (var c = 0; c < 6; c++) { var gx = 50 + (c - 2.5) * 7.5, gy = 76; for (var j2 = 0; j2 < 9; j2++) { var row = Math.floor(j2 / 3); add(C(gx + (j2 % 3 - 1) * 1.3 + row * 0.2, gy + row * 1.5 + (j2 % 3 === 1 ? 0.4 : 0), 0.65 + o * 0.35), 'url(#gUzum)'); } add(C(gx + 0.8, gy + 4.6, 0.6 + o * 0.3), 'url(#gUzum)'); } }
    },
    ihlamur: function () { yuvarlak({ th: [12, 22, 32, 34], R: [5, 12, 18, 19], g: 'url(#gIhlamur)', lg: 'url(#gYaprakGenc)', ry: 0.84, adet: 14, cicekEvre: 3, cicek: function (x, y) { for (var j = 0; j < 4; j++) add(C(x + (j % 2) * 1.2 - 0.6, y + Math.floor(j / 2) * 1.1, 0.75), '#F6EBA0'); add(leaf(x, y - 1, -0.6, 3, 0.9), '#D8E6A0'); } }); },
    erguvan: function () { yuvarlak({ th: [12, 22, 30, 32], R: [5, 11, 16, 17], g: 'url(#gKureNar)', tac: function (k) { return k >= 2 ? 'url(#gErguvan)' : 'url(#gKureNar)'; }, lg: 'url(#gErguvan)', ry: 0.8, adet: 18, hepCicek: 2, bark: 'url(#gGovdeKoyu)', cicek: function (x, y) { for (var j = 0; j < 3; j++) add(El(x + (j - 1) * 1.1, y + (j % 2) * 0.8, 0.9, 0.6), j % 2 ? '#E85ABA' : '#C2389A'); } }); },
    misvak: function () { yuvarlak({ th: [10, 16, 20, 22], R: [5, 13, 18, 20], g: 'url(#gMisvak)', lg: 'url(#gYaprakGenc)', ry: 0.62, cokGovde: true, tw: 2.4, adet: 16, meyve: function (x, y) { add(C(x, y, 0.8), '#D2483A'); add(C(x + 1.2, y + 0.6, 0.7), '#E8743A'); },
      ekle: function (cx, cy, R, ry) { for (var k = 0; k < 10; k++) { var x = cx + (r() - 0.5) * R * 1.8; add(Q(x, cy + R * ry * 0.4, x + (r() - 0.5) * 3, cy + R * ry * 0.8, x + (r() - 0.5) * 4, cy + R * ry * 1.1), 'none', 0.8, '#7E9A5A', 0.8); } } }); },
    akcaagac: function () { yuvarlak({ th: [12, 22, 32, 34], R: [5, 12, 18, 19], g: 'url(#gKureKoyu)', tac: function (k) { return k >= 3 ? 'url(#gAkcaagac)' : k === 2 ? 'url(#gSigla)' : 'url(#gKureKoyu)'; }, lg: 'url(#gSigla)', ry: 0.82, adet: 0 }); },
    sogut: function () {
      var H = sv([10, 24, 34, 36]), R = sv([5, 12, 18, 20]); shadow(R + 4);
      if (i === 0) { fide(H, 'url(#gSogut)'); return; }
      trunk(50, 112, H, 2.4 + i * 0.6, 1.4, 2, 'url(#gGovdeGri)');
      branch(52, 112 - H * 0.75, 50 - R * 0.6, 112 - H - R * 0.05, 1.5, '#6E5A48'); branch(52, 112 - H * 0.8, 50 + R * 0.65, 112 - H - R * 0.1, 1.3, '#6E5A48');
      var cx = 51, cy = 112 - H - R * 0.15;
      function ust(t) { return cy - R * 0.5 * Math.sqrt(Math.max(0, 1 - (2 * t - 1) * (2 * t - 1))); }
      add(El(cx, cy, R * 1.02, R * 0.5), 'url(#gSogut)', 0.7);
      var n = Math.round((16 + i * 8) * lod + 6);
      for (var k = 0; k < n; k++) { // kubbeden sarkan saçaklar: arkadakiler koyu, öndekiler açık
        var t = r(), x0 = cx - R + t * 2 * R, y0 = ust(t) + 1 + r() * R * 0.25, kenar = Math.sqrt(Math.max(0, 1 - (2 * t - 1) * (2 * t - 1))), len = (R * 0.85 + i * 2.5) * (0.55 + r() * 0.45) * (0.6 + 0.4 * kenar), sw = (t - 0.5) * 6 + (r() - 0.5) * 2;
        var col = k % 3 === 0 ? '#4E8A3A' : k % 3 === 1 ? '#7EB850' : '#A6D670';
        add(Q(x0, y0, x0 + sw * 0.25, y0 + len * 0.55, x0 + sw, y0 + len), 'none', 0.95, col, 1.1 + r() * 0.5);
        if (lod > 0.6) for (var j = 1; j <= 3; j++) { var tt = j / 4; add(leaf(x0 + sw * tt * tt, y0 + len * tt, 1.57 + (r() - 0.5) * 0.7, 1.9, 0.5), 'url(#gSogut)', 0.95); }
      }
      for (var k2 = 0; k2 < 8; k2++) { var t2 = (k2 + 0.5) / 8; add(El(cx - R * 0.9 + t2 * R * 1.8, ust(t2) + R * 0.05, R * 0.22, R * 0.12), 'url(#gSogut)'); }
      add(El(cx - R * 0.35, cy - R * 0.3, R * 0.3, R * 0.09), 'url(#gParlak)', 0.45);
    },
    sedir: function () {
      var H = sv([10, 30, 50, 54]), W = sv([5, 14, 22, 26]); shadow(W * 0.9 + 3);
      if (i === 0) { fide(H * 0.8, 'url(#gSedir)'); return; }
      trunk(50, 112, H * 0.95, 2.4 + i * 0.7, 1, 0, 'url(#gGovde)');
      var kat = 2 + i; for (var k = 0; k < kat; k++) { var t = k / kat, y = 112 - H * (0.35 + t * 0.6), w = W * (1 - t * 0.55) * (k % 2 ? 0.92 : 1), off = k % 2 ? 3 : -2;
        add(Q(50, y + 2, 50 + off - w * 0.5, y, 50 + off - w, y + 1), 'none', 1, '#5A3A24', 1); add(Q(50, y + 2, 50 + off + w * 0.5, y, 50 + off + w, y + 1), 'none', 1, '#5A3A24', 1);
        add('M' + f(50 + off - w * 1.08) + ' ' + f(y + 1.5) + 'Q' + f(50 + off) + ' ' + f(y - 9.5) + ' ' + f(50 + off + w * 1.08) + ' ' + f(y + 1.5) + 'Q' + f(50 + off) + ' ' + f(y + 4.6) + ' ' + f(50 + off - w * 1.08) + ' ' + f(y + 1.5) + 'Z', 'url(#gSedir)');
        if (lod > 0.6) add(Q(50 + off - w * 0.8, y - 0.5, 50 + off, y - 4.5, 50 + off + w * 0.8, y - 0.5), 'none', 0.4, '#CFEFDF', 0.6); }
    },
    manolya: function () { yuvarlak({ th: [12, 22, 30, 32], R: [5, 11, 15, 16], g: 'url(#gKureKoyu)', tac: function (k) { return k >= 3 ? 'url(#gIhlamur)' : 'url(#gKureKoyu)'; }, lg: 'url(#gYaprakGenc)', ry: 0.86, adet: 12, hepCicek: 2, bark: 'url(#gGovdeGri)',
      cicek: function (x, y, k) { var s = i === 2 ? 1 + p * 0.8 : 2.2; if (i === 2) { bud(x, y, s * 0.8, 'url(#gManolya)'); return; } add(leaf(x, y + s, -1.9, s * 2, s * 0.7), 'url(#gManolya)'); add(leaf(x, y + s, -1.25, s * 2, s * 0.7), 'url(#gManolya)'); add(leaf(x, y + s, -1.57, s * 2.2, s * 0.6), '#FFF4F8'); } }); },
    sakura: function () { yuvarlak({ th: [12, 22, 30, 32], R: [5, 12, 17, 19], g: 'url(#gKureNar)', tac: function (k) { return k >= 2 ? 'url(#gSakura)' : 'url(#gKureNar)'; }, lg: 'url(#gBadem)', ry: 0.74, adet: 22, hepCicek: 2, bark: 'url(#gGovdeKoyu)', bend: 2,
      cicek: function (x, y) { blossom(x, y, i === 2 ? 0.9 + p * 0.6 : 1.7, 'url(#gBadem)', '#E8578A'); } }); },
    sidre: function () { yuvarlak({ th: [10, 18, 26, 28], R: [5, 13, 19, 21], g: 'url(#gSidre)', lg: 'url(#gYaprakGenc)', ry: 0.6, tw: 3, bark: 'url(#gGovdeKoyu)', bend: 3, adet: 16,
      ekle: function (cx, cy, R, ry) { if (lod > 0.6) for (var k = 0; k < 12; k++) { var a = r() * 6.28, x = cx + Math.cos(a) * R * 0.95, y = cy + Math.sin(a) * R * ry * 0.95; add('M' + f(x) + ' ' + f(y) + 'l' + f(Math.cos(a) * 1.6) + ' ' + f(Math.sin(a) * 1.6), 'none', 0.8, '#5A4A2E', 0.4); } },
      meyve: function (x, y) { add(C(x, y, 1.1), 'url(#gSidreMeyve)'); } }); },
    jakaranda: function () { yuvarlak({ th: [12, 22, 32, 34], R: [5, 12, 18, 20], g: 'url(#gKureKoyu)', tac: function (k) { return k >= 3 ? 'url(#gJakaranda)' : 'url(#gKureKoyu)'; }, lg: 'url(#gJakaranda)', ry: 0.68, adet: 20, hepCicek: 3, bark: 'url(#gGovdeGri)', bend: 2,
      cicek: function (x, y) { for (var j = 0; j < 4; j++) add(El(x + (j % 2) * 1.3 - 0.6, y + Math.floor(j / 2) * 1.1, 0.8, 0.55), j % 2 ? '#B49CF2' : '#7E62D8'); } }); },
    sigla: function () { yuvarlak({ th: [12, 24, 34, 36], R: [5, 12, 18, 20], g: 'url(#gKureKoyu)', tac: function (k) { return k >= 3 ? 'url(#gSigla)' : 'url(#gKureCinar)'; }, lg: 'url(#gSigla)', ry: 0.8, adet: 0, bark: 'url(#gGovdeKoyu)',
      ekle: function (cx, cy, R, ry) { if (i < 3) return; var renk = ['#F2C12E', '#F08A2A', '#E2482A', '#B8221A', '#8E1A3A']; for (var k = 0; k < 26 * lod; k++) { var a = r() * 6.28, d = Math.sqrt(r()) * R * 0.92, x = cx + Math.cos(a) * d, y = cy + Math.sin(a) * d * ry, s = 1.3 + r() * 0.8; for (var j = 0; j < 5; j++) add(leaf(x, y, -1.57 + j * 1.2566, s, s * 0.32), renk[k % 5]); } } }); },
    baobab: function () {
      var H = sv([8, 20, 30, 34]), W = sv([1.4, 4, 9, 12]); shadow(W * 1.6 + 6);
      if (i === 0) { fide(H); return; }
      add('M' + f(50 - W) + ' 112C' + f(50 - W * 1.25) + ' ' + f(112 - H * 0.5) + ' ' + f(50 - W * 0.55) + ' ' + f(112 - H * 0.9) + ' ' + f(50 - W * 0.35) + ' ' + f(112 - H) + 'L' + f(50 + W * 0.35) + ' ' + f(112 - H) + 'C' + f(50 + W * 0.55) + ' ' + f(112 - H * 0.9) + ' ' + f(50 + W * 1.25) + ' ' + f(112 - H * 0.5) + ' ' + f(50 + W) + ' 112Z', 'url(#gBaobabGovde)');
      if (lod > 0.6) for (var k = 0; k < 5; k++) add(Q(50 - W * 0.6 + k * W * 0.3, 111, 50 - W * 0.5 + k * W * 0.28, 112 - H * 0.5, 50 - W * 0.2 + k * W * 0.12, 112 - H * 0.9), 'none', 0.35, '#5A4232', 0.6);
      var top = 112 - H; [[-1, -0.9], [-0.4, -1.2], [0.3, -1.1], [1, -0.85]].forEach(function (q, k) { var ex = 50 + q[0] * (6 + W), ey = top + q[1] * (5 + i * 2); add(Q(50 + q[0] * W * 0.2, top + 1, 50 + q[0] * W * 0.5, ey + 2, ex, ey), 'none', 1, '#7E6450', 1.2 + i * 0.3);
        if (i >= 2) canopy(ex, ey - 1, 3 + i * 1.2, 4, 'url(#gKureZeytin)', 'url(#gYaprakGenc)', 0.6); });
      if (i === 3) { var o = ease(p); for (var k2 = 0; k2 < 6; k2++) { var x = 50 + (r() - 0.5) * (14 + W), y = top + 3 + r() * 3; add(Q(x, y - 1, x + 0.3, y + 1, x, y + 2 * o + 1), 'none', 1, '#6E5A3A', 0.4); add(El(x, y + 2.6 * o + 1.6, 1, 1.6), '#C8AE7A'); } }
    },
    ejder: function () {
      var H = sv([8, 18, 26, 30]), R = sv([4, 9, 18, 24]); shadow(R + 3);
      if (i === 0) { fide(H, 'url(#gEjder)'); return; }
      trunk(50, 112, H * 0.55, 3 + i * 0.6, 2.4, 0, 'url(#gGovdeGri)');
      var top = 112 - H * 0.55, n = 2 + i * 2; for (var k = 0; k < n; k++) { var a = -1.57 + (k - (n - 1) / 2) * 0.32, ex = 50 + Math.cos(a) * H * 0.55, ey = top + Math.sin(a) * H * 0.5; add(Q(50, top, 50 + Math.cos(a) * H * 0.2, top - 4, ex, ey), 'none', 1, '#8E8476', 1.6 + i * 0.2); }
      var cy = top - H * 0.45; add('M' + f(50 - R) + ' ' + f(cy + 2) + 'C' + f(50 - R) + ' ' + f(cy - R * 0.5) + ' ' + f(50 + R) + ' ' + f(cy - R * 0.5) + ' ' + f(50 + R) + ' ' + f(cy + 2) + 'Q50 ' + f(cy + 6) + ' ' + f(50 - R) + ' ' + f(cy + 2) + 'Z', 'url(#gEjder)');
      if (lod > 0.6) for (var k2 = 0; k2 < 30; k2++) { var x = 50 - R * 0.9 + r() * R * 1.8, y = cy - R * 0.32 * Math.sin(((x - 50) / R + 1) * 1.57) + r() * 3; add(leaf(x, y + 1, -1.57 + (r() - 0.5) * 1.6, 2.6, 0.5), 'url(#gEjder)'); }
      add(El(46, cy - R * 0.22, R * 0.3, R * 0.08), 'url(#gParlak)', 0.45);
      if (i === 3) { var o = ease(p); for (var k3 = 0; k3 < 8; k3++) add(C(50 + (r() - 0.5) * R * 1.4, cy + 3 + r() * 2, 0.6 + o * 0.4), '#C21E2A'); }
    },
    okaliptus: function () {
      var H = sv([8, 24, 40, 46]), R = sv([4, 9, 14, 16]); shadow(R + 4);
      if (i === 0) { fide(H, 'url(#gZeytinGumus)'); return; }
      var tw = 1.6 + i * 0.9; trunk(50, 112, H, tw, tw * 0.6, 1, i >= 2 ? 'url(#gOkaliptus)' : 'url(#gGovdeGri)');
      if (i >= 2) { var renk = ['#3EAE6A', '#3E8AD8', '#9A5AD0', '#F08A3A', '#E2C23A', '#C23A5A']; var o = i === 3 ? 1 : ease(p); for (var k = 0; k < Math.round(9 * o * lod) + 2; k++) { var x = 50 - tw * 0.6 + (k % 4) * tw * 0.4, y0 = 111 - (k * 7) % (H * 0.8); add('M' + f(x) + ' ' + f(y0) + 'L' + f(x + 0.3) + ' ' + f(y0 - H * 0.22), 'none', 0.85, renk[k % 6], 0.9); } }
      branch(51, 112 - H * 0.75, 50 - R * 0.6, 112 - H - R * 0.1, tw * 0.4, '#8E8E7A'); branch(51, 112 - H * 0.8, 50 + R * 0.6, 112 - H - R * 0.2, tw * 0.35, '#8E8E7A');
      canopy(51, 112 - H - R * 0.35, R, 7 + i * 2, 'url(#gKureZeytin)', 'url(#gZeytinGumus)', 0.7);
    },
    sekoya: function () {
      var H = sv([10, 32, 60, 70]), W = sv([4, 9, 13, 15]); shadow(W + 4);
      if (i === 0) { fide(H * 0.8, 'url(#gSekoya)'); return; }
      var tw = 1.8 + i * 1.2; trunk(50, 112, H * 0.55, tw, tw * 0.5, 0, 'url(#gSekoyaGovde)');
      if (lod > 0.6) for (var k = 0; k < 4; k++) add(Q(50 - tw * 0.5 + k * tw * 0.33, 111, 50 - tw * 0.4 + k * tw * 0.3, 112 - H * 0.3, 50 - tw * 0.25 + k * tw * 0.17, 112 - H * 0.55), 'none', 0.4, '#4A1A0E', 0.5);
      var top = 112 - 8 - H, kat = 4 + i * 2; for (var k2 = 0; k2 < kat; k2++) { var t = k2 / kat, y = 112 - H * 0.35 - H * 0.62 * t, w = W * (1 - t * 0.7); add(El(50 + (k2 % 2 ? 1.5 : -1.5), y, w, 3.4), 'url(#gSekoya)'); }
      add('M50 ' + f(top - 2) + 'L' + f(50 + W * 0.25) + ' ' + f(top + 8) + 'L' + f(50 - W * 0.25) + ' ' + f(top + 8) + 'Z', 'url(#gSekoya)');
    }
  };

  if (YENI[tur]) { YENI[tur](); return S; }

  if (tur === 'gul') {
    shadow(14 + i * 4);
    if (i === 0) { var h0 = lerp(10, 26, ease(p)); stem(50, 112, 50, 112 - h0, 2, 1.8); add(leaf(50, 112 - h0 * 0.55, -2.6, 10, 3.6), 'url(#gYaprak)'); add(leaf(50, 112 - h0 * 0.8, -0.5, 10 * p + 4, 3.2), 'url(#gYaprakGenc)'); add(leaf(50, 112 - h0, -1.9, 6 * p + 3, 2.4), 'url(#gYaprakGenc)'); }
    else {
      var H = i === 1 ? lerp(30, 54, ease(p)) : 56, top = 112 - H;
      stem(50, 112, 50, top, 3, 2.4, '#2F7A3A');
      var lv = [[0.25, -2.6], [0.42, -0.5], [0.6, -2.4], [0.75, -0.7]];
      lv.forEach(function (q, k) { if (i === 1 && k > 1 + p * 3) return; var y = 112 - H * q[0], len = 13; add(leaf(50, y, q[1], len, 4.2), 'url(#gYaprak)'); add(rib(50, y, q[1], len), 'none', 0.5, '#1F5E2C', 0.5); add(leaf(50 + Math.cos(q[1]) * len * 0.55, y + Math.sin(q[1]) * len * 0.55, q[1] - 0.7, 6, 2.2), 'url(#gYaprak)'); add(leaf(50 + Math.cos(q[1]) * len * 0.55, y + Math.sin(q[1]) * len * 0.55, q[1] + 0.7, 6, 2.2), 'url(#gYaprak)'); });
      for (var k = 0; k < 4; k++) { var ty = 112 - H * (0.2 + k * 0.17); add('M50 ' + f(ty) + 'l' + (k % 2 ? 2.2 : -2.2) + ' -1.4l' + (k % 2 ? -1.2 : 1.2) + ' 2.4Z', '#5E2A1E'); }
      if (i === 1) {
        var bs = lerp(3.4, 7, ease(p));
        add(leaf(50, top + 2, -1.57, bs * 2.3, bs * 0.95), 'url(#gGonca)');
        add(leaf(50, top + 2.5, -2.2, bs * 1.7, bs * 0.5), 'url(#gYaprak)'); add(leaf(50, top + 2.5, -0.95, bs * 1.7, bs * 0.5), 'url(#gYaprak)');
      } else {
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
    var th = i === 0 ? lerp(16, 34, ease(p)) : i === 1 ? lerp(34, 40, ease(p)) : lerp(40, 46, ease(p)), tw = i === 0 ? 1.6 : lerp(2.4, 2.9, i === 1 ? p * 0.5 : 0.5 + p * 0.5);
    trunk(50, 112, th, tw, tw * 0.5, 1, 'url(#gGovdeKoyu)');
    var bs = i === 1 ? lerp(0.8, 0.92, ease(p)) : i === 2 ? lerp(0.92, 1, ease(p)) : 1;
    var br = i === 0 ? [[-8, 12], [7, 10]] : [[-16, 20], [-8, 26], [6, 27], [16, 18], [-2, 30]].map(function (q) { return [q[0] * bs, q[1] * bs]; });
    br.forEach(function (q) { branch(50, 112 - th * 0.75, 50 + q[0], 112 - th - q[1] * 0.5, i === 0 ? 1 : 1.6, '#4A2F22'); });
    if (i === 0) { br.forEach(function (q) { add(leaf(50 + q[0], 112 - th - q[1] * 0.5, -1.2, 5, 1.8), 'url(#gYaprakGenc)'); }); }
    else {
      var nfl = i === 1 ? 26 : 44;
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
    var prev = Math.max(0, i - 1);
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
var BITKI_EK = {
  karahindiba: ['Karahindiba öbeği', 'Karahindiba çayırı', 'Karahindiba tarlası'], papatya: ['Papatya demeti', 'Papatya çayırı', 'Papatya tarlası'],
  menekse: ['Menekşe tutamı', 'Menekşe yastığı', 'Menekşe tarhı'], reyhan: ['Reyhan demeti', 'Reyhan sırası', 'Reyhan bahçesi'], lale: ['Lale demeti', 'Lale tarhı', 'Lale bahçesi'],
  gelincik: ['Gelincik öbeği', 'Gelincik tarlası', 'Kızıl tarla'], karanfil: ['Karanfil demeti', 'Karanfil tarhı', 'Karanfil bahçesi'], sumbul: ['Sümbül demeti', 'Sümbül tarhı', 'Sümbül bahçesi'],
  kardelen: ['Kardelen öbeği', 'Kardelen yamacı', 'Kardelen vadisi'], lavanta: ['Lavanta tutamı', 'Lavanta tarhı', 'Lavanta tarlası'], nergis: ['Nergis demeti', 'Nergis tarhı', 'Nergis bahçesi'],
  gul: ['Gül fidanı', 'Gül çalısı', 'Ulu gül çalısı'], aycicegi: ['Ayçiçeği sırası', 'Ayçiçeği tarhı', 'Ayçiçeği tarlası'], zambak: ['Zambak demeti', 'Zambak tarhı', 'Zambak bahçesi'],
  kina: ['Kına çalısı', 'Kına çiti', 'Kına bahçesi'], corekotu: ['Çörek otu öbeği', 'Çörek otu tarhı', 'Çörek otu tarlası'], yasemin: ['Yasemin çalısı', 'Yasemin çiti', 'Yasemin bahçesi'],
  sakayik: ['Şakayık çalısı', 'Şakayık tarhı', 'Şakayık bahçesi'], frezya: ['Frezya demeti', 'Frezya tarhı', 'Frezya bahçesi'], ortanca: ['Ortanca çalısı', 'Ortanca çiti', 'Ortanca bahçesi'],
  nilufer: ['Nilüfer öbeği', 'Nilüfer gölcüğü', 'Nilüfer gölü'], kamelya: ['Kamelya çalısı', 'Kamelya çiti', 'Kamelya bahçesi'], begonvil: ['Gür begonvil', 'Begonvil tacı', 'Ulu begonvil'],
  terslale: ['Ters lale öbeği', 'Ters lale yamacı'], yesim: ['Gür yeşim çardağı', 'Ulu yeşim çardağı'], rafflesia: ['Dev rafflesia'], orkide: [],
  cam: ['Olgun çam', 'Ulu çam', 'Asırlık çam'], kavak: ['Olgun kavak', 'Ulu kavak', 'Asırlık kavak'], servi: ['Olgun servi', 'Ulu servi'], badem: ['Olgun badem', 'Ulu badem'],
  elma: ['Olgun elma', 'Ulu elma'], incir: ['Olgun incir', 'Ulu incir'], asma: ['Olgun asma', 'Asırlık asma'], turunc: ['Olgun turunç', 'Ulu turunç'], ihlamur: ['Olgun ıhlamur', 'Ulu ıhlamur'],
  nar: ['Olgun nar', 'Ulu nar'], erguvan: ['Olgun erguvan', 'Ulu erguvan'], misvak: ['Olgun misvak', 'Ulu misvak'], akcaagac: ['Olgun akçaağaç', 'Ulu akçaağaç'], zeytin: ['Olgun zeytin', 'Asırlık zeytin'],
  sogut: ['Olgun söğüt', 'Ulu söğüt'], sedir: ['Olgun sedir', 'Asırlık sedir'], manolya: ['Olgun manolya', 'Ulu manolya'], sakura: ['Olgun sakura', 'Ulu sakura'], sidre: ['Ulu sidre'],
  jakaranda: ['Ulu jakaranda'], hurma: ['Ulu hurma'], cinar: [], sigla: ['Ulu sığla'], baobab: ['Asırlık baobab'], ejder: [], okaliptus: [], sekoya: []
};
BITKI_SIRA.forEach(function (t) {
  var b = BITKI[t], ek = BITKI_EK[t] || [], n = ek.length, span = (BITKI_MAX - b.dk) / Math.max(1, n);
  b.temel = b.evre.slice();
  b.evre = b.temel.concat(ek.map(function (ad, k) { return [ad, Math.round(b.dk + span * k), k === n - 1 ? BITKI_MAX : Math.round(b.dk + span * (k + 1))]; }));
});
var BITKI_BUYU = { nilufer: 1, begonvil: 1, yesim: 1, rafflesia: 1 }; // kopyalanmaz, ağaç gibi büyür
function buyuyen(tur) { return BITKI[tur].tur === 'Ağaç' || !!BITKI_BUYU[tur]; }
function bitkiUst(S) { var m = 112; S.forEach(function (q) { var tok = q.d.match(/[MLQCZlhv]|-?\d*\.?\d+/g) || [], cmd = '', k = 0; tok.forEach(function (t) { if (/[A-Za-z]/.test(t)) { cmd = t; k = 0; return; } if ('MLQC'.indexOf(cmd) >= 0 && k % 2 === 1) m = Math.min(m, +t); k++; }); }); return m; }
var CLONE = [[0, 0, 1], [-17, -5, .86], [17, -5, .86], [-9, -11, .8], [9, -11, .8], [-28, 0, .78], [28, 0, .78], [-21, -15, .72], [21, -15, .72]];
function bitkiAdet(tur, dk) { var b = BITKI[tur]; if (buyuyen(tur) || dk <= b.dk) return 1; var e = Math.min(1, (dk - b.dk) / (BITKI_MAX - b.dk)); return e < 1 / 3 ? 1 + 6 * e : e < 2 / 3 ? 3 + 9 * (e - 1 / 3) : 6 + 9 * (e - 2 / 3); }
function bitkiOzet(tur, dk) {
  var b = BITKI[tur], E = bitkiEvre(tur, Math.max(0, Math.min(dk, BITKI_MAX) - 0.001));
  if (dk < b.dk) return E.ad + ' · ' + b.ad.toLowerCase() + ' ' + b.dk + ' dk’da tam formuna erer';
  if (buyuyen(tur)) return E.ad + (dk >= BITKI_MAX ? ' · en büyük hâli' : '');
  var n = Math.floor(bitkiAdet(tur, dk) + 0.001); return E.ad + ' · ' + n + ' ' + (n === 1 ? 'çiçek' : 'öbek');
}
function yolDonustur(d, s, dx, dy) {
  var tok = d.match(/[MLQCTZHVmlqctzhv]|-?\d*\.?\d+(?:e-?\d+)?/g) || [], out = [], cmd = '', k = 0;
  function X(x) { return Math.round((50 + (x - 50) * s + dx) * 10) / 10; } function Y(y) { return Math.round((112 + (y - 112) * s + dy) * 10) / 10; } function R(v) { return Math.round(v * s * 100) / 100; }
  for (var i = 0; i < tok.length; i++) {
    var t = tok[i];
    if (/[A-Za-z]/.test(t)) { cmd = t; out.push(t); k = 0; continue; }
    var v = Number(t);
    if (cmd === 'M' || cmd === 'L' || cmd === 'Q' || cmd === 'C' || cmd === 'T') { out.push(k % 2 === 0 ? X(v) : Y(v)); }
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
  if (buyuyen(tur)) { var o2 = {}; for (var k in opt) o2[k] = opt[k]; o2.bolluk = e; var T = bitkiTemel(tur, b.dk, seed, o2), sc = 1 + 0.32 * e, ust = bitkiUst(T); if (ust < 112) sc = Math.max(1, Math.min(sc, 109 / (112 - ust))); return bitkiDonustur(T, sc, 0, 0); }
  var n = bitkiAdet(tur, dk), full = Math.floor(n), frac = n - full, out = [], lod = (opt.lod || 1) * (n > 3 ? 0.6 : 0.85);
  var w = 14 + Math.min(9, Math.ceil(n)) * 3.2;
  out.push({ d: elYol(50, 112, w, w * 0.22, function (v) { return Math.round(v * 10) / 10; }), f: 'url(#gGolge)', s: 'none', w: 0, o: 1 });
  var idx = []; for (var j = 0; j < Math.min(9, Math.ceil(n)); j++) idx.push(j);
  idx.sort(function (a, c) { return CLONE[a][1] - CLONE[c][1]; });
  idx.forEach(function (j) {
    var c = CLONE[j], grow = j < full ? 1 : frac; if (grow <= 0.02) return;
    var sh = bitkiTemel(tur, b.dk, (seed || 7) + j * 13, { lod: lod }).filter(function (q) { return q.f !== 'url(#gGolge)'; });
    out = out.concat(bitkiDonustur(sh, c[2] * (0.35 + 0.65 * grow), c[0], c[1] * 0.6, j === 0 ? 1 : 0.98));
  });
  return out;
}
/* Uygulama köprüsü: JavaScriptCore'dan tek çağrıyla tür listesi ve çizim verisi */
function bitkiKatalog() { return BITKI_SIRA.map(function (t) { var b = BITKI[t]; return { id: t, ad: b.ad, tur: b.tur, dk: b.dk, renk: b.renk, sinif: b.sinif, fiyat: b.fiyat, not: b.not, evre: b.evre, temel: b.temel }; }); }
function bitkiJSON(tur, dk, seed, lod) { return JSON.stringify(bitkiCiz(tur, dk, seed, { lod: lod || 1 })); }

function rnd(a) { return function () { a |= 0; a = a + 0x6D2B79F5 | 0; var t = Math.imul(a ^ a >>> 15, 1 | a); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; }; }
