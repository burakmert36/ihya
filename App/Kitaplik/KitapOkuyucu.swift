import AVFoundation
import PDFKit
import SwiftUI

/// PDF görünümüne dışarıdan erişim: sayfaya git, yakınlaştır, vurgula.
@MainActor
@Observable
final class PDFDenetci {
    @ObservationIgnored weak var gorunum: OkumaPDF?
    let belge: PDFDocument?
    var sayfa = 0
    /// 1: sayfa ekrana sığar
    var yakinlik: Double = 1
    @ObservationIgnored var uyguluyor = false

    init(url: URL) { belge = PDFDocument(url: url) }

    var toplam: Int { belge?.pageCount ?? 0 }

    func git(_ i: Int) {
        let h = max(0, min(i, toplam - 1))
        sayfa = h
        if let v = gorunum, let p = belge?.page(at: h) { v.go(to: p) }
    }

    /// Otomatik kaydırma hızı (nokta/sn); 0 kapalı. Yalnız aşağı kayan sayfa görünümünde çalışır.
    private(set) var kaydirmaHizi: Double = 0
    func kaydir(_ h: Double) { kaydirmaHizi = max(0, h); kaydirmayiKur() }
    @ObservationIgnored private var kaydirmaZamanlayici: Timer?

    private func kaydirmayiKur() {
        kaydirmaZamanlayici?.invalidate()
        kaydirmaZamanlayici = nil
        guard kaydirmaHizi > 0 else { return }
        kaydirmaZamanlayici = Timer.scheduledTimer(withTimeInterval: 1.0 / 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, let v = self.gorunum, let k = v.subviews.compactMap({ $0 as? UIScrollView }).first else { return }
                let enFazla = k.contentSize.height - k.bounds.height + k.adjustedContentInset.bottom
                guard k.contentOffset.y < enFazla else { self.kaydir(0); return }
                k.contentOffset.y = min(enFazla, k.contentOffset.y + self.kaydirmaHizi / 30)
            }
        }
    }

    func sonraki() { gorunum?.goToNextPage(nil) }
    func onceki() { gorunum?.goToPreviousPage(nil) }

    func yakinlastir(_ adim: Double) {
        yakinlik = max(1, min(4, ((yakinlik + adim) * 100).rounded() / 100))
        uygula()
    }

    func uygula() {
        guard let v = gorunum else { return }
        let sigan = v.scaleFactorForSizeToFit
        guard sigan > 0 else { return }
        uyguluyor = true
        v.minScaleFactor = sigan
        v.maxScaleFactor = sigan * 4
        if yakinlik <= 1.001 {
            v.autoScales = true
        } else {
            v.autoScales = false
            v.scaleFactor = sigan * yakinlik
        }
        uyguluyor = false
    }

    /// Aranan sözü sayfada sarıyla işaretler ve oraya gider.
    func vurgula(_ q: String, sayfa i: Int) {
        guard let v = gorunum, let p = belge?.page(at: i), let ham = p.string else { git(i); return }
        let s = ham as NSString
        var secimler: [PDFSelection] = []
        var aralik = NSRange(location: 0, length: s.length)
        while aralik.length > 0 {
            let f = s.range(of: q, options: [.caseInsensitive, .diacriticInsensitive], range: aralik, locale: Locale(identifier: "tr_TR"))
            if f.location == NSNotFound { break }
            if let sec = p.selection(for: f) {
                sec.color = UIColor.systemYellow.withAlphaComponent(0.55)
                secimler.append(sec)
            }
            aralik = NSRange(location: f.location + f.length, length: s.length - f.location - f.length)
        }
        v.highlightedSelections = secimler
        sayfa = i
        if let ilk = secimler.first { v.go(to: ilk) } else { git(i) }
    }
}

/// Boyutu değişince (ekran döndü) yakınlık yeniden uygulansın diye.
final class OkumaPDF: PDFView {
    var boyutDegisti: (() -> Void)?
    private var sonBoyut: CGSize = .zero
    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != sonBoyut {
            sonBoyut = bounds.size
            boyutDegisti?()
        }
    }
}

enum Dokunus { case orta, sol, sag }

struct PDFGorunumu: UIViewRepresentable {
    let denetci: PDFDenetci
    let baslangic: Int
    let yatay: Bool
    let sagdanSola: Bool
    let zemin: UIColor
    let sayfaDegisti: (Int) -> Void
    let yakinlikDegisti: (Double) -> Void
    let dokunuldu: (Dokunus) -> Void

    func makeCoordinator() -> Koordinator { Koordinator(self) }

    func makeUIView(context: Context) -> OkumaPDF {
        let v = OkumaPDF()
        v.backgroundColor = zemin
        v.pageShadowsEnabled = !yatay
        v.displaysRTL = sagdanSola
        if yatay {
            v.displayMode = .singlePage
            v.displayDirection = .horizontal
            v.usePageViewController(true, withViewOptions: [UIPageViewController.OptionsKey.interPageSpacing: 16])
        } else {
            v.displayMode = .singlePageContinuous
            v.displayDirection = .vertical
        }
        v.autoScales = true
        v.document = denetci.belge
        denetci.gorunum = v
        let k = context.coordinator
        NotificationCenter.default.addObserver(k, selector: #selector(Koordinator.sayfaDegisti(_:)), name: .PDFViewPageChanged, object: v)
        NotificationCenter.default.addObserver(k, selector: #selector(Koordinator.olcekDegisti(_:)), name: .PDFViewScaleChanged, object: v)

        let cift = UITapGestureRecognizer(target: k, action: #selector(Koordinator.ciftDokunus(_:)))
        cift.numberOfTapsRequired = 2
        cift.cancelsTouchesInView = false
        cift.delegate = k
        let tek = UITapGestureRecognizer(target: k, action: #selector(Koordinator.dokunus(_:)))
        tek.cancelsTouchesInView = false
        tek.delegate = k
        tek.require(toFail: cift)
        v.addGestureRecognizer(cift)
        v.addGestureRecognizer(tek)

        let dn = denetci
        v.boyutDegisti = { [weak dn] in
            DispatchQueue.main.async { MainActor.assumeIsolated { if let d = dn, d.yakinlik > 1 { d.uygula() } } }
        }
        let hedef = baslangic
        Task { @MainActor in
            if let p = denetci.belge?.page(at: hedef) { v.go(to: p) }
            denetci.sayfa = hedef
            denetci.uygula()
            k.hazir = true
        }
        return v
    }

    func updateUIView(_ v: OkumaPDF, context: Context) {
        context.coordinator.ust = self
        if v.backgroundColor != zemin { v.backgroundColor = zemin }
        if v.displaysRTL != sagdanSola { v.displaysRTL = sagdanSola }
    }

    static func dismantleUIView(_ v: OkumaPDF, coordinator: Koordinator) {
        NotificationCenter.default.removeObserver(coordinator)
        v.boyutDegisti = nil
    }

    final class Koordinator: NSObject, UIGestureRecognizerDelegate {
        var ust: PDFGorunumu
        var hazir = false
        init(_ u: PDFGorunumu) { ust = u }

        @objc func sayfaDegisti(_ n: Notification) {
            guard hazir, let v = n.object as? PDFView, let p = v.currentPage, let d = v.document else { return }
            let i = d.index(for: p)
            MainActor.assumeIsolated {
                ust.denetci.sayfa = i
                ust.sayfaDegisti(i)
            }
        }

        @objc func olcekDegisti(_ n: Notification) {
            guard hazir, let v = n.object as? PDFView else { return }
            MainActor.assumeIsolated {
                guard !ust.denetci.uyguluyor, v.scaleFactorForSizeToFit > 0 else { return }
                let y = max(1, min(4, Double(v.scaleFactor / v.scaleFactorForSizeToFit)))
                if abs(y - ust.denetci.yakinlik) > 0.02 {
                    ust.denetci.yakinlik = y
                    ust.yakinlikDegisti(y)
                }
            }
        }

        @objc func ciftDokunus(_ g: UITapGestureRecognizer) {}

        @objc func dokunus(_ g: UITapGestureRecognizer) {
            guard let v = g.view else { return }
            let x = g.location(in: v).x, w = v.bounds.width
            let yon: Dokunus = !ust.yatay ? .orta : (x < w * 0.22 ? .sol : (x > w * 0.78 ? .sag : .orta))
            MainActor.assumeIsolated { ust.dokunuldu(yon) }
        }

        func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith o: UIGestureRecognizer) -> Bool { true }
    }
}

extension OkumaTemasi {
    /// PDF zemini: koyu temalarda renkler ters çevrildiği için zeminin tersi verilir.
    var pdfZemin: UIColor {
        switch self {
        case .gece: UIColor(white: 0.915, alpha: 1)
        case .siyah: .white
        case .sepya: UIColor(white: 0.87, alpha: 1)
        default: UIColor(Color(hex: zemin))
        }
    }
}

private extension View {
    /// PDF sayfaları beyaz zeminlidir: gece/siyah temada renkler ters çevrilir (resimler doğal kalsın diye ton 180° döner),
    /// sepyada ters çevrilip sıcak tona boyanır.
    @ViewBuilder func pdfTemasi(_ t: OkumaTemasi) -> some View {
        switch t {
        case .gece: self.colorInvert().hueRotation(.degrees(180)).brightness(0.04)
        case .siyah: self.colorInvert().hueRotation(.degrees(180))
        case .sepya: self.colorInvert().hueRotation(.degrees(180)).colorMultiply(Color(hex: "#F0DDB8"))
        default: self
        }
    }
}

/// Kitap okuyucu: sayfa ya da yazı görünümü, yazı büyüt-küçült, yatay/dikey sayfa, ekran yönü, mavi ışık süzgeci,
/// içindekiler, yer imleri, arama, okuma süresi.
struct OkumaEkrani: View {
    let kitapID: UUID
    @Environment(Depo.self) private var depo
    @Environment(Yonlendirici.self) private var yon
    @Environment(OdakMotoru.self) private var odak
    @Environment(VakitServisi.self) private var vakit
    @Environment(\.palet) private var palet
    @Environment(\.scenePhase) private var faz
    @State private var denetci: PDFDenetci?
    @State private var gizli = false
    @State private var sayfaGostergesi: Double = 0
    @State private var surukleniyor = false
    @State private var acilis = Date()
    @State private var panel: Panel?
    @State private var okuyucu = SesliOkuyucu()

    enum Panel: String, Identifiable { case ayar, icindekiler, ara; var id: String { rawValue } }

    private var kitap: Kitap? { depo.kayit.kitaplar.first { $0.id == kitapID } }

    var body: some View {
        if let k = kitap {
            icerik(k)
        } else {
            ContentUnavailableView("Kitap bulunamadı", systemImage: "book")
        }
    }

    @ViewBuilder
    private func icerik(_ k: Kitap) -> some View {
        let a = depo.ayarlar
        let tema = depo.okumaTemasi(vakit)
        ZStack {
            Color(hex: tema.zemin).ignoresSafeArea()
            if let d = denetci {
                if a.kitapMetin {
                    MetinOkuyucu(denetci: d, tema: tema, punto: a.okumaPunto, satir: a.satirBoslugu(a.okumaPunto),
                                 duz: a.kitapYaziTipi == 1, kenar: [14, 22, 36][max(0, min(2, a.kitapKenar))]) { cubuklar() }
                } else {
                    PDFGorunumu(denetci: d, baslangic: k.sayfa, yatay: a.kitapYatay, sagdanSola: a.kitapSagdanSola, zemin: tema.pdfZemin,
                                sayfaDegisti: { sayfaKaydet($0) }, yakinlikDegisti: { y in kitapDegistir { $0.yakinlik = y } },
                                dokunuldu: dokunus)
                        .id("\(a.kitapYatay)-\(a.kitapSagdanSola)")
                        .pdfTemasi(tema)
                        .ignoresSafeArea(edges: .bottom)
                }
            } else {
                ProgressView()
            }
        }
        .sicakIsik()
        .overlay(alignment: .bottom) {
            if !gizli, let d = denetci { altPanel(k, d).transition(.move(edge: .bottom).combined(with: .opacity)) }
        }
        .overlay(alignment: .topTrailing) {
            if let d = denetci, d.kaydirmaHizi > 0 {
                HStack(spacing: 4) {
                    Button { d.kaydir(max(10, d.kaydirmaHizi - 10)) } label: { Image(systemName: "tortoise.fill").frame(width: 34, height: 34) }
                        .accessibilityLabel("Yavaşlat")
                    Button { d.kaydir(0) } label: { Image(systemName: "stop.fill").frame(width: 34, height: 34) }
                        .accessibilityLabel("Otomatik kaydırmayı durdur")
                    Button { d.kaydir(min(120, d.kaydirmaHizi + 10)) } label: { Image(systemName: "hare.fill").frame(width: 34, height: 34) }
                        .accessibilityLabel("Hızlandır")
                }
                .font(.system(size: 14, weight: .bold))
                .buttonStyle(.plain)
                .padding(4)
                .camYuzey(palet.cam(etkilesimli: true), in: .capsule)
                .padding(12)
            }
        }
        .statusBarHidden(gizli)
        .toolbar(gizli ? .hidden : .visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationTitle(k.ad)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { araclar(k) }
        .uyanikTut()
        .sheet(item: $panel) { p in
            Group {
                switch p {
                case .ayar: KitapAyarlari(denetci: denetci).presentationDetents([.medium, .large])
                case .icindekiler: if let d = denetci { KitapIcindekiler(denetci: d, kitapID: kitapID).presentationDetents([.large]) }
                case .ara: if let d = denetci { KitapAramasi(url: KitapDeposu.url(k), denetci: d).presentationDetents([.large]) }
                }
            }
            .sahne(.kitaplik)
        }
        .onAppear {
            if denetci == nil {
                let d = PDFDenetci(url: KitapDeposu.url(k))
                d.sayfa = k.sayfa
                d.yakinlik = k.yakinlik
                denetci = d
                if k.toplam != d.toplam, d.toplam > 0 { kitapDegistir { $0.toplam = d.toplam } }
            }
            acilis = .now
            ekranYonu(a.kitapEkran)
            if let p = yon.kitapPanel { panel = Panel(rawValue: p); yon.kitapPanel = nil }
        }
        .onDisappear {
            okuyucu.dur()
            denetci?.kaydir(0)
            sureyiYaz()
            YonKilidi.ayarla(.portrait)
        }
        .onChange(of: a.kitapEkran) { _, y in ekranYonu(y) }
        .onChange(of: faz) { _, f in
            if f != .active { sureyiYaz() } else { acilis = .now }
        }
        .onChange(of: denetci?.sayfa) { _, s in if !surukleniyor, let s { sayfaGostergesi = Double(s) } }
    }

    // MARK: Araç çubukları

    @ToolbarContentBuilder
    private func araclar(_ k: Kitap) -> some ToolbarContent {
        let s = denetci?.sayfa ?? k.sayfa
        let imli = k.yerImleri.contains(s)
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                kitapDegistir { kk in
                    if let i = kk.yerImleri.firstIndex(of: s) { kk.yerImleri.remove(at: i) } else { kk.yerImleri.append(s); kk.yerImleri.sort() }
                }
                Dokunsal.hafif(0.6)
            } label: { Image(systemName: imli ? "bookmark.fill" : "bookmark") }
            .accessibilityLabel(imli ? "Yer imini kaldır" : "Bu sayfaya yer imi koy")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                let yeni = depo.ayarlar.kitapEkran == 1 ? 0 : 1
                depo.degistir { $0.ayarlar.kitapEkran = yeni }
            } label: { Image(systemName: depo.ayarlar.kitapEkran == 1 ? "rectangle.portrait.rotate" : "rectangle.landscape.rotate") }
            .accessibilityLabel(depo.ayarlar.kitapEkran == 1 ? "Ekranı dik çevir" : "Ekranı yan çevir")
        }
        if odak.hal == .bos {
            ToolbarItem(placement: .topBarTrailing) {
                Button { yon.odakAc(konu: "Kitap", kitap: kitapID) } label: { Image(systemName: "leaf") }
                    .accessibilityLabel("Odakla oku: okuma süresi bahçene sayılsın")
            }
        }
    }

    private func altPanel(_ k: Kitap, _ d: PDFDenetci) -> some View {
        let toplam = max(d.toplam, 1)
        let metin = depo.ayarlar.kitapMetin
        return VStack(spacing: 8) {
            HStack {
                Text(surukleniyor ? "Sayfa \(Int(sayfaGostergesi) + 1)" : "\(d.sayfa + 1) / \(toplam)")
                    .font(.system(size: 13, weight: .bold)).monospacedDigit()
                Spacer()
                Text(kalanYazisi(k, d)).font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary).lineLimit(1)
            }
            if toplam > 1 {
                Slider(value: $sayfaGostergesi, in: 0...Double(toplam - 1), step: 1, onEditingChanged: { s in
                    surukleniyor = s
                    if !s { d.git(Int(sayfaGostergesi)) }
                })
                .environment(\.layoutDirection, depo.ayarlar.kitapSagdanSola && depo.ayarlar.kitapYatay ? .rightToLeft : .leftToRight)
                .accessibilityLabel("Sayfa")
                .accessibilityValue("\(Int(sayfaGostergesi) + 1) / \(toplam)")
            }
            HStack(spacing: 0) {
                dugme("list.bullet", "İçindekiler") { panel = .icindekiler }
                dugme("magnifyingglass", "Ara") { panel = .ara }
                dugme("textformat.size.smaller", "Yazıyı küçült") { kucult(metin, d) }
                dugme("textformat.size.larger", "Yazıyı büyüt") { buyut(metin, d) }
                dugme(depo.ayarlar.kitapYatay ? "arrow.left.arrow.right" : "arrow.up.arrow.down",
                      depo.ayarlar.kitapYatay ? "Sayfalar yana çevriliyor; aşağı kaydırmaya geç" : "Sayfalar aşağı kayıyor; yana çevirmeye geç") {
                    depo.degistir { $0.ayarlar.kitapYatay.toggle(); $0.ayarlar.kitapMetin = false }
                }
                dugme(okuyucu.okuyor ? "speaker.wave.2.fill" : "headphones", okuyucu.okuyor ? "Sesli okumayı durdur" : "Bu sayfadan sesli oku") {
                    okuyucu.okuyor ? okuyucu.dur() : okuyucu.basla(d, hiz: depo.ayarlar.kitapSesHizi)
                }
                dugme("textformat", "Okuma ayarları") { panel = .ayar }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .camYuzey(palet.cam(), in: .rect(cornerRadius: 26))
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }

    private func dugme(_ simge: String, _ ad: String, _ islem: @escaping () -> Void) -> some View {
        Button { islem(); Dokunsal.hafif(0.4) } label: {
            Image(systemName: simge).font(.system(size: 18, weight: .semibold)).frame(maxWidth: .infinity, minHeight: 40).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(ad)
    }

    private func kalanYazisi(_ k: Kitap, _ d: PDFDenetci) -> String {
        let kalan = max(0, d.toplam - d.sayfa - 1)
        if kalan == 0 { return "Son sayfa" }
        var p = "%\(Int(Double(d.sayfa + 1) / Double(max(d.toplam, 1)) * 100)) · \(kalan) sayfa kaldı"
        if k.okumaSn >= 600, k.sayfa >= 5 { p += " · ~" + OkumaSuresi.yazi(k.okumaSn / Double(k.sayfa + 1) * Double(kalan)) }
        return p
    }

    // MARK: İşler

    private func buyut(_ metin: Bool, _ d: PDFDenetci) {
        if metin { depo.degistir { $0.ayarlar.okumaPunto = min(34, $0.ayarlar.okumaPunto + 1) } } else {
            d.yakinlastir(0.15)
            kitapDegistir { $0.yakinlik = d.yakinlik }
        }
    }

    private func kucult(_ metin: Bool, _ d: PDFDenetci) {
        if metin { depo.degistir { $0.ayarlar.okumaPunto = max(13, $0.ayarlar.okumaPunto - 1) } } else {
            d.yakinlastir(-0.15)
            kitapDegistir { $0.yakinlik = d.yakinlik }
        }
    }

    private func dokunus(_ y: Dokunus) {
        let rtl = depo.ayarlar.kitapSagdanSola
        switch y {
        case .orta: cubuklar()
        case .sol: rtl ? denetci?.sonraki() : denetci?.onceki()
        case .sag: rtl ? denetci?.onceki() : denetci?.sonraki()
        }
    }

    private func cubuklar() {
        withAnimation(.easeInOut(duration: 0.22)) { gizli.toggle() }
    }

    private func sayfaKaydet(_ s: Int) {
        guard kitap?.sayfa != s else { return }
        kitapDegistir { k in
            k.sayfa = s
            k.son = .now
            if k.toplam > 0, s + 1 >= k.toplam { k.bitti = true }
        }
    }

    private func sureyiYaz() {
        let gecen = Date().timeIntervalSince(acilis)
        acilis = .now
        guard gecen > 5 else { return }
        kitapDegistir { $0.okumaSn += min(gecen, 2 * 3600); $0.son = .now }
    }

    private func kitapDegistir(_ islem: (inout Kitap) -> Void) {
        depo.degistir { kayit in
            if let i = kayit.kitaplar.firstIndex(where: { $0.id == kitapID }) { islem(&kayit.kitaplar[i]) }
        }
    }

    private func ekranYonu(_ y: Int) {
        YonKilidi.ayarla(y == 1 ? .landscape : (y == 2 ? .allButUpsideDown : .portrait))
    }
}

// MARK: Yazı görünümü

/// Sayfanın yazısı okuma temasında, istenen boyutta akar; büyütünce satırlar ekrana sığar.
private struct MetinOkuyucu: View {
    let denetci: PDFDenetci
    let tema: OkumaTemasi
    let punto: Double
    let satir: Double
    let duz: Bool
    let kenar: CGFloat
    let dokunuldu: () -> Void
    @State private var konum: Int?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 28) {
                ForEach(0..<denetci.toplam, id: \.self) { i in
                    MetinSayfasi(belge: denetci.belge, no: i, tema: tema, punto: punto, satir: satir, duz: duz).id(i)
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, kenar)
            .padding(.top, 12)
            .padding(.bottom, 160)
        }
        .scrollPosition(id: $konum, anchor: .top)
        .onAppear { konum = denetci.sayfa }
        .onChange(of: konum) { _, y in if let y, y != denetci.sayfa { denetci.sayfa = y } }
        .onChange(of: denetci.sayfa) { _, s in if konum != s { konum = s } }
        .environment(\.colorScheme, tema.koyu ? .dark : .light)
        .onTapGesture { dokunuldu() }
    }
}

private struct MetinSayfasi: View {
    let belge: PDFDocument?
    let no: Int
    let tema: OkumaTemasi
    let punto: Double
    let satir: Double
    let duz: Bool
    @State private var metin: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Rectangle().fill(Color(hex: tema.yazi).opacity(0.18)).frame(height: 1)
                Text("Sayfa \(no + 1)").font(.system(size: 11, weight: .heavy)).tracking(0.8).foregroundStyle(Color(hex: tema.yazi).opacity(0.5))
                Rectangle().fill(Color(hex: tema.yazi).opacity(0.18)).frame(height: 1)
            }
            if let metin {
                if metin.isEmpty {
                    Text("Bu sayfada seçilebilir yazı yok; taranmış bir sayfa olabilir. Sayfa görünümüne geçebilirsin.")
                        .font(.system(size: 14, weight: .medium)).italic().foregroundStyle(Color(hex: tema.yazi).opacity(0.6))
                } else {
                    Text(metin)
                        .font(duz ? .system(size: punto) : .okuma(punto))
                        .lineSpacing(satir)
                        .foregroundStyle(Color(hex: tema.yazi))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                Color.clear.frame(height: 400)
            }
        }
        .task(id: no) { metin = KitapDeposu.duzenle(belge?.page(at: no)?.string ?? "") }
    }
}

// MARK: Ayarlar

private struct KitapAyarlari: View {
    let denetci: PDFDenetci?
    @Environment(Depo.self) private var depo
    @Environment(\.palet) private var palet
    @Environment(\.dismiss) private var kapat
    @State private var parlaklik: Double = 0.5

    var body: some View {
        let a = depo.ayarlar
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    bolum("Yazı boyutu") {
                        HStack(spacing: 12) {
                            Button { degistirBoyut(-1) } label: { Text("A").font(.system(size: 15, weight: .bold, design: .serif)).frame(width: 52, height: 40) }
                                .buttonStyle(.glass).accessibilityLabel("Küçült")
                            Spacer()
                            Text(a.kitapMetin ? "\(Int(a.okumaPunto)) punto" : "%\(Int((denetci?.yakinlik ?? 1) * 100))")
                                .font(.kalin(16)).monospacedDigit()
                            Spacer()
                            Button { degistirBoyut(1) } label: { Text("A").font(.system(size: 24, weight: .bold, design: .serif)).frame(width: 52, height: 40) }
                                .buttonStyle(.glass).accessibilityLabel("Büyüt")
                        }
                        if !a.kitapMetin, (denetci?.yakinlik ?? 1) > 1 {
                            Button("Sayfayı ekrana sığdır") { denetci?.yakinlik = 1; denetci?.uygula(); kaydetYakinlik() }
                                .font(.system(size: 13, weight: .bold))
                        }
                        Text(a.kitapMetin ? "Yazı görünümünde satırlar ekrana sığar." : "Sayfa görünümünde iki parmakla da büyütebilirsin. Satırların ekrana sığması için “Yazı” görünümüne geç.")
                            .font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                    }
                    bolum("Görünüm") {
                        CamSegment(secenekler: [false, true], secili: depo.ayar(\.kitapMetin), ad: { $0 ? "Yazı" : "Sayfa" })
                        if !a.kitapMetin {
                            CamSegment(secenekler: [false, true], secili: depo.ayar(\.kitapYatay), ad: { $0 ? "Yana çevir" : "Aşağı kaydır" })
                        }
                        Toggle(isOn: depo.ayar(\.kitapSagdanSola)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sağdan sola").font(.kalin(14))
                                Text("Arapça ve Osmanlıca kitaplarda sayfa sırası").font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                            }
                        }
                    }
                    if a.kitapMetin {
                        bolum("Yazı tipi ve kenar") {
                            CamSegment(secenekler: [0, 1], secili: depo.ayar(\.kitapYaziTipi), ad: { ["Tırnaklı", "Düz"][$0] })
                            CamSegment(secenekler: [0, 1, 2], secili: depo.ayar(\.kitapKenar), ad: { ["Dar kenar", "Orta", "Geniş kenar"][$0] })
                        }
                    } else if !a.kitapYatay, let d = denetci {
                        bolum("Otomatik kaydırma") {
                            CamSegment(secenekler: [0.0, 20.0, 40.0, 70.0], secili: Binding(get: { [0.0, 20.0, 40.0, 70.0].min { abs($0 - d.kaydirmaHizi) < abs($1 - d.kaydirmaHizi) } ?? 0 }, set: { d.kaydir($0) }),
                                       ad: { [0.0: "Kapalı", 20.0: "Yavaş", 40.0: "Orta", 70.0: "Hızlı"][$0] ?? "" })
                            Text("Sayfa kendiliğinden aşağı akar; elin serbest kalır. Okurken sağ üstteki düğmelerle hızını değiştirirsin.")
                                .font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                        }
                    }
                    bolum("Sesli okuma") {
                        HStack(spacing: 12) {
                            Image(systemName: "tortoise").foregroundStyle(.secondary)
                            Slider(value: depo.ayar(\.kitapSesHizi), in: 0.35...0.65)
                            Image(systemName: "hare").foregroundStyle(.secondary)
                        }
                        Text("Alttaki kulaklık düğmesi kitabı bulunduğun sayfadan Türkçe sesle okur; sayfa bitince sonrakine geçer.")
                            .font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                    }
                    bolum("Ekran yönü") {
                        CamSegment(secenekler: [0, 1, 2], secili: depo.ayar(\.kitapEkran), ad: { ["Dik", "Yan", "Telefonla dönsün"][$0] })
                    }
                    bolum("Tema") {
                        OkumaTemaSecici()
                    }
                    bolum("Mavi ışık süzgeci") {
                        HStack(spacing: 12) {
                            Image(systemName: "sun.min").foregroundStyle(.secondary)
                            Slider(value: depo.ayar(\.sicakIsik), in: 0...1).tint(Color(red: 1, green: 0.62, blue: 0.25))
                            Image(systemName: "sun.max.fill").foregroundStyle(Color(red: 1, green: 0.62, blue: 0.25))
                        }
                        Text("Ekrana amber bir katman koyar; gece okurken gözü yormaz.").font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                    }
                    bolum("Parlaklık") {
                        HStack(spacing: 12) {
                            Image(systemName: "light.min").foregroundStyle(.secondary)
                            Slider(value: $parlaklik, in: 0.05...1)
                                .onChange(of: parlaklik) { _, y in ekran?.brightness = CGFloat(y) }
                            Image(systemName: "light.max").foregroundStyle(.secondary)
                        }
                    }
                    if a.kitapMetin {
                        bolum("Satır arası") {
                            CamSegment(secenekler: [0, 1, 2], secili: depo.ayar(\.satirAraligi), ad: { ["Sık", "Rahat", "Geniş"][$0] })
                        }
                    }
                    Toggle(isOn: depo.ayar(\.ekranAcik)) {
                        Text("Okurken ekran kapanmasın").font(.kalin(15))
                    }
                    .camKart(kose: 22, ic: 14)
                }
                .padding(16)
            }
            .navigationTitle("Okuma ayarları")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Bitti") { kapat() } } }
            .onAppear { parlaklik = Double(ekran?.brightness ?? 0.5) }
        }
    }

    private var ekran: UIScreen? { (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen }

    private func degistirBoyut(_ y: Int) {
        if depo.ayarlar.kitapMetin {
            depo.degistir { $0.ayarlar.okumaPunto = max(13, min(34, $0.ayarlar.okumaPunto + Double(y))) }
        } else {
            denetci?.yakinlastir(Double(y) * 0.15)
            kaydetYakinlik()
        }
        Dokunsal.hafif(0.4)
    }

    private func kaydetYakinlik() {
        guard let d = denetci, let id = depo.kayit.kitaplar.first(where: { KitapDeposu.url($0).path == d.belge?.documentURL?.path })?.id else { return }
        depo.degistir { k in if let i = k.kitaplar.firstIndex(where: { $0.id == id }) { k.kitaplar[i].yakinlik = d.yakinlik } }
    }

    private func bolum<I: View>(_ baslik: String, @ViewBuilder _ icerik: () -> I) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            BolumBasligi(metin: baslik)
            icerik()
        }
        .camKart(kose: 22, ic: 14)
    }
}

// MARK: İçindekiler, yer imleri, sayfalar

/// Sayfa küçük resimleri ayrı bir belge kopyasından üretilir (okuyucu takılmasın).
actor KucukResim {
    private let belge: PDFDocument?
    private var onbellek: [Int: UIImage] = [:]
    init(url: URL) { belge = PDFDocument(url: url) }

    func resim(_ i: Int, genislik: CGFloat) -> UIImage? {
        if let r = onbellek[i] { return r }
        guard let p = belge?.page(at: i) else { return nil }
        let b = p.bounds(for: .mediaBox)
        let r = p.thumbnail(of: CGSize(width: genislik * 2, height: genislik * 2 * b.height / max(b.width, 1)), for: .mediaBox)
        onbellek[i] = r
        return r
    }
}

private struct KitapIcindekiler: View {
    let denetci: PDFDenetci
    let kitapID: UUID
    @Environment(Depo.self) private var depo
    @Environment(\.palet) private var palet
    @Environment(\.dismiss) private var kapat
    @State private var bolum = 0
    @State private var uretici: KucukResim?

    struct Baslik: Identifiable { let id: Int; let ad: String; let sayfa: Int; let derinlik: Int }

    var body: some View {
        let kitap = depo.kayit.kitaplar.first { $0.id == kitapID }
        let basliklar = Self.basliklar(denetci.belge)
        NavigationStack {
            VStack(spacing: 10) {
                CamSegment(secenekler: [0, 1, 2], secili: $bolum, ad: { ["Bölümler", "Yer imleri", "Sayfalar"][$0] })
                    .padding(.horizontal, 16)
                switch bolum {
                case 0:
                    if basliklar.isEmpty {
                        bos("Bu PDF'te içindekiler bilgisi yok.", "Sayfalar sekmesinden istediğin sayfaya git.", "list.bullet.indent")
                    } else {
                        List(basliklar) { b in
                            Button { denetci.git(b.sayfa); kapat() } label: {
                                HStack {
                                    Text(b.ad).font(.system(size: b.derinlik == 0 ? 15.5 : 14, weight: b.derinlik == 0 ? .bold : .medium, design: .serif))
                                        .padding(.leading, CGFloat(b.derinlik) * 16)
                                    Spacer()
                                    Text("\(b.sayfa + 1)").font(.system(size: 13, weight: .semibold)).monospacedDigit().foregroundStyle(.secondary)
                                }
                                .foregroundStyle(aktif(b, basliklar) ? palet.vurgu : Color.primary)
                            }
                        }
                        .scrollContentBackground(.hidden)
                    }
                case 1:
                    if let kitap, !kitap.yerImleri.isEmpty {
                        List {
                            ForEach(kitap.yerImleri, id: \.self) { s in
                                Button { denetci.git(s); kapat() } label: {
                                    HStack(spacing: 12) {
                                        SayfaResmi(uretici: uretici, no: s, genislik: 44)
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text("Sayfa \(s + 1)").font(.kalin(15))
                                            Text(Self.ozet(denetci.belge, s)).font(.system(size: 12.5, weight: .medium)).foregroundStyle(.secondary).lineLimit(2)
                                        }
                                    }
                                }
                            }
                            .onDelete { sira in
                                depo.degistir { k in
                                    if let i = k.kitaplar.firstIndex(where: { $0.id == kitapID }) { k.kitaplar[i].yerImleri.remove(atOffsets: sira) }
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                    } else {
                        bos("Yer imi yok", "Okurken sağ üstteki kurdele simgesine dokun; sayfa buraya eklenir.", "bookmark")
                    }
                default:
                    ScrollViewReader { kaydir in
                        ScrollView {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 14) {
                                ForEach(0..<denetci.toplam, id: \.self) { i in
                                    Button { denetci.git(i); kapat() } label: {
                                        VStack(spacing: 5) {
                                            SayfaResmi(uretici: uretici, no: i, genislik: 100)
                                                .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(i == denetci.sayfa ? palet.vurgu : .clear, lineWidth: 2.5))
                                            Text("\(i + 1)").font(.system(size: 12, weight: i == denetci.sayfa ? .heavy : .semibold)).monospacedDigit()
                                                .foregroundStyle(i == denetci.sayfa ? palet.vurgu : .secondary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .id(i)
                                }
                            }
                            .padding(16)
                        }
                        .onAppear { kaydir.scrollTo(denetci.sayfa, anchor: .center) }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.top, 8)
            .navigationTitle(kitap?.ad ?? "İçindekiler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Bitti") { kapat() } } }
        }
        .task {
            if uretici == nil, let u = denetci.belge?.documentURL { uretici = KucukResim(url: u) }
            if basliklar.isEmpty, bolum == 0 { bolum = (kitap?.yerImleri.isEmpty ?? true) ? 2 : 1 }
        }
    }

    /// Okunan sayfanın içinde bulunduğu bölüm.
    private func aktif(_ b: Baslik, _ l: [Baslik]) -> Bool {
        let sonraki = l.first(where: { $0.sayfa > b.sayfa })?.sayfa ?? Int.max
        return b.sayfa <= denetci.sayfa && sonraki > denetci.sayfa
    }

    private func bos(_ baslik: String, _ alt: String, _ simge: String) -> some View {
        ContentUnavailableView { Label(baslik, systemImage: simge) } description: { Text(alt) }
    }

    static func basliklar(_ b: PDFDocument?) -> [Baslik] {
        guard let b, let kok = b.outlineRoot else { return [] }
        var sonuc: [Baslik] = []
        func gez(_ o: PDFOutline, _ d: Int) {
            for i in 0..<o.numberOfChildren {
                guard let c = o.child(at: i), sonuc.count < 500 else { continue }
                let sayfa = c.destination?.page ?? (c.action as? PDFActionGoTo)?.destination.page
                if let sayfa, let ad = c.label?.trimmingCharacters(in: .whitespacesAndNewlines), !ad.isEmpty {
                    sonuc.append(Baslik(id: sonuc.count, ad: ad, sayfa: b.index(for: sayfa), derinlik: min(d, 3)))
                }
                if d < 3 { gez(c, d + 1) }
            }
        }
        gez(kok, 0)
        return sonuc
    }

    static func ozet(_ b: PDFDocument?, _ s: Int) -> String {
        let t = (b?.page(at: s)?.string ?? "").split(whereSeparator: \.isNewline).joined(separator: " ")
        return t.isEmpty ? "Yazısız sayfa" : String(t.prefix(120))
    }
}

private struct SayfaResmi: View {
    let uretici: KucukResim?
    let no: Int
    let genislik: CGFloat
    @State private var resim: UIImage?

    var body: some View {
        Group {
            if let resim { Image(uiImage: resim).resizable().scaledToFit() } else { Color.white.opacity(0.85).aspectRatio(0.72, contentMode: .fit) }
        }
        .frame(width: genislik)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
        .task(id: "\(no)-\(uretici != nil)") { resim = await uretici?.resim(no, genislik: genislik) }
    }
}

// MARK: Arama

private struct KitapAramasi: View {
    let url: URL
    let denetci: PDFDenetci
    @Environment(\.palet) private var palet
    @Environment(\.dismiss) private var kapat
    @State private var q = ""
    @State private var sonuclar: [Bulgu] = []
    @State private var araniyor = false
    @State private var arandi = ""

    struct Bulgu: Identifiable, Sendable { let id: Int; let sayfa: Int; let once: String; let eslesen: String; let sonra: String }

    var body: some View {
        NavigationStack {
            List {
                if araniyor { HStack { ProgressView(); Text("Aranıyor…").foregroundStyle(.secondary) } }
                if !araniyor, !arandi.isEmpty, sonuclar.isEmpty {
                    Text("“\(arandi)” bu kitapta bulunamadı.").foregroundStyle(.secondary)
                }
                if !sonuclar.isEmpty {
                    Section("\(sonuclar.count)\(sonuclar.count >= 300 ? "+" : "") sonuç") {
                        ForEach(sonuclar) { b in
                            Button { denetci.vurgula(arandi, sayfa: b.sayfa); kapat() } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Sayfa \(b.sayfa + 1)").font(.system(size: 12, weight: .heavy)).foregroundStyle(palet.vurgu)
                                    Text(parca(b)).font(.system(size: 14.5)).lineLimit(3)
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .searchable(text: $q, placement: .navigationBarDrawer(displayMode: .always), prompt: "Kitapta ara")
            .autocorrectionDisabled()
            .navigationTitle("Kitapta ara")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Bitti") { kapat() } } }
            .task(id: q) {
                let aranan = q.trimmingCharacters(in: .whitespaces)
                guard aranan.count >= 2 else { sonuclar = []; arandi = ""; return }
                try? await Task.sleep(nanoseconds: 400_000_000)
                guard !Task.isCancelled else { return }
                araniyor = true
                let u = url
                let bulunan = await Task.detached(priority: .userInitiated) { KitapAramasi.ara(u, aranan) }.value
                guard !Task.isCancelled else { return }
                sonuclar = bulunan
                arandi = aranan
                araniyor = false
            }
        }
    }

    private func parca(_ b: Bulgu) -> AttributedString {
        var a = AttributedString(b.once)
        var e = AttributedString(b.eslesen)
        e.font = .system(size: 14.5, weight: .heavy)
        e.backgroundColor = Color.yellow.opacity(0.35)
        a.append(e)
        a.append(AttributedString(b.sonra))
        return a
    }

    nonisolated static func ara(_ url: URL, _ q: String) -> [Bulgu] {
        guard let d = PDFDocument(url: url) else { return [] }
        var sonuc: [Bulgu] = []
        let tr = Locale(identifier: "tr_TR")
        for i in 0..<d.pageCount {
            guard let ham = d.page(at: i)?.string, sonuc.count < 300 else { continue }
            let s = ham as NSString
            var aralik = NSRange(location: 0, length: s.length)
            while aralik.length > 0, sonuc.count < 300 {
                let f = s.range(of: q, options: [.caseInsensitive, .diacriticInsensitive], range: aralik, locale: tr)
                if f.location == NSNotFound { break }
                let bas = max(0, f.location - 50), son = min(s.length, f.location + f.length + 70)
                let temiz: (String) -> String = { $0.replacingOccurrences(of: "\n", with: " ") }
                sonuc.append(Bulgu(id: sonuc.count, sayfa: i,
                                   once: (bas > 0 ? "…" : "") + temiz(s.substring(with: NSRange(location: bas, length: f.location - bas))),
                                   eslesen: temiz(s.substring(with: f)),
                                   sonra: temiz(s.substring(with: NSRange(location: f.location + f.length, length: son - f.location - f.length))) + (son < s.length ? "…" : "")))
                aralik = NSRange(location: f.location + f.length, length: s.length - f.location - f.length)
            }
        }
        return sonuc
    }
}


/// Kitabı Türkçe sesle okur (yazısı seçilebilen PDF'lerde); sayfa bitince sonrakine geçer.
@MainActor
@Observable
final class SesliOkuyucu: NSObject, AVSpeechSynthesizerDelegate {
    private(set) var okuyor = false
    @ObservationIgnored private let konusan = AVSpeechSynthesizer()
    @ObservationIgnored private weak var denetci: PDFDenetci?
    @ObservationIgnored private var hiz: Float = 0.5

    override init() {
        super.init()
        konusan.delegate = self
    }

    func basla(_ d: PDFDenetci, hiz h: Double) {
        denetci = d
        hiz = Float(h)
        okuyor = true
        SesOturumu.hazirla()
        sayfayiOku(d.sayfa)
    }

    func dur() {
        okuyor = false
        konusan.stopSpeaking(at: .immediate)
    }

    private func sayfayiOku(_ i: Int) {
        guard okuyor, let d = denetci, i < d.toplam else { okuyor = false; return }
        let metin = KitapDeposu.duzenle(d.belge?.page(at: i)?.string ?? "")
        if d.sayfa != i { d.git(i) }
        // Yazısız sayfayı atlar (en çok üç sayfa).
        guard !metin.isEmpty else {
            if i + 1 < min(d.toplam, d.sayfa + 4) { sayfayiOku(i + 1) } else { okuyor = false }
            return
        }
        let u = AVSpeechUtterance(string: metin)
        u.voice = AVSpeechSynthesisVoice(language: "tr-TR")
        u.rate = hiz
        konusan.speak(u)
    }

    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish u: AVSpeechUtterance) {
        Task { @MainActor in
            guard self.okuyor, let d = self.denetci else { return }
            self.sayfayiOku(d.sayfa + 1)
        }
    }
}
