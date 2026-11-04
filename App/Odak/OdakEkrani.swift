import SwiftUI

struct OdakEkrani: View {
    @Environment(OdakMotoru.self) private var odak

    private var halAnahtari: Int {
        switch odak.hal {
        case .bos: 0
        case .calisiyor: 1
        case .bitti: 2
        case .kurudu: 3
        }
    }

    var body: some View {
        Group {
            switch odak.hal {
            case .bos: OdakKurulum()
            case .calisiyor: OdakCalisiyor()
            case .bitti(let o): OdakSonuc(oturum: o, basarili: true)
            case .kurudu(let o): OdakSonuc(oturum: o, basarili: false)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.86), value: halAnahtari)
        .sahne(.odak)
        .toolbar(.hidden, for: .navigationBar)
    }
}

enum OdakCercevesi {
    /// Bitkinin tam formunu kadraja sığdırır; zemin altta kalır, küçük çiçekler aşırı büyümez.
    static func hesapla(_ b: CGRect, oran: CGFloat = 0.9) -> CGRect {
        let alt = max(b.maxY, 114) + 2
        var h = max(alt - (b.minY - 8), 54)
        let w = max(b.width + 14, h * oran)
        h = max(h, w / oran)
        return CGRect(x: b.midX - w / 2, y: alt - h, width: w, height: h)
    }
    static let varsayilan = CGRect(x: 5, y: 10, width: 90, height: 106)
    /// Kubbenin sabit kadrajı: süre arttıkça bitki gerçekten büyür.
    static let kubbe = CGRect(x: -12, y: -24, width: 124, height: 149)
}

/// Zeminde gölgeli küçük toprak adası.
struct ToprakAdasi: View {
    var body: some View {
        ZStack {
            Ellipse().fill(Color.black.opacity(0.10)).frame(height: 30).offset(y: 6).blur(radius: 6)
            Ellipse()
                .fill(LinearGradient(colors: [Color(red: 0.55, green: 0.80, blue: 0.42), Color(red: 0.30, green: 0.58, blue: 0.28)], startPoint: .top, endPoint: .bottom))
                .frame(height: 34)
            Ellipse()
                .fill(LinearGradient(colors: [Color(red: 0.62, green: 0.45, blue: 0.30), Color(red: 0.42, green: 0.29, blue: 0.19)], startPoint: .top, endPoint: .bottom))
                .frame(height: 22)
                .offset(y: 12)
                .mask(Rectangle().offset(y: 17))
        }
    }
}

/// Cam kubbe: içinde bitki, altında ahşap kaide; arkasında yumuşak hale.
struct CamKubbe<Icerik: View>: View {
    var hale: Color = Color(r: 120, g: 255, b: 180, a: 0.28)
    @ViewBuilder var icerik: () -> Icerik

    var body: some View {
        ZStack(alignment: .top) {
            UnevenRoundedRectangle(topLeadingRadius: 125, bottomLeadingRadius: 36, bottomTrailingRadius: 36, topTrailingRadius: 125)
                .fill(RadialGradient(colors: [hale, hale.opacity(0)], center: UnitPoint(x: 0.5, y: 0.6), startRadius: 0, endRadius: 160))
                .frame(width: 250, height: 270)
            Color.clear
                .frame(width: 222, height: 254)
                .glassEffect(.regular.tint(Color.white.opacity(0.05)), in: UnevenRoundedRectangle(topLeadingRadius: 111, bottomLeadingRadius: 30, bottomTrailingRadius: 30, topTrailingRadius: 111))
                .padding(.top, 8)
            icerik()
                .frame(width: 200, height: 240)
                .padding(.top, 20)
            Capsule()
                .fill(LinearGradient(colors: [Color(hex: "#8A5E3C"), Color(hex: "#4A2F1E")], startPoint: .top, endPoint: .bottom))
                .overlay(alignment: .top) { Capsule().fill(Color(r: 255, g: 220, b: 180, a: 0.35)).frame(height: 2).padding(.horizontal, 14).padding(.top, 1) }
                .frame(width: 242, height: 30)
                .shadow(color: .black.opacity(0.4), radius: 10, y: 10)
                .padding(.top, 254)
        }
        .frame(width: 250, height: 290)
    }
}

/// Evre şeridi: her evre süresi kadar yer kaplar; dolu kısım geçen süre.
struct EvreSeridi: View {
    @Environment(\.palet) private var palet
    let tur: BitkiTuru
    let plan: Int
    var dk: Double? = nil

    var body: some View {
        let p = Double(plan)
        let evreler = tur.evreler.filter { $0.bas < p }
        GeometryReader { g in
            let bosluk: CGFloat = 4
            let kullanilir = g.size.width - bosluk * CGFloat(max(0, evreler.count - 1))
            HStack(alignment: .top, spacing: bosluk) {
                ForEach(evreler, id: \.self) { e in
                    let son = min(e.son, p)
                    let dolu = dk.map { max(0, min(1, ($0 - e.bas) / max(0.01, son - e.bas))) } ?? 0
                    let simdi = dk.map { $0 >= e.bas && $0 < son } ?? false
                    VStack(alignment: .leading, spacing: 5) {
                        IlerlemeCubugu(oran: dolu, yukseklik: 7)
                        Text(e.ad).font(.kalin(10.5)).lineLimit(1).minimumScaleFactor(0.6)
                            .foregroundStyle(simdi ? palet.vurgu : Color.primary.opacity(0.85))
                        Text("\(Int(e.bas))–\(Int(son)) dk").font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary)
                            .lineLimit(1).minimumScaleFactor(0.6)
                    }
                    .frame(width: max(24, kullanilir * CGFloat((son - e.bas) / p)), alignment: .leading)
                }
            }
        }
        .frame(height: 46)
    }
}

// MARK: Kurulum

struct OdakKurulum: View {
    @Environment(Depo.self) private var depo
    @Environment(OdakMotoru.self) private var odak
    @Environment(SesMotoru.self) private var ses
    @Environment(Yonlendirici.self) private var yon
    @Environment(\.palet) private var palet

    @State private var tur = ""
    @State private var plan = 25
    @State private var konu: UUID?
    @State private var ad = ""
    @State private var ozet = ""
    @State private var zipla = false

    private var acikTurler: [BitkiTuru] { BitkiKatalogu.tumu.filter { depo.acikMi($0.id) } }
    private var secili: BitkiTuru? { BitkiKatalogu.bul(tur) }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ustSerit
                ikinciSatir
                CamKubbe {
                    if !tur.isEmpty {
                        BitkiResmi(tur: tur, dk: Double(plan), tohum: 7, cerceve: OdakCercevesi.kubbe)
                            .scaleEffect(zipla ? 1.04 : 1, anchor: .bottom)
                    }
                }
                .padding(.top, 4)
                if let b = secili {
                    VStack(spacing: 2) {
                        Text("\(plan) DK SONUNDA · \(b.evre(Double(plan) - 0.01).evre.ad.uppercased(with: Locale(identifier: "tr_TR")))")
                            .font(.kalin(13)).tracking(1.2).foregroundStyle(palet.vurgu)
                            .lineLimit(1).minimumScaleFactor(0.7)
                        Text("\(plan):00")
                            .font(.system(size: 50, weight: .heavy)).monospacedDigit().tracking(-1.5)
                            .contentTransition(.numericText(value: Double(plan)))
                            .padding(.horizontal, 22)
                            .glassEffect(palet.cam(), in: .capsule)
                            .padding(.vertical, 4)
                        Text(altYazi(b)).font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    EvreSeridi(tur: b, plan: plan).padding(.horizontal, 4).padding(.top, 6)
                }
                sureSecici
                turSecici
                TextField("Oturum adı (isteğe bağlı)", text: $ad)
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 18)
                    .frame(height: 44)
                    .glassEffect(palet.cam(), in: .capsule)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            AnaDugme(baslik: "BAŞLAT · \(plan) dk", yukseklik: 40, eylem: baslat)
                .disabled(secili == nil)
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
        }
        .onAppear {
            if tur.isEmpty {
                tur = depo.acikMi(depo.kayit.sonTur) ? depo.kayit.sonTur : (acikTurler.first?.id ?? "papatya")
                plan = depo.kayit.sonPlan
                konu = konu ?? depo.kayit.konular.first?.id
            }
        }
        .task(id: "\(tur)-\(plan)") {
            guard !tur.isEmpty else { return }
            let t = tur, p = Double(plan)
            ozet = await Task.detached { BitkiMotoru.ortak.ozet(tur: t, dk: p) }.value
        }
    }

    private func altYazi(_ b: BitkiTuru) -> String {
        let parcalar = ozet.components(separatedBy: " · ")
        guard parcalar.count > 1 else { return "Süreyi artırdıkça bitki büyür" }
        let kalan = parcalar.dropFirst().joined(separator: " · ")
        return kalan.contains("tam formuna") ? kalan.prefix(1).uppercased() + kalan.dropFirst() : "Süreyi artırdıkça bitki büyür: \(kalan)"
    }

    private var ustSerit: some View {
        HStack(spacing: 8) {
            Button { yon.odakAcik = false } label: {
                Image(systemName: "xmark").font(.system(size: 15, weight: .bold)).frame(width: 44, height: 44).contentShape(Circle())
            }
            .buttonStyle(.plain)
            .glassEffect(palet.cam(etkilesimli: true), in: .circle)
            .accessibilityLabel("Kapat")
            let konular = depo.kayit.konular
            if konular.count <= 5, !konular.isEmpty {
                CamSegment(secenekler: konular.map(\.id), secili: Binding(get: { konu ?? konular[0].id }, set: { konu = $0 }),
                           ad: { id in konular.first { $0.id == id }?.ad ?? "" })
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(konular) { k in
                            KonuCipi(ad: k.ad, renk: Color(hex: k.renk), secili: konu == k.id) { konu = k.id }
                        }
                    }
                }
                .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            }
        }
    }

    private var ikinciSatir: some View {
        HStack(spacing: 8) {
            Text(depo.konu(konu)?.aciklama ?? "")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            NavigationLink(value: Rota.konular) {
                Image(systemName: "slider.horizontal.3").font(.system(size: 13, weight: .bold)).frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .glassEffect(palet.cam(etkilesimli: true), in: .circle)
            .accessibilityLabel("Konuları düzenle")
            NavigationLink(value: Rota.sesler) {
                HStack(spacing: 6) {
                    Image(systemName: ses.caliyor ? "speaker.wave.2.fill" : "speaker.wave.2")
                        .symbolEffect(.variableColor.iterative, isActive: ses.caliyor)
                    Text(sesEtiketi).lineLimit(1)
                }
                .font(.system(size: 12.5, weight: .heavy))
                .padding(.horizontal, 12)
                .frame(height: 34)
            }
            .buttonStyle(.plain)
            .glassEffect(palet.cam(etkilesimli: true), in: .capsule)
        }
    }

    private var sesEtiketi: String {
        guard let ilk = SesTuru.tumu.first(where: { ses.katman[$0.id] != nil }) else { return "Sesler" }
        return ses.katman.count > 1 ? "\(ilk.ad) +\(ses.katman.count - 1)" : ilk.ad
    }

    private var sureSecici: some View {
        HStack(spacing: 8) {
            Button { sureyiDegistir(-5) } label: {
                Image(systemName: "minus").font(.system(size: 16, weight: .bold)).frame(width: 38, height: 38).contentShape(Circle())
            }
            .buttonStyle(.plain)
            .glassEffect(palet.cam(etkilesimli: true), in: .circle)
            .accessibilityLabel("Süreyi 5 dakika azalt")
            Slider(value: Binding(get: { Double(plan) }, set: { yeni in
                let v = Int(yeni)
                if v != plan { plan = v; Dokunsal.hafif(0.3) }
            }), in: 10...120, step: 5)
            .tint(palet.cubuk.last ?? palet.vurgu)
            Text("\(plan) dk").font(.kalin(16)).monospacedDigit().frame(width: 58)
            Button { sureyiDegistir(5) } label: {
                Image(systemName: "plus").font(.system(size: 16, weight: .bold)).frame(width: 38, height: 38).contentShape(Circle())
            }
            .buttonStyle(.plain)
            .glassEffect(palet.cam(etkilesimli: true), in: .circle)
            .accessibilityLabel("Süreyi 5 dakika artır")
        }
        .padding(6)
        .glassEffect(palet.cam(), in: .capsule)
    }

    private func sureyiDegistir(_ d: Int) {
        let v = min(120, max(10, plan + d))
        guard v != plan else { return }
        withAnimation(.snappy) { plan = v }
        Dokunsal.hafif(0.5)
    }

    private var turSecici: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(acikTurler) { b in
                    let on = tur == b.id
                    Button {
                        tur = b.id
                        Dokunsal.hafif(0.5)
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { zipla = true }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.15)) { zipla = false }
                    } label: {
                        VStack(spacing: 1) {
                            BitkiResmi(tur: b.id, dk: Double(b.dk), tohum: 3, lod: 0.5, sigdir: true)
                                .frame(width: 40, height: 42)
                            Text(b.ad).font(.kalin(10)).lineLimit(1).minimumScaleFactor(0.7)
                        }
                        .frame(width: 58, height: 64)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(on ? 0.26 : 0.05)))
                        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(on ? (palet.cubuk.first ?? palet.vurgu) : .clear, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(b.ad)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
                NavigationLink(value: Rota.koleksiyon) {
                    VStack(spacing: 4) {
                        Image(systemName: "square.grid.2x2").font(.system(size: 18, weight: .semibold))
                        Text("Koleksiyon").font(.kalin(10)).lineLimit(1).minimumScaleFactor(0.7)
                    }
                    .frame(width: 66, height: 64)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.05)))
                }
                .buttonStyle(.plain)
            }
            .padding(6)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .glassEffect(palet.cam(), in: .rect(cornerRadius: 26))
    }

    private func baslat() {
        guard secili != nil else { return }
        odak.baslat(tur: tur, plan: plan, konu: konu, ad: ad.trimmingCharacters(in: .whitespacesAndNewlines))
        ad = ""
    }
}

struct KonuCipi: View {
    let ad: String
    let renk: Color
    let secili: Bool
    let sec: () -> Void
    @Environment(\.palet) private var palet
    var body: some View {
        Button(action: sec) {
            HStack(spacing: 6) {
                Circle().fill(renk).frame(width: 8, height: 8)
                Text(ad).font(.system(size: 13, weight: .bold))
            }
            .padding(.horizontal, 12)
            .frame(height: 34)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(secili ? Glass.regular.tint(renk.opacity(0.45)).interactive() : palet.cam(etkilesimli: true), in: .capsule)
        .accessibilityAddTraits(secili ? .isSelected : [])
    }
}

// MARK: Çalışırken

struct OdakCalisiyor: View {
    @Environment(OdakMotoru.self) private var odak
    @Environment(Depo.self) private var depo
    @Environment(SesMotoru.self) private var ses
    @Environment(\.palet) private var palet
    @State private var bitirSor = false
    @State private var belir = false

    var body: some View {
        if let d = odak.devam, let b = BitkiKatalogu.bul(d.tur) {
            TimelineView(.periodic(from: .now, by: 1)) { an in
                let gecenSn = min(Double(d.plan) * 60, d.gecenSn(an.date))
                let gecen = gecenSn / 60
                let kalan = max(0, Int((Double(d.plan) * 60 - gecenSn).rounded(.up)))
                let e = b.evre(min(gecen, Double(d.plan) - 0.001))
                VStack(spacing: 10) {
                    ust(d)
                    Spacer(minLength: 0)
                    CamKubbe(hale: kalan < 120 ? Color(r: 170, g: 255, b: 200, a: 0.6) : Color(r: 120, g: 255, b: 180, a: 0.28)) {
                        BitkiResmi(tur: d.tur, dk: (gecen * 4).rounded(.down) / 4, tohum: d.tohum, cerceve: OdakCercevesi.kubbe)
                            .scaleEffect(belir ? 1 : 0.4, anchor: .bottom)
                            .opacity(belir ? 1 : 0)
                    }
                    evreNoktalari(b, d.plan, e.evre)
                    if d.molada, let mb = d.molaBas {
                        let m = max(0, Int(OdakMotoru.molaSiniri - an.date.timeIntervalSince(mb)))
                        Text("MOLA").font(.kalin(13)).tracking(1.2).foregroundStyle(palet.vurgu)
                        Text(String(format: "%d:%02d", m / 60, m % 60))
                            .font(.system(size: 64, weight: .heavy)).monospacedDigit().tracking(-2)
                        Text("Mola bitince sayaç kaldığı yerden sürer").font(.system(size: 14, weight: .semibold)).foregroundStyle(.secondary)
                    } else {
                        Text(String(format: "%d:%02d", kalan / 60, kalan % 60))
                            .font(.system(size: 64, weight: .heavy)).monospacedDigit().tracking(-2)
                            .contentTransition(.numericText(countsDown: true))
                        Text("kalan · \(e.evre.ad.lowercased(with: Locale(identifier: "tr_TR")))")
                            .font(.system(size: 14, weight: .semibold)).foregroundStyle(.secondary)
                    }
                    if let s = OdakCalisiyor.ayet {
                        (Text("“\(s.soz)” ").font(.system(size: 14, design: .serif).italic())
                         + Text(s.kaynak.uppercased(with: Locale(identifier: "tr_TR"))).font(.system(size: 11, weight: .heavy)))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 6)
                    }
                    Spacer(minLength: 0)
                    dugmeler(d)
                    Text(d.molada ? "Molada uygulamadan çıkabilirsin." : d.kati ? "Ekranı kilitleyebilirsin. Başka uygulamaya geçersen bitki kurur." : "Rahat kip: uygulamadan çıkmak bitkiyi kurutmaz.")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .confirmationDialog("Odağı bitirmek istiyor musun?", isPresented: $bitirSor, titleVisibility: .visible) {
                Button("Bitir, bitki kurusun", role: .destructive) { odak.vazgec() }
                Button("Devam et", role: .cancel) {}
            } message: {
                Text("Süre dolmadan bitirirsen bitki kurur. Kuru dal bahçende kalır; aynı süreyle yeniden yeşertebilirsin.")
            }
            .task(id: d.tur) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) { belir = true }
            }
        }
    }

    /// Odak sırasında gösterilen kısa âyet (kaynağı doğrulanmış sözlerden).
    static let ayet: Soz? = Icerik.gunun(Icerik.sozler.filter { $0.ayetMi && $0.soz.count <= 90 })

    private func ust(_ d: DevamEdenOdak) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                if let k = depo.konu(d.konu) {
                    HStack(spacing: 6) {
                        Circle().fill(Color(hex: k.renk)).frame(width: 8, height: 8)
                        Text(k.ad).font(.kalin(13))
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .glassEffect(palet.cam(), in: .capsule)
                }
                Spacer()
                NavigationLink(value: Rota.sesler) {
                    Image(systemName: ses.caliyor ? "speaker.wave.2.fill" : "speaker.wave.2")
                        .symbolEffect(.variableColor.iterative, isActive: ses.caliyor)
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .glassEffect(palet.cam(etkilesimli: true), in: .circle)
                .accessibilityLabel("Sesler")
            }
            if !d.ad.isEmpty {
                Text(d.ad).font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
            }
        }
    }

    private func evreNoktalari(_ b: BitkiTuru, _ plan: Int, _ simdiki: Evre) -> some View {
        let evreler = b.evreler.filter { $0.bas < Double(plan) }
        let i = evreler.firstIndex(of: simdiki) ?? 0
        return HStack(spacing: 10) {
            ForEach(Array(evreler.enumerated()), id: \.offset) { k, e in
                HStack(spacing: 4) {
                    Circle().fill(k <= i ? (palet.cubuk.first ?? palet.vurgu) : Color.primary.opacity(0.25)).frame(width: 7, height: 7)
                    Text(e.ad).font(.system(size: 11, weight: k == i ? .heavy : .semibold))
                        .foregroundStyle(k == i ? Color.primary : Color.secondary)
                        .lineLimit(1)
                }
            }
        }
        .minimumScaleFactor(0.7)
        .padding(.top, 4)
    }

    @ViewBuilder
    private func dugmeler(_ d: DevamEdenOdak) -> some View {
        HStack(spacing: 10) {
            if d.molada {
                AnaDugme(baslik: "DEVAM", yukseklik: 40) { odak.molayiBitir() }
                    .layoutPriority(1)
            } else {
                Button { odak.molaVer() } label: {
                    Text("Mola · 5 dk").font(.kalin(16)).tracking(0.4).frame(maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(.glass)
                .controlSize(.large)
            }
            Button { bitirSor = true } label: {
                Text("Bitir").font(.kalin(16)).tracking(0.4).frame(maxWidth: .infinity, minHeight: 40)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
        }
    }
}

// MARK: Sonuç

struct OdakSonuc: View {
    let oturum: OdakOturumu
    let basarili: Bool
    @Environment(OdakMotoru.self) private var odak
    @Environment(Depo.self) private var depo
    @Environment(Yonlendirici.self) private var yon
    @Environment(\.palet) private var palet
    @State private var goster = false
    @State private var konfeti = false
    @State private var ozet = ""

    var body: some View {
        let ad = BitkiKatalogu.ad(oturum.tur)
        let dk = basarili ? Double(oturum.plan) : max(1, oturum.sure)
        VStack(spacing: 12) {
            HStack {
                Spacer()
                Button { kapat() } label: {
                    Image(systemName: "xmark").font(.system(size: 15, weight: .bold)).frame(width: 44, height: 44).contentShape(Circle())
                }
                .buttonStyle(.plain)
                .glassEffect(palet.cam(etkilesimli: true), in: .circle)
                .accessibilityLabel("Kapat")
            }
            Spacer(minLength: 0)
            CamKubbe(hale: basarili ? Color(r: 170, g: 255, b: 200, a: 0.6) : Color(r: 200, g: 170, b: 120, a: 0.25)) {
                BitkiResmi(tur: oturum.tur, dk: dk, tohum: oturum.tohum, cerceve: OdakCercevesi.kubbe, kurudu: !basarili)
                    .scaleEffect(goster ? 1 : 0.7, anchor: .bottom)
            }
            Text(basarili ? "BAHÇEYE HAZIR" : "KURU DAL")
                .font(.kalin(13)).tracking(1.2).foregroundStyle(basarili ? palet.vurgu : Color(hex: "#E8C38A"))
            Text(basarili ? ad : "Bitki kurudu")
                .font(.system(size: 34, weight: .heavy)).tracking(-0.6)
            Text(basarili ? "\(ozet.isEmpty ? ad : ozet) · \(oturum.plan) dk" : "Odak \(oturum.sure.sureMetni) sürdü. Aynı süreyle bir oturum bu dalı yeniden yeşertir.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
            if basarili, oturum.kazanc > 0 {
                Label("+\(oturum.kazanc) tohum", systemImage: "leaf.circle.fill")
                    .font(.kalin(15))
                    .foregroundStyle(palet.vurgu)
                    .padding(.horizontal, 16).frame(height: 40)
                    .glassEffect(.regular.tint(palet.dolgu.opacity(0.25)), in: .capsule)
                    .scaleEffect(goster ? 1 : 0.3)
                if let siradaki = BitkiKatalogu.tumu.filter({ !depo.acikMi($0.id) && $0.fiyat <= depo.kayit.tohum }).min(by: { $0.fiyat < $1.fiyat }) {
                    Text("\(siradaki.ad) için yeterli tohumun var.").font(.system(size: 12.5, weight: .semibold)).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            HStack(spacing: 10) {
                if basarili {
                    AnaDugme(baslik: "BAHÇEYE DİK", yukseklik: 40) { kapat(bahce: true) }
                        .layoutPriority(1)
                    Button { odak.kapat() } label: {
                        Text("Yeni").font(.kalin(16)).frame(maxWidth: .infinity, minHeight: 40)
                    }
                    .buttonStyle(.glass).controlSize(.large)
                } else {
                    AnaDugme(baslik: "İHYA ET · \(oturum.plan) dk", yukseklik: 40) {
                        odak.kapat()
                        odak.baslat(tur: oturum.tur, plan: oturum.plan, konu: oturum.konu, ad: oturum.ad, ihya: oturum.id)
                    }
                    .layoutPriority(1)
                    Button { kapat(bahce: true) } label: {
                        Text("Bahçe").font(.kalin(16)).frame(maxWidth: .infinity, minHeight: 40)
                    }
                    .buttonStyle(.glass).controlSize(.large)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .overlay { if konfeti { KonfetiYagmuru() } }
        .task {
            let t = oturum.tur, p = Double(oturum.plan)
            ozet = await Task.detached { BitkiMotoru.ortak.ozet(tur: t, dk: p) }.value
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55)) { goster = true }
            if basarili {
                konfeti = true
                try? await Task.sleep(nanoseconds: 3_600_000_000)
                konfeti = false
            }
        }
    }

    private func kapat(bahce: Bool = false) {
        odak.kapat()
        yon.odakAcik = false
        if bahce { yon.sekme = .bahce; yon.bahceYol = [] }
    }
}
