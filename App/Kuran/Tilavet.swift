import AVFoundation
import MediaPlayer
import Observation
import SwiftUI

/// Hafızlar. EveryAyah'takiler âyet âyet, mp3quran'dakiler bütün sûre kaydı ve âyet zamanlarıyla çalınır; kayıtlar depoya konmaz.
struct Hafiz: Identifiable, Hashable {
    enum Grup: String, CaseIterable {
        case kabe, nebevi, huzur
        var ad: String {
            switch self {
            case .kabe: "Mescid-i Harâm (Kâbe)"
            case .nebevi: "Mescid-i Nebevî"
            case .huzur: "Huzur veren sesler"
            }
        }
    }

    let id: String        // EveryAyah klasör adı ya da "mp3quran-<no>"
    let ad: String
    let arapca: String
    /// Rozette görünen kısa Arapça ad.
    let kisa: String
    let unvan: String
    /// Rozet rengi
    let renk: String
    var grup: Grup = .kabe
    /// mp3quran okuyucu numarası ve ses klasörü (bütün sûre kaydı)
    var okuyucu: Int? = nil
    var klasor: String? = nil

    var tamSure: Bool { okuyucu != nil }

    private static func m(_ no: Int, _ yol: String, _ ad: String, _ arapca: String, _ kisa: String, _ unvan: String, _ renk: String, _ g: Grup) -> Hafiz {
        Hafiz(id: "mp3quran-\(no)", ad: ad, arapca: arapca, kisa: kisa, unvan: unvan, renk: renk, grup: g, okuyucu: no,
              klasor: "https://cdn.mp3quran.net/audio/\(yol)/r1/")
    }

    static let tumu: [Hafiz] = [
        Hafiz(id: "Abdurrahmaan_As-Sudais_192kbps", ad: "Abdurrahman es-Südeys", arapca: "عبد الرحمن السديس", kisa: "السديس", unvan: "Kâbe imamı", renk: "#E9C46A"),
        Hafiz(id: "MaherAlMuaiqly128kbps", ad: "Mâhir el-Muaykılî", arapca: "ماهر المعيقلي", kisa: "المعيقلي", unvan: "Kâbe imamı", renk: "#7CC8FF"),
        Hafiz(id: "Yasser_Ad-Dussary_128kbps", ad: "Yâsir ed-Devserî", arapca: "ياسر الدوسري", kisa: "الدوسري", unvan: "Kâbe imamı", renk: "#9BE38F"),
        Hafiz(id: "Abdullaah_3awwaad_Al-Juhaynee_128kbps", ad: "Abdullah el-Cühenî", arapca: "عبد الله الجهني", kisa: "الجهني", unvan: "Kâbe imamı", renk: "#F4A3C4"),
        m(217, "bandar-baleela", "Bender Belîle", "بندر بليلة", "بليلة", "Kâbe imamı", "#8FD3C7", .kabe),
        Hafiz(id: "Saood_ash-Shuraym_128kbps", ad: "Suûd eş-Şüreym", arapca: "سعود الشريم", kisa: "الشريم", unvan: "Kâbe'nin eski imamı", renk: "#C9B6FF"),
        Hafiz(id: "Ali_Jaber_64kbps", ad: "Ali Câbir", arapca: "علي جابر", kisa: "جابر", unvan: "Kâbe'nin eski imamı", renk: "#FFB677"),
        m(61, "abdullah-khayyat", "Abdullah Hayyât", "عبد الله خياط", "خياط", "Kâbe'nin eski imamı", "#D9C49A", .kabe),

        Hafiz(id: "Hudhaify_128kbps", ad: "Ali el-Huzeyfî", arapca: "علي الحذيفي", kisa: "الحذيفي", unvan: "Mescid-i Nebevî imamı", renk: "#A7D8A0", grup: .nebevi),
        Hafiz(id: "Salah_Al_Budair_128kbps", ad: "Salâh el-Büdeyr", arapca: "صلاح البدير", kisa: "البدير", unvan: "Mescid-i Nebevî imamı", renk: "#9CC9F5", grup: .nebevi),
        m(49, "abdulbari-thubaiti", "Abdulbârî es-Subeytî", "عبد الباري الثبيتي", "الثبيتي", "Mescid-i Nebevî imamı", "#F2B5A0", .nebevi),
        m(58, "abdullah-buaijan", "Abdullah el-Buaycân", "عبد الله البعيجان", "البعيجان", "Mescid-i Nebevî imamı", "#B9B2F0", .nebevi),
        m(67, "abdulmohsen-qasim", "Abdulmuhsin el-Kâsım", "عبد المحسن القاسم", "القاسم", "Mescid-i Nebevî imamı", "#E8D17F", .nebevi),
        Hafiz(id: "Muhammad_Ayyoub_128kbps", ad: "Muhammed Eyyûb", arapca: "محمد أيوب", kisa: "أيوب", unvan: "Mescid-i Nebevî'nin eski imamı", renk: "#F7A8B8", grup: .nebevi),

        m(225, "abdulrahman-oosi", "Abdurrahman el-Ussî", "عبد الرحمن العوسي", "العوسي", "Huzur veren tilavet", "#9FE0D0", .huzur),
        m(86, "nasser-qatami", "Nâsır el-Katâmî", "ناصر القطامي", "القطامي", "Huzur veren tilavet", "#C4E38F", .huzur),
        m(12, "idrees-abkar", "İdrîs Ebker", "إدريس أبكر", "أبكر", "Huzur veren tilavet", "#F5C78E", .huzur),
        m(236, "abdulrahman-majed", "Abdurrahman el-Mâcid", "عبد الرحمن الماجد", "الماجد", "Huzur veren tilavet", "#A9C8FF", .huzur),
        m(259, "ahmad-nufais", "Ahmed en-Nüfeys", "أحمد النفيس", "النفيس", "Huzur veren tilavet", "#E7B3F0", .huzur),
        m(221, "raad-kurdi", "Raad el-Kürdî", "رعد الكردي", "الكردي", "Huzur veren tilavet", "#FFD39A", .huzur),
        m(245, "mansour-salimi", "Mansûr es-Sâlimî", "منصور السالمي", "السالمي", "Huzur veren tilavet", "#B7E4F5", .huzur),
        m(273, "haitham-dukhain", "Heysem ed-Dühayn", "هيثم الدخين", "الدخين", "Huzur veren tilavet", "#D7E8A6", .huzur),
    ]
    static func bul(_ id: String) -> Hafiz { tumu.first { $0.id == id } ?? tumu[0] }
    static func grup(_ g: Grup) -> [Hafiz] { tumu.filter { $0.grup == g } }
}

/// mp3quran âyet zamanı (milisaniye).
struct AyetZamani: Codable, Equatable {
    let ayah: Int
    let start_time: Double
    let end_time: Double
}

/// Âyet takipli tilavet. Okunan âyet bilinir; okuyucu onu vurgular ve ekranda tutar.
/// EveryAyah hafızlarında her âyetin kaydı ayrı çalınır; mp3quran hafızlarında bütün sûre akar, âyet zaman cetvelinden bulunur.
/// Kayıtlar dinlendikçe (ya da "indir"le) telefona iner; inen sûre internetsiz dinlenir.
@MainActor
@Observable
final class TilavetMotoru {
    static let ortak = TilavetMotoru()
    nonisolated static let kaynak = "https://everyayah.com/data/"
    nonisolated static let zamanKaynagi = "https://mp3quran.net/api/v3/ayat_timing"
    nonisolated static let ayetSayilari = [7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128, 111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73, 54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6]

    private(set) var hafiz = Hafiz.tumu[0]
    /// 0: etkin değil.
    private(set) var sure = 0
    /// 0: besmele.
    private(set) var ayet = 0
    private(set) var caliyor = false
    /// Kayıt iniyor ya da akış dolmayı bekliyor.
    private(set) var bekliyor = false
    private(set) var hata: String?
    /// Her âyet kaç kez okunsun; 0 sürekli (ezber için).
    private(set) var tekrar = 1
    private(set) var hiz: Float = 1
    /// Okunan âyet ekranda tutulsun.
    var takip = true
    /// Sûre bitince sonrakine geçilsin.
    var devam = false
    /// İnen sûreler: "hafız|sûre" → 0…1
    private(set) var indirmeler: [String: Double] = [:]

    var etkin: Bool { sure > 0 }
    var sureAyetSayisi: Int { (1...114).contains(sure) ? TilavetMotoru.ayetSayilari[sure - 1] : 0 }
    /// Çalma durumu değişince (odak seslerini kısmak için).
    @ObservationIgnored var degisti: ((Bool) -> Void)?

    // Âyet âyet (EveryAyah)
    @ObservationIgnored private var oynatici: AVAudioPlayer?
    @ObservationIgnored private let bitis = BitisTemsilcisi()
    // Bütün sûre (mp3quran)
    @ObservationIgnored private var akis: AVPlayer?
    @ObservationIgnored private var akisAnahtari = ""
    @ObservationIgnored private var zamanlar: [AyetZamani] = []
    @ObservationIgnored private var akisGozlemi: Any?
    @ObservationIgnored private var akisBitisi: NSObjectProtocol?
    @ObservationIgnored private var akisDurumlari: [NSKeyValueObservation] = []
    @ObservationIgnored private var araniyor = false

    @ObservationIgnored private var tekrarSayac = 0
    @ObservationIgnored private var nesil = 0
    @ObservationIgnored private var inenler: [String: Task<URL?, Never>] = [:]
    @ObservationIgnored private var surIndirme: Task<Void, Never>?
    @ObservationIgnored private var gozlemciler: [NSObjectProtocol] = []

    private init() {
        bitis.bitti = { [weak self] in self?.ayetBitti() }
        let m = NotificationCenter.default
        gozlemciler.append(m.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] not in
            guard let ham = not.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt, let tip = AVAudioSession.InterruptionType(rawValue: ham) else { return }
            let devamEt = ((not.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt).map { AVAudioSession.InterruptionOptions(rawValue: $0).contains(.shouldResume) }) ?? false
            Task { @MainActor in
                guard let self, self.etkin else { return }
                if tip == .began, self.caliyor { self.durumYaz(false) }
                if tip == .ended, devamEt, self.oynatici != nil || self.akis != nil { self.devamEt() }
            }
        })
        gozlemciler.append(m.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] not in
            guard let ham = not.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  AVAudioSession.RouteChangeReason(rawValue: ham) == .oldDeviceUnavailable else { return }
            Task { @MainActor in self?.duraklat() }
        })
    }

    func ayarla(_ a: Ayarlar) {
        let yeni = Hafiz.bul(a.tilavetHafiz)
        if yeni != hafiz { hafizSec(yeni) }
        if Float(a.tilavetHiz) != hiz { hizAyarla(Float(a.tilavetHiz)) }
        takip = a.tilavetTakip
        devam = a.tilavetDevam
    }

    // MARK: Çalma

    /// Sûrenin bir âyetinden başlar. 1. âyetten başlarken (Fâtiha ve Tevbe dışında) önce besmele okunur.
    func cal(sure s: Int, ayet a: Int) {
        guard (1...114).contains(s) else { return }
        sure = s
        ayet = (a <= 1 && s != 1 && s != 9) ? 0 : max(1, min(a, TilavetMotoru.ayetSayilari[s - 1]))
        tekrarSayac = 0
        hata = nil
        SesOturumu.tilavet = true
        oynat()
    }

    func degistirOynat() { caliyor ? duraklat() : devamEt() }

    func devamEt() {
        guard etkin else { return }
        if let p = akis {
            SesOturumu.tilavet = true
            SesOturumu.hazirla()
            p.playImmediately(atRate: hiz)
            durumYaz(true)
        } else if let o = oynatici, !bekliyor {
            SesOturumu.tilavet = true
            SesOturumu.hazirla()
            o.play()
            durumYaz(true)
        } else {
            oynat()
        }
    }

    func duraklat() {
        guard etkin else { return }
        oynatici?.pause()
        akis?.pause()
        durumYaz(false)
    }

    /// Tamamen durur; okuyucudaki vurgu kalkar.
    func dur() {
        nesil += 1
        oynatici?.stop()
        oynatici = nil
        akisKapat()
        sure = 0
        ayet = 0
        bekliyor = false
        durumYaz(false)
        SesOturumu.tilavet = false
        SimdiCalan.guncelle()
    }

    func sonraki() {
        guard etkin else { return }
        tekrarSayac = 0
        if ayet < sureAyetSayisi { ayet += 1; oynat() } else { sureBitti() }
    }

    func onceki() {
        guard etkin else { return }
        tekrarSayac = 0
        // Âyetin başından 3 sn geçtiyse önce âyetin başına döner.
        if let o = oynatici, o.currentTime > 3 { o.currentTime = 0; SimdiCalan.guncelle(); return }
        if akis != nil, gecen - kesinBaslangic(ayet) > 3 { akisAra(kesinBaslangic(ayet)); return }
        let ilk = (sure != 1 && sure != 9) ? 0 : 1
        ayet = max(ilk, ayet - 1)
        oynat()
    }

    /// Okuyucuda bir âyete dokununca oradan sürer.
    func atla(ayet a: Int) {
        guard etkin else { return }
        tekrarSayac = 0
        ayet = max(0, min(a, sureAyetSayisi))
        oynat()
    }

    func hafizSec(_ h: Hafiz) {
        guard h != hafiz else { return }
        hafiz = h
        if etkin { tekrarSayac = 0; oynat() }
    }

    func tekrarAyarla(_ n: Int) {
        tekrar = max(0, n)
        tekrarSayac = 0
    }

    func hizAyarla(_ v: Float) {
        hiz = max(0.5, min(2, v))
        oynatici?.rate = hiz
        akis?.defaultRate = hiz
        if let p = akis, p.rate > 0 { p.rate = hiz }
        SimdiCalan.guncelle()
    }

    private func oynat() {
        if hafiz.tamSure { akisOynat(); return }
        akisKapat()
        nesil += 1
        let n = nesil, s = sure, a = ayet, h = hafiz
        oynatici?.stop()
        bekliyor = true
        durumYaz(true)
        Task { @MainActor in
            let url = await self.dosya(h, s, a == 0 ? nil : a)
            guard n == self.nesil else { return }
            self.bekliyor = false
            guard let url, let o = try? AVAudioPlayer(contentsOf: url) else {
                self.hata = "Kayıt indirilemedi. İnternet bağlantını kontrol edip tekrar dene."
                self.durumYaz(false)
                return
            }
            self.hata = nil
            o.enableRate = true
            o.rate = self.hiz
            o.delegate = self.bitis
            o.prepareToPlay()
            self.oynatici = o
            SesOturumu.tilavet = true
            SesOturumu.hazirla()
            o.play()
            self.durumYaz(true)
            self.oncedenIndir(h, s, a)
        }
    }

    private func ayetBitti() {
        guard etkin else { return }
        tekrarSayac += 1
        if ayet > 0, tekrar == 0 || tekrarSayac < tekrar {
            oynatici?.currentTime = 0
            oynatici?.play()
            SimdiCalan.guncelle()
            return
        }
        tekrarSayac = 0
        if ayet < sureAyetSayisi { ayet += 1; oynat() } else { sureBitti() }
    }

    private func sureBitti() {
        if devam, sure < 114 {
            cal(sure: sure + 1, ayet: 1)
        } else {
            oynatici?.stop()
            oynatici = nil
            akisKapat()
            durumYaz(false)
            Dokunsal.basari()
        }
    }

    private func durumYaz(_ c: Bool) {
        if caliyor != c { caliyor = c; degisti?(c) }
        SimdiCalan.guncelle()
    }

    var gecen: TimeInterval {
        if let p = akis { let t = p.currentTime().seconds; return t.isFinite ? t : 0 }
        return oynatici?.currentTime ?? 0
    }
    var uzunluk: TimeInterval {
        if let d = akis?.currentItem?.duration.seconds { return d.isFinite ? d : 0 }
        return oynatici?.duration ?? 0
    }

    // MARK: Bütün sûre akışı (mp3quran)

    /// Zamana göre okunan âyet. Cetvelin ilk âyetinden önceki kısım besmeledir (Fâtiha ve Tevbe'de istiâze; 1. âyet sayılır).
    nonisolated static func ayetBul(_ sn: Double, _ z: [AyetZamani], sure: Int) -> Int? {
        guard let ilk = z.first else { return nil }
        let ms = sn * 1000
        if ms < ilk.start_time { return (sure == 1 || sure == 9) ? ilk.ayah : 0 }
        var lo = 0, hi = z.count - 1
        while lo < hi {
            let m = (lo + hi + 1) / 2
            if z[m].start_time <= ms { lo = m } else { hi = m - 1 }
        }
        return z[lo].ayah
    }

    /// Âyetin başladığı an (sn). 1. âyet ya da besmele için baştan (besmele de okunsun).
    private func baslangic(_ a: Int) -> Double { a <= 1 ? 0 : kesinBaslangic(a) }
    private func kesinBaslangic(_ a: Int) -> Double {
        guard a > 0, let z = zamanlar.first(where: { $0.ayah == a }) else { return 0 }
        return z.start_time / 1000
    }

    private func akisOynat() {
        oynatici?.stop()
        oynatici = nil
        let anahtar = hafiz.id + "|" + String(sure)
        // Aynı sûre açıksa yalnız yerini değiştirir (besmele: baştan; âyet: tam başı).
        if let p = akis, anahtar == akisAnahtari {
            akisAra(ayet <= 0 ? 0 : kesinBaslangic(ayet))
            if p.rate == 0 { SesOturumu.tilavet = true; SesOturumu.hazirla(); p.playImmediately(atRate: hiz) }
            durumYaz(true)
            return
        }
        akisKapat()
        nesil += 1
        let n = nesil, s = sure, h = hafiz
        bekliyor = true
        durumYaz(true)
        Task { @MainActor in
            let z = await TilavetMotoru.zamanlar(h, s) ?? []
            guard n == self.nesil, let uzak = TilavetMotoru.uzakSure(h, s) else { return }
            let yerel = TilavetMotoru.yerelSure(h, s)
            let varMi = FileManager.default.fileExists(atPath: yerel.path)
            let secenek: [String: Any]? = varMi ? [AVURLAssetPreferPreciseDurationAndTimingKey: true] : nil
            let varlik = AVURLAsset(url: varMi ? yerel : uzak, options: secenek)
            let oge = AVPlayerItem(asset: varlik)
            oge.audioTimePitchAlgorithm = .timeDomain
            let p = AVPlayer(playerItem: oge)
            p.defaultRate = self.hiz
            self.akis = p
            self.akisAnahtari = h.id + "|" + String(s)
            self.zamanlar = z
            self.akisGozlemi = p.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 8), queue: .main) { [weak self] t in
                MainActor.assumeIsolated { self?.zamanIlerledi(t.seconds) }
            }
            self.akisBitisi = NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification, object: oge, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.akisBitti() }
            }
            self.akisDurumlari = [
                p.observe(\.timeControlStatus) { [weak self] o, _ in
                    let bekle = o.timeControlStatus == .waitingToPlayAtSpecifiedRate
                    Task { @MainActor in self?.bekliyor = bekle }
                },
                oge.observe(\.status) { [weak self] o, _ in
                    guard o.status == .failed else { return }
                    Task { @MainActor in
                        guard let self, n == self.nesil else { return }
                        self.hata = "Kayıt açılamadı. İnternet bağlantını kontrol edip tekrar dene."
                        self.akisKapat()
                        self.durumYaz(false)
                    }
                },
            ]
            let bas = self.baslangic(self.ayet)
            if bas > 0 { _ = await p.seek(to: CMTime(seconds: bas, preferredTimescale: 1000), toleranceBefore: .zero, toleranceAfter: .zero) }
            guard n == self.nesil else { return }
            self.hata = z.isEmpty ? "Bu kayıtta âyet takibi yok; sûre baştan sona okunur." : nil
            SesOturumu.tilavet = true
            SesOturumu.hazirla()
            p.playImmediately(atRate: self.hiz)
            self.durumYaz(true)
        }
    }

    private func akisAra(_ sn: Double) {
        guard let p = akis else { return }
        araniyor = true
        p.seek(to: CMTime(seconds: sn, preferredTimescale: 1000), toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            Task { @MainActor in self?.araniyor = false; SimdiCalan.guncelle() }
        }
    }

    private func zamanIlerledi(_ sn: Double) {
        guard etkin, akis != nil, !araniyor, let a = TilavetMotoru.ayetBul(sn, zamanlar, sure: sure), a != ayet else { return }
        // Bir sonraki âyete geçerken tekrar sırası bitmediyse âyetin başına döner.
        if a == ayet + 1, ayet > 0, tekrar != 1, tekrar == 0 || tekrarSayac + 1 < tekrar {
            tekrarSayac += 1
            akisAra(kesinBaslangic(ayet))
            return
        }
        tekrarSayac = 0
        ayet = a
        SimdiCalan.guncelle()
    }

    private func akisBitti() {
        guard etkin, akis != nil else { return }
        if ayet > 0, tekrar != 1, tekrar == 0 || tekrarSayac + 1 < tekrar {
            tekrarSayac += 1
            akisAra(kesinBaslangic(ayet))
            akis?.playImmediately(atRate: hiz)
            return
        }
        tekrarSayac = 0
        sureBitti()
    }

    private func akisKapat() {
        if let g = akisGozlemi { akis?.removeTimeObserver(g) }
        if let b = akisBitisi { NotificationCenter.default.removeObserver(b) }
        akisDurumlari.forEach { $0.invalidate() }
        akisDurumlari = []
        akisGozlemi = nil
        akisBitisi = nil
        akis?.pause()
        akis = nil
        akisAnahtari = ""
        araniyor = false
    }

    // MARK: Dosyalar

    /// Uygulama Desteği/Tilavet: yeniden indirilebilir kayıtlar iCloud yedeğine girmez.
    nonisolated static var klasor: URL {
        var u = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Tilavet")
        if !FileManager.default.fileExists(atPath: u.path) {
            try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        }
        if (try? u.resourceValues(forKeys: [.isExcludedFromBackupKey]))?.isExcludedFromBackup != true {
            var d = URLResourceValues()
            d.isExcludedFromBackup = true
            try? u.setResourceValues(d)
        }
        return u
    }

    /// a nil: besmele (Fâtiha'nın ilk âyeti).
    nonisolated static func ad(_ s: Int, _ a: Int?) -> String { a.map { String(format: "%03d%03d", s, $0) } ?? "001001" }

    nonisolated static func yerel(_ h: Hafiz, _ s: Int, _ a: Int?) -> URL {
        let k = klasor.appendingPathComponent(h.id)
        try? FileManager.default.createDirectory(at: k, withIntermediateDirectories: true)
        return k.appendingPathComponent(ad(s, a) + ".mp3")
    }

    nonisolated static func yerelSure(_ h: Hafiz, _ s: Int) -> URL {
        let k = klasor.appendingPathComponent(h.id)
        try? FileManager.default.createDirectory(at: k, withIntermediateDirectories: true)
        return k.appendingPathComponent(String(format: "%03d.mp3", s))
    }

    nonisolated static func uzakSure(_ h: Hafiz, _ s: Int) -> URL? {
        h.klasor.flatMap { URL(string: $0 + String(format: "%03d.mp3", s)) }
    }

    /// Sûrenin âyet zamanları: önce telefondan, yoksa mp3quran'dan (inince saklanır).
    nonisolated static func zamanlar(_ h: Hafiz, _ s: Int) async -> [AyetZamani]? {
        guard let no = h.okuyucu else { return nil }
        let k = klasor.appendingPathComponent(h.id)
        try? FileManager.default.createDirectory(at: k, withIntermediateDirectories: true)
        let dosya = k.appendingPathComponent(String(format: "%03d.json", s))
        if let d = try? Data(contentsOf: dosya), let z = try? JSONDecoder().decode([AyetZamani].self, from: d), !z.isEmpty { return z }
        guard let url = URL(string: zamanKaynagi + "?surah=\(s)&read=\(no)") else { return nil }
        for _ in 0..<2 {
            if let (d, y) = try? await URLSession.shared.data(from: url), (y as? HTTPURLResponse)?.statusCode == 200,
               let z = try? JSONDecoder().decode([AyetZamani].self, from: d), !z.isEmpty {
                let sirali = z.filter { $0.ayah > 0 }.sorted { $0.start_time < $1.start_time }
                if let j = try? JSONEncoder().encode(sirali) { try? j.write(to: dosya, options: .atomic) }
                return sirali
            }
        }
        return nil
    }

    private func dosya(_ h: Hafiz, _ s: Int, _ a: Int?) async -> URL? {
        let hedef = TilavetMotoru.yerel(h, s, a)
        if FileManager.default.fileExists(atPath: hedef.path) { return hedef }
        let anahtar = h.id + "/" + TilavetMotoru.ad(s, a)
        if let g = inenler[anahtar] { return await g.value }
        let g = Task.detached(priority: .userInitiated) { () -> URL? in
            guard let url = URL(string: TilavetMotoru.kaynak + h.id + "/" + TilavetMotoru.ad(s, a) + ".mp3") else { return nil }
            for _ in 0..<2 {
                if let (gecici, yanit) = try? await URLSession.shared.download(from: url),
                   (yanit as? HTTPURLResponse)?.statusCode == 200 {
                    try? FileManager.default.removeItem(at: hedef)
                    if (try? FileManager.default.moveItem(at: gecici, to: hedef)) != nil { return hedef }
                }
            }
            return nil
        }
        inenler[anahtar] = g
        let sonuc = await g.value
        inenler[anahtar] = nil
        return sonuc
    }

    /// Sıradaki üç âyeti arka planda indirir; geçişte bekleme olmaz.
    private func oncedenIndir(_ h: Hafiz, _ s: Int, _ a: Int) {
        let son = TilavetMotoru.ayetSayilari[s - 1]
        guard a < son else { return }
        let sira = Array(a + 1...min(son, a + 3))
        Task { @MainActor in for x in sira { _ = await self.dosya(h, s, x) } }
    }

    func indirmeAnahtari(_ s: Int) -> String { hafiz.id + "|" + String(s) }

    func indirildi(_ s: Int) -> Bool {
        if hafiz.tamSure { return FileManager.default.fileExists(atPath: TilavetMotoru.yerelSure(hafiz, s).path) }
        let k = TilavetMotoru.klasor.appendingPathComponent(hafiz.id)
        let adlar = Set((try? FileManager.default.contentsOfDirectory(atPath: k.path)) ?? [])
        return (1...TilavetMotoru.ayetSayilari[s - 1]).allSatisfy { adlar.contains(TilavetMotoru.ad(s, $0) + ".mp3") }
    }

    /// Sûrenin bütün âyetlerini (ve besmeleyi) ya da bütün sûre kaydını indirir.
    func sureyiIndir(_ s: Int) {
        let h = hafiz, anahtar = indirmeAnahtari(s)
        guard indirmeler[anahtar] == nil else { return }
        indirmeler[anahtar] = 0
        if h.tamSure {
            surIndirme = Task { @MainActor in
                _ = await TilavetMotoru.zamanlar(h, s)
                var tamam = false
                if let uzak = TilavetMotoru.uzakSure(h, s) {
                    tamam = await Indirici.indir(uzak, TilavetMotoru.yerelSure(h, s)) { o in
                        Task { @MainActor in if self.indirmeler[anahtar] != nil { self.indirmeler[anahtar] = o } }
                    }
                }
                self.indirmeler[anahtar] = nil
                if !tamam, !Task.isCancelled { self.hata = "Sûre indirilemedi; sonra tekrar dene." }
            }
            return
        }
        surIndirme = Task { @MainActor in
            let son = TilavetMotoru.ayetSayilari[s - 1]
            var liste: [Int?] = (s != 1 && s != 9) ? [nil] : []
            liste += (1...son).map { Optional($0) }
            var tamam = 0, hatali = 0
            for a in liste {
                if Task.isCancelled { break }
                if await self.dosya(h, s, a) == nil { hatali += 1 }
                tamam += 1
                self.indirmeler[anahtar] = Double(tamam) / Double(liste.count)
            }
            self.indirmeler[anahtar] = nil
            if hatali > 0 { self.hata = "\(hatali) âyet indirilemedi; sonra tekrar dene." }
        }
    }

    func indirmeyiDurdur() {
        surIndirme?.cancel()
        surIndirme = nil
        indirmeler = [:]
    }

    /// Telefondaki tilavet kayıtlarının toplam boyutu (bayt).
    nonisolated static func boyut() -> Int64 {
        guard let e = FileManager.default.enumerator(at: klasor, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var t: Int64 = 0
        for case let u as URL in e { t += Int64((try? u.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0) }
        return t
    }

    func kayitlariSil() {
        dur()
        try? FileManager.default.removeItem(at: TilavetMotoru.klasor)
    }
}

/// Büyük dosyaları ilerlemesini bildirerek indirir; görev iptal edilirse indirme de durur.
enum Indirici {
    private final class Kutu: @unchecked Sendable {
        var gorev: URLSessionDownloadTask?
        var gozlem: NSKeyValueObservation?
    }

    nonisolated static func indir(_ kaynak: URL, _ hedef: URL, ilerleme: @escaping @Sendable (Double) -> Void) async -> Bool {
        let k = Kutu()
        return await withTaskCancellationHandler {
            await withCheckedContinuation { (devam: CheckedContinuation<Bool, Never>) in
                let g = URLSession.shared.downloadTask(with: kaynak) { gecici, yanit, _ in
                    var tamam = false
                    if let gecici, (yanit as? HTTPURLResponse)?.statusCode == 200 {
                        try? FileManager.default.removeItem(at: hedef)
                        tamam = (try? FileManager.default.moveItem(at: gecici, to: hedef)) != nil
                    }
                    k.gozlem?.invalidate()
                    devam.resume(returning: tamam)
                }
                k.gozlem = g.progress.observe(\.fractionCompleted) { p, _ in ilerleme(p.fractionCompleted) }
                k.gorev = g
                g.resume()
            }
        } onCancel: {
            k.gorev?.cancel()
        }
    }
}

/// AVAudioPlayer temsilcisi NSObject ister; motor saf Swift kalsın diye ayrı tutulur.
private final class BitisTemsilcisi: NSObject, AVAudioPlayerDelegate {
    var bitti: (@MainActor () -> Void)?
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.bitti?() }
    }
}

// MARK: Kilit ekranı

/// Kilit ekranı ve Denetim Merkezi: tilavet etkinse onu, değilse odak seslerini gösterir; çal/durdur, önceki/sonraki.
@MainActor
enum SimdiCalan {
    static weak var ses: SesMotoru?
    private static var kuruldu = false
    private static var kapaklar: [Int: MPMediaItemArtwork] = [:]

    static func kur(ses s: SesMotoru) {
        ses = s
        guard !kuruldu else { return }
        kuruldu = true
        let m = MPRemoteCommandCenter.shared()
        let t = TilavetMotoru.ortak
        // Komutlar ana iş parçacığında gelir.
        m.playCommand.addTarget { _ in
            MainActor.assumeIsolated { if t.etkin { t.devamEt() } else { ses?.oynat() } }
            return .success
        }
        m.pauseCommand.addTarget { _ in
            MainActor.assumeIsolated { if t.etkin { t.duraklat() } else { ses?.duraklat() } }
            return .success
        }
        m.togglePlayPauseCommand.addTarget { _ in
            MainActor.assumeIsolated { if t.etkin { t.degistirOynat() } else { ses?.degistirOynat() } }
            return .success
        }
        m.nextTrackCommand.addTarget { _ in
            MainActor.assumeIsolated { if t.etkin { t.sonraki() } }
            return .success
        }
        m.previousTrackCommand.addTarget { _ in
            MainActor.assumeIsolated { if t.etkin { t.onceki() } }
            return .success
        }
    }

    static func guncelle() {
        let t = TilavetMotoru.ortak
        let m = MPRemoteCommandCenter.shared()
        m.nextTrackCommand.isEnabled = t.etkin
        m.previousTrackCommand.isEnabled = t.etkin
        let merkez = MPNowPlayingInfoCenter.default()
        if t.etkin {
            let sureAdi = KuranDeposu.ortak.sure(t.sure)?.ad ?? "\(t.sure). sûre"
            var bilgi: [String: Any] = [
                MPMediaItemPropertyTitle: "\(sureAdi) · " + (t.ayet == 0 ? "Besmele" : "\(t.ayet). âyet"),
                MPMediaItemPropertyArtist: t.hafiz.ad,
                MPMediaItemPropertyAlbumTitle: "Kur'an-ı Kerîm · \(t.sureAyetSayisi) âyet",
                MPNowPlayingInfoPropertyPlaybackRate: t.caliyor ? Double(t.hiz) : 0,
                MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0,
                MPMediaItemPropertyPlaybackDuration: t.uzunluk,
                MPNowPlayingInfoPropertyElapsedPlaybackTime: t.gecen,
            ]
            if let k = kapak(t.sure) { bilgi[MPMediaItemPropertyArtwork] = k }
            merkez.nowPlayingInfo = bilgi
        } else if let s = ses, !s.katman.isEmpty {
            var bilgi: [String: Any] = [
                MPMediaItemPropertyTitle: s.seciliAdlar,
                MPMediaItemPropertyArtist: "Odak sesleri",
                MPMediaItemPropertyAlbumTitle: "İhya",
                MPNowPlayingInfoPropertyPlaybackRate: s.caliyor ? 1.0 : 0.0,
                MPNowPlayingInfoPropertyIsLiveStream: true,
            ]
            if let k = kapak(0) { bilgi[MPMediaItemPropertyArtwork] = k }
            merkez.nowPlayingInfo = bilgi
        } else {
            merkez.nowPlayingInfo = nil
        }
    }

    /// Kilit ekranı görseli: sûrenin Arapça adı sekiz köşeli yıldızın ortasında (0: odak sesleri).
    private static func kapak(_ sure: Int) -> MPMediaItemArtwork? {
        if let k = kapaklar[sure] { return k }
        let ad = sure == 0 ? "" : (KuranDeposu.ortak.sure(sure)?.arapca ?? "")
        let r = ImageRenderer(content: KapakGorseli(arapca: ad, sure: sure))
        r.scale = 3
        guard let resim = r.uiImage else { return nil }
        let k = MPMediaItemArtwork(boundsSize: resim.size) { _ in resim }
        kapaklar[sure] = k
        return k
    }
}

private struct KapakGorseli: View {
    let arapca: String
    let sure: Int
    var body: some View {
        ZStack {
            LinearGradient(colors: sure == 0 ? [Color(hex: "#0E3B2A"), Color(hex: "#1FB25A")] : [Color(hex: "#1B1446"), Color(hex: "#3B2C8C")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            SekizKoseYildiz(ic: 0.72).stroke(Color(hex: "#F3D27A").opacity(0.7), lineWidth: 3).frame(width: 150, height: 150)
            SekizKoseYildiz(ic: 0.72).stroke(Color(hex: "#F3D27A").opacity(0.3), lineWidth: 2).frame(width: 118, height: 118).rotationEffect(.degrees(22.5))
            if sure == 0 {
                Image(systemName: "waveform").font(.system(size: 54, weight: .semibold)).foregroundStyle(.white)
            } else {
                Text(arapca).font(.arapca(30, kalin: true)).foregroundStyle(Color(hex: "#F3D27A")).lineLimit(1).minimumScaleFactor(0.5).frame(width: 112)
            }
        }
        .frame(width: 200, height: 200)
    }
}
