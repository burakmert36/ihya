import SwiftUI

struct VakitlerEkrani: View {
    @Environment(VakitServisi.self) private var vakit

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { an in
            let d = vakit.durum(an.date)
            let bugun = vakit.vakitler(an.date)
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(VakitAdi.vaktine(d.sonraki)).font(.title2.weight(.semibold))
                        Text(timerInterval: an.date...max(an.date, d.sonrakiZaman), countsDown: true)
                            .font(.system(size: 44, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(Color.ihya)
                        Text("\(vakit.konumAdi) · \(vakit.hicri(an.date))").font(.footnote).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }
                Section {
                    ForEach(0..<6, id: \.self) { i in
                        HStack {
                            Text(VakitAdi.adlar[i])
                            Spacer()
                            Text(Tarihler.saat.string(from: bugun[i])).monospacedDigit()
                        }
                        .font(.body.weight(i == d.simdiki ? .semibold : .regular))
                        .foregroundStyle(i == d.simdiki ? Color.ihya : .primary)
                    }
                } header: {
                    Text("Bugün").textCase(nil)
                }
                Section {
                    AylikBaslik()
                    ForEach(0..<30, id: \.self) { g in
                        let gun = Calendar.current.date(byAdding: .day, value: g, to: Calendar.current.startOfDay(for: an.date))!
                        AylikSatir(gun: gun, saatler: vakit.vakitler(gun), bugun: g == 0)
                    }
                } header: {
                    Text("Otuz Günlük Takvim").textCase(nil)
                }
            }
        }
        .navigationTitle("Vakitler")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AylikBaslik: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("Gün").frame(width: 58, alignment: .leading)
            ForEach(["İms", "Gün", "Öğl", "İki", "Akş", "Yat"], id: \.self) { Text($0).frame(maxWidth: .infinity) }
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
    }
}

private struct AylikSatir: View {
    let gun: Date
    let saatler: [Date]
    let bugun: Bool
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(Tarihler.kisaGun.string(from: gun)).font(.caption.weight(.semibold))
                Text(Tarihler.haftaGunuKisa.string(from: gun)).font(.caption2).foregroundStyle(.secondary)
            }
            .frame(width: 58, alignment: .leading)
            ForEach(0..<min(6, saatler.count), id: \.self) { i in
                Text(Tarihler.saat.string(from: saatler[i])).frame(maxWidth: .infinity)
            }
            .font(.caption.monospacedDigit())
        }
        .foregroundStyle(bugun ? Color.ihya : .primary)
        .listRowBackground(bugun ? Color.ihya.opacity(0.08) : nil)
    }
}
