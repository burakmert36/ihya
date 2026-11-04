import CoreLocation
import SwiftUI
import UniformTypeIdentifiers

struct AyarlarEkrani: View {
    @Environment(Depo.self) private var depo
    @Environment(VakitServisi.self) private var vakit
    @Environment(\.palet) private var palet
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
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                BolumBasligi(metin: "Tema").padding(.horizontal, 6)
                temalar
                grup("Vakitler") {
                    secimSatiri("Vakitler nereye göre?", alt: depo.ayarlar.konumKipi == .bursa ? "Diyanet'in Bursa takvimi; internet varken kendiliğinden yenilenir." : "Bulunduğun yere göre güneşten hesaplanır; birkaç dakika sapabilir.") {
                        Picker("", selection: depo.ayar(\.konumKipi)) {
                            Text("Bursa").tag(KonumKipi.bursa)
                            Text("Konumum").tag(KonumKipi.cihaz)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 160)
                    }
                    if depo.ayarlar.konumKipi == .cihaz {
                        Ayrac()
                        Button {
                            konum.iste { e, b in
                                depo.degistir { $0.ayarlar.enlem = e; $0.ayarlar.boylam = b; $0.ayarlar.konumAdi = "Bulunduğun yer" }
                                mesaj = "Konum güncellendi."
                            }
                        } label: {
                            HStack {
                                Label("Konumu güncelle", systemImage: "location").font(.system(size: 15, weight: .bold))
                                Spacer()
                                Text(String(format: "%.3f, %.3f", depo.ayarlar.enlem, depo.ayarlar.boylam)).font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                grup("Hatırlatmalar") {
                    ForEach(0..<6, id: \.self) { i in
                        if i > 0 { Ayrac() }
                        anahtar(VakitAdi.adlar[i], alt: i == 1 ? "Güneş doğuşu; sabah namazının son vakti" : nil,
                                Binding(get: { depo.ayarlar.vakitBildirim[i] }, set: { v in depo.degistir { $0.ayarlar.vakitBildirim[i] = v } }))
                    }
                    Ayrac()
                    secimSatiri("Önceden hatırlat", alt: nil) {
                        Picker("", selection: depo.ayar(\.onceDakika)) {
                            Text("Vaktinde").tag(0)
                            ForEach([5, 10, 15, 30, 45], id: \.self) { Text("\($0) dk önce").tag($0) }
                        }
                        .pickerStyle(.menu)
                    }
                }
                grup("Ezan ve bildirim sesi") {
                    secimSatiri("Bildirim sesi", alt: nil) {
                        Picker("", selection: depo.ayar(\.ezan)) {
                            ForEach(EzanTuru.allCases) { Text($0.ad).tag($0) }
                        }
                        .pickerStyle(.menu)
                    }
                    if let kayit = depo.ayarlar.ezan.kayitAdi {
                        let hazir = EzanKaydi.mevcut(kayit) && ezanDurum >= 0
                        Ayrac()
                        HStack {
                            Label(hazir ? "Kayıt hazır" : "Kayıt yok", systemImage: hazir ? "checkmark.circle.fill" : "exclamationmark.circle")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(hazir ? Color(hex: "#34C759") : Color.orange)
                            Spacer()
                            Button(hazir ? "Değiştir" : "Ses dosyası ekle") { ezanEkle = depo.ayarlar.ezan }.font(.system(size: 14, weight: .bold))
                            if hazir {
                                Button("Sil", role: .destructive) { EzanKaydi.sil(kayit); ezanDurum += 1 }.font(.system(size: 14, weight: .bold))
                            }
                        }
                    }
                    if depo.ayarlar.ezan != .sessiz {
                        Ayrac()
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                            ForEach(AyarlarEkrani.tonlar) { t in
                                let on = depo.ayarlar.bildirimTonu == t.id
                                Button {
                                    depo.degistir { $0.ayarlar.bildirimTonu = t.id }
                                    Efekt.cal(t.id, duzey: 0.9)
                                } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: on ? "speaker.wave.2.fill" : "play.fill").font(.system(size: 11, weight: .bold))
                                        Text(t.ad).font(.kalin(13))
                                    }
                                    .foregroundStyle(on ? Color.white : Color.primary)
                                    .frame(maxWidth: .infinity, minHeight: 38)
                                    .background(Capsule().fill(on ? Color(hex: "#1FB25A") : Color.primary.opacity(0.07)))
                                    .contentShape(Capsule())
                                }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(on ? .isSelected : [])
                            }
                        }
                    }
                    Ayrac()
                    Button {
                        Task { mesaj = await Bildirim.dene(depo.ayarlar) }
                    } label: {
                        Label("Deneme bildirimi gönder", systemImage: "bell.badge").font(.kalin(14)).frame(maxWidth: .infinity, minHeight: 30)
                    }
                    .buttonStyle(.glass)
                    Text("Tona dokununca telefon sessizde de duyulur. Bildirim sesini ise iOS, telefon sessiz kipteyken çalmaz. iOS bildirim sesini 30 saniyeyle sınırlar; makamlı ezan için kendi kaydını ekle, ilk 29 saniyesi çalar.")
                        .font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                }
                grup("Odak") {
                    anahtar("Uygulamadan çıkınca bitki kurusun", alt: "Ekranı kilitlemek serbest; başka uygulamada 10 sn'den uzun kalırsan bitki kurur.", depo.ayar(\.katiMod))
                    Ayrac()
                    secimSatiri("Günlük hedef", alt: "Bugün kartındaki çubuk") {
                        Stepper("\(depo.ayarlar.gunlukHedef) dk", value: depo.ayar(\.gunlukHedef), in: 10...600, step: 10)
                            .font(.system(size: 14, weight: .bold))
                            .fixedSize()
                    }
                    Ayrac()
                    NavigationLink(value: Rota.konular) {
                        HStack {
                            Text("Odak konuları").font(.system(size: 15, weight: .bold))
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                grup("Sesler") {
                    anahtar("Odak süresince çal", alt: "Son seçtiğin sesler odak başlayınca çalar, bitince durur.", depo.ayar(\.sesOdakta))
                    Ayrac()
                    anahtar("Sonda sesi yavaşça azalt", alt: nil, depo.ayar(\.sesSondaAzalt))
                    Ayrac()
                    anahtar("Ezan vaktinde sustur", alt: nil, depo.ayar(\.ezandaSustur))
                    Ayrac()
                    anahtar("Kur’an dinlerken kıs", alt: "Başka uygulama ses çalınca odak sesleri kısılır.", depo.ayar(\.kuranDinlerkenKis))
                }
                grup("Tesbih") {
                    anahtar("Titreşim", alt: nil, depo.ayar(\.tesbihTitresim))
                    Ayrac()
                    anahtar("Kehribar sesi", alt: nil, depo.ayar(\.tesbihSes))
                    if depo.ayarlar.tesbihSes {
                        HStack {
                            Image(systemName: "speaker.fill").foregroundStyle(.secondary)
                            Slider(value: depo.ayar(\.tesbihSesDuzeyi), in: 0.05...1, onEditingChanged: { suruyor in
                                if !suruyor { Efekt.cal("tesbih_tik", duzey: Float(depo.ayarlar.tesbihSesDuzeyi)) }
                            })
                            Image(systemName: "speaker.wave.3.fill").foregroundStyle(.secondary)
                        }
                    }
                }
                grup("Okuma") {
                    secimSatiri("Yazı boyutu", alt: nil) {
                        Stepper("\(Int(depo.ayarlar.okumaPunto)) pt", value: depo.ayar(\.okumaPunto), in: 14...30, step: 1)
                            .font(.system(size: 14, weight: .bold))
                            .fixedSize()
                    }
                    Ayrac()
                    anahtar("Koyu okuma kartları", alt: "Hadis, söz ve dualarda krem yerine koyu kart", Binding(get: { depo.ayarlar.okumaKoyu ?? false }, set: { v in depo.degistir { $0.ayarlar.okumaKoyu = v } }))
                }
                grup("Kaynaklar") {
                    Kaynak(ad: "Hadisler", deger: "Sahîh-i Buhârî (Türkçe tercüme; her metin numarasıyla karşılaştırıldı)")
                    Ayrac()
                    Kaynak(ad: "Âyet mealleri", deger: "Diyanet İşleri Başkanlığı meali")
                    Ayrac()
                    Kaynak(ad: "Vakitler", deger: "Diyanet takvimi (ezanvakti.emushaf.net)")
                    Ayrac()
                    Kaynak(ad: "Doğa sesleri", deger: "Moodist ve Blanket kayıtları (CC0 / Pixabay lisansı)")
                    Ayrac()
                    Kaynak(ad: "Arapça yazı", deger: "Amiri yazı tipi (SIL Open Font License)")
                    Ayrac()
                    Kaynak(ad: "Sürüm", deger: (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") + " (" + (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "") + ")")
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
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

    /// Tema önizlemeleri: saat, çubuk ve üç nokta.
    private var temalar: some View {
        HStack(spacing: 8) {
            ForEach(Tema.allCases) { t in
                let on = depo.ayarlar.tema == t
                let o = t.onizleme
                Button {
                    withAnimation(.easeInOut(duration: 0.35)) { depo.degistir { $0.ayarlar.tema = t } }
                    Dokunsal.hafif(0.6)
                } label: {
                    VStack(spacing: 6) {
                        VStack(spacing: 6) {
                            Text("17:49").font(.kalin(15)).foregroundStyle(o.vurgu)
                            Capsule().fill(o.cubuk).frame(width: 34, height: 4)
                            HStack(spacing: 3) {
                                Circle().fill(o.vurgu).frame(width: 6, height: 6)
                                Circle().fill(o.vurgu).frame(width: 6, height: 6)
                                Circle().strokeBorder(o.vurgu, lineWidth: 1.2).frame(width: 6, height: 6)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 86)
                        .background {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(t == .ihya ? AnyShapeStyle(LinearGradient(colors: [Color(hex: "#8FD0F7"), Color(hex: "#F2F7FF"), Color(hex: "#FFF1DE")], startPoint: .top, endPoint: .bottom)) : AnyShapeStyle(o.taban))
                        }
                        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(on ? palet.vurgu : Color.primary.opacity(0.12), lineWidth: on ? 3 : 1))
                        Text(t.ad).font(.kalin(12)).foregroundStyle(on ? palet.vurgu : Color.primary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(t.ad) teması")
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(10)
        .glassEffect(palet.cam(), in: .rect(cornerRadius: 26))
    }

    private func grup<I: View>(_ baslik: String, @ViewBuilder _ icerik: () -> I) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            BolumBasligi(metin: baslik).padding(.horizontal, 6).padding(.top, 8)
            VStack(alignment: .leading, spacing: 10) { icerik() }
                .camKart(kose: 24, ic: 14)
        }
    }

    private func anahtar(_ ad: String, alt: String?, _ deger: Binding<Bool>) -> some View {
        Toggle(isOn: deger) {
            VStack(alignment: .leading, spacing: 2) {
                Text(ad).font(.system(size: 15, weight: .bold))
                if let alt { Text(alt).font(.system(size: 12.5, weight: .medium)).foregroundStyle(.secondary) }
            }
        }
        .tint(Color(hex: "#34C759"))
    }

    private func secimSatiri<S: View>(_ ad: String, alt: String?, @ViewBuilder _ secim: () -> S) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(ad).font(.system(size: 15, weight: .bold))
                if let alt { Text(alt).font(.system(size: 12.5, weight: .medium)).foregroundStyle(.secondary) }
            }
            Spacer(minLength: 4)
            secim()
        }
    }
}

/// Grup içindeki ince ayraç.
private struct Ayrac: View {
    var body: some View { Rectangle().fill(Color.primary.opacity(0.08)).frame(height: 0.5) }
}

private struct Kaynak: View {
    let ad: String
    let deger: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(ad).font(.system(size: 14, weight: .bold))
            Text(deger).font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
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
