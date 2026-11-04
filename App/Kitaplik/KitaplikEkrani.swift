import SwiftUI

struct KitaplikEkrani: View {
    @Environment(Depo.self) private var depo
    @Environment(\.palet) private var palet
    @State private var arama = ""

    private struct Bolum: Identifiable {
        let rota: Rota, ad: String, alt: String, harf: String, r1: String, r2: String
        var id: String { ad }
    }

    private var bolumler: [Bolum] {
        [
            Bolum(rota: .dualar, ad: "Dualar", alt: "Sabah · akşam · konulu", harf: "د", r1: "#F7C548", r2: "#D98E1F"),
            Bolum(rota: .hadisler, ad: "Hadisler", alt: "\(Icerik.hadisler.count) sahih hadis", harf: "ح", r1: "#9B8CFF", r2: "#5B4BD8"),
            Bolum(rota: .sozler, ad: "Hikmet", alt: "\(Icerik.sozler.count) kaynaklı söz", harf: "ع", r1: "#FF9AB8", r2: "#D9507E"),
            Bolum(rota: .duaDefteri, ad: "Dua Defterim", alt: "Sayaçlı zikirler", harf: "ن", r1: "#8FD6C8", r2: "#2E8F7E"),
            Bolum(rota: .zikir, ad: "Zikir", alt: "Tesbih ve tesbihat", harf: "ذ", r1: "#7FDB8A", r2: "#2A9C4A"),
            Bolum(rota: .kitaplar, ad: "Kitaplarım", alt: "PDF ekle ve oku", harf: "ك", r1: "#F4B884", r2: "#C77B3A"),
            Bolum(rota: .esma, ad: "Esmâ-i Hüsnâ", alt: "99 isim · ezber", harf: "أ", r1: "#FFA07A", r2: "#D9573A"),
            Bolum(rota: .kible, ad: "Kıble", alt: "Pusula ile yön", harf: "ق", r1: "#7CC4FF", r2: "#2F7FD1"),
            Bolum(rota: .diniGunler, ad: "Dinî günler", alt: "Kandiller · üç aylar", harf: "ي", r1: "#C9A2FF", r2: "#8452D6"),
            Bolum(rota: .favoriler, ad: "Kaydettiklerim", alt: "\(depo.kayit.favoriler.count) kayıt", harf: "م", r1: "#FF8FA3", r2: "#D93B5E"),
        ]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                SahneBasligi(baslik: "Kitaplık") {
                    Text("Hepsi telefonunda · çevrimdışı")
                        .font(.system(size: 12, weight: .bold)).foregroundStyle(.secondary)
                        .lineLimit(1).minimumScaleFactor(0.8)
                        .padding(.bottom, 6)
                }
                aramaAlani
                if arama.trimmingCharacters(in: .whitespaces).count >= 2 {
                    AramaSonuclari(metin: arama)
                } else {
                    if let h = Icerik.gunun(Icerik.hadisler.filter { $0.metin.count <= 140 }) { GununHadisiKarti(hadis: h) }
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                        ForEach(bolumler) { b in
                            NavigationLink(value: b.rota) {
                                HStack(spacing: 10) {
                                    HarfRozeti(harf: b.harf, renk1: b.r1, renk2: b.r2)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(b.ad).font(.kalin(14)).lineLimit(1).minimumScaleFactor(0.8)
                                        Text(b.alt).font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary).lineLimit(1)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(.horizontal, 10)
                                .frame(height: 60)
                                .contentShape(RoundedRectangle(cornerRadius: 20))
                            }
                            .buttonStyle(.plain)
                            .camYuzey(palet.cam(etkilesimli: true), in: .rect(cornerRadius: 20))
                        }
                    }
                    EsmaEzberKarti()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        .altCubukPayi()
        .toolbar(.hidden, for: .navigationBar)
    }

    private var aramaAlani: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").font(.system(size: 16, weight: .semibold)).foregroundStyle(.secondary)
            TextField("Dua, hadis, söz ara", text: $arama)
                .font(.system(size: 15, weight: .semibold))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !arama.isEmpty {
                Button { arama = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Aramayı temizle")
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 46)
        .camYuzey(palet.cam(), in: .capsule)
    }
}

/// Kitaplıkta arama: hadis, söz ve dualarda geçen metin.
struct AramaSonuclari: View {
    let metin: String

    var body: some View {
        let q = metin.trimmingCharacters(in: .whitespaces).lowercased(with: Locale(identifier: "tr_TR"))
        let tr = Locale(identifier: "tr_TR")
        let hadisler = Icerik.hadisler.filter { $0.metin.lowercased(with: tr).contains(q) || $0.konu.lowercased(with: tr).contains(q) }.prefix(20)
        let sozler = Icerik.sozler.filter { $0.soz.lowercased(with: tr).contains(q) || $0.kisi.lowercased(with: tr).contains(q) }.prefix(20)
        let dualar = Icerik.duaTemalari.flatMap(\.dualar).filter { $0.baslik.lowercased(with: tr).contains(q) || $0.anlam.lowercased(with: tr).contains(q) }.prefix(20)
        LazyVStack(alignment: .leading, spacing: 12) {
            if hadisler.isEmpty, sozler.isEmpty, dualar.isEmpty {
                Text("“\(metin)” için sonuç yok.").font(.system(size: 14, weight: .semibold)).foregroundStyle(.secondary).padding(.top, 20)
            }
            if !dualar.isEmpty { BolumBasligi(metin: "Dualar · \(dualar.count)"); ForEach(dualar) { DuaKarti(dua: $0) } }
            if !hadisler.isEmpty { BolumBasligi(metin: "Hadisler · \(hadisler.count)"); ForEach(hadisler) { HadisKarti(hadis: $0) } }
            if !sozler.isEmpty { BolumBasligi(metin: "Sözler · \(sozler.count)"); ForEach(sozler) { SozKarti(soz: $0) } }
        }
    }
}

/// Kitaplık başındaki krem "Günün hadisi" kartı.
struct GununHadisiKarti: View {
    let hadis: Hadis
    var body: some View {
        NavigationLink(value: Rota.gununHadisi) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("GÜNÜN HADİSİ").font(.kalin(10.5)).tracking(1)
                        .foregroundStyle(Color(hex: "#FFE6A8"))
                        .padding(.horizontal, 9).frame(height: 22)
                        .background(Capsule().fill(Color(hex: "#2A2416")))
                    Text(hadis.ravi).font(.system(size: 11, weight: .bold)).foregroundStyle(Color(hex: "#7A6A48")).lineLimit(1)
                }
                Text("“\(hadis.metin)”").font(.system(size: 19, weight: .medium, design: .serif)).lineSpacing(3).multilineTextAlignment(.leading)
                Text(hadis.kaynak.uppercased(with: Locale(identifier: "tr_TR"))).font(.kalin(11.5)).tracking(0.6).foregroundStyle(Color.altin)
            }
            .kremKart(kose: 28, ic: 16)
        }
        .buttonStyle(.plain)
    }
}

/// Esmâ ezberi: 99 nokta, sıradaki isim, "Ezberledim".
struct EsmaEzberKarti: View {
    @Environment(Depo.self) private var depo
    @Environment(\.palet) private var palet

    var body: some View {
        let ezber = Set(depo.kayit.ezber)
        let siradaki = Icerik.esma.first { !ezber.contains($0.no) }
        HStack(spacing: 14) {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(8), spacing: 3), count: 11), spacing: 3) {
                ForEach(1...99, id: \.self) { n in
                    Circle()
                        .fill(ezber.contains(n) ? Color(hex: "#FFD66B") : Color.primary.opacity(0.16))
                        .frame(width: 8, height: 8)
                        .shadow(color: ezber.contains(n) ? Color(hex: "#FFD66B").opacity(0.7) : .clear, radius: 3)
                }
            }
            .frame(width: 118)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("ESMÂ EZBERİ · \(ezber.count)/99").font(.kalin(10.5)).tracking(1).foregroundStyle(.secondary)
                if let s = siradaki {
                    Text(s.arapca).font(.arapca(25)).foregroundStyle(Color(hex: "#FFE08A")).lineLimit(1).minimumScaleFactor(0.6)
                    (Text(s.ad).font(.kalin(13.5)) + Text(" · \(s.anlam)").font(.system(size: 13.5, weight: .semibold)).foregroundStyle(.secondary))
                        .lineLimit(2)
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { depo.degistir { $0.ezber.append(s.no) } }
                        Dokunsal.basari()
                    } label: {
                        Text("EZBERLEDİM").font(.kalin(12.5)).tracking(0.5).foregroundStyle(.white).frame(maxWidth: .infinity, minHeight: 26)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(Color(hex: "#1FB25A"))
                    .padding(.top, 2)
                } else {
                    Text("Doksan dokuz ismin hepsini ezberledin.").font(.kalin(14))
                    Button("Baştan başla") { depo.degistir { $0.ezber = [] } }.font(.system(size: 13, weight: .bold))
                }
            }
        }
        .camKart(kose: 28, ic: 14)
    }
}

/// Okuma alanı: "Aa" ile okuma ayarları (tema, boyut, satır arası, sıcak ışık), sıcak ışık katmanı, ekranın açık kalması.
struct OkumaAlani: ViewModifier {
    @Environment(Depo.self) private var depo
    @Environment(Yonlendirici.self) private var yon
    @State private var ayarlar = false

    func body(content: Content) -> some View {
        content
            .sicakIsik()
            .uyanikTut()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { ayarlar = true } label: { Image(systemName: "textformat.size") }
                        .accessibilityLabel("Okuma ayarları")
                }
            }
            .sheet(isPresented: $ayarlar) { OkumaAyarlariSayfasi().presentationDetents([.medium, .large]) }
            .onAppear { if yon.okumaAyarAc { yon.okumaAyarAc = false; ayarlar = true } }
    }
}

/// Okuma kartı: gündüz temasında krem, sepya/gece/siyah temada kendi zemin ve yazı rengiyle.
struct OkumaKarti: ViewModifier {
    @Environment(Depo.self) private var depo
    @Environment(VakitServisi.self) private var vakit
    var ic: CGFloat = 18

    @ViewBuilder
    func body(content: Content) -> some View {
        let t = depo.okumaTemasi(vakit)
        if t.koyu {
            content
                .environment(\.colorScheme, .dark)
                .foregroundStyle(Color(hex: t.yazi))
                .padding(ic)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: t.zemin), in: .rect(cornerRadius: 24))
                .overlay { CamKenari(sekil: RoundedRectangle(cornerRadius: 24)) }
        } else {
            content.kremKart(kose: 24, ic: ic)
        }
    }
}

extension View {
    func okumaAlani() -> some View { modifier(OkumaAlani()) }
    func okumaKarti(ic: CGFloat = 18) -> some View { modifier(OkumaKarti(ic: ic)) }
}

// MARK: Hadisler ve hikmet

enum HadisBolumu: String, CaseIterable, Hashable {
    case gunun = "Günün hadisi", hadisler = "Hadisler", hikmet = "Hikmet"
}

struct HadislerEkrani: View {
    @Environment(Depo.self) private var depo
    @Environment(\.palet) private var palet
    @State private var bolum: HadisBolumu
    @State private var konu: String?
    @State private var begenilenler = false
    @State private var kaydir = 0

    init(bolum: HadisBolumu = .gunun) { _bolum = State(initialValue: bolum) }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                CamSegment(secenekler: HadisBolumu.allCases, secili: $bolum, ad: { $0.rawValue })
                    .padding(.horizontal, 16)
                switch bolum {
                case .gunun: gunun.padding(.horizontal, 16)
                case .hadisler: hadisListesi
                case .hikmet: hikmet
                }
            }
            .padding(.bottom, 24)
        }
        .okumaAlani()
        .navigationTitle(bolum == .hikmet ? "Hikmet" : "Hadis-i Şerifler")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var gunun: some View {
        if let h = Icerik.gunun(Icerik.hadisler, kaydir: kaydir) {
            let p = depo.ayarlar.okumaPunto
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Text("GÜNÜN HADİSİ").font(.kalin(10.5)).tracking(1)
                        .foregroundStyle(Color(hex: "#FFE6A8"))
                        .padding(.horizontal, 9).frame(height: 22)
                        .background(Capsule().fill(Color(hex: "#2A2416")))
                    Text(h.konu).font(.system(size: 11, weight: .bold)).foregroundStyle(Color(hex: "#7A5A1A"))
                        .padding(.horizontal, 9).frame(height: 22)
                        .background(Capsule().fill(Color(hex: "#F3E3BC")))
                        .lineLimit(1)
                    Spacer()
                    BegenDugmesi(tur: .hadis, anahtar: String(h.no))
                }
                Text(h.metin)
                    .font(.system(size: p + 4, design: .serif))
                    .lineSpacing((p + 4) * 0.3)
                    .textSelection(.enabled)
                    .padding(.vertical, 18)
                Rectangle().fill(LinearGradient(colors: [Color(r: 201, g: 160, b: 74, a: 0), Color(r: 201, g: 160, b: 74, a: 0.7), Color(r: 201, g: 160, b: 74, a: 0)], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 1)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Râvî: \(h.ravi)").font(.system(size: 13, weight: .semibold))
                    Text(h.kaynak.uppercased(with: Locale(identifier: "tr_TR"))).font(.kalin(12)).tracking(0.6).foregroundStyle(Color.altin)
                }
                HStack(spacing: 10) {
                    if let url = URL(string: h.link) {
                        Link(destination: url) {
                            Text("Kaynağı aç · sunnah.com").font(.kalin(14)).foregroundStyle(.white).frame(maxWidth: .infinity, minHeight: 30)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(Color(hex: "#1FB25A"))
                    }
                    Button { withAnimation(.snappy) { kaydir += 1 } } label: {
                        Image(systemName: "arrow.clockwise").font(.system(size: 15, weight: .bold)).frame(width: 30, height: 30)
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel("Başka bir hadis")
                    ShareLink(item: "\(h.metin)\n\n\(h.ravi) · \(h.kaynak)") {
                        Image(systemName: "square.and.arrow.up").font(.system(size: 15, weight: .bold)).frame(width: 30, height: 30)
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel("Paylaş")
                }
                Text("Yalnız Sahîh-i Buhârî ve yalnız Hz. Peygamber’in sözleri. Her hadis numarası kaynağa karşı doğrulandı; sahâbe sözleri Hikmet bölümünde.")
                    .font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
            }
            .okumaKarti(ic: 20)
        }
    }

    @ViewBuilder
    private var hadisListesi: some View {
        let liste = Icerik.hadisler.filter { (konu == nil || $0.konu == konu) && (!begenilenler || depo.begenildi(.hadis, String($0.no))) }
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                KonuCipi(ad: "Tümü", renk: palet.vurgu, secili: konu == nil && !begenilenler) { konu = nil; begenilenler = false }
                KonuCipi(ad: "Kaydettiklerim", renk: .pink, secili: begenilenler) { begenilenler.toggle() }
                ForEach(Icerik.hadisKonulari, id: \.self) { k in
                    KonuCipi(ad: k, renk: palet.vurgu, secili: konu == k) { konu = konu == k ? nil : k }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        ForEach(liste) { h in HadisKarti(hadis: h).padding(.horizontal, 16) }
        if liste.isEmpty {
            Text("Beğendiğin hadisler burada görünür.").font(.system(size: 14, weight: .semibold)).foregroundStyle(.secondary).padding(.top, 30)
        }
    }

    @ViewBuilder
    private var hikmet: some View {
        let gruplar = Dictionary(grouping: Icerik.sozler, by: \.grup)
        let sira = Icerik.sozler.reduce(into: [String]()) { if !$0.contains($1.grup) { $0.append($1.grup) } }
        ForEach(sira, id: \.self) { g in
            BolumBasligi(metin: g).padding(.horizontal, 16).padding(.top, 8)
            ForEach(gruplar[g] ?? []) { s in SozKarti(soz: s).padding(.horizontal, 16) }
        }
    }
}

struct HadisKarti: View {
    @Environment(Depo.self) private var depo
    let hadis: Hadis
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(hadis.konu.uppercased(with: Locale(identifier: "tr_TR"))).font(.kalin(10.5)).tracking(1).foregroundStyle(Color.altin)
            Text(hadis.metin)
                .font(.okuma(depo.ayarlar.okumaPunto))
                .lineSpacing(depo.ayarlar.satirBoslugu(depo.ayarlar.okumaPunto))
                .textSelection(.enabled)
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(hadis.ravi).font(.footnote.weight(.semibold))
                    if let url = URL(string: hadis.link) {
                        Link(hadis.kaynak, destination: url).font(.caption.weight(.bold))
                    } else {
                        Text(hadis.kaynak).font(.caption.weight(.bold))
                    }
                }
                .foregroundStyle(.secondary)
                Spacer()
                BegenDugmesi(tur: .hadis, anahtar: String(hadis.no))
                ShareLink(item: "\(hadis.metin)\n\n\(hadis.ravi) · \(hadis.kaynak)") { Image(systemName: "square.and.arrow.up") }
                    .accessibilityLabel("Paylaş")
            }
        }
        .okumaKarti()
    }
}

struct SozKarti: View {
    @Environment(Depo.self) private var depo
    let soz: Soz
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(soz.soz).font(.okuma(depo.ayarlar.okumaPunto)).lineSpacing(depo.ayarlar.satirBoslugu(depo.ayarlar.okumaPunto)).textSelection(.enabled)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(soz.kisi).font(.footnote.weight(.semibold))
                    Text(soz.kaynak).font(.caption)
                }
                .foregroundStyle(.secondary)
                Spacer()
                BegenDugmesi(tur: .soz, anahtar: soz.id)
            }
        }
        .okumaKarti()
    }
}

// MARK: Kaydettiklerim

struct FavorilerEkrani: View {
    @Environment(Depo.self) private var depo

    var body: some View {
        let f = depo.kayit.favoriler
        let hadisler = f.filter { $0.tur == .hadis }.compactMap { k in Icerik.hadisler.first { String($0.no) == k.anahtar } }
        let sozler = f.filter { $0.tur == .soz }.compactMap { k in Icerik.sozler.first { $0.id == k.anahtar } }
        let dualar = f.filter { $0.tur == .dua }.compactMap { Icerik.dua($0.anahtar) }
        let ayetler = f.filter { $0.tur == .ayet }.compactMap { k -> AyetYeri? in
            let p = k.anahtar.split(separator: ":").compactMap { Int($0) }
            return p.count == 2 ? AyetYeri(sure: p[0], ayet: p[1]) : nil
        }
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                if f.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "heart").font(.system(size: 34, weight: .semibold)).foregroundStyle(.secondary)
                        Text("Henüz kayıt yok").font(.kalin(17))
                        Text("Âyet, hadis, söz ve dualardaki kalbe dokununca burada toplanır.").font(.system(size: 14, weight: .medium)).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                }
                if !ayetler.isEmpty {
                    BolumBasligi(metin: "Âyetler", simge: "book")
                    ForEach(ayetler, id: \.self) { KayitliAyetKarti(yer: $0) }
                }
                if !hadisler.isEmpty {
                    BolumBasligi(metin: "Hadisler", simge: "text.book.closed")
                    ForEach(hadisler) { HadisKarti(hadis: $0) }
                }
                if !dualar.isEmpty {
                    BolumBasligi(metin: "Dualar", simge: "hands.sparkles")
                    ForEach(dualar) { DuaKarti(dua: $0) }
                }
                if !sozler.isEmpty {
                    BolumBasligi(metin: "Sözler ve âyetler", simge: "quote.opening")
                    ForEach(sozler) { SozKarti(soz: $0) }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .okumaAlani()
        .navigationTitle("Kaydettiklerim")
        .navigationBarTitleDisplayMode(.inline)
        .task { await KuranDeposu.ortak.hazirla() }
    }
}

/// Kaydedilen âyet: Arapçası, meali; dokununca okuyucuda açılır.
struct KayitliAyetKarti: View {
    let yer: AyetYeri
    @Environment(Depo.self) private var depo
    @Environment(Yonlendirici.self) private var yon
    @State private var kuran = KuranDeposu.ortak

    var body: some View {
        let p = depo.ayarlar.okumaPunto
        let v = kuran.ayet(yer)
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(kuran.sure(yer.sure)?.ad ?? "Sûre \(yer.sure)") \(yer.sure):\(yer.ayet)").font(.headline)
                Spacer()
                BegenDugmesi(tur: .ayet, anahtar: "\(yer.sure):\(yer.ayet)")
            }
            if let v {
                Text(v.arapca)
                    .font(.arapca(p + 8))
                    .lineSpacing(p * 0.5)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                let meal = v.meal.isEmpty ? (kuran.ayetleri(yer.sure).dropFirst(yer.ayet).first { !$0.meal.isEmpty }?.meal ?? "") : v.meal
                Text(meal).font(.okuma(p)).lineSpacing(depo.ayarlar.satirBoslugu(p))
            } else {
                ProgressView().frame(maxWidth: .infinity)
            }
            Button { yon.ac(.sure(yer.sure, yer.ayet)) } label: {
                Label("Okuyucuda aç", systemImage: "book").font(.kalin(13))
            }
            .buttonStyle(.glass)
        }
        .okumaKarti()
    }
}
