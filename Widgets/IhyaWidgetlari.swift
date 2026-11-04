import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

@main
struct IhyaWidgetlari: WidgetBundle {
    var body: some Widget {
        SeriWidget()
        VakitWidget()
        OdakCanliEtkinligi()
        OdaklanKontrolu()
        SeslerKontrolu()
    }
}

// MARK: Zaman çizelgesi

struct IhyaGirdi: TimelineEntry {
    let date: Date
    let veri: WidgetVerisi?
}

/// Her vakit girişinde (ve imsakta) yeni bir giriş; sayaçlar sistem saatiyle kendi kendine sayar.
struct IhyaSaglayici: TimelineProvider {
    func placeholder(in context: Context) -> IhyaGirdi { IhyaGirdi(date: .now, veri: .ornek) }

    func getSnapshot(in context: Context, completion: @escaping (IhyaGirdi) -> Void) {
        completion(IhyaGirdi(date: .now, veri: context.isPreview ? (Paylasim.oku() ?? .ornek) : Paylasim.oku()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<IhyaGirdi>) -> Void) {
        let veri = Paylasim.oku()
        let simdi = Date()
        var anlar = [simdi]
        if let v = veri { anlar += v.vakitler.map(\.zaman).filter { $0 > simdi }.prefix(8) }
        let girdiler = anlar.map { IhyaGirdi(date: $0, veri: veri) }
        let sonraki = anlar.last.map { max($0, simdi.addingTimeInterval(1800)) } ?? simdi.addingTimeInterval(3600)
        completion(Timeline(entries: girdiler, policy: .after(sonraki)))
    }
}

// MARK: Ortak parçalar

private enum Renk {
    static let yesil = Color(red: 0.12, green: 0.70, blue: 0.35)
    static let acikYesil = Color(red: 0.49, green: 0.94, blue: 0.64)
    static let altin = Color(red: 0.95, green: 0.82, blue: 0.48)
    static let gece1 = Color(red: 0.07, green: 0.10, blue: 0.22)
    static let gece2 = Color(red: 0.16, green: 0.12, blue: 0.36)
    static let bahce1 = Color(red: 0.05, green: 0.23, blue: 0.16)
    static let bahce2 = Color(red: 0.10, green: 0.42, blue: 0.27)
}

private struct BitkiGorseli: View {
    var boyut: CGFloat
    var body: some View {
        if let u = Paylasim.bitkiResmi, let d = try? Data(contentsOf: u), let r = UIImage(data: d) {
            Image(uiImage: r).resizable().scaledToFit().frame(width: boyut, height: boyut)
        } else {
            Image(systemName: "leaf.fill").font(.system(size: boyut * 0.55, weight: .semibold)).foregroundStyle(Renk.acikYesil)
                .frame(width: boyut, height: boyut)
        }
    }
}

private struct AcBilgisi: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "leaf.fill").font(.title2).foregroundStyle(Renk.acikYesil)
            Text("İhya'yı bir kez aç").font(.caption.weight(.semibold)).multilineTextAlignment(.center)
        }
        .foregroundStyle(.white)
    }
}

// MARK: Seri

struct SeriWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ihya.seri", provider: IhyaSaglayici()) { g in
            SeriGorunumu(g: g)
                .widgetURL(URL(string: "ihya://seri"))
        }
        .configurationDisplayName("Seri ve bahçe")
        .description("Günlük dikim serin, bugünün odağı ve son fidanın.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryInline])
    }
}

struct SeriGorunumu: View {
    let g: IhyaGirdi
    @Environment(\.widgetFamily) private var aile

    var body: some View {
        switch aile {
        case .accessoryCircular: dairesel
        case .accessoryInline: satir
        default: kucuk
        }
    }

    private var kucuk: some View {
        Group {
            if let v = g.veri {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(v.seri)").font(.system(size: 38, weight: .heavy, design: .rounded)).minimumScaleFactor(0.6)
                            Text("gün seri").font(.system(size: 12, weight: .bold)).foregroundStyle(.white.opacity(0.75))
                        }
                        Spacer(minLength: 0)
                        BitkiGorseli(boyut: 54)
                    }
                    Spacer(minLength: 0)
                    if let t = v.telafi {
                        Label("\(t) fidanla kurtar", systemImage: "arrow.uturn.backward").font(.system(size: 12, weight: .bold)).foregroundStyle(.orange)
                    } else {
                        Text(v.bugunDikildi ? "Bugün yeşerdi" : "Bugün fidan bekliyor")
                            .font(.system(size: 12, weight: .bold)).foregroundStyle(v.bugunDikildi ? Renk.acikYesil : Renk.altin)
                    }
                    ProgressView(value: Double(min(v.bugunDk, v.hedefDk)), total: Double(max(1, v.hedefDk)))
                        .tint(Renk.acikYesil)
                    HStack {
                        Text("\(v.bugunDk)/\(v.hedefDk) dk").font(.system(size: 11, weight: .semibold)).monospacedDigit()
                        Spacer()
                        if v.rahmet > 0 {
                            HStack(spacing: 2) {
                                ForEach(0..<v.rahmet, id: \.self) { _ in Image(systemName: "cloud.rain.fill") }
                            }
                            .font(.system(size: 10)).foregroundStyle(Color(red: 0.35, green: 0.7, blue: 1))
                        }
                    }
                    .foregroundStyle(.white.opacity(0.8))
                }
                .foregroundStyle(.white)
            } else {
                AcBilgisi()
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(colors: [Renk.bahce1, Renk.bahce2], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var dairesel: some View {
        let v = g.veri
        return Gauge(value: Double(min(v?.bugunDk ?? 0, v?.hedefDk ?? 1)), in: 0...Double(max(1, v?.hedefDk ?? 1))) {
            Image(systemName: "leaf.fill")
        } currentValueLabel: {
            Text("\(v?.seri ?? 0)").font(.system(size: 18, weight: .heavy, design: .rounded))
        }
        .gaugeStyle(.accessoryCircular)
        .containerBackground(for: .widget) { Color.clear }
    }

    private var satir: some View {
        let v = g.veri
        return Text(Image(systemName: "leaf.fill")) + Text(" \(v?.seri ?? 0) gün seri · \(v?.bugunDk ?? 0) dk")
    }
}

// MARK: Vakit

struct VakitWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ihya.vakit", provider: IhyaSaglayici()) { g in
            VakitGorunumu(g: g)
                .widgetURL(URL(string: "ihya://vakitler"))
        }
        .configurationDisplayName("Namaz vakti")
        .description("Sıradaki vakit ve kalan süre; büyük boyutta bütün vakitler ve serin.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

struct VakitGorunumu: View {
    let g: IhyaGirdi
    @Environment(\.widgetFamily) private var aile

    var body: some View {
        switch aile {
        case .accessoryRectangular: dikdortgen
        case .accessoryInline: satir
        case .systemMedium: orta
        default: kucuk
        }
    }

    private var arkaPlan: some View {
        LinearGradient(colors: [Renk.gece1, Renk.gece2], startPoint: .top, endPoint: .bottom)
    }

    private var kucuk: some View {
        Group {
            if let v = g.veri, let s = v.sonraki(g.date) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(v.konum.uppercased(with: Locale(identifier: "tr_TR"))).font(.system(size: 10, weight: .heavy)).tracking(0.8).foregroundStyle(.white.opacity(0.6))
                    Spacer(minLength: 0)
                    Text("\(s.sonraki.ad) vaktine").font(.system(size: 13, weight: .bold)).foregroundStyle(Renk.altin)
                    Text(s.sonraki.zaman, style: .timer)
                        .font(.system(size: 30, weight: .heavy, design: .rounded)).monospacedDigit()
                        .minimumScaleFactor(0.6).lineLimit(1)
                    Text(s.sonraki.zaman, style: .time).font(.system(size: 13, weight: .semibold)).foregroundStyle(.white.opacity(0.75))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                AcBilgisi()
            }
        }
        .containerBackground(for: .widget) { arkaPlan }
    }

    private var orta: some View {
        Group {
            if let v = g.veri, let s = v.sonraki(g.date) {
                let bugun = Array(v.vakitler.filter { Calendar.current.isDate($0.zaman, inSameDayAs: g.date) }.prefix(6))
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(v.hicri).font(.system(size: 10, weight: .bold)).foregroundStyle(.white.opacity(0.6)).lineLimit(1)
                        Spacer(minLength: 0)
                        Text("\(s.sonraki.ad) vaktine").font(.system(size: 13, weight: .bold)).foregroundStyle(Renk.altin)
                        Text(s.sonraki.zaman, style: .timer)
                            .font(.system(size: 32, weight: .heavy, design: .rounded)).monospacedDigit().minimumScaleFactor(0.6).lineLimit(1)
                        HStack(spacing: 4) {
                            Image(systemName: "leaf.fill").foregroundStyle(Renk.acikYesil)
                            Text("\(v.seri) gün · \(v.namazKilinan)/5 namaz").font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(.white.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    VStack(spacing: 3) {
                        ForEach(bugun, id: \.self) { x in
                            let siradaki = x == s.sonraki
                            HStack {
                                Text(x.ad).font(.system(size: 12, weight: siradaki ? .heavy : .semibold))
                                Spacer()
                                Text(x.zaman, style: .time).font(.system(size: 12, weight: siradaki ? .heavy : .medium)).monospacedDigit()
                            }
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .background(Capsule().fill(siradaki ? Renk.altin.opacity(0.25) : .clear))
                            .foregroundStyle(siradaki ? Renk.altin : .white.opacity(x.zaman < g.date ? 0.5 : 0.9))
                        }
                    }
                    .frame(width: 128)
                }
                .foregroundStyle(.white)
            } else {
                AcBilgisi()
            }
        }
        .containerBackground(for: .widget) { arkaPlan }
    }

    private var dikdortgen: some View {
        VStack(alignment: .leading, spacing: 1) {
            if let v = g.veri, let s = v.sonraki(g.date) {
                HStack(spacing: 4) {
                    Image(systemName: "moon.stars.fill")
                    Text("\(s.sonraki.ad) ").font(.headline) + Text(s.sonraki.zaman, style: .time).font(.headline)
                }
                Text(s.sonraki.zaman, style: .timer).font(.system(size: 15, weight: .semibold)).monospacedDigit()
                Text("\(v.seri) gün seri").font(.caption2)
            } else {
                Text("İhya'yı bir kez aç").font(.caption)
            }
        }
        .containerBackground(for: .widget) { Color.clear }
    }

    private var satir: some View {
        Group {
            if let v = g.veri, let s = v.sonraki(g.date) {
                Text("\(s.sonraki.ad) ") + Text(s.sonraki.zaman, style: .time)
            } else {
                Text("İhya")
            }
        }
    }
}

// MARK: Canlı Etkinlik

struct OdakCanliEtkinligi: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: OdakEtkinligi.self) { c in
            KilitEkraniEtkinligi(c: c)
                .activityBackgroundTint(Renk.bahce1.opacity(0.85))
                .activitySystemActionForegroundColor(.white)
                .widgetURL(URL(string: "ihya://odak"))
        } dynamicIsland: { c in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(c.attributes.bitki, systemImage: "leaf.fill").font(.system(size: 14, weight: .bold)).foregroundStyle(Renk.acikYesil)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    sayac(c.state).font(.system(size: 18, weight: .heavy, design: .rounded)).monospacedDigit().frame(maxWidth: 90)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(c.state.molada ? "Molada" : c.attributes.konu).font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
                        ilerleme(c.state)
                    }
                }
            } compactLeading: {
                Image(systemName: c.state.molada ? "pause.fill" : "leaf.fill").foregroundStyle(Renk.acikYesil)
            } compactTrailing: {
                sayac(c.state).monospacedDigit().frame(maxWidth: 52).foregroundStyle(Renk.acikYesil)
            } minimal: {
                Image(systemName: "leaf.fill").foregroundStyle(Renk.acikYesil)
            }
            .widgetURL(URL(string: "ihya://odak"))
        }
    }
}

@ViewBuilder
private func sayac(_ s: OdakEtkinligi.ContentState) -> some View {
    if s.molada {
        Text(Duration.seconds(s.kalanSn).formatted(.time(pattern: .minuteSecond)))
    } else {
        Text(timerInterval: s.baslangic...max(s.baslangic, s.bitis), countsDown: true)
    }
}

@ViewBuilder
private func ilerleme(_ s: OdakEtkinligi.ContentState) -> some View {
    if s.molada {
        ProgressView(value: 1 - Double(s.kalanSn) / max(1, s.bitis.timeIntervalSince(s.baslangic))).tint(Renk.acikYesil)
    } else {
        ProgressView(timerInterval: s.baslangic...max(s.baslangic, s.bitis), countsDown: false) { EmptyView() } currentValueLabel: { EmptyView() }
            .tint(Renk.acikYesil)
    }
}

struct KilitEkraniEtkinligi: View {
    let c: ActivityViewContext<OdakEtkinligi>
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Renk.yesil.opacity(0.3))
                Image(systemName: c.state.molada ? "pause.fill" : "leaf.fill").font(.system(size: 22, weight: .bold)).foregroundStyle(Renk.acikYesil)
            }
            .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(c.attributes.bitki).font(.system(size: 16, weight: .heavy))
                    Text("· \(c.attributes.plan) dk").font(.system(size: 13, weight: .semibold)).foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    sayac(c.state).font(.system(size: 22, weight: .heavy, design: .rounded)).monospacedDigit().frame(maxWidth: 96, alignment: .trailing)
                }
                Text(c.state.molada ? "Molada; dönünce sayaç sürer" : c.attributes.konu).font(.system(size: 12.5, weight: .semibold)).foregroundStyle(.white.opacity(0.75))
                ilerleme(c.state)
            }
        }
        .foregroundStyle(.white)
        .padding(16)
    }
}

// MARK: Denetim Merkezi

struct OdaklanKontrolu: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "ihya.kontrol.odak") {
            ControlWidgetButton(action: OdaklanNiyeti()) {
                Label("Odaklan", systemImage: "leaf.fill")
            }
        }
        .displayName("Odaklan")
        .description("İhya'da yeni bir odak oturumu açar.")
    }
}

struct SeslerKontrolu: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "ihya.kontrol.sesler") {
            ControlWidgetButton(action: SeslerNiyeti()) {
                Label("Odak sesleri", systemImage: "waveform")
            }
        }
        .displayName("Odak sesleri")
        .description("İhya'da odak sesleri ekranını açar.")
    }
}
