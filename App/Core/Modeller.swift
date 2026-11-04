import Foundation

/// Odak oturumunun konusu (ders, iş, okuma…). Renk onaltılık metin olarak saklanır.
struct Konu: Codable, Identifiable, Hashable {
    var id = UUID()
    var ad: String
    var renk: String
    var aciklama: String = ""
}

struct OdakOturumu: Codable, Identifiable, Hashable {
    enum Durum: String, Codable { case tamam, vazgecildi }
    var id = UUID()
    var baslangic: Date
    var plan: Int            // planlanan dakika
    var sure: Double         // gerçekleşen dakika
    var tur: String          // bitki türü
    var tohum: Int           // çizim çeşitliliği için tohum
    var konu: UUID?
    var ad: String = ""
    var not: String = ""
    var durum: Durum
    var kazanc: Int = 0      // kazanılan tohum
    var bitis: Date { baslangic.addingTimeInterval(sure * 60) }
}

/// Uygulama kapanırsa kaldığı yerden sürmesi için devam eden odak.
struct DevamEdenOdak: Codable, Hashable {
    var baslangic: Date
    var plan: Int
    var tur: String
    var tohum: Int
    var konu: UUID?
    var ad: String
    var kati: Bool
    /// Biten molaların toplamı (sn) ve süren molanın başı.
    var molaSn: Double? = nil
    var molaBas: Date? = nil
    /// Bu oturum tamamlanınca yeniden yeşerecek kuru bitki.
    var ihya: UUID? = nil

    var molada: Bool { molaBas != nil }

    /// Molalar düşülerek geçen süre (sn).
    func gecenSn(_ an: Date = .now) -> Double {
        let mola = (molaSn ?? 0) + (molaBas.map { max(0, an.timeIntervalSince($0)) } ?? 0)
        return max(0, an.timeIntervalSince(baslangic) - mola)
    }

    /// Molasız sürseydi biteceği an.
    var bitis: Date { Date().addingTimeInterval(Double(plan) * 60 - gecenSn()) }
}

struct ZikirKaydi: Codable, Identifiable, Hashable {
    var id = UUID()
    var baslik: String       // boşsa "Genel zikirler"
    var sayi: Int
    var tarih: Date
    var gorunenAd: String { baslik.isEmpty ? "Genel zikirler" : baslik }
}

struct Karisim: Codable, Identifiable, Hashable {
    var id = UUID()
    var ad: String
    var katman: [String: Double]
    var mesafe: [String: Double]? = nil
}

struct Favori: Codable, Identifiable, Hashable {
    enum Tur: String, Codable { case hadis, soz, dua }
    var tur: Tur
    var anahtar: String
    var tarih = Date()
    var id: String { tur.rawValue + ":" + anahtar }
}

struct Kitap: Codable, Identifiable, Hashable {
    var id = UUID()
    var ad: String
    var dosya: String        // Documents/Kitaplar altındaki dosya adı
    var sayfa: Int = 0
    var toplam: Int = 0
    var eklenme = Date()
    var son: Date?
}

enum EzanTuru: String, Codable, CaseIterable, Identifiable {
    case makamli, tekMuezzin, kisa, sessiz
    var id: String { rawValue }
    var ad: String {
        switch self {
        case .makamli: "Makamlı ezan"
        case .tekMuezzin: "Tek müezzin"
        case .kisa: "Kısa bildirim"
        case .sessiz: "Sessiz"
        }
    }
    /// Library/Sounds altındaki dosya adı (kullanıcının eklediği kayıt).
    var kayitAdi: String? {
        switch self {
        case .makamli: "ezan_makamli"
        case .tekMuezzin: "ezan_tek"
        default: nil
        }
    }
}

enum Tema: String, Codable, CaseIterable, Identifiable {
    case ihya, gece, fildisi, lacivert, zumrut, klasik, gunbatimi, okyanus, gul, mermer, mor
    var id: String { rawValue }
    var ad: String {
        switch self {
        case .ihya: "İhya"
        case .gece: "Gece"
        case .fildisi: "Fildişi"
        case .lacivert: "Lacivert"
        case .zumrut: "Zümrüt"
        case .klasik: "Klasik"
        case .gunbatimi: "Gün batımı"
        case .okyanus: "Okyanus"
        case .gul: "Gül"
        case .mermer: "Mermer"
        case .mor: "Mor"
        }
    }
}

enum KonumKipi: String, Codable, CaseIterable, Identifiable {
    case bursa, cihaz
    var id: String { rawValue }
}

struct Ayarlar: Codable, Equatable {
    var konumKipi: KonumKipi = .bursa
    var enlem: Double = 40.1826
    var boylam: Double = 29.0665
    var konumAdi: String = "Bursa"
    /// imsak, güneş, öğle, ikindi, akşam, yatsı
    var vakitBildirim: [Bool] = [true, false, true, true, true, true]
    var onceDakika: Int = 0
    var ezan: EzanTuru = .kisa
    var bildirimTonu: String = "bildirim_can"
    var katiMod: Bool = true
    var sesOdakta: Bool = true
    var sesSondaAzalt: Bool = true
    var tesbihTitresim: Bool = true
    var tesbihSes: Bool = true
    var tesbihSesDuzeyi: Double = 0.35
    var okumaPunto: Double = 19
    /// nil: uygulama temasıyla aynı
    var okumaKoyu: Bool? = nil
    var tema: Tema = .ihya
    var gunlukHedef: Int = 60
    var ezandaSustur: Bool = true
    var kuranDinlerkenKis: Bool = true
    var kuranMeal: Bool = true
    var kuranOkunus: Bool = false
    var kuranPunto: Double = 28

    enum CodingKeys: String, CodingKey {
        case konumKipi, enlem, boylam, konumAdi, vakitBildirim, onceDakika, ezan, bildirimTonu, katiMod
        case sesOdakta, sesSondaAzalt, tesbihTitresim, tesbihSes, tesbihSesDuzeyi, okumaPunto, okumaKoyu, tema, gunlukHedef, ezandaSustur, kuranDinlerkenKis
        case kuranMeal, kuranOkunus, kuranPunto
    }
}

extension Ayarlar {
    /// Eksik alanlar varsayılan değerle dolar; sürüm geçişlerinde ayarlar kaybolmaz.
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func v<T: Decodable>(_ k: CodingKeys, _ d: T) -> T { (try? c.decodeIfPresent(T.self, forKey: k)) ?? d }
        konumKipi = v(.konumKipi, konumKipi); enlem = v(.enlem, enlem); boylam = v(.boylam, boylam)
        konumAdi = v(.konumAdi, konumAdi); onceDakika = v(.onceDakika, onceDakika); ezan = v(.ezan, ezan)
        bildirimTonu = v(.bildirimTonu, bildirimTonu); katiMod = v(.katiMod, katiMod)
        sesOdakta = v(.sesOdakta, sesOdakta); sesSondaAzalt = v(.sesSondaAzalt, sesSondaAzalt)
        tesbihTitresim = v(.tesbihTitresim, tesbihTitresim); tesbihSes = v(.tesbihSes, tesbihSes)
        tesbihSesDuzeyi = v(.tesbihSesDuzeyi, tesbihSesDuzeyi); okumaPunto = v(.okumaPunto, okumaPunto)
        okumaKoyu = (try? c.decodeIfPresent(Bool.self, forKey: .okumaKoyu)) ?? nil
        tema = v(.tema, tema); gunlukHedef = v(.gunlukHedef, gunlukHedef)
        ezandaSustur = v(.ezandaSustur, ezandaSustur); kuranDinlerkenKis = v(.kuranDinlerkenKis, kuranDinlerkenKis)
        kuranMeal = v(.kuranMeal, kuranMeal); kuranOkunus = v(.kuranOkunus, kuranOkunus); kuranPunto = v(.kuranPunto, kuranPunto)
        let vb = v(.vakitBildirim, vakitBildirim)
        if vb.count == 6 { vakitBildirim = vb }
    }
}

/// Diske yazılan bütün kullanıcı verisi.
struct Kayit: Codable {
    var ayarlar = Ayarlar()
    var oturumlar: [OdakOturumu] = []
    var devam: DevamEdenOdak? = nil
    var konular: [Konu] = Kayit.varsayilanKonular
    var zikirler: [ZikirKaydi] = []
    var karisimlar: [Karisim] = []
    var sonKatman: [String: Double] = [:]
    var sonMesafe: [String: Double] = [:]
    var favoriler: [Favori] = []
    var kitaplar: [Kitap] = []
    var namaz: [String: [Int]] = [:]
    var tohum: Int = 0
    var acik: [String] = BitkiKatalogu.baslangic
    var sonTur: String = "papatya"
    var sonPlan: Int = 25
    /// Ezberlenen Esmâ-i Hüsnâ numaraları.
    var ezber: [Int] = []
    /// Kur'an'da kaldığın yer: [sûre, âyet].
    var kuranSon: [Int] = []

    enum CodingKeys: String, CodingKey {
        case ayarlar, oturumlar, devam, konular, zikirler, karisimlar, sonKatman, sonMesafe, favoriler, kitaplar, namaz, tohum, acik, sonTur, sonPlan, ezber, kuranSon
    }

    static let varsayilanKonular: [Konu] = [
        Konu(ad: "Kur'an", renk: "#27AE60", aciklama: "Mushaf açık; tilavet ve ezber"),
        Konu(ad: "Dinle", renk: "#2F80ED", aciklama: "Sohbet, ders ya da tilavet dinleme"),
        Konu(ad: "Kitap", renk: "#F2994A", aciklama: "Okuma ve not alma"),
        Konu(ad: "Zikir", renk: "#9B51E0", aciklama: "Tesbih ve dua"),
        Konu(ad: "Serbest", renk: "#56657F", aciklama: "Ders, iş ya da başka bir odak"),
    ]
}

extension Kayit {
    init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func v<T: Decodable>(_ k: CodingKeys, _ d: T) -> T { (try? c.decodeIfPresent(T.self, forKey: k)) ?? d }
        ayarlar = v(.ayarlar, ayarlar); oturumlar = v(.oturumlar, oturumlar)
        devam = (try? c.decodeIfPresent(DevamEdenOdak.self, forKey: .devam)) ?? nil
        konular = v(.konular, konular); zikirler = v(.zikirler, zikirler); karisimlar = v(.karisimlar, karisimlar)
        sonKatman = v(.sonKatman, sonKatman); sonMesafe = v(.sonMesafe, sonMesafe); favoriler = v(.favoriler, favoriler); kitaplar = v(.kitaplar, kitaplar)
        namaz = v(.namaz, namaz); tohum = v(.tohum, tohum); acik = v(.acik, acik)
        sonTur = v(.sonTur, sonTur); sonPlan = v(.sonPlan, sonPlan); ezber = v(.ezber, ezber); kuranSon = v(.kuranSon, kuranSon)
    }
}
