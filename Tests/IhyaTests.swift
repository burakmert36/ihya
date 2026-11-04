import AVFoundation
import XCTest
@testable import Ihya

/// Çekirdek kuralların birim testleri (CI'da simülatörde çalışır).
@MainActor
final class IhyaTests: XCTestCase {
    private let takvim: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Istanbul")!
        return c
    }()

    // Gün sınırı: imsak 05:00 kabul edilir.
    private func gun(_ t: Date) -> Date {
        let g = takvim.startOfDay(for: t)
        return t < g.addingTimeInterval(5 * 3600) ? takvim.date(byAdding: .day, value: -1, to: g)! : g
    }

    private func imsak(_ g: Date) -> Date { g.addingTimeInterval(5 * 3600) }

    /// Bugünden geriye 'gunler' gün önce, saat 'saat'te dikim.
    private func dikim(_ gunOnce: Int, saat: Double = 14, simdi: Date) -> Date {
        takvim.startOfDay(for: takvim.date(byAdding: .day, value: -gunOnce, to: simdi)!).addingTimeInterval(saat * 3600)
    }

    private var simdi: Date { takvim.date(from: DateComponents(year: 2026, month: 11, day: 20, hour: 15))! }

    private func hesapla(_ d: [Date]) -> SeriDurumu {
        Seri.hesapla(dikimler: d, simdi: simdi, gun: gun, imsak: imsak, takvim: takvim)
    }

    // MARK: Seri

    func testHerGunDikilinceSeriVeRahmet() {
        let d = hesapla((0..<10).map { dikim($0, simdi: simdi) })
        XCTAssertEqual(d.seri, 10)
        XCTAssertEqual(d.rahmet, 1)
        XCTAssertEqual(d.rahmeteKalan, 4)
        XCTAssertTrue(d.bugunDikildi)
        XCTAssertNil(d.telafi)
    }

    func testRahmetKacanGunuKapatir() {
        // 8 gün dikim, dün boş, bugün dikim
        let d = hesapla((2..<10).map { dikim($0, simdi: simdi) } + [dikim(0, simdi: simdi)])
        XCTAssertEqual(d.seri, 9)
        XCTAssertEqual(d.rahmet, 0)
        XCTAssertEqual(d.rahmetGunleri.count, 1)
    }

    func testTelafiBekliyor() {
        // 3 gün dikim, dün boş (rahmet yok), bugün henüz dikim yok
        let d = hesapla((2..<5).map { dikim($0, simdi: simdi) })
        XCTAssertEqual(d.seri, 3)
        XCTAssertEqual(d.telafi?.kalan, 2)
        XCTAssertEqual(d.telafi?.onceki, 3)
    }

    func testIkiDikimleTelafi() {
        let d = hesapla((2..<5).map { dikim($0, simdi: simdi) } + [dikim(0, saat: 9, simdi: simdi), dikim(0, saat: 11, simdi: simdi)])
        XCTAssertNil(d.telafi)
        XCTAssertEqual(d.seri, 4)
    }

    func testTelafiOlmazsaSeriSifirlanir() {
        // 3 gün dikim, 4 gün önce boş, 3 gün önce 1 dikim, 2 gün önce boş, dün ve bugün boş
        let d = hesapla((5..<8).map { dikim($0, simdi: simdi) } + [dikim(3, simdi: simdi)])
        XCTAssertEqual(d.seri, 0)
        XCTAssertNil(d.telafi)
        XCTAssertEqual(d.enUzun, 4)
    }

    func testImsaktanOnceDikimOncekiGuneSayilir() {
        // Dün 14.00 ve bugün 03.00 (imsaktan önce) → ikisi de dünkü gün; bugün dikilmedi sayılır
        let d = hesapla([dikim(1, simdi: simdi), dikim(0, saat: 3, simdi: simdi)])
        XCTAssertFalse(d.bugunDikildi)
        XCTAssertEqual(d.seri, 1)
    }

    func testKilometreTaslari() {
        var d = SeriDurumu()
        d.seri = 39
        XCTAssertEqual(d.ulasilanTas, 30)
        XCTAssertEqual(d.sonrakiTas, 40)
    }

    // MARK: Gürültü

    func testGurultuDuzeyiVeDikis() {
        let f = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        for g in Gurultu.allCases {
            guard let t = Gurultu.tampon(g, bicim: f), let k = t.floatChannelData else { return XCTFail("tampon yok \(g)") }
            let n = Int(t.frameLength)
            var kare: Float = 0
            for i in 0..<n { kare += k[0][i] * k[0][i]; XCTAssertFalse(k[0][i].isNaN) }
            let rms = (kare / Float(n)).squareRoot()
            XCTAssertEqual(rms, 0.11, accuracy: 0.03, "\(g) yüksekliği")
            // Dikişte (son örnekten ilk örneğe) sıçrama, ortalama örnek farkından çok büyük olmamalı.
            var fark: Float = 0
            for i in 1..<2000 { fark += abs(k[0][i] - k[0][i - 1]) }
            let dikis = abs(k[0][0] - k[0][n - 1])
            XCTAssertLessThan(dikis, max(0.05, fark / 1999 * 8), "\(g) dikişi")
        }
    }

    // MARK: Yedek

    func testYedekGidipGelir() throws {
        var k = Kayit()
        k.oturumlar = [OdakOturumu(baslangic: simdi, plan: 25, sure: 25, tur: "gul", tohum: 3, konu: nil, durum: .tamam, kazanc: 3)]
        k.kaza = ["sabah": 4]
        k.favoriler = [Favori(tur: .ayet, anahtar: "2:255")]
        k.yedekYeri = Data([1, 2, 3])
        let d = try XCTUnwrap(Yedek.veri(k))
        let geri = try Yedek.coz(d)
        XCTAssertEqual(geri.oturumlar.count, 1)
        XCTAssertEqual(geri.kaza["sabah"], 4)
        XCTAssertEqual(geri.favoriler.first?.tur, .ayet)
        XCTAssertNil(geri.yedekYeri, "cihaza özgü yer imi yedeğe girmemeli")
        XCTAssertThrowsError(try Yedek.coz(Data("{\"x\":1}".utf8)))
    }

    func testEskiKoyuOkumaAyariTemayaTasinir() throws {
        let j = Data("{\"okumaKoyu\":true}".utf8)
        let a = try JSONDecoder().decode(Ayarlar.self, from: j)
        XCTAssertEqual(a.okumaTemasi, .gece)
        XCTAssertEqual(a.ilceKodu, 9335)
    }

    // MARK: İçerik

    func testEsmaDualariHerIsimde() {
        XCTAssertEqual(Icerik.esma.count, 99)
        for e in Icerik.esma { XCTAssertFalse(Icerik.esmaDualari(e.no).isEmpty, "\(e.no). isim duasız") }
    }

    func testNida() {
        XCTAssertEqual(EsmaDetay.nida("el-Latîf"), "Yâ Latîf")
        XCTAssertEqual(EsmaDetay.nida("er-Rahmân"), "Yâ Rahmân")
        XCTAssertEqual(EsmaDetay.nida("eş-Şekûr"), "Yâ Şekûr")
        XCTAssertEqual(EsmaDetay.nida("Allah"), "Yâ Allah")
    }

    func testTilavetTablosu() {
        XCTAssertEqual(TilavetMotoru.ayetSayilari.count, 114)
        XCTAssertEqual(TilavetMotoru.ayetSayilari.reduce(0, +), KuranDeposu.toplamAyet)
        XCTAssertEqual(TilavetMotoru.ad(36, 12), "036012")
        XCTAssertEqual(TilavetMotoru.ad(9, nil), "001001")
        XCTAssertEqual(Hafiz.tumu.count, 22)
        XCTAssertEqual(Set(Hafiz.tumu.map(\.id)).count, Hafiz.tumu.count, "hafız kimlikleri tekil olmalı")
        XCTAssertEqual(Hafiz.tumu[0].id, "Abdurrahmaan_As-Sudais_192kbps", "varsayılan hafız değişmemeli")
        XCTAssertEqual(TilavetMotoru.uzakSure(Hafiz.bul("mp3quran-225"), 36)?.absoluteString, "https://cdn.mp3quran.net/audio/abdulrahman-oosi/r1/036.mp3")
    }

    func testZamanCetvelindenAyet() {
        let z = [AyetZamani(ayah: 1, start_time: 5380, end_time: 8480), AyetZamani(ayah: 2, start_time: 8480, end_time: 14440),
                 AyetZamani(ayah: 3, start_time: 14440, end_time: 18720)]
        XCTAssertEqual(TilavetMotoru.ayetBul(2, z, sure: 2), 0, "ilk âyetten önce besmele")
        XCTAssertEqual(TilavetMotoru.ayetBul(2, z, sure: 1), 1, "Fâtiha'da istiâze 1. âyet sayılır")
        XCTAssertEqual(TilavetMotoru.ayetBul(8.48, z, sure: 2), 2)
        XCTAssertEqual(TilavetMotoru.ayetBul(100, z, sure: 2), 3)
        XCTAssertNil(TilavetMotoru.ayetBul(1, [], sure: 2))
    }

    func testMuezzinSecimi() {
        var a = Ayarlar()
        XCTAssertEqual(a.vaktinMuezzini(4), "mekke")
        a.vakitMuezzin = ["sabah", "", "afasi", "katami", "", "zehrani"]
        XCTAssertEqual(a.vaktinMuezzini(0), "sabah")
        XCTAssertEqual(a.vaktinMuezzini(4), "mekke", "boş vakit genel seçime düşer")
        XCTAssertEqual(Set(Muezzin.tumu.map(\.id)).count, Muezzin.tumu.count)
        XCTAssertTrue(Muezzin.tumu.allSatisfy { $0.url != nil })
    }

    func testPdfYazisiDuzenlenir() {
        let ham = "Bu uzun bir satırdır ve okumayı kolay-\nlaştırmak için birleşmeli, devam eden\ncümle burada bitiyor ama satır uzundur.\nKısa son satır.\n\nYeni paragraf başlıyor."
        let d = KitapDeposu.duzenle(ham)
        XCTAssertTrue(d.contains("kolaylaştırmak"), d)
        XCTAssertTrue(d.contains("devam eden cümle"), d)
        XCTAssertTrue(d.contains("Kısa son satır.\n\nYeni paragraf"), d)
        XCTAssertEqual(KitapDeposu.duzenle(""), "")
    }

    func testEskiKitapKaydiAcilir() throws {
        let j = Data("{\"id\":\"0000000B-0000-4000-8000-000000000001\",\"ad\":\"A\",\"dosya\":\"a.pdf\",\"sayfa\":4,\"toplam\":10,\"eklenme\":0}".utf8)
        let k = try JSONDecoder().decode(Kitap.self, from: j)
        XCTAssertEqual(k.sayfa, 4)
        XCTAssertEqual(k.yakinlik, 1)
        XCTAssertTrue(k.yerImleri.isEmpty)
        XCTAssertFalse(k.tamam)
        XCTAssertEqual(k.oran, 0.5, accuracy: 0.001)
    }

    func testMealAramaKatlamasi() {
        XCTAssertTrue(KuranDeposu.katla("Sabredenlerle beraberdir").contains(KuranDeposu.katla("SABRED")))
        XCTAssertEqual(KuranDeposu.katla("Işık"), KuranDeposu.katla("isik"))
    }
}
