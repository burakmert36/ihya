import SwiftUI

struct DiniGunlerEkrani: View {
    var body: some View {
        let bugun = Calendar.current.startOfDay(for: .now)
        let gelecek = Icerik.diniGunler.filter { $0.gun >= bugun }
        let gecmis = Icerik.diniGunler.filter { $0.gun < bugun }
        List {
            if let ilk = gelecek.first {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sıradaki").font(.caption.weight(.semibold)).foregroundStyle(Color.ihya)
                        Text(ilk.ad).font(.title2.weight(.semibold))
                        Text(Tarihler.gunAyGun.string(from: ilk.gun)).font(.subheadline)
                        Text(kalan(ilk.gun, bugun)).font(.headline).foregroundStyle(Color.ihya)
                        if !ilk.aciklama.isEmpty { Text(ilk.aciklama).font(.footnote).foregroundStyle(.secondary) }
                    }
                    .padding(.vertical, 6)
                }
            }
            ForEach(yillar(Array(gelecek.dropFirst()))) { grup in
                Section(String(grup.yil)) {
                    ForEach(grup.gunler) { g in GunSatiri(gun: g, kalan: kalan(g.gun, bugun)) }
                }
            }
            if !gecmis.isEmpty {
                Section("Geçenler") {
                    ForEach(gecmis.reversed()) { g in GunSatiri(gun: g, kalan: "").opacity(0.5) }
                }
            }
            Section {
                Text("Tarihler Diyanet İşleri Başkanlığı'nın dinî günler takviminden alınmıştır. Kandil, belirtilen günün akşamıyla başlayan gecedir.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Dinî Günler")
        .navigationBarTitleDisplayMode(.inline)
    }

    private struct YilGrubu: Identifiable { let yil: Int; let gunler: [DiniGun]; var id: Int { yil } }

    private func yillar(_ liste: [DiniGun]) -> [YilGrubu] {
        let g = Dictionary(grouping: liste) { Calendar.current.component(.year, from: $0.gun) }
        return g.keys.sorted().map { YilGrubu(yil: $0, gunler: g[$0] ?? []) }
    }

    private func kalan(_ gun: Date, _ bugun: Date) -> String {
        let n = Calendar.current.dateComponents([.day], from: bugun, to: gun).day ?? 0
        return n == 0 ? "Bugün" : n == 1 ? "Yarın" : "\(n) gün kaldı"
    }
}

private struct GunSatiri: View {
    let gun: DiniGun
    let kalan: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: gun.tur == "bayram" ? "star.fill" : gun.tur == "kandil" ? "moon.stars.fill" : gun.tur == "arefe" ? "sunset.fill" : "calendar")
                .foregroundStyle(gun.tur == "bayram" ? Color.orange : Color.ihya)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(gun.ad).font(.body)
                Text(Tarihler.gunAyGun.string(from: gun.gun)).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(kalan).font(.caption).foregroundStyle(.secondary).monospacedDigit()
        }
    }
}
