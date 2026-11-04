import SwiftUI

/// Kur'an sekmesi: kaldığın yer, huzur modu, sûre ve cüz listesi.
struct KuranEkrani: View {
    @Environment(Depo.self) private var depo
    @Environment(Yonlendirici.self) private var yon
    @Environment(\.palet) private var palet
    @State private var kuran = KuranDeposu.ortak
    @State private var cuzler = false
    @State private var arama = ""
    @State private var bulunan: [AyetYeri] = []

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                SahneBasligi(baslik: "Kur'an-ı Kerîm") {
                    Text("Diyanet meali").font(.system(size: 12, weight: .bold)).foregroundStyle(.secondary).padding(.bottom, 6)
                }
                if kuran.hazir {
                    kaldigin
                    DinleKarti()
                    huzur
                    CamSegment(secenekler: [false, true], secili: $cuzler, ad: { $0 ? "Cüzler" : "Sûreler" })
                    if cuzler {
                        ForEach(kuran.cuzBaslari, id: \.cuz) { c in
                            NavigationLink(value: Rota.sure(c.sure, c.ayet)) {
                                satir(no: c.cuz, ad: "\(c.cuz). Cüz", alt: "\(kuran.sure(c.sure)?.ad ?? "") \(c.ayet). âyetten", arapca: nil)
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        aramaAlani
                        if let y = dogrudan {
                            NavigationLink(value: Rota.sure(y.sure, y.ayet)) {
                                satir(no: y.sure, ad: "\(kuran.sure(y.sure)?.ad ?? "") \(y.ayet). âyet", alt: "Âyete git", arapca: kuran.sure(y.sure)?.arapca)
                            }
                            .buttonStyle(.plain)
                        }
                        ForEach(suzulmus) { s in
                            NavigationLink(value: Rota.sure(s.no, 1)) {
                                satir(no: s.no, ad: s.ad, alt: "\(s.mekki ? "Mekkî" : "Medenî") · \(s.ayetSayisi) âyet", arapca: s.arapca)
                            }
                            .buttonStyle(.plain)
                        }
                        if !bulunan.isEmpty {
                            BolumBasligi(metin: "Mealde · \(bulunan.count >= 80 ? "80+" : "\(bulunan.count)") âyet", simge: "text.magnifyingglass")
                                .padding(.top, 8)
                            ForEach(bulunan, id: \.self) { y in
                                NavigationLink(value: Rota.sure(y.sure, y.ayet)) { AyetSonucu(yer: y, arama: arama) }
                                    .buttonStyle(.plain)
                            }
                        } else if arama.trimmingCharacters(in: .whitespaces).count >= 3, suzulmus.isEmpty, dogrudan == nil {
                            Text("“\(arama)” mealde geçmiyor.").font(.system(size: 14, weight: .semibold)).foregroundStyle(.secondary).padding(.top, 20)
                        }
                    }
                } else {
                    KuranIndirme(kuran: kuran)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        .altCubukPayi()
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await kuran.hazirla()
            if let o = yon.kuranAramaOrnegi { arama = o; yon.kuranAramaOrnegi = nil }
        }
        .task(id: arama) {
            let q = arama
            guard q.trimmingCharacters(in: .whitespaces).count >= 3, Int(q) == nil else { bulunan = []; return }
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            bulunan = kuran.ara(q)
        }
    }

    /// "36:12", "36 12" ya da "36.12" yazınca doğrudan âyete gider.
    private var dogrudan: AyetYeri? {
        let p = arama.split(whereSeparator: { ":. ".contains($0) }).compactMap { Int($0) }
        guard p.count == 2, (1...114).contains(p[0]), let s = kuran.sure(p[0]), (1...s.ayetSayisi).contains(p[1]) else { return nil }
        return AyetYeri(sure: p[0], ayet: p[1])
    }

    private var suzulmus: [Sure] {
        let q = arama.trimmingCharacters(in: .whitespaces).lowercased(with: Locale(identifier: "tr_TR"))
        guard !q.isEmpty else { return kuran.sureler }
        if let n = Int(q) { return kuran.sureler.filter { $0.no == n } }
        return kuran.sureler.filter { $0.ad.lowercased(with: Locale(identifier: "tr_TR")).contains(q) }
    }

    private var aramaAlani: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").font(.system(size: 15, weight: .semibold)).foregroundStyle(.secondary)
            TextField("Sûre, 36:12 ya da mealde kelime", text: $arama)
                .font(.system(size: 15, weight: .semibold))
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !arama.isEmpty {
                Button { arama = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Aramayı temizle")
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .camYuzey(palet.cam(), in: .capsule)
    }

    private var kaldigin: some View {
        let son = depo.kayit.kuranSon
        let s = son.first ?? 1, a = son.count > 1 ? son[1] : 1
        let oran = son.isEmpty ? 0 : kuran.oran(sure: s, ayet: a)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(son.isEmpty ? "BAŞLA" : "KALDIĞIN YER").font(.kalin(11)).tracking(1.2).foregroundStyle(.secondary)
                Spacer()
                (Text("Hatim ") + Text("%\(Int((oran * 100).rounded()))").foregroundStyle(palet.vurgu)).font(.kalin(13))
            }
            Text(son.isEmpty ? "Fâtiha, 1. âyet" : "\(kuran.sure(s)?.ad ?? ""), \(a). âyet").font(.system(size: 20, weight: .heavy))
            HStack(spacing: 12) {
                IlerlemeCubugu(oran: oran, yukseklik: 8)
                Button { yon.ac(.sure(s, a)) } label: {
                    Text(son.isEmpty ? "OKU" : "DEVAM ET").font(.kalin(14)).tracking(0.6).foregroundStyle(palet.dolguMetin).padding(.horizontal, 6).frame(minHeight: 28)
                }
                .buttonStyle(.glassProminent)
                .tint(palet.dolgu)
            }
        }
        .camKart(kose: 26)
    }

    private var huzur: some View {
        Button { yon.odakAc(konu: "Kur'an") } label: {
            HStack(spacing: 12) {
                FilizSimgesi().fill(Color(hex: "#7CF0A4")).frame(width: 22, height: 22)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color(hex: "#1FB25A").opacity(0.25)))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Huzur modunda oku").font(.kalin(15))
                    Text("Odak başlat; okudukça fidanın büyür").font(.system(size: 12.5, weight: .semibold)).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(.secondary)
            }
            .camKart(kose: 24, ic: 12)
        }
        .buttonStyle(.plain)
    }

    private func satir(no: Int, ad: String, alt: String, arapca: String?) -> some View {
        HStack(spacing: 12) {
            ZStack {
                SekizKoseYildiz(ic: 0.72).stroke(palet.vurgu.opacity(0.7), lineWidth: 1.2)
                Text("\(no)").font(.kalin(12)).monospacedDigit()
            }
            .frame(width: 38, height: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(ad).font(.kalin(16))
                Text(alt).font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            if let arapca {
                Text(arapca).font(.arapca(20)).foregroundStyle(palet.vurgu).lineLimit(1).minimumScaleFactor(0.6)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 62)
        .contentShape(Rectangle())
        .camYuzey(palet.cam(etkilesimli: true), in: .rect(cornerRadius: 20))
    }
}

/// Mealde bulunan bir âyet: yeri, Arapçası (kısaltılmış) ve aranan kelimesi vurgulanmış meali.
struct AyetSonucu: View {
    let yer: AyetYeri
    let arama: String
    @Environment(\.palet) private var palet
    @State private var kuran = KuranDeposu.ortak

    var body: some View {
        let v = kuran.ayet(yer)
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(kuran.sure(yer.sure)?.ad ?? "") \(yer.sure):\(v.map { $0.mealBas < $0.no ? "\($0.mealBas)-\($0.no)" : "\($0.no)" } ?? "\(yer.ayet)")")
                    .font(.kalin(13)).foregroundStyle(palet.vurgu)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundStyle(.secondary)
            }
            Text(vurgulu(v?.meal ?? "")).font(.okuma(15)).lineLimit(4).multilineTextAlignment(.leading)
        }
        .camKart(kose: 20, ic: 14)
    }

    private func vurgulu(_ m: String) -> AttributedString {
        var a = AttributedString(m)
        let q = arama.trimmingCharacters(in: .whitespaces)
        if let r = m.range(of: q, options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "tr_TR")),
           let ar = Range(r, in: a) {
            a[ar].foregroundColor = palet.vurgu
            a[ar].font = Font.okuma(15).bold()
        }
        return a
    }
}

/// İlk açılışta metnin indirilmesi.
struct KuranIndirme: View {
    let kuran: KuranDeposu
    @Environment(\.palet) private var palet

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "book.closed").font(.system(size: 36, weight: .semibold)).foregroundStyle(palet.vurgu)
            switch kuran.durum {
            case .iniyor(let o):
                Text("Kur'an metni indiriliyor").font(.kalin(17))
                ProgressView(value: o).tint(palet.vurgu)
                Text("Bir kez iner (yaklaşık 5 MB); sonra internetsiz okunur.").font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)
            case .hata(let m):
                Text(m).font(.system(size: 14, weight: .semibold)).multilineTextAlignment(.center)
                AnaDugme(baslik: "TEKRAR DENE", yukseklik: 30) { Task { await kuran.tekrarDene() } }
            default:
                ProgressView()
                Text("Hazırlanıyor…").font(.system(size: 14, weight: .semibold)).foregroundStyle(.secondary)
            }
            Text("Arapça metin: Kral Fahd Mushafı (Hafs). Meal: Diyanet İşleri Başkanlığı.").font(.system(size: 11.5, weight: .medium)).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .camKart(kose: 28, ic: 22)
        .padding(.top, 20)
    }
}

// MARK: Okuyucu

/// Sûre okuyucu: Arapça, isteğe bağlı okunuş ve meal; kaldığın yeri kendiliğinden saklar.
/// Tilavet çalarken okunan âyet vurgulanır ve ekranda tutulur.
struct KuranOkuyucu: View {
    let sure: Int
    var ayet: Int = 1
    @Environment(Depo.self) private var depo
    @Environment(Yonlendirici.self) private var yon
    @Environment(\.palet) private var palet
    @State private var kuran = KuranDeposu.ortak
    @State private var t = TilavetMotoru.ortak
    @State private var kaydirildi = false
    @State private var sonGorunen = 1

    private var buSure: Bool { t.etkin && t.sure == sure }

    var body: some View {
        let a = depo.ayarlar
        Group {
            if kuran.hazir, let s = kuran.sure(sure) {
                ScrollViewReader { okuyucu in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            baslik(s)
                            if sure != 1 && sure != 9 {
                                let okunuyor = buSure && t.ayet == 0
                                Text("بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ").font(.arapca(a.kuranPunto)).foregroundStyle(palet.vurgu)
                                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                                    .background {
                                        if okunuyor { RoundedRectangle(cornerRadius: 20).fill(palet.vurgu.opacity(0.14)) }
                                    }
                                    .animation(.easeInOut(duration: 0.3), value: okunuyor)
                                    .id(0)
                            }
                            ForEach(kuran.ayetleri(sure), id: \.no) { v in
                                ayetGorunumu(v, a)
                                    .id(v.no)
                                    .onAppear { kaydet(v.no) }
                            }
                            if sure < 114, let sonraki = kuran.sure(sure + 1) {
                                Button { yon.ac(.sure(sure + 1, 1)) } label: {
                                    Label("Sonraki: \(sonraki.ad)", systemImage: "arrow.right").font(.kalin(15)).frame(maxWidth: .infinity, minHeight: 34)
                                }
                                .buttonStyle(.glass).controlSize(.large)
                                .padding(.top, 8)
                            }
                            Text("Arapça metin: Kral Fahd Mushafı (Hafs). Meal: Diyanet İşleri Başkanlığı. Okunuş yaklaşık telaffuzdur. Tilavet kayıtları: EveryAyah arşivi.")
                                .font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                    .onAppear {
                        guard !kaydirildi else { return }
                        kaydirildi = true
                        let hedef = buSure ? t.ayet : ayet
                        guard hedef > 1 else { return }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { okuyucu.scrollTo(hedef, anchor: .top) }
                    }
                    .onChange(of: t.ayet) { _, yeni in
                        guard buSure, t.takip else { return }
                        withAnimation(.easeInOut(duration: 0.45)) { okuyucu.scrollTo(yeni, anchor: .center) }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    TilavetCubugu(sure: sure, baslangic: { sonGorunen })
                        .padding(.horizontal, 12)
                        .padding(.bottom, 6)
                }
            } else {
                ScrollView { KuranIndirme(kuran: kuran).padding(.horizontal, 16) }
            }
        }
        .uyanikTut()
        .navigationTitle(kuran.sure(sure)?.ad ?? "Kur'an")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Toggle("Meal", isOn: depo.ayar(\.kuranMeal))
                    Toggle("Okunuş", isOn: depo.ayar(\.kuranOkunus))
                    Button("Yazıyı büyüt", systemImage: "textformat.size.larger") { depo.degistir { $0.ayarlar.kuranPunto = min(44, $0.ayarlar.kuranPunto + 2) } }
                    Button("Yazıyı küçült", systemImage: "textformat.size.smaller") { depo.degistir { $0.ayarlar.kuranPunto = max(20, $0.ayarlar.kuranPunto - 2) } }
                } label: { Image(systemName: "textformat") }
                .accessibilityLabel("Okuma ayarları")
            }
        }
        .task { await kuran.hazirla() }
        .onAppear { sonGorunen = max(1, ayet) }
    }

    private func baslik(_ s: Sure) -> some View {
        HStack {
            Text("\(s.no) · \(s.ayetSayisi) âyet").font(.system(size: 12.5, weight: .bold)).foregroundStyle(.secondary)
            Spacer()
            Text(s.arapca).font(.arapca(26, kalin: true)).foregroundStyle(palet.vurgu).lineLimit(1).minimumScaleFactor(0.6)
            Spacer()
            Text(s.mekki ? "Mekkî" : "Medenî").font(.system(size: 12.5, weight: .bold)).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(palet.vurgu.opacity(0.45), lineWidth: 1))
        .camYuzey(palet.cam(), in: .rect(cornerRadius: 18))
        .padding(.top, 6)
    }

    private func ayetGorunumu(_ v: Ayet, _ a: Ayarlar) -> some View {
        let okunuyor = buSure && t.ayet == v.no
        let anahtar = "\(sure):\(v.no)"
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("\(sure):\(v.no)")
                    .font(.kalin(11)).monospacedDigit().foregroundStyle(okunuyor ? palet.dolguMetin : .secondary)
                    .padding(.horizontal, 9).frame(height: 22)
                    .background(Capsule().fill(okunuyor ? palet.vurgu : palet.vurgu.opacity(0.12)))
                if okunuyor, t.caliyor {
                    Image(systemName: "waveform").font(.system(size: 12, weight: .bold)).foregroundStyle(palet.vurgu)
                        .symbolEffect(.variableColor.iterative, isActive: true)
                        .accessibilityHidden(true)
                }
                Spacer()
                Button { dinle(v.no) } label: {
                    Image(systemName: okunuyor && t.caliyor ? "pause.circle.fill" : "play.circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(okunuyor ? palet.vurgu : .secondary)
                        .frame(width: 32, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(okunuyor && t.caliyor ? "Durdur" : "\(v.no). âyetten dinle")
                BegenDugmesi(tur: .ayet, anahtar: anahtar)
            }
            Text("\(v.arapca) ﴿\(v.no.arapcaRakam)﴾")
                .font(.arapca(a.kuranPunto))
                .lineSpacing(a.kuranPunto * 0.45)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundStyle(okunuyor ? palet.vurgu : .primary)
            if a.kuranOkunus, !v.okunus.isEmpty {
                Text(v.okunus).font(.system(size: 15, design: .serif).italic()).foregroundStyle(palet.vurgu.opacity(0.9))
            }
            if a.kuranMeal, !v.meal.isEmpty {
                (Text(v.mealBas < v.no ? "\(v.mealBas)-\(v.no). " : "\(v.no). ").font(.kalin(13)).foregroundStyle(palet.vurgu) + Text(v.meal).font(.okuma(a.okumaPunto - 1)))
                    .lineSpacing(3)
            }
        }
        .camKart(okunuyor ? palet.vurgu : nil, kose: 22, ic: 14)
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(palet.vurgu.opacity(okunuyor ? 0.85 : 0), lineWidth: 1.5))
        .scaleEffect(okunuyor ? 1.01 : 1)
        .animation(.easeInOut(duration: 0.3), value: okunuyor)
        .contextMenu {
            Button("Buradan dinle", systemImage: "play") { t.cal(sure: sure, ayet: v.no) }
            Button(depo.begenildi(.ayet, anahtar) ? "Kaydedilenlerden çıkar" : "Kaydet", systemImage: "heart") { depo.begen(.ayet, anahtar) }
            Button("Kopyala", systemImage: "doc.on.doc") {
                UIPasteboard.general.string = "\(v.arapca)\n\n\(v.meal.isEmpty ? "" : v.meal + " ")(\(kuran.sure(sure)?.ad ?? "") \(sure):\(v.no))"
            }
        }
    }

    private func dinle(_ no: Int) {
        if buSure, t.ayet == no { t.degistirOynat() } else if buSure { t.atla(ayet: no) } else { t.cal(sure: sure, ayet: no) }
        Dokunsal.hafif(0.5)
    }

    /// Görünen en son âyeti kaldığın yer olarak saklar.
    private func kaydet(_ no: Int) {
        sonGorunen = no
        let yeni = [sure, no]
        guard depo.kayit.kuranSon != yeni else { return }
        depo.degistir { $0.kuranSon = yeni }
    }
}
