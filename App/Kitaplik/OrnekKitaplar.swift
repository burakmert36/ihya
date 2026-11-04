import PDFKit
import UIKit

/// CI ekran görüntüleri için örnek PDF kitaplar (yalnız ekran görüntüsü kipinde üretilir).
enum OrnekKitaplar {
    static let ilk = UUID(uuidString: "0000000B-0000-4000-8000-000000000001")!

    private struct Tanim {
        let no: Int
        let ad: String
        let yazar: String
        let renk: (UIColor, UIColor)
        let sayfa: Int
        let okunan: Int
        let gunOnce: Double
        let bitti: Bool
        let sn: Double
    }

    private static let tanimlar: [Tanim] = [
        Tanim(no: 1, ad: "Kimyâ-yı Saâdet", yazar: "İmam Gazâlî", renk: (renk("#0F4C3A"), renk("#06281F")), sayfa: 24, okunan: 9, gunOnce: 0.1, bitti: false, sn: 5400),
        Tanim(no: 2, ad: "Mesnevî'den Hikâyeler", yazar: "Mevlânâ", renk: (renk("#6E1F2A"), renk("#3D0F17")), sayfa: 18, okunan: 2, gunOnce: 2, bitti: false, sn: 900),
        Tanim(no: 3, ad: "Kutadgu Bilig", yazar: "Yûsuf Has Hâcib", renk: (renk("#1F3A6E"), renk("#0F1D3D")), sayfa: 30, okunan: 0, gunOnce: 1, bitti: false, sn: 0),
        Tanim(no: 4, ad: "Siyer Notları", yazar: "Okuma defteri", renk: (renk("#8A5A2B"), renk("#4A2E14")), sayfa: 14, okunan: 0, gunOnce: 6, bitti: false, sn: 0),
        Tanim(no: 5, ad: "Edebü'd-Dünyâ ve'd-Dîn", yazar: "Mâverdî", renk: (renk("#4B2E6E"), renk("#24153A")), sayfa: 20, okunan: 19, gunOnce: 12, bitti: true, sn: 14_400),
        Tanim(no: 6, ad: "Kâbûsnâme", yazar: "Keykâvus", renk: (renk("#2E5E3A"), renk("#173020")), sayfa: 16, okunan: 15, gunOnce: 20, bitti: true, sn: 9000),
    ]

    static func hazirla() -> [Kitap] {
        tanimlar.map { t in
            let dosya = "ornek-\(t.no).pdf"
            let url = KitapDeposu.klasor.appendingPathComponent(dosya)
            if !FileManager.default.fileExists(atPath: url.path) { yaz(t, url) }
            var k = Kitap(ad: t.ad, dosya: dosya, sayfa: t.okunan, toplam: t.sayfa)
            k.id = UUID(uuidString: String(format: "0000000B-0000-4000-8000-%012d", t.no))!
            k.eklenme = Date().addingTimeInterval(-(t.gunOnce + 3) * 86400)
            k.son = t.okunan > 0 ? Date().addingTimeInterval(-t.gunOnce * 86400) : nil
            k.bitti = t.bitti
            k.okumaSn = t.sn
            if t.no == 1 { k.yerImleri = [3, 7] }
            return k
        }
    }

    private static func renk(_ hex: String) -> UIColor {
        var v: UInt64 = 0
        Scanner(string: hex.replacingOccurrences(of: "#", with: "")).scanHexInt64(&v)
        return UIColor(red: CGFloat((v >> 16) & 255) / 255, green: CGFloat((v >> 8) & 255) / 255, blue: CGFloat(v & 255) / 255, alpha: 1)
    }

    private static let paragraflar = [
        "Okumak, insanın kendi içine açılan bir kapıdır. Sayfalar ilerledikçe zihin sakinleşir, dağınık düşünceler bir araya gelir.",
        "Bu örnek sayfa, kitap okuyucunun görünümünü göstermek için yazıldı. Yazıyı büyütebilir, sayfaları yana ya da aşağı çevirebilir, geceleri mavi ışığı azaltabilirsin.",
        "İlim, az da olsa her gün yapılan okumayla derinleşir. Kaldığın sayfa hatırlanır; yer imi koyduğun sayfalara içindekiler bölümünden dönebilirsin.",
        "Güzel bir kitap, iyi bir dost gibidir: sabırla dinler, yeri geldiğinde yol gösterir. Her bölümün sonunda kısa bir mola vermek okunanı yerleştirir.",
    ]

    private static func yaz(_ t: Tanim, _ url: URL) {
        let boyut = CGRect(x: 0, y: 0, width: 420, height: 620)
        let r = UIGraphicsPDFRenderer(bounds: boyut)
        try? r.writePDF(to: url) { c in
            // Kapak
            c.beginPage()
            let g = c.cgContext
            let renkler = [t.renk.0.cgColor, t.renk.1.cgColor] as CFArray
            if let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: renkler, locations: [0, 1]) {
                g.drawLinearGradient(grad, start: .zero, end: CGPoint(x: 0, y: boyut.height), options: [])
            }
            let altin = renk("#E9C46A")
            altin.setStroke()
            UIBezierPath(rect: boyut.insetBy(dx: 22, dy: 22)).stroke()
            let ic = UIBezierPath(rect: boyut.insetBy(dx: 30, dy: 30))
            ic.lineWidth = 0.6
            ic.stroke()
            yildiz(g, merkez: CGPoint(x: boyut.midX, y: 220), r: 54, renk: altin)
            let ortala = NSMutableParagraphStyle()
            ortala.alignment = .center
            let baslik = NSAttributedString(string: t.ad, attributes: [
                .font: UIFont(descriptor: UIFont.systemFont(ofSize: 30, weight: .bold).fontDescriptor.withDesign(.serif)!, size: 30),
                .foregroundColor: renk("#F6E7C1"), .paragraphStyle: ortala])
            baslik.draw(in: CGRect(x: 40, y: 320, width: boyut.width - 80, height: 120))
            NSAttributedString(string: t.yazar.uppercased(with: Locale(identifier: "tr_TR")), attributes: [
                .font: UIFont.systemFont(ofSize: 12, weight: .heavy), .kern: 2, .foregroundColor: altin, .paragraphStyle: ortala])
                .draw(in: CGRect(x: 40, y: 520, width: boyut.width - 80, height: 24))
            // İç sayfalar
            let govde: [NSAttributedString.Key: Any] = [
                .font: UIFont(descriptor: UIFont.systemFont(ofSize: 13).fontDescriptor.withDesign(.serif)!, size: 13),
                .foregroundColor: UIColor(white: 0.12, alpha: 1)]
            for s in 1..<t.sayfa {
                c.beginPage()
                if s % 5 == 1 {
                    NSAttributedString(string: "\(s / 5 + 1). Bölüm", attributes: [
                        .font: UIFont(descriptor: UIFont.systemFont(ofSize: 22, weight: .bold).fontDescriptor.withDesign(.serif)!, size: 22),
                        .foregroundColor: UIColor(white: 0.1, alpha: 1)]).draw(at: CGPoint(x: 44, y: 50))
                }
                var y: CGFloat = s % 5 == 1 ? 100 : 54
                for i in 0..<5 {
                    let m = NSAttributedString(string: paragraflar[(s + i) % paragraflar.count], attributes: govde)
                    let h = m.boundingRect(with: CGSize(width: boyut.width - 88, height: 400), options: .usesLineFragmentOrigin, context: nil).height
                    m.draw(in: CGRect(x: 44, y: y, width: boyut.width - 88, height: h + 4))
                    y += h + 14
                }
                NSAttributedString(string: "\(s + 1)", attributes: [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.gray])
                    .draw(at: CGPoint(x: boyut.midX - 4, y: boyut.height - 34))
            }
        }
        // Bölüm başlıkları (içindekiler)
        guard let d = PDFDocument(url: url) else { return }
        let kok = PDFOutline()
        for (i, s) in stride(from: 1, to: t.sayfa, by: 5).enumerated() {
            guard let p = d.page(at: s) else { continue }
            let o = PDFOutline()
            o.label = "\(i + 1). Bölüm"
            o.destination = PDFDestination(page: p, at: CGPoint(x: 0, y: p.bounds(for: .mediaBox).maxY))
            kok.insertChild(o, at: i)
        }
        d.outlineRoot = kok
        d.write(to: url)
    }

    private static func yildiz(_ g: CGContext, merkez m: CGPoint, r: CGFloat, renk: UIColor) {
        let p = UIBezierPath()
        for k in 0..<16 {
            let a = CGFloat(k) * .pi / 8 - .pi / 2
            let rr = k % 2 == 0 ? r : r * 0.72
            let n = CGPoint(x: m.x + cos(a) * rr, y: m.y + sin(a) * rr)
            k == 0 ? p.move(to: n) : p.addLine(to: n)
        }
        p.close()
        renk.setStroke()
        p.lineWidth = 1.5
        p.stroke()
        UIBezierPath(ovalIn: CGRect(x: m.x - r * 0.3, y: m.y - r * 0.3, width: r * 0.6, height: r * 0.6)).stroke()
    }
}
