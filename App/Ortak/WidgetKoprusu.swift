import ActivityKit
import Foundation
import UIKit
import WidgetKit

/// Uygulamadan widget'lara: özet veriyi ve son fidanın resmini ortak klasöre yazar, widget'ları yeniler.
@MainActor
enum WidgetKoprusu {
    private static var sonVeri: WidgetVerisi?
    private static var sonResim = ""

    static func guncelle(_ depo: Depo, _ vakit: VakitServisi) {
        guard !EkranGoruntusu.etkin, let dosya = Paylasim.veriDosyasi else { return }
        let c = Calendar.current
        let d = depo.seriDurumu(vakit)
        let bugunGun = vakit.imsakGunu(.now)
        let bugunkuler = depo.kayit.oturumlar.filter { $0.durum == .tamam && vakit.imsakGunu($0.baslangic) == bugunGun }
        var vakitler: [WidgetVakti] = []
        for g in 0..<3 {
            let gun = c.date(byAdding: .day, value: g, to: .now)!
            for (i, z) in vakit.vakitler(gun).enumerated() { vakitler.append(WidgetVakti(ad: VakitAdi.adlar[i], zaman: z)) }
        }
        let son = depo.kayit.oturumlar.last { $0.durum == .tamam }
        var veri = WidgetVerisi(
            guncelleme: .now, seri: d.seri, rahmet: d.rahmet, bugunDikildi: d.bugunDikildi, telafi: d.telafi?.kalan,
            bugunDk: Int(bugunkuler.reduce(0) { $0 + $1.sure }), hedefDk: depo.ayarlar.gunlukHedef, bugunFidan: bugunkuler.count,
            sonBitki: son.map { BitkiKatalogu.ad($0.tur) }, namazKilinan: depo.kayit.namaz[Depo.gunAnahtari(.now)]?.count ?? 0,
            konum: vakit.konumAdi, hicri: vakit.hicri(.now), vakitler: vakitler)
        if let s = sonVeri { veri.guncelleme = s.guncelleme }
        guard veri != sonVeri else { return }
        veri.guncelleme = .now
        sonVeri = veri
        if let j = try? JSONEncoder().encode(veri) { try? j.write(to: dosya, options: .atomic) }
        WidgetCenter.shared.reloadAllTimelines()

        // Son fidanın resmi (değiştiyse)
        if let son, let hedef = Paylasim.bitkiResmi {
            let anahtar = "\(son.tur)-\(son.plan)-\(son.tohum)"
            guard anahtar != sonResim else { return }
            sonResim = anahtar
            Task {
                guard let r = await BitkiMotoru.ortak.resim(tur: son.tur, dk: Double(son.plan), tohum: son.tohum, boyut: CGSize(width: 120, height: 140),
                                                            olcek: 2, cerceve: CGRect(x: 0, y: 0, width: 100, height: 120), sigdir: true),
                      let png = r.pngData() else { return }
                try? png.write(to: hedef, options: .atomic)
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}

/// Odak oturumunun Canlı Etkinliği: başlarken açılır, molada donar, bitince kapanır.
@MainActor
enum CanliEtkinlik {
    private static var etkinlik: Activity<OdakEtkinligi>?

    static func baslat(_ d: DevamEdenOdak, konu: String) {
        guard !EkranGoruntusu.etkin, ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        bitir()
        let a = OdakEtkinligi(bitki: BitkiKatalogu.ad(d.tur), konu: konu.isEmpty ? "Odak" : konu, plan: d.plan)
        etkinlik = try? Activity.request(attributes: a, content: .init(state: durum(d), staleDate: d.bitis.addingTimeInterval(60)), pushType: nil)
    }

    static func guncelle(_ d: DevamEdenOdak) {
        guard let e = etkinlik else { return }
        let s = durum(d)
        Task { await e.update(.init(state: s, staleDate: d.molada ? nil : d.bitis.addingTimeInterval(60))) }
    }

    static func bitir() {
        let e = etkinlik
        etkinlik = nil
        // Uygulama yeniden açıldığında önceki açılıştan kalanlar da kapansın.
        Task {
            await e?.end(nil, dismissalPolicy: .immediate)
            for x in Activity<OdakEtkinligi>.activities { await x.end(nil, dismissalPolicy: .immediate) }
        }
    }

    private static func durum(_ d: DevamEdenOdak) -> OdakEtkinligi.ContentState {
        let kalan = max(0, Double(d.plan) * 60 - d.gecenSn())
        let bitis = Date().addingTimeInterval(kalan)
        return .init(bitis: bitis, baslangic: bitis.addingTimeInterval(-Double(d.plan) * 60), molada: d.molada, kalanSn: Int(kalan))
    }
}
