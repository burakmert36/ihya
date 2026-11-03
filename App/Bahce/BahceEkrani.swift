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
    var body: some View {
        VStack(spacing: 10) {
            Picker("Dönem", selection: $donem) {
                ForEach(Donem.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .onChange(of: donem) { _, _ in kaydir = 0 }
            HStack {
                Button { kaydir -= 1 } label: { Image(systemName: "chevron.left") }
                    .accessibilityLabel("Önceki")
                Spacer()
                Text(donem.baslik(kaydir)).font(.headline)
                Spacer()
                Button { kaydir += 1 } label: { Image(systemName: "chevron.right") }
                    .disabled(kaydir >= 0)
                    .accessibilityLabel("Sonraki")
            }
            .buttonStyle(.glass)
        }
    }
}

struct BahceEkrani: View {
    @Environment(Depo.self) private var depo
    @State private var donem: Donem = .gun
    @State private var kaydir = 0

    var body: some View {
        let a = donem.aralik(kaydir)
        let liste = depo.kayit.oturumlar.filter { a.contains($0.baslangic) }.sorted { $0.baslangic < $1.baslangic }
        let tamam = liste.filter { $0.durum == .tamam }
        ScrollView {
            VStack(spacing: 18) {
                DonemSecici(donem: $donem, kaydir: $kaydir)
                BahceAlani(oturumlar: liste)
                    .padding(.vertical, 6)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    Ozet(baslik: "Odak", deger: tamam.reduce(0) { $0 + $1.sure }.sureMetni, simge: "clock")
                    Ozet(baslik: "Bitki", deger: "\(tamam.count)", simge: "leaf")
                    Ozet(baslik: "Kuruyan", deger: "\(liste.count - tamam.count)", simge: "wind")
                    Ozet(baslik: "Tohum", deger: "+\(tamam.reduce(0) { $0 + $1.kazanc })", simge: "leaf.circle")
                }
                NavigationLink(value: Rota.istatistik) {
                    HStack {
                        Label("Grafikler ve konular", systemImage: "chart.bar.xaxis")
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                    }
                    .camKart()
                }
                .buttonStyle(.plain)
                if !liste.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        BolumBasligi(metin: "Oturumlar", simge: "list.bullet")
                        ForEach(liste.reversed().prefix(12)) { o in OturumSatiri(oturum: o) }
                    }
                    .camKart()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .navigationTitle("Bahçe")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: Rota.koleksiyon) { Image(systemName: "square.grid.2x2") }
                    .accessibilityLabel("Koleksiyon")
            }
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
                       cerceve: CGRect(x: -4, y: -12, width: 108, height: 130), lod: 0.5, kurudu: oturum.durum == .vazgecildi)
                .frame(width: 36, height: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(oturum.ad.isEmpty ? BitkiKatalogu.ad(oturum.tur) : oturum.ad).font(.subheadline.weight(.medium)).lineLimit(1)
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
            Text(oturum.sure.sureMetni).font(.subheadline).monospacedDigit()
                .foregroundStyle(oturum.durum == .tamam ? .primary : .secondary)
        }
    }
}

/// İzometrik çim adası; bitkiler arkadan öne dizilir. Bütün bitkiler aynı ölçekte çizilir (ağaç çiçekten büyük görünür).
struct BahceAlani: View {
    let oturumlar: [OdakOturumu]
    static let sinir = 64

    var body: some View {
        let gosterilen = Array(oturumlar.suffix(BahceAlani.sinir))
        let n = max(4, min(8, Int(ceil(sqrt(Double(max(1, gosterilen.count)))))))
        GeometryReader { g in
            let W = g.size.width, H = W * 0.56
            let hucre = W / CGFloat(n)
            ZStack(alignment: .topLeading) {
                ElmasZemin(n: n).frame(width: W, height: H + 22).offset(y: hucre * 0.6)
                ForEach(yerlesim(gosterilen.count, n), id: \.sira) { y in
                    let o = gosterilen[y.sira]
                    let cx = W / 2 + CGFloat(y.i - y.j) * hucre / 2
                    let cy = hucre * 0.6 + CGFloat(y.i + y.j + 1) * (H / 2) / CGFloat(n)
                    BitkiResmi(tur: o.tur, dk: o.durum == .tamam ? Double(o.plan) : max(1, o.sure), tohum: o.tohum,
                               cerceve: CGRect(x: -10, y: -24, width: 120, height: 144), lod: n > 5 ? 0.45 : 0.7, kurudu: o.durum == .vazgecildi)
                        .frame(width: hucre * 1.35, height: hucre * 1.62)
                        .position(x: cx, y: cy - hucre * 0.62)
                }
            }
        }
        .aspectRatio(1 / 0.72, contentMode: .fit)
        .overlay(alignment: .bottom) {
            if oturumlar.isEmpty {
                Text("Bu dönemde bitki yok.").font(.footnote).foregroundStyle(.secondary).padding(.bottom, 4)
            } else if oturumlar.count > BahceAlani.sinir {
                Text("+\(oturumlar.count - BahceAlani.sinir) bitki daha").font(.footnote).foregroundStyle(.secondary)
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

struct ElmasZemin: View {
    let n: Int
    var body: some View {
        Canvas { ctx, b in
            let W = b.width, H = b.height - 22, d: CGFloat = 18
            var ust = Path()
            ust.move(to: CGPoint(x: W / 2, y: 0)); ust.addLine(to: CGPoint(x: W, y: H / 2))
            ust.addLine(to: CGPoint(x: W / 2, y: H)); ust.addLine(to: CGPoint(x: 0, y: H / 2)); ust.closeSubpath()
            var sol = Path()
            sol.move(to: CGPoint(x: 0, y: H / 2)); sol.addLine(to: CGPoint(x: W / 2, y: H))
            sol.addLine(to: CGPoint(x: W / 2, y: H + d)); sol.addLine(to: CGPoint(x: 0, y: H / 2 + d)); sol.closeSubpath()
            var sag = Path()
            sag.move(to: CGPoint(x: W, y: H / 2)); sag.addLine(to: CGPoint(x: W / 2, y: H))
            sag.addLine(to: CGPoint(x: W / 2, y: H + d)); sag.addLine(to: CGPoint(x: W, y: H / 2 + d)); sag.closeSubpath()
            ctx.fill(sol, with: .color(Color(red: 0.55, green: 0.38, blue: 0.24)))
            ctx.fill(sag, with: .color(Color(red: 0.44, green: 0.30, blue: 0.19)))
            ctx.fill(ust, with: .linearGradient(Gradient(colors: [Color(red: 0.62, green: 0.84, blue: 0.45), Color(red: 0.36, green: 0.66, blue: 0.32)]),
                                                startPoint: CGPoint(x: W / 2, y: 0), endPoint: CGPoint(x: W / 2, y: H)))
            var izgara = Path()
            for k in 1..<n {
                let t = CGFloat(k) / CGFloat(n)
                izgara.move(to: CGPoint(x: W / 2 * (1 - t), y: H / 2 * t)); izgara.addLine(to: CGPoint(x: W - W / 2 * t, y: H / 2 + H / 2 * t))
                izgara.move(to: CGPoint(x: W / 2 + W / 2 * t, y: H / 2 * t)); izgara.addLine(to: CGPoint(x: W / 2 * t, y: H / 2 + H / 2 * t))
            }
            ctx.stroke(izgara, with: .color(.white.opacity(0.13)), lineWidth: 0.8)
        }
    }
}

// MARK: İstatistik

struct IstatistikEkrani: View {
    @Environment(Depo.self) private var depo
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
                        Ozet(baslik: "Şimdiki seri", deger: "\(seri()) gün", simge: "calendar")
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
                                        BitkiResmi(tur: t.tur, dk: Double(BitkiKatalogu.bul(t.tur)?.dk ?? 25), cerceve: CGRect(x: -4, y: -10, width: 108, height: 128), lod: 0.6)
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

    private func seri() -> Int {
        let c = Calendar.current
        let gunler = Set(depo.kayit.oturumlar.filter { $0.durum == .tamam }.map { c.startOfDay(for: $0.baslangic) })
        var g = c.startOfDay(for: .now)
        if !gunler.contains(g) { g = c.date(byAdding: .day, value: -1, to: g)! }
        var n = 0
        while gunler.contains(g) { n += 1; g = c.date(byAdding: .day, value: -1, to: g)! }
        return n
    }
}
