import SwiftUI

struct KoleksiyonEkrani: View {
    @Environment(\.palet) private var palet
    @Environment(Depo.self) private var depo
    @State private var agac = false
    @State private var secili: BitkiTuru?
    @State private var kutlanan: BitkiTuru?

    var body: some View {
        let liste = BitkiKatalogu.tumu.filter { $0.agac == agac }
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(depo.kayit.tohum) tohum").font(.title2.weight(.semibold))
                        Text("\(depo.kayit.acik.count)/\(BitkiKatalogu.tumu.count) tür açık · tohum yalnız kilit açar, dikmek ücretsiz")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "leaf.circle.fill").font(.largeTitle).foregroundStyle(palet.vurgu)
                }
                .camKart(palet.vurgu)
                Picker("Tür", selection: $agac) {
                    Text("Çiçekler").tag(false)
                    Text("Ağaçlar").tag(true)
                }
                .pickerStyle(.segmented)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                    ForEach(liste) { b in
                        Button { secili = b } label: { KoleksiyonHucresi(tur: b, acik: depo.acikMi(b.id)) }
                            .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .navigationTitle("Koleksiyon")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $secili) { b in
            BitkiDetay(tur: b) { acilan in
                secili = nil
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    kutlanan = acilan
                }
            }
            .sahne(.bahce)
            .presentationDetents([.large])
        }
        .overlay {
            if let k = kutlanan {
                KilitKutlamasi(tur: k) { withAnimation { kutlanan = nil } }
                    .transition(.opacity)
            }
        }
    }
}

struct KoleksiyonHucresi: View {
    @Environment(\.palet) private var palet
    let tur: BitkiTuru
    let acik: Bool
    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                BitkiResmi(tur: tur.id, dk: Double(tur.dk), tohum: 7, lod: 0.6, siluet: !acik, sigdir: true)
                    .frame(height: 96)
                if tur.nadide {
                    Image(systemName: "sparkles").font(.caption).foregroundStyle(Color(red: 0.9, green: 0.65, blue: 0.1))
                }
            }
            Text(tur.ad).font(.footnote.weight(.medium)).lineLimit(1).minimumScaleFactor(0.8)
            HStack(spacing: 4) {
                if acik {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(palet.vurgu)
                    Text("\(tur.dk) dk")
                } else {
                    Image(systemName: "lock.fill")
                    Text("\(tur.fiyat)")
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .camYuzey(acik ? Glass.regular : Glass.regular.tint(Color.secondary.opacity(0.08)), in: .rect(cornerRadius: 18))
    }
}

struct BitkiDetay: View {
    @Environment(Depo.self) private var depo
    @Environment(\.dismiss) private var kapat
    let tur: BitkiTuru
    let acildi: (BitkiTuru) -> Void

    var body: some View {
        let acik = depo.acikMi(tur.id)
        let yeter = depo.kayit.tohum >= tur.fiyat
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    BitkiResmi(tur: tur.id, dk: Double(tur.dk), tohum: 7, siluet: !acik, sigdir: true)
                        .frame(height: 250)
                    VStack(spacing: 6) {
                        Text(tur.ad).font(.title.weight(.bold))
                        Text("\(tur.agac ? "Ağaç" : "Çiçek") · \(tur.dk) dakikada tam form\(tur.nadide ? " · nadide" : "")")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    Text(tur.not).font(.okuma(17)).multilineTextAlignment(.center).padding(.horizontal, 8)
                    VStack(alignment: .leading, spacing: 10) {
                        BolumBasligi(metin: "Evreler", simge: "chart.line.uptrend.xyaxis")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(tur.temel, id: \.self) { e in
                                    VStack(spacing: 4) {
                                        BitkiResmi(tur: tur.id, dk: max(0.5, e.son - 0.01), tohum: 7, cerceve: CGRect(x: -4, y: -10, width: 108, height: 128), lod: 0.6, siluet: !acik)
                                            .frame(width: 70, height: 84)
                                        Text(e.ad).font(.caption2).lineLimit(1)
                                        Text("\(Int(e.son)) dk").font(.caption2).foregroundStyle(.secondary)
                                    }
                                    .frame(width: 80)
                                }
                            }
                        }
                        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
                        if tur.dk < 120 {
                            Text("\(tur.dk) dakikadan sonra da büyür; 120 dakikada \(tur.evreler.last?.ad.lowercased(with: Locale(identifier: "tr_TR")) ?? "en büyük hâline") olur.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    .camKart()
                    if !acik {
                        Button {
                            if depo.kilidiAc(tur.id, fiyat: tur.fiyat) {
                                acildi(tur)
                            }
                        } label: {
                            Label(yeter ? "\(tur.fiyat) tohumla aç" : "\(tur.fiyat - depo.kayit.tohum) tohum daha gerekli", systemImage: yeter ? "lock.open.fill" : "lock.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glassProminent)
                        .controlSize(.large)
                        .disabled(!yeter)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { kapat() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Kapat")
                }
            }
        }
    }
}
