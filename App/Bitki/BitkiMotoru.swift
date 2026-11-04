import JavaScriptCore
import SwiftUI
import UIKit

struct Evre: Hashable {
    let ad: String
    let bas: Double
    let son: Double
}

struct BitkiTuru: Identifiable, Hashable {
    let id: String
    let ad: String
    let agac: Bool
    let dk: Int
    let renk: String
    let sinif: String        // baslangic · siradan · yeni · nadide
    let fiyat: Int
    let not: String
    let evreler: [Evre]      // 120 dakikaya kadar (ek evreler dahil)
    let temel: [Evre]        // tam forma kadar

    var nadide: Bool { sinif == "nadide" }

    /// dk anındaki evre, evre içi ilerleme ve sıradaki evre.
    func evre(_ dk: Double) -> (sira: Int, evre: Evre, ilerleme: Double, sonraki: Evre?) {
        var i = 0
        for (k, e) in evreler.enumerated() where dk >= e.bas { i = k }
        let e = evreler[i]
        let p = max(0, min(1, (dk - e.bas) / max(0.001, e.son - e.bas)))
        return (i, e, p, i + 1 < evreler.count ? evreler[i + 1] : nil)
    }
}

enum BitkiKatalogu {
    static let baslangic = ["karahindiba", "papatya", "cam", "kavak"]
    static var tumu: [BitkiTuru] { BitkiMotoru.ortak.katalog }
    static func bul(_ id: String) -> BitkiTuru? { BitkiMotoru.ortak.katalog.first { $0.id == id } }
    static func ad(_ id: String) -> String { bul(id)?.ad ?? id }
}

/// Bitki çizimleri: Tasarim/motor/bitki.js uygulamada JavaScriptCore ile çalışır, çıktısı Core Graphics ile çizilir.
/// JS bağlamı tek bir seri kuyrukta kullanılır; çizimler bellekte önbelleğe alınır.
final class BitkiMotoru: @unchecked Sendable {
    static let ortak = BitkiMotoru()

    struct Sekil: Decodable {
        let d: String
        let f: String
        let s: String
        let w: Double
        let o: Double
    }

    private struct Gradyan {
        let lineer: Bool
        let a: CGPoint
        let b: CGPoint
        let r: CGFloat
        let gradyan: CGGradient
    }

    private let kuyruk = DispatchQueue(label: "ihya.bitki", qos: .userInitiated)
    private var baglam: JSContext?
    private var gradyanlar: [String: Gradyan] = [:]
    private var yollar: [String: CGPath] = [:]
    private let onbellek = NSCache<NSString, UIImage>()
    private(set) var katalog: [BitkiTuru] = []

    private init() {
        onbellek.countLimit = 260
        kuyruk.sync { kur() }
    }

    private func kur() {
        let b = JSContext()
        b?.exceptionHandler = { _, hata in print("bitki.js hata:", hata?.toString() ?? "") }
        if let url = Bundle.main.url(forResource: "bitki", withExtension: "js"), let kod = try? String(contentsOf: url, encoding: .utf8) {
            b?.evaluateScript(kod)
        }
        baglam = b
        if let json = b?.evaluateScript("JSON.stringify(bitkiKatalog())")?.toString(), let veri = json.data(using: .utf8),
           let dizi = try? JSONSerialization.jsonObject(with: veri) as? [[String: Any]] {
            katalog = dizi.compactMap(BitkiMotoru.tur)
        }
        if let url = Bundle.main.url(forResource: "gradients", withExtension: "json"), let veri = try? Data(contentsOf: url),
           let tablo = try? JSONSerialization.jsonObject(with: veri) as? [String: [String: Any]] {
            for (id, g) in tablo { if let x = BitkiMotoru.gradyan(g) { gradyanlar[id] = x } }
        }
    }

    private static func tur(_ d: [String: Any]) -> BitkiTuru? {
        guard let id = d["id"] as? String, let ad = d["ad"] as? String else { return nil }
        func evreler(_ x: Any?) -> [Evre] {
            (x as? [[Any]] ?? []).compactMap { e in
                guard e.count == 3, let a = e[0] as? String, let b = (e[1] as? NSNumber)?.doubleValue, let s = (e[2] as? NSNumber)?.doubleValue else { return nil }
                return Evre(ad: a, bas: b, son: s)
            }
        }
        return BitkiTuru(id: id, ad: ad, agac: (d["tur"] as? String) == "Ağaç", dk: (d["dk"] as? NSNumber)?.intValue ?? 25,
                         renk: d["renk"] as? String ?? "#27AE60", sinif: d["sinif"] as? String ?? "siradan",
                         fiyat: (d["fiyat"] as? NSNumber)?.intValue ?? 0, not: d["not"] as? String ?? "",
                         evreler: evreler(d["evre"]), temel: evreler(d["temel"]))
    }

    private static func gradyan(_ g: [String: Any]) -> Gradyan? {
        guard let duraklar = g["s"] as? [[Any]] else { return nil }
        var renkler: [CGColor] = [], konumlar: [CGFloat] = []
        for d in duraklar where d.count == 3 {
            guard let o = (d[0] as? NSNumber)?.doubleValue, let hex = d[1] as? String, let a = (d[2] as? NSNumber)?.doubleValue else { continue }
            konumlar.append(o)
            renkler.append(renk(hex, a))
        }
        guard let cg = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: renkler as CFArray, locations: konumlar) else { return nil }
        func n(_ k: String, _ v: Double) -> CGFloat { CGFloat((g[k] as? NSNumber)?.doubleValue ?? v) }
        if (g["t"] as? String) == "l" {
            return Gradyan(lineer: true, a: CGPoint(x: n("x1", 0), y: n("y1", 0)), b: CGPoint(x: n("x2", 1), y: n("y2", 0)), r: 0, gradyan: cg)
        }
        return Gradyan(lineer: false, a: CGPoint(x: n("cx", 0.5), y: n("cy", 0.5)), b: .zero, r: n("r", 0.5), gradyan: cg)
    }

    private static func renk(_ hex: String, _ alfa: Double = 1) -> CGColor {
        var s = hex
        if s.hasPrefix("#") { s.removeFirst() }
        if s.count == 3 { s = s.map { "\($0)\($0)" }.joined() }
        let v = UInt64(s, radix: 16) ?? 0
        return CGColor(srgbRed: CGFloat((v >> 16) & 0xFF) / 255, green: CGFloat((v >> 8) & 0xFF) / 255, blue: CGFloat(v & 0xFF) / 255, alpha: CGFloat(alfa))
    }

    // MARK: Çizim verisi

    private func sekiller(_ tur: String, _ dk: Double, _ tohum: Int, _ lod: Double) -> [Sekil] {
        guard let f = baglam?.objectForKeyedSubscript("bitkiJSON"),
              let json = f.call(withArguments: [tur, dk, tohum, lod])?.toString(), let veri = json.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([Sekil].self, from: veri)) ?? []
    }

    /// "Gül fidanı · 1 çiçek" gibi kısa özet (bitki.js bitkiOzet).
    func ozet(tur: String, dk: Double) -> String {
        kuyruk.sync {
            baglam?.objectForKeyedSubscript("bitkiOzet")?.call(withArguments: [tur, dk])?.toString() ?? BitkiKatalogu.ad(tur)
        }
    }

    private func yol(_ d: String) -> CGPath {
        if let y = yollar[d] { return y }
        let y = BitkiMotoru.yolCoz(d)
        if yollar.count > 6000 { yollar.removeAll(keepingCapacity: true) }
        yollar[d] = y
        return y
    }

    /// Bitkinin çizim birimlerindeki sınır kutusu (gölge dahil).
    func sinir(tur: String, dk: Double, tohum: Int) async -> CGRect {
        await withCheckedContinuation { devam in
            kuyruk.async {
                var r = CGRect.null
                for s in self.sekiller(tur, dk, tohum, 0.5) {
                    let y = self.yol(s.d)
                    let b = s.s != "none" && s.w > 0 ? y.copy(strokingWithWidth: s.w, lineCap: .round, lineJoin: .round, miterLimit: 4).boundingBoxOfPath : y.boundingBoxOfPath
                    if !b.isNull { r = r.union(b) }
                }
                devam.resume(returning: r.isNull ? CGRect(x: 0, y: 0, width: 100, height: 120) : r)
            }
        }
    }

    /// Bitkiyi verilen boyutta (pt) ve çerçevede (çizim birimi) çizer.
    /// sigdir: çerçeveyi yok sayar, bitkinin kendi sınırına göre kadrajlar (küçük simgeler için).
    func resim(tur: String, dk: Double, tohum: Int, boyut: CGSize, olcek: CGFloat, cerceve: CGRect, lod: Double = 1, sigdir: Bool = false) async -> UIImage? {
        guard boyut.width > 1, boyut.height > 1 else { return nil }
        let anahtar = "\(tur)|\(Int(dk * 20))|\(tohum)|\(Int(boyut.width))x\(Int(boyut.height))|\(Int(cerceve.minX)),\(Int(cerceve.minY)),\(Int(cerceve.width)),\(Int(cerceve.height))|\(lod)|\(sigdir)" as NSString
        if let r = onbellek.object(forKey: anahtar) { return r }
        return await withCheckedContinuation { devam in
            kuyruk.async {
                if let r = self.onbellek.object(forKey: anahtar) { devam.resume(returning: r); return }
                let sekil = self.sekiller(tur, dk, tohum, lod)
                let w = Int((boyut.width * olcek).rounded()), h = Int((boyut.height * olcek).rounded())
                guard let uzay = CGColorSpace(name: CGColorSpace.sRGB),
                      let c = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: uzay,
                                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { devam.resume(returning: nil); return }
                c.translateBy(x: 0, y: CGFloat(h))
                c.scaleBy(x: olcek, y: -olcek)
                self.ciz(sekil, c, boyut: boyut, cerceve: sigdir ? self.kadraj(sekil, oran: boyut.width / boyut.height) : cerceve)
                guard let cg = c.makeImage() else { devam.resume(returning: nil); return }
                let resim = UIImage(cgImage: cg, scale: olcek, orientation: .up)
                self.onbellek.setObject(resim, forKey: anahtar)
                devam.resume(returning: resim)
            }
        }
    }

    /// Şekillerin sınırına (gölge hariç) göre, alt kenarı koruyarak istenen orana genişletilmiş kadraj.
    private func kadraj(_ sekiller: [Sekil], oran: CGFloat) -> CGRect {
        var r = CGRect.null
        for s in sekiller where s.f != "url(#gGolge)" {
            let y = yol(s.d)
            let b = s.s != "none" && s.w > 0 ? y.boundingBoxOfPath.insetBy(dx: -s.w / 2, dy: -s.w / 2) : y.boundingBoxOfPath
            if !b.isNull, b.width.isFinite { r = r.union(b) }
        }
        guard !r.isNull, r.width > 0.5, r.height > 0.5 else { return CGRect(x: 0, y: 0, width: 100, height: 120) }
        var b = r.insetBy(dx: -max(1.5, r.width * 0.08), dy: -max(1.5, r.height * 0.06))
        if b.width / b.height < oran {
            let w = b.height * oran
            b = CGRect(x: b.midX - w / 2, y: b.minY, width: w, height: b.height)
        } else {
            let h = b.width / oran
            b = CGRect(x: b.minX, y: b.maxY - h, width: b.width, height: h)
        }
        return b
    }

    private func ciz(_ sekiller: [Sekil], _ c: CGContext, boyut: CGSize, cerceve: CGRect) {
        let s = min(boyut.width / cerceve.width, boyut.height / cerceve.height)
        c.translateBy(x: (boyut.width - cerceve.width * s) / 2 - cerceve.minX * s, y: (boyut.height - cerceve.height * s) / 2 - cerceve.minY * s)
        c.scaleBy(x: s, y: s)
        c.setLineCap(.round)
        c.setLineJoin(.round)
        for sk in sekiller {
            let y = yol(sk.d)
            c.saveGState()
            c.setAlpha(CGFloat(sk.o))
            if sk.f.hasPrefix("url(#") {
                let id = String(sk.f.dropFirst(5).dropLast())
                if let g = gradyanlar[id] {
                    let bb = y.boundingBoxOfPath
                    if bb.width > 0.001, bb.height > 0.001 {
                        c.saveGState()
                        c.addPath(y)
                        c.clip()
                        c.translateBy(x: bb.minX, y: bb.minY)
                        c.scaleBy(x: bb.width, y: bb.height)
                        if g.lineer {
                            c.drawLinearGradient(g.gradyan, start: g.a, end: g.b, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
                        } else {
                            c.drawRadialGradient(g.gradyan, startCenter: g.a, startRadius: 0, endCenter: g.a, endRadius: g.r, options: [.drawsAfterEndLocation])
                        }
                        c.restoreGState()
                    }
                }
            } else if sk.f != "none" {
                c.setFillColor(BitkiMotoru.renk(sk.f))
                c.addPath(y)
                c.fillPath()
            }
            if sk.s != "none", sk.w > 0 {
                c.setStrokeColor(BitkiMotoru.renk(sk.s))
                c.setLineWidth(CGFloat(sk.w))
                c.addPath(y)
                c.strokePath()
            }
            c.restoreGState()
        }
    }

    /// SVG yol dili (M L Q C Z ve göreli m l h v q c) → CGPath.
    static func yolCoz(_ d: String) -> CGPath {
        let b = Array(d.utf8), n = b.count
        let yol = CGMutablePath()
        var i = 0, komut: UInt8 = 0
        var simdi = CGPoint.zero, bas = CGPoint.zero
        func ayirac(_ c: UInt8) -> Bool { c == 32 || c == 44 || c == 10 || c == 13 || c == 9 }
        func harf(_ c: UInt8) -> Bool { (c >= 65 && c <= 90) || (c >= 97 && c <= 122) }
        func sayi() -> CGFloat? {
            while i < n, ayirac(b[i]) { i += 1 }
            guard i < n else { return nil }
            let s = i
            if b[i] == 45 || b[i] == 43 { i += 1 }
            var nokta = false, rakam = false
            while i < n {
                let c = b[i]
                if c >= 48 && c <= 57 { rakam = true; i += 1 } else if c == 46 && !nokta { nokta = true; i += 1 } else { break }
            }
            if i < n, b[i] == 101 || b[i] == 69 {
                var j = i + 1
                if j < n, b[j] == 45 || b[j] == 43 { j += 1 }
                if j < n, b[j] >= 48 && b[j] <= 57 { i = j; while i < n, b[i] >= 48 && b[i] <= 57 { i += 1 } }
            }
            guard rakam else { i = s; return nil }
            return CGFloat(Double(String(decoding: b[s..<i], as: UTF8.self)) ?? 0)
        }
        while i < n {
            let c = b[i]
            if ayirac(c) { i += 1; continue }
            if harf(c) {
                komut = c; i += 1
                if c == 90 || c == 122 { yol.closeSubpath(); simdi = bas }
                continue
            }
            let once = i
            switch komut {
            case 77, 109: // M m
                if let x = sayi(), let y = sayi() {
                    simdi = komut == 109 ? CGPoint(x: simdi.x + x, y: simdi.y + y) : CGPoint(x: x, y: y)
                    yol.move(to: simdi); bas = simdi
                    komut = komut == 109 ? 108 : 76
                }
            case 76, 108: // L l
                if let x = sayi(), let y = sayi() {
                    simdi = komut == 108 ? CGPoint(x: simdi.x + x, y: simdi.y + y) : CGPoint(x: x, y: y)
                    yol.addLine(to: simdi)
                }
            case 72, 104: // H h
                if let x = sayi() { simdi.x = komut == 104 ? simdi.x + x : x; yol.addLine(to: simdi) }
            case 86, 118: // V v
                if let y = sayi() { simdi.y = komut == 118 ? simdi.y + y : y; yol.addLine(to: simdi) }
            case 81, 113: // Q q
                if let x1 = sayi(), let y1 = sayi(), let x = sayi(), let y = sayi() {
                    let o = komut == 113 ? simdi : .zero
                    let k = CGPoint(x: o.x + x1, y: o.y + y1)
                    simdi = CGPoint(x: o.x + x, y: o.y + y)
                    yol.addQuadCurve(to: simdi, control: k)
                }
            case 67, 99: // C c
                if let x1 = sayi(), let y1 = sayi(), let x2 = sayi(), let y2 = sayi(), let x = sayi(), let y = sayi() {
                    let o = komut == 99 ? simdi : .zero
                    let k1 = CGPoint(x: o.x + x1, y: o.y + y1), k2 = CGPoint(x: o.x + x2, y: o.y + y2)
                    simdi = CGPoint(x: o.x + x, y: o.y + y)
                    yol.addCurve(to: simdi, control1: k1, control2: k2)
                }
            default:
                break
            }
            if i == once { i += 1 } // çözülemeyen karakteri atla; sonsuz döngüye girme
        }
        return yol
    }
}

/// Bitki görseli: arka planda çizilir, hazır olunca görünür; yeni çizim gelene kadar eskisi kalır.
struct BitkiResmi: View {
    let tur: String
    var dk: Double
    var tohum: Int = 7
    var cerceve: CGRect = CGRect(x: 0, y: 0, width: 100, height: 120)
    var lod: Double = 1
    var kurudu = false
    var siluet = false
    var sigdir = false

    @Environment(\.displayScale) private var olcek
    @State private var resim: UIImage?

    var body: some View {
        GeometryReader { geo in
            let anahtar = "\(tur)|\(Int(dk * 20))|\(tohum)|\(Int(geo.size.width))x\(Int(geo.size.height))|\(cerceve.debugDescription)|\(lod)|\(sigdir)"
            Group {
                if let resim {
                    Image(uiImage: resim)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                } else {
                    Color.clear
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .task(id: anahtar) {
                let r = await BitkiMotoru.ortak.resim(tur: tur, dk: dk, tohum: tohum, boyut: geo.size, olcek: olcek, cerceve: cerceve, lod: lod, sigdir: sigdir)
                if let r { resim = r }
            }
        }
        .saturation(kurudu ? 0.15 : 1)
        .colorMultiply(kurudu ? Color(red: 0.82, green: 0.68, blue: 0.52) : .white)
        .brightness(siluet ? -1 : 0)
        .opacity(siluet ? 0.3 : 1)
    }
}
