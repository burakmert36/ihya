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

// MARK: Kurulum

struct OdakKurulum: View {
    @Environment(Depo.self) private var depo
    @Environment(OdakMotoru.self) private var odak
    @Environment(SesMotoru.self) private var ses

    @State private var tur = ""
    @State private var plan = 25
    @State private var konu: UUID?
    @State private var ad = ""
    @State private var cerceve = OdakCercevesi.varsayilan
    @State private var zipla = false

    private var acikTurler: [BitkiTuru] { BitkiKatalogu.tumu.filter { depo.acikMi($0.id) } }
    private var secili: BitkiTuru? { BitkiKatalogu.bul(tur) }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                onizleme
                turSecici
                sureSecici
                konuSecici
                TextField("Oturum adı (isteğe bağlı)", text: $ad)
                    .textFieldStyle(.plain)
                    .padding(14)
                    .glassEffect(.regular, in: .rect(cornerRadius: 16))
                Button(action: baslat) {
                    Text("Başla").font(.headline).frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.extraLarge)
                .disabled(secili == nil)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Odak")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HStack(spacing: 4) {
                    Image(systemName: "leaf.circle.fill")
                    Text("\(depo.kayit.tohum)").monospacedDigit()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.ihya)
                .fixedSize()
                .padding(.horizontal, 4)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(depo.kayit.tohum) tohum")
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink(value: Rota.sesler) { Image(systemName: ses.caliyor ? "speaker.wave.2.fill" : "speaker.wave.2") }
                    .accessibilityLabel("Sesler")
                NavigationLink(value: Rota.koleksiyon) { Image(systemName: "square.grid.2x2") }
                    .accessibilityLabel("Koleksiyon")
            }
        }
        .onAppear {
            if tur.isEmpty {
                tur = depo.acikMi(depo.kayit.sonTur) ? depo.kayit.sonTur : (acikTurler.first?.id ?? "papatya")
                plan = depo.kayit.sonPlan
            }
        }
        .task(id: "\(tur)-\(plan)") {
            guard !tur.isEmpty else { return }
            let b = await BitkiMotoru.ortak.sinir(tur: tur, dk: Double(plan), tohum: 7)
            withAnimation(.easeInOut(duration: 0.35)) { cerceve = OdakCercevesi.hesapla(b) }
        }
    }

    private var onizleme: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .bottom) {
                ToprakAdasi().frame(width: 230).offset(y: 10)
                if !tur.isEmpty {
                    BitkiResmi(tur: tur, dk: Double(plan), tohum: 7, cerceve: cerceve)
                        .frame(width: 250, height: 270)
                        .scaleEffect(zipla ? 1.04 : 1, anchor: .bottom)
                }
            }
            .frame(height: 290)
            if let b = secili {
                let e = b.evre(Double(plan) - 0.01)
                Text(e.evre.ad).font(.title3.weight(.semibold))
                Text(plan < b.dk ? "\(b.ad) \(b.dk) dk’da tam açar" : "+\(OdakMotoru.tohumKazanci(plan)) tohum")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 6)
    }

    private var turSecici: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(acikTurler) { b in
                    Button {
                        tur = b.id
                        Dokunsal.hafif(0.5)
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { zipla = true }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.15)) { zipla = false }
                    } label: {
                        VStack(spacing: 4) {
                            BitkiResmi(tur: b.id, dk: Double(b.dk), tohum: 7, lod: 0.6, sigdir: true)
                                .frame(width: 54, height: 62)
                            Text(b.ad).font(.caption2).lineLimit(1)
                        }
                        .frame(width: 72)
                        .padding(.vertical, 8)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(tur == b.id ? Color.ihya.opacity(0.16) : Color.clear)
                                .stroke(tur == b.id ? Color.ihya : Color.clear, lineWidth: 1.5)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
    }

    private var sureSecici: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(plan)").font(.system(size: 44, weight: .semibold, design: .rounded)).monospacedDigit()
                    .contentTransition(.numericText(value: Double(plan)))
                Text("dakika").font(.headline).foregroundStyle(.secondary)
                Spacer()
            }
            Slider(value: Binding(get: { Double(plan) }, set: { yeni in
                let v = Int(yeni)
                if v != plan { plan = v; Dokunsal.hafif(0.3) }
            }), in: 10...120, step: 5)
            HStack {
                Text("10 dk"); Spacer(); Text("120 dk")
            }
            .font(.caption).foregroundStyle(.secondary)
        }
        .camKart()
    }

    private var konuSecici: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                BolumBasligi(metin: "Konu", simge: "tag")
                NavigationLink(value: Rota.konular) { Text("Düzenle").font(.footnote) }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    KonuCipi(ad: "Konusuz", renk: .secondary, secili: konu == nil) { konu = nil }
                    ForEach(depo.kayit.konular) { k in
                        KonuCipi(ad: k.ad, renk: Color(hex: k.renk), secili: konu == k.id) { konu = k.id }
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            if let k = depo.konu(konu), !k.aciklama.isEmpty {
                Text(k.aciklama).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .camKart()
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
    var body: some View {
        Button(action: sec) {
            HStack(spacing: 6) {
                Circle().fill(renk).frame(width: 8, height: 8)
                Text(ad).font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(secili ? renk.opacity(0.18) : Color.secondary.opacity(0.08)))
            .overlay(Capsule().stroke(secili ? renk : .clear, lineWidth: 1.2))
        }
        .buttonStyle(.plain)
    }
}

// MARK: Çalışırken

struct OdakCalisiyor: View {
    @Environment(OdakMotoru.self) private var odak
    @Environment(Depo.self) private var depo
    @State private var cerceve = OdakCercevesi.varsayilan
    @State private var vazgecSor = false
    @State private var belir = false

    var body: some View {
        if let d = odak.devam {
            TimelineView(.periodic(from: .now, by: 1)) { an in
                let gecen = min(Double(d.plan), max(0, an.date.timeIntervalSince(d.baslangic) / 60))
                VStack(spacing: 18) {
                    VStack(spacing: 4) {
                        if let k = depo.konu(d.konu) {
                            KonuCipi(ad: k.ad, renk: Color(hex: k.renk), secili: true) {}
                                .allowsHitTesting(false)
                        }
                        if !d.ad.isEmpty { Text(d.ad).font(.headline) }
                    }
                    .frame(minHeight: 44)
                    Spacer(minLength: 0)
                    ZStack(alignment: .bottom) {
                        ToprakAdasi().frame(width: 250).offset(y: 10)
                        BitkiResmi(tur: d.tur, dk: (gecen * 4).rounded(.down) / 4, tohum: d.tohum, cerceve: cerceve)
                            .frame(width: 280, height: 320)
                            .scaleEffect(belir ? 1 : 0.4, anchor: .bottom)
                            .opacity(belir ? 1 : 0)
                    }
                    .frame(height: 330)
                    Text(timerInterval: d.baslangic...d.bitis, countsDown: true)
                        .font(.system(size: 56, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    if let b = BitkiKatalogu.bul(d.tur) {
                        EvreCubugu(tur: b, dk: gecen, plan: d.plan)
                    }
                    Spacer(minLength: 0)
                    Button("Vazgeç", role: .destructive) { vazgecSor = true }
                        .buttonStyle(.glass)
                        .controlSize(.large)
                    Text(d.kati ? "Ekranı kilitleyebilirsin. Başka uygulamaya geçersen bitki kurur." : "Rahat kip: uygulamadan çıkmak bitkiyi kurutmaz.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .toolbar(.hidden, for: .tabBar)
            .confirmationDialog("Odağı bırakmak istiyor musun?", isPresented: $vazgecSor, titleVisibility: .visible) {
                Button("Vazgeç, bitki kurusun", role: .destructive) { odak.vazgec() }
                Button("Devam et", role: .cancel) {}
            } message: {
                Text("Şimdiye kadar geçen süre bahçende kuru bir bitki olarak kalır.")
            }
            .task(id: d.tur) {
                let b = await BitkiMotoru.ortak.sinir(tur: d.tur, dk: Double(d.plan), tohum: d.tohum)
                cerceve = OdakCercevesi.hesapla(b)
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) { belir = true }
            }
        }
    }
}

/// Evre çubuğu: ilerleme ve evre sınırları; yazılar üst üste binmesin diye yalnız şimdiki ve sıradaki evre yazılır.
struct EvreCubugu: View {
    let tur: BitkiTuru
    let dk: Double
    let plan: Int

    var body: some View {
        let p = Double(plan)
        let sinirlar = tur.evreler.map(\.bas).filter { $0 > 0 && $0 < p }
        let e = tur.evre(min(dk, p - 0.001))
        VStack(spacing: 8) {
            GeometryReader { g in
                let w = g.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.18))
                    Capsule().fill(Color(hex: tur.renk).gradient).frame(width: max(10, w * dk / p))
                    ForEach(sinirlar, id: \.self) { s in
                        Circle().fill(.background).frame(width: 5, height: 5).offset(x: w * s / p - 2.5)
                    }
                }
            }
            .frame(height: 10)
            HStack {
                Text(e.evre.ad).font(.subheadline.weight(.semibold))
                Spacer()
                if let s = e.sonraki, s.bas < p {
                    Text("Sıradaki: \(s.ad) · \(max(1, Int(ceil(s.bas - dk)))) dk")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
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
    @State private var cerceve = OdakCercevesi.varsayilan
    @State private var goster = false
    @State private var konfeti = false

    var body: some View {
        let ad = BitkiKatalogu.ad(oturum.tur)
        VStack(spacing: 18) {
            Spacer(minLength: 0)
            ZStack(alignment: .bottom) {
                if basarili {
                    Circle()
                        .fill(RadialGradient(colors: [Color.ihya.opacity(0.28), .clear], center: .center, startRadius: 10, endRadius: 170))
                        .frame(width: 340, height: 340)
                        .offset(y: -20)
                        .scaleEffect(goster ? 1 : 0.5)
                }
                ToprakAdasi().frame(width: 250).offset(y: 10)
                BitkiResmi(tur: oturum.tur, dk: basarili ? Double(oturum.plan) : max(1, oturum.sure), tohum: oturum.tohum, cerceve: cerceve, kurudu: !basarili)
                    .frame(width: 280, height: 320)
                    .scaleEffect(goster ? 1 : 0.7, anchor: .bottom)
            }
            .frame(height: 340)
            VStack(spacing: 6) {
                Text(basarili ? "Tamamlandı" : "Bitki kurudu").font(.largeTitle.weight(.bold))
                Text(basarili ? "\(ad) bahçene eklendi · \(oturum.plan) dk" : "Odak \(oturum.sure.sureMetni) sürdü. Kuru bitki bahçende kalır.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            if basarili, oturum.kazanc > 0 {
                Label("+\(oturum.kazanc) tohum", systemImage: "leaf.circle.fill")
                    .font(.headline)
                    .foregroundStyle(Color.ihya)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .glassEffect(.regular.tint(Color.ihya.opacity(0.2)), in: .capsule)
                    .scaleEffect(goster ? 1 : 0.3)
                if let siradaki = BitkiKatalogu.tumu.filter({ !depo.acikMi($0.id) && $0.fiyat <= depo.kayit.tohum }).min(by: { $0.fiyat < $1.fiyat }) {
                    Text("\(siradaki.ad) için yeterli tohumun var.").font(.footnote).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            VStack(spacing: 10) {
                Button { odak.kapat() } label: { Text("Tamam").font(.headline).frame(maxWidth: .infinity) }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                Button {
                    odak.kapat()
                    yon.sekme = .bahce
                } label: { Text("Bahçeye git").frame(maxWidth: .infinity) }
                    .buttonStyle(.glass)
                    .controlSize(.large)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .overlay { if konfeti { KonfetiYagmuru() } }
        .task {
            let b = await BitkiMotoru.ortak.sinir(tur: oturum.tur, dk: Double(oturum.plan), tohum: oturum.tohum)
            cerceve = OdakCercevesi.hesapla(b)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55)) { goster = true }
            if basarili {
                konfeti = true
                try? await Task.sleep(nanoseconds: 3_600_000_000)
                konfeti = false
            }
        }
    }
}
