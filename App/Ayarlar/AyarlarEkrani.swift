import CoreLocation
import SwiftUI
import UniformTypeIdentifiers

struct AyarlarEkrani: View {
    @Environment(Depo.self) private var depo
    @Environment(VakitServisi.self) private var vakit
    @Environment(Yonlendirici.self) private var yon
    @Environment(\.palet) private var palet
    @State private var ezanDurum = 0
    @State private var muezzinAc = false
    @State private var mesaj: String?
    @State private var konum = KonumAlici()
    /// Tek dosya seçici: ezan kaydı, yedek klasörü ya da geri yüklenecek yedek.
    @State private var secici: Secici?
    @State private var disaAktar = false
    @State private var disaBelge: YedekBelgesi?
    @State private var geriYuklenecek: Kayit?
    @State private var okumaAyarlari = false
    @State private var kayitBoyutu: Int64 = 0
    @State private var kayitSilSor = false

    enum Secici: Identifiable {
        case ezan(EzanTuru), yedekKlasoru, geriYukle
        var id: String {
            switch self {
            case .ezan(let t): "ezan-" + t.rawValue
            case .yedekKlasoru: "klasor"
            case .geriYukle: "geri"
            }
        }
        var turler: [UTType] {
            switch self {
            case .ezan: [.audio]
            case .yedekKlasoru: [.folder]
            case .geriYukle: [.json]
            }
        }
    }

    struct Ton: Identifiable { let id: String; let ad: String }
    static let tonlar: [Ton] = [
        Ton(id: "bildirim_can", ad: "Çan"), Ton(id: "bildirim_kristal", ad: "Kristal"), Ton(id: "bildirim_damla", ad: "Damla"),
        Ton(id: "bildirim_sabah", ad: "Sabah"), Ton(id: "bildirim_huzur", ad: "Huzur"), Ton(id: "bildirim_esinti", ad: "Esinti"),
    ]

    var body: some View {
        ustKisim
        .fileExporter(isPresented: $disaAktar, document: disaBelge, contentType: .json,
                      defaultFilename: Yedek.dosyaAdi()) { sonuc in
            if case .success = sonuc { mesaj = "Yedek kaydedildi." }
        }
        .confirmationDialog("Yedek geri yüklensin mi?", isPresented: Binding(get: { geriYuklenecek != nil }, set: { if !$0 { geriYuklenecek = nil } }), titleVisibility: .visible) {
            Button("Geri yükle", role: .destructive) {
                if let k = geriYuklenecek { Yedek.geriYukle(k, depo: depo); mesaj = "Yedek geri yüklendi." }
                geriYuklenecek = nil
            }
            Button("Vazgeç", role: .cancel) { geriYuklenecek = nil }
        } message: {
            if let k = geriYuklenecek {
                Text("Telefondaki veriler yedektekiyle değişecek: \(k.oturumlar.filter { $0.durum == .tamam }.count) fidan, \(k.zikirler.count) zikir kaydı, \(k.favoriler.count) kayıt. Şimdiki veriler önce Yedekler klasörüne ayrıca yazılır.")
            }
        }
        .confirmationDialog("Tilavet kayıtları silinsin mi?", isPresented: $kayitSilSor, titleVisibility: .visible) {
            Button("Sil", role: .destructive) {
                TilavetMotoru.ortak.kayitlariSil()
                kayitBoyutu = 0
            }
        } message: {
            Text("İndirilen bütün âyet kayıtları telefondan silinir. Dinleyince yeniden iner.")
        }
        .sheet(isPresented: $okumaAyarlari) { OkumaAyarlariSayfasi().presentationDetents([.medium, .large]) }
        .task { kayitBoyutu = await Task.detached { TilavetMotoru.boyut() }.value }
        .alert(mesaj ?? "", isPresented: Binding(get: { mesaj != nil }, set: { if !$0 { mesaj = nil } })) {
            Button("Tamam", role: .cancel) {}
        }
    }

    private var ustKisim: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                BolumBasligi(metin: "Tema").padding(.horizontal, 6)
                temalar
                vakitGruplari
                ezanGrubu
                odakGruplari
                tilavetGrubu
                altGruplar
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .navigationTitle("Ayarlar")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $muezzinAc) { MuezzinSecici().presentationDetents([.large]) }
        .onAppear { if yon.muezzinAc { yon.muezzinAc = false; muezzinAc = true } }
        .onChange(of: depo.ayarlar.ezan) { _, yeni in
            if yeni == .muezzin { Task { await EzanCalar.ortak.gerekenleriIndir(depo.ayarlar); await Bildirim.vakitleriKur(vakit, depo.ayarlar) } }
        }
        .fileImporter(isPresented: Binding(get: { secici != nil }, set: { if !$0 { secici = nil } }), allowedContentTypes: secici?.turler ?? [.data]) { dosyaSecildi($0) }
    }

    private func dosyaSecildi(_ sonuc: Result<URL, Error>) {
            guard let s = secici else { return }
            secici = nil
            guard case .success(let url) = sonuc else { return }
            switch s {
            case .ezan(let tur):
                guard let ad = tur.kayitAdi else { return }
                do {
                    try EzanKaydi.ice(url, ad: ad)
                    ezanDurum += 1
                    mesaj = "\(tur.ad) kaydı eklendi."
                    Task { await Bildirim.vakitleriKur(vakit, depo.ayarlar) }
                } catch {
                    mesaj = "Bu dosya okunamadı. MP3, M4A ya da WAV dene."
                }
            case .yedekKlasoru:
                mesaj = Yedek.klasorSec(url, depo: depo) ?? "Yedek klasörü “\(url.lastPathComponent)” oldu; ilk yedek yazıldı."
            case .geriYukle:
                let erisim = url.startAccessingSecurityScopedResource()
                defer { if erisim { url.stopAccessingSecurityScopedResource() } }
                do {
                    geriYuklenecek = try Yedek.coz(try Data(contentsOf: url))
                } catch {
                    mesaj = (error as? LocalizedError)?.errorDescription ?? "Dosya okunamadı."
                }
            }
        }

    /// Tema ızgarası: her kart temanın zemini üstünde Besmele'den bir parça gösterir.
    private var temalar: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
            ForEach(Tema.allCases) { t in
                let on = depo.ayarlar.tema == t
                let p = t.palet(.bugun)
                Button {
                    withAnimation(.easeInOut(duration: 0.35)) { depo.degistir { $0.ayarlar.tema = t } }
                    Dokunsal.hafif(0.6)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        VStack(alignment: .leading, spacing: 2) {
                            Spacer(minLength: 0)
                            Text("ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ").font(.arapca(15)).foregroundStyle(p.vurgu).lineLimit(1).minimumScaleFactor(0.6)
                            Text("Rahman ve Rahim").font(.system(size: 12, weight: .medium, design: .serif)).foregroundStyle(p.metin).lineLimit(1).minimumScaleFactor(0.7)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
                        .background(SahneZemini(palet: p).clipShape(.rect(cornerRadius: 16)))
                        .overlay(alignment: .topTrailing) {
                            if on {
                                Image(systemName: "checkmark.circle.fill").font(.system(size: 18)).foregroundStyle(.white, palet.vurgu).padding(6)
                            }
                        }
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(on ? palet.vurgu : Color.white.opacity(0.18), lineWidth: on ? 2.5 : 1))
                        Text(t.ad).font(.kalin(12.5)).foregroundStyle(on ? palet.vurgu : Color.primary).padding(.leading, 4)
                    }
                    .padding(6)
                    .background(RoundedRectangle(cornerRadius: 20).fill(on ? palet.vurgu.opacity(0.12) : Color.clear))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(t.ad) teması")
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(8)
        .camYuzey(palet.cam(), in: .rect(cornerRadius: 26))
    }

    @ViewBuilder private var vakitGruplari: some View {
        grup("Vakitler") {
            secimSatiri("Vakitler nereye göre?", alt: depo.ayarlar.konumKipi == .bursa ? "Diyanet'in ilçe takvimi; internet varken kendiliğinden yenilenir." : "Bulunduğun yere göre güneşten hesaplanır; birkaç dakika sapabilir.") {
                Picker("", selection: depo.ayar(\.konumKipi)) {
                    Text("Diyanet").tag(KonumKipi.bursa)
                    Text("Konumum").tag(KonumKipi.cihaz)
                }
                .pickerStyle(.segmented)
                .frame(width: 170)
            }
            if depo.ayarlar.konumKipi == .bursa {
                Ayrac()
                NavigationLink(value: Rota.ilce) {
                    HStack {
                        Label("İlçe", systemImage: "mappin.and.ellipse").font(.system(size: 15, weight: .bold))
                        Spacer()
                        Text(depo.ayarlar.ilceAdi).font(.system(size: 14, weight: .semibold)).foregroundStyle(.secondary)
                        Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            if depo.ayarlar.konumKipi == .cihaz {
                Ayrac()
                Button {
                    konum.iste { e, b in
                        depo.degistir { $0.ayarlar.enlem = e; $0.ayarlar.boylam = b; $0.ayarlar.konumAdi = "Bulunduğun yer" }
                        mesaj = "Konum güncellendi."
                    }
                } label: {
                    HStack {
                        Label("Konumu güncelle", systemImage: "location").font(.system(size: 15, weight: .bold))
                        Spacer()
                        Text(String(format: "%.3f, %.3f", depo.ayarlar.enlem, depo.ayarlar.boylam)).font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        grup("Hatırlatmalar") {
            ForEach(0..<6, id: \.self) { i in
                if i > 0 { Ayrac() }
                anahtar(VakitAdi.adlar[i], alt: i == 1 ? "Güneş doğuşu; sabah namazının son vakti" : nil,
                        Binding(get: { depo.ayarlar.vakitBildirim[i] }, set: { v in depo.degistir { $0.ayarlar.vakitBildirim[i] = v } }))
            }
            Ayrac()
            secimSatiri("Önceden hatırlat", alt: nil) {
                Picker("", selection: depo.ayar(\.onceDakika)) {
                    Text("Vaktinde").tag(0)
                    ForEach([5, 10, 15, 30, 45], id: \.self) { Text("\($0) dk önce").tag($0) }
                }
                .pickerStyle(.menu)
            }
            Ayrac()
            anahtar("Seri hatırlatması", alt: "Bugün fidan dikmediysen seçtiğin saatte nazikçe hatırlatır; namaz vaktine denk gelirse kayar.", depo.ayar(\.seriHatirlatma))
            if depo.ayarlar.seriHatirlatma {
                DatePicker("Saat", selection: Binding(get: {
                    Calendar.current.startOfDay(for: .now).addingTimeInterval(Double(depo.ayarlar.seriHatirlatmaDk) * 60)
                }, set: { t in
                    let c = Calendar.current.dateComponents([.hour, .minute], from: t)
                    depo.degistir { $0.ayarlar.seriHatirlatmaDk = (c.hour ?? 20) * 60 + (c.minute ?? 30) }
                }), displayedComponents: .hourAndMinute)
                .font(.system(size: 15, weight: .bold))
            }
            Ayrac()
            anahtar("Cuma özeti", alt: "Cuma sabahı geçen yedi günün odak, namaz ve zikir özeti.", depo.ayar(\.cumaOzeti))
        }
    }

    @ViewBuilder private var odakGruplari: some View {
        grup("Odak") {
            anahtar("Uygulamadan çıkınca bitki kurusun", alt: "Ekranı kilitlemek serbest; başka uygulamada 10 sn'den uzun kalırsan bitki kurur.", depo.ayar(\.katiMod))
            Ayrac()
            secimSatiri("Günlük hedef", alt: "Bugün kartındaki çubuk") {
                Stepper("\(depo.ayarlar.gunlukHedef) dk", value: depo.ayar(\.gunlukHedef), in: 10...600, step: 10)
                    .font(.system(size: 14, weight: .bold))
                    .fixedSize()
            }
            Ayrac()
            NavigationLink(value: Rota.konular) {
                HStack {
                    Text("Odak konuları").font(.system(size: 15, weight: .bold))
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        grup("Sesler") {
            anahtar("Odak süresince çal", alt: "Son seçtiğin sesler odak başlayınca çalar, bitince durur.", depo.ayar(\.sesOdakta))
            Ayrac()
            anahtar("Sonda sesi yavaşça azalt", alt: nil, depo.ayar(\.sesSondaAzalt))
            Ayrac()
            anahtar("Ezan vaktinde sustur", alt: nil, depo.ayar(\.ezandaSustur))
            Ayrac()
            anahtar("Kur’an dinlerken kıs", alt: "Tilavet ya da başka uygulama ses çalınca odak sesleri kısılır.", depo.ayar(\.kuranDinlerkenKis))
            Ayrac()
            anahtar("Kilit ekranında göster", alt: "Odak seslerini kilit ekranından başlatıp durdurursun. Açıkken çalan müzik durur; kapalıyken müzikle birlikte çalar.", depo.ayar(\.sesKilitEkrani))
        }
    }

    @ViewBuilder private var altGruplar: some View {
        grup("Tesbih") {
            anahtar("Titreşim", alt: nil, depo.ayar(\.tesbihTitresim))
            Ayrac()
            anahtar("Kehribar sesi", alt: nil, depo.ayar(\.tesbihSes))
            if depo.ayarlar.tesbihSes {
                HStack {
                    Image(systemName: "speaker.fill").foregroundStyle(.secondary)
                    Slider(value: depo.ayar(\.tesbihSesDuzeyi), in: 0.05...1, onEditingChanged: { suruyor in
                        if !suruyor { Efekt.cal("tesbih_tik", duzey: Float(depo.ayarlar.tesbihSesDuzeyi)) }
                    })
                    Image(systemName: "speaker.wave.3.fill").foregroundStyle(.secondary)
                }
            }
        }
        grup("Okuma") {
            Button { okumaAyarlari = true } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Okuma ayarları").font(.system(size: 15, weight: .bold))
                        Text("\(depo.ayarlar.okumaTemasi.ad) · \(Int(depo.ayarlar.okumaPunto)) pt · sıcak ışık %\(Int(depo.ayarlar.sicakIsik * 100))")
                            .font(.system(size: 12.5, weight: .medium)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        grup("Yedekleme") {
            VStack(alignment: .leading, spacing: 4) {
                Text(depo.kayit.sonYedek.map { "Son yedek: \(Tarihler.gunAy.string(from: $0)) \(Tarihler.saat.string(from: $0))" } ?? "Henüz yedek yok")
                    .font(.system(size: 15, weight: .bold))
                Text(Yedek.klasorAdi(depo.kayit.yedekYeri).map { "Her gün “\($0)” klasörüne ve telefondaki Yedekler klasörüne yazılır." }
                     ?? "Her gün telefondaki Yedekler klasörüne yazılır. Uygulama silinirse bu klasör de silinir; iCloud Drive'da bir klasör seç.")
                    .font(.system(size: 12.5, weight: .medium)).foregroundStyle(.secondary)
            }
            Ayrac()
            Button { secici = .yedekKlasoru } label: {
                Label(depo.kayit.yedekYeri == nil ? "Yedek klasörü seç (iCloud Drive)" : "Yedek klasörünü değiştir", systemImage: "folder.badge.plus")
                    .font(.system(size: 15, weight: .bold)).frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            Ayrac()
            HStack(spacing: 10) {
                Button { mesaj = Yedek.gunlukYedek(depo, zorla: true) ?? "Yedek alındı." } label: {
                    Label("Şimdi yedekle", systemImage: "arrow.clockwise.icloud").font(.kalin(13.5)).frame(maxWidth: .infinity, minHeight: 28)
                }
                .buttonStyle(.glass)
                Button {
                    disaBelge = Yedek.veri(depo.kayit).map { YedekBelgesi(veri: $0) }
                    disaAktar = true
                } label: {
                    Label("Dışa aktar", systemImage: "square.and.arrow.up").font(.kalin(13.5)).frame(maxWidth: .infinity, minHeight: 28)
                }
                .buttonStyle(.glass)
            }
            Button { secici = .geriYukle } label: {
                Label("Yedekten geri yükle", systemImage: "arrow.uturn.backward.circle").font(.kalin(13.5)).frame(maxWidth: .infinity, minHeight: 28)
            }
            .buttonStyle(.glass)
            Text("Yedekte bahçen, oturumların, namaz ve kaza kayıtların, zikirlerin, kaydettiklerin, karışımların ve ayarların vardır. PDF kitaplar ve tilavet kayıtları yedeğe girmez.")
                .font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
        }
        grup("Kaynaklar") {
            Kaynak(ad: "Hadisler", deger: "Sahîh-i Buhârî (Türkçe tercüme; her metin numarasıyla karşılaştırıldı)")
            Ayrac()
            Kaynak(ad: "Âyet mealleri", deger: "Diyanet İşleri Başkanlığı meali")
            Ayrac()
            Kaynak(ad: "Vakitler", deger: "Diyanet takvimi (ezanvakti.emushaf.net)")
            Ayrac()
            Kaynak(ad: "Odak sesleri", deger: "Moodist ve Blanket kayıtları (CC0 / Pixabay lisansı), 41 döngü")
            Ayrac()
            Kaynak(ad: "Arapça yazı", deger: "Amiri yazı tipi (SIL Open Font License)")
            Ayrac()
            Kaynak(ad: "Kur'an metni ve tilavet", deger: "Kral Fahd Mushafı (fawazahmed0/quran-api); tilavet: EveryAyah ve mp3quran arşivleri (âyet zamanlarıyla)")
            Ayrac()
            Kaynak(ad: "Gizlilik", deger: "Hesap, sunucu, reklam ve analitik yok. Verilerin yalnız bu telefonda ve seçtiğin yedek klasöründe durur; internete yalnız vakit takvimi, tilavet ve ezan kayıtları için çıkılır.")
            Ayrac()
            Kaynak(ad: "Ezan kayıtları", deger: "Athan-MP3 derlemesi; seçilince indirilir, uygulamaya gömülmez")
            Ayrac()
            Kaynak(ad: "Sürüm", deger: (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") + " (" + (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "") + ")")
        }
    }

    private var ezanGrubu: some View {
        grup("Ezan ve bildirim sesi") {
            secimSatiri("Bildirim sesi", alt: nil) {
                Picker("", selection: depo.ayar(\.ezan)) {
                    ForEach(EzanTuru.allCases) { Text($0.ad).tag($0) }
                }
                .pickerStyle(.menu)
            }
            if depo.ayarlar.ezan == .muezzin {
                let a = depo.ayarlar
                let m = Muezzin.bul(a.muezzin)
                Ayrac()
                Button { muezzinAc = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "speaker.wave.2.circle.fill").font(.system(size: 26)).foregroundStyle(Color(hex: "#1FB25A"))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(a.vakitMuezzin.count == 6 ? "Her vakte ayrı müezzin" : m.ad).font(.kalin(15))
                            Text(EzanCalar.hazir(m) || a.vakitMuezzin.count == 6 ? "Dinle, değiştir ya da vakitlere ayır" : "Kayıt inmedi; dokun ve seç")
                                .font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            if let kayit = depo.ayarlar.ezan.kayitAdi {
                let hazir = EzanKaydi.mevcut(kayit) && ezanDurum >= 0
                Ayrac()
                HStack {
                    Label(hazir ? "Kayıt hazır" : "Kayıt yok", systemImage: hazir ? "checkmark.circle.fill" : "exclamationmark.circle")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(hazir ? Color(hex: "#34C759") : Color.orange)
                    Spacer()
                    Button(hazir ? "Değiştir" : "Ses dosyası ekle") { secici = .ezan(depo.ayarlar.ezan) }.font(.system(size: 14, weight: .bold))
                    if hazir {
                        Button("Sil", role: .destructive) { EzanKaydi.sil(kayit); ezanDurum += 1 }.font(.system(size: 14, weight: .bold))
                    }
                }
            }
            if depo.ayarlar.ezan != .sessiz {
                Ayrac()
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(AyarlarEkrani.tonlar) { t in
                        let on = depo.ayarlar.bildirimTonu == t.id
                        Button {
                            depo.degistir { $0.ayarlar.bildirimTonu = t.id }
                            Efekt.cal(t.id, duzey: 0.9)
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: on ? "speaker.wave.2.fill" : "play.fill").font(.system(size: 11, weight: .bold))
                                Text(t.ad).font(.kalin(13))
                            }
                            .foregroundStyle(on ? Color.white : Color.primary)
                            .frame(maxWidth: .infinity, minHeight: 38)
                            .background(Capsule().fill(on ? Color(hex: "#1FB25A") : Color.primary.opacity(0.07)))
                            .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(on ? .isSelected : [])
                    }
                }
            }
            Ayrac()
            Button {
                Task { mesaj = await Bildirim.dene(depo.ayarlar) }
            } label: {
                Label("Deneme bildirimi gönder", systemImage: "bell.badge").font(.kalin(14)).frame(maxWidth: .infinity, minHeight: 30)
            }
            .buttonStyle(.glass)
            Text("Tona dokununca telefon sessizde de duyulur. Bildirim sesini ise iOS, telefon sessiz kipteyken çalmaz. iOS bildirim sesini 30 saniyeyle sınırlar: ezanın ilk 29 saniyesi çalar; uygulama açıksa ezanın tamamı okunur. Makamlı ezan için kendi kaydını da ekleyebilirsin.")
                .font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
        }
    }

    private var tilavetGrubu: some View {
        grup("Tilavet") {
            secimSatiri("Hafız", alt: Hafiz.bul(depo.ayarlar.tilavetHafiz).unvan) {
                Picker("", selection: depo.ayar(\.tilavetHafiz)) {
                    ForEach(Hafiz.Grup.allCases, id: \.self) { g in
                        Section(g.ad) { ForEach(Hafiz.grup(g)) { Text($0.ad).tag($0.id) } }
                    }
                }
                .pickerStyle(.menu)
            }
            Ayrac()
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Telefondaki kayıtlar").font(.system(size: 15, weight: .bold))
                    Text(ByteCountFormatter.string(fromByteCount: kayitBoyutu, countStyle: .file)).font(.system(size: 12.5, weight: .medium)).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Sil", role: .destructive) { kayitSilSor = true }
                    .font(.system(size: 14, weight: .bold))
                    .disabled(kayitBoyutu == 0)
            }
            Text("Âyet kayıtları dinledikçe iner ve internetsiz yeniden çalar. Silinse de gerektiğinde yeniden iner.")
                .font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
        }
    }

    private func grup<I: View>(_ baslik: String, @ViewBuilder _ icerik: () -> I) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            BolumBasligi(metin: baslik).padding(.horizontal, 6).padding(.top, 8)
            VStack(alignment: .leading, spacing: 10) { icerik() }
                .camKart(kose: 24, ic: 14)
        }
    }

    private func anahtar(_ ad: String, alt: String?, _ deger: Binding<Bool>) -> some View {
        Toggle(isOn: deger) {
            VStack(alignment: .leading, spacing: 2) {
                Text(ad).font(.system(size: 15, weight: .bold))
                if let alt { Text(alt).font(.system(size: 12.5, weight: .medium)).foregroundStyle(.secondary) }
            }
        }
        .tint(Color(hex: "#34C759"))
    }

    private func secimSatiri<S: View>(_ ad: String, alt: String?, @ViewBuilder _ secim: () -> S) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(ad).font(.system(size: 15, weight: .bold))
                if let alt { Text(alt).font(.system(size: 12.5, weight: .medium)).foregroundStyle(.secondary) }
            }
            Spacer(minLength: 4)
            secim()
        }
    }
}

/// Grup içindeki ince ayraç.
private struct Ayrac: View {
    var body: some View { Rectangle().fill(Color.primary.opacity(0.08)).frame(height: 0.5) }
}

private struct Kaynak: View {
    let ad: String
    let deger: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(ad).font(.system(size: 14, weight: .bold))
            Text(deger).font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
        }
    }
}

/// Tek seferlik konum (vakit hesabı için).
@Observable
final class KonumAlici: NSObject, CLLocationManagerDelegate {
    private let y = CLLocationManager()
    @ObservationIgnored private var bitince: ((Double, Double) -> Void)?

    override init() {
        super.init()
        y.delegate = self
        y.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func iste(_ b: @escaping (Double, Double) -> Void) {
        bitince = b
        if y.authorizationStatus == .notDetermined { y.requestWhenInUseAuthorization() }
        y.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let k = locations.last else { return }
        bitince?(k.coordinate.latitude, k.coordinate.longitude)
        bitince = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if bitince != nil, manager.authorizationStatus == .authorizedWhenInUse { manager.requestLocation() }
    }
}
