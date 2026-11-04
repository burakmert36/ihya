import AVFoundation
import SwiftUI
import UIKit

extension Color {
    /// "#RRGGBB" biçiminden renk.
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        let v = UInt64(s, radix: 16) ?? 0x27AE60
        self.init(.sRGB, red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255, opacity: 1)
    }

    /// Tasarım tuvalindeki rgba(…) değerleri için.
    init(r: Double, g: Double, b: Double, a: Double = 1) {
        self.init(.sRGB, red: r / 255, green: g / 255, blue: b / 255, opacity: a)
    }

    static let ihya = Color.accentColor
    static let toprak = Color(red: 0.55, green: 0.38, blue: 0.24)
    static let krem = Color(hex: "#FFF8E8")
    static let kremMetin = Color(hex: "#1E190E")
    static let altin = Color(hex: "#9A6A00")
}

extension Font {
    static func arapca(_ boyut: CGFloat, kalin: Bool = false) -> Font { .custom(kalin ? "Amiri-Bold" : "Amiri-Regular", size: boyut) }
    static func okuma(_ boyut: CGFloat) -> Font { .system(size: boyut, weight: .regular, design: .serif) }
    /// Tasarımın kalın arayüz yazısı (Inter 800 karşılığı).
    static func kalin(_ boyut: CGFloat) -> Font { .system(size: boyut, weight: .heavy) }
}

// MARK: Sahne ve palet

/// Her ekranın tasarımdaki zemini. İhya temasında her sahnenin kendi rengi var; diğer temalar bütün sahnelere tek zemin verir.
enum Sahne: Hashable { case bugun, odak, bahce, kitaplik, sesler, vakit, hadis, okuma, zikir, ayarlar }

/// Zemindeki yumuşak ışık lekesi; x, y ekranın oranı, r nokta cinsinden yarıçap.
struct Isik: Hashable {
    var renk: Color
    var x: CGFloat
    var y: CGFloat
    var r: CGFloat
}

struct Palet {
    var koyu: Bool
    var duraklar: [Gradient.Stop]
    /// nil: yukarıdan aşağı doğrusal; değer: o noktadan dairesel.
    var merkez: UnitPoint? = nil
    var yaricap: CGFloat = 520
    var isiklar: [Isik] = []
    var metin: Color
    var vurgu: Color
    /// Birincil düğme rengi ve üstündeki yazı.
    var dolgu: Color
    var dolguMetin: Color = .white
    /// İlerleme çubuğu.
    var cubuk: [Color]
    /// Camın tonu (açık zeminde beyaz, koyu temada kart rengi).
    var kartTon: Color? = nil
    var yildiz: Bool = false
    /// İhya temasında Bahçe'nin tepe, bulut ve çimi.
    var bahceSahnesi = false

    var renkSemasi: ColorScheme { koyu ? .dark : .light }

    func cam(_ ton: Color? = nil, etkilesimli: Bool = false) -> Glass {
        var g = Glass.regular
        if let t = ton { g = g.tint(t) } else if let k = kartTon { g = g.tint(k) }
        return etkilesimli ? g.interactive() : g
    }

    static func dur(_ c: [(String, Double)]) -> [Gradient.Stop] { c.map { Gradient.Stop(color: Color(hex: $0.0), location: $0.1) } }

    static let varsayilan = Palet.ihya(.bugun)

    // İhya temasının sahneleri (renkler tasarım tuvalinden).
    static func ihya(_ s: Sahne) -> Palet {
        let yesil = [Color(hex: "#57D67E"), Color(hex: "#1BA552")]
        let beyazCam = Color.white.opacity(0.24)
        switch s {
        case .bugun, .ayarlar:
            return Palet(koyu: false,
                         duraklar: dur([("#8FD0F7", 0), ("#CBE9FB", 0.32), ("#F2F7FF", 0.62), ("#FFF1DE", 1)]),
                         isiklar: [Isik(renk: Color(r: 255, g: 246, b: 205), x: 0.83, y: 0.17, r: 125),
                                   Isik(renk: Color(r: 120, g: 230, b: 170, a: 0.45), x: 0.18, y: 0.60, r: 130),
                                   Isik(renk: Color(r: 255, g: 160, b: 120, a: 0.40), x: 0.82, y: 0.83, r: 140)],
                         metin: Color(hex: "#12302A"), vurgu: Color(hex: "#0E6A33"), dolgu: Color(hex: "#1FB25A"), cubuk: yesil, kartTon: beyazCam)
        case .bahce:
            return Palet(koyu: false,
                         duraklar: dur([("#6FBDF2", 0), ("#A9DCFA", 0.30), ("#E4F5FF", 0.52), ("#F2FAEC", 0.70), ("#E6F2DF", 1)]),
                         isiklar: [Isik(renk: Color(r: 255, g: 248, b: 210), x: 0.82, y: 0.18, r: 115),
                                   Isik(renk: Color(r: 255, g: 120, b: 150, a: 0.6), x: 0.14, y: 0.72, r: 90),
                                   Isik(renk: Color(r: 255, g: 214, b: 90, a: 0.65), x: 0.64, y: 0.83, r: 105),
                                   Isik(renk: Color(r: 120, g: 170, b: 255, a: 0.55), x: 0.88, y: 0.67, r: 100),
                                   Isik(renk: Color(r: 170, g: 120, b: 255, a: 0.5), x: 0.31, y: 0.93, r: 90)],
                         metin: Color(hex: "#10261A"), vurgu: Color(hex: "#0E5A2C"), dolgu: Color(hex: "#1FB25A"), cubuk: yesil, kartTon: beyazCam, bahceSahnesi: true)
        case .vakit:
            return Palet(koyu: false,
                         duraklar: dur([("#F4B97A", 0), ("#F8D9B0", 0.24), ("#EADFF0", 0.52), ("#DCE6F5", 1)]),
                         isiklar: [Isik(renk: Color(r: 255, g: 240, b: 200, a: 0.9), x: 0.5, y: 0.2, r: 130),
                                   Isik(renk: Color(r: 255, g: 150, b: 90, a: 0.55), x: 0.15, y: 0.6, r: 130),
                                   Isik(renk: Color(r: 110, g: 160, b: 255, a: 0.5), x: 0.85, y: 0.78, r: 140),
                                   Isik(renk: Color(r: 140, g: 220, b: 170, a: 0.5), x: 0.46, y: 0.97, r: 120)],
                         metin: Color(hex: "#0F2233"), vurgu: Color(hex: "#C25E00"), dolgu: Color(hex: "#F08A24"), cubuk: [Color(hex: "#FFC65C"), Color(hex: "#FF9F43")], kartTon: beyazCam)
        case .odak:
            return Palet(koyu: true,
                         duraklar: dur([("#1F6B5A", 0), ("#11403A", 0.45), ("#08201E", 1)]), merkez: UnitPoint(x: 0.5, y: 0.38), yaricap: 520,
                         isiklar: [Isik(renk: Color(r: 90, g: 255, b: 190, a: 0.20), x: 0.23, y: 0.32, r: 150),
                                   Isik(renk: Color(r: 120, g: 200, b: 255, a: 0.16), x: 0.79, y: 0.55, r: 160)],
                         metin: Color(hex: "#F2FFF6"), vurgu: Color(hex: "#9CF5BE"), dolgu: Color(hex: "#1FB25A"), cubuk: [Color(hex: "#7CF0A4"), Color(hex: "#22C463")], yildiz: true)
        case .kitaplik:
            return Palet(koyu: true,
                         duraklar: dur([("#23606A", 0), ("#133844", 0.46), ("#0A1A22", 1)]), merkez: UnitPoint(x: 0.75, y: 0), yaricap: 600,
                         isiklar: [Isik(renk: Color(r: 255, g: 190, b: 90, a: 0.30), x: 0.18, y: 0.46, r: 140),
                                   Isik(renk: Color(r: 150, g: 120, b: 255, a: 0.30), x: 0.82, y: 0.73, r: 150),
                                   Isik(renk: Color(r: 80, g: 230, b: 170, a: 0.24), x: 0.49, y: 0.95, r: 125)],
                         metin: Color(hex: "#F2F8FA"), vurgu: Color(hex: "#FFE08A"), dolgu: Color(hex: "#1FB25A"), cubuk: [Color(hex: "#7CF0A4"), Color(hex: "#22C463")])
        case .sesler:
            return Palet(koyu: true,
                         duraklar: dur([("#0D1B2E", 0), ("#142B45", 0.40), ("#0B1626", 1)]),
                         isiklar: [Isik(renk: Color(r: 80, g: 160, b: 255, a: 0.45), x: 0.18, y: 0.25, r: 150),
                                   Isik(renk: Color(r: 255, g: 140, b: 60, a: 0.38), x: 0.84, y: 0.5, r: 160),
                                   Isik(renk: Color(r: 90, g: 230, b: 160, a: 0.30), x: 0.44, y: 0.84, r: 150)],
                         metin: Color(hex: "#EEF5FF"), vurgu: Color(hex: "#7FC4FF"), dolgu: Color(hex: "#1FB25A"), cubuk: [Color(hex: "#7FC4FF"), Color(hex: "#3B8EF0")])
        case .hadis:
            return Palet(koyu: true,
                         duraklar: dur([("#3B2E8C", 0), ("#1B1745", 0.45), ("#0E0C24", 1)]), merkez: UnitPoint(x: 0.3, y: 0), yaricap: 580,
                         isiklar: [Isik(renk: Color(r: 255, g: 214, b: 120, a: 0.22), x: 0.85, y: 0.26, r: 130),
                                   Isik(renk: Color(r: 255, g: 120, b: 170, a: 0.45), x: 0.2, y: 0.57, r: 120),
                                   Isik(renk: Color(r: 90, g: 200, b: 255, a: 0.40), x: 0.8, y: 0.82, r: 130)],
                         metin: Color(hex: "#F3F1FF"), vurgu: Color(hex: "#FFD66B"), dolgu: Color(hex: "#1FB25A"), cubuk: [Color(hex: "#B7A8FF"), Color(hex: "#6E5BF0")])
        case .zikir:
            return Palet(koyu: true,
                         duraklar: dur([("#1A1850", 0), ("#0D0C2A", 0.5), ("#070816", 1)]), merkez: UnitPoint(x: 0.1, y: 0.04), yaricap: 620,
                         isiklar: [Isik(renk: Color(r: 244, g: 176, b: 74, a: 0.18), x: 0.5, y: 0.52, r: 200),
                                   Isik(renk: Color(r: 79, g: 70, b: 229, a: 0.32), x: 0.1, y: 0.05, r: 220)],
                         metin: Color(hex: "#F5F5F7"), vurgu: Color(hex: "#F4B04A"), dolgu: Color(hex: "#F4B04A"), dolguMetin: Color(hex: "#2A1600"),
                         cubuk: [Color(hex: "#FFD27A"), Color(hex: "#F4B04A")], yildiz: true)
        case .okuma:
            return Palet(koyu: true, duraklar: dur([("#282622", 0), ("#181715", 1)]),
                         isiklar: [Isik(renk: Color(r: 255, g: 200, b: 120, a: 0.10), x: 0.8, y: 0.1, r: 180)],
                         metin: Color(hex: "#EDE6D6"), vurgu: Color(hex: "#E8C77A"), dolgu: Color(hex: "#C99A3A"), cubuk: [Color(hex: "#E8C77A"), Color(hex: "#C99A3A")])
        }
    }

    /// Tek zeminli temalar (Ayarlar tasarımındaki Gece, Fildişi, Lacivert, Zümrüt).
    static func tek(koyu: Bool, taban: String, isik1: Color, isik2: Color, isik3: Color, metin: String, vurgu: String, dolgu: String, dolguMetin: Color, cubuk: String, kart: String) -> Palet {
        Palet(koyu: koyu, duraklar: [Gradient.Stop(color: Color(hex: taban), location: 0), Gradient.Stop(color: Color(hex: taban), location: 1)],
              isiklar: [Isik(renk: isik1, x: 0.12, y: 0.06, r: 380), Isik(renk: isik2, x: 0.9, y: 0.85, r: 340), Isik(renk: isik3, x: 0.78, y: 0.42, r: 190)],
              metin: Color(hex: metin), vurgu: Color(hex: vurgu), dolgu: Color(hex: dolgu), dolguMetin: dolguMetin,
              cubuk: [Color(hex: cubuk).opacity(0.85), Color(hex: cubuk)], kartTon: Color(hex: kart).opacity(koyu ? 0.42 : 0.5), yildiz: koyu)
    }
}

extension Tema {
    func palet(_ s: Sahne) -> Palet {
        switch self {
        case .ihya:
            return Palet.ihya(s)
        case .gece:
            return .tek(koyu: true, taban: "#08080F", isik1: Color(r: 79, g: 70, b: 229, a: 0.36), isik2: Color(r: 59, g: 47, b: 143, a: 0.30), isik3: Color(r: 79, g: 70, b: 229, a: 0.20),
                        metin: "#F5F5F7", vurgu: "#FFD60A", dolgu: "#FFD60A", dolguMetin: Color(hex: "#1A1500"), cubuk: "#4F46E5", kart: "#14141F")
        case .fildisi:
            return .tek(koyu: false, taban: "#F4EFE6", isik1: Color(r: 201, g: 154, b: 0, a: 0.16), isik2: Color(r: 79, g: 70, b: 229, a: 0.08), isik3: Color(r: 201, g: 154, b: 0, a: 0.10),
                        metin: "#1C1A17", vurgu: "#A87B00", dolgu: "#A87B00", dolguMetin: .white, cubuk: "#4F46E5", kart: "#FFFDF8")
        case .lacivert:
            return .tek(koyu: true, taban: "#070D1F", isik1: Color(r: 56, g: 98, b: 255, a: 0.32), isik2: Color(r: 30, g: 60, b: 160, a: 0.30), isik3: Color(r: 56, g: 98, b: 255, a: 0.18),
                        metin: "#F2F5FB", vurgu: "#FFD60A", dolgu: "#FFD60A", dolguMetin: Color(hex: "#1A1500"), cubuk: "#3862FF", kart: "#101A33")
        case .zumrut:
            return .tek(koyu: true, taban: "#04140F", isik1: Color(r: 52, g: 199, b: 89, a: 0.26), isik2: Color(r: 16, g: 120, b: 90, a: 0.30), isik3: Color(r: 52, g: 199, b: 89, a: 0.14),
                        metin: "#EFF7F3", vurgu: "#FFD60A", dolgu: "#FFD60A", dolguMetin: Color(hex: "#1A1500"), cubuk: "#34C759", kart: "#0B231C")
        }
    }

    /// Ayarlar'daki küçük önizleme için taban ve vurgu.
    var onizleme: (taban: Color, vurgu: Color, cubuk: Color, metin: Color) {
        switch self {
        case .ihya: (Color(hex: "#8FD0F7"), Color(hex: "#0E6A33"), Color(hex: "#1BA552"), Color(hex: "#12302A"))
        case .gece: (Color(hex: "#08080F"), Color(hex: "#FFD60A"), Color(hex: "#4F46E5"), Color(hex: "#F5F5F7"))
        case .fildisi: (Color(hex: "#F4EFE6"), Color(hex: "#A87B00"), Color(hex: "#4F46E5"), Color(hex: "#1C1A17"))
        case .lacivert: (Color(hex: "#070D1F"), Color(hex: "#FFD60A"), Color(hex: "#3862FF"), Color(hex: "#F2F5FB"))
        case .zumrut: (Color(hex: "#04140F"), Color(hex: "#FFD60A"), Color(hex: "#34C759"), Color(hex: "#EFF7F3"))
        }
    }
}

extension EnvironmentValues {
    @Entry var palet: Palet = Palet.varsayilan
}

/// Sahnenin zemini: renk geçişi, ışık lekeleri, gerekirse yıldızlar. Ekranın tamamını kaplar, dokunuş almaz.
struct SahneZemini: View {
    let palet: Palet
    var body: some View {
        GeometryReader { g in
            let W = g.size.width, H = g.size.height
            ZStack {
                if let m = palet.merkez {
                    RadialGradient(stops: palet.duraklar, center: m, startRadius: 0, endRadius: palet.yaricap)
                } else {
                    LinearGradient(stops: palet.duraklar, startPoint: .top, endPoint: .bottom)
                }
                ForEach(Array(palet.isiklar.enumerated()), id: \.offset) { _, i in
                    Circle()
                        .fill(RadialGradient(colors: [i.renk, i.renk.opacity(0)], center: .center, startRadius: 0, endRadius: i.r))
                        .frame(width: i.r * 2, height: i.r * 2)
                        .position(x: i.x * W, y: i.y * H)
                }
                if palet.yildiz { YildizAlani().opacity(0.8) }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Gece göğü: sabit tohumlu küçük yıldızlar.
struct YildizAlani: View {
    var body: some View {
        Canvas { ctx, b in
            var s: UInt64 = 0x9E3779B97F4A7C15
            func r() -> CGFloat { s = s &* 6364136223846793005 &+ 1442695040888963407; return CGFloat((s >> 33) % 10_000) / 10_000 }
            for _ in 0..<70 {
                let x = r() * b.width, y = r() * b.height * 0.75, k = 0.6 + r() * 1.6
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: k, height: k)), with: .color(.white.opacity(0.25 + Double(r()) * 0.55)))
            }
        }
    }
}

/// Ekranı sahnesine yerleştirir: zemin, renk şeması, metin ve vurgu rengi, palet ortamı.
struct SahneDuzeni: ViewModifier {
    @Environment(Depo.self) private var depo
    let sahne: Sahne
    func body(content: Content) -> some View {
        let p = depo.ayarlar.tema.palet(sahne)
        content
            .scrollContentBackground(.hidden)
            .foregroundStyle(p.metin)
            .tint(p.vurgu)
            .environment(\.palet, p)
            .environment(\.colorScheme, p.renkSemasi)
            .background { SahneZemini(palet: p) }
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}

extension View {
    func sahne(_ s: Sahne) -> some View { modifier(SahneDuzeni(sahne: s)) }
}

// MARK: Cam bileşenler

/// Liquid Glass kart: içerik kenarlardan 16 pt içeride; cam, sahnenin tonunu alır.
struct CamKart: ViewModifier {
    @Environment(\.palet) private var palet
    var renk: Color? = nil
    var kose: CGFloat = 26
    var ic: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(ic)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(palet.cam(renk.map { $0.opacity(0.18) }), in: .rect(cornerRadius: kose))
    }
}

/// Krem okuma kartı (günün sözü, günün hadisi): koyu zeminde de açık okunur.
struct KremKart: ViewModifier {
    var kose: CGFloat = 26
    var ic: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .foregroundStyle(Color.kremMetin)
            .environment(\.colorScheme, .light)
            .padding(ic)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LinearGradient(colors: [Color(r: 255, g: 253, b: 246, a: 0.92), Color(r: 247, g: 240, b: 224, a: 0.86)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: .rect(cornerRadius: kose))
            .glassEffect(.regular.tint(Color.krem.opacity(0.35)), in: .rect(cornerRadius: kose))
    }
}

extension View {
    func camKart(_ renk: Color? = nil, kose: CGFloat = 26, ic: CGFloat = 16) -> some View { modifier(CamKart(renk: renk, kose: kose, ic: ic)) }
    func kremKart(kose: CGFloat = 26, ic: CGFloat = 16) -> some View { modifier(KremKart(kose: kose, ic: ic)) }
}

/// Bölüm başlığı: küçük, kalın, aralıklı büyük harf.
struct BolumBasligi: View {
    let metin: String
    var simge: String? = nil
    var body: some View {
        HStack(spacing: 6) {
            if let simge { Image(systemName: simge).font(.system(size: 11, weight: .heavy)) }
            Text(metin.uppercased(with: Locale(identifier: "tr_TR"))).font(.kalin(11)).tracking(1)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Kök ekranların büyük başlığı; üstte küçük satır, sağda isteğe bağlı düğmeler.
struct SahneBasligi<Sag: View>: View {
    var ust: String? = nil
    let baslik: String
    @ViewBuilder var sag: () -> Sag

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                if let ust {
                    Text(ust).font(.kalin(12)).tracking(0.8).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.8)
                }
                Text(baslik).font(.system(size: 34, weight: .heavy)).tracking(-0.6).lineLimit(1).minimumScaleFactor(0.7)
            }
            Spacer(minLength: 4)
            sag()
        }
        .padding(.horizontal, 4)
        .padding(.top, 6)
    }
}

extension SahneBasligi where Sag == EmptyView {
    init(ust: String? = nil, baslik: String) { self.init(ust: ust, baslik: baslik) { EmptyView() } }
}

/// Birincil düğme: tonlu Liquid Glass hap.
struct AnaDugme: View {
    @Environment(\.palet) private var palet
    let baslik: String
    var simge: String? = nil
    var yukseklik: CGFloat = 36
    let eylem: () -> Void

    var body: some View {
        Button(action: eylem) {
            HStack(spacing: 8) {
                if let simge { Image(systemName: simge) }
                Text(baslik).tracking(0.6)
            }
            .font(.kalin(16))
            .foregroundStyle(palet.dolguMetin)
            .frame(maxWidth: .infinity, minHeight: yukseklik)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
        .tint(palet.dolgu)
    }
}

/// İkincil düğme: cam hap, renkli yazı.
struct CamDugme: View {
    let baslik: String
    var simge: String? = nil
    var renk: Color? = nil
    var yukseklik: CGFloat = 30
    let eylem: () -> Void

    var body: some View {
        Button(action: eylem) {
            HStack(spacing: 6) {
                if let simge { Image(systemName: simge) }
                Text(baslik)
            }
            .font(.kalin(14))
            .foregroundStyle(renk ?? Color.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, minHeight: yukseklik)
        }
        .buttonStyle(.glass)
        .controlSize(.large)
    }
}

/// Cam şerit içinde kayan seçim (Odak kipleri, hadis bölümleri, dönem).
struct CamSegment<T: Hashable>: View {
    let secenekler: [T]
    @Binding var secili: T
    let ad: (T) -> String
    var yukseklik: CGFloat = 36
    @Environment(\.palet) private var palet
    @Namespace private var alan

    var body: some View {
        HStack(spacing: 0) {
            ForEach(secenekler, id: \.self) { s in
                let on = s == secili
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) { secili = s }
                    Dokunsal.hafif(0.4)
                } label: {
                    Text(ad(s))
                        .font(.kalin(13))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .foregroundStyle(on ? (palet.koyu ? Color(hex: "#0D2B22") : palet.vurgu) : Color.primary)
                        .frame(maxWidth: .infinity, minHeight: yukseklik)
                        .background {
                            if on {
                                Capsule().fill(Color.white.opacity(palet.koyu ? 0.92 : 0.85))
                                    .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                                    .matchedGeometryEffect(id: "secim", in: alan)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(4)
        .glassEffect(palet.cam(), in: .capsule)
    }
}

/// Renk geçişli ilerleme çubuğu.
struct IlerlemeCubugu: View {
    @Environment(\.palet) private var palet
    let oran: Double
    var yukseklik: CGFloat = 8
    var renkler: [Color]? = nil

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.12))
                Capsule()
                    .fill(LinearGradient(colors: renkler ?? palet.cubuk, startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(oran > 0 ? yukseklik : 0, g.size.width * min(1, max(0, oran))))
            }
        }
        .frame(height: yukseklik)
    }
}

/// Kitaplık rozetleri: renk geçişli daire içinde Arapça harf.
struct HarfRozeti: View {
    let harf: String
    let renk1: String
    let renk2: String
    var boyut: CGFloat = 38

    var body: some View {
        Text(harf)
            .font(.arapca(boyut * 0.52, kalin: true))
            .foregroundStyle(.white)
            .frame(width: boyut, height: boyut)
            .background(Circle().fill(LinearGradient(colors: [Color(hex: renk1), Color(hex: renk2)], startPoint: .topLeading, endPoint: .bottomTrailing)))
            .overlay(Circle().strokeBorder(.white.opacity(0.45), lineWidth: 0.6))
            .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
            .accessibilityHidden(true)
    }
}

/// Dokunsal geri bildirim.
@MainActor
enum Dokunsal {
    private static let hafifUretec = UIImpactFeedbackGenerator(style: .light)
    private static let ortaUretec = UIImpactFeedbackGenerator(style: .medium)
    private static let sertUretec = UIImpactFeedbackGenerator(style: .rigid)
    private static let bildirim = UINotificationFeedbackGenerator()

    static func hafif(_ guc: CGFloat = 0.7) { hafifUretec.impactOccurred(intensity: guc) }
    static func orta() { ortaUretec.impactOccurred() }
    static func sert() { sertUretec.impactOccurred() }
    static func basari() { bildirim.notificationOccurred(.success) }
    static func uyari() { bildirim.notificationOccurred(.warning) }

    /// Kilit açılınca: yükselen üç vuruş ve başarı.
    static func kutlama() {
        Task { @MainActor in
            for (i, g) in [0.4, 0.6, 0.85].enumerated() {
                hafifUretec.impactOccurred(intensity: g)
                try? await Task.sleep(nanoseconds: UInt64(90_000_000 + i * 20_000_000))
            }
            sertUretec.impactOccurred()
            try? await Task.sleep(nanoseconds: 120_000_000)
            bildirim.notificationOccurred(.success)
        }
    }
}

/// Uygulamanın ses oturumu: sessiz kipte de duyulur, başka uygulamaların sesini kesmez.
@MainActor
enum SesOturumu {
    static func hazirla() {
        let o = AVAudioSession.sharedInstance()
        try? o.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? o.setActive(true)
    }
}

/// Kısa arayüz sesleri (tesbih, kutlama, ışıltı, bildirim tonu önizlemesi).
@MainActor
enum Efekt {
    private static var oynaticilar: [String: AVAudioPlayer] = [:]

    static func cal(_ ad: String, duzey: Float = 0.8) {
        SesOturumu.hazirla()
        let o: AVAudioPlayer
        if let mevcut = oynaticilar[ad] { o = mevcut } else {
            guard let url = Bundle.main.url(forResource: ad, withExtension: "wav"), let yeni = try? AVAudioPlayer(contentsOf: url) else { return }
            yeni.prepareToPlay()
            oynaticilar[ad] = yeni
            o = yeni
        }
        o.volume = duzey
        o.currentTime = 0
        o.play()
    }
}

/// İslami sekiz köşeli yıldız (Rub'u'l-hizb) motifi.
struct SekizKoseYildiz: Shape {
    var ic: CGFloat = 0.72
    func path(in r: CGRect) -> Path {
        let m = CGPoint(x: r.midX, y: r.midY), R = min(r.width, r.height) / 2
        var p = Path()
        for k in 0..<16 {
            let a = Double(k) * .pi / 8 - .pi / 2
            let rr = k.isMultiple(of: 2) ? R : R * ic
            let n = CGPoint(x: m.x + cos(a) * rr, y: m.y + sin(a) * rr)
            k == 0 ? p.move(to: n) : p.addLine(to: n)
        }
        p.closeSubpath()
        return p
    }
}

/// Arka plan için hafif geometrik desen (yıldız ızgarası).
struct MotifDeseni: View {
    var renk: Color = .ihya
    var aralik: CGFloat = 44
    var body: some View {
        Canvas { ctx, boyut in
            let yildiz = SekizKoseYildiz(ic: 0.62)
            var y: CGFloat = 0, satir = 0
            while y < boyut.height + aralik {
                var x: CGFloat = satir.isMultiple(of: 2) ? 0 : aralik / 2
                while x < boyut.width + aralik {
                    let r = CGRect(x: x - 9, y: y - 9, width: 18, height: 18)
                    ctx.stroke(yildiz.path(in: r), with: .color(renk.opacity(0.16)), lineWidth: 0.8)
                    x += aralik
                }
                y += aralik * 0.75; satir += 1
            }
        }
        .allowsHitTesting(false)
    }
}

/// Kâbe simgesi: SF Symbols ile aynı çizgi kalınlığında özel çizim.
struct KabeSimgesi: View {
    var body: some View {
        Canvas { ctx, b in
            let w = min(b.width, b.height)
            let r = CGRect(x: (b.width - w) / 2 + w * 0.12, y: (b.height - w) / 2 + w * 0.18, width: w * 0.76, height: w * 0.68)
            ctx.fill(Path(roundedRect: r, cornerRadius: w * 0.06), with: .color(.primary))
            let serit = CGRect(x: r.minX, y: r.minY + r.height * 0.22, width: r.width, height: r.height * 0.13)
            ctx.fill(Path(serit), with: .color(Color(red: 0.86, green: 0.70, blue: 0.30)))
        }
    }
}

/// Filiz simgesi (sekme çubuğu ve Odak düğmesi): tasarımdaki iki yapraklı fidan.
struct FilizSimgesi: Shape {
    func path(in r: CGRect) -> Path {
        let s = min(r.width, r.height) / 24
        let o = CGPoint(x: r.midX - 12 * s, y: r.midY - 12 * s)
        func n(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: o.x + x * s, y: o.y + y * s) }
        var p = Path()
        // sol yaprak
        p.move(to: n(12, 14.4))
        p.addCurve(to: n(4, 7.2), control1: n(12, 9.8), control2: n(9, 7.2))
        p.addCurve(to: n(12, 14.4), control1: n(4, 11.8), control2: n(7, 14.4))
        p.closeSubpath()
        // sağ yaprak
        p.move(to: n(12, 11.6))
        p.addCurve(to: n(20, 3.8), control1: n(12, 6.8), control2: n(15, 3.8))
        p.addCurve(to: n(12, 11.6), control1: n(20, 8.6), control2: n(17, 11.6))
        p.closeSubpath()
        // gövde
        p.addRoundedRect(in: CGRect(x: o.x + 11.05 * s, y: o.y + 11.6 * s, width: 1.9 * s, height: 9.8 * s), cornerSize: CGSize(width: 0.95 * s, height: 0.95 * s))
        return p
    }
}

extension Int {
    /// 125 → "2 sa 5 dk"
    var sureMetni: String {
        let s = self / 60, d = self % 60
        if s == 0 { return "\(d) dk" }
        return d == 0 ? "\(s) sa" : "\(s) sa \(d) dk"
    }
}

extension Double {
    var sureMetni: String { Int(self.rounded()).sureMetni }
}

extension DateFormatter {
    static func tr(_ kalip: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = kalip
        return f
    }
}

enum Tarihler {
    static let gunAy = DateFormatter.tr("d MMMM")
    static let gunAyYil = DateFormatter.tr("d MMMM yyyy")
    static let gunAyGun = DateFormatter.tr("d MMMM EEEE")
    static let kisaGun = DateFormatter.tr("d MMM")
    static let ayYil = DateFormatter.tr("LLLL yyyy")
    static let saat = DateFormatter.tr("HH:mm")
    static let haftaGunuKisa = DateFormatter.tr("EEE")
    static let gunAdi = DateFormatter.tr("EEEE")

    /// "SALI · 3 KASIM"
    static func ustSatir(_ t: Date = .now) -> String {
        let tr = Locale(identifier: "tr_TR")
        return "\(gunAdi.string(from: t).uppercased(with: tr)) · \(gunAy.string(from: t).uppercased(with: tr))"
    }
}
