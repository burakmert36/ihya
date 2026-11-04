import PDFKit
import SwiftUI
import UniformTypeIdentifiers

/// Kullanıcının kendi PDF kitapları. Dosyalar Documents/Kitaplar altında, yalnız bu telefonda durur.
enum KitapDeposu {
    static var klasor: URL {
        let u = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Kitaplar", isDirectory: true)
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }

    static func url(_ k: Kitap) -> URL { klasor.appendingPathComponent(k.dosya) }

    static func bilgi(_ url: URL) -> (ad: String, toplam: Int) {
        let belge = PDFDocument(url: url)
        let baslik = (belge?.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let ad = (baslik?.isEmpty == false ? baslik! : url.deletingPathExtension().lastPathComponent)
        return (ad, belge?.pageCount ?? 0)
    }

    /// Seçilen PDF'i kopyalar; aynı adlı dosya varsa ada numara ekler.
    static func ice(_ kaynak: URL) throws -> Kitap {
        let erisim = kaynak.startAccessingSecurityScopedResource()
        defer { if erisim { kaynak.stopAccessingSecurityScopedResource() } }
        guard PDFDocument(url: kaynak) != nil else { throw CocoaError(.fileReadCorruptFile) }
        var hedef = klasor.appendingPathComponent(kaynak.lastPathComponent)
        var n = 2
        while FileManager.default.fileExists(atPath: hedef.path) {
            hedef = klasor.appendingPathComponent("\(kaynak.deletingPathExtension().lastPathComponent) \(n).pdf")
            n += 1
        }
        try FileManager.default.copyItem(at: kaynak, to: hedef)
        let b = bilgi(hedef)
        return Kitap(ad: b.ad, dosya: hedef.lastPathComponent, toplam: b.toplam)
    }

    /// Dosyalar uygulamasıyla klasöre konmuş ama listede olmayan PDF'leri bulur.
    static func yeniler(_ bilinen: [Kitap]) -> [Kitap] {
        let adlar = Set(bilinen.map(\.dosya))
        let dosyalar = (try? FileManager.default.contentsOfDirectory(at: klasor, includingPropertiesForKeys: nil)) ?? []
        return dosyalar.filter { $0.pathExtension.lowercased() == "pdf" && !adlar.contains($0.lastPathComponent) }.map { u in
            let b = bilgi(u)
            return Kitap(ad: b.ad, dosya: u.lastPathComponent, toplam: b.toplam)
        }
    }

    static func sil(_ k: Kitap) {
        try? FileManager.default.removeItem(at: url(k))
        try? FileManager.default.removeItem(at: kapakDosyasi(k))
        kapaklar.removeObject(forKey: k.dosya as NSString)
    }

    // MARK: Kapak

    private static let kapaklar = NSCache<NSString, UIImage>()

    static func kapakDosyasi(_ k: Kitap) -> URL {
        let u = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("Kapaklar", isDirectory: true)
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u.appendingPathComponent(k.dosya + ".jpg")
    }

    /// İlk sayfanın küçük resmi (önbellekte saklanır).
    static func kapak(_ k: Kitap) async -> UIImage? {
        let anahtar = k.dosya as NSString
        if let r = kapaklar.object(forKey: anahtar) { return r }
        let url = url(k), dosya = kapakDosyasi(k)
        let r = await Task.detached(priority: .utility) { () -> UIImage? in
            if let d = try? Data(contentsOf: dosya), let i = UIImage(data: d) { return i }
            guard let p = PDFDocument(url: url)?.page(at: 0) else { return nil }
            let kutu = p.bounds(for: .mediaBox)
            let w: CGFloat = 360
            let i = p.thumbnail(of: CGSize(width: w, height: w * kutu.height / max(kutu.width, 1)), for: .mediaBox)
            if let j = i.jpegData(compressionQuality: 0.82) { try? j.write(to: dosya, options: .atomic) }
            return i
        }.value
        if let r { kapaklar.setObject(r, forKey: anahtar) }
        return r
    }

    /// Kitap sırtının rengi: kapağın ortalama rengi canlıysa o, değilse ada göre deri tonu.
    static func sirtRengi(_ k: Kitap, kapak: UIImage?) -> Color {
        let deriler = ["#7B2E2E", "#1F4E5F", "#2E5E3A", "#5B3A6E", "#8A5A2B", "#23395B", "#6B6B2E", "#6E2F4F"]
        let yedek = Color(hex: deriler[abs(k.ad.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }) % deriler.count])
        guard let cg = kapak?.cgImage else { return yedek }
        var piksel = [UInt8](repeating: 0, count: 4)
        guard let bag = CGContext(data: &piksel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return yedek }
        bag.interpolationQuality = .medium
        bag.draw(cg, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        let renk = UIColor(red: CGFloat(piksel[0]) / 255, green: CGFloat(piksel[1]) / 255, blue: CGFloat(piksel[2]) / 255, alpha: 1)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0
        renk.getHue(&h, saturation: &s, brightness: &b, alpha: nil)
        guard s > 0.22, b > 0.15 else { return yedek }
        return Color(hue: h, saturation: min(0.75, s * 1.1), brightness: min(0.62, max(0.3, b * 0.8)))
    }

    // MARK: Metin

    /// PDF sayfasının yazısını okunur hale getirir: satır sonu tirelerini birleştirir, satırları paragraflara toplar.
    static func duzenle(_ ham: String) -> String {
        let satirlar = ham.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
        let uzunluklar = satirlar.map(\.count).filter { $0 > 0 }.sorted()
        let tipik = uzunluklar.isEmpty ? 0 : uzunluklar[min(uzunluklar.count - 1, uzunluklar.count * 4 / 5)]
        var sonuc = "", paragraf = ""
        func bitir() {
            guard !paragraf.isEmpty else { return }
            if !sonuc.isEmpty { sonuc += "\n\n" }
            sonuc += paragraf
            paragraf = ""
        }
        for s in satirlar {
            if s.isEmpty { bitir(); continue }
            if paragraf.hasSuffix("-"), let ilk = s.first, ilk.isLowercase {
                paragraf.removeLast()
                paragraf += s
            } else {
                paragraf += paragraf.isEmpty ? s : " " + s
            }
            // Kısa kalan ve cümleyle biten satır paragrafı bitirir.
            if let son = s.last, ".!?:…\"”»".contains(son), Double(s.count) < Double(tipik) * 0.75 { bitir() }
        }
        bitir()
        return sonuc.replacingOccurrences(of: "[ \\t]{2,}", with: " ", options: .regularExpression)
    }
}

/// Kitaplık: kitaplar ahşap raflarda kapakları ya da sırtları görünecek biçimde dizilir.
struct KitaplarEkrani: View {
    @Environment(Depo.self) private var depo
    @Environment(Yonlendirici.self) private var yon
    @Environment(\.palet) private var palet
    @AppStorage("kitaplik.sirt") private var sirtlar = false
    /// 0 son okunan, 1 son eklenen, 2 ad
    @AppStorage("kitaplik.sira") private var sira = 0
    @State private var ice = false
    @State private var hata: String?
    @State private var silinecek: Kitap?
    @State private var adlandirilan: Kitap?
    @State private var yeniAd = ""
    @State private var arama = ""

    private var kitaplar: [Kitap] {
        var l = depo.kayit.kitaplar
        let q = arama.trimmingCharacters(in: .whitespaces)
        if !q.isEmpty { l = l.filter { $0.ad.range(of: q, options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "tr_TR")) != nil } }
        switch sira {
        case 1: l.sort { $0.eklenme > $1.eklenme }
        case 2: l.sort { $0.ad.localizedStandardCompare($1.ad) == .orderedAscending }
        default: l.sort { ($0.son ?? $0.eklenme) > ($1.son ?? $1.eklenme) }
        }
        return l
    }

    var body: some View {
        let l = kitaplar
        let okunan = l.filter { $0.basladi && !$0.tamam }
        let sirada = l.filter { !$0.basladi && !$0.tamam }
        let biten = l.filter(\.tamam)
        ScrollView {
            VStack(spacing: 22) {
                if depo.kayit.kitaplar.isEmpty {
                    BosRaf { ice = true }
                } else {
                    if arama.isEmpty, let k = okunan.first { DevamKarti(kitap: k) }
                    if !okunan.isEmpty { KitapRafi(baslik: "Okuyorum", kitaplar: okunan, sirtlar: sirtlar, eylem: eylem) }
                    if !sirada.isEmpty { KitapRafi(baslik: "Sırada", kitaplar: sirada, sirtlar: sirtlar, eylem: eylem) }
                    if !biten.isEmpty { KitapRafi(baslik: "Bitirdiklerim", kitaplar: biten, sirtlar: sirtlar, eylem: eylem) }
                    if l.isEmpty {
                        ContentUnavailableView.search(text: arama)
                    }
                }
                Text("Kitaplar yalnız bu telefonda saklanır. Dosyalar uygulamasında “İhya › Kitaplar” klasörüne koyduğun PDF'ler de rafa dizilir. Bir kitaba basılı tutunca adını değiştirir, bitti işaretler ya da silersin.")
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 28)
        }
        .scrollDismissesKeyboard(.interactively)
        .modifier(KitapAramasiDuzeni(etkin: depo.kayit.kitaplar.count > 4, arama: $arama))
        .navigationTitle("Kitaplarım")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Görünüm", selection: $sirtlar) {
                        Label("Kapaklar", systemImage: "square.grid.3x2").tag(false)
                        Label("Sırtlar", systemImage: "books.vertical").tag(true)
                    }
                    Picker("Sırala", selection: $sira) {
                        Text("Son okunan").tag(0)
                        Text("Son eklenen").tag(1)
                        Text("Ada göre").tag(2)
                    }
                } label: { Image(systemName: "line.3.horizontal.decrease.circle") }
                .accessibilityLabel("Görünüm ve sıralama")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { ice = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("PDF ekle")
            }
        }
        .fileImporter(isPresented: $ice, allowedContentTypes: [.pdf], allowsMultipleSelection: true) { sonuc in
            switch sonuc {
            case .success(let urller):
                var yeni: [Kitap] = []
                for u in urller {
                    do { yeni.append(try KitapDeposu.ice(u)) } catch { hata = "“\(u.lastPathComponent)” eklenemedi; dosya bozuk ya da PDF değil." }
                }
                if !yeni.isEmpty { depo.degistir { $0.kitaplar.insert(contentsOf: yeni, at: 0) }; Dokunsal.basari() }
            case .failure:
                hata = "Dosya açılamadı."
            }
        }
        .alert("Olmadı", isPresented: Binding(get: { hata != nil }, set: { if !$0 { hata = nil } })) {
            Button("Tamam", role: .cancel) {}
        } message: { Text(hata ?? "") }
        .alert("Kitabın adı", isPresented: Binding(get: { adlandirilan != nil }, set: { if !$0 { adlandirilan = nil } })) {
            TextField("Ad", text: $yeniAd)
            Button("Kaydet") {
                let ad = yeniAd.trimmingCharacters(in: .whitespacesAndNewlines)
                if let k = adlandirilan, !ad.isEmpty { degistir(k) { $0.ad = ad } }
            }
            Button("Vazgeç", role: .cancel) {}
        }
        .confirmationDialog("“\(silinecek?.ad ?? "")” silinsin mi?", isPresented: Binding(get: { silinecek != nil }, set: { if !$0 { silinecek = nil } }),
                            titleVisibility: .visible) {
            Button("Kitabı sil", role: .destructive) {
                guard let k = silinecek else { return }
                KitapDeposu.sil(k)
                depo.degistir { $0.kitaplar.removeAll { $0.id == k.id } }
            }
        } message: { Text("PDF dosyası bu telefondan kalkar; geri alınamaz.") }
        .task {
            let yeni = KitapDeposu.yeniler(depo.kayit.kitaplar)
            if !yeni.isEmpty { depo.degistir { $0.kitaplar.append(contentsOf: yeni) } }
        }
    }

    private func eylem(_ e: KitapEylemi, _ k: Kitap) {
        switch e {
        case .odak: yon.odakAc(konu: "Kitap", kitap: k.id)
        case .adlandir: yeniAd = k.ad; adlandirilan = k
        case .bitti: degistir(k) { $0.bitti = true; $0.son = $0.son ?? .now }
        case .sifirla: degistir(k) { $0.bitti = false; $0.sayfa = 0 }
        case .sil: silinecek = k
        }
    }

    private func degistir(_ k: Kitap, _ islem: (inout Kitap) -> Void) {
        depo.degistir { kayit in
            if let i = kayit.kitaplar.firstIndex(where: { $0.id == k.id }) { islem(&kayit.kitaplar[i]) }
        }
    }
}

/// Arama alanı yalnız kitap çoğalınca görünür.
private struct KitapAramasiDuzeni: ViewModifier {
    let etkin: Bool
    @Binding var arama: String
    @ViewBuilder func body(content: Content) -> some View {
        if etkin { content.searchable(text: $arama, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Kitap ara") } else { content }
    }
}

enum KitapEylemi { case odak, adlandir, bitti, sifirla, sil }

// MARK: Ahşap

/// Raf ahşabının renkleri: koyu düzende ceviz, açıkta meşe.
struct Ahsap {
    let cerceve: [Color]
    let arka: [Color]
    let ust: [Color]
    let on: [Color]

    static func renkler(_ koyu: Bool) -> Ahsap {
        koyu
            ? Ahsap(cerceve: [Color(hex: "#5C3A1F"), Color(hex: "#3F2714")], arka: [Color(hex: "#2A1A0D"), Color(hex: "#20140A")],
                    ust: [Color(hex: "#8E5F34"), Color(hex: "#6E4626")], on: [Color(hex: "#6A4323"), Color(hex: "#4A2E17")])
            : Ahsap(cerceve: [Color(hex: "#B07D4B"), Color(hex: "#8E5F34")], arka: [Color(hex: "#5E3F24"), Color(hex: "#4A311B")],
                    ust: [Color(hex: "#D4A774"), Color(hex: "#BD8D58")], on: [Color(hex: "#A87445"), Color(hex: "#875A31")])
    }
}

/// Ahşap damarı: ince, rastgele (ama her çizimde aynı) yatay çizgiler.
private struct Damar: View {
    var tohum = 7
    var yogunluk = 0.10
    var body: some View {
        Canvas { c, boyut in
            var r = UInt64(tohum) &* 2654435761
            func rnd() -> Double { r = r &* 6364136223846793005 &+ 1442695040888963407; return Double(r >> 33) / Double(1 << 31) }
            let adet = max(3, Int(boyut.height / 3))
            for _ in 0..<adet {
                let y = rnd() * boyut.height
                var p = Path()
                p.move(to: CGPoint(x: 0, y: y))
                p.addCurve(to: CGPoint(x: boyut.width, y: y + (rnd() - 0.5) * 3),
                           control1: CGPoint(x: boyut.width * 0.33, y: y + (rnd() - 0.5) * 4),
                           control2: CGPoint(x: boyut.width * 0.66, y: y + (rnd() - 0.5) * 4))
                c.stroke(p, with: .color(.black.opacity(yogunluk * (0.4 + rnd()))), lineWidth: 0.6 + rnd() * 0.8)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Kitapların durduğu raf tahtası: üst yüz, ön yüz ve arkaya düşen gölge.
private struct RafTahtasi: View {
    let ahsap: Ahsap
    var tohum = 1
    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: ahsap.ust, startPoint: .top, endPoint: .bottom).frame(height: 7)
            ZStack(alignment: .top) {
                LinearGradient(colors: ahsap.on, startPoint: .top, endPoint: .bottom)
                Damar(tohum: tohum, yogunluk: 0.14)
                Rectangle().fill(Color.white.opacity(0.22)).frame(height: 1)
            }
            .frame(height: 13)
        }
        .shadow(color: .black.opacity(0.35), radius: 3, y: 3)
    }
}

/// Bir raf dolabı: üstte pirinç levhalı başlık, içinde kitap sıraları.
struct KitapRafi: View {
    let baslik: String
    let kitaplar: [Kitap]
    let sirtlar: Bool
    let eylem: (KitapEylemi, Kitap) -> Void
    @Environment(\.colorScheme) private var sema
    @State private var genislik: CGFloat = 330

    private let kenar: CGFloat = 9
    private let ic: CGFloat = 12

    var body: some View {
        let ahsap = Ahsap.renkler(sema == .dark)
        let icGenislik = max(200, genislik - kenar * 2 - ic * 2)
        let sira = sirtlar ? sirtSiralari(icGenislik) : kapakSiralari
        VStack(spacing: 0) {
            // Başlık tahtası ve pirinç levha
            ZStack {
                LinearGradient(colors: ahsap.cerceve, startPoint: .top, endPoint: .bottom)
                Damar(tohum: baslik.count, yogunluk: 0.12)
                Levha(metin: "\(baslik) · \(kitaplar.count)")
            }
            .frame(height: 34)
            ForEach(sira.indices, id: \.self) { i in
                VStack(spacing: 0) {
                    HStack(alignment: .bottom, spacing: sirtlar ? 2 : 14) {
                        ForEach(sira[i]) { k in
                            if sirtlar {
                                KitapDugmesi(kitap: k, eylem: eylem) { KitapSirti(kitap: k) }
                            } else {
                                KitapDugmesi(kitap: k, eylem: eylem) { KitapKapagi(kitap: k, genislik: (icGenislik - 28) / 3) }
                            }
                        }
                    }
                    .padding(.horizontal, ic)
                    .padding(.top, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        ZStack(alignment: .top) {
                            LinearGradient(colors: ahsap.arka, startPoint: .top, endPoint: .bottom)
                            Damar(tohum: i + 11, yogunluk: 0.18)
                            // Üst rafın gölgesi
                            LinearGradient(colors: [.black.opacity(0.45), .clear], startPoint: .top, endPoint: .bottom).frame(height: 14)
                        }
                    }
                    RafTahtasi(ahsap: ahsap, tohum: i + 3)
                }
                .padding(.horizontal, kenar)
            }
            Color.clear.frame(height: kenar)
        }
        .background {
            ZStack {
                LinearGradient(colors: ahsap.cerceve, startPoint: .topLeading, endPoint: .bottomTrailing)
                Damar(tohum: 99, yogunluk: 0.1)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
        .shadow(color: .black.opacity(0.28), radius: 12, y: 6)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { genislik = $0 }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(baslik) rafı, \(kitaplar.count) kitap")
    }

    private var kapakSiralari: [[Kitap]] {
        stride(from: 0, to: kitaplar.count, by: 3).map { Array(kitaplar[$0..<min($0 + 3, kitaplar.count)]) }
    }

    private func sirtSiralari(_ w: CGFloat) -> [[Kitap]] {
        var sonuc: [[Kitap]] = [], satir: [Kitap] = [], dolu: CGFloat = 0
        for k in kitaplar {
            let g = KitapSirti.genislik(k) + 2
            if dolu + g > w, !satir.isEmpty { sonuc.append(satir); satir = []; dolu = 0 }
            satir.append(k)
            dolu += g
        }
        if !satir.isEmpty { sonuc.append(satir) }
        return sonuc
    }
}

/// Raf başlığındaki pirinç levha.
private struct Levha: View {
    let metin: String
    var body: some View {
        Text(metin.uppercased(with: Locale(identifier: "tr_TR")))
            .font(.system(size: 10.5, weight: .heavy, design: .serif))
            .tracking(1.4)
            .foregroundStyle(Color(hex: "#3A2810"))
            .shadow(color: .white.opacity(0.45), radius: 0, y: 0.6)
            .padding(.horizontal, 14).padding(.vertical, 4)
            .background {
                Capsule().fill(LinearGradient(colors: [Color(hex: "#F3D9A0"), Color(hex: "#C99A4B"), Color(hex: "#E8C77E")], startPoint: .top, endPoint: .bottom))
                    .overlay(Capsule().strokeBorder(Color(hex: "#7A5523").opacity(0.6), lineWidth: 0.8))
                    .shadow(color: .black.opacity(0.35), radius: 1.5, y: 1)
            }
    }
}

/// Kitaba dokununca açılır; basılı tutunca eylemler.
private struct KitapDugmesi<Icerik: View>: View {
    let kitap: Kitap
    let eylem: (KitapEylemi, Kitap) -> Void
    @ViewBuilder let icerik: () -> Icerik

    var body: some View {
        NavigationLink(value: Rota.kitap(kitap.id)) { icerik() }
            .buttonStyle(KitapBasma())
            .contextMenu {
                Button("Odakla oku", systemImage: "leaf") { eylem(.odak, kitap) }
                Button("Adını değiştir", systemImage: "pencil") { eylem(.adlandir, kitap) }
                if kitap.tamam {
                    Button("Baştan okunacak", systemImage: "arrow.counterclockwise") { eylem(.sifirla, kitap) }
                } else {
                    Button("Bitti olarak işaretle", systemImage: "checkmark.seal") { eylem(.bitti, kitap) }
                }
                ShareLink(item: KitapDeposu.url(kitap)) { Label("Paylaş", systemImage: "square.and.arrow.up") }
                Divider()
                Button("Sil", systemImage: "trash", role: .destructive) { eylem(.sil, kitap) }
            } preview: {
                KitapOnizleme(kitap: kitap)
            }
            .accessibilityLabel(KitapDugmesi.erisim(kitap))
    }

    static func erisim(_ k: Kitap) -> String {
        if k.tamam { return "\(k.ad), bitti" }
        if k.basladi { return "\(k.ad), yüzde \(Int(k.oran * 100)) okundu" }
        return "\(k.ad), başlanmadı"
    }
}

/// Basınca kitap hafifçe raftan kalkar.
private struct KitapBasma: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.04 : 1, anchor: .bottom)
            .offset(y: configuration.isPressed ? -4 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Önden görünen kitap: kapak, cilt gölgesi, sayfa kenarı, ilerleme.
struct KitapKapagi: View {
    let kitap: Kitap
    let genislik: CGFloat
    @State private var resim: UIImage?

    var body: some View {
        let oran = resim.map { $0.size.height / max($0.size.width, 1) } ?? 1.45
        let h = genislik * min(max(oran, 1.15), 1.6)
        ZStack(alignment: .leading) {
            if let resim {
                Image(uiImage: resim).resizable().scaledToFill()
            } else {
                UretilmisKapak(ad: kitap.ad, renk: KitapDeposu.sirtRengi(kitap, kapak: nil))
            }
            // Cilt: sol kenarda kıvrım gölgesi
            LinearGradient(stops: [.init(color: .black.opacity(0.38), location: 0), .init(color: .white.opacity(0.22), location: 0.035),
                                   .init(color: .black.opacity(0.16), location: 0.075), .init(color: .clear, location: 0.13)],
                           startPoint: .leading, endPoint: .trailing)
        }
        .frame(width: genislik, height: h)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 2, bottomLeadingRadius: 2, bottomTrailingRadius: 5, topTrailingRadius: 5))
        .background(alignment: .trailing) {
            // Sayfa kenarı
            UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 4, topTrailingRadius: 4)
                .fill(LinearGradient(colors: [Color(hex: "#F4ECDA"), Color(hex: "#D9CDB2")], startPoint: .leading, endPoint: .trailing))
                .frame(width: 8, height: h - 6)
                .offset(x: 3)
        }
        .overlay(alignment: .topTrailing) {
            if kitap.basladi && !kitap.tamam {
                // Ayraç kurdelesi
                Ayrac2().fill(Color(hex: "#C0392B")).frame(width: 11, height: 26).offset(x: -10, y: -1)
                    .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
            }
        }
        .overlay(alignment: .bottomTrailing) { durum.padding(5) }
        .shadow(color: .black.opacity(0.5), radius: 4, x: 2, y: 2)
        .task(id: kitap.dosya) { resim = await KitapDeposu.kapak(kitap) }
    }

    @ViewBuilder private var durum: some View {
        if kitap.tamam {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 17, weight: .bold))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, Color(hex: "#1FB25A"))
                .shadow(color: .black.opacity(0.3), radius: 1.5, y: 1)
        } else if kitap.basladi {
            Text("%\(Int(kitap.oran * 100))").font(.system(size: 10.5, weight: .heavy)).monospacedDigit()
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(.ultraThinMaterial, in: .capsule)
        } else if kitap.eklenme.timeIntervalSinceNow > -3 * 86400 {
            Text("YENİ").font(.system(size: 9, weight: .heavy)).tracking(0.6).foregroundStyle(.white)
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(Color(hex: "#1FB25A"), in: .capsule)
        }
    }
}

/// Kitap ayracı kurdelesi (uçta V kesik).
private struct Ayrac2: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY - r.width * 0.45))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Kapağı okunamayan kitaplar için çizilen kapak.
private struct UretilmisKapak: View {
    let ad: String
    let renk: Color
    var body: some View {
        ZStack {
            LinearGradient(colors: [renk, renk.opacity(0.75)], startPoint: .top, endPoint: .bottom)
            RoundedRectangle(cornerRadius: 2).strokeBorder(Color(hex: "#E9C46A").opacity(0.7), lineWidth: 1).padding(7)
            Text(ad).font(.system(size: 12, weight: .bold, design: .serif)).foregroundStyle(Color(hex: "#F6E7C1"))
                .multilineTextAlignment(.center).lineLimit(4).minimumScaleFactor(0.7).padding(14)
        }
    }
}

/// Yandan görünen kitap: sırt rengi kapaktan, kalınlığı sayfa sayısından.
struct KitapSirti: View {
    let kitap: Kitap
    @State private var renk: Color?

    static func genislik(_ k: Kitap) -> CGFloat { 24 + min(26, CGFloat(k.toplam).squareRoot() * 1.4) }
    static func yukseklik(_ k: Kitap) -> CGFloat {
        let t = abs(k.dosya.unicodeScalars.reduce(7) { ($0 &* 31) &+ Int($1.value) }) % 5
        return 132 + CGFloat(t) * 7
    }

    var body: some View {
        let w = KitapSirti.genislik(kitap), h = KitapSirti.yukseklik(kitap)
        let r = renk ?? KitapDeposu.sirtRengi(kitap, kapak: nil)
        let yazi = Color(hex: "#F6E7C1")
        ZStack {
            LinearGradient(stops: [.init(color: .black.opacity(0.45), location: 0), .init(color: .white.opacity(0.18), location: 0.3),
                                   .init(color: .clear, location: 0.55), .init(color: .black.opacity(0.4), location: 1)],
                           startPoint: .leading, endPoint: .trailing)
                .background(r)
            VStack(spacing: 0) {
                bantlar.padding(.top, 10)
                Spacer(minLength: 4)
                Text(kitap.ad)
                    .font(.system(size: w > 36 ? 12 : 10.5, weight: .bold, design: .serif))
                    .foregroundStyle(yazi)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(width: h - 62)
                    .rotationEffect(.degrees(90))
                    .frame(width: w, height: h - 62)
                Spacer(minLength: 4)
                if kitap.tamam {
                    Image(systemName: "checkmark").font(.system(size: 9, weight: .heavy)).foregroundStyle(yazi).padding(.bottom, 2)
                } else if kitap.basladi {
                    Circle().fill(Color(hex: "#E9C46A")).frame(width: 5, height: 5).padding(.bottom, 4)
                }
                bantlar.padding(.bottom, 10)
            }
        }
        .frame(width: w, height: h)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(alignment: .top) {
            if kitap.basladi && !kitap.tamam {
                Rectangle().fill(Color(hex: "#C0392B")).frame(width: 3, height: 16).offset(x: w * 0.2, y: -8)
            }
        }
        .shadow(color: .black.opacity(0.45), radius: 2, x: 1.5, y: 1)
        .task(id: kitap.dosya) { renk = KitapDeposu.sirtRengi(kitap, kapak: await KitapDeposu.kapak(kitap)) }
    }

    private var bantlar: some View {
        VStack(spacing: 2) {
            Rectangle().fill(Color(hex: "#E9C46A").opacity(0.85)).frame(height: 1.5)
            Rectangle().fill(Color(hex: "#E9C46A").opacity(0.85)).frame(height: 1.5)
        }
        .padding(.horizontal, 3)
    }
}

/// Basılı tutunca görünen önizleme: kapak, ad, ilerleme.
private struct KitapOnizleme: View {
    let kitap: Kitap
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            KitapKapagi(kitap: kitap, genislik: 150)
            Text(kitap.ad).font(.system(size: 15, weight: .bold, design: .serif)).lineLimit(3)
            Text(KitapOnizleme.ozet(kitap)).font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(width: 210)
    }

    static func ozet(_ k: Kitap) -> String {
        var p: [String] = []
        if k.toplam > 0 { p.append(k.tamam ? "\(k.toplam) sayfa, bitti" : "Sayfa \(k.sayfa + 1) / \(k.toplam)") }
        if k.okumaSn >= 60 { p.append(OkumaSuresi.yazi(k.okumaSn) + " okundu") }
        return p.joined(separator: " · ")
    }
}

/// Süre yazısı: "2 sa 15 dk", "40 dk".
enum OkumaSuresi {
    static func yazi(_ sn: Double) -> String {
        let dk = Int(sn / 60)
        return dk >= 60 ? "\(dk / 60) sa \(dk % 60) dk" : "\(max(1, dk)) dk"
    }
}

/// Rafların üstünde: kaldığın kitap, ilerleme ve kalan süre tahmini.
private struct DevamKarti: View {
    let kitap: Kitap
    @Environment(Yonlendirici.self) private var yon
    @Environment(\.palet) private var palet

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            KitapKapagi(kitap: kitap, genislik: 74)
            VStack(alignment: .leading, spacing: 7) {
                BolumBasligi(metin: "Kaldığın yer", simge: "bookmark.fill")
                Text(kitap.ad).font(.system(size: 17, weight: .bold, design: .serif)).lineLimit(2)
                Text("Sayfa \(kitap.sayfa + 1) / \(kitap.toplam) · %\(Int(kitap.oran * 100))")
                    .font(.system(size: 12.5, weight: .semibold)).foregroundStyle(.secondary).monospacedDigit()
                IlerlemeCubugu(oran: kitap.oran, yukseklik: 5)
                if let k = kalan { Text(k).font(.system(size: 11.5, weight: .semibold)).foregroundStyle(.secondary) }
                HStack(spacing: 8) {
                    NavigationLink(value: Rota.kitap(kitap.id)) {
                        Label("Devam et", systemImage: "book.fill").font(.kalin(14))
                    }
                    .buttonStyle(.glassProminent)
                    Button { yon.odakAc(konu: "Kitap", kitap: kitap.id) } label: {
                        Image(systemName: "leaf.fill").font(.system(size: 15, weight: .bold)).foregroundStyle(Color(hex: "#1FB25A"))
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel("Odakla oku")
                }
                .padding(.top, 2)
            }
        }
        .camKart(kose: 24, ic: 14)
    }

    /// Okunan sayfa ve süreden kalan süre tahmini (yeterli veri varsa).
    private var kalan: String? {
        guard kitap.okumaSn >= 600, kitap.sayfa >= 5, kitap.toplam > kitap.sayfa + 1 else {
            return kitap.okumaSn >= 60 ? "\(OkumaSuresi.yazi(kitap.okumaSn)) okudun" : nil
        }
        let sayfaBasi = kitap.okumaSn / Double(kitap.sayfa + 1)
        return "\(OkumaSuresi.yazi(kitap.okumaSn)) okudun · yaklaşık \(OkumaSuresi.yazi(sayfaBasi * Double(kitap.toplam - kitap.sayfa - 1))) kaldı"
    }
}

/// Boş raf: ilk kitabı eklemeye çağırır.
private struct BosRaf: View {
    let ekle: () -> Void
    @Environment(\.colorScheme) private var sema

    var body: some View {
        let ahsap = Ahsap.renkler(sema == .dark)
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Image(systemName: "books.vertical").font(.system(size: 40, weight: .light)).foregroundStyle(Color(hex: "#E9C46A"))
                Text("Rafın boş").font(.system(size: 20, weight: .bold, design: .serif)).foregroundStyle(Color(hex: "#F6E7C1"))
                Text("Telefonundaki PDF kitapları ekle; rafa dizilsin, kaldığın sayfa hatırlansın.")
                    .font(.system(size: 13.5, weight: .medium)).foregroundStyle(Color(hex: "#F6E7C1").opacity(0.75)).multilineTextAlignment(.center)
                Button(action: ekle) { Label("PDF ekle", systemImage: "plus").font(.kalin(15)) }
                    .buttonStyle(.glassProminent)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 24).padding(.vertical, 30)
            .frame(maxWidth: .infinity)
            .background(LinearGradient(colors: ahsap.arka, startPoint: .top, endPoint: .bottom))
            RafTahtasi(ahsap: ahsap)
        }
        .padding(9)
        .background(LinearGradient(colors: ahsap.cerceve, startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.28), radius: 12, y: 6)
    }
}
