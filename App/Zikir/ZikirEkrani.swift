import Charts
import SwiftUI

struct ZikirEkrani: View {
    @Environment(Depo.self) private var depo
    @AppStorage("zikir.sayi") private var sayi = 0
    @AppStorage("zikir.baslik") private var baslik = ""
    @AppStorage("zikir.tesbihat") private var tesbihat = false
    @AppStorage("zikir.asama") private var asama = 0
    @State private var hiz = 0.3
    @State private var sonDokunus = Date.distantPast
    @State private var sifirlaSor = false
    @State private var sesAyari = false
    @State private var kaydedildi = false
    @FocusState private var yaziyor: Bool

    static let tesbihatAdlari = ["Sübhânallah", "Elhamdülillah", "Allâhu ekber"]

    var body: some View {
        VStack(spacing: 16) {
            ust
            TesbihHalkasi(sayi: sayi, hiz: hiz)
                .overlay {
                    VStack(spacing: 2) {
                        Text("\(sayi)")
                            .font(.system(size: 64, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText(value: Double(sayi)))
                        Text(tesbihat ? "\(min(asama + 1, 3)). tur · 33" : (sayi >= 33 ? "\(sayi / 33) × 33" : "dokun"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
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
        .padding(.bottom, 12)
        .navigationTitle("Zikir")
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
            VStack(spacing: 6) {
                if asama < 3 {
                    Text(ZikirEkrani.tesbihatAdlari[asama]).font(.title2.weight(.semibold))
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { i in
                            Capsule().fill(i < asama ? Color.ihya : i == asama ? Color.ihya.opacity(0.4) : Color.secondary.opacity(0.2))
                                .frame(width: 34, height: 6)
                        }
                    }
                } else {
                    Text("Tesbihat tamam").font(.title2.weight(.semibold))
                    Text("Lâ ilâhe illallâhu vahdehû lâ şerîke leh, lehü'l-mülkü ve lehü'l-hamdü ve hüve alâ külli şey'in kadîr.")
                        .font(.okuma(15)).multilineTextAlignment(.center).foregroundStyle(.secondary)
                }
            }
            .frame(minHeight: 70)
        } else {
            TextField("Zikir adı (isteğe bağlı)", text: $baslik)
                .font(.title3.weight(.medium))
                .multilineTextAlignment(.center)
                .focused($yaziyor)
                .submitLabel(.done)
                .padding(.vertical, 10)
                .frame(minHeight: 70)
        }
    }

    private var denetimler: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                dugme("Sıfırla", "arrow.counterclockwise") { if sayi > 0 { sifirlaSor = true } }
                dugme("33×3", tesbihat ? "checkmark.circle.fill" : "circle.grid.3x3", vurgu: tesbihat) {
                    tesbihat.toggle()
                    sayi = 0
                    asama = 0
                }
                dugme("Titreşim", depo.ayarlar.tesbihTitresim ? "iphone.radiowaves.left.and.right" : "iphone.slash", vurgu: depo.ayarlar.tesbihTitresim) {
                    depo.degistir { $0.ayarlar.tesbihTitresim.toggle() }
                }
                dugme("Ses", depo.ayarlar.tesbihSes ? "speaker.wave.2" : "speaker.slash", vurgu: depo.ayarlar.tesbihSes) { sesAyari = true }
                    .popover(isPresented: $sesAyari) {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Tık sesi", isOn: depo.ayar(\.tesbihSes))
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
                dugme(kaydedildi ? "Kaydedildi" : "Kaydet", kaydedildi ? "checkmark" : "tray.and.arrow.down", vurgu: kaydedildi) { kaydet() }
                    .disabled(sayi == 0 && !kaydedildi)
            }
        }
    }

    private func dugme(_ ad: String, _ simge: String, vurgu: Bool = false, _ is_: @escaping () -> Void) -> some View {
        Button(action: is_) {
            VStack(spacing: 5) {
                Image(systemName: simge).font(.body.weight(.medium)).contentTransition(.symbolEffect(.replace))
                Text(ad).font(.caption2).lineLimit(1).minimumScaleFactor(0.8)
            }
            .foregroundStyle(vurgu ? Color.ihya : Color.primary)
            .frame(maxWidth: .infinity, minHeight: 58)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
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

/// 33 tanelik tesbih: her sayımda bir tane ilerler; hız dokunma aralığına göre değişir. 11 ve 22. taneler nişanedir.
struct TesbihHalkasi: View {
    let sayi: Int
    let hiz: Double
    static let tane = 33

    var body: some View {
        GeometryReader { g in
            let r = min(g.size.width, g.size.height) / 2 - 18
            ZStack {
                Circle().stroke(Color.secondary.opacity(0.15), lineWidth: 1.5).frame(width: r * 2, height: r * 2)
                ZStack {
                    ForEach(0..<TesbihHalkasi.tane, id: \.self) { i in
                        let nisane = i % 11 == 0
                        Circle()
                            .fill(RadialGradient(colors: nisane ? [Color(red: 0.98, green: 0.86, blue: 0.55), Color(red: 0.72, green: 0.48, blue: 0.16)]
                                                 : [Color(red: 0.62, green: 0.86, blue: 0.62), Color(red: 0.13, green: 0.52, blue: 0.30)],
                                                 center: UnitPoint(x: 0.35, y: 0.3), startRadius: 1, endRadius: 14))
                            .frame(width: nisane ? 24 : 19, height: nisane ? 24 : 19)
                            .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
                            .offset(y: -r)
                            .rotationEffect(.degrees(Double(i) * 360 / Double(TesbihHalkasi.tane)))
                    }
                }
                .rotationEffect(.degrees(-Double(sayi) * 360 / Double(TesbihHalkasi.tane)))
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.caption)
                    .foregroundStyle(Color.ihya)
                    .offset(y: -r - 22)
            }
            .frame(width: g.size.width, height: g.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(.horizontal, 8)
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
                            .foregroundStyle(Color.ihya.gradient)
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
