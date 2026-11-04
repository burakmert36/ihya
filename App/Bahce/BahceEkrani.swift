import Charts
import SwiftUI

enum Donem: String, CaseIterable, Identifiable {
    case gun = "Gün", hafta = "Hafta", ay = "Ay", yil = "Yıl"
    var id: String { rawValue }

    static var takvim: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "tr_TR")
        c.firstWeekday = 2
        return c
    }

    /// kaydir: 0 bu dönem, -1 önceki…
    func aralik(_ kaydir: Int, simdi: Date = .now) -> DateInterval {
        let c = Donem.takvim
        let bilesen: Calendar.Component = self == .gun ? .day : self == .hafta ? .weekOfYear : self == .ay ? .month : .year
        let an = c.date(byAdding: bilesen, value: kaydir, to: simdi) ?? simdi
        return c.dateInterval(of: bilesen, for: an) ?? DateInterval(start: c.startOfDay(for: an), duration: 86400)
    }

    func baslik(_ kaydir: Int) -> String {
        let a = aralik(kaydir)
        switch self {
        case .gun: return kaydir == 0 ? "Bugün" : kaydir == -1 ? "Dün" : Tarihler.gunAyGun.string(from: a.start)
        case .hafta:
            let son = a.end.addingTimeInterval(-1)
            return kaydir == 0 ? "Bu hafta" : "\(Tarihler.kisaGun.string(from: a.start)) – \(Tarihler.kisaGun.string(from: son))"
        case .ay: return Tarihler.ayYil.string(from: a.start).capitalized(with: Locale(identifier: "tr_TR"))
        case .yil: return String(Donem.takvim.component(.year, from: a.start))
        }
    }
}

struct DonemSecici: View {
    @Binding var donem: Donem
    @Binding var kaydir: Int
    @Environment(\.palet) private var palet
    var body: some View {
        VStack(spacing: 10) {
            CamSegment(secenekler: Donem.allCases, secili: $donem, ad: { $0.rawValue }, yukseklik: 32)
                .onChange(of: donem) { _, _ in kaydir = 0 }
            HStack {
                Button { kaydir -= 1 } label: { Image(systemName: "chevron.left").font(.system(size: 14, weight: .bold)).frame(width: 36, height: 36) }
                    .buttonStyle(.plain)
                    .camYuzey(palet.cam(etkilesimli: true), in: .circle)
                    .accessibilityLabel("Önceki")
                Spacer()
                Text(donem.baslik(kaydir)).font(.kalin(16))
                Spacer()
                Button { kaydir += 1 } label: { Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold)).frame(width: 36, height: 36) }
                    .buttonStyle(.plain)
                    .camYuzey(palet.cam(etkilesimli: true), in: .circle)
                    .disabled(kaydir >= 0)
                    .opacity(kaydir >= 0 ? 0.4 : 1)
                    .accessibilityLabel("Sonraki")
            }
        }
    }
}

struct BahceEkrani: View {
    @Environment(Depo.self) private var depo
    @Environment(VakitServisi.self) private var vakit
    @Environment(OdakMotoru.self) private var odak
    @Environment(Yonlendirici.self) private var yon
    @Environment(\.palet) private var palet
    @State private var donem: Donem = .gun
    @State private var kaydir = 0
    @State private var secili: UUID?

    var body: some View {
        let a = donem.aralik(kaydir)
        let liste = depo.kayit.oturumlar.filter { a.contains($0.baslangic) }.sorted { $0.baslangic < $1.baslangic }
        ScrollView {
            VStack(spacing: 12) {
                TakipSecici()
                SahneBasligi(ust: Tarihler.ustSatir(), baslik: "Bahçem") {
                    HStack(spacing: 8) {
                        hap(simge: "flame.fill", renk: Color(hex: "#22B35A"), metin: "\(depo.seri(vakit))", etiket: "Seri \(depo.seri(vakit)) gün")
                        hap(simge: "leaf.fill", renk: Color(hex: "#2E9BEA"), metin: "\(depo.kayit.tohum)", etiket: "\(depo.kayit.tohum) tohum")
                    }
                    .padding(.bottom, 4)
                }
                BahceAlani(oturumlar: liste, secili: secili) { o in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { secili = secili == o.id ? nil : o.id }
                    Dokunsal.hafif(0.5)
                }
                .padding(.horizontal, -8)
                if let id = secili, let o = depo.kayit.oturumlar.first(where: { $0.id == id }) {
                    BitkiAyrintisi(oturum: o) { withAnimation { secili = nil } } ihya: {
                        secili = nil
                        odak.kapat()
                        odak.baslat(tur: o.tur, plan: o.plan, konu: o.konu, ad: o.ad, ihya: o.id)
                        yon.odakAcik = true
                    }
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
                } else {
                    DonemOzeti(donem: donem, kaydir: kaydir, liste: liste)
                        .transition(.opacity)
                }
                DonemSecici(donem: $donem, kaydir: $kaydir)
                HaftalikOdak()
                GlassEffectContainer(spacing: 8) {
                    HStack(spacing: 8) {
                        NavigationLink(value: Rota.koleksiyon) {
                            Label("Koleksiyon", systemImage: "square.grid.2x2").font(.kalin(14)).frame(maxWidth: .infinity, minHeight: 30)
                        }
                        .buttonStyle(.glass).controlSize(.large)
                        NavigationLink(value: Rota.istatistik) {
                            Label("İstatistik", systemImage: "chart.bar.xaxis").font(.kalin(14)).frame(maxWidth: .infinity, minHeight: 30)
                        }
                        .buttonStyle(.glass).controlSize(.large)
                    }
                }
                if !liste.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        BolumBasligi(metin: "Oturumlar", simge: "list.bullet")
                        ForEach(liste.reversed().prefix(12)) { o in
                            Button { withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { secili = o.id } } label: { OturumSatiri(oturum: o) }
                                .buttonStyle(.plain)
                        }
                    }
                    .camKart()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .altCubukPayi()
        .background { BahceGokyuzu() }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: donem) { _, _ in secili = nil }
        .onChange(of: kaydir) { _, _ in secili = nil }
    }

    private func hap(simge: String, renk: Color, metin: String, etiket: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: simge).foregroundStyle(renk)
            Text(metin).font(.kalin(15)).monospacedDigit()
        }
        .padding(.horizontal, 12)
        .frame(height: 38)
        .camYuzey(palet.cam(), in: .capsule)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(etiket)
    }
}

/// Seçili dönemin özeti: hedef çubuğu, dikilenler, kuruyanlar.
struct DonemOzeti: View {
    @Environment(Depo.self) private var depo
    @Environment(\.palet) private var palet
    let donem: Donem
    let kaydir: Int
    let liste: [OdakOturumu]

    var body: some View {
        let tamam = liste.filter { $0.durum == .tamam }
        let dk = Int(tamam.reduce(0) { $0 + $1.sure }.rounded())
        let gunHedefi = max(10, depo.ayarlar.gunlukHedef)
        let hedef = donem == .gun ? gunHedefi : donem == .hafta ? gunHedefi * 7 : donem == .ay ? gunHedefi * 30 : gunHedefi * 365
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(donem.baslik(kaydir)).font(.kalin(17))
                Spacer()
                Text("\(dk) / \(hedef) dk · \(tamam.count) dikim").font(.system(size: 13, weight: .bold)).foregroundStyle(.secondary).monospacedDigit()
            }
            IlerlemeCubugu(oran: Double(dk) / Double(hedef))
            if !liste.isEmpty {
                AkisDuzeni(bosluk: 8) {
                    ForEach(liste.suffix(6).reversed()) { o in
                        let kuru = o.durum == .vazgecildi
                        Text("\(BitkiKatalogu.ad(o.tur)) · \(depo.konu(o.konu)?.ad ?? "Odak") \(kuru ? "\(Int(o.sure.rounded())) dk kurudu" : "\(o.plan) dk")")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundStyle(Color(hex: kuru ? "#9A4A08" : "#1D6B3A"))
                            .padding(.horizontal, 10)
                            .frame(height: 28)
                            .background(Capsule().fill(kuru ? Color(r: 255, g: 243, b: 224, a: 0.85) : Color.white.opacity(0.7)))
                    }
                }
            }
            Text(liste.isEmpty ? "Bu dönemde bitki yok. Odaklan düğmesiyle ilk fidanını dik." : "Bitkinin boyu ona verdiğin süreyi gösterir. Kuru dala dokun, aynı süreyle ihya et.")
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .camKart(kose: 28)
    }
}

/// Bahçede seçilen bitkinin kartı.
struct BitkiAyrintisi: View {
    @Environment(Depo.self) private var depo
    @Environment(\.palet) private var palet
    let oturum: OdakOturumu
    let kapat: () -> Void
    let ihya: () -> Void

    var body: some View {
        let kuru = oturum.durum == .vazgecildi
        let dk = kuru ? max(1, oturum.sure) : Double(oturum.plan)
        let b = BitkiKatalogu.bul(oturum.tur)
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                BitkiResmi(tur: oturum.tur, dk: dk, tohum: oturum.tohum, lod: 0.7, kurudu: kuru, sigdir: true)
                    .frame(width: 54, height: 64)
                    .background(RoundedRectangle(cornerRadius: 16).fill(LinearGradient(colors: [Color(hex: "#DDF1FF"), Color(hex: "#F4FBEF")], startPoint: .top, endPoint: .bottom)))
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(BitkiKatalogu.ad(oturum.tur)) · \(kuru ? "Kuru dal" : (b?.evre(dk - 0.01).evre.ad ?? ""))")
                        .font(.system(size: 20, weight: .heavy)).lineLimit(1).minimumScaleFactor(0.7)
                    Text("\(Tarihler.gunAy.string(from: oturum.baslangic)) · \(depo.konu(oturum.konu)?.ad ?? "Odak") · \(kuru ? oturum.sure.sureMetni : "\(oturum.plan) dk")")
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Button(action: kapat) {
                    Image(systemName: "xmark").font(.system(size: 14, weight: .bold)).frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .camYuzey(palet.cam(etkilesimli: true), in: .circle)
                .accessibilityLabel("Kapat")
            }
            if let b {
                EvreSeridi(tur: b, plan: oturum.plan, dk: dk)
                Text(b.not).font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)
            }
            if !oturum.ad.isEmpty { Text(oturum.ad).font(.system(size: 13, weight: .semibold)) }
            if kuru {
                AnaDugme(baslik: "İHYA ET · \(oturum.plan) dk", yukseklik: 34, eylem: ihya)
            }
        }
        .camKart(kose: 30)
    }
}

/// Satır satır dizilen hap etiketleri (sığmayan alt satıra geçer).
struct AkisDuzeni: Layout {
    var bosluk: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let w = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, satir: CGFloat = 0, enGenis: CGFloat = 0
        for s in subviews {
            let b = s.sizeThatFits(.unspecified)
            if x > 0, x + b.width > w { x = 0; y += satir + bosluk; satir = 0 }
            x += b.width + bosluk
            satir = max(satir, b.height)
            enGenis = max(enGenis, x - bosluk)
        }
        return CGSize(width: min(w, enGenis), height: y + satir)
    }

    func placeSubviews(in r: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = r.minX, y = r.minY, satir: CGFloat = 0
        for s in subviews {
            let b = s.sizeThatFits(.unspecified)
            if x > r.minX, x + b.width > r.maxX { x = r.minX; y += satir + bosluk; satir = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(b))
            x += b.width + bosluk
            satir = max(satir, b.height)
        }
    }
}

/// İhya temasında Bahçe'nin göğü: bulutlar, tepeler ve çim.
struct BahceGokyuzu: View {
    @Environment(Depo.self) private var depo
    @Environment(\.accessibilityReduceMotion) private var hareketiAzalt
    @State private var kay = false

    var body: some View {
        if depo.ayarlar.tema.palet(.bahce).bahceSahnesi {
            GeometryReader { g in
                let W = g.size.width, H = g.size.height, sx = W / 390
                ZStack(alignment: .topLeading) {
                    Canvas { ctx, _ in
                        let c = ctx
                        func tepe(_ y0: CGFloat, _ noktalar: [(CGFloat, CGFloat, CGFloat, CGFloat)], _ renk: Color) {
                            var p = Path()
                            p.move(to: CGPoint(x: 0, y: y0 + noktalar[0].1 * sx))
                            for n in noktalar { p.addQuadCurve(to: CGPoint(x: n.2 * sx, y: y0 + n.3 * sx), control: CGPoint(x: n.0 * sx, y: y0 + n.1 * sx)) }
                            p.addLine(to: CGPoint(x: W, y: H)); p.addLine(to: CGPoint(x: 0, y: H)); p.closeSubpath()
                            c.fill(p, with: .color(renk))
                        }
                        let y0 = H * 0.225
                        tepe(y0, [(70, 60, 150, 98), (225, 116, 300, 80), (345, 64, 390, 96)], Color(hex: "#BFE3D2").opacity(0.7))
                        tepe(y0 + 30 * sx, [(90, 100, 190, 136), (290, 154, 390, 122)], Color(hex: "#A6D7B4").opacity(0.75))
                        let cim = CGRect(x: 0, y: H * 0.52, width: W, height: H * 0.48)
                        ctx.fill(Path(cim), with: .linearGradient(Gradient(stops: [.init(color: Color(r: 160, g: 220, b: 150, a: 0), location: 0), .init(color: Color(hex: "#B9E4A6"), location: 0.3), .init(color: Color(hex: "#9FD58E"), location: 1)]),
                                                                 startPoint: CGPoint(x: 0, y: cim.minY), endPoint: CGPoint(x: 0, y: cim.maxY)))
                    }
                    bulut(120 * sx, 34 * sx).offset(x: 22 * sx + (kay ? 24 : 0), y: H * 0.178)
                    bulut(80 * sx, 22 * sx).opacity(0.85).offset(x: 250 * sx - (kay ? 18 : 0), y: H * 0.237)
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear { if !hareketiAzalt { withAnimation(.easeInOut(duration: 16).repeatForever(autoreverses: true)) { kay = true } } }
        }
    }

    private func bulut(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack(alignment: .bottomLeading) {
            Capsule().fill(Color.white.opacity(0.78)).frame(width: w, height: h)
            Circle().fill(Color.white.opacity(0.72)).frame(width: h * 1.35, height: h * 1.35).offset(x: w * 0.3, y: -h * 0.45)
        }
    }
}

struct Ozet: View {
    let baslik: String
    let deger: String
    let simge: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(baslik, systemImage: simge).font(.caption).foregroundStyle(.secondary)
            Text(deger).font(.title3.weight(.semibold)).monospacedDigit()
        }
        .camKart(kose: 18)
    }
}

struct OturumSatiri: View {
    @Environment(Depo.self) private var depo
    let oturum: OdakOturumu
    var body: some View {
        HStack(spacing: 12) {
            BitkiResmi(tur: oturum.tur, dk: oturum.durum == .tamam ? Double(oturum.plan) : max(1, oturum.sure), tohum: oturum.tohum,
                       lod: 0.5, kurudu: oturum.durum == .vazgecildi, sigdir: true)
                .frame(width: 36, height: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(oturum.ad.isEmpty ? BitkiKatalogu.ad(oturum.tur) : oturum.ad).font(.subheadline.weight(.semibold)).lineLimit(1)
                HStack(spacing: 6) {
                    if let k = depo.konu(oturum.konu) {
                        Circle().fill(Color(hex: k.renk)).frame(width: 7, height: 7)
                        Text(k.ad)
                    }
                    Text(Tarihler.saat.string(from: oturum.baslangic))
                }
                .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(oturum.sure.sureMetni).font(.subheadline.weight(.semibold)).monospacedDigit()
                .foregroundStyle(oturum.durum == .tamam ? Color.primary : Color.secondary)
        }
        .contentShape(Rectangle())
    }
}

/// İzometrik çim adası; bitkiler arkadan öne dizilir. Bütün bitkiler aynı ölçekte çizilir (ağaç çiçekten büyük görünür).
struct BahceAlani: View {
    let oturumlar: [OdakOturumu]
    var secili: UUID? = nil
    var sec: ((OdakOturumu) -> Void)? = nil
    static let sinir = 64

    var body: some View {
        let gosterilen = Array(oturumlar.suffix(BahceAlani.sinir))
        let n = max(4, min(8, Int(ceil(sqrt(Double(max(1, gosterilen.count)))))))
        GeometryReader { g in
            let W = g.size.width, H = W * 0.56
            let hucre = W / CGFloat(n)
            ZStack(alignment: .topLeading) {
                Ellipse().fill(Color.black.opacity(0.12)).frame(width: W * 0.88, height: 28).blur(radius: 10)
                    .position(x: W / 2, y: hucre * 0.6 + H + 26)
                ElmasZemin(n: n).frame(width: W, height: H + 26).offset(y: hucre * 0.6)
                ForEach(yerlesim(gosterilen.count, n), id: \.sira) { y in
                    let o = gosterilen[y.sira]
                    let cx = W / 2 + CGFloat(y.i - y.j) * hucre / 2
                    let cy = hucre * 0.6 + CGFloat(y.i + y.j + 1) * (H / 2) / CGFloat(n)
                    BitkiResmi(tur: o.tur, dk: o.durum == .tamam ? Double(o.plan) : max(1, o.sure), tohum: o.tohum,
                               cerceve: CGRect(x: -10, y: -24, width: 120, height: 144), lod: n > 5 ? 0.45 : 0.7, kurudu: o.durum == .vazgecildi)
                        .frame(width: hucre * 1.35, height: hucre * 1.62)
                        .scaleEffect(secili == o.id ? 1.12 : 1, anchor: .bottom)
                        .shadow(color: secili == o.id ? Color.white.opacity(0.9) : .clear, radius: 8)
                        .contentShape(Rectangle().inset(by: hucre * 0.25))
                        .onTapGesture { sec?(o) }
                        .position(x: cx, y: cy - hucre * 0.62)
                        .accessibilityLabel("\(BitkiKatalogu.ad(o.tur)), \(o.durum == .tamam ? "\(o.plan) dakika" : "kuru")")
                        .accessibilityAddTraits(.isButton)
                }
            }
        }
        .aspectRatio(1 / 0.74, contentMode: .fit)
        .overlay(alignment: .bottom) {
            if oturumlar.count > BahceAlani.sinir {
                Text("+\(oturumlar.count - BahceAlani.sinir) bitki daha").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
            }
        }
    }

    private struct Yer { let sira: Int; let i: Int; let j: Int }

    /// Hücreleri ortadan dışa doğru doldurur, sonra arkadan öne sıralar.
    private func yerlesim(_ adet: Int, _ n: Int) -> [Yer] {
        var hucreler: [(Int, Int)] = []
        for i in 0..<n { for j in 0..<n { hucreler.append((i, j)) } }
        let m = Double(n - 1) / 2
        hucreler.sort { a, b in
            let da = abs(Double(a.0) - m) + abs(Double(a.1) - m), db = abs(Double(b.0) - m) + abs(Double(b.1) - m)
            return da == db ? (a.0 + a.1 < b.0 + b.1) : da < db
        }
        let secili = Array(hucreler.prefix(adet))
        return secili.enumerated().map { Yer(sira: $0.offset, i: $0.element.0, j: $0.element.1) }
            .sorted { ($0.i + $0.j, $0.i) < ($1.i + $1.j, $1.i) }
    }
}

/// Adanın zemini: dama çim karoları, toprak yanlar, üstte ince çim şeridi.
struct ElmasZemin: View {
    let n: Int
    var body: some View {
        Canvas { ctx, b in
            let W = b.width, d: CGFloat = 26, H = b.height - d
            func nokta(_ i: CGFloat, _ j: CGFloat) -> CGPoint { CGPoint(x: W / 2 + (i - j) * W / 2 / CGFloat(n), y: (i + j) * H / 2 / CGFloat(n)) }
            var sol = Path()
            sol.move(to: CGPoint(x: 0, y: H / 2)); sol.addLine(to: CGPoint(x: W / 2, y: H))
            sol.addLine(to: CGPoint(x: W / 2, y: H + d)); sol.addLine(to: CGPoint(x: 0, y: H / 2 + d)); sol.closeSubpath()
            var sag = Path()
            sag.move(to: CGPoint(x: W, y: H / 2)); sag.addLine(to: CGPoint(x: W / 2, y: H))
            sag.addLine(to: CGPoint(x: W / 2, y: H + d)); sag.addLine(to: CGPoint(x: W, y: H / 2 + d)); sag.closeSubpath()
            ctx.fill(sol, with: .linearGradient(Gradient(colors: [Color(hex: "#B07A4E"), Color(hex: "#7E5333")]), startPoint: CGPoint(x: 0, y: H / 2), endPoint: CGPoint(x: 0, y: H + d)))
            ctx.fill(sag, with: .linearGradient(Gradient(colors: [Color(hex: "#93623D"), Color(hex: "#5E3D25")]), startPoint: CGPoint(x: W, y: H / 2), endPoint: CGPoint(x: W, y: H + d)))
            // çim karoları
            for i in 0..<n {
                for j in 0..<n {
                    var k = Path()
                    k.move(to: nokta(CGFloat(i), CGFloat(j)))
                    k.addLine(to: nokta(CGFloat(i + 1), CGFloat(j)))
                    k.addLine(to: nokta(CGFloat(i + 1), CGFloat(j + 1)))
                    k.addLine(to: nokta(CGFloat(i), CGFloat(j + 1)))
                    k.closeSubpath()
                    let acik = (i + j).isMultiple(of: 2)
                    ctx.fill(k, with: .color(acik ? Color(hex: "#86CF62") : Color(hex: "#74BF52")))
                    ctx.stroke(k, with: .color(.white.opacity(0.18)), lineWidth: 0.6)
                }
            }
            // ön kenarda ince çim şeridi
            var serit = Path()
            serit.move(to: CGPoint(x: 0, y: H / 2)); serit.addLine(to: CGPoint(x: W / 2, y: H)); serit.addLine(to: CGPoint(x: W, y: H / 2))
            serit.addLine(to: CGPoint(x: W, y: H / 2 + 5)); serit.addLine(to: CGPoint(x: W / 2, y: H + 5)); serit.addLine(to: CGPoint(x: 0, y: H / 2 + 5)); serit.closeSubpath()
            ctx.fill(serit, with: .color(Color(hex: "#5FAE45")))
        }
    }
}

// MARK: İstatistik

struct IstatistikEkrani: View {
    @Environment(Depo.self) private var depo
    @Environment(VakitServisi.self) private var vakit
    @State private var donem: Donem = .hafta
    @State private var kaydir = 0

    private struct Cubuk: Identifiable { let id = UUID(); let etiket: String; let sira: Int; let konu: String; let renk: String; let dk: Double }
    private struct Dilim: Identifiable { let id = UUID(); let konu: String; let renk: String; let dk: Double }
    private struct TurSayisi: Identifiable { let tur: String; let adet: Int; var id: String { tur } }

    var body: some View {
        let a = donem.aralik(kaydir)
        let liste = depo.kayit.oturumlar.filter { a.contains($0.baslangic) && $0.durum == .tamam }
        let cubuklar = cubukla(liste, a)
        let dilimler = dilimle(liste)
        let alan = dilimler.map(\.konu) + ["—"]
        let boya = dilimler.map { Color(hex: $0.renk) } + [Color.clear]
        ScrollView {
            VStack(spacing: 18) {
                DonemSecici(donem: $donem, kaydir: $kaydir)
                VStack(alignment: .leading, spacing: 12) {
                    BolumBasligi(metin: "Odak süresi (dk)", simge: "chart.bar")
                    Chart(cubuklar) { c in
                        BarMark(x: .value("Zaman", c.etiket), y: .value("Dakika", c.dk))
                            .foregroundStyle(by: .value("Konu", c.konu))
                            .cornerRadius(4)
                    }
                    .chartForegroundStyleScale(domain: alan, range: boya)
                    .chartXAxis { AxisMarks(values: .automatic(desiredCount: 8)) }
                    .chartLegend(.hidden)
                    .frame(height: 220)
                }
                .camKart()
                VStack(alignment: .leading, spacing: 12) {
                    BolumBasligi(metin: "Konulara göre", simge: "chart.pie")
                    if dilimler.isEmpty {
                        Text("Bu dönemde tamamlanan odak yok.").font(.footnote).foregroundStyle(.secondary)
                    } else {
                        HStack(spacing: 18) {
                            Chart(dilimler) { d in
                                SectorMark(angle: .value("Dakika", d.dk), innerRadius: .ratio(0.6), angularInset: 1.5)
                                    .foregroundStyle(Color(hex: d.renk))
                                    .cornerRadius(3)
                            }
                            .frame(width: 130, height: 130)
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(dilimler) { d in
                                    HStack(spacing: 8) {
                                        Circle().fill(Color(hex: d.renk)).frame(width: 9, height: 9)
                                        Text(d.konu).font(.subheadline)
                                        Spacer()
                                        Text(d.dk.sureMetni).font(.subheadline).monospacedDigit().foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .camKart()
                VStack(alignment: .leading, spacing: 12) {
                    BolumBasligi(metin: "Seriler", simge: "flame")
                    HStack {
                        Ozet(baslik: "Şimdiki seri", deger: "\(depo.seri(vakit)) gün", simge: "calendar")
                        Ozet(baslik: "Toplam bitki", deger: "\(depo.kayit.oturumlar.filter { $0.durum == .tamam }.count)", simge: "tree")
                    }
                }
                let turler = Array(Dictionary(grouping: liste, by: \.tur).map { TurSayisi(tur: $0.key, adet: $0.value.count) }.sorted { $0.adet > $1.adet }.prefix(6))
                if !turler.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        BolumBasligi(metin: "En çok dikilenler", simge: "leaf")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(turler) { t in
                                    VStack(spacing: 4) {
                                        BitkiResmi(tur: t.tur, dk: Double(BitkiKatalogu.bul(t.tur)?.dk ?? 25), lod: 0.6, sigdir: true)
                                            .frame(width: 56, height: 66)
                                        Text("\(BitkiKatalogu.ad(t.tur)) ×\(t.adet)").font(.caption2)
                                    }
                                }
                            }
                        }
                        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
                    }
                    .camKart()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .navigationTitle("İstatistik")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func cubukla(_ liste: [OdakOturumu], _ a: DateInterval) -> [Cubuk] {
        let c = Donem.takvim
        var kovalar: [(String, Date, Date)] = []
        switch donem {
        case .gun:
            for s in stride(from: 0, to: 24, by: 3) {
                let b = c.date(byAdding: .hour, value: s, to: a.start)!
                kovalar.append((String(format: "%02d", s), b, c.date(byAdding: .hour, value: 3, to: b)!))
            }
        case .hafta:
            for g in 0..<7 {
                let b = c.date(byAdding: .day, value: g, to: a.start)!
                kovalar.append((Tarihler.haftaGunuKisa.string(from: b), b, c.date(byAdding: .day, value: 1, to: b)!))
            }
        case .ay:
            var b = a.start
            while b < a.end {
                let s = c.date(byAdding: .day, value: 1, to: b)!
                kovalar.append((String(c.component(.day, from: b)), b, s))
                b = s
            }
        case .yil:
            for m in 0..<12 {
                let b = c.date(byAdding: .month, value: m, to: a.start)!
                kovalar.append((DateFormatter.tr("MMM").string(from: b), b, c.date(byAdding: .month, value: 1, to: b)!))
            }
        }
        var sonuc: [Cubuk] = []
        for (sira, k) in kovalar.enumerated() {
            let icindeki = liste.filter { $0.baslangic >= k.1 && $0.baslangic < k.2 }
            if icindeki.isEmpty { sonuc.append(Cubuk(etiket: k.0, sira: sira, konu: "—", renk: "#999999", dk: 0)); continue }
            for (konu, grup) in Dictionary(grouping: icindeki, by: { $0.konu }) {
                let kk = depo.konu(konu)
                sonuc.append(Cubuk(etiket: k.0, sira: sira, konu: kk?.ad ?? "Konusuz", renk: kk?.renk ?? "#8E8E93", dk: grup.reduce(0) { $0 + $1.sure }))
            }
        }
        return sonuc
    }

    private func dilimle(_ liste: [OdakOturumu]) -> [Dilim] {
        Dictionary(grouping: liste, by: { $0.konu }).map { konu, grup in
            let k = depo.konu(konu)
            return Dilim(konu: k?.ad ?? "Konusuz", renk: k?.renk ?? "#8E8E93", dk: grup.reduce(0) { $0 + $1.sure })
        }
        .sorted { $0.dk > $1.dk }
    }
}
