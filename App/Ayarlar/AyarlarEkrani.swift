import CoreLocation
import SwiftUI
import UniformTypeIdentifiers

struct AyarlarEkrani: View {
    @Environment(Depo.self) private var depo
    @Environment(VakitServisi.self) private var vakit
    @State private var ezanEkle: EzanTuru?
    @State private var ezanDurum = 0
    @State private var mesaj: String?
    @State private var konum = KonumAlici()

    struct Ton: Identifiable { let id: String; let ad: String }
    static let tonlar: [Ton] = [
        Ton(id: "bildirim_can", ad: "Çan"), Ton(id: "bildirim_kristal", ad: "Kristal"), Ton(id: "bildirim_damla", ad: "Damla"),
        Ton(id: "bildirim_sabah", ad: "Sabah"), Ton(id: "bildirim_huzur", ad: "Huzur"), Ton(id: "bildirim_esinti", ad: "Esinti"),
    ]

    var body: some View {
        Form {
            Section {
                Picker("Vakitler nereye göre?", selection: depo.ayar(\.konumKipi)) {
                    Text("Bursa · Diyanet takvimi").tag(KonumKipi.bursa)
                    Text("Bulunduğum yer").tag(KonumKipi.cihaz)
                }
                .pickerStyle(.inline)
                .labelsHidden()
                if depo.ayarlar.konumKipi == .cihaz {
                    Button {
                        konum.iste { e, b in
                            depo.degistir { $0.ayarlar.enlem = e; $0.ayarlar.boylam = b; $0.ayarlar.konumAdi = "Bulunduğun yer" }
                            mesaj = "Konum güncellendi."
                        }
                    } label: {
                        Label("Konumu güncelle", systemImage: "location")
                    }
                    Text(String(format: "%.3f, %.3f", depo.ayarlar.enlem, depo.ayarlar.boylam)).font(.footnote).foregroundStyle(.secondary)
                }
            } header: {
                Text("Vakitler").textCase(nil)
            } footer: {
                Text(depo.ayarlar.konumKipi == .bursa ? "Diyanet'in Bursa takvimi kullanılır; internet varken kendiliğinden yenilenir." : "Vakitler bulunduğun yere göre güneşin konumundan hesaplanır; Diyanet takviminden birkaç dakika sapabilir.")
            }

            Section {
                ForEach(0..<6, id: \.self) { i in
                    Toggle(VakitAdi.adlar[i], isOn: Binding(get: { depo.ayarlar.vakitBildirim[i] }, set: { v in depo.degistir { $0.ayarlar.vakitBildirim[i] = v } }))
                }
                Picker("Önceden hatırlat", selection: depo.ayar(\.onceDakika)) {
                    Text("Vaktinde").tag(0)
                    ForEach([5, 10, 15, 30, 45], id: \.self) { Text("\($0) dk önce").tag($0) }
                }
            } header: {
                Text("Bildirimler").textCase(nil)
            }

            Section {
                Picker("Bildirim sesi", selection: depo.ayar(\.ezan)) {
                    ForEach(EzanTuru.allCases) { Text($0.ad).tag($0) }
                }
                if let kayit = depo.ayarlar.ezan.kayitAdi {
                    let hazir = EzanKaydi.mevcut(kayit) && ezanDurum >= 0
                    HStack {
                        Label(hazir ? "Kayıt hazır" : "Kayıt yok", systemImage: hazir ? "checkmark.circle.fill" : "exclamationmark.circle")
                            .foregroundStyle(hazir ? Color.ihya : .orange)
                        Spacer()
                        Button(hazir ? "Değiştir" : "Ses dosyası ekle") { ezanEkle = depo.ayarlar.ezan }
                    }
                    if hazir {
                        Button("Kaydı sil", role: .destructive) { EzanKaydi.sil(kayit); ezanDurum += 1 }
                    }
                }
                if depo.ayarlar.ezan != .sessiz {
                    ForEach(AyarlarEkrani.tonlar) { t in
                        Button {
                            depo.degistir { $0.ayarlar.bildirimTonu = t.id }
                            Efekt.cal(t.id, duzey: 0.8)
                        } label: {
                            HStack {
                                Text(t.ad).foregroundStyle(.primary)
                                Spacer()
                                if depo.ayarlar.bildirimTonu == t.id { Image(systemName: "checkmark").foregroundStyle(Color.ihya) }
                                Image(systemName: "play.circle").foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } header: {
                Text("Ezan ve Bildirim Sesi").textCase(nil)
            } footer: {
                Text("iOS bildirim sesini 30 saniyeyle sınırlar. Makamlı ezan ve tek müezzin için kendi ses dosyanı ekle; ilk 29 saniyesi çalar. Kayıt yoksa ya da güneş vaktinde aşağıdaki kısa ton çalar.")
            }

            Section {
                Toggle("Uygulamadan çıkınca bitki kurusun", isOn: depo.ayar(\.katiMod))
            } header: {
                Text("Odak").textCase(nil)
            } footer: {
                Text("Ekranı kilitlemek her zaman serbest. Bu açıkken başka uygulamaya geçip 10 saniyeden uzun kalırsan bitki kurur.")
            }

            Section {
                Toggle("Odak süresince", isOn: depo.ayar(\.sesOdakta))
                Toggle("Sonda sesi yavaşça azalt", isOn: depo.ayar(\.sesSondaAzalt))
            } header: {
                Text("Sesler").textCase(nil)
            }

            Section {
                Toggle("Titreşim", isOn: depo.ayar(\.tesbihTitresim))
                Toggle("Tık sesi", isOn: depo.ayar(\.tesbihSes))
                if depo.ayarlar.tesbihSes {
                    HStack {
                        Image(systemName: "speaker.fill").foregroundStyle(.secondary)
                        Slider(value: depo.ayar(\.tesbihSesDuzeyi), in: 0.05...1, onEditingChanged: { suruyor in
                            if !suruyor { Efekt.cal("tesbih_tik", duzey: Float(depo.ayarlar.tesbihSesDuzeyi)) }
                        })
                        Image(systemName: "speaker.wave.3.fill").foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Tesbih").textCase(nil)
            }

            Section {
                Picker("Tema", selection: depo.ayar(\.tema)) {
                    ForEach(Tema.allCases) { Text($0.ad).tag($0) }
                }
                Stepper("Okuma yazısı: \(Int(depo.ayarlar.okumaPunto)) pt", value: depo.ayar(\.okumaPunto), in: 14...30, step: 1)
                NavigationLink(value: Rota.konular) { Text("Odak konuları") }
            } header: {
                Text("Görünüm").textCase(nil)
            }

            Section {
                Kaynak(ad: "Hadisler", deger: "Sahîh-i Buhârî (Türkçe tercüme; her metin numarasıyla karşılaştırıldı)")
                Kaynak(ad: "Âyet mealleri", deger: "Diyanet İşleri Başkanlığı meali")
                Kaynak(ad: "Vakitler", deger: "Diyanet takvimi (ezanvakti.emushaf.net)")
                Kaynak(ad: "Doğa sesleri", deger: "Moodist ve Blanket kayıtları (CC0 / Pixabay lisansı)")
                Kaynak(ad: "Arapça yazı", deger: "Amiri yazı tipi (SIL Open Font License)")
                Kaynak(ad: "Sürüm", deger: (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") + " (" + (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "") + ")")
            } header: {
                Text("Kaynaklar").textCase(nil)
            }
        }
        .navigationTitle("Ayarlar")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: Binding(get: { ezanEkle != nil }, set: { if !$0 { ezanEkle = nil } }), allowedContentTypes: [.audio]) { sonuc in
            guard let tur = ezanEkle, let ad = tur.kayitAdi else { return }
            if case .success(let url) = sonuc {
                do {
                    try EzanKaydi.ice(url, ad: ad)
                    ezanDurum += 1
                    mesaj = "\(tur.ad) kaydı eklendi."
                    Task { await Bildirim.vakitleriKur(vakit, depo.ayarlar) }
                } catch {
                    mesaj = "Bu dosya okunamadı. MP3, M4A ya da WAV dene."
                }
            }
            ezanEkle = nil
        }
        .alert(mesaj ?? "", isPresented: Binding(get: { mesaj != nil }, set: { if !$0 { mesaj = nil } })) {
            Button("Tamam", role: .cancel) {}
        }
    }
}

private struct Kaynak: View {
    let ad: String
    let deger: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(ad).font(.subheadline)
            Text(deger).font(.caption).foregroundStyle(.secondary)
        }
    }
}

/// Tek seferlik konum (vakit hesabı için).
@Observable
final class KonumAlici: NSObject, CLLocationManagerDelegate {
    private let y = CLLocationManager()
    @ObservationIgnored private var bitince: ((Double, Double) -> Void)?

    override init() {
        super.init()
        y.delegate = self
        y.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func iste(_ b: @escaping (Double, Double) -> Void) {
        bitince = b
        if y.authorizationStatus == .notDetermined { y.requestWhenInUseAuthorization() }
        y.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let k = locations.last else { return }
        bitince?(k.coordinate.latitude, k.coordinate.longitude)
        bitince = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if bitince != nil, manager.authorizationStatus == .authorizedWhenInUse { manager.requestLocation() }
    }
}
