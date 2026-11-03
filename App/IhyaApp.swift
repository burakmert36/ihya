import AVFoundation
import BackgroundTasks
import SwiftUI

@main
struct IhyaApp: App {
    @State private var depo: Depo
    @State private var vakit: VakitServisi
    @State private var ses: SesMotoru
    @State private var odak: OdakMotoru
    @State private var yon = Yonlendirici()

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        let d = Depo.yukle()
        let s = SesMotoru()
        let o = OdakMotoru(depo: d)
        o.bagla(s)
        let v = VakitServisi()
        v.ayarla(d.ayarlar)
        _depo = State(initialValue: d)
        _ses = State(initialValue: s)
        _odak = State(initialValue: o)
        _vakit = State(initialValue: v)
        DispatchQueue.global(qos: .userInitiated).async { _ = BitkiMotoru.ortak }
    }

    var body: some Scene {
        WindowGroup {
            KokGorunum()
                .environment(depo)
                .environment(vakit)
                .environment(ses)
                .environment(odak)
                .environment(yon)
                .preferredColorScheme(depo.ayarlar.tema.renkSemasi)
        }
        .backgroundTask(.appRefresh(ArkaPlan.kimlik)) {
            await ArkaPlan.calis()
        }
    }
}

/// Arka planda vakit takvimini yeniler ve bildirimleri yeniden kurar.
@MainActor
enum ArkaPlan {
    static let kimlik = "com.burakmert36.ihya.vakit"

    static func calis() async {
        let d = Depo.yukle()
        let v = VakitServisi()
        v.ayarla(d.ayarlar)
        await v.gerekirseYenile()
        await Bildirim.vakitleriKur(v, d.ayarlar)
        planla()
    }

    static func planla() {
        let istek = BGAppRefreshTaskRequest(identifier: kimlik)
        istek.earliestBeginDate = Date(timeIntervalSinceNow: 8 * 3600)
        try? BGTaskScheduler.shared.submit(istek)
    }
}

enum Sekme: Hashable { case bugun, odak, bahce, zikir, kitaplik }

enum Rota: Hashable {
    case vakitler, ayarlar, konular, kible, hadisler, sozler, dualar, duaDefteri, esma, diniGunler, kitaplar, favoriler
    case kitap(UUID)
    case istatistik, koleksiyon, sesler, zikirIstatistik
}

@MainActor
@Observable
final class Yonlendirici {
    var sekme: Sekme = .bugun
    var bugunYol: [Rota] = []
    var odakYol: [Rota] = []
    var bahceYol: [Rota] = []
    var zikirYol: [Rota] = []
    var kitaplikYol: [Rota] = []

    func sesleriAc() {
        sekme = .odak
        if odakYol.last != .sesler { odakYol.append(.sesler) }
    }

    /// CI ekran görüntüleri için doğrudan ekran açar.
    func ekranAc(_ ad: String, depo: Depo, odak: OdakMotoru) {
        switch ad {
        case "odak": sekme = .odak
        case "odak-calisiyor": sekme = .odak; odak.ornekBaslat()
        case "odak-bitti": sekme = .odak; odak.ornekBitir()
        case "bahce": sekme = .bahce
        case "istatistik": sekme = .bahce; bahceYol = [.istatistik]
        case "koleksiyon": sekme = .bahce; bahceYol = [.koleksiyon]
        case "sesler": sekme = .odak; odakYol = [.sesler]
        case "kitaplik": sekme = .kitaplik
        case "hadis": sekme = .kitaplik; kitaplikYol = [.hadisler]
        case "hadis-koyu": depo.degistir { $0.ayarlar.okumaKoyu = true }; sekme = .kitaplik; kitaplikYol = [.hadisler]
        case "dualar": sekme = .kitaplik; kitaplikYol = [.dualar]
        case "dua-defteri": sekme = .kitaplik; kitaplikYol = [.dualar, .duaDefteri]
        case "esma": sekme = .kitaplik; kitaplikYol = [.esma]
        case "kible": sekme = .kitaplik; kitaplikYol = [.kible]
        case "dinigunler": sekme = .kitaplik; kitaplikYol = [.diniGunler]
        case "kitaplar": sekme = .kitaplik; kitaplikYol = [.kitaplar]
        case "okuma", "favoriler": sekme = .kitaplik; kitaplikYol = [.favoriler]
        case "zikir": sekme = .zikir
        case "zikir-istatistik": sekme = .zikir; zikirYol = [.zikirIstatistik]
        case "vakitler": bugunYol = [.vakitler]
        case "ayarlar": bugunYol = [.ayarlar]
        default: sekme = .bugun
        }
    }
}

struct KokGorunum: View {
    @Environment(Depo.self) private var depo
    @Environment(VakitServisi.self) private var vakit
    @Environment(SesMotoru.self) private var ses
    @Environment(OdakMotoru.self) private var odak
    @Environment(Yonlendirici.self) private var yon
    @Environment(\.scenePhase) private var faz

    var body: some View {
        @Bindable var yon = yon
        TabView(selection: $yon.sekme) {
            Tab("Bugün", systemImage: "sun.max", value: Sekme.bugun) {
                NavigationStack(path: $yon.bugunYol) { BugunEkrani().rotalar() }
            }
            Tab("Odak", systemImage: "leaf", value: Sekme.odak) {
                NavigationStack(path: $yon.odakYol) { OdakEkrani().rotalar() }
            }
            Tab("Bahçe", systemImage: "tree", value: Sekme.bahce) {
                NavigationStack(path: $yon.bahceYol) { BahceEkrani().rotalar() }
            }
            Tab("Zikir", systemImage: "circle.dotted", value: Sekme.zikir) {
                NavigationStack(path: $yon.zikirYol) { ZikirEkrani().rotalar() }
            }
            Tab("Kitaplık", systemImage: "books.vertical", value: Sekme.kitaplik) {
                NavigationStack(path: $yon.kitaplikYol) { KitaplikEkrani().rotalar() }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .modifier(SesSeridiAksesuari(acik: !ses.katman.isEmpty))
        .task { await baslangic() }
        .onChange(of: faz) { _, yeni in
            switch yeni {
            case .background:
                odak.arkaPlanaGecti()
                depo.hemenKaydet()
                ArkaPlan.planla()
            case .active:
                odak.onPlanaGeldi()
                Task { await vakit.gerekirseYenile() }
            default: break
            }
        }
        .onChange(of: depo.ayarlar) { _, yeni in
            vakit.ayarla(yeni)
            Task { await Bildirim.vakitleriKur(vakit, yeni) }
        }
        .onChange(of: ses.katman) { _, yeni in
            if !yeni.isEmpty { depo.degistir { $0.sonKatman = yeni } }
        }
    }

    private func baslangic() async {
        if EkranGoruntusu.etkin {
            yon.ekranAc(EkranGoruntusu.ekran, depo: depo, odak: odak)
            return
        }
        await Bildirim.izinIste()
        await vakit.gerekirseYenile()
        await Bildirim.vakitleriKur(vakit, depo.ayarlar)
        ArkaPlan.planla()
    }
}

extension View {
    func rotalar() -> some View {
        navigationDestination(for: Rota.self) { RotaGorunumu(rota: $0) }
    }
}

struct RotaGorunumu: View {
    let rota: Rota
    var body: some View {
        switch rota {
        case .vakitler: VakitlerEkrani()
        case .ayarlar: AyarlarEkrani()
        case .konular: KonularEkrani()
        case .kible: KibleEkrani()
        case .hadisler: HadislerEkrani()
        case .sozler: SozlerEkrani()
        case .dualar: DualarEkrani()
        case .duaDefteri: DuaDefteriEkrani()
        case .esma: EsmaEkrani()
        case .diniGunler: DiniGunlerEkrani()
        case .kitaplar: KitaplarEkrani()
        case .kitap(let id): OkumaEkrani(kitapID: id)
        case .favoriler: FavorilerEkrani()
        case .istatistik: IstatistikEkrani()
        case .koleksiyon: KoleksiyonEkrani()
        case .sesler: SeslerEkrani()
        case .zikirIstatistik: ZikirIstatistikEkrani()
        }
    }
}

/// Alt sekme çubuğunun üstündeki ince ses şeridi; ses seçili değilse gizlenir (iOS 26.1+).
struct SesSeridiAksesuari: ViewModifier {
    let acik: Bool
    func body(content: Content) -> some View {
        if #available(iOS 26.1, *) {
            content.tabViewBottomAccessory(isEnabled: acik) { SesSeridi() }
        } else {
            content.tabViewBottomAccessory { SesSeridi() }
        }
    }
}

struct SesSeridi: View {
    @Environment(SesMotoru.self) private var ses
    @Environment(Yonlendirici.self) private var yon
    @Environment(\.tabViewBottomAccessoryPlacement) private var yer
    @State private var duzeyAcik = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "waveform")
                .symbolEffect(.variableColor.iterative, isActive: ses.caliyor)
                .foregroundStyle(ses.caliyor ? Color.ihya : Color.secondary)
            Text(ses.katman.isEmpty ? "Odak sesleri" : ses.seciliAdlar)
                .font(.subheadline)
                .lineLimit(1)
            Spacer(minLength: 4)
            if yer != .inline {
                Button { duzeyAcik.toggle() } label: { Image(systemName: "speaker.wave.2") }
                    .accessibilityLabel("Ses düzeyi")
                    .popover(isPresented: $duzeyAcik) {
                        DuzeyAyari().presentationCompactAdaptation(.popover)
                    }
            }
            Button { ses.degistirOynat() } label: {
                Image(systemName: ses.caliyor ? "pause.fill" : "play.fill").contentTransition(.symbolEffect(.replace))
            }
            .accessibilityLabel(ses.caliyor ? "Duraklat" : "Çal")
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture { yon.sesleriAc() }
    }
}

private struct DuzeyAyari: View {
    @Environment(SesMotoru.self) private var ses
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "speaker.fill").foregroundStyle(.secondary)
            Slider(value: Binding(get: { ses.anaDuzey }, set: { ses.ana($0) }), in: 0...1)
                .frame(width: 180)
            Image(systemName: "speaker.wave.3.fill").foregroundStyle(.secondary)
        }
        .padding(16)
    }
}
