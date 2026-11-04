import AVFoundation

/// Cihazda üretilen gürültüler. Dosya gerekmez: 16 saniyelik stereo bir tampon bir kez üretilir ve döngüyle çalınır.
/// Döngünün sonu başına eş güçlü çapraz geçişle dikilir; dikişte tık duyulmaz.
enum Gurultu: String, CaseIterable {
    case beyaz, pembe, kahverengi

    private static var onbellek: [Gurultu: AVAudioPCMBuffer] = [:]
    private static let kilit = NSLock()

    /// Kayıtlı doğa sesleriyle aynı algılanan yükseklikte olsun diye hedef etkin değer.
    private static let hedefRMS: Float = 0.11

    static func tampon(_ g: Gurultu, bicim: AVAudioFormat) -> AVAudioPCMBuffer? {
        kilit.lock(); defer { kilit.unlock() }
        if let t = onbellek[g], t.format.sampleRate == bicim.sampleRate, t.format.channelCount == bicim.channelCount { return t }
        let sr = bicim.sampleRate
        let n = Int(sr * 16), dikis = Int(sr * 0.75)
        guard let t = AVAudioPCMBuffer(pcmFormat: bicim, frameCapacity: AVAudioFrameCount(n)), let k = t.floatChannelData else { return nil }
        t.frameLength = AVAudioFrameCount(n)
        for kanal in 0..<Int(bicim.channelCount) {
            var u = Uretec(tohum: 0x9E37_79B9 &+ UInt64(kanal) &* 7919 &+ UInt64(g.rawValue.utf8.count) &* 104_729)
            var ham = [Float](repeating: 0, count: n + dikis)
            for i in 0..<ham.count { ham[i] = u.sonraki(g) }
            // Ortalamayı sıfırla (kahverengi gürültü kayabilir), sonra hedef yüksekliğe getir.
            let ort = ham.reduce(0, +) / Float(ham.count)
            var kare: Float = 0
            for i in 0..<ham.count { ham[i] -= ort; kare += ham[i] * ham[i] }
            let olcek = hedefRMS / max(1e-6, (kare / Float(ham.count)).squareRoot())
            let c = k[kanal]
            for i in 0..<n {
                var x = ham[i]
                if i < dikis {
                    // Baştaki parça, döngü sonunun devamıyla harmanlanır: son örnekten başa geçiş kesintisiz.
                    let a = Float(i) / Float(dikis) * .pi / 2
                    x = ham[i] * sin(a) + ham[n + i] * cos(a)
                }
                c[i] = max(-1, min(1, x * olcek))
            }
        }
        onbellek[g] = t
        return t
    }

    /// Küçük, hızlı ve tekrarlanabilir sayı üreteci (xorshift) ve renk süzgeçleri.
    private struct Uretec {
        var s: UInt64
        // Pembe (Paul Kellet) ve kahverengi (sızdıran toplayıcı) süzgeç durumu
        var b0: Float = 0, b1: Float = 0, b2: Float = 0, b3: Float = 0, b4: Float = 0, b5: Float = 0, b6: Float = 0
        var kah: Float = 0

        init(tohum: UInt64) { s = tohum == 0 ? 0x1234_5678 : tohum }

        mutating func beyaz() -> Float {
            s ^= s << 13; s ^= s >> 7; s ^= s << 17
            return Float(Double(s >> 11) / Double(1 << 53)) * 2 - 1
        }

        mutating func sonraki(_ g: Gurultu) -> Float {
            let w = beyaz()
            switch g {
            case .beyaz:
                return w
            case .pembe:
                b0 = 0.99886 * b0 + w * 0.0555179
                b1 = 0.99332 * b1 + w * 0.0750759
                b2 = 0.96900 * b2 + w * 0.1538520
                b3 = 0.86650 * b3 + w * 0.3104856
                b4 = 0.55000 * b4 + w * 0.5329522
                b5 = -0.7616 * b5 - w * 0.0168980
                let p = b0 + b1 + b2 + b3 + b4 + b5 + b6 + w * 0.5362
                b6 = w * 0.115926
                return p
            case .kahverengi:
                kah = (kah + 0.02 * w) * 0.995
                return kah
            }
        }
    }
}
