import Foundation

/// Uygulama ile widget'ların ortak klasörü (App Group).
/// SideStore/AltStore grup kimliğini hesabın takımına göre yeniden adlandırır ve gerçek adı Info.plist'e "ALTAppGroups" olarak yazar.
enum Paylasim {
    static let grupVarsayilan = "group.com.burakmert36.ihya"

    static var grup: String {
        (Bundle.main.object(forInfoDictionaryKey: "ALTAppGroups") as? [String])?.first ?? grupVarsayilan
    }

    static var klasor: URL? { FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: grup) }
    static var veriDosyasi: URL? { klasor?.appendingPathComponent("widget.json") }
    static var bitkiResmi: URL? { klasor?.appendingPathComponent("bitki.png") }

    static func oku() -> WidgetVerisi? {
        guard let u = veriDosyasi, let d = try? Data(contentsOf: u) else { return nil }
        return try? JSONDecoder().decode(WidgetVerisi.self, from: d)
    }
}

/// Widget'ların gösterdiği özet; uygulama her değişiklikte yazar.
struct WidgetVerisi: Codable, Hashable {
    var guncelleme: Date
    var seri: Int
    var rahmet: Int
    var bugunDikildi: Bool
    /// Seri kırıldıysa kurtarmak için kalan dikim.
    var telafi: Int?
    var bugunDk: Int
    var hedefDk: Int
    var bugunFidan: Int
    var sonBitki: String?
    var namazKilinan: Int
    var konum: String
    var hicri: String
    /// Bugünden başlayarak birkaç günün vakitleri (imsak, güneş, öğle, ikindi, akşam, yatsı).
    var vakitler: [WidgetVakti]

    static let ornek = WidgetVerisi(
        guncelleme: .now, seri: 12, rahmet: 1, bugunDikildi: true, telafi: nil, bugunDk: 45, hedefDk: 60, bugunFidan: 2,
        sonBitki: "Gül", namazKilinan: 3, konum: "Bursa", hicri: "24 Cemâziyelevvel 1448",
        vakitler: (0..<6).map { WidgetVakti(ad: ["İmsak", "Güneş", "Öğle", "İkindi", "Akşam", "Yatsı"][$0], zaman: Date().addingTimeInterval(Double($0) * 3 * 3600 - 3 * 3600)) }
    )

    /// Verilen andan sonraki ilk vakit ve ondan önceki.
    func sonraki(_ an: Date) -> (onceki: WidgetVakti?, sonraki: WidgetVakti)? {
        guard let i = vakitler.firstIndex(where: { $0.zaman > an }) else { return nil }
        return (i > 0 ? vakitler[i - 1] : nil, vakitler[i])
    }
}

struct WidgetVakti: Codable, Hashable {
    var ad: String
    var zaman: Date
}
