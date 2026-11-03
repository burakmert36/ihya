import Foundation
import Observation

/// Bir günün altı vakti: imsak, güneş, öğle, ikindi, akşam, yatsı ("HH:mm").
struct GunVakti: Codable, Hashable {
    let gun: String          // yyyy-MM-dd
    let saatler: [String]
    let hicri: String
}

enum VakitSabit {
    static let ilceKodu = 9335 // Bursa merkez
    static var onbellekDosyasi: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("vakitler.json")
    }
}

enum VakitAdi {
    static let adlar = ["İmsak", "Güneş", "Öğle", "İkindi", "Akşam", "Yatsı"]
    /// "İkindi Vaktine", "Akşam Vaktine" (başlıklar için)
    static func vaktine(_ i: Int) -> String { adlar[i] + " Vaktine" }
    /// Namaz takibi için beş vakit (güneş hariç): vakit sırası → takip sırası
    static let namazlar = [(0, "Sabah"), (2, "Öğle"), (3, "İkindi"), (4, "Akşam"), (5, "Yatsı")]
}

/// Diyanet vakitlerini sağlar: önce indirilen takvim (ezanvakti.emushaf.net), yoksa pakete gömülü takvim,
/// o da yoksa güneşin konumundan hesap. Konum kipi "cihaz" ise doğrudan hesaplar.
@MainActor
@Observable
final class VakitServisi {
    private(set) var takvim: [String: GunVakti] = [:]
    private(set) var kip: KonumKipi = .bursa
    private(set) var enlem = 40.1826
    private(set) var boylam = 29.0665
    private(set) var konumAdi = "Bursa"


    init() {
        for g in VakitServisi.gomulu() { takvim[g.gun] = g }
        if let veri = try? Data(contentsOf: VakitSabit.onbellekDosyasi), let liste = try? JSONDecoder().decode([GunVakti].self, from: veri) {
            for g in liste { takvim[g.gun] = g }
        }
    }

    func ayarla(_ a: Ayarlar) {
        kip = a.konumKipi
        enlem = a.enlem
        boylam = a.boylam
        konumAdi = a.konumKipi == .bursa ? "Bursa" : a.konumAdi
    }

    // MARK: Sorgular

    func gunVakti(_ tarih: Date) -> GunVakti? { kip == .bursa ? takvim[Depo.gunAnahtari(tarih)] : nil }

    /// Günün altı vakti (yerel saat).
    func vakitler(_ tarih: Date) -> [Date] {
        let gun = Calendar.current.startOfDay(for: tarih)
        if let g = gunVakti(tarih) {
            let s = g.saatler.compactMap { VakitServisi.saatten($0, gun: gun) }
            if s.count == 6 { return s }
        }
        return GunesHesabi.vakitler(gun: gun, enlem: kip == .bursa ? 40.1826 : enlem, boylam: kip == .bursa ? 29.0665 : boylam)
    }

    func hicri(_ tarih: Date) -> String {
        if let h = gunVakti(tarih)?.hicri, !h.isEmpty { return h }
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .islamicUmmAlQura)
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMMM y"
        return f.string(from: tarih)
    }

    /// Şimdiki vakit sırası (0-5) ve bir sonraki vaktin zamanı.
    func durum(_ simdi: Date = .now) -> (simdiki: Int, sonraki: Int, sonrakiZaman: Date) {
        let bugun = vakitler(simdi)
        if let i = bugun.firstIndex(where: { $0 > simdi }) {
            return (i == 0 ? 5 : i - 1, i, bugun[i])
        }
        let yarin = vakitler(Calendar.current.date(byAdding: .day, value: 1, to: simdi)!)
        return (5, 0, yarin[0])
    }

    static func saatten(_ s: String, gun: Date) -> Date? {
        let p = s.split(separator: ":").compactMap { Int($0) }
        guard p.count == 2 else { return nil }
        return Calendar.current.date(bySettingHour: p[0], minute: p[1], second: 0, of: gun)
    }

    // MARK: İndirme

    /// Takvimde 10 günden az ileri veri varsa indirir. Ağ yoksa sessizce vazgeçer.
    func gerekirseYenile() async {
        guard kip == .bursa, !EkranGoruntusu.etkin else { return }
        let ileri = (0..<12).filter { takvim[Depo.gunAnahtari(Calendar.current.date(byAdding: .day, value: $0, to: .now)!)] != nil }.count
        guard ileri < 10 else { return }
        if let yeni = await VakitServisi.indir() {
            for g in yeni { takvim[g.gun] = g }
            VakitServisi.onbellegeYaz(Array(takvim.values))
        }
    }

    nonisolated static func indir() async -> [GunVakti]? {
        guard let url = URL(string: "https://ezanvakti.emushaf.net/vakitler/\(VakitSabit.ilceKodu)") else { return nil }
        var istek = URLRequest(url: url, timeoutInterval: 20)
        istek.setValue("application/json", forHTTPHeaderField: "Accept")
        guard let (veri, yanit) = try? await URLSession.shared.data(for: istek),
              (yanit as? HTTPURLResponse)?.statusCode == 200,
              let dizi = try? JSONSerialization.jsonObject(with: veri) as? [[String: Any]] else { return nil }
        let sonuc: [GunVakti] = dizi.compactMap { d in
            guard let t = d["MiladiTarihKisa"] as? String else { return nil }
            let p = t.split(separator: ".")
            guard p.count == 3 else { return nil }
            let saatler = ["Imsak", "Gunes", "Ogle", "Ikindi", "Aksam", "Yatsi"].compactMap { d[$0] as? String }
            guard saatler.count == 6 else { return nil }
            return GunVakti(gun: "\(p[2])-\(p[1])-\(p[0])", saatler: saatler, hicri: d["HicriTarihUzun"] as? String ?? "")
        }
        return sonuc.isEmpty ? nil : sonuc
    }

    nonisolated static func onbellegeYaz(_ liste: [GunVakti]) {
        let esik = Depo.gunAnahtariBagimsiz(Calendar.current.date(byAdding: .day, value: -3, to: .now)!)
        let tut = liste.filter { $0.gun >= esik }.sorted { $0.gun < $1.gun }
        if let veri = try? JSONEncoder().encode(tut) { try? veri.write(to: VakitSabit.onbellekDosyasi, options: .atomic) }
    }

    /// Pakete gömülü 30 günlük Diyanet cetveli.
    private static func gomulu() -> [GunVakti] {
        guard let url = Bundle.main.url(forResource: "vakitler", withExtension: "json"), let veri = try? Data(contentsOf: url),
              let dizi = try? JSONSerialization.jsonObject(with: veri) as? [[String: Any]] else { return [] }
        return dizi.compactMap { d in
            guard let t = d["tarih"] as? String else { return nil }
            let p = t.split(separator: ".")
            guard p.count == 3 else { return nil }
            let saatler = ["imsak", "gunes", "ogle", "ikindi", "aksam", "yatsi"].compactMap { d[$0] as? String }
            guard saatler.count == 6 else { return nil }
            return GunVakti(gun: "\(p[2])-\(p[1])-\(p[0])", saatler: saatler, hicri: d["hicri"] as? String ?? "")
        }
    }
}

extension Depo {
    nonisolated static func gunAnahtariBagimsiz(_ tarih: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: tarih)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}

/// Güneşin konumundan namaz vakti hesabı (imsak 18°, yatsı 17°, ikindi gölge 1 kat) ve Diyanet temkinleri.
enum GunesHesabi {
    static let temkin: [Double] = [-0.23, -7.44, 4.97, 4.29, 7.37, 0.33] // dakika

    static func vakitler(gun: Date, enlem: Double, boylam: Double, saatDilimi: TimeZone = .current) -> [Date] {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: gun)
        let jd = julyen(c.year ?? 2026, c.month ?? 1, c.day ?? 1) - boylam / 360
        let fark = Double(saatDilimi.secondsFromGMT(for: gun)) / 3600
        func gunes(_ t: Double) -> (sapma: Double, denklem: Double) {
            let d = jd + t - 2451545.0
            let g = derece(357.529 + 0.98560028 * d), q = derece(280.459 + 0.98564736 * d)
            let l = derece(q + 1.915 * sin(rad(g)) + 0.020 * sin(rad(2 * g)))
            let e = 23.439 - 0.00000036 * d
            let ra = derece(deg(atan2(cos(rad(e)) * sin(rad(l)), cos(rad(l))))) / 15
            return (deg(asin(sin(rad(e)) * sin(rad(l)))), q / 15 - saat(ra))
        }
        func ogle(_ t: Double) -> Double { saat(12 - gunes(t).denklem) }
        func aciZamani(_ aci: Double, _ t: Double, _ once: Bool) -> Double {
            let s = gunes(t).sapma
            let v = deg(acos(max(-1, min(1, (-sin(rad(aci)) - sin(rad(s)) * sin(rad(enlem))) / (cos(rad(s)) * cos(rad(enlem))))))) / 15
            return ogle(t) + (once ? -v : v)
        }
        func ikindi(_ t: Double) -> Double {
            let s = gunes(t).sapma
            let aci = -deg(atan(1 / (1 + tan(rad(abs(enlem - s))))))
            return aciZamani(aci, t, false)
        }
        let ham = [aciZamani(18, 5 / 24, true), aciZamani(0.833, 6 / 24, true), ogle(12 / 24), ikindi(13 / 24), aciZamani(0.833, 18 / 24, false), aciZamani(17, 18 / 24, false)]
        let basla = Calendar.current.startOfDay(for: gun)
        return ham.enumerated().map { i, h in
            let yerel = h + fark - boylam / 15
            return basla.addingTimeInterval((yerel * 60 + temkin[i]) * 60)
        }
    }

    private static func julyen(_ y: Int, _ m: Int, _ d: Int) -> Double {
        var y = y, m = m
        if m <= 2 { y -= 1; m += 12 }
        let a = floor(Double(y) / 100), b = 2 - a + floor(a / 4)
        return floor(365.25 * Double(y + 4716)) + floor(30.6001 * Double(m + 1)) + Double(d) + b - 1524.5
    }
    private static func rad(_ d: Double) -> Double { d * .pi / 180 }
    private static func deg(_ r: Double) -> Double { r * 180 / .pi }
    private static func derece(_ a: Double) -> Double { let x = a.truncatingRemainder(dividingBy: 360); return x < 0 ? x + 360 : x }
    private static func saat(_ a: Double) -> Double { let x = a.truncatingRemainder(dividingBy: 24); return x < 0 ? x + 24 : x }
}
