import SwiftUI

struct KitaplikEkrani: View {
    private struct Bolum: Identifiable {
        let rota: Rota, ad: String, alt: String, simge: String, renk: Color
        var id: String { ad }
    }

    private let bolumler: [Bolum] = [
        Bolum(rota: .hadisler, ad: "Hadis-i Şerifler", alt: "Sahîh-i Buhârî", simge: "text.book.closed", renk: Color(red: 0.16, green: 0.55, blue: 0.36)),
        Bolum(rota: .dualar, ad: "Dualar", alt: "Konulu dualar ve Dua Defterim", simge: "hands.sparkles", renk: Color(red: 0.36, green: 0.42, blue: 0.86)),
        Bolum(rota: .esma, ad: "Esmâ-ül Hüsnâ", alt: "99 isim ve anlamları", simge: "sparkles", renk: Color(red: 0.80, green: 0.58, blue: 0.16)),
        Bolum(rota: .sozler, ad: "Hikmetli Sözler", alt: "Âyetler ve güzel sözler", simge: "quote.opening", renk: Color(red: 0.62, green: 0.38, blue: 0.78)),
        Bolum(rota: .kitaplar, ad: "Kitaplarım", alt: "PDF ekle ve oku", simge: "books.vertical", renk: Color(red: 0.70, green: 0.40, blue: 0.28)),
        Bolum(rota: .kible, ad: "Kıble", alt: "Pusula ile yön", simge: "location.north.line", renk: Color(red: 0.12, green: 0.50, blue: 0.62)),
        Bolum(rota: .diniGunler, ad: "Dinî Günler", alt: "Kandiller ve bayramlar", simge: "calendar", renk: Color(red: 0.85, green: 0.38, blue: 0.40)),
        Bolum(rota: .favoriler, ad: "Kaydettiklerim", alt: "Beğendiğin hadis, söz ve dualar", simge: "heart", renk: .pink),
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(bolumler) { b in
                    NavigationLink(value: b.rota) {
                        VStack(alignment: .leading, spacing: 10) {
                            Image(systemName: b.simge)
                                .font(.title2)
                                .foregroundStyle(b.renk)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(b.renk.opacity(0.14)))
                            Spacer(minLength: 0)
                            Text(b.ad).font(.headline).lineLimit(1).minimumScaleFactor(0.8)
                            Text(b.alt).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
                        .padding(16)
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .navigationTitle("Kitaplık")
    }
}

/// Okuma alanı: kendi açık/koyu kipi (güneş simgesi), punto düğmeleri.
struct OkumaAlani: ViewModifier {
    @Environment(Depo.self) private var depo
    @Environment(\.colorScheme) private var sistem

    func body(content: Content) -> some View {
        let koyu = depo.ayarlar.okumaKoyu ?? (sistem == .dark)
        content
            .environment(\.colorScheme, koyu ? .dark : .light)
            .background((koyu ? Color(red: 0.07, green: 0.08, blue: 0.08) : Color(red: 0.985, green: 0.975, blue: 0.95)).ignoresSafeArea())
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { puntoDegistir(-1) } label: { Image(systemName: "textformat.size.smaller") }
                        .accessibilityLabel("Yazıyı küçült")
                        .disabled(depo.ayarlar.okumaPunto <= 14)
                    Button { puntoDegistir(1) } label: { Image(systemName: "textformat.size.larger") }
                        .accessibilityLabel("Yazıyı büyüt")
                        .disabled(depo.ayarlar.okumaPunto >= 30)
                    Button {
                        depo.degistir { $0.ayarlar.okumaKoyu = !koyu }
                        Dokunsal.hafif(0.5)
                    } label: { Image(systemName: koyu ? "sun.max" : "moon") }
                        .accessibilityLabel(koyu ? "Açık okuma" : "Koyu okuma")
                        .contextMenu {
                            Button("Uygulama temasıyla aynı") { depo.degistir { $0.ayarlar.okumaKoyu = nil } }
                        }
                }
            }
    }

    private func puntoDegistir(_ y: Double) {
        depo.degistir { $0.ayarlar.okumaPunto = min(30, max(14, $0.ayarlar.okumaPunto + y)) }
        Dokunsal.hafif(0.4)
    }
}

extension View {
    func okumaAlani() -> some View { modifier(OkumaAlani()) }
}

// MARK: Hadisler

struct HadislerEkrani: View {
    @Environment(Depo.self) private var depo
    @State private var konu: String?
    @State private var begenilenler = false

    var body: some View {
        let liste = Icerik.hadisler.filter { (konu == nil || $0.konu == konu) && (!begenilenler || depo.begenildi(.hadis, String($0.no))) }
        ScrollView {
            LazyVStack(spacing: 14, pinnedViews: []) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        KonuCipi(ad: "Tümü", renk: .ihya, secili: konu == nil && !begenilenler) { konu = nil; begenilenler = false }
                        KonuCipi(ad: "Kaydettiklerim", renk: .pink, secili: begenilenler) { begenilenler.toggle() }
                        ForEach(Icerik.hadisKonulari, id: \.self) { k in
                            KonuCipi(ad: k, renk: .ihya, secili: konu == k) { konu = konu == k ? nil : k }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
                ForEach(liste) { h in HadisKarti(hadis: h).padding(.horizontal, 16) }
                if liste.isEmpty {
                    ContentUnavailableView("Kayıt yok", systemImage: "heart", description: Text("Beğendiğin hadisler burada görünür."))
                }
            }
            .padding(.bottom, 24)
        }
        .okumaAlani()
        .navigationTitle("Hadis-i Şerifler")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HadisKarti: View {
    @Environment(Depo.self) private var depo
    let hadis: Hadis
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(hadis.konu).font(.caption.weight(.semibold)).foregroundStyle(Color.ihya)
            Text(hadis.metin)
                .font(.okuma(depo.ayarlar.okumaPunto))
                .lineSpacing(depo.ayarlar.okumaPunto * 0.28)
                .textSelection(.enabled)
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(hadis.ravi).font(.footnote)
                    if let url = URL(string: hadis.link) {
                        Link(hadis.kaynak, destination: url).font(.caption)
                    } else {
                        Text(hadis.kaynak).font(.caption)
                    }
                }
                .foregroundStyle(.secondary)
                Spacer()
                BegenDugmesi(tur: .hadis, anahtar: String(hadis.no))
                ShareLink(item: "\(hadis.metin)\n\n\(hadis.ravi) · \(hadis.kaynak)") { Image(systemName: "square.and.arrow.up") }
                    .accessibilityLabel("Paylaş")
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.primary.opacity(0.045)))
    }
}

// MARK: Sözler

struct SozlerEkrani: View {
    @Environment(Depo.self) private var depo

    var body: some View {
        let gruplar = Dictionary(grouping: Icerik.sozler, by: \.grup)
        let sira = Icerik.sozler.reduce(into: [String]()) { if !$0.contains($1.grup) { $0.append($1.grup) } }
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                ForEach(sira, id: \.self) { g in
                    Text(g).font(.title3.weight(.semibold)).padding(.top, 8)
                    ForEach(gruplar[g] ?? []) { s in SozKarti(soz: s) }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .okumaAlani()
        .navigationTitle("Hikmetli Sözler")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SozKarti: View {
    @Environment(Depo.self) private var depo
    let soz: Soz
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(soz.soz).font(.okuma(depo.ayarlar.okumaPunto)).lineSpacing(depo.ayarlar.okumaPunto * 0.25).textSelection(.enabled)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(soz.kisi).font(.footnote)
                    Text(soz.kaynak).font(.caption)
                }
                .foregroundStyle(.secondary)
                Spacer()
                BegenDugmesi(tur: .soz, anahtar: soz.id)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.primary.opacity(0.045)))
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
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                if f.isEmpty {
                    ContentUnavailableView("Henüz kayıt yok", systemImage: "heart", description: Text("Hadis, söz ve dualardaki kalbe dokununca burada toplanır."))
                        .padding(.top, 40)
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
    }
}
