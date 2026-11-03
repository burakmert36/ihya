import Foundation

struct Hadis: Codable, Identifiable, Hashable {
    let no: Int
    let kitap: String
    let konu: String
    let ravi: String
    let metin: String
    let kaynak: String
    let link: String
    var id: Int { no }
}

struct Soz: Codable, Identifiable, Hashable {
    let grup: String
    let kisi: String
    let soz: String
    let kaynak: String
    var id: String { kaynak + "|" + String(soz.prefix(32)) }
    var ayetMi: Bool { kaynak.hasPrefix("Kur'ân") }
}

private struct HikmetDosyasi: Codable { let sozler: [Soz] }

struct Dua: Codable, Identifiable, Hashable {
    let id: String
    let baslik: String
    let arapca: String?
    let okunus: String
    let anlam: String
    let kaynak: String
    let not: String?
}

struct DuaTemasi: Codable, Identifiable, Hashable {
    let id: String
    let ad: String
    let simge: String
    let dualar: [Dua]
}

struct DefterOgesi: Codable, Hashable {
    let baslik: String
    let okunus: String?
    let anlam: String?
    let not: String?
    let tekrar: Int?
}

struct VakiaAyeti: Codable, Hashable { let no: Int; let okunus: String }

struct DefterBolumu: Codable, Identifiable, Hashable {
    let baslik: String
    let aciklama: String?
    let ogeler: [DefterOgesi]?
    let ayetler: [VakiaAyeti]?
    let metin: String?
    var id: String { baslik }
}

struct DuaDefteri: Codable, Hashable {
    let baslik: String
    let giris: [DefterOgesi]
    let bolumler: [DefterBolumu]
    let kapanis: DefterOgesi
}

private struct DualarDosyasi: Codable { let temalar: [DuaTemasi]; let defter: DuaDefteri }

struct EsmaIsmi: Codable, Identifiable, Hashable {
    let no: Int
    let ad: String
    let arapca: String
    let anlam: String
    let aciklama: String
    var id: Int { no }
}

struct DiniGun: Codable, Identifiable, Hashable {
    let tarih: String
    let ad: String
    let tur: String
    let aciklama: String
    var id: String { tarih + ad }
    var gun: Date {
        let p = tarih.split(separator: "-").compactMap { Int($0) }
        return Calendar.current.date(from: DateComponents(year: p[0], month: p[1], day: p[2])) ?? .distantPast
    }
}

private struct DiniGunDosyasi: Codable { let kaynak: String; let gunler: [DiniGun] }

/// Pakete gömülü içerik. Her dosya ilk kullanımda bir kez okunur.
enum Icerik {
    private static func oku<T: Decodable>(_ ad: String, _ tur: T.Type) -> T? {
        guard let url = Bundle.main.url(forResource: ad, withExtension: "json"), let veri = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: veri)
    }

    static let hadisler: [Hadis] = oku("hadisler", [Hadis].self) ?? []
    static let sozler: [Soz] = oku("hikmetler", HikmetDosyasi.self)?.sozler ?? []
    private static let dualarDosyasi = oku("dualar", DualarDosyasi.self)
    static let duaTemalari: [DuaTemasi] = dualarDosyasi?.temalar ?? []
    static let duaDefteri: DuaDefteri? = dualarDosyasi?.defter
    static let esma: [EsmaIsmi] = oku("esma", [EsmaIsmi].self) ?? []
    static let diniGunler: [DiniGun] = oku("dinigunler", DiniGunDosyasi.self)?.gunler ?? []

    static var hadisKonulari: [String] {
        var gorulen = Set<String>(), sira: [String] = []
        for h in hadisler where gorulen.insert(h.konu).inserted { sira.append(h.konu) }
        return sira
    }

    static func dua(_ id: String) -> Dua? { duaTemalari.lazy.flatMap(\.dualar).first { $0.id == id } }

    /// Güne göre değişen ama gün içinde sabit kalan seçim.
    static func gunun<T>(_ liste: [T], tarih: Date = .now, kaydir: Int = 0) -> T? {
        guard !liste.isEmpty else { return nil }
        let gun = Calendar.current.ordinality(of: .day, in: .era, for: tarih) ?? 0
        return liste[(gun * 7 + kaydir) % liste.count]
    }
}
