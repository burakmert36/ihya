import SwiftUI

/// Vakit sekmesi: sıradaki vakit kartı ve 30 günlük cetvel (tasarımdaki VakitCetveli).
struct VakitlerEkrani: View {
    @Environment(VakitServisi.self) private var vakit
    @Environment(\.palet) private var palet

    var body: some View {
        let simdi = Date()
        ScrollView {
            VStack(spacing: 12) {
                SahneBasligi(ust: "\(vakit.konumAdi) · \(vakit.kip == .bursa ? "Diyanet" : "hesap")", baslik: "Vakitler") {
                    Text(BugunEkrani.hicriKisa(vakit.hicri(simdi)).capitalized(with: Locale(identifier: "tr_TR")))
                            .font(.kalin(12.5))
                            .foregroundStyle(Color(hex: palet.koyu ? "#FFD08A" : "#6A3A00"))
                            .lineLimit(1).minimumScaleFactor(0.7)
                            .padding(.horizontal, 12).frame(height: 34)
                            .glassEffect(palet.cam(), in: .capsule)
                            .padding(.bottom, 4)
                }
                TimelineView(.periodic(from: .now, by: 1)) { an in
                    let d = vakit.durum(an.date)
                    let bugun = vakit.vakitler(an.date)
                    let k = bugun.firstIndex { $0 > an.date }
                    let kalan = max(0, Int(d.sonrakiZaman.timeIntervalSince(an.date)))
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("\(VakitAdi.adlar[d.sonraki]) vaktine").font(.kalin(15))
                            Spacer()
                            Text(DateFormatter.tr("EEE, d MMM").string(from: an.date)).font(.system(size: 13, weight: .bold)).foregroundStyle(.secondary)
                        }
                        Text(kalan >= 3600 ? "\(kalan / 3600) sa \(kalan % 3600 / 60) dk" : String(format: "%d:%02d", kalan / 60, kalan % 60))
                            .font(.system(size: 46, weight: .heavy)).monospacedDigit().tracking(-1)
                            .contentTransition(.numericText(countsDown: true))
                        HStack(spacing: 4) {
                            ForEach(0..<6, id: \.self) { j in
                                let simdi = j == (k ?? 0)
                                VStack(spacing: 2) {
                                    Text(VakitAdi.adlar[j]).font(.kalin(10.5)).lineLimit(1).minimumScaleFactor(0.8)
                                        .foregroundStyle(simdi ? Color.white.opacity(0.9) : Color.secondary)
                                    Text(Tarihler.saat.string(from: bugun[j])).font(.kalin(14)).monospacedDigit()
                                        .foregroundStyle(simdi ? Color.white : Color.primary)
                                        .lineLimit(1).minimumScaleFactor(0.8)
                                }
                                .frame(maxWidth: .infinity, minHeight: 58)
                                .background {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(simdi ? AnyShapeStyle(LinearGradient(colors: [Color(hex: "#FFB25C"), Color(hex: "#F07A1F")], startPoint: .top, endPoint: .bottom))
                                              : AnyShapeStyle(Color.white.opacity(palet.koyu ? 0.07 : 0.45)))
                                        .shadow(color: simdi ? Color(r: 240, g: 120, b: 30, a: 0.35) : .clear, radius: 8, y: 5)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                    .camKart(kose: 30)
                }
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color(hex: "#1FB25A"))
                    Text(durumSatiri(simdi)).font(.system(size: 12, weight: .bold)).lineLimit(1).minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 6)
                cetvel(simdi)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func durumSatiri(_ simdi: Date) -> String {
        let son = Calendar.current.date(byAdding: .day, value: 29, to: simdi)!
        let kaynak = vakit.kip == .bursa && vakit.gunVakti(simdi) != nil ? "Diyanet cetveli" : "Diyanet yöntemiyle hesap"
        return "\(kaynak) · \(Tarihler.kisaGun.string(from: simdi)) – \(Tarihler.kisaGun.string(from: son)) · 30 gün"
    }

    private func cetvel(_ simdi: Date) -> some View {
        let sutunlar = [GridItem(.fixed(62), spacing: 0)] + Array(repeating: GridItem(.flexible(), spacing: 0), count: 6)
        return VStack(spacing: 0) {
            LazyVGrid(columns: sutunlar, spacing: 0) {
                Text("Tarih").frame(maxWidth: .infinity, alignment: .leading)
                ForEach(VakitAdi.adlar, id: \.self) { Text($0).lineLimit(1).minimumScaleFactor(0.7) }
            }
            .font(.kalin(10.5))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .frame(height: 38)
            .background(Color.white.opacity(palet.koyu ? 0.06 : 0.45))
            ForEach(0..<30, id: \.self) { g in
                let gun = Calendar.current.date(byAdding: .day, value: g, to: Calendar.current.startOfDay(for: simdi))!
                let saatler = vakit.vakitler(gun)
                let cuma = Calendar.current.component(.weekday, from: gun) == 6
                LazyVGrid(columns: sutunlar, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(DateFormatter.tr("d MMM EEE").string(from: gun)).font(.system(size: 12, weight: .bold)).lineLimit(1).minimumScaleFactor(0.7)
                        Text(BugunEkrani.hicriKisa(vakit.hicri(gun)).split(separator: " ").prefix(2).joined(separator: " ").capitalized(with: Locale(identifier: "tr_TR")))
                            .font(.system(size: 9.5, weight: .medium)).foregroundStyle(.secondary).lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(0..<min(6, saatler.count), id: \.self) { i in
                        Text(Tarihler.saat.string(from: saatler[i])).font(.system(size: 12.5, weight: g == 0 ? .bold : .regular)).monospacedDigit()
                            .lineLimit(1).minimumScaleFactor(0.8)
                    }
                }
                .padding(.horizontal, 10)
                .frame(height: 40)
                .background(g == 0 ? Color(r: 255, g: 220, b: 170, a: palet.koyu ? 0.22 : 0.6) : cuma ? Color.white.opacity(palet.koyu ? 0.04 : 0.22) : Color.clear)
                .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(palet.koyu ? 0.08 : 0.55)).frame(height: 0.5) }
            }
            Text("Kaynak: Diyanet İşleri Başkanlığı, Bursa merkez (ilçe no 9335). Cetvel telefonda saklanır ve gün aşırı yenilenir; internet yoksa Diyanet yöntemiyle hesaplanır (±1 dk).")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .clipShape(.rect(cornerRadius: 28))
        .glassEffect(palet.cam(), in: .rect(cornerRadius: 28))
    }
}
