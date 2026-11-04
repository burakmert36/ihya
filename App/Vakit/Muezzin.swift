import AVFoundation
import SwiftUI

/// İndirilebilir ezan kayıtları. Kayıtlar depoya konmaz; seçilince indirilir.
/// İlk 29 saniyesi bildirim sesi olur (iOS sınırı 30 sn); uygulama açıkken vakit girerse ezanın tamamı okunur.
struct Muezzin: Identifiable, Hashable {
    let id: String
    let ad: String
    let not: String
    let dosya: String

    /// Sabit bir sürüme bağlı: dosyalar sonradan değişemez.
    static let kaynak = "https://raw.githubusercontent.com/abodehq/Athan-MP3/cf1a9dd4f1e5e10009439099c5af74479ad332c0/Sounds/"

    var url: URL? { dosya.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed).flatMap { URL(string: Muezzin.kaynak + $0) } }
    /// Library/Sounds altındaki bildirim sesi (uzantısız).
    var kayitAdi: String { "ezan_m_" + id }

    static let tumu: [Muezzin] = [
        Muezzin(id: "mekke", ad: "Mekke ezanı", not: "Mescid-i Harâm", dosya: "Athan Makkah.mp3"),
        Muezzin(id: "afasi", ad: "Meşârî el-Afâsî", not: "Kuveyt", dosya: "Athan Mishary Alafasi.mp3"),
        Muezzin(id: "katami", ad: "Nâsır el-Katâmî", not: "Riyad", dosya: "Athan Nasser Alqatami.mp3"),
        Muezzin(id: "zehrani", ad: "Mansûr ez-Zehrânî", not: "Suudi Arabistan", dosya: "Athan Mansoor Az-Zahrani.mp3"),
        Muezzin(id: "hemezani", ad: "Mâcid el-Hemezânî", not: "Suudi Arabistan", dosya: "Athan Majed Al-hamathani.mp3"),
        Muezzin(id: "maliki", ad: "Hamdân el-Mâlikî", not: "Suudi Arabistan", dosya: "Athan Hamdan Almalki.mp3"),
        Muezzin(id: "dagriri", ad: "Hamed ed-Dağrîrî", not: "Suudi Arabistan", dosya: "Athan Hamad Deghreri.mp3"),
        Muezzin(id: "erkani", ad: "İbrâhim el-Erkânî", not: "Suudi Arabistan", dosya: "Athan Ibrahim Al-Arkani.mp3"),
        Muezzin(id: "abdulbasit", ad: "Abdulbâsıt Abdussamed", not: "Mısır, eski kayıt", dosya: "Athan Abed Albase6.mp3"),
        Muezzin(id: "minsavi", ad: "Muhammed Sıddîk el-Minşâvî", not: "Mısır, eski kayıt", dosya: "Athan Mohammad Almenshawy.mp3"),
        Muezzin(id: "rifat", ad: "Muhammed Rif'at", not: "Mısır, eski kayıt", dosya: "Athan Mohammad Ref3at.mp3"),
        Muezzin(id: "nuayna", ad: "Ahmed Nuayna", not: "Mısır", dosya: "Athan Ahmad Nuyne3.mp3"),
        Muezzin(id: "suheyb", ad: "Suheyb Hatbe", not: "", dosya: "Athan Suhaib Khatba.mp3"),
        Muezzin(id: "sabah", ad: "Sabah ezanı", not: "“es-salâtu hayrun mine'n-nevm” ile", dosya: "Athan Al-fajer - Malek chebae.mp3"),
    ]

    static func bul(_ id: String) -> Muezzin { tumu.first { $0.id == id } ?? tumu[0] }
}

/// Müezzin kayıtlarını indirir, önizletir ve uygulama açıkken ezanın tamamını okur.
@MainActor
@Observable
final class EzanCalar {
    static let ortak = EzanCalar()

    /// Bildirim temsilcisi ana iş parçacığı dışından da okuyabilsin diye ayarların kopyası.
    nonisolated(unsafe) static var ayarlar = Ayarlar()

    private(set) var inenler: Set<String> = []
    private(set) var calan: String?
    private(set) var hata: String?
    /// Görünümler indirme bitince yenilensin.
    private(set) var surum = 0
    @ObservationIgnored private var oynatici: AVAudioPlayer?
    @ObservationIgnored private let bitis = EzanBitis()

    private init() { bitis.bitti = { [weak self] in self?.calan = nil } }

    /// Uygulama Desteği/Ezan: tam kayıtlar (yeniden indirilebilir, yedeğe girmez).
    nonisolated static var klasor: URL {
        var u = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Ezan")
        if !FileManager.default.fileExists(atPath: u.path) {
            try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
            var d = URLResourceValues()
            d.isExcludedFromBackup = true
            try? u.setResourceValues(d)
        }
        return u
    }

    nonisolated static func tam(_ m: Muezzin) -> URL { klasor.appendingPathComponent(m.id + ".mp3") }

    nonisolated static func hazir(_ m: Muezzin) -> Bool {
        FileManager.default.fileExists(atPath: tam(m).path) && EzanKaydi.mevcut(m.kayitAdi)
    }

    func hazirMi(_ m: Muezzin) -> Bool { _ = surum; return EzanCalar.hazir(m) }

    /// Kaydı indirir ve bildirim sesini (29 sn) hazırlar.
    @discardableResult
    func indir(_ m: Muezzin) async -> Bool {
        if EzanCalar.hazir(m) { return true }
        guard let url = m.url, !inenler.contains(m.id) else { return false }
        inenler.insert(m.id)
        defer { inenler.remove(m.id); surum += 1 }
        let hedef = EzanCalar.tam(m)
        guard await Indirici.indir(url, hedef, ilerleme: { _ in }) else {
            hata = "\(m.ad) indirilemedi. İnternet bağlantını kontrol et."
            return false
        }
        do {
            try EzanKaydi.ice(hedef, ad: m.kayitAdi)
            var u = EzanKaydi.klasor.appendingPathComponent(m.kayitAdi + ".caf")
            var d = URLResourceValues()
            d.isExcludedFromBackup = true
            try? u.setResourceValues(d)
            hata = nil
            return true
        } catch {
            try? FileManager.default.removeItem(at: hedef)
            hata = "\(m.ad) kaydı açılamadı."
            return false
        }
    }

    /// Ayarlarda seçili bütün müezzinleri indirir.
    func gerekenleriIndir(_ a: Ayarlar) async {
        guard a.ezan == .muezzin else { return }
        let idler = Set([0, 2, 3, 4, 5].map { a.vaktinMuezzini($0) })
        for id in idler { await indir(Muezzin.bul(id)) }
    }

    func onizle(_ m: Muezzin) {
        if calan == m.id { durdur(); return }
        Task {
            guard await indir(m), let o = try? AVAudioPlayer(contentsOf: EzanCalar.tam(m)) else { return }
            oynat(o, m.id)
        }
    }

    func durdur() {
        oynatici?.stop()
        oynatici = nil
        calan = nil
    }

    private func oynat(_ o: AVAudioPlayer, _ id: String) {
        oynatici?.stop()
        SesOturumu.hazirla()
        o.delegate = bitis
        o.prepareToPlay()
        o.play()
        oynatici = o
        calan = id
    }

    /// Vakit bildirimi uygulama açıkken gelirse ezanın tamamı okunur; bildirim sessiz gösterilir.
    nonisolated static func tamOkunacak(vakit i: Int) -> Muezzin? {
        let a = ayarlar
        guard a.ezan == .muezzin, i != 1, a.onceDakika == 0 else { return nil }
        let m = Muezzin.bul(a.vaktinMuezzini(i))
        return FileManager.default.fileExists(atPath: tam(m).path) ? m : nil
    }

    func vaktiOku(_ m: Muezzin) {
        guard !TilavetMotoru.ortak.caliyor, let o = try? AVAudioPlayer(contentsOf: EzanCalar.tam(m)) else { return }
        oynat(o, m.id)
    }
}

private final class EzanBitis: NSObject, AVAudioPlayerDelegate {
    var bitti: (@MainActor () -> Void)?
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.bitti?() }
    }
}

/// Müezzin seçimi: önizleme, indirme, vakte göre ayrı ses.
struct MuezzinSecici: View {
    @Environment(Depo.self) private var depo
    @Environment(VakitServisi.self) private var vakit
    @Environment(\.palet) private var palet
    @Environment(\.dismiss) private var kapat
    @State private var e = EzanCalar.ortak
    /// nil: genel seçim; sayı: o vaktin seçimi
    @State private var hedefVakit: Int?

    private static let vakitler = [0, 2, 3, 4, 5]

    var body: some View {
        let a = depo.ayarlar
        let ayri = a.vakitMuezzin.count == 6
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Kâbe imamları ezan okumaz; ezanı müezzinler okur. Mekke ezanı Mescid-i Harâm'dan bir kayıttır. Seçtiğin kayıt bir kez iner; vakit bildiriminde ilk 29 saniyesi çalar (iOS sınırı), uygulama açıksa ezanın tamamı okunur.")
                        .font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)

                    Toggle(isOn: Binding(get: { ayri }, set: { v in
                        depo.degistir { $0.ayarlar.vakitMuezzin = v ? Array(repeating: $0.ayarlar.muezzin, count: 6) : [] }
                        if !v { hedefVakit = nil }
                    })) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Her vakte ayrı ezan").font(.kalin(15))
                            Text("Sabah, öğle, ikindi, akşam ve yatsıya ayrı müezzin seç.").font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                        }
                    }
                    .camKart(kose: 22, ic: 14)

                    if ayri {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(MuezzinSecici.vakitler, id: \.self) { i in
                                    let secili = (hedefVakit ?? 0) == i
                                    Button { hedefVakit = i } label: {
                                        VStack(spacing: 2) {
                                            Text(VakitAdi.adlar[i] == "İmsak" ? "Sabah" : VakitAdi.adlar[i]).font(.kalin(13))
                                            Text(Muezzin.bul(a.vaktinMuezzini(i)).ad).font(.system(size: 10.5, weight: .semibold)).lineLimit(1)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(.horizontal, 12).frame(width: 118, height: 50)
                                        .camYuzey(palet.cam(secili ? palet.vurgu.opacity(0.3) : nil, etkilesimli: true), in: .rect(cornerRadius: 16))
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityAddTraits(secili ? .isSelected : [])
                                }
                            }
                        }
                        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
                    }

                    if let h = e.hata {
                        Label(h, systemImage: "exclamationmark.triangle.fill").font(.system(size: 13, weight: .semibold)).foregroundStyle(.orange)
                    }

                    ForEach(Muezzin.tumu) { m in
                        let seciliId = ayri ? a.vaktinMuezzini(hedefVakit ?? 0) : a.muezzin
                        satir(m, secili: m.id == seciliId)
                    }
                    Text("Kayıtlar: Athan-MP3 derlemesi (GitHub). Ses dosyaları uygulamaya gömülmez.")
                        .font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary).padding(.top, 4)
                }
                .padding(16)
            }
            .sahne(.ayarlar)
            .navigationTitle("Ezan sesi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Bitti") { kapat() } } }
            .onAppear { if ayri, hedefVakit == nil { hedefVakit = 0 } }
            .onDisappear {
                e.durdur()
                Task { await Bildirim.vakitleriKur(vakit, depo.ayarlar) }
            }
        }
    }

    private func satir(_ m: Muezzin, secili: Bool) -> some View {
        let hazir = e.hazirMi(m)
        let iniyor = e.inenler.contains(m.id)
        return HStack(spacing: 12) {
            Button { e.onizle(m) } label: {
                ZStack {
                    Circle().fill(palet.vurgu.opacity(0.16))
                    if iniyor { ProgressView().controlSize(.small) } else {
                        Image(systemName: e.calan == m.id ? "stop.fill" : "play.fill").font(.system(size: 15, weight: .bold)).foregroundStyle(palet.vurgu)
                    }
                }
                .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(e.calan == m.id ? "Durdur" : "\(m.ad) dinle")
            Button { sec(m) } label: {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(m.ad).font(.kalin(15)).lineLimit(1)
                        HStack(spacing: 6) {
                            if !m.not.isEmpty { Text(m.not) }
                            if hazir { Label("İndi", systemImage: "checkmark.circle.fill").labelStyle(.titleAndIcon).foregroundStyle(Color(hex: "#34C759")) }
                        }
                        .font(.system(size: 11.5, weight: .semibold)).foregroundStyle(.secondary).lineLimit(1)
                    }
                    Spacer(minLength: 4)
                    Image(systemName: secili ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 21)).foregroundStyle(secili ? palet.vurgu : .secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(secili ? .isSelected : [])
        }
        .padding(10)
        .camYuzey(palet.cam(secili ? palet.vurgu.opacity(0.18) : nil, etkilesimli: true), in: .rect(cornerRadius: 20))
    }

    private func sec(_ m: Muezzin) {
        Dokunsal.hafif(0.6)
        depo.degistir { k in
            if k.ayarlar.vakitMuezzin.count == 6 {
                k.ayarlar.vakitMuezzin[hedefVakit ?? 0] = m.id
            } else {
                k.ayarlar.muezzin = m.id
            }
            k.ayarlar.ezan = .muezzin
        }
        Task { await e.indir(m) }
    }
}
