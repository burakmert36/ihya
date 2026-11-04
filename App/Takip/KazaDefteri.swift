import SwiftUI

/// Kaza defteri: her vakit için borç sayısı; "kıldım" ile düşer, "ekle" ile artar.
/// Son üç günde kısmen işaretlenmiş günlerin eksik vakitlerini kazaya eklemeyi önerir.
struct KazaKarti: View {
    @Environment(Depo.self) private var depo
    @Environment(\.palet) private var palet
    @State private var duzenle = false

    var body: some View {
        let toplam = depo.kayit.kaza.values.reduce(0, +)
        let oneri = depo.kazaOnerisi()
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Kaza defteri").font(.kalin(16))
                Spacer()
                Text("\(toplam)").font(.system(size: 28, weight: .heavy)).monospacedDigit().foregroundStyle(palet.vurgu)
                    .contentTransition(.numericText(value: Double(toplam)))
                Text("vakit borç").font(.system(size: 12, weight: .bold)).foregroundStyle(.secondary)
            }
            if !oneri.isEmpty {
                let adet = oneri.reduce(0) { $0 + $1.vakitler.count }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Son günlerde işaretlenmemiş \(adet) vakit var: " + oneri.map { o in
                        "\(Tarihler.gunAy.string(from: Depo.tarih(o.gun))) " + o.vakitler.compactMap { v in VakitAdi.namazlar.first { $0.0 == v }?.1 }.joined(separator: ", ")
                    }.joined(separator: "; ") + ". Kazaya eklensin mi?")
                        .font(.system(size: 13, weight: .medium))
                    HStack(spacing: 8) {
                        Button { withAnimation { depo.kazaOnerisiniUygula(true) }; Dokunsal.hafif(0.6) } label: {
                            Text("Kazaya ekle").font(.kalin(13)).foregroundStyle(palet.dolguMetin)
                        }
                        .buttonStyle(.glassProminent).tint(palet.dolgu)
                        Button { withAnimation { depo.kazaOnerisiniUygula(false) } } label: {
                            Text("Kıldım, ekleme").font(.kalin(13))
                        }
                        .buttonStyle(.glass)
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color.orange.opacity(0.12)))
            }
            ForEach(Depo.kazaVakitleri, id: \.anahtar) { v in
                let n = depo.kayit.kaza[v.anahtar] ?? 0
                HStack(spacing: 10) {
                    Text(v.ad).font(.kalin(15)).frame(width: 64, alignment: .leading)
                    Text("\(n)").font(.system(size: 20, weight: .heavy)).monospacedDigit()
                        .foregroundStyle(n > 0 ? Color.primary : Color.secondary)
                        .contentTransition(.numericText(value: Double(n)))
                        .frame(minWidth: 44, alignment: .leading)
                    Spacer()
                    if duzenle {
                        Button { withAnimation { depo.kazaDegistir(v.anahtar, 1) }; Dokunsal.hafif(0.5) } label: {
                            Image(systemName: "plus").font(.system(size: 14, weight: .bold)).frame(width: 36, height: 32)
                        }
                        .buttonStyle(.glass)
                        .accessibilityLabel("\(v.ad) kazasına bir ekle")
                    }
                    Button {
                        withAnimation { depo.kazaDegistir(v.anahtar, -1) }
                        Dokunsal.basari()
                    } label: {
                        Label("Kıldım", systemImage: "checkmark").font(.kalin(13))
                    }
                    .buttonStyle(.glass)
                    .disabled(n == 0)
                    .accessibilityLabel("\(v.ad) kazasını kıldım")
                }
            }
            HStack {
                Text(duzenle ? "Borcu eklemek için artıya dokun." : "Kıldığın kaza namazını “Kıldım” ile düş.")
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                Spacer()
                Button(duzenle ? "Bitti" : "Borç ekle") { withAnimation { duzenle.toggle() } }
                    .font(.kalin(13))
            }
        }
        .camKart(kose: 28)
    }
}

extension Depo {
    /// "yyyy-MM-dd" → gün başı
    static func tarih(_ anahtar: String) -> Date {
        let p = anahtar.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3 else { return .now }
        return Calendar.current.date(from: DateComponents(year: p[0], month: p[1], day: p[2])) ?? .now
    }
}
