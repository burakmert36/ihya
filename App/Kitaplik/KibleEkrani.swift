import CoreLocation
import SwiftUI

/// Pusula ve konum: kıble açısı (büyük daire), Kâbe'ye uzaklık. Konum izni yoksa Bursa kullanılır.
@Observable
final class KibleYonetici: NSObject, CLLocationManagerDelegate {
    var yon: Double = 0                 // cihazın baktığı yön (derece, kuzeyden)
    var pusulaVar = CLLocationManager.headingAvailable()
    var enlem = 40.1826
    var boylam = 29.0665
    var konumlu = false
    var dogruluk: Double = -1

    @ObservationIgnored private let yonetici = CLLocationManager()
    static let kabe = (enlem: 21.4225, boylam: 39.8262)

    override init() {
        super.init()
        yonetici.delegate = self
        yonetici.desiredAccuracy = kCLLocationAccuracyKilometer
        yonetici.headingFilter = 1
    }

    func baslat() {
        if yonetici.authorizationStatus == .notDetermined { yonetici.requestWhenInUseAuthorization() }
        yonetici.startUpdatingLocation()
        if pusulaVar { yonetici.startUpdatingHeading() }
    }

    func durdur() {
        yonetici.stopUpdatingHeading()
        yonetici.stopUpdatingLocation()
    }

    var kibleAcisi: Double {
        let r = Double.pi / 180
        let f1 = enlem * r, f2 = KibleYonetici.kabe.enlem * r, dl = (KibleYonetici.kabe.boylam - boylam) * r
        let t = atan2(sin(dl) * cos(f2), cos(f1) * sin(f2) - sin(f1) * cos(f2) * cos(dl)) / r
        return (t + 360).truncatingRemainder(dividingBy: 360)
    }

    var uzaklikKm: Int {
        let r = Double.pi / 180
        let df = (KibleYonetici.kabe.enlem - enlem) * r, dl = (KibleYonetici.kabe.boylam - boylam) * r
        let a = sin(df / 2) * sin(df / 2) + cos(enlem * r) * cos(KibleYonetici.kabe.enlem * r) * sin(dl / 2) * sin(dl / 2)
        return Int(6371 * 2 * atan2(sqrt(a), sqrt(1 - a)))
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        yon = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        dogruluk = newHeading.headingAccuracy
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let k = locations.last else { return }
        enlem = k.coordinate.latitude
        boylam = k.coordinate.longitude
        konumlu = true
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
}

struct KibleEkrani: View {
    @State private var y = KibleYonetici()

    var body: some View {
        let fark = Self.aci(y.kibleAcisi - y.yon)
        let hizali = y.pusulaVar && abs(fark) < 4
        VStack(spacing: 24) {
            VStack(spacing: 4) {
                Text(hizali ? "Kıble yönündesin" : y.pusulaVar ? (fark > 0 ? "Sağa dön" : "Sola dön") : "Kıble açısı")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(hizali ? Color.ihya : .primary)
                    .contentTransition(.opacity)
                Text(y.pusulaVar ? "\(Int(abs(fark).rounded()))° fark" : "Bu cihazda pusula yok; açıyı kuzeyden ölç.")
                    .font(.subheadline).foregroundStyle(.secondary).monospacedDigit()
            }
            .padding(.top, 12)
            ZStack {
                Circle()
                    .fill(hizali ? Color.ihya.opacity(0.14) : Color.secondary.opacity(0.06))
                    .animation(.easeInOut(duration: 0.3), value: hizali)
                Kadran(kible: y.kibleAcisi)
                    .rotationEffect(.degrees(-y.yon))
                    .animation(.interpolatingSpring(stiffness: 60, damping: 14), value: y.yon)
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.title3)
                    .foregroundStyle(hizali ? Color.ihya : .primary)
                    .offset(y: -168)
            }
            .frame(width: 320, height: 320)
            .sensoryFeedback(.success, trigger: hizali) { _, yeni in yeni }
            VStack(spacing: 6) {
                Text("Kıble açısı \(Int(y.kibleAcisi.rounded()))° · Kâbe'ye \(y.uzaklikKm.formatted()) km")
                    .font(.subheadline).monospacedDigit()
                Text(y.konumlu ? "Bulunduğun yere göre" : "Konum yok; Bursa'ya göre hesaplandı")
                    .font(.footnote).foregroundStyle(.secondary)
                if y.pusulaVar, y.dogruluk > 20 {
                    Label("Pusulayı düzeltmek için telefonu havada 8 çiz.", systemImage: "exclamationmark.triangle")
                        .font(.footnote).foregroundStyle(.orange)
                }
            }
            Spacer(minLength: 0)
            Text("Telefonu yere paralel tut. Metal ve mıknatıslardan uzak dur.")
                .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                .padding(.bottom, 12)
        }
        .padding(.horizontal, 20)
        .navigationTitle("Kıble")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { y.baslat() }
        .onDisappear { y.durdur() }
    }

    /// -180…180 aralığına getirir.
    static func aci(_ a: Double) -> Double {
        var x = a.truncatingRemainder(dividingBy: 360)
        if x > 180 { x -= 360 }
        if x < -180 { x += 360 }
        return x
    }
}

/// Pusula kadranı: yön harfleri, derece çizgileri ve kıble işareti.
private struct Kadran: View {
    let kible: Double
    var body: some View {
        ZStack {
            ForEach(0..<72, id: \.self) { i in
                Rectangle()
                    .fill(i % 18 == 0 ? Color.primary : Color.secondary.opacity(i % 2 == 0 ? 0.6 : 0.3))
                    .frame(width: i % 18 == 0 ? 2 : 1, height: i % 18 == 0 ? 14 : (i % 2 == 0 ? 9 : 6))
                    .offset(y: -150)
                    .rotationEffect(.degrees(Double(i) * 5))
            }
            ForEach(Array(["K", "D", "G", "B"].enumerated()), id: \.offset) { i, h in
                Text(h)
                    .font(.headline)
                    .foregroundStyle(i == 0 ? Color.red : .primary)
                    .rotationEffect(.degrees(-Double(i) * 90))
                    .offset(y: -122)
                    .rotationEffect(.degrees(Double(i) * 90))
            }
            VStack(spacing: 4) {
                KabeSimgesi().frame(width: 34, height: 34)
                Capsule().fill(Color.ihya).frame(width: 3, height: 76)
            }
            .offset(y: -58)
            .rotationEffect(.degrees(kible))
            Circle().fill(Color.ihya).frame(width: 10, height: 10)
        }
    }
}
