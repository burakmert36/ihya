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
    /// ayet anahtarı "sûre:âyet" biçimindedir.
    enum Tur: String, Codable { case hadis, soz, dua, ayet }
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
    /// Yer imi konan sayfalar (0'dan)
    var yerImleri: [Int] = []
    /// Sayfa görünümünde yakınlık (1: ekrana sığar)
    var yakinlik: Double = 1
    /// Toplam okuma süresi (sn)
    var okumaSn: Double = 0
    /// Okuma bitti olarak işaretlendi
    var bitti = false

    var oran: Double { toplam > 0 ? Double(min(sayfa + 1, toplam)) / Double(toplam) : 0 }
    var tamam: Bool { bitti || (toplam > 0 && sayfa + 1 >= toplam) }
    var basladi: Bool { sayfa > 0 || son != nil }
}

extension Kitap {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ad = try c.decode(String.self, forKey: .ad)
        dosya = try c.decode(String.self, forKey: .dosya)
        func v<T: Decodable>(_ k: CodingKeys, _ d: T) -> T { (try? c.decodeIfPresent(T.self, forKey: k)) ?? d }
        id = v(.id, UUID()); sayfa = v(.sayfa, 0); toplam = v(.toplam, 0); eklenme = v(.eklenme, Date())
        son = try? c.decodeIfPresent(Date.self, forKey: .son)
        yerImleri = v(.yerImleri, []); yakinlik = v(.yakinlik, 1); okumaSn = v(.okumaSn, 0); bitti = v(.bitti, false)
    }
}

enum EzanTuru: String, Codable, CaseIterable, Identifiable {
    case muezzin, makamli, tekMuezzin, kisa, sessiz
    var id: String { rawValue }
    var ad: String {
        switch self {
        case .muezzin: "Müezzin ezanı"
        case .makamli: "Kendi kaydım (elle ekle)"
        case .tekMuezzin: "Kendi kaydım 2"
        case .kisa: "Normal bildirim sesi"
        case .sessiz: "Sessiz"
        }
    }
    /// Library/Sounds altındaki dosya adı (kullanıcının eklediği kayıt).
    /// Seçicide görünenler (eski "tek müezzin" kaydı çalışmaya devam eder ama listede yok).
    static let secenekler: [EzanTuru] = [.kisa, .muezzin, .makamli, .sessiz]

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
    /// "bursa" adı eski kayıtlarla uyum için kaldı: Diyanet'in seçilen ilçe cetveli.
    case bursa, cihaz
    var id: String { rawValue }
}

/// Okuma ekranlarının zemini ve yazı rengi (kontrast 7:1 ile 13:1 arası; saf siyah üstüne saf beyaz yok).
enum OkumaTemasi: String, Codable, CaseIterable, Identifiable {
    case otomatik, gunduz, sepya, gece, siyah
    var id: String { rawValue }
    var ad: String {
        switch self {
        case .otomatik: "Kendiliğinden"
        case .gunduz: "Gündüz"
        case .sepya: "Sepya"
        case .gece: "Gece"
        case .siyah: "Siyah"
        }
    }
    var zemin: String {
        switch self {
        case .otomatik, .gunduz: "#F6F0E2"
        case .sepya: "#1F1A13"
        case .gece: "#161512"
        case .siyah: "#000000"
        }
    }
    var yazi: String {
        switch self {
        case .otomatik, .gunduz: "#2B261D"
        case .sepya: "#E6D3B0"
        case .gece: "#E4DED2"
        case .siyah: "#C9C4BA"
        }
    }
    var koyu: Bool { self != .gunduz && self != .otomatik }
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
    /// Diyanet ilçe numarası (ezanvakti.emushaf.net); 9335 Bursa merkez.
    var ilceKodu: Int = 9335
    var ilceAdi: String = "Bursa"
    var tilavetHafiz: String = Hafiz.tumu[0].id
    var tilavetHiz: Double = 1
    var tilavetTakip: Bool = true
    var tilavetDevam: Bool = false
    /// Odak sesleri kilit ekranında görünsün (başka uygulamaların sesiyle karışmaz).
    var sesKilitEkrani: Bool = true
    var okumaTemasi: OkumaTemasi = .otomatik
    /// 0…1: mavi ışığı azaltan amber katman.
    var sicakIsik: Double = 0.3
    /// 0 sık, 1 rahat, 2 geniş
    var satirAraligi: Int = 1
    var ekranAcik: Bool = true
    var seriHatirlatma: Bool = true
    /// Gün içindeki dakika (20.30)
    var seriHatirlatmaDk: Int = 20 * 60 + 30
    var cumaOzeti: Bool = true
    /// İndirilen müezzin ezanı (Muezzin.id)
    var muezzin: String = "mekke"
    /// Vakte göre müezzin (imsak, güneş, öğle, ikindi, akşam, yatsı); boşsa hepsinde "muezzin".
    var vakitMuezzin: [String] = []
    /// Kitap okuyucu: sayfalar yana çevrilsin (kapalıysa aşağı kayar)
    var kitapYatay: Bool = false
    /// Sayfalar sağdan sola (Arapça, Osmanlıca kitaplar)
    var kitapSagdanSola: Bool = false
    /// 0 dik, 1 yan, 2 telefonla döner
    var kitapEkran: Int = 0
    /// Sayfa yerine yalnız yazı (büyütünce satırlar ekrana sığar)
    var kitapMetin: Bool = false
    /// Yazı görünümü: 0 tırnaklı, 1 düz yazı tipi
    var kitapYaziTipi: Int = 0
    /// Yazı görünümü kenar boşluğu: 0 dar, 1 orta, 2 geniş
    var kitapKenar: Int = 1
    /// Sesli okuma hızı (AVSpeechUtterance oranı)
    var kitapSesHizi: Double = 0.5

    enum CodingKeys: String, CodingKey {
        case konumKipi, enlem, boylam, konumAdi, vakitBildirim, onceDakika, ezan, bildirimTonu, katiMod
        case sesOdakta, sesSondaAzalt, tesbihTitresim, tesbihSes, tesbihSesDuzeyi, okumaPunto, okumaKoyu, tema, gunlukHedef, ezandaSustur, kuranDinlerkenKis
        case kuranMeal, kuranOkunus, kuranPunto, ilceKodu, ilceAdi, tilavetHafiz, tilavetHiz, tilavetTakip, tilavetDevam, sesKilitEkrani
        case okumaTemasi, sicakIsik, satirAraligi, ekranAcik, seriHatirlatma, seriHatirlatmaDk, cumaOzeti, muezzin, vakitMuezzin
        case kitapYatay, kitapSagdanSola, kitapEkran, kitapMetin, kitapYaziTipi, kitapKenar, kitapSesHizi
    }

    /// Vaktin müezzini (Muezzin.id).
    func vaktinMuezzini(_ i: Int) -> String {
        vakitMuezzin.count == 6 && vakitMuezzin.indices.contains(i) && !vakitMuezzin[i].isEmpty ? vakitMuezzin[i] : muezzin
    }

    /// Okuma teması: "kendiliğinden" akşamdan imsaka gece, öbür saatlerde gündüz.
    func etkinOkumaTemasi(gece: Bool) -> OkumaTemasi { okumaTemasi == .otomatik ? (gece ? .gece : .gunduz) : okumaTemasi }
    var satirCarpani: Double { [1.45, 1.7, 1.95][max(0, min(2, satirAraligi))] }
    /// SwiftUI satır boşluğu (yazının kendi ~1,2 satır yüksekliğine eklenen).
    func satirBoslugu(_ punto: Double) -> Double { punto * max(0.1, satirCarpani - 1.2) }
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
        ilceKodu = v(.ilceKodu, ilceKodu); ilceAdi = v(.ilceAdi, ilceAdi); tilavetHafiz = v(.tilavetHafiz, tilavetHafiz); tilavetHiz = v(.tilavetHiz, tilavetHiz)
        tilavetTakip = v(.tilavetTakip, tilavetTakip); tilavetDevam = v(.tilavetDevam, tilavetDevam); sesKilitEkrani = v(.sesKilitEkrani, sesKilitEkrani)
        // Eski "koyu okuma" anahtarı yeni temaya taşınır.
        okumaTemasi = v(.okumaTemasi, okumaKoyu.map { $0 ? OkumaTemasi.gece : .gunduz } ?? okumaTemasi)
        sicakIsik = v(.sicakIsik, sicakIsik); satirAraligi = v(.satirAraligi, satirAraligi); ekranAcik = v(.ekranAcik, ekranAcik)
        seriHatirlatma = v(.seriHatirlatma, seriHatirlatma); seriHatirlatmaDk = v(.seriHatirlatmaDk, seriHatirlatmaDk); cumaOzeti = v(.cumaOzeti, cumaOzeti)
        muezzin = v(.muezzin, muezzin); vakitMuezzin = v(.vakitMuezzin, vakitMuezzin)
        kitapYatay = v(.kitapYatay, kitapYatay); kitapSagdanSola = v(.kitapSagdanSola, kitapSagdanSola)
        kitapEkran = v(.kitapEkran, kitapEkran); kitapMetin = v(.kitapMetin, kitapMetin)
        kitapYaziTipi = v(.kitapYaziTipi, kitapYaziTipi); kitapKenar = v(.kitapKenar, kitapKenar); kitapSesHizi = v(.kitapSesHizi, kitapSesHizi)
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
    /// Kaza borcu: vakit anahtarı (sabah, ogle, ikindi, aksam, yatsi, vitir) → adet.
    var kaza: [String: Int] = [:]
    /// Kutlaması gösterilen son seri kilometre taşı.
    var kutlananSeri: Int = 0
    /// Kendiliğinden yedek klasörü (güvenlik kapsamlı yer imi) ve son yedeğin zamanı.
    var yedekYeri: Data? = nil
    var sonYedek: Date? = nil
    /// Kaza önerisine bakılan son gün ("yyyy-MM-dd"); aynı öneri bir kez sorulur.
    var kazaBakilan: String = ""

    enum CodingKeys: String, CodingKey {
        case ayarlar, oturumlar, devam, konular, zikirler, karisimlar, sonKatman, sonMesafe, favoriler, kitaplar, namaz, tohum, acik, sonTur, sonPlan, ezber, kuranSon
        case kaza, kutlananSeri, yedekYeri, sonYedek, kazaBakilan
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
        kaza = v(.kaza, kaza); kutlananSeri = v(.kutlananSeri, kutlananSeri)
        yedekYeri = (try? c.decodeIfPresent(Data.self, forKey: .yedekYeri)) ?? nil
        sonYedek = (try? c.decodeIfPresent(Date.self, forKey: .sonYedek)) ?? nil
        kazaBakilan = v(.kazaBakilan, kazaBakilan)
    }
}
