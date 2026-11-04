import AVFoundation
import BackgroundTasks
import SwiftUI
import UserNotifications

@main
struct IhyaApp: App {
    @State private var depo: Depo
    @State private var vakit: VakitServisi
    @State private var ses: SesMotoru
    @State private var odak: OdakMotoru
    @State private var yon = Yonlendirici()

    init() {
        // Sessiz kipte de duyulsun; başka uygulamaların sesini kesmesin.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        UNUserNotificationCenter.current().delegate = BildirimTemsilcisi.ortak
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
        }
        .backgroundTask(.appRefresh(ArkaPlan.kimlik)) {
            await ArkaPlan.calis()
        }
    }
}

/// Uygulama açıkken gelen bildirimler de görünsün ve sesli çalsın (odak bildirimleri hariç; onları ekran zaten gösteriyor).
final class BildirimTemsilcisi: NSObject, UNUserNotificationCenterDelegate {
    static let ortak = BildirimTemsilcisi()

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let id = notification.request.identifier
        // Uygulama açıkken vakit girerse ezanın tamamı okunur; bildirim sessiz gelir.
        if id.hasPrefix("vakit-"), let i = id.split(separator: "-").last.flatMap({ Int($0) }), let m = EzanCalar.tamOkunacak(vakit: i) {
            DispatchQueue.main.async { MainActor.assumeIsolated { EzanCalar.ortak.vaktiOku(m) } }
            completionHandler([.banner, .list])
            return
        }
        completionHandler(id.hasPrefix("odak-") ? [] : [.banner, .list, .sound])
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
        await Bildirim.gunlukleriKur(d, v)
        Yedek.gunlukYedek(d, isaretle: false)
        planla()
    }

    static func planla() {
        let istek = BGAppRefreshTaskRequest(identifier: kimlik)
        istek.earliestBeginDate = Date(timeIntervalSinceNow: 8 * 3600)
        try? BGTaskScheduler.shared.submit(istek)
    }
}

/// Alt çubuktaki dört sekme; Odak ayrı yuvarlak düğmeyle tam ekran açılır.
enum Sekme: Hashable, CaseIterable {
    case bugun, kuran, takip, kitaplik

    var ad: String {
        switch self {
        case .bugun: "Bugün"
        case .kuran: "Kur'an"
        case .takip: "Takip"
        case .kitaplik: "Kitaplık"
        }
    }

    var simge: String {
        switch self {
        case .bugun: "sun.max"
        case .kuran: "book"
        case .takip: "checkmark.circle"
        case .kitaplik: "books.vertical"
        }
    }

    var sahne: Sahne {
        switch self {
        case .bugun: .bugun
        case .kuran: .kuran
        case .takip: .bahce
        case .kitaplik: .kitaplik
        }
    }
}

/// Takip sekmesinin bölümleri.
enum TakipBolumu: String, CaseIterable, Hashable {
    case bahce = "Bahçe", namaz = "Namaz", zikir = "Zikir"
    var sahne: Sahne {
        switch self {
        case .bahce: .bahce
        case .namaz: .vakit
        case .zikir: .zikir
        }
    }
}

enum Rota: Hashable {
    case vakitler, ayarlar, konular, ilce, kible, gununHadisi, hadisler, sozler, dualar, duaDefteri, esma, diniGunler, kitaplar, favoriler
    case kitap(UUID)
    case istatistik, koleksiyon, sesler, zikir, zikirIstatistik
    /// Kur'an okuyucu: sûre, âyet.
    case sure(Int, Int)

    var sahne: Sahne {
        switch self {
        case .vakitler: .vakit
        case .ayarlar, .konular, .ilce: .ayarlar
        case .gununHadisi, .hadisler, .sozler, .favoriler: .hadis
        case .kible, .dualar, .duaDefteri, .esma, .diniGunler, .kitaplar: .kitaplik
        case .kitap: .okuma
        case .istatistik, .koleksiyon: .bahce
        case .sesler: .sesler
        case .zikir, .zikirIstatistik: .zikir
        case .sure: .kuran
        }
    }
}

@MainActor
@Observable
final class Yonlendirici {
    var sekme: Sekme = .bugun
    var odakAcik = false
    var takipBolum: TakipBolumu = .bahce
    /// Esmâ ekranı açılınca doğrudan gösterilecek isim (ekran görüntüsü için).
    var esmaAc: Int?
    /// Kur'an aramasının örnek sözcüğü (ekran görüntüsü için).
    var kuranAramaOrnegi: String?
    /// Seri sayfası ve okuma ayarları doğrudan açılsın (ekran görüntüsü için).
    var seriAc = false
    var okumaAyarAc = false
    var bugunYol: [Rota] = []
    var kuranYol: [Rota] = []
    var takipYol: [Rota] = []
    var kitaplikYol: [Rota] = []
    var odakYol: [Rota] = []

    var yol: [Rota] {
        get {
            switch sekme {
            case .bugun: bugunYol
            case .kuran: kuranYol
            case .takip: takipYol
            case .kitaplik: kitaplikYol
            }
        }
        set {
            switch sekme {
            case .bugun: bugunYol = newValue
            case .kuran: kuranYol = newValue
            case .takip: takipYol = newValue
            case .kitaplik: kitaplikYol = newValue
            }
        }
    }

    /// Şu an görünen ekranın sahnesi (durum çubuğu ve alt çubuk rengi için).
    var aktifSahne: Sahne {
        if odakAcik { return odakYol.last?.sahne ?? .odak }
        return yol.last?.sahne ?? (sekme == .takip ? takipBolum.sahne : sekme.sahne)
    }

    /// Alt çubuk yalnız kök ekranlarda görünür (alt ekranlar kendi düğmelerini alta koyar).
    var okumada: Bool { !yol.isEmpty }

    /// Odak kurulumunda seçili gelecek konu (ad) ve okunacak kitap.
    var odakKonu: String?
    var odakKitap: UUID?

    func odakAc(konu: String? = nil, kitap: UUID? = nil) {
        odakKonu = konu
        if let kitap { odakKitap = kitap }
        odakYol = []
        odakAcik = true
    }

    /// Ses ekranını o an açık olan yığına ekler.
    func ac(_ r: Rota) {
        if odakAcik {
            if odakYol.last != r { odakYol.append(r) }
        } else if yol.last != r {
            yol.append(r)
        }
    }

    func sesleriAc() { ac(.sesler) }

    /// Sekmeye geçer; aynı sekmeye yeniden dokunulursa köke döner.
    func sec(_ s: Sekme) {
        if sekme == s { yol = [] } else { sekme = s }
    }

    /// CI ekran görüntüleri için doğrudan ekran açar.
    func ekranAc(_ ad: String, depo: Depo, odak: OdakMotoru) {
        switch ad {
        case "odak": odakAcik = true
        case "odak-calisiyor": odak.ornekBaslat(); odakAcik = true
        case "odak-bitti": odak.ornekBitir(); odakAcik = true
        case "bahce": sekme = .takip; takipBolum = .bahce
        case "istatistik": sekme = .takip; takipYol = [.istatistik]
        case "koleksiyon": sekme = .takip; takipYol = [.koleksiyon]
        case "takip-namaz": sekme = .takip; takipBolum = .namaz
        case "takip-zikir": sekme = .takip; takipBolum = .zikir
        case "kuran": sekme = .kuran
        case "kuran-oku": sekme = .kuran; kuranYol = [.sure(36, 1)]
        case "kuran-dinle": sekme = .kuran; kuranYol = [.sure(1, 1)]; TilavetMotoru.ortak.cal(sure: 1, ayet: 2)
        case "kuran-ara": sekme = .kuran; kuranAramaOrnegi = "sabır"
        case "sesler": sekme = .bugun; bugunYol = [.sesler]
        case "kitaplik": sekme = .kitaplik
        case "hadis": sekme = .kitaplik; kitaplikYol = [.gununHadisi]
        case "hadisler": sekme = .kitaplik; kitaplikYol = [.hadisler]
        case "hadis-koyu": depo.degistir { $0.ayarlar.okumaTemasi = .sepya }; sekme = .kitaplik; kitaplikYol = [.hadisler]
        case "dualar": sekme = .kitaplik; kitaplikYol = [.dualar]
        case "dua-defteri": sekme = .kitaplik; kitaplikYol = [.dualar, .duaDefteri]
        case "esma": sekme = .kitaplik; kitaplikYol = [.esma]
        case let t where t.hasPrefix("esma-"): sekme = .kitaplik; kitaplikYol = [.esma]; esmaAc = Int(t.dropFirst(5))
        case "kible": sekme = .kitaplik; kitaplikYol = [.kible]
        case "dinigunler": sekme = .kitaplik; kitaplikYol = [.diniGunler]
        case "kitaplar": sekme = .kitaplik; kitaplikYol = [.kitaplar]
        case "okuma", "favoriler": sekme = .kitaplik; kitaplikYol = [.favoriler]
        case "zikir": sekme = .kitaplik; kitaplikYol = [.zikir]
        case "zikir-istatistik": sekme = .kitaplik; kitaplikYol = [.zikir, .zikirIstatistik]
        case "vakitler": bugunYol = [.vakitler]
        case "ayarlar": bugunYol = [.ayarlar]
        case "ilce": bugunYol = [.ayarlar, .ilce]
        case "seri": sekme = .bugun; seriAc = true
        case "okuma-ayar": sekme = .kitaplik; kitaplikYol = [.hadisler]; okumaAyarAc = true
        case let t where t.hasPrefix("tema-"):
            // "tema-gece" ya da "tema-gece-kitaplik": temayı seçer, varsa ekranı açar.
            let p = t.split(separator: "-").map(String.init)
            if p.count > 1, let tema = Tema(rawValue: p[1]) { depo.degistir { $0.ayarlar.tema = tema } }
            if p.count > 2 { ekranAc(p[2...].joined(separator: "-"), depo: depo, odak: odak) }
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
    @State private var ziyaret: Set<Sekme> = [.bugun]

    var body: some View {
        @Bindable var yon = yon
        let p = depo.ayarlar.tema.palet(yon.aktifSahne)
        ZStack {
            ForEach(Sekme.allCases, id: \.self) { s in
                if ziyaret.contains(s) || yon.sekme == s {
                    sekmeYigini(s)
                        .opacity(yon.sekme == s ? 1 : 0)
                        .allowsHitTesting(yon.sekme == s)
                        .accessibilityHidden(yon.sekme != s)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !yon.okumada { AltCubuk().environment(\.palet, p) }
        }
        .preferredColorScheme(p.renkSemasi)
        .fullScreenCover(isPresented: $yon.odakAcik, onDismiss: { if odak.devam == nil { odak.kapat() } }) {
            OdakKapsayici()
                .environment(depo)
                .environment(vakit)
                .environment(ses)
                .environment(odak)
                .environment(yon)
        }
        .onChange(of: yon.sekme) { _, yeni in ziyaret.insert(yeni) }
        .task { await baslangic() }
        .onChange(of: faz) { _, yeni in
            switch yeni {
            case .background:
                odak.arkaPlanaGecti()
                sesSeciminiSakla()
                WidgetKoprusu.guncelle(depo, vakit)
                Yedek.gunlukYedek(depo)
                depo.hemenKaydet()
                ArkaPlan.planla()
            case .active:
                odak.onPlanaGeldi()
                if odak.hal != .bos { yon.odakAcik = true }
                niyetiIsle(NiyetKoprusu.al())
                Task { await vakit.gerekirseYenile() }
            default: break
            }
        }
        .onChange(of: depo.ayarlar) { _, yeni in
            vakit.ayarla(yeni)
            Task {
                await Bildirim.vakitleriKur(vakit, yeni)
                await Bildirim.gunlukleriKur(depo, vakit)
            }
        }
        .onChange(of: depo.kayit.oturumlar.count) { _, _ in
            Task { await Bildirim.gunlukleriKur(depo, vakit) }
            WidgetKoprusu.guncelle(depo, vakit)
        }
        .onChange(of: depo.kayit.namaz) { _, _ in WidgetKoprusu.guncelle(depo, vakit) }
        .onReceive(NotificationCenter.default.publisher(for: .ihyaNiyet)) { n in
            _ = NiyetKoprusu.al()
            niyetiIsle(n.object as? String)
        }
        .onOpenURL { url in niyetiIsle(url.host()) }
        .onChange(of: Set(ses.katman.keys)) { _, _ in sesSeciminiSakla() }
        .onChange(of: depo.ayarlar.kuranDinlerkenKis, initial: true) { _, yeni in ses.kuranKis = yeni }
        .onChange(of: depo.ayarlar, initial: true) { _, a in
            TilavetMotoru.ortak.ayarla(a)
            ses.kilitEkrani = a.sesKilitEkrani
            EzanCalar.ayarlar = a
        }
        .task { await ezandaSustur() }
    }

    /// Widget, Canlı Etkinlik, Denetim Merkezi ve kısayollardan gelen istek (ihya://odak gibi).
    private func niyetiIsle(_ ad: String?) {
        guard let ad else { return }
        switch ad {
        case "odak": if !yon.odakAcik { yon.odakAc() }
        case "sesler": yon.odakAcik = false; yon.sekme = .bugun; yon.bugunYol = [.sesler]
        case "vakitler": yon.odakAcik = false; yon.sekme = .bugun; yon.bugunYol = [.vakitler]
        case "seri": yon.odakAcik = false; yon.sekme = .bugun; yon.bugunYol = []; yon.seriAc = true
        case "dinle":
            let son = depo.kayit.kuranSon
            let s = son.first ?? 1, a = son.count > 1 ? son[1] : 1
            yon.odakAcik = false
            yon.sekme = .kuran
            yon.kuranYol = [.sure(s, a)]
            if !TilavetMotoru.ortak.etkin { TilavetMotoru.ortak.cal(sure: s, ayet: a) }
        default: break
        }
    }

    /// "Ezan vaktinde sustur": vakit girince çalan odak seslerini yavaşça durdurur (güneş doğuşu hariç).
    private func ezandaSustur() async {
        while !Task.isCancelled {
            let d = vakit.durum()
            let bekle = max(1, d.sonrakiZaman.timeIntervalSinceNow)
            try? await Task.sleep(nanoseconds: UInt64(min(bekle, 6 * 3600) * 1_000_000_000))
            if Task.isCancelled { return }
            if bekle <= 6 * 3600, d.sonraki != 1, depo.ayarlar.ezandaSustur {
                if ses.caliyor { ses.duraklat() }
                if TilavetMotoru.ortak.caliyor { TilavetMotoru.ortak.duraklat() }
            }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }
    }

    @ViewBuilder
    private func sekmeYigini(_ s: Sekme) -> some View {
        @Bindable var yon = yon
        switch s {
        case .bugun: NavigationStack(path: $yon.bugunYol) { BugunEkrani().sahne(.bugun).rotalar() }
        case .kuran: NavigationStack(path: $yon.kuranYol) { KuranEkrani().sahne(.kuran).rotalar() }
        case .takip: NavigationStack(path: $yon.takipYol) { TakipEkrani().rotalar() }
        case .kitaplik: NavigationStack(path: $yon.kitaplikYol) { KitaplikEkrani().sahne(.kitaplik).rotalar() }
        }
    }

    /// Ses seçimi yalnız seçim değişince ve arka plana geçerken saklanır (sürgü sürüklerken her karede değil).
    private func sesSeciminiSakla() {
        guard !ses.katman.isEmpty, ses.katman != depo.kayit.sonKatman || ses.mesafe != depo.kayit.sonMesafe else { return }
        depo.degistir { $0.sonKatman = ses.katman; $0.sonMesafe = ses.mesafe }
    }

    private func baslangic() async {
        SimdiCalan.kur(ses: ses)
        TilavetMotoru.ortak.degisti = { [ses] c in ses.tilavetCaliyor(c) }
        if EkranGoruntusu.etkin {
            yon.ekranAc(EkranGoruntusu.ekran, depo: depo, odak: odak)
            ziyaret.insert(yon.sekme)
            if EkranGoruntusu.sesSinamasi { await SesMotoru.sina() }
            return
        }
        if odak.hal != .bos { yon.odakAcik = true }
        await Bildirim.izinIste()
        await vakit.gerekirseYenile()
        await Bildirim.vakitleriKur(vakit, depo.ayarlar)
        await Bildirim.gunlukleriKur(depo, vakit)
        Yedek.gunlukYedek(depo)
        WidgetKoprusu.guncelle(depo, vakit)
        if odak.devam == nil { CanliEtkinlik.bitir() } else if let d = odak.devam { CanliEtkinlik.baslat(d, konu: depo.konu(d.konu)?.ad ?? "") }
        niyetiIsle(NiyetKoprusu.al())
        ArkaPlan.planla()
    }
}

/// Odak akışı: kendi gezinme yığınıyla tam ekran.
struct OdakKapsayici: View {
    @Environment(Depo.self) private var depo
    @Environment(Yonlendirici.self) private var yon

    var body: some View {
        @Bindable var yon = yon
        NavigationStack(path: $yon.odakYol) {
            OdakEkrani().rotalar()
        }
        .preferredColorScheme(depo.ayarlar.tema.palet(yon.odakYol.last?.sahne ?? .odak).renkSemasi)
    }
}

extension View {
    func rotalar() -> some View {
        navigationDestination(for: Rota.self) { RotaGorunumu(rota: $0) }
    }
}

/// Her rota kendi sahnesinde açılır (sahne dışarıdan verilir ki ekranın kendi palet okuması doğru olsun).
struct RotaGorunumu: View {
    let rota: Rota
    var body: some View {
        icerik.sahne(rota.sahne)
    }

    @ViewBuilder
    private var icerik: some View {
        switch rota {
        case .vakitler: VakitlerEkrani()
        case .ayarlar: AyarlarEkrani()
        case .konular: KonularEkrani()
        case .ilce: IlceSecici()
        case .kible: KibleEkrani()
        case .gununHadisi: HadislerEkrani(bolum: .gunun)
        case .hadisler: HadislerEkrani(bolum: .hadisler)
        case .sozler: HadislerEkrani(bolum: .hikmet)
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
        case .zikir: ZikirEkrani()
        case .zikirIstatistik: ZikirIstatistikEkrani()
        case .sure(let n, let a): KuranOkuyucu(sure: n, ayet: a)
        }
    }
}

// MARK: Alt çubuk

/// Tasarımdaki alt çubuk: dört sekmeli cam kapsül ve yanında yeşil yuvarlak Odak düğmesi.
struct AltCubuk: View {
    @Environment(Yonlendirici.self) private var yon
    @Environment(\.palet) private var palet
    @Namespace private var alan

    var body: some View {
        GlassEffectContainer(spacing: 14) {
            HStack(spacing: 12) {
                HStack(spacing: 0) {
                    ForEach(Sekme.allCases, id: \.self) { s in sekmeDugmesi(s) }
                }
                .padding(6)
                .camYuzey(palet.cam(etkilesimli: true), in: .capsule)

                Button { yon.odakAc(); Dokunsal.orta() } label: {
                    FilizSimgesi()
                        .fill(palet.dolguMetin)
                        .frame(width: 30, height: 30)
                        .frame(width: 64, height: 64)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .camYuzey(.regular.tint(palet.dolgu.opacity(0.9)).interactive(), in: .circle)
                .accessibilityLabel("Odaklan, yeni oturum")
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 2)
    }

    private func sekmeDugmesi(_ s: Sekme) -> some View {
        let on = yon.sekme == s
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { yon.sec(s) }
            Dokunsal.hafif(0.5)
        } label: {
            VStack(spacing: 2) {
                Image(systemName: s.simge)
                .font(.system(size: 19, weight: .semibold))
                .frame(height: 24)
                Text(s.ad).font(.system(size: 10.5, weight: .bold))
            }
            .foregroundStyle(on ? (palet.koyu ? Color.white : palet.vurgu) : Color.primary.opacity(0.78))
            .frame(maxWidth: .infinity, minHeight: 52)
            .background {
                if on {
                    Capsule().fill(Color.white.opacity(palet.koyu ? 0.2 : 0.58))
                        .matchedGeometryEffect(id: "sekme", in: alan)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(s.ad)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
