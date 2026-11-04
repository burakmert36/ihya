import Foundation
import Observation

struct Sure: Identifiable, Hashable {
    let no: Int
    let ad: String
    let arapca: String
    let mekki: Bool
    let ayetSayisi: Int
    var id: Int { no }
}

struct AyetYeri: Hashable {
    let sure: Int
    let ayet: Int
}

struct Ayet: Hashable {
    let no: Int
    let arapca: String
    /// Diyanet meali bazı âyetleri birlikte çevirir; ortak meal yalnız grubun son âyetinde durur, öncekilerde boştur.
    let meal: String
    /// Mealin kapsadığı ilk âyet (tek âyetse kendisi).
    let mealBas: Int
    let okunus: String
    let cuz: Int
}

/// Kur'an metni: Arapça (Hafs, Kral Fahd Mushafı), Diyanet meali ve Türkçe okunuş.
/// Depoya konmaz; ilk açılışta bir kez indirilir (yaklaşık 5 MB), sonra telefonda çevrimdışı okunur.
@MainActor
@Observable
final class KuranDeposu {
    static let ortak = KuranDeposu()
    nonisolated static let toplamAyet = 6236

    enum Durum: Equatable { case yok, iniyor(Double), hazir, hata(String) }

    private(set) var durum: Durum = .yok
    private(set) var sureler: [Sure] = []
    @ObservationIgnored private(set) var ayetler: [[Ayet]] = []
    /// Her sûrenin Mushaf'taki ilk âyetinin sırası (hatim yüzdesi için).
    @ObservationIgnored private var baslangic: [Int] = []

    private static let kaynak = "https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/"
    private static let dosyalar: [(String, String)] = [
        ("arapca", "editions/ara-quranuthmanihaf.min.json"),
        ("meal", "editions/tur-diyanetisleri.min.json"),
        ("okunus", "editions/tur-latinalphabet.min.json"),
        ("bilgi", "info.min.json"),
    ]

    nonisolated static var klasor: URL {
        let u = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Kuran")
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }

    var hazir: Bool { durum == .hazir }

    func hazirla() async {
        switch durum {
        case .hazir, .iniyor: return
        default: break
        }
        let k = KuranDeposu.klasor
        let eksik = KuranDeposu.dosyalar.filter { !FileManager.default.fileExists(atPath: k.appendingPathComponent($0.0 + ".json").path) }
        if !eksik.isEmpty {
            durum = .iniyor(0)
            for (i, (ad, yol)) in eksik.enumerated() {
                guard let url = URL(string: KuranDeposu.kaynak + yol),
                      let (veri, yanit) = try? await URLSession.shared.data(from: url),
                      (yanit as? HTTPURLResponse)?.statusCode == 200, veri.count > 1000 else {
                    durum = .hata("Kur'an metni indirilemedi. İnternete bağlanıp tekrar dene.")
                    return
                }
                try? veri.write(to: k.appendingPathComponent(ad + ".json"), options: .atomic)
                durum = .iniyor(Double(i + 1) / Double(eksik.count))
            }
        }
        let sonuc = await Task.detached(priority: .userInitiated) { KuranDeposu.coz(k) }.value
        guard let sonuc else {
            for (ad, _) in KuranDeposu.dosyalar { try? FileManager.default.removeItem(at: k.appendingPathComponent(ad + ".json")) }
            durum = .hata("Kur'an dosyaları bozuk; yeniden indirilecek. Tekrar dene.")
            return
        }
        sureler = sonuc.0
        ayetler = sonuc.1
        var t = 0
        baslangic = ayetler.map { a in defer { t += a.count }; return t }
        durum = .hazir
    }

    func tekrarDene() async {
        durum = .yok
        await hazirla()
    }

    func sure(_ no: Int) -> Sure? { sureler.indices.contains(no - 1) ? sureler[no - 1] : nil }
    func ayetleri(_ no: Int) -> [Ayet] { ayetler.indices.contains(no - 1) ? ayetler[no - 1] : [] }

    /// Mushaf sırasına göre okunan oran (0…1).
    func oran(sure: Int, ayet: Int) -> Double {
        guard baslangic.indices.contains(sure - 1) else { return 0 }
        return Double(baslangic[sure - 1] + ayet) / Double(KuranDeposu.toplamAyet)
    }

    /// Mealde arama için büyük-küçük harf ve şapka farkı silinmiş metinler (ilk aramada bir kez hazırlanır).
    @ObservationIgnored private var katlanmis: [[String]] = []

    nonisolated static func katla(_ s: String) -> String {
        s.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "tr_TR"))
            .replacingOccurrences(of: "ı", with: "i")
    }

    /// Mealde geçen âyetler (Mushaf sırasıyla, en çok 'enFazla').
    func ara(_ q: String, enFazla: Int = 80) -> [AyetYeri] {
        let k = KuranDeposu.katla(q.trimmingCharacters(in: .whitespaces))
        guard k.count >= 3, hazir else { return [] }
        if katlanmis.isEmpty { katlanmis = ayetler.map { $0.map { KuranDeposu.katla($0.meal) } } }
        var sonuc: [AyetYeri] = []
        for (i, liste) in katlanmis.enumerated() {
            for (j, m) in liste.enumerated() where m.contains(k) {
                sonuc.append(AyetYeri(sure: i + 1, ayet: j + 1))
                if sonuc.count >= enFazla { return sonuc }
            }
        }
        return sonuc
    }

    func ayet(_ y: AyetYeri) -> Ayet? {
        let l = ayetleri(y.sure)
        return l.indices.contains(y.ayet - 1) ? l[y.ayet - 1] : nil
    }

    /// Cüzlerin başladığı yerler: (cüz, sûre, âyet).
    var cuzBaslari: [(cuz: Int, sure: Int, ayet: Int)] {
        var sonuc: [(Int, Int, Int)] = []
        var son = 0
        for (i, liste) in ayetler.enumerated() {
            for a in liste where a.cuz != son {
                son = a.cuz
                sonuc.append((a.cuz, i + 1, a.no))
            }
        }
        return sonuc.map { (cuz: $0.0, sure: $0.1, ayet: $0.2) }
    }

    // MARK: Çözümleme

    nonisolated static func coz(_ k: URL) -> ([Sure], [[Ayet]])? {
        func oku(_ ad: String) -> [String: Any]? {
            guard let v = try? Data(contentsOf: k.appendingPathComponent(ad + ".json")) else { return nil }
            return (try? JSONSerialization.jsonObject(with: v)) as? [String: Any]
        }
        func metinler(_ d: [String: Any]?) -> [[String]]? {
            guard let liste = d?["quran"] as? [[String: Any]] else { return nil }
            var s = Array(repeating: [String](), count: 114)
            for v in liste {
                guard let c = v["chapter"] as? Int, (1...114).contains(c), let t = v["text"] as? String else { continue }
                s[c - 1].append(t)
            }
            return s
        }
        guard let ar = metinler(oku("arapca")), let ml = metinler(oku("meal")),
              let bilgi = oku("bilgi")?["chapters"] as? [[String: Any]], bilgi.count == 114 else { return nil }
        let ok = metinler(oku("okunus"))
        var sureler: [Sure] = []
        var ayetler: [[Ayet]] = []
        for i in 0..<114 {
            let b = bilgi[i]
            let cuzler = (b["verses"] as? [[String: Any]])?.map { ($0["juz"] as? Int) ?? 0 } ?? []
            let n = ar[i].count
            guard n > 0, ml[i].count == n else { return nil }
            var liste: [Ayet] = []
            var bas = 0
            for j in 0..<n {
                let ortak = j + 1 < n && ml[i][j + 1] == ml[i][j]
                liste.append(Ayet(no: j + 1, arapca: ar[i][j], meal: ortak ? "" : ml[i][j], mealBas: bas + 1,
                                  okunus: (ok?[i].indices.contains(j) ?? false) ? ok![i][j] : "",
                                  cuz: cuzler.indices.contains(j) ? cuzler[j] : 0))
                if !ortak { bas = j + 1 }
            }
            ayetler.append(liste)
            sureler.append(Sure(no: i + 1, ad: KuranDeposu.adlar[i], arapca: b["arabicname"] as? String ?? "",
                                mekki: (b["revelation"] as? String ?? "").hasPrefix("Mec"), ayetSayisi: n))
        }
        return ayetler.reduce(0) { $0 + $1.count } == toplamAyet ? (sureler, ayetler) : nil
    }

    nonisolated static let adlar = [
        "Fâtiha", "Bakara", "Âl-i İmrân", "Nisâ", "Mâide", "En'âm", "A'râf", "Enfâl", "Tevbe", "Yûnus",
        "Hûd", "Yûsuf", "Ra'd", "İbrâhîm", "Hicr", "Nahl", "İsrâ", "Kehf", "Meryem", "Tâhâ",
        "Enbiyâ", "Hac", "Mü'minûn", "Nûr", "Furkân", "Şuarâ", "Neml", "Kasas", "Ankebût", "Rûm",
        "Lokmân", "Secde", "Ahzâb", "Sebe'", "Fâtır", "Yâsîn", "Sâffât", "Sâd", "Zümer", "Mü'min",
        "Fussilet", "Şûrâ", "Zuhruf", "Duhân", "Câsiye", "Ahkâf", "Muhammed", "Fetih", "Hucurât", "Kâf",
        "Zâriyât", "Tûr", "Necm", "Kamer", "Rahmân", "Vâkıa", "Hadîd", "Mücâdele", "Haşr", "Mümtehine",
        "Saf", "Cuma", "Münâfikûn", "Teğâbün", "Talâk", "Tahrîm", "Mülk", "Kalem", "Hâkka", "Meâric",
        "Nûh", "Cin", "Müzzemmil", "Müddessir", "Kıyâme", "İnsân", "Mürselât", "Nebe'", "Nâziât", "Abese",
        "Tekvîr", "İnfitâr", "Mutaffifîn", "İnşikâk", "Burûc", "Târık", "A'lâ", "Gâşiye", "Fecr", "Beled",
        "Şems", "Leyl", "Duhâ", "İnşirâh", "Tîn", "Alak", "Kadr", "Beyyine", "Zilzâl", "Âdiyât",
        "Kâria", "Tekâsür", "Asr", "Hümeze", "Fîl", "Kureyş", "Mâûn", "Kevser", "Kâfirûn", "Nasr",
        "Tebbet", "İhlâs", "Felak", "Nâs",
    ]
}

extension Int {
    /// Arapça-Hint rakamları: 12 → ١٢
    var arapcaRakam: String { String(String(self).map { c in c.wholeNumberValue.map { Character(UnicodeScalar(0x0660 + $0)!) } ?? c }) }
}
