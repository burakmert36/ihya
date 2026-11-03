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

    static let ihya = Color.accentColor
    static let toprak = Color(red: 0.55, green: 0.38, blue: 0.24)
}

extension Font {
    static func arapca(_ boyut: CGFloat, kalin: Bool = false) -> Font { .custom(kalin ? "Amiri-Bold" : "Amiri-Regular", size: boyut) }
    static func okuma(_ boyut: CGFloat) -> Font { .system(size: boyut, weight: .regular, design: .serif) }
}

extension Tema {
    var renkSemasi: ColorScheme? { self == .sistem ? nil : self == .acik ? .light : .dark }
}

/// Liquid Glass kart: içerik kenarlarından 16 pt içeride, köşeler 22 pt.
struct CamKart: ViewModifier {
    var renk: Color? = nil
    var kose: CGFloat = 22
    private var cam: Glass {
        if let renk { return Glass.regular.tint(renk.opacity(0.18)) }
        return Glass.regular
    }

    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(cam, in: .rect(cornerRadius: kose))
    }
}

extension View {
    func camKart(_ renk: Color? = nil, kose: CGFloat = 22) -> some View { modifier(CamKart(renk: renk, kose: kose)) }
}

/// Bölüm başlığı: küçük, sakin, büyük harfsiz.
struct BolumBasligi: View {
    let metin: String
    var simge: String? = nil
    var body: some View {
        HStack(spacing: 6) {
            if let simge { Image(systemName: simge).font(.footnote.weight(.semibold)) }
            Text(metin).font(.footnote.weight(.semibold))
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
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

/// Kısa arayüz sesleri (tesbih, kutlama, ışıltı). Sessiz anahtarına uyar.
@MainActor
enum Efekt {
    private static var oynaticilar: [String: AVAudioPlayer] = [:]

    static func cal(_ ad: String, duzey: Float = 0.8) {
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
}
