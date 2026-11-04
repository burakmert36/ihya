import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// Bütün kullanıcı verisi (oturumlar, bahçe, namaz, kaza, zikir, kaydedilenler, karışımlar, ayarlar) tek JSON dosyası.
/// Kitap PDF'leri ve tilavet kayıtları yedeğe girmez (yeniden eklenebilir/indirilebilir).
struct YedekBelgesi: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var veri: Data

    init(veri: Data) { self.veri = veri }

    init(configuration: ReadConfiguration) throws {
        guard let d = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        veri = d
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: veri) }
}

@MainActor
enum Yedek {
    /// Telefondaki yedek klasörü (Dosyalar › Telefonumda › Ihya › Yedekler); son 7 gün tutulur.
    nonisolated static var yerelKlasor: URL {
        let u = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Yedekler")
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }

    nonisolated static func dosyaAdi(_ t: Date = .now) -> String { "Ihya-yedek-\(Depo.gunAnahtariBagimsiz(t)).json" }

    /// Cihaza özgü alanlar (yedek klasörünün yer imi) yedeğe yazılmaz.
    nonisolated static func veri(_ k: Kayit) -> Data? {
        var temiz = k
        temiz.yedekYeri = nil
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? e.encode(temiz)
    }

    /// Dosyadan okur; geçerli bir İhya yedeği değilse açıklamalı hata verir.
    nonisolated static func coz(_ d: Data) throws -> Kayit {
        guard let nesne = try? JSONSerialization.jsonObject(with: d) as? [String: Any], nesne["ayarlar"] != nil || nesne["oturumlar"] != nil else {
            throw YedekHatasi.gecersiz
        }
        do { return try JSONDecoder().decode(Kayit.self, from: d) } catch { throw YedekHatasi.gecersiz }
    }

    enum YedekHatasi: LocalizedError {
        case gecersiz, klasorYok
        var errorDescription: String? {
            switch self {
            case .gecersiz: "Bu dosya bir İhya yedeği değil ya da bozuk."
            case .klasorYok: "Yedek klasörüne ulaşılamadı. Klasörü yeniden seç."
            }
        }
    }

    /// Günlük yedek: telefondaki klasöre her gün bir dosya (7 gün tutulur) ve seçildiyse kullanıcının klasörüne (ör. iCloud Drive).
    /// Gün içinde ikinci kez yazmaz. Döndürdüğü metin hata ya da nil'dir.
    @discardableResult
    static func gunlukYedek(_ depo: Depo, zorla: Bool = false, isaretle: Bool = true) -> String? {
        guard !EkranGoruntusu.etkin else { return nil }
        if !zorla, let s = depo.kayit.sonYedek, Calendar.current.isDateInToday(s) { return nil }
        guard let d = veri(depo.kayit) else { return "Yedek hazırlanamadı." }
        let ad = dosyaAdi()
        try? d.write(to: yerelKlasor.appendingPathComponent(ad), options: .atomic)
        eskileriSil()
        var hata: String?
        if let yer = depo.kayit.yedekYeri {
            hata = klasoreYaz(d, ad: ad, yerImi: yer)
        }
        // Arka plan görevi ayrı bir Depo örneğiyle çalışır; asıl veriyi ezmesin diye işaret koymaz.
        if isaretle { depo.degistir { $0.sonYedek = .now } }
        return hata
    }

    nonisolated private static func eskileriSil() {
        let k = yerelKlasor
        let adlar = ((try? FileManager.default.contentsOfDirectory(atPath: k.path)) ?? []).filter { $0.hasPrefix("Ihya-yedek-") }.sorted()
        for a in adlar.dropLast(7) { try? FileManager.default.removeItem(at: k.appendingPathComponent(a)) }
    }

    /// Kullanıcının seçtiği klasöre yazar: tek "Ihya-yedek.json" (her gün üzerine) ve haftada bir tarihli kopya.
    nonisolated static func klasoreYaz(_ d: Data, ad: String, yerImi: Data) -> String? {
        var eski = false
        guard let klasor = try? URL(resolvingBookmarkData: yerImi, options: [], relativeTo: nil, bookmarkDataIsStale: &eski) else {
            return YedekHatasi.klasorYok.errorDescription
        }
        let erisim = klasor.startAccessingSecurityScopedResource()
        defer { if erisim { klasor.stopAccessingSecurityScopedResource() } }
        var hata: NSError?
        var yazildi = false
        let hedefler = [klasor.appendingPathComponent("Ihya-yedek.json")]
            + (Calendar.current.component(.weekday, from: .now) == 6 ? [klasor.appendingPathComponent(ad)] : [])
        for hedef in hedefler {
            NSFileCoordinator().coordinate(writingItemAt: hedef, options: .forReplacing, error: &hata) { u in
                yazildi = (try? d.write(to: u, options: .atomic)) != nil
            }
        }
        return yazildi && hata == nil ? nil : YedekHatasi.klasorYok.errorDescription
    }

    /// Seçilen klasörün yer imini saklar ve hemen bir yedek yazar.
    static func klasorSec(_ url: URL, depo: Depo) -> String? {
        let erisim = url.startAccessingSecurityScopedResource()
        defer { if erisim { url.stopAccessingSecurityScopedResource() } }
        guard let yer = try? url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil) else {
            return "Klasör saklanamadı."
        }
        depo.degistir { $0.yedekYeri = yer }
        return gunlukYedek(depo, zorla: true)
    }

    nonisolated static func klasorAdi(_ yerImi: Data?) -> String? {
        guard let yerImi else { return nil }
        var eski = false
        guard let u = try? URL(resolvingBookmarkData: yerImi, options: [], relativeTo: nil, bookmarkDataIsStale: &eski) else { return nil }
        return u.lastPathComponent
    }

    /// Geri yüklemeden önce mevcut veri telefondaki yedek klasörüne ayrıca yazılır (yanlışlıkla geri yüklemeye karşı).
    static func geriYukle(_ yeni: Kayit, depo: Depo) {
        if let d = veri(depo.kayit) {
            try? d.write(to: yerelKlasor.appendingPathComponent("Ihya-geri-yuklemeden-once-\(Depo.gunAnahtariBagimsiz(.now)).json"), options: .atomic)
        }
        let yer = depo.kayit.yedekYeri
        depo.tumunuDegistir(yeni)
        depo.degistir { $0.yedekYeri = yer; $0.devam = nil }
        depo.hemenKaydet()
    }
}
