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
