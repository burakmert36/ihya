import AppIntents
import Foundation

extension Notification.Name {
    static let ihyaNiyet = Notification.Name("ihya.niyet")
}

/// Denetim Merkezi ve kısayollardan gelen istekleri uygulamaya taşır.
enum NiyetKoprusu {
    static let anahtar = "ihya.bekleyenNiyet"
    /// Niyet widget sürecinde çalışırsa da uygulama görsün diye ortak klasörün ayarları kullanılır.
    private static var ayarlar: UserDefaults { UserDefaults(suiteName: Paylasim.grup) ?? .standard }
    static func gonder(_ ad: String) {
        ayarlar.set(ad, forKey: anahtar)
        NotificationCenter.default.post(name: .ihyaNiyet, object: ad)
    }
    static func al() -> String? {
        let v = ayarlar.string(forKey: anahtar)
        ayarlar.removeObject(forKey: anahtar)
        return v
    }
}

/// "Odaklan": uygulamayı odak kurulumuyla açar.
struct OdaklanNiyeti: AppIntent {
    static let title: LocalizedStringResource = "Odaklan"
    static let description = IntentDescription("İhya'da yeni bir odak oturumu açar.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        NiyetKoprusu.gonder("odak")
        return .result()
    }
}

/// "Sesler": uygulamayı odak sesleri ekranında açar.
struct SeslerNiyeti: AppIntent {
    static let title: LocalizedStringResource = "Odak sesleri"
    static let description = IntentDescription("İhya'da odak sesleri ekranını açar.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        NiyetKoprusu.gonder("sesler")
        return .result()
    }
}

/// "Kur'an dinle": kaldığın yerden tilaveti açar.
struct KuranDinleNiyeti: AppIntent {
    static let title: LocalizedStringResource = "Kur'an dinle"
    static let description = IntentDescription("İhya'da Kur'an'ı kaldığın yerden dinletir.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        NiyetKoprusu.gonder("dinle")
        return .result()
    }
}
