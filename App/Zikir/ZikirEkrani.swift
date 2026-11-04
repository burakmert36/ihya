import Charts
import SwiftUI

struct ZikirEkrani: View {
    @Environment(Depo.self) private var depo
    @Environment(\.palet) private var palet
    @AppStorage("zikir.sayi") private var sayi = 0
    @AppStorage("zikir.baslik") private var baslik = ""
    @AppStorage("zikir.tesbihat") private var tesbihat = true
    @AppStorage("zikir.asama") private var asama = 0
    @State private var hiz = 0.3
    @State private var sonDokunus = Date.distantPast
    @State private var sifirlaSor = false
    @State private var sesAyari = false
    @State private var kaydedildi = false
    @FocusState private var yaziyor: Bool

    static let tesbihatAdlari = ["Sübhânallah", "Elhamdülillah", "Allâhu ekber", "Tevhid"]
    static let arapca = ["سُبْحَانَ اللّٰهِ", "اَلْحَمْدُ لِلّٰهِ", "اَللّٰهُ أَكْبَرُ", "لَا إِلٰهَ إِلَّا اللّٰهُ"]
    static let anlam = ["Allah her türlü eksiklikten münezzehtir", "Hamd yalnız Allah’a mahsustur", "Allah en büyüktür", "Allah’tan başka ilâh yoktur"]

    var body: some View {
        VStack(spacing: 12) {
            ust
            TesbihHalkasi(sayi: sayi, hiz: hiz)
                .overlay {
                    VStack(spacing: 0) {
                        Text("\(sayi)")
                            .font(.system(size: 64, weight: .heavy))
                            .monospacedDigit()
                            .contentTransition(.numericText(value: Double(sayi)))
                        Text(tesbihat ? "/ 33" : (sayi >= 33 ? "\(sayi / 33) × 33" : " "))
                            .font(.kalin(15)).foregroundStyle(.secondary)
                        Text("dokun · bir tane çek").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary).padding(.top, 6)
                    }
                    .allowsHitTesting(false)
                }
                .contentShape(Circle())
                .onTapGesture { say() }
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("Say, şu an \(sayi)")
                .frame(maxHeight: .infinity)
            denetimler
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .navigationTitle(tesbihat ? "Tesbihat" : "Zikir")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: Rota.zikirIstatistik) { Image(systemName: "chart.bar.xaxis") }
                    .accessibilityLabel("Zikir istatistikleri")
            }
        }
        .confirmationDialog("Sayaç sıfırlansın mı?", isPresented: $sifirlaSor, titleVisibility: .visible) {
            Button("Kaydet ve sıfırla") { kaydet() }
            Button("Kaydetmeden sıfırla", role: .destructive) { sifirla() }
            Button("Vazgeç", role: .cancel) {}
        }
    }

    @ViewBuilder private var ust: some View {
        if tesbihat {
            let a = min(asama, 3)
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { i in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(ZikirEkrani.tesbihatAdlari[i]).font(.kalin(10.5)).lineLimit(1).minimumScaleFactor(0.6)
                                .foregroundStyle(i <= a ? palet.vurgu : Color.secondary)
                            IlerlemeCubugu(oran: i < a ? 1 : i == a ? (i == 3 ? 1 : Double(sayi) / 33) : 0, yukseklik: 6)
                        }
                    }
                }
                Text(ZikirEkrani.arapca[a])
                    .font(.arapca(40, kalin: true))
                    .foregroundStyle(LinearGradient(colors: [Color(hex: "#FFE2A0"), Color(hex: "#E89A35")], startPoint: .top, endPoint: .bottom))
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .padding(.top, 4)
                Text(ZikirEkrani.tesbihatAdlari[a]).font(.system(size: 18, design: .serif).italic())
                Text(a < 3 ? ZikirEkrani.anlam[a] : "Lâ ilâhe illallâhu vahdehû lâ şerîke leh, lehü’l-mülkü ve lehü’l-hamdü ve hüve alâ külli şey’in kadîr.")
                    .font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            .padding(.top, 6)
        } else {
            TextField("Zikir adı (isteğe bağlı)", text: $baslik)
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .multilineTextAlignment(.center)
                .focused($yaziyor)
                .submitLabel(.done)
                .padding(.horizontal, 16)
                .frame(height: 50)
                .camYuzey(palet.cam(), in: .capsule)
                .padding(.top, 10)
        }
    }

    private var denetimler: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                hap(depo.ayarlar.tesbihSes ? "Kehribar sesi" : "Ses kapalı", on: depo.ayarlar.tesbihSes) { sesAyari = true }
                    .popover(isPresented: $sesAyari) {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Kehribar sesi", isOn: depo.ayar(\.tesbihSes))
                            HStack {
                                Image(systemName: "speaker.fill").foregroundStyle(.secondary)
                                Slider(value: depo.ayar(\.tesbihSesDuzeyi), in: 0.05...1, onEditingChanged: { suruyor in
                                    if !suruyor { Efekt.cal("tesbih_tik", duzey: Float(depo.ayarlar.tesbihSesDuzeyi)) }
                                })
                                Image(systemName: "speaker.wave.3.fill").foregroundStyle(.secondary)
                            }
                            .disabled(!depo.ayarlar.tesbihSes)
                        }
                        .padding(18)
                        .frame(width: 260)
                        .presentationCompactAdaptation(.popover)
                    }
                hap("Titreşim", on: depo.ayarlar.tesbihTitresim) { depo.degistir { $0.ayarlar.tesbihTitresim.toggle() } }
                hap("Baştan", on: false) { if sayi > 0 || asama > 0 { sifirlaSor = true } }
            }
            HStack(spacing: 8) {
                hap(tesbihat ? "33×3 tesbihat" : "Serbest zikir", on: tesbihat) {
                    tesbihat.toggle()
                    sayi = 0
                    asama = 0
                }
                hap(kaydedildi ? "Kaydedildi" : "Kaydet", on: kaydedildi) { kaydet() }
                    .disabled(sayi == 0 && !kaydedildi)
            }
        }
    }

    private func hap(_ ad: String, on: Bool, _ eylem: @escaping () -> Void) -> some View {
        Button(action: eylem) {
            Text(ad).font(.kalin(14)).lineLimit(1).minimumScaleFactor(0.8)
                .foregroundStyle(on ? palet.vurgu : Color.primary)
                .padding(.horizontal, 16)
                .frame(minHeight: 40)
                .overlay(Capsule().strokeBorder(on ? palet.vurgu.opacity(0.8) : .clear, lineWidth: 1.2))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .camYuzey(on ? Glass.regular.tint(palet.vurgu.opacity(0.18)).interactive() : palet.cam(etkilesimli: true), in: .capsule)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func say() {
        if yaziyor { yaziyor = false }
        if tesbihat, asama >= 3 { return }
        let simdi = Date()
        let dt = simdi.timeIntervalSince(sonDokunus)
        sonDokunus = simdi
        hiz = min(0.45, max(0.12, dt * 0.6))
        withAnimation(.spring(response: hiz, dampingFraction: 0.78)) { sayi += 1 }
        let a = depo.ayarlar
        if a.tesbihSes { Efekt.cal("tesbih_tik", duzey: Float(a.tesbihSesDuzeyi)) }
        let tamTur = sayi % 33 == 0
        if a.tesbihTitresim { tamTur ? Dokunsal.sert() : Dokunsal.hafif(0.55) }
        if tesbihat, sayi >= 33 {
            asama += 1
            if asama >= 3 {
                depo.degistir { $0.zikirler.append(ZikirKaydi(baslik: "Namaz tesbihatı", sayi: 99, tarih: .now)) }
                if a.tesbihTitresim { Dokunsal.basari() }
                Efekt.cal("efekt_isilti", duzey: 0.5)
            }
            withAnimation(.easeInOut(duration: 0.25)) { sayi = 0 }
        }
        kaydedildi = false
    }

    private func kaydet() {
        guard sayi > 0 else { return }
        let b = tesbihat ? "Namaz tesbihatı" : baslik.trimmingCharacters(in: .whitespacesAndNewlines)
        depo.degistir { $0.zikirler.append(ZikirKaydi(baslik: b, sayi: sayi, tarih: .now)) }
        Dokunsal.basari()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            kaydedildi = true
            sayi = 0
        }
    }

    private func sifirla() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { sayi = 0; asama = 0 }
        kaydedildi = false
    }
}

/// 33 tanelik kehribar tesbih: her sayımda bir tane ilerler; hız dokunma aralığına göre değişir. Altta sabit imame ve püskül.
struct TesbihHalkasi: View {
    let sayi: Int
    let hiz: Double
    static let tane = 33

    var body: some View {
        GeometryReader { g in
            let r = min(g.size.width, g.size.height) / 2 - 22
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Color(r: 79, g: 70, b: 229, a: 0.28), Color(r: 79, g: 70, b: 229, a: 0.04)], center: .center, startRadius: 0, endRadius: r))
                    .frame(width: r * 2, height: r * 2)
                Circle().stroke(Color(r: 244, g: 176, b: 74, a: 0.25), lineWidth: 1).frame(width: r * 2, height: r * 2)
                ZStack {
                    ForEach(0..<TesbihHalkasi.tane, id: \.self) { i in
                        let nisane = i % 11 == 0
                        Circle()
                            .fill(RadialGradient(stops: [.init(color: Color(hex: "#FFEDC0"), location: 0), .init(color: Color(hex: "#F4B04A"), location: 0.38),
                                                         .init(color: Color(hex: "#C46A1B"), location: 0.78), .init(color: Color(hex: "#7E3F0E"), location: 1)],
                                                 center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: nisane ? 11 : 9))
                            .frame(width: nisane ? 20 : 16, height: nisane ? 20 : 16)
                            .shadow(color: Color(hex: "#F4B04A").opacity(0.35), radius: 3)
                            .offset(y: -r)
                            .rotationEffect(.degrees(Double(i) * 360 / Double(TesbihHalkasi.tane)))
                    }
                }
                .rotationEffect(.degrees(-Double(sayi) * 360 / Double(TesbihHalkasi.tane)))
                // imame ve püskül
                VStack(spacing: 0) {
                    Capsule().fill(LinearGradient(colors: [Color(hex: "#FFE2A0"), Color(hex: "#E89A35"), Color(hex: "#9A5114")], startPoint: .top, endPoint: .bottom))
                        .frame(width: 12, height: 30)
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { _ in Capsule().fill(Color(hex: "#E8B04A")).frame(width: 1.5, height: 34) }
                    }
                }
                .offset(y: r + 30)
            }
            .frame(width: g.size.width, height: g.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(.horizontal, 8)
        .padding(.bottom, 40)
    }
}

// MARK: İstatistik

struct ZikirIstatistikEkrani: View {
    @Environment(Depo.self) private var depo
    @State private var donem: Donem = .hafta
    @State private var kaydir = 0
    @State private var secili = "__tumu"

    private struct Cubuk: Identifiable { let id = UUID(); let etiket: String; let sayi: Int }
    private struct Toplam: Identifiable { let ad: String; let sayi: Int; var id: String { ad } }

    var body: some View {
        let a = donem.aralik(kaydir)
        let donemdeki = depo.kayit.zikirler.filter { a.contains($0.tarih) }
        let filtreli = secili == "__tumu" ? donemdeki : donemdeki.filter { $0.baslik == secili }
        let basliklar = Array(Set(depo.kayit.zikirler.map(\.baslik))).sorted()
        let toplamlar = Dictionary(grouping: donemdeki, by: \.baslik).map { Toplam(ad: $0.key, sayi: $0.value.reduce(0) { $0 + $1.sayi }) }.sorted { $0.sayi > $1.sayi }
        ScrollView {
            VStack(spacing: 18) {
                DonemSecici(donem: $donem, kaydir: $kaydir)
                Picker("Zikir", selection: $secili) {
                    Text("Bütün zikirler").tag("__tumu")
                    ForEach(basliklar, id: \.self) { b in Text(b.isEmpty ? "Genel zikirler" : b).tag(b) }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        BolumBasligi(metin: "Toplam", simge: "number")
                        Text("\(filtreli.reduce(0) { $0 + $1.sayi })").font(.title3.weight(.semibold)).monospacedDigit()
                    }
                    Chart(cubukla(filtreli, a)) { c in
                        BarMark(x: .value("Zaman", c.etiket), y: .value("Sayı", c.sayi))
                            .foregroundStyle(Color(hex: "#F4B04A").gradient)
                            .cornerRadius(4)
                    }
                    .chartXAxis { AxisMarks(values: .automatic(desiredCount: 8)) }
                    .frame(height: 220)
                }
                .camKart()
                VStack(alignment: .leading, spacing: 10) {
                    BolumBasligi(metin: "Zikirler", simge: "list.bullet")
                    if toplamlar.isEmpty {
                        Text("Bu dönemde kayıtlı zikir yok.").font(.footnote).foregroundStyle(.secondary)
                    }
                    ForEach(toplamlar) { t in
                        HStack {
                            Text(t.ad.isEmpty ? "Genel zikirler" : t.ad)
                            Spacer()
                            Text("\(t.sayi)").monospacedDigit().foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                }
                .camKart()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .navigationTitle("Zikir istatistikleri")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func cubukla(_ liste: [ZikirKaydi], _ a: DateInterval) -> [Cubuk] {
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
        return kovalar.map { k in Cubuk(etiket: k.0, sayi: liste.filter { $0.tarih >= k.1 && $0.tarih < k.2 }.reduce(0) { $0 + $1.sayi }) }
    }
}
