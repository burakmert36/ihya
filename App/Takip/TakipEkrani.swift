import Charts
import SwiftUI

/// Takip sekmesi: Bahçe (odak), Namaz ve Zikir ayrı bölümler; her bölüm kendi sahnesinde.
struct TakipEkrani: View {
    @Environment(Yonlendirici.self) private var yon

    var body: some View {
        switch yon.takipBolum {
        case .bahce: BahceEkrani().sahne(.bahce)
        case .namaz: NamazTakipEkrani().sahne(.vakit)
        case .zikir: ZikirTakipEkrani().sahne(.zikir)
        }
    }
}

/// Takip bölümleri arasında geçiş (her bölümün başında).
struct TakipSecici: View {
    @Environment(Yonlendirici.self) private var yon

    var body: some View {
        @Bindable var yon = yon
        CamSegment(secenekler: TakipBolumu.allCases, secili: $yon.takipBolum, ad: { $0.rawValue })
            .padding(.top, 4)
    }
}

/// Son yedi günün odak dakikaları; günlük hedef çizgisiyle.
struct HaftalikOdak: View {
    @Environment(Depo.self) private var depo
    @Environment(\.palet) private var palet

    private struct Gun: Identifiable { let id: Int; let etiket: String; let dk: Double }

    var body: some View {
        let c = Calendar.current
        let bugun = c.startOfDay(for: .now)
        let gunler: [Gun] = (0..<7).map { i in
            let g = c.date(byAdding: .day, value: i - 6, to: bugun)!
            let dk = depo.kayit.oturumlar.filter { $0.durum == .tamam && c.isDate($0.baslangic, inSameDayAs: g) }.reduce(0) { $0 + $1.sure }
            return Gun(id: i, etiket: i == 6 ? "Bugün" : Tarihler.haftaGunuKisa.string(from: g), dk: dk)
        }
        let toplam = gunler.reduce(0) { $0 + $1.dk }
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Son 7 gün").font(.kalin(16))
                Spacer()
                Text("\(toplam.sureMetni) · günde \((toplam / 7).sureMetni)").font(.system(size: 12.5, weight: .bold)).foregroundStyle(.secondary)
            }
            Chart {
                ForEach(gunler) { g in
                    BarMark(x: .value("Gün", g.etiket), y: .value("Dakika", g.dk))
                        .foregroundStyle(LinearGradient(colors: palet.cubuk, startPoint: .bottom, endPoint: .top))
                        .cornerRadius(5)
                }
                RuleMark(y: .value("Hedef", Double(depo.ayarlar.gunlukHedef)))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Color.secondary)
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 150)
        }
        .camKart(kose: 28)
    }
}

// MARK: Namaz

/// Haftalık namaz çizelgesi: son yedi gün, beş vakit; dokununca işaretlenir.
struct NamazTakipEkrani: View {
    @Environment(Depo.self) private var depo
    @Environment(VakitServisi.self) private var vakit
    @Environment(\.palet) private var palet

    var body: some View {
        let c = Calendar.current
        let bugun = c.startOfDay(for: .now)
        let gunler = (0..<7).map { c.date(byAdding: .day, value: $0 - 6, to: bugun)! }
        let haftalik = gunler.reduce(0) { t, g in t + VakitAdi.namazlar.filter { depo.kilindi($0.0, gun: g) }.count }
        let aylik = (0..<30).reduce(0) { t, i in
            let g = c.date(byAdding: .day, value: -i, to: bugun)!
            return t + VakitAdi.namazlar.filter { depo.kilindi($0.0, gun: g) }.count
        }
        ScrollView {
            VStack(spacing: 12) {
                TakipSecici()
                SahneBasligi(ust: Tarihler.ustSatir(), baslik: "Namaz")
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Bu hafta").font(.kalin(16))
                        Spacer()
                        Text("\(haftalik)").font(.system(size: 28, weight: .heavy)).foregroundStyle(palet.vurgu)
                        Text("/ 35 kılındı").font(.system(size: 12, weight: .bold)).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 0) {
                        Text("").frame(width: 54)
                        ForEach(0..<VakitAdi.namazlar.count, id: \.self) { k in
                            Text(VakitAdi.namazlar[k].1).font(.kalin(11)).foregroundStyle(.secondary).frame(maxWidth: .infinity).lineLimit(1).minimumScaleFactor(0.7)
                        }
                    }
                    ForEach(gunler, id: \.self) { g in
                        let bugunMu = c.isDateInToday(g)
                        let saatler = vakit.vakitler(g)
                        HStack(spacing: 0) {
                            Text(bugunMu ? "Bugün" : Tarihler.haftaGunuKisa.string(from: g))
                                .font(.system(size: 13, weight: bugunMu ? .heavy : .semibold))
                                .foregroundStyle(bugunMu ? palet.vurgu : Color.primary)
                                .frame(width: 54, alignment: .leading)
                            ForEach(0..<VakitAdi.namazlar.count, id: \.self) { k in
                                let v = VakitAdi.namazlar[k]
                                let kilindi = depo.kilindi(v.0, gun: g)
                                let gelmedi = bugunMu && saatler.indices.contains(v.0) && Date() < saatler[v.0]
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { depo.namazDegistir(v.0, gun: g) }
                                    Dokunsal.hafif(kilindi ? 0.4 : 0.8)
                                } label: {
                                    ZStack {
                                        Circle().fill(kilindi ? AnyShapeStyle(LinearGradient(colors: palet.cubuk, startPoint: .top, endPoint: .bottom)) : AnyShapeStyle(Color.primary.opacity(0.06)))
                                        Circle().strokeBorder(kilindi ? Color.clear : Color.primary.opacity(gelmedi ? 0.12 : 0.3), style: StrokeStyle(lineWidth: 1.5, dash: gelmedi ? [3, 3] : []))
                                        if kilindi { Image(systemName: "checkmark").font(.system(size: 11, weight: .heavy)).foregroundStyle(.white) }
                                    }
                                    .frame(width: 26, height: 26)
                                    .frame(maxWidth: .infinity, minHeight: 34)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(Tarihler.gunAy.string(from: g)) \(v.1) \(kilindi ? "kılındı" : "kılınmadı")")
                            }
                        }
                    }
                    Text("Bir vakte dokun: kılındı olarak işaretlenir, tekrar dokununca kalkar.")
                        .font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                }
                .camKart(kose: 28)
                HStack(spacing: 10) {
                    sayac("Son 30 gün", "\(aylik)", "/ 150 vakit")
                    sayac("Tam gün serisi", "\(tamGunSerisi())", "gün")
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .altCubukPayi()
        .toolbar(.hidden, for: .navigationBar)
    }

    private func sayac(_ baslik: String, _ deger: String, _ alt: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(baslik).font(.kalin(12)).foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(deger).font(.system(size: 26, weight: .heavy)).monospacedDigit()
                Text(alt).font(.system(size: 12, weight: .bold)).foregroundStyle(.secondary)
            }
        }
        .camKart(kose: 24, ic: 14)
    }

    /// Beş vaktin hepsinin kılındığı ardışık günler (bugün tamamlanmadıysa dünden sayar).
    private func tamGunSerisi() -> Int {
        let c = Calendar.current
        func tam(_ g: Date) -> Bool { VakitAdi.namazlar.allSatisfy { depo.kilindi($0.0, gun: g) } }
        var g = c.startOfDay(for: .now)
        if !tam(g) { g = c.date(byAdding: .day, value: -1, to: g)! }
        var n = 0
        while tam(g), n < 3650 { n += 1; g = c.date(byAdding: .day, value: -1, to: g)! }
        return n
    }
}

// MARK: Zikir

/// Zikir takibi: tesbihe geçiş, bugün ve haftanın toplamı, günlük çubuklar, zikir başına toplamlar.
struct ZikirTakipEkrani: View {
    @Environment(Depo.self) private var depo
    @Environment(\.palet) private var palet

    private struct Gun: Identifiable { let id: Int; let etiket: String; let sayi: Int }
    private struct Toplam: Identifiable { let ad: String; let sayi: Int; var id: String { ad } }

    var body: some View {
        let c = Calendar.current
        let bugun = c.startOfDay(for: .now)
        let hafta = depo.kayit.zikirler.filter { $0.tarih >= c.date(byAdding: .day, value: -6, to: bugun)! }
        let gunler: [Gun] = (0..<7).map { i in
            let g = c.date(byAdding: .day, value: i - 6, to: bugun)!
            return Gun(id: i, etiket: i == 6 ? "Bugün" : Tarihler.haftaGunuKisa.string(from: g),
                       sayi: hafta.filter { c.isDate($0.tarih, inSameDayAs: g) }.reduce(0) { $0 + $1.sayi })
        }
        let toplamlar = Dictionary(grouping: hafta, by: \.gorunenAd).map { Toplam(ad: $0.key, sayi: $0.value.reduce(0) { $0 + $1.sayi }) }.sorted { $0.sayi > $1.sayi }
        ScrollView {
            VStack(spacing: 12) {
                TakipSecici()
                SahneBasligi(ust: Tarihler.ustSatir(), baslik: "Zikir")
                NavigationLink(value: Rota.zikir) {
                    HStack(spacing: 14) {
                        Image(systemName: "circle.dotted").font(.system(size: 26, weight: .semibold)).foregroundStyle(palet.vurgu)
                            .frame(width: 52, height: 52)
                            .background(Circle().fill(palet.vurgu.opacity(0.14)))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tesbihi aç").font(.kalin(17))
                            Text("33×3 tesbihat ya da serbest zikir").font(.system(size: 12.5, weight: .semibold)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold)).foregroundStyle(.secondary)
                    }
                    .camKart(kose: 26, ic: 14)
                }
                .buttonStyle(.plain)
                HStack(spacing: 10) {
                    kutu("Bugün", gunler.last?.sayi ?? 0)
                    kutu("Bu hafta", gunler.reduce(0) { $0 + $1.sayi })
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Son 7 gün").font(.kalin(16))
                    Chart(gunler) { g in
                        BarMark(x: .value("Gün", g.etiket), y: .value("Sayı", g.sayi))
                            .foregroundStyle(LinearGradient(colors: palet.cubuk, startPoint: .bottom, endPoint: .top))
                            .cornerRadius(5)
                    }
                    .chartYAxis { AxisMarks(position: .leading) }
                    .frame(height: 150)
                }
                .camKart(kose: 28)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Bu haftaki zikirler").font(.kalin(16))
                    if toplamlar.isEmpty {
                        Text("Bu hafta kaydedilmiş zikir yok. Tesbihte \"Kaydet\" ile kaydedilir.").font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)
                    }
                    ForEach(toplamlar) { t in
                        HStack {
                            Text(t.ad).font(.system(size: 15, weight: .semibold))
                            Spacer()
                            Text("\(t.sayi)").font(.kalin(15)).monospacedDigit().foregroundStyle(palet.vurgu)
                        }
                    }
                    NavigationLink(value: Rota.zikirIstatistik) {
                        Label("Ay ve yıl görünümü", systemImage: "chart.bar.xaxis").font(.kalin(14)).frame(maxWidth: .infinity, minHeight: 30)
                    }
                    .buttonStyle(.glass).controlSize(.large)
                }
                .camKart(kose: 28)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .altCubukPayi()
        .toolbar(.hidden, for: .navigationBar)
    }

    private func kutu(_ baslik: String, _ sayi: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(baslik).font(.kalin(12)).foregroundStyle(.secondary)
            Text("\(sayi)").font(.system(size: 30, weight: .heavy)).monospacedDigit().foregroundStyle(palet.vurgu)
        }
        .camKart(kose: 24, ic: 14)
    }
}
