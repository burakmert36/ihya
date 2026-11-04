import Foundation

/// Dikim serisinin durumu (gün sınırı imsaktır).
struct SeriDurumu: Equatable {
    var seri = 0
    var enUzun = 0
    /// Birikmiş rahmet yağmuru (en çok 2): kaçan bir günü kendiliğinden kapatır.
    var rahmet = 0
    /// Bir sonraki rahmete kalan dikimli gün (7 günde bir kazanılır).
    var rahmeteKalan = 7
    var bugunDikildi = false
    /// Seri kırıldıysa 48 saat içinde 2 dikimle kurtarılabilir.
    var telafi: Telafi?
    /// Rahmetle kapanan günlerin başlangıcı.
    var rahmetGunleri: [Date] = []

    struct Telafi: Equatable {
        var kalan: Int
        /// Telafinin son anı (pencerenin ertesi günü imsak).
        var bitis: Date
        /// Kırılmadan önceki seri.
        var onceki: Int
    }

    var sonrakiTas: Int? { Seri.taslar.first { $0 > seri } }
    /// Ulaşılan en büyük kilometre taşı.
    var ulasilanTas: Int? { Seri.taslar.last { $0 <= seri } }
}

enum Seri {
    static let taslar = [3, 7, 30, 40, 100, 365]
    static let rahmetGun = 7
    static let enFazlaRahmet = 2
    static let telafiDikim = 2

    /// - dikimler: tamamlanan odak oturumlarının başlangıçları
    /// - gun: bir anı ait olduğu günün başlangıcına (imsak günü) çevirir
    /// - imsak: bir günün başlangıcı (gece yarısı) için o günün imsak anı
    static func hesapla(dikimler: [Date], simdi: Date, gun: (Date) -> Date, imsak: (Date) -> Date,
                        takvim: Calendar = .current) -> SeriDurumu {
        var sayim: [Date: Int] = [:]
        for d in dikimler { sayim[gun(d), default: 0] += 1 }
        let bugun = gun(simdi)
        var s = SeriDurumu()
        s.bugunDikildi = (sayim[bugun] ?? 0) > 0
        guard let ilk = sayim.keys.min(), ilk <= bugun else { return s }

        var seri = 0, enUzun = 0, rahmet = 0, sayac = 0
        var askida: (bas: Date, kalan: Int, onceki: Int)?
        var rahmetGunleri: [Date] = []
        var d = ilk
        while d <= bugun {
            let n = sayim[d] ?? 0
            let bugunMu = d == bugun
            if let a = askida {
                if n > 0 { seri += 1 }
                let kalan = a.kalan - n
                let pencereSonu = takvim.date(byAdding: .day, value: 2, to: a.bas)!
                if kalan <= 0 {
                    askida = nil
                } else if d >= pencereSonu && !bugunMu {
                    // Telafi olmadı: seri, kırılan günden sonraki ardışık dikimli günlerden yeniden sayılır.
                    var g = d, yeni = 0
                    while g > a.bas, (sayim[g] ?? 0) > 0 { yeni += 1; g = takvim.date(byAdding: .day, value: -1, to: g)! }
                    seri = yeni
                    sayac = yeni
                    askida = nil
                } else {
                    askida = (a.bas, kalan, a.onceki)
                }
            } else if n > 0 {
                seri += 1
                sayac += 1
                if sayac >= rahmetGun { sayac = 0; rahmet = min(enFazlaRahmet, rahmet + 1) }
            } else if !bugunMu {
                if seri > 0, rahmet > 0 {
                    rahmet -= 1
                    rahmetGunleri.append(d)
                } else if seri > 0 {
                    askida = (d, telafiDikim, seri)
                } else {
                    sayac = 0
                }
            }
            enUzun = max(enUzun, seri)
            d = takvim.date(byAdding: .day, value: 1, to: d)!
        }
        s.seri = seri
        s.enUzun = enUzun
        s.rahmet = rahmet
        s.rahmeteKalan = rahmetGun - sayac
        s.rahmetGunleri = rahmetGunleri
        if let a = askida {
            let bitisGunu = takvim.date(byAdding: .day, value: 3, to: a.bas)!
            s.telafi = .init(kalan: a.kalan, bitis: imsak(bitisGunu), onceki: a.onceki)
        }
        return s
    }
}
