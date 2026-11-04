import AVFoundation
import Foundation
import UserNotifications

/// Vakit bildirimleri ve ezan kayıtları.
@MainActor
enum Bildirim {
    static let merkez = UNUserNotificationCenter.current()

    @discardableResult
    static func izinIste() async -> Bool {
        (try? await merkez.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Önümüzdeki 9 günün vakit bildirimlerini yeniden kurar (iOS en çok 64 bekleyen bildirime izin verir).
    static func vakitleriKur(_ servis: VakitServisi, _ a: Ayarlar) async {
        guard !EkranGoruntusu.etkin else { return }
        let bekleyen = await merkez.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix("vakit-") }
        merkez.removePendingNotificationRequests(withIdentifiers: bekleyen)
        guard a.vakitBildirim.contains(true) else { return }
        let ayar = await merkez.notificationSettings()
        guard ayar.authorizationStatus == .authorized || ayar.authorizationStatus == .provisional else { return }

        let simdi = Date()
        var adet = 0
        for g in 0..<9 {
            let gun = Calendar.current.date(byAdding: .day, value: g, to: simdi)!
            for (i, zaman) in servis.vakitler(gun).enumerated() where a.vakitBildirim[i] {
                let an = zaman.addingTimeInterval(-Double(a.onceDakika) * 60)
                guard an > simdi, adet < 58 else { continue }
                let icerik = UNMutableNotificationContent()
                icerik.title = a.onceDakika > 0 ? "\(VakitAdi.adlar[i]) vaktine \(a.onceDakika) dakika" : "\(VakitAdi.adlar[i]) vakti"
                icerik.body = govde(i, a.onceDakika, zaman)
                icerik.sound = ses(i, a)
                icerik.interruptionLevel = .timeSensitive
                let bilesen = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: an)
                let istek = UNNotificationRequest(identifier: "vakit-\(Depo.gunAnahtari(gun))-\(i)", content: icerik,
                                                  trigger: UNCalendarNotificationTrigger(dateMatching: bilesen, repeats: false))
                try? await merkez.add(istek)
                adet += 1
            }
        }
    }

    private static func govde(_ i: Int, _ once: Int, _ zaman: Date) -> String {
        let saat = Tarihler.saat.string(from: zaman)
        if once > 0 { return "\(VakitAdi.adlar[i]) vakti \(saat)'de giriyor." }
        switch i {
        case 0: return "İmsak vakti girdi (\(saat)). Sabah namazının vakti başladı."
        case 1: return "Güneş doğdu (\(saat)). Sabah namazının vakti çıktı."
        default: return "\(VakitAdi.adlar[i]) namazının vakti girdi (\(saat))."
        }
    }

    private static func ses(_ i: Int, _ a: Ayarlar) -> UNNotificationSound? {
        if a.ezan == .sessiz { return nil }
        if i != 1, a.onceDakika == 0, let kayit = a.ezan.kayitAdi, EzanKaydi.mevcut(kayit) {
            return UNNotificationSound(named: UNNotificationSoundName(kayit + ".caf"))
        }
        return UNNotificationSound(named: UNNotificationSoundName(a.bildirimTonu + ".wav"))
    }

    /// Ayarlar'daki "Deneme bildirimi": 5 sn sonra seçili sesle bir bildirim. Kullanıcıya gösterilecek açıklamayı döndürür.
    static func dene(_ a: Ayarlar) async -> String {
        if await merkez.notificationSettings().authorizationStatus == .notDetermined { _ = await izinIste() }
        let ayar = await merkez.notificationSettings()
        guard ayar.authorizationStatus == .authorized || ayar.authorizationStatus == .provisional else {
            return "Bildirim izni kapalı. iPhone Ayarlar › Ihya › Bildirimler'den aç."
        }
        let icerik = UNMutableNotificationContent()
        icerik.title = "Deneme bildirimi"
        icerik.body = "Vakit bildirimleri bu sesle gelecek."
        icerik.sound = ses(2, a)
        merkez.removePendingNotificationRequests(withIdentifiers: ["deneme"])
        try? await merkez.add(UNNotificationRequest(identifier: "deneme", content: icerik, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)))
        if a.ezan == .sessiz { return "5 saniye sonra sessiz bir bildirim gelecek (ses: Sessiz)." }
        if ayar.soundSetting != .enabled { return "5 saniye sonra gelecek, ama bu uygulamanın bildirim sesi iPhone ayarlarında kapalı." }
        return "5 saniye sonra gelecek. Telefon sessiz kipteyse iOS bildirim sesini çalmaz; zil anahtarını aç."
    }

    // MARK: Seri hatırlatması ve Cuma özeti

    /// Vakit dışı bildirimler (günde en çok iki): bugün dikim yoksa akşamüstü seri hatırlatması, Cuma sabahı haftanın özeti.
    /// Namaz vakitlerinin 20 dakika yakınına düşmez; suçlayıcı dil kullanmaz.
    static func gunlukleriKur(_ depo: Depo, _ vakit: VakitServisi) async {
        guard !EkranGoruntusu.etkin else { return }
        let bekleyen = await merkez.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix("seri-") || $0.hasPrefix("cuma-") }
        merkez.removePendingNotificationRequests(withIdentifiers: bekleyen)
        let ayar = await merkez.notificationSettings()
        guard ayar.authorizationStatus == .authorized || ayar.authorizationStatus == .provisional else { return }
        let a = depo.ayarlar
        let c = Calendar.current
        let simdi = Date()
        if a.seriHatirlatma {
            let durum = depo.seriDurumu(vakit)
            for g in 0..<3 {
                let gun = c.startOfDay(for: c.date(byAdding: .day, value: g, to: simdi)!)
                if g == 0 && durum.bugunDikildi { continue }
                let an = vakittenKacir(gun.addingTimeInterval(Double(a.seriHatirlatmaDk) * 60), vakit)
                guard an > simdi else { continue }
                let icerik = UNMutableNotificationContent()
                if g == 0, let t = durum.telafi {
                    icerik.title = "Serini kurtarabilirsin"
                    icerik.body = "\(t.kalan) fidan daha dikersen \(t.onceki) günlük serin sürer."
                } else if g == 0, durum.seri > 0 {
                    icerik.title = "Bugünün fidanı seni bekliyor"
                    icerik.body = "\(durum.seri) günlük serin sürüyor. Kısa bir odakla bugünü de yeşert."
                } else {
                    icerik.title = "Bugünün fidanı seni bekliyor"
                    icerik.body = "Kısa bir odakla bahçene bir fidan ek; Kur'an, kitap ya da zikir olabilir."
                }
                icerik.sound = UNNotificationSound(named: UNNotificationSoundName("bildirim_damla.wav"))
                let b = c.dateComponents([.year, .month, .day, .hour, .minute], from: an)
                try? await merkez.add(UNNotificationRequest(identifier: "seri-\(Depo.gunAnahtari(gun))", content: icerik,
                                                            trigger: UNCalendarNotificationTrigger(dateMatching: b, repeats: false)))
            }
        }
        if a.cumaOzeti {
            var gun = c.startOfDay(for: simdi)
            while c.component(.weekday, from: gun) != 6 { gun = c.date(byAdding: .day, value: 1, to: gun)! }
            var an = vakittenKacir(gun.addingTimeInterval(10.5 * 3600), vakit)
            if an <= simdi { an = vakittenKacir(c.date(byAdding: .day, value: 7, to: gun)!.addingTimeInterval(10.5 * 3600), vakit) }
            let icerik = UNMutableNotificationContent()
            icerik.title = "Hayırlı Cumalar"
            icerik.body = haftaOzeti(depo)
            icerik.sound = UNNotificationSound(named: UNNotificationSoundName("bildirim_huzur.wav"))
            let b = c.dateComponents([.year, .month, .day, .hour, .minute], from: an)
            try? await merkez.add(UNNotificationRequest(identifier: "cuma-\(Depo.gunAnahtari(an))", content: icerik,
                                                        trigger: UNCalendarNotificationTrigger(dateMatching: b, repeats: false)))
        }
    }

    /// Bir vaktin 20 dakika yakınındaysa o vaktin 25 dakika sonrasına kaydırır.
    static func vakittenKacir(_ an: Date, _ vakit: VakitServisi) -> Date {
        for v in vakit.vakitler(an) where abs(v.timeIntervalSince(an)) < 20 * 60 { return v.addingTimeInterval(25 * 60) }
        return an
    }

    /// Son yedi günün özeti: odak süresi, fidan, namaz, zikir.
    static func haftaOzeti(_ depo: Depo) -> String {
        let c = Calendar.current
        let bas = c.date(byAdding: .day, value: -7, to: .now)!
        let oturum = depo.kayit.oturumlar.filter { $0.durum == .tamam && $0.baslangic >= bas }
        let dk = Int(oturum.reduce(0) { $0 + $1.sure })
        let namaz = (0..<7).reduce(0) { t, i in t + (depo.kayit.namaz[Depo.gunAnahtari(c.date(byAdding: .day, value: -i, to: .now)!)]?.count ?? 0) }
        let zikir = depo.kayit.zikirler.filter { $0.tarih >= bas }.reduce(0) { $0 + $1.sayi }
        var p: [String] = []
        if dk > 0 { p.append(dk >= 60 ? "\(dk / 60) sa \(dk % 60) dk odak" : "\(dk) dk odak") }
        if !oturum.isEmpty { p.append("\(oturum.count) fidan") }
        if namaz > 0 { p.append("\(namaz)/35 namaz") }
        if zikir > 0 { p.append("\(zikir) zikir") }
        return p.isEmpty ? "Yeni haftaya bir fidanla başlamaya ne dersin?" : "Son yedi gün: " + p.joined(separator: ", ") + "."
    }

    // MARK: Odak bildirimleri

    static func odakBitti(_ zaman: Date, bitki: String) {
        let icerik = UNMutableNotificationContent()
        icerik.title = "Odak tamamlandı"
        icerik.body = "\(bitki) bahçene eklendi."
        icerik.sound = UNNotificationSound(named: UNNotificationSoundName("efekt_kutlama.wav"))
        let t = UNTimeIntervalNotificationTrigger(timeInterval: max(1, zaman.timeIntervalSinceNow), repeats: false)
        merkez.add(UNNotificationRequest(identifier: "odak-bitti", content: icerik, trigger: t))
    }

    static func odakUyarisi() {
        let icerik = UNMutableNotificationContent()
        icerik.title = "Bitkin seni bekliyor"
        icerik.body = "10 saniye içinde dönersen odak sürer. Ekranı kilitlemek serbest."
        icerik.sound = .default
        icerik.interruptionLevel = .timeSensitive
        merkez.add(UNNotificationRequest(identifier: "odak-uyari", content: icerik, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)))
    }

    static func odakIptal() {
        merkez.removePendingNotificationRequests(withIdentifiers: ["odak-bitti", "odak-uyari"])
        merkez.removeDeliveredNotifications(withIdentifiers: ["odak-uyari"])
    }

    static func uyariyiKaldir() {
        merkez.removePendingNotificationRequests(withIdentifiers: ["odak-uyari"])
        merkez.removeDeliveredNotifications(withIdentifiers: ["odak-uyari"])
    }
}

/// Kullanıcının eklediği ezan kayıtları. iOS bildirim sesini 30 saniyeyle sınırlar;
/// kaydın ilk 29 saniyesi (sonu yumuşatılarak) Library/Sounds altına CAF olarak yazılır.
enum EzanKaydi {
    static var klasor: URL {
        let u = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0].appendingPathComponent("Sounds")
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }

    static func mevcut(_ ad: String) -> Bool { FileManager.default.fileExists(atPath: klasor.appendingPathComponent(ad + ".caf").path) }

    static func sil(_ ad: String) { try? FileManager.default.removeItem(at: klasor.appendingPathComponent(ad + ".caf")) }

    static func ice(_ kaynak: URL, ad: String) throws {
        let erisim = kaynak.startAccessingSecurityScopedResource()
        defer { if erisim { kaynak.stopAccessingSecurityScopedResource() } }
        let giris = try AVAudioFile(forReading: kaynak)
        let bicim = giris.processingFormat
        let hedef = klasor.appendingPathComponent(ad + ".caf")
        try? FileManager.default.removeItem(at: hedef)
        let ayar: [String: Any] = [AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: bicim.sampleRate, AVNumberOfChannelsKey: bicim.channelCount,
                                   AVLinearPCMBitDepthKey: 16, AVLinearPCMIsFloatKey: false, AVLinearPCMIsBigEndianKey: false]
        let cikis = try AVAudioFile(forWriting: hedef, settings: ayar, commonFormat: .pcmFormatFloat32, interleaved: false)
        let toplam = min(giris.length, AVAudioFramePosition(bicim.sampleRate * 29))
        let sonumBasi = toplam - AVAudioFramePosition(bicim.sampleRate * 1.5)
        guard let tampon = AVAudioPCMBuffer(pcmFormat: bicim, frameCapacity: 16384) else { return }
        var okunan: AVAudioFramePosition = 0
        while okunan < toplam {
            try giris.read(into: tampon, frameCount: AVAudioFrameCount(min(16384, toplam - okunan)))
            let n = Int(tampon.frameLength)
            if n == 0 { break }
            if let kanallar = tampon.floatChannelData {
                for k in 0..<Int(bicim.channelCount) {
                    for j in 0..<n {
                        let konum = okunan + AVAudioFramePosition(j)
                        if konum > sonumBasi { kanallar[k][j] *= Float(toplam - konum) / Float(toplam - sonumBasi) }
                    }
                }
            }
            try cikis.write(from: tampon)
            okunan += AVAudioFramePosition(n)
        }
    }
}
