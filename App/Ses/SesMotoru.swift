import AVFoundation
import Observation
import SwiftUI

struct SesTuru: Identifiable, Hashable {
    let id: String
    let ad: String
    let simge: String
    let uzunluk: Double     // döngü uzunluğu (sn)
    let renk: Color         // kartın cam tonu (tasarımdan)
    let bas: Double = 0.5   // döngünün başladığı yer (sn); öncesi döngünün sonunun kopyası
    /// Dosya yerine cihazda üretilen gürültü.
    var gurultu: Gurultu? = nil
    var kume: Kume = .doga

    enum Kume: String, CaseIterable {
        case yagmur, doga, hayvan, mekan, ev, yolculuk
        var ad: String {
            switch self {
            case .yagmur: "Yağmur"
            case .doga: "Doğa"
            case .hayvan: "Hayvanlar"
            case .mekan: "Mekânlar"
            case .ev: "Ev ve masa"
            case .yolculuk: "Yolculuk"
            }
        }
        var simge: String {
            switch self {
            case .yagmur: "cloud.rain"
            case .doga: "leaf"
            case .hayvan: "bird"
            case .mekan: "building.columns"
            case .ev: "house"
            case .yolculuk: "sailboat"
            }
        }
    }
    /// İkinci sürgünün adı: kayıtlarda uzaklık, gürültülerde yumuşaklık (ikisi de aynı süzgeci sürer).
    var ikinciAyar: String { gurultu == nil ? "Uzaklık" : "Yumuşak" }

    static let doga: [SesTuru] = [
        SesTuru(id: "yagmur_hafif", ad: "Hafif yağmur", simge: "cloud.drizzle", uzunluk: 60.0, renk: Color(r: 120, g: 180, b: 255), kume: .yagmur),
        SesTuru(id: "yagmur", ad: "Yağmur", simge: "cloud.rain", uzunluk: 34.719297, renk: Color(r: 100, g: 160, b: 255), kume: .yagmur),
        SesTuru(id: "yagmur_cam", ad: "Cama vuran yağmur", simge: "drop", uzunluk: 25.642653, renk: Color(r: 140, g: 190, b: 255), kume: .yagmur),
        SesTuru(id: "yagmur_siddetli", ad: "Sağanak", simge: "cloud.heavyrain", uzunluk: 14.288141, renk: Color(r: 90, g: 130, b: 240), kume: .yagmur),
        SesTuru(id: "cadir_yagmur", ad: "Çadıra yağmur", simge: "tent", uzunluk: 40.0, renk: Color(r: 130, g: 200, b: 170), kume: .yagmur),
        SesTuru(id: "semsiye_yagmur", ad: "Şemsiyeye yağmur", simge: "umbrella", uzunluk: 21.254921, renk: Color(r: 150, g: 170, b: 255), kume: .yagmur),
        SesTuru(id: "araba_yagmur", ad: "Arabada yağmur", simge: "car", uzunluk: 7.11585, renk: Color(r: 120, g: 150, b: 200), kume: .yagmur),
        SesTuru(id: "gokgurultusu", ad: "Gök gürültüsü", simge: "cloud.bolt.rain", uzunluk: 60.0, renk: Color(r: 190, g: 170, b: 255), kume: .yagmur),

        SesTuru(id: "dere", ad: "Dere", simge: "humidity", uzunluk: 70.0, renk: Color(r: 90, g: 200, b: 230)),
        SesTuru(id: "nehir", ad: "Nehir", simge: "drop.halffull", uzunluk: 40.0, renk: Color(r: 80, g: 185, b: 215)),
        SesTuru(id: "selale", ad: "Şelale", simge: "mountain.2", uzunluk: 18.185918, renk: Color(r: 110, g: 210, b: 220)),
        SesTuru(id: "damlalar", ad: "Damlalar", simge: "drop.circle", uzunluk: 40.0, renk: Color(r: 120, g: 205, b: 245)),
        SesTuru(id: "deniz", ad: "Deniz dalgaları", simge: "water.waves", uzunluk: 70.0, renk: Color(r: 70, g: 170, b: 230)),
        SesTuru(id: "orman_ruzgar", ad: "Ağaçlarda rüzgâr", simge: "tree", uzunluk: 48.0, renk: Color(r: 90, g: 220, b: 140)),
        SesTuru(id: "ruzgar", ad: "Rüzgâr", simge: "wind", uzunluk: 40.0, renk: Color(r: 170, g: 195, b: 225)),
        SesTuru(id: "firtina", ad: "Fırtına rüzgârı", simge: "tornado", uzunluk: 48.0, renk: Color(r: 150, g: 170, b: 210)),
        SesTuru(id: "tropik", ad: "Tropik orman", simge: "leaf.fill", uzunluk: 45.0, renk: Color(r: 70, g: 205, b: 120)),
        SesTuru(id: "kamp_atesi", ad: "Kamp ateşi", simge: "flame", uzunluk: 60.0, renk: Color(r: 255, g: 140, b: 60)),
        SesTuru(id: "kar_yuruyus", ad: "Karda yürüyüş", simge: "snowflake", uzunluk: 31.367347, renk: Color(r: 200, g: 225, b: 255)),
        SesTuru(id: "yaprak_yuruyus", ad: "Yapraklarda yürüyüş", simge: "leaf", uzunluk: 15.272585, renk: Color(r: 230, g: 170, b: 90)),

        SesTuru(id: "kuslar", ad: "Kuş cıvıltısı", simge: "bird", uzunluk: 70.0, renk: Color(r: 150, g: 230, b: 120), kume: .hayvan),
        SesTuru(id: "gece", ad: "Gece böcekleri", simge: "moon.stars", uzunluk: 70.0, renk: Color(r: 160, g: 150, b: 255), kume: .hayvan),
        SesTuru(id: "baykus", ad: "Baykuş", simge: "moon", uzunluk: 10.0, renk: Color(r: 150, g: 135, b: 220), kume: .hayvan),
        SesTuru(id: "kurbaga", ad: "Kurbağalar", simge: "leaf.circle", uzunluk: 40.0, renk: Color(r: 120, g: 210, b: 110), kume: .hayvan),
        SesTuru(id: "marti", ad: "Martılar", simge: "bird.fill", uzunluk: 38.0, renk: Color(r: 150, g: 200, b: 240), kume: .hayvan),
        SesTuru(id: "agackakan", ad: "Ağaçkakan", simge: "tree.fill", uzunluk: 12.0, renk: Color(r: 200, g: 150, b: 100), kume: .hayvan),
        SesTuru(id: "ari", ad: "Arı kovanı", simge: "hexagon", uzunluk: 39.85483, renk: Color(r: 250, g: 200, b: 80), kume: .hayvan),
        SesTuru(id: "kedi", ad: "Mırlayan kedi", simge: "cat", uzunluk: 33.362154, renk: Color(r: 240, g: 180, b: 150), kume: .hayvan),

        SesTuru(id: "kafe", ad: "Kafe", simge: "cup.and.saucer", uzunluk: 70.0, renk: Color(r: 210, g: 160, b: 110), kume: .mekan),
        SesTuru(id: "kutuphane", ad: "Kütüphane", simge: "books.vertical", uzunluk: 70.0, renk: Color(r: 200, g: 180, b: 140), kume: .mekan),
        SesTuru(id: "gece_koy", ad: "Gece köyü", simge: "house.lodge", uzunluk: 45.0, renk: Color(r: 140, g: 140, b: 210), kume: .mekan),
        SesTuru(id: "su_alti", ad: "Su altı", simge: "bubbles.and.sparkles", uzunluk: 37.948844, renk: Color(r: 60, g: 160, b: 210), kume: .mekan),

        SesTuru(id: "somine", ad: "Şömine", simge: "fireplace", uzunluk: 18.0, renk: Color(r: 255, g: 170, b: 90), kume: .ev),
        SesTuru(id: "saat", ad: "Saat tıkırtısı", simge: "clock", uzunluk: 12.0, renk: Color(r: 210, g: 200, b: 180), kume: .ev),
        SesTuru(id: "sayfa", ad: "Sayfa çevirme", simge: "book.pages", uzunluk: 14.0, renk: Color(r: 235, g: 215, b: 170), kume: .ev),
        SesTuru(id: "daktilo", ad: "Daktilo", simge: "keyboard", uzunluk: 16.480499, renk: Color(r: 190, g: 190, b: 200), kume: .ev),
        SesTuru(id: "ruzgar_cani", ad: "Rüzgâr çanı", simge: "bell", uzunluk: 40.0, renk: Color(r: 240, g: 210, b: 130), kume: .ev),
        SesTuru(id: "vantilator", ad: "Vantilatör", simge: "fan.ceiling", uzunluk: 12.0, renk: Color(r: 180, g: 210, b: 220), kume: .ev),

        SesTuru(id: "tren", ad: "Trende", simge: "tram", uzunluk: 40.0, renk: Color(r: 170, g: 160, b: 200), kume: .yolculuk),
        SesTuru(id: "yelkenli", ad: "Yelkenli", simge: "sailboat", uzunluk: 45.0, renk: Color(r: 100, g: 180, b: 230), kume: .yolculuk),
        SesTuru(id: "kurek", ad: "Kayıkta kürek", simge: "oar.2.crossed", uzunluk: 20.234739, renk: Color(r: 120, g: 190, b: 190), kume: .yolculuk),
    ]
    static func kumedekiler(_ k: Kume) -> [SesTuru] { doga.filter { $0.kume == k } }
    static let gurultuler: [SesTuru] = [
        SesTuru(id: "gurultu_beyaz", ad: "Beyaz gürültü", simge: "waveform", uzunluk: 16, renk: Color(r: 225, g: 230, b: 245), gurultu: .beyaz),
        SesTuru(id: "gurultu_pembe", ad: "Pembe gürültü", simge: "waveform.path", uzunluk: 16, renk: Color(r: 255, g: 150, b: 195), gurultu: .pembe),
        SesTuru(id: "gurultu_kahve", ad: "Kahverengi gürültü", simge: "wave.3.right", uzunluk: 16, renk: Color(r: 190, g: 135, b: 90), gurultu: .kahverengi),
    ]
    static let tumu: [SesTuru] = doga + gurultuler
    static func bul(_ id: String) -> SesTuru? { tumu.first { $0.id == id } }
}

/// Sabit bir ses yuvası: oynatıcı → süzgeç → yankı → ana karıştırıcı. Yuvalar motor çalışmadan önce bir kez bağlanır;
/// ses değişince yalnız yuvaya yeni dosya atanır (çalışırken düğüm bağlamak yok).
@MainActor
private final class Yuva {
    let oynatici = AVAudioPlayerNode()
    /// Uzaklık: alçak geçiren süzgeç (uzak ses boğuk) ve yankı (uzak ses odada dağılır).
    let suzgec = AVAudioUnitEQ(numberOfBands: 1)
    let yanki = AVAudioUnitReverb()
    private(set) var tur: String?
    private var dosya: AVAudioFile?
    private var tampon: AVAudioPCMBuffer?
    private var bas: AVAudioFramePosition = 0
    private var uzunluk: AVAudioFrameCount = 0
    /// Her atama ve durdurmada artar; eski kuyruk geri çağrıları yok sayılır.
    private var nesil = 0
    private(set) var aktif = false
    private var duzey: Double = 0.7
    private var mesafe: Double = 0

    init() {
        let b = suzgec.bands[0]
        b.filterType = .lowPass
        b.frequency = 20000
        b.bypass = false
        yanki.loadFactoryPreset(.mediumHall)
        yanki.wetDryMix = 0
    }

    var bos: Bool { tur == nil }

    /// Yuvaya ses atar. Biçim yuva biçimiyle aynı değilse atamaz.
    func ata(_ t: SesTuru, bicim: AVAudioFormat) -> Bool {
        bosalt()
        if let g = t.gurultu {
            guard let b = Gurultu.tampon(g, bicim: bicim) else { return false }
            tampon = b
            tur = t.id
            return true
        }
        guard let url = Bundle.main.url(forResource: t.id, withExtension: "mp3"), let f = try? AVAudioFile(forReading: url) else {
            print("SES: dosya açılamadı \(t.id)")
            return false
        }
        let pb = f.processingFormat
        guard pb.channelCount == bicim.channelCount, pb.sampleRate == bicim.sampleRate else {
            print("SES: biçim uyumsuz \(t.id) \(pb)")
            return false
        }
        bas = AVAudioFramePosition(t.bas * pb.sampleRate)
        uzunluk = AVAudioFrameCount(max(0, min(t.uzunluk * pb.sampleRate, Double(f.length - bas))))
        guard uzunluk > 0 else { return false }
        dosya = f
        tur = t.id
        return true
    }

    /// d: 0 yakın … 1 uzak. Kesim frekansı 20 kHz'den 2,2 kHz'e iner, yankı artar, ses biraz kısılır.
    func ayarla(duzey: Double? = nil, mesafe: Double? = nil) {
        if let duzey { self.duzey = duzey }
        if let mesafe { self.mesafe = mesafe }
        let d = max(0, min(1, self.mesafe))
        suzgec.bands[0].frequency = Float(20000 * pow(2200.0 / 20000.0, d))
        yanki.wetDryMix = Float(40 * d)
        oynatici.volume = Float(self.duzey * (1 - 0.3 * d))
    }

    func baslat() {
        guard dosya != nil || tampon != nil else { return }
        if !aktif {
            aktif = true
            nesil += 1
            if let tampon {
                oynatici.scheduleBuffer(tampon, at: nil, options: .loops)
            } else {
                kuyruga(nesil)
                kuyruga(nesil)
            }
        }
        if !oynatici.isPlaying { oynatici.play() }
    }

    /// Motor yeniden başlayınca kuyruk boşalmış olur; baştan kurar.
    func yenidenKur() {
        guard aktif else { return }
        aktif = false
        oynatici.stop()
        baslat()
    }

    private func kuyruga(_ n: Int) {
        guard let f = dosya else { return }
        oynatici.scheduleSegment(f, startingFrame: bas, frameCount: uzunluk, at: nil, completionCallbackType: .dataConsumed) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.aktif, self.nesil == n else { return }
                self.kuyruga(n)
            }
        }
    }

    func duraklat() { oynatici.pause() }

    func bosalt() {
        aktif = false
        nesil += 1
        oynatici.stop()
        dosya = nil
        tampon = nil
        tur = nil
    }
}

/// Odak sesleri karıştırıcısı. En çok 6 katman.
@MainActor
@Observable
final class SesMotoru {
    static let enFazla = 6
    private(set) var katman: [String: Double] = [:]     // seçili sesler ve düzeyleri
    private(set) var mesafe: [String: Double] = [:]     // 0 yakın … 1 uzak
    private(set) var caliyor = false
    private(set) var anaDuzey: Double = 1
    /// Son başlatma hatası (Sesler ekranında gösterilir).
    private(set) var hata: String?
    /// 30/60 dk zamanlayıcısının bitişi.
    private(set) var uykuBitis: Date?
    /// Başka uygulama (ör. Kur'an tilaveti) ses çalarken kısılsın mı.
    @ObservationIgnored var kuranKis = true
    @ObservationIgnored private var kisik = false
    /// Uygulama içinde tilavet çalarken odak sesleri 12 dB kısılır.
    @ObservationIgnored private var tilavetKisik = false
    /// Açıksa odak sesleri kilit ekranında görünür (başka uygulamaların sesiyle karışmaz).
    @ObservationIgnored var kilitEkrani = true

    private let motor = AVAudioEngine()
    private let bicim = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
    @ObservationIgnored private var yuvalar: [Yuva] = []
    @ObservationIgnored private var gecis: Task<Void, Never>?
    @ObservationIgnored private var sonumGorevi: Task<Void, Never>?
    @ObservationIgnored private var gozlemciler: [NSObjectProtocol] = []
    /// Yumuşak açılış/kapanış çarpanı; kullanıcının ana düzeyiyle çarpılır.
    @ObservationIgnored private var gecisCarpani: Double = 1

    init() {
        // Bütün yuvalar motor başlamadan önce bağlanır.
        let ana = motor.mainMixerNode
        for _ in 0..<SesMotoru.enFazla {
            let y = Yuva()
            motor.attach(y.oynatici)
            motor.attach(y.suzgec)
            motor.attach(y.yanki)
            motor.connect(y.yanki, to: ana, format: bicim)
            motor.connect(y.suzgec, to: y.yanki, format: bicim)
            motor.connect(y.oynatici, to: y.suzgec, format: bicim)
            yuvalar.append(y)
        }
        let m = NotificationCenter.default
        gozlemciler.append(m.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] not in
            guard let ham = not.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt, let tip = AVAudioSession.InterruptionType(rawValue: ham) else { return }
            Task { @MainActor in
                if tip == .ended, self?.caliyor == true { self?.yenidenBaslat() }
            }
        })
        gozlemciler.append(m.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] not in
            guard let ham = not.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  AVAudioSession.RouteChangeReason(rawValue: ham) == .oldDeviceUnavailable else { return }
            // Kulaklık çıkınca ses hoparlörden devam etmesin.
            Task { @MainActor in self?.duraklat() }
        })
        gozlemciler.append(m.addObserver(forName: .AVAudioEngineConfigurationChange, object: motor, queue: .main) { [weak self] _ in
            Task { @MainActor in if self?.caliyor == true { self?.yenidenBaslat() } }
        })
        gozlemciler.append(m.addObserver(forName: AVAudioSession.silenceSecondaryAudioHintNotification, object: nil, queue: .main) { [weak self] not in
            guard let ham = not.userInfo?[AVAudioSessionSilenceSecondaryAudioHintTypeKey] as? UInt,
                  let tip = AVAudioSession.SilenceSecondaryAudioHintType(rawValue: ham) else { return }
            Task { @MainActor in
                guard let self else { return }
                self.kisik = tip == .begin && self.kuranKis
                self.uygula()
            }
        })
    }

    var seciliAdlar: String {
        let adlar = SesTuru.tumu.filter { katman[$0.id] != nil }.map(\.ad)
        return adlar.isEmpty ? "Ses seçilmedi" : adlar.joined(separator: " · ")
    }

    private func yuva(_ id: String) -> Yuva? { yuvalar.first { $0.tur == id } }

    // MARK: Seçim

    func degistir(_ id: String) {
        if katman[id] != nil {
            katman[id] = nil
            mesafe[id] = nil
            yuva(id)?.bosalt()
            if katman.isEmpty { duraklat() }
        } else {
            guard katman.count < SesMotoru.enFazla else { Dokunsal.uyari(); return }
            katman[id] = 0.7
            if caliyor { ac(id) } else { oynat() }
        }
    }

    func duzey(_ id: String, _ v: Double) {
        katman[id] = v
        yuva(id)?.ayarla(duzey: v)
    }

    func mesafeAyarla(_ id: String, _ v: Double) {
        mesafe[id] = v
        yuva(id)?.ayarla(mesafe: v)
    }

    func ana(_ v: Double) {
        anaDuzey = v
        uygula()
    }

    private func uygula() { motor.mainMixerNode.outputVolume = Float(anaDuzey * gecisCarpani * (kisik ? 0.25 : 1) * (tilavetKisik ? 0.25 : 1)) }

    /// Tilavet başlayınca/bitince çağrılır.
    func tilavetCaliyor(_ evet: Bool) {
        let yeni = evet && kuranKis
        guard yeni != tilavetKisik else { return }
        tilavetKisik = yeni
        uygula()
    }

    /// Uyku zamanlayıcısı: dk sonra sesi yavaşça kısıp durdurur; nil kapatır.
    func uyku(_ dk: Int?) {
        if let dk {
            let b = Date().addingTimeInterval(Double(dk) * 60)
            uykuBitis = b
            sondaAzalt(bitis: b, sure: 30)
        } else {
            uykuBitis = nil
            sonumuIptal()
        }
    }

    func yukle(_ k: [String: Double], mesafe m: [String: Double] = [:], baslat: Bool) {
        katman = k.filter { SesTuru.bul($0.key) != nil }
        mesafe = m.filter { katman[$0.key] != nil }
        for y in yuvalar { if let t = y.tur, katman[t] == nil { y.bosalt() } }
        for (id, y) in yuvalar.compactMap({ y in y.tur.map { ($0, y) } }) { y.ayarla(duzey: katman[id] ?? 0.7, mesafe: mesafe[id] ?? 0) }
        if baslat || caliyor { oynat() }
    }

    /// Bütün sesleri yumuşakça kısıp kapatır.
    func hepsiniKis() {
        sonumGorevi?.cancel()
        guard caliyor else {
            for y in yuvalar { y.bosalt() }
            katman = [:]; mesafe = [:]
            return
        }
        gecisle(hedef: 0, sure: 0.8) { [weak self] in
            guard let self else { return }
            for y in self.yuvalar { y.bosalt() }
            self.katman = [:]
            self.mesafe = [:]
            self.caliyor = false
            self.motor.pause()
            self.gecisCarpani = 1
            self.uygula()
            SimdiCalan.guncelle()
        }
    }

    // MARK: Çalma

    func oynat() {
        guard !katman.isEmpty else { return }
        SesOturumu.odakKilitEkrani = kilitEkrani
        guard motoruBaslat() else { return }
        for id in katman.keys { ac(id) }
        caliyor = true
        gecisCarpani = 0
        uygula()
        gecisle(hedef: 1, sure: 1.2)
        SimdiCalan.guncelle()
    }

    func duraklat() {
        sonumGorevi?.cancel()
        uykuBitis = nil
        guard caliyor else { return }
        caliyor = false
        SimdiCalan.guncelle()
        gecisle(hedef: 0, sure: 0.6) { [weak self] in
            guard let self, !self.caliyor else { return }
            for y in self.yuvalar where y.aktif { y.duraklat() }
            self.motor.pause()
            self.gecisCarpani = 1
            self.uygula()
        }
    }

    func degistirOynat() { caliyor ? duraklat() : oynat() }

    /// Odak bitimine doğru son 'sure' saniyede sesi sıfıra indirir.
    func sondaAzalt(bitis: Date, sure: Double = 60) {
        sonumGorevi?.cancel()
        sonumGorevi = Task { @MainActor [weak self] in
            let bekle = bitis.timeIntervalSinceNow - sure
            if bekle > 0 { try? await Task.sleep(nanoseconds: UInt64(bekle * 1_000_000_000)) }
            guard !Task.isCancelled, let self, self.caliyor else { return }
            let kalan = max(1, bitis.timeIntervalSinceNow)
            self.gecisle(hedef: 0, sure: kalan) { [weak self] in self?.duraklat() }
        }
    }

    func sonumuIptal() {
        sonumGorevi?.cancel()
        if caliyor { gecisle(hedef: 1, sure: 0.5) }
    }

    // MARK: İç işler

    @discardableResult
    private func motoruBaslat() -> Bool {
        SesOturumu.hazirla()
        if !motor.isRunning {
            motor.prepare()
            do {
                try motor.start()
                hata = nil
            } catch {
                hata = "Ses başlatılamadı: \(error.localizedDescription)"
                print("SES: motor başlamadı \(error)")
                return false
            }
        }
        return true
    }

    private func yenidenBaslat() {
        guard motoruBaslat() else { return }
        for y in yuvalar where y.aktif { y.yenidenKur() }
    }

    private func ac(_ id: String) {
        guard let tur = SesTuru.bul(id) else { return }
        let y: Yuva
        if let mevcut = yuva(id) {
            y = mevcut
        } else {
            guard let bos = yuvalar.first(where: { $0.bos }), bos.ata(tur, bicim: bicim) else { return }
            y = bos
        }
        y.ayarla(duzey: katman[id] ?? 0.7, mesafe: mesafe[id] ?? 0)
        if motor.isRunning || motoruBaslat() { y.baslat() }
    }

    private func gecisle(hedef: Double, sure: Double, bitince: (() -> Void)? = nil) {
        gecis?.cancel()
        let bas = gecisCarpani
        gecis = Task { @MainActor [weak self] in
            let adim = max(1, Int(min(sure, 120) * 20))
            for i in 1...adim {
                try? await Task.sleep(nanoseconds: UInt64(sure / Double(adim) * 1_000_000_000))
                if Task.isCancelled { return }
                guard let self else { return }
                self.gecisCarpani = bas + (hedef - bas) * Double(i) / Double(adim)
                self.uygula()
            }
            bitince?()
        }
    }

    // MARK: Sınama (CI)

    /// Simülatörde '-sesSinama 1' ile: aynı zinciri çevrimdışı işler (yakın/uzak düzeyi), sonra gerçek motoru çalıştırıp
    /// oynatıcının ilerlediğini denetler. Sonuç konsola "SES-SINAMA" satırlarıyla yazılır.
    static func sina() async {
        print("SES-SINAMA başladı")
        for t in SesTuru.doga {
            let var1 = Bundle.main.url(forResource: t.id, withExtension: "mp3") != nil
            if !var1 { print("SES-SINAMA eksik dosya \(t.id)") }
        }
        for ton in ["bildirim_can", "bildirim_damla", "efekt_kutlama"] {
            print("SES-SINAMA ton \(ton) \(Bundle.main.url(forResource: ton, withExtension: "wav") != nil ? "var" : "YOK")")
        }
        // 1) Çevrimdışı işleme: aynı yuva zinciri, 2 sn
        for d in [0.0, 1.0] {
            let e = AVAudioEngine()
            let f = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
            do {
                try e.enableManualRenderingMode(.offline, format: f, maximumFrameCount: 4096)
                let y = Yuva()
                e.attach(y.oynatici); e.attach(y.suzgec); e.attach(y.yanki)
                e.connect(y.yanki, to: e.mainMixerNode, format: f)
                e.connect(y.suzgec, to: y.yanki, format: f)
                e.connect(y.oynatici, to: y.suzgec, format: f)
                guard let t = SesTuru.bul("yagmur_hafif"), y.ata(t, bicim: f) else { print("SES-SINAMA atama başarısız"); continue }
                y.ayarla(duzey: 0.7, mesafe: d)
                try e.start()
                y.baslat()
                let tampon = AVAudioPCMBuffer(pcmFormat: e.manualRenderingFormat, frameCapacity: e.manualRenderingMaximumFrameCount)!
                var toplam: Double = 0, adet = 0
                while adet < 44100 * 2 {
                    let s = try e.renderOffline(tampon.frameCapacity, to: tampon)
                    guard s == .success, let k = tampon.floatChannelData else { break }
                    for i in 0..<Int(tampon.frameLength) { toplam += Double(k[0][i] * k[0][i]) }
                    adet += Int(tampon.frameLength)
                }
                print(String(format: "SES-SINAMA çevrimdışı uzaklık=%.0f rms=%.4f kare=%ld", d, sqrt(toplam / Double(max(1, adet))), adet))
                y.bosalt()
                e.stop()
            } catch {
                print("SES-SINAMA çevrimdışı hata \(error)")
            }
        }
        // 2) Gerçek motor
        let m = SesMotoru()
        m.yukle(["yagmur_hafif": 0.7, "kuslar": 0.5], baslat: true)
        try? await Task.sleep(nanoseconds: 2_500_000_000)
        let calan = m.yuvalar.filter { $0.oynatici.isPlaying }.count
        var ornek: Int64 = -1
        if let y = m.yuvalar.first(where: { $0.aktif }), let an = y.oynatici.lastRenderTime, let pt = y.oynatici.playerTime(forNodeTime: an) { ornek = pt.sampleTime }
        print("SES-SINAMA gerçek motor çalışıyor=\(m.motor.isRunning) çalan=\(calan) örnek=\(ornek) hata=\(m.hata ?? "-") kategori=\(AVAudioSession.sharedInstance().category.rawValue)")
        m.degistir("kuslar")
        try? await Task.sleep(nanoseconds: 600_000_000)
        m.degistir("deniz")
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        m.degistir("gurultu_pembe")
        try? await Task.sleep(nanoseconds: 800_000_000)
        print("SES-SINAMA gürültü çalan=\(m.yuvalar.filter { $0.oynatici.isPlaying }.count) seçili=\(m.katman.keys.sorted())")
        print("SES-SINAMA değişim sonrası çalan=\(m.yuvalar.filter { $0.oynatici.isPlaying }.count) seçili=\(m.katman.keys.sorted())")
        m.hepsiniKis()
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        print("SES-SINAMA bitti")
        exit(0)
    }
}
