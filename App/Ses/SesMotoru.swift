import AVFoundation
import Observation
import SwiftUI

struct SesTuru: Identifiable, Hashable {
    let id: String
    let ad: String
    let simge: String
    let uzunluk: Double     // döngü uzunluğu (sn)
    let bas: Double = 0.5   // döngünün başladığı yer (sn); öncesi döngünün sonunun kopyası

    static let tumu: [SesTuru] = [
        SesTuru(id: "yagmur_hafif", ad: "Hafif yağmur", simge: "cloud.drizzle", uzunluk: 60.0),
        SesTuru(id: "yagmur", ad: "Yapraklarda yağmur", simge: "cloud.rain", uzunluk: 34.719297),
        SesTuru(id: "yagmur_cam", ad: "Camda yağmur", simge: "drop", uzunluk: 25.642653),
        SesTuru(id: "yagmur_siddetli", ad: "Sağanak", simge: "cloud.heavyrain", uzunluk: 14.288141),
        SesTuru(id: "gokgurultusu", ad: "Gök gürültüsü", simge: "cloud.bolt.rain", uzunluk: 60.0),
        SesTuru(id: "firtina", ad: "Rüzgâr", simge: "wind", uzunluk: 48.0),
        SesTuru(id: "orman_ruzgar", ad: "Ormanda rüzgâr", simge: "tree", uzunluk: 48.0),
        SesTuru(id: "kuslar", ad: "Kuşlar", simge: "bird", uzunluk: 70.0),
        SesTuru(id: "dere", ad: "Dere", simge: "humidity", uzunluk: 70.0),
        SesTuru(id: "deniz", ad: "Deniz", simge: "water.waves", uzunluk: 70.0),
        SesTuru(id: "gece", ad: "Gece", simge: "moon.stars", uzunluk: 70.0),
        SesTuru(id: "kamp_atesi", ad: "Kamp ateşi", simge: "flame", uzunluk: 60.0),
        SesTuru(id: "somine", ad: "Şömine", simge: "fireplace", uzunluk: 18.0),
        SesTuru(id: "kafe", ad: "Kafe", simge: "cup.and.saucer", uzunluk: 70.0),
        SesTuru(id: "kutuphane", ad: "Kütüphane", simge: "books.vertical", uzunluk: 70.0),
    ]
    static func bul(_ id: String) -> SesTuru? { tumu.first { $0.id == id } }
}

/// Bir ses katmanı: dosyanın döngü bölümünü kesintisiz, art arda kuyruğa ekleyerek çalar (bellekte tam dosya tutmaz).
@MainActor
private final class Katman {
    let oynatici = AVAudioPlayerNode()
    /// Uzaklık: alçak geçiren süzgeç (uzak ses boğuk) ve yankı (uzak ses odada dağılır).
    let suzgec = AVAudioUnitEQ(numberOfBands: 1)
    let yanki = AVAudioUnitReverb()
    let dosya: AVAudioFile
    let bas: AVAudioFramePosition
    let uzunluk: AVAudioFrameCount
    private var aktif = false
    private var duzey: Double = 0.7
    private var mesafe: Double = 0

    init?(_ tur: SesTuru) {
        guard let url = Bundle.main.url(forResource: tur.id, withExtension: "mp3"), let f = try? AVAudioFile(forReading: url) else { return nil }
        dosya = f
        let sr = f.processingFormat.sampleRate
        bas = AVAudioFramePosition(tur.bas * sr)
        uzunluk = AVAudioFrameCount(min(tur.uzunluk * sr, Double(f.length - bas)))
        let b = suzgec.bands[0]
        b.filterType = .lowPass
        b.frequency = 20000
        b.bypass = false
        yanki.loadFactoryPreset(.mediumRoom)
        yanki.wetDryMix = 2
    }

    /// d: 0 yakın … 1 uzak. Kesim frekansı 20 kHz'den 1,1 kHz'e iner, yankı artar, ses biraz kısılır.
    func ayarla(duzey: Double? = nil, mesafe: Double? = nil) {
        if let duzey { self.duzey = duzey }
        if let mesafe { self.mesafe = mesafe }
        let d = max(0, min(1, self.mesafe))
        suzgec.bands[0].frequency = Float(20000 * pow(1100.0 / 20000.0, d))
        yanki.wetDryMix = Float(2 + 46 * d)
        oynatici.volume = Float(self.duzey * (1 - 0.45 * d))
    }

    private func kuyruga() {
        oynatici.scheduleSegment(dosya, startingFrame: bas, frameCount: uzunluk, at: nil, completionCallbackType: .dataConsumed) { [weak self] _ in
            Task { @MainActor in self?.devam() }
        }
    }

    private func devam() { if aktif { kuyruga() } }

    func baslat() {
        guard !aktif else { if !oynatici.isPlaying { oynatici.play() }; return }
        aktif = true
        kuyruga(); kuyruga()
        oynatici.play()
    }

    func durdur() {
        aktif = false
        oynatici.stop()
    }
}

/// Odak sesleri karıştırıcısı. En çok 6 katman; çalmayan katman motoru meşgul etmez, hiçbir şey çalmıyorsa motor durur.
@MainActor
@Observable
final class SesMotoru {
    static let enFazla = 6
    private(set) var katman: [String: Double] = [:]     // seçili sesler ve düzeyleri
    private(set) var mesafe: [String: Double] = [:]     // 0 yakın … 1 uzak
    private(set) var caliyor = false
    private(set) var anaDuzey: Double = 1

    private let motor = AVAudioEngine()
    @ObservationIgnored private var katmanlar: [String: Katman] = [:]
    @ObservationIgnored private var gecis: Task<Void, Never>?
    @ObservationIgnored private var sonumGorevi: Task<Void, Never>?
    @ObservationIgnored private var gozlemciler: [NSObjectProtocol] = []
    /// Yumuşak açılış/kapanış çarpanı; kullanıcının ana düzeyiyle çarpılır.
    @ObservationIgnored private var gecisCarpani: Double = 1

    init() {
        let m = NotificationCenter.default
        gozlemciler.append(m.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] not in
            guard let ham = not.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt, let tip = AVAudioSession.InterruptionType(rawValue: ham) else { return }
            Task { @MainActor in
                if tip == .ended, self?.caliyor == true { self?.motoruBaslat() }
            }
        })
        gozlemciler.append(m.addObserver(forName: .AVAudioEngineConfigurationChange, object: motor, queue: .main) { [weak self] _ in
            Task { @MainActor in if self?.caliyor == true { self?.motoruBaslat() } }
        })
    }

    var seciliAdlar: String {
        let adlar = SesTuru.tumu.filter { katman[$0.id] != nil }.map(\.ad)
        return adlar.isEmpty ? "Ses seçilmedi" : adlar.joined(separator: " · ")
    }

    // MARK: Seçim

    func degistir(_ id: String) {
        if katman[id] != nil {
            katman[id] = nil
            mesafe[id] = nil
            if let k = katmanlar.removeValue(forKey: id) { kapat(k) }
            if katman.isEmpty { duraklat() }
        } else {
            guard katman.count < SesMotoru.enFazla else { Dokunsal.uyari(); return }
            katman[id] = 0.7
            if !caliyor { oynat() } else { ac(id) }
        }
    }

    func duzey(_ id: String, _ v: Double) {
        katman[id] = v
        katmanlar[id]?.ayarla(duzey: v)
    }

    func mesafeAyarla(_ id: String, _ v: Double) {
        mesafe[id] = v
        katmanlar[id]?.ayarla(mesafe: v)
    }

    func ana(_ v: Double) {
        anaDuzey = v
        uygula()
    }

    private func uygula() { motor.mainMixerNode.outputVolume = Float(anaDuzey * gecisCarpani) }

    func yukle(_ k: [String: Double], mesafe m: [String: Double] = [:], baslat: Bool) {
        for (id, kat) in katmanlar where k[id] == nil { kapat(kat); katmanlar[id] = nil }
        katman = k.filter { SesTuru.bul($0.key) != nil }
        mesafe = m.filter { katman[$0.key] != nil }
        for (id, kat) in katmanlar { kat.ayarla(duzey: katman[id] ?? 0.7, mesafe: mesafe[id] ?? 0) }
        if baslat || caliyor { oynat() }
    }

    /// Bütün sesleri yumuşakça kısıp kapatır.
    func hepsiniKis() {
        guard caliyor else { katman = [:]; return }
        gecisle(hedef: 0, sure: 0.8) { [weak self] in
            guard let self else { return }
            for k in self.katmanlar.values { self.kapat(k) }
            self.katmanlar = [:]
            self.katman = [:]
            self.mesafe = [:]
            self.caliyor = false
            self.motor.stop()
            self.gecisCarpani = 1
        }
    }

    // MARK: Çalma

    func oynat() {
        guard !katman.isEmpty else { return }
        motoruBaslat()
        for id in katman.keys { ac(id) }
        caliyor = true
        gecisCarpani = 0
        uygula()
        gecisle(hedef: 1, sure: 1.2)
    }

    func duraklat() {
        sonumGorevi?.cancel()
        guard caliyor else { return }
        gecisle(hedef: 0, sure: 0.6) { [weak self] in
            guard let self else { return }
            for k in self.katmanlar.values { k.oynatici.pause() }
            self.motor.pause()
            self.caliyor = false
            self.gecisCarpani = 1
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

    private func motoruBaslat() {
        let oturum = AVAudioSession.sharedInstance()
        try? oturum.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? oturum.setActive(true)
        if !motor.isRunning {
            motor.prepare()
            try? motor.start()
        }
        for k in katmanlar.values where !k.oynatici.isPlaying { k.baslat() }
    }

    private func ac(_ id: String) {
        if let k = katmanlar[id] { k.ayarla(duzey: katman[id] ?? 0.7, mesafe: mesafe[id] ?? 0); k.baslat(); return }
        guard let tur = SesTuru.bul(id), let k = Katman(tur) else { return }
        let bicim = k.dosya.processingFormat
        motor.attach(k.oynatici)
        motor.attach(k.suzgec)
        motor.attach(k.yanki)
        motor.connect(k.oynatici, to: k.suzgec, format: bicim)
        motor.connect(k.suzgec, to: k.yanki, format: bicim)
        motor.connect(k.yanki, to: motor.mainMixerNode, format: bicim)
        k.ayarla(duzey: katman[id] ?? 0.7, mesafe: mesafe[id] ?? 0)
        katmanlar[id] = k
        if !motor.isRunning { try? motor.start() }
        k.baslat()
    }

    private func kapat(_ k: Katman) {
        k.durdur()
        motor.detach(k.oynatici)
        motor.detach(k.suzgec)
        motor.detach(k.yanki)
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
}
