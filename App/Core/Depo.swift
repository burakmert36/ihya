import Foundation
import Observation
import SwiftUI

/// Kullanıcı verisinin tek kaynağı. Değişiklikler kısa bir gecikmeyle, atomik olarak diske yazılır.
@MainActor
@Observable
final class Depo {
    private(set) var kayit: Kayit
    private let kalici: Bool
    @ObservationIgnored private var yazmaGorevi: Task<Void, Never>?

    static var dosya: URL {
        let kok = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: kok, withIntermediateDirectories: true)
        return kok.appendingPathComponent("ihya.json")
    }

    init(kayit: Kayit, kalici: Bool) {
        self.kayit = kayit
        self.kalici = kalici
    }

    static func yukle() -> Depo {
        if EkranGoruntusu.etkin { return Depo(kayit: Ornek.kayit(), kalici: false) }
        if let veri = try? Data(contentsOf: dosya), let k = try? JSONDecoder().decode(Kayit.self, from: veri) {
            return Depo(kayit: k, kalici: true)
        }
        return Depo(kayit: Kayit(), kalici: true)
    }

    // MARK: Kaydetme

    func degistir(_ islem: (inout Kayit) -> Void) {
        islem(&kayit)
        kaydet()
    }

    func kaydet() {
        guard kalici else { return }
        yazmaGorevi?.cancel()
        yazmaGorevi = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 600_000_000)
            guard !Task.isCancelled, let self else { return }
            self.hemenKaydet()
        }
    }

    func hemenKaydet() {
        guard kalici, let veri = try? JSONEncoder().encode(kayit) else { return }
        let hedef = Depo.dosya
        DispatchQueue.global(qos: .utility).async { try? veri.write(to: hedef, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]) }
    }

    // MARK: Ayarlar

    var ayarlar: Ayarlar { kayit.ayarlar }

    func ayar<T>(_ yol: WritableKeyPath<Ayarlar, T>) -> Binding<T> {
        Binding(get: { self.kayit.ayarlar[keyPath: yol] }, set: { yeni in self.degistir { $0.ayarlar[keyPath: yol] = yeni } })
    }

    // MARK: Tohum ve koleksiyon

    func acikMi(_ tur: String) -> Bool { kayit.acik.contains(tur) }

    @discardableResult
    func kilidiAc(_ tur: String, fiyat: Int) -> Bool {
        guard !acikMi(tur), kayit.tohum >= fiyat else { return false }
        degistir { $0.tohum -= fiyat; $0.acik.append(tur) }
        return true
    }

    // MARK: Namaz takibi

    nonisolated static func gunAnahtari(_ tarih: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: tarih)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    func kilindi(_ vakit: Int, gun: Date = .now) -> Bool { kayit.namaz[Depo.gunAnahtari(gun)]?.contains(vakit) ?? false }

    func namazDegistir(_ vakit: Int, gun: Date = .now) {
        let a = Depo.gunAnahtari(gun)
        degistir { k in
            var liste = k.namaz[a] ?? []
            if let i = liste.firstIndex(of: vakit) { liste.remove(at: i) } else { liste.append(vakit) }
            k.namaz[a] = liste
        }
    }

    /// Tamamlanan odakla süren gün serisi; bugün henüz odak yoksa dünden sayar.
    var seri: Int {
        let c = Calendar.current
        let gunler = Set(kayit.oturumlar.filter { $0.durum == .tamam }.map { c.startOfDay(for: $0.baslangic) })
        var g = c.startOfDay(for: .now)
        if !gunler.contains(g) { g = c.date(byAdding: .day, value: -1, to: g)! }
        var n = 0
        while gunler.contains(g) { n += 1; g = c.date(byAdding: .day, value: -1, to: g)! }
        return n
    }

    /// Bugün tamamlanan oturumlar.
    var bugunkuOturumlar: [OdakOturumu] { kayit.oturumlar.filter { Calendar.current.isDateInToday($0.baslangic) } }

    // MARK: Favoriler

    func begenildi(_ tur: Favori.Tur, _ anahtar: String) -> Bool { kayit.favoriler.contains { $0.tur == tur && $0.anahtar == anahtar } }

    func begen(_ tur: Favori.Tur, _ anahtar: String) {
        degistir { k in
            if let i = k.favoriler.firstIndex(where: { $0.tur == tur && $0.anahtar == anahtar }) { k.favoriler.remove(at: i) }
            else { k.favoriler.insert(Favori(tur: tur, anahtar: anahtar), at: 0) }
        }
    }

    // MARK: Konular

    func konu(_ id: UUID?) -> Konu? { kayit.konular.first { $0.id == id } }
}

/// Simülatörde ekran görüntüsü alınırken kullanılan örnek veri (diske yazılmaz).
enum Ornek {
    static func kayit() -> Kayit {
        var k = Kayit()
        k.tohum = 46
        k.acik = BitkiKatalogu.baslangic + ["gul", "lale", "menekse", "reyhan", "badem", "servi", "zeytin", "turunc"]
        let takvim = Calendar.current
        let bugun = takvim.startOfDay(for: .now)
        let turler = ["papatya", "gul", "lale", "cam", "kavak", "menekse", "badem", "servi", "reyhan", "zeytin", "turunc", "karahindiba"]
        var r = SistemRastgele(tohum: 11)
        for gun in 0..<34 {
            let adet = gun == 0 ? 4 : Int(r.sonraki() * 4)
            for j in 0..<adet {
                let plan = [15, 25, 30, 45, 60, 25, 40][Int(r.sonraki() * 7)]
                let bas = takvim.date(byAdding: .minute, value: 8 * 60 + j * 95 + Int(r.sonraki() * 40), to: takvim.date(byAdding: .day, value: -gun, to: bugun)!)!
                let vazgecti = r.sonraki() < 0.08
                let konu = k.konular[Int(r.sonraki() * Double(k.konular.count))]
                k.oturumlar.append(OdakOturumu(baslangic: bas, plan: plan, sure: vazgecti ? Double(plan) * 0.4 : Double(plan),
                                               tur: turler[Int(r.sonraki() * Double(turler.count))], tohum: Int(r.sonraki() * 1000),
                                               konu: konu.id, ad: "", durum: vazgecti ? .vazgecildi : .tamam,
                                               kazanc: vazgecti ? 0 : OdakMotoru.tohumKazanci(plan)))
            }
            if gun < 20 {
                for b in ["Sübhânallah", "", "Estağfirullah"] where r.sonraki() < 0.7 {
                    k.zikirler.append(ZikirKaydi(baslik: b, sayi: 33 * (1 + Int(r.sonraki() * 4)), tarih: takvim.date(byAdding: .day, value: -gun, to: .now)!))
                }
            }
        }
        k.namaz[Depo.gunAnahtari(.now)] = [0, 1]
        k.favoriler = [Favori(tur: .ayet, anahtar: "2:255"), Favori(tur: .hadis, anahtar: "1"), Favori(tur: .dua, anahtar: "istihare")]
        k.sonKatman = ["yagmur": 0.7, "kuslar": 0.4]
        k.kuranSon = [36, 12]
        k.ezber = Array(1...12)
        k.karisimlar = [Karisim(ad: "Yağmurlu kütüphane", katman: ["yagmur_cam": 0.6, "kutuphane": 0.5])]
        return k
    }
}

/// Tekrarlanabilir rastgele sayı (örnek veri için).
struct SistemRastgele {
    private var durum: UInt64
    init(tohum: UInt64) { durum = tohum &* 0x9E3779B97F4A7C15 }
    mutating func sonraki() -> Double {
        durum = durum &* 6364136223846793005 &+ 1442695040888963407
        return Double(durum >> 11) / Double(1 << 53)
    }
}

/// CI'daki simülatörde '-ekranGoruntusu 1 -ekran <ad>' ile açılış.
enum EkranGoruntusu {
    static let etkin = UserDefaults.standard.bool(forKey: "ekranGoruntusu")
    static let ekran = UserDefaults.standard.string(forKey: "ekran") ?? ""
    /// CI: ses motorunu sınar, sonucu konsola yazar.
    static let sesSinamasi = UserDefaults.standard.bool(forKey: "sesSinama")
}
