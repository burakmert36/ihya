import ActivityKit
import Foundation

/// Odak oturumunun Canlı Etkinliği (kilit ekranı ve Dynamic Island).
struct OdakEtkinligi: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// Molasız sürseydi biteceği an (sayaç sistem saatiyle sayar).
        var bitis: Date
        /// Sayacın başlangıcı (molalar düşülmüş).
        var baslangic: Date
        var molada: Bool
        /// Molada donmuş kalan süre (sn).
        var kalanSn: Int
    }
    var bitki: String
    var konu: String
    var plan: Int
}
