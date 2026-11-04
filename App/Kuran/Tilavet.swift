import AVFoundation
import MediaPlayer
import Observation
import SwiftUI

/// Mescid-i Harâm (Kâbe) imamları. Âyet âyet kayıtlar EveryAyah arşivinden indirilir; depoya konmaz.
struct Hafiz: Identifiable, Hashable {
    let id: String        // arşivdeki klasör adı
    let ad: String
    let arapca: String
    /// Rozette görünen kısa Arapça ad.
    let kisa: String
    let unvan: String
    /// Rozet rengi
    let renk: String

    static let tumu: [Hafiz] = [
        Hafiz(id: "Abdurrahmaan_As-Sudais_192kbps", ad: "Abdurrahman es-Südeys", arapca: "عبد الرحمن السديس", kisa: "السديس", unvan: "Kâbe imamı", renk: "#E9C46A"),
        Hafiz(id: "MaherAlMuaiqly128kbps", ad: "Mâhir el-Muaykılî", arapca: "ماهر المعيقلي", kisa: "المعيقلي", unvan: "Kâbe imamı", renk: "#7CC8FF"),
        Hafiz(id: "Yasser_Ad-Dussary_128kbps", ad: "Yâsir ed-Devserî", arapca: "ياسر الدوسري", kisa: "الدوسري", unvan: "Kâbe imamı", renk: "#9BE38F"),
        Hafiz(id: "Abdullaah_3awwaad_Al-Juhaynee_128kbps", ad: "Abdullah el-Cühenî", arapca: "عبد الله الجهني", kisa: "الجهني", unvan: "Kâbe imamı", renk: "#F4A3C4"),
        Hafiz(id: "Saood_ash-Shuraym_128kbps", ad: "Suûd eş-Şüreym", arapca: "سعود الشريم", kisa: "الشريم", unvan: "Kâbe'nin eski imamı", renk: "#C9B6FF"),
        Hafiz(id: "Ali_Jaber_64kbps", ad: "Ali Câbir", arapca: "علي جابر", kisa: "جابر", unvan: "Kâbe'nin eski imamı", renk: "#FFB677"),
    ]
    static func bul(_ id: String) -> Hafiz { tumu.first { $0.id == id } ?? tumu[0] }
}

/// Âyet takipli tilavet: her âyetin kaydı ayrı çalınır; okunan âyet bilinir, okuyucu onu vurgular ve ekranda tutar.
/// Kayıtlar dinlendikçe telefona iner; bir sûre bütünüyle indirilirse internetsiz dinlenir.
@MainActor
@Observable
final class TilavetMotoru {
    static let ortak = TilavetMotoru()
    nonisolated static let kaynak = "https://everyayah.com/data/"
    nonisolated static let ayetSayilari = [7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128, 111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73, 54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6]

    private(set) var hafiz = Hafiz.tumu[0]
    /// 0: etkin değil.
    private(set) var sure = 0
    /// 0: besmele.
    private(set) var ayet = 0
    private(set) var caliyor = false
    /// Âyetin kaydı iniyor.
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

    @ObservationIgnored private var oynatici: AVAudioPlayer?
    @ObservationIgnored private let bitis = BitisTemsilcisi()
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
                if tip == .ended, devamEt, self.oynatici != nil { self.devamEt() }
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
        if let o = oynatici, !bekliyor {
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
        durumYaz(false)
    }

    /// Tamamen durur; okuyucudaki vurgu kalkar.
    func dur() {
        nesil += 1
        oynatici?.stop()
        oynatici = nil
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
        SimdiCalan.guncelle()
    }

    private func oynat() {
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
            durumYaz(false)
            Dokunsal.basari()
        }
    }

    private func durumYaz(_ c: Bool) {
        if caliyor != c { caliyor = c; degisti?(c) }
        SimdiCalan.guncelle()
    }

    var gecen: TimeInterval { oynatici?.currentTime ?? 0 }
    var uzunluk: TimeInterval { oynatici?.duration ?? 0 }

    // MARK: Dosyalar

    nonisolated static var klasor: URL {
        let u = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Tilavet")
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }

    /// a nil: besmele (Fâtiha'nın ilk âyeti).
    nonisolated static func ad(_ s: Int, _ a: Int?) -> String { a.map { String(format: "%03d%03d", s, $0) } ?? "001001" }

    nonisolated static func yerel(_ h: Hafiz, _ s: Int, _ a: Int?) -> URL {
        let k = klasor.appendingPathComponent(h.id)
        try? FileManager.default.createDirectory(at: k, withIntermediateDirectories: true)
        return k.appendingPathComponent(ad(s, a) + ".mp3")
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
        let k = TilavetMotoru.klasor.appendingPathComponent(hafiz.id)
        let adlar = Set((try? FileManager.default.contentsOfDirectory(atPath: k.path)) ?? [])
        return (1...TilavetMotoru.ayetSayilari[s - 1]).allSatisfy { adlar.contains(TilavetMotoru.ad(s, $0) + ".mp3") }
    }

    /// Sûrenin bütün âyetlerini (ve besmeleyi) indirir.
    func sureyiIndir(_ s: Int) {
        let h = hafiz, anahtar = indirmeAnahtari(s)
        guard indirmeler[anahtar] == nil else { return }
        indirmeler[anahtar] = 0
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
