import Foundation
import Observation
import UIKit

/// Odak oturumunun yaşam döngüsü: başlat, kilit/uygulamadan çıkış ayrımı, tamamla, vazgeç.
/// Ekran kilitlemek serbesttir; katı kipte başka uygulamaya geçip 10 saniyeden uzun kalınırsa bitki kurur.
@MainActor
@Observable
final class OdakMotoru {
    enum Hal: Equatable {
        case bos
        case calisiyor
        case bitti(OdakOturumu)
        case kurudu(OdakOturumu)
    }

    private(set) var hal: Hal = .bos
    private(set) var devam: DevamEdenOdak?
    /// Tamamlanan oturumdan sonra kilidi açılabilecek ilk tür (kutlama ekranı için)
    private(set) var sonKazanc = 0

    private let depo: Depo
    @ObservationIgnored private weak var ses: SesMotoru?
    @ObservationIgnored private var arkaPlanGiris: Date?
    @ObservationIgnored private var sonKilit: Date?
    @ObservationIgnored private var arkaGorev: UIBackgroundTaskIdentifier = .invalid
    @ObservationIgnored private var kontrolGorevi: Task<Void, Never>?

    static let tolerans: TimeInterval = 10

    init(depo: Depo) {
        self.depo = depo
        KilitDinleyici.kur { [weak self] in self?.sonKilit = Date() }
        NotificationCenter.default.addObserver(forName: UIApplication.protectedDataWillBecomeUnavailableNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.sonKilit = Date() }
        }
        if let d = depo.kayit.devam {
            devam = d
            hal = .calisiyor
            if Date() >= d.bitis { tamamla() } else { izle() }
        }
    }

    func bagla(_ ses: SesMotoru) { self.ses = ses }

    nonisolated static func tohumKazanci(_ dk: Int) -> Int { Int((0.05 * pow(Double(dk), 1.3)).rounded()) }

    var gecenDakika: Double {
        guard let d = devam else { return 0 }
        return min(Double(d.plan), max(0, Date().timeIntervalSince(d.baslangic) / 60))
    }

    // MARK: Akış

    func baslat(tur: String, plan: Int, konu: UUID?, ad: String) {
        let d = DevamEdenOdak(baslangic: Date(), plan: plan, tur: tur, tohum: Int.random(in: 1...9999), konu: konu, ad: ad, kati: depo.ayarlar.katiMod)
        devam = d
        hal = .calisiyor
        depo.degistir { $0.devam = d; $0.sonTur = tur; $0.sonPlan = plan }
        depo.hemenKaydet()
        Bildirim.odakBitti(d.bitis, bitki: BitkiKatalogu.ad(tur))
        if depo.ayarlar.sesOdakta, !depo.kayit.sonKatman.isEmpty, let ses {
            if !ses.caliyor { ses.yukle(depo.kayit.sonKatman, baslat: true) }
            if depo.ayarlar.sesSondaAzalt { ses.sondaAzalt(bitis: d.bitis) }
        }
        Efekt.cal("efekt_baslat", duzey: 0.5)
        Dokunsal.orta()
        izle()
    }

    func vazgec() {
        guard let d = devam else { return }
        let o = OdakOturumu(baslangic: d.baslangic, plan: d.plan, sure: gecenDakika, tur: d.tur, tohum: d.tohum, konu: d.konu, ad: d.ad, durum: .vazgecildi)
        bitir(o)
        hal = .kurudu(o)
        Efekt.cal("efekt_vazgec", duzey: 0.5)
        Dokunsal.uyari()
    }

    func tamamla() {
        guard let d = devam else { return }
        let kazanc = OdakMotoru.tohumKazanci(d.plan)
        let o = OdakOturumu(baslangic: d.baslangic, plan: d.plan, sure: Double(d.plan), tur: d.tur, tohum: d.tohum, konu: d.konu, ad: d.ad, durum: .tamam, kazanc: kazanc)
        sonKazanc = kazanc
        bitir(o)
        depo.degistir { $0.tohum += kazanc }
        hal = .bitti(o)
        if UIApplication.shared.applicationState == .active {
            Efekt.cal("efekt_kutlama", duzey: 0.7)
            Dokunsal.basari()
        }
    }

    func kapat() { hal = .bos }

    // MARK: Ekran görüntüsü örnekleri

    func ornekBaslat() {
        devam = DevamEdenOdak(baslangic: Date().addingTimeInterval(-11 * 60), plan: 30, tur: "gul", tohum: 7, konu: depo.kayit.konular.first?.id, ad: "Fıkıh dersi", kati: true)
        hal = .calisiyor
    }

    func ornekBitir() {
        let o = OdakOturumu(baslangic: Date().addingTimeInterval(-30 * 60), plan: 30, sure: 30, tur: "gul", tohum: 7, konu: depo.kayit.konular.first?.id, ad: "Fıkıh dersi", durum: .tamam, kazanc: 4)
        sonKazanc = 4
        hal = .bitti(o)
    }

    private func bitir(_ o: OdakOturumu) {
        kontrolGorevi?.cancel()
        devam = nil
        depo.degistir { $0.oturumlar.append(o); $0.devam = nil }
        depo.hemenKaydet()
        Bildirim.odakIptal()
        if depo.ayarlar.sesOdakta, let ses {
            ses.sonumuIptal()
            if o.durum == .tamam, depo.ayarlar.sesSondaAzalt { ses.duraklat() }
        }
    }

    /// Bitiş anını bekler (uygulama açıkken).
    private func izle() {
        kontrolGorevi?.cancel()
        guard let d = devam else { return }
        kontrolGorevi = Task { @MainActor [weak self] in
            let kalan = d.bitis.timeIntervalSinceNow
            if kalan > 0 { try? await Task.sleep(nanoseconds: UInt64(kalan * 1_000_000_000)) }
            guard !Task.isCancelled, let self, self.devam == d else { return }
            self.tamamla()
        }
    }

    // MARK: Arka plan

    func arkaPlanaGecti() {
        guard let d = devam else { return }
        arkaPlanGiris = Date()
        guard d.kati else { return }
        arkaGorev = UIApplication.shared.beginBackgroundTask(withName: "odak") { [weak self] in Task { @MainActor in self?.arkaGorevBitti() } }
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard let self, self.devam != nil else { return }
            if !self.kilitlendi { Bildirim.odakUyarisi() }
            self.arkaGorevBitti()
        }
    }

    func onPlanaGeldi() {
        Bildirim.uyariyiKaldir()
        defer { arkaPlanGiris = nil; sonKilit = nil }
        guard let d = devam else { return }
        if Date() >= d.bitis { tamamla(); return }
        if d.kati, let giris = arkaPlanGiris, !kilitlendi, Date().timeIntervalSince(giris) > OdakMotoru.tolerans {
            vazgec()
            return
        }
        izle()
    }

    private var kilitlendi: Bool {
        guard let k = sonKilit, let g = arkaPlanGiris else { return false }
        return abs(k.timeIntervalSince(g)) < 4 || k > g
    }

    private func arkaGorevBitti() {
        if arkaGorev != .invalid { UIApplication.shared.endBackgroundTask(arkaGorev); arkaGorev = .invalid }
    }
}

/// Ekranın kilitlendiğini sistem bildiriminden öğrenir (uygulamadan çıkmakla kilitlemeyi ayırmak için).
enum KilitDinleyici {
    private static var geriCagri: (@MainActor () -> Void)?

    @MainActor
    static func kur(_ c: @escaping @MainActor () -> Void) {
        geriCagri = c
        let merkez = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterAddObserver(merkez, nil, kilitGeriCagrisi, "com.apple.springboard.lockcomplete" as CFString, nil, .deliverImmediately)
    }

    fileprivate static func bildir() { Task { @MainActor in geriCagri?() } }
}

private let kilitGeriCagrisi: CFNotificationCallback = { _, _, _, _, _ in KilitDinleyici.bildir() }
