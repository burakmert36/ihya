import SwiftUI

/// Esmâ-ül Hüsnâ: sade bir ızgara, sekiz köşeli yıldız motifi; dokununca anlam ve açıklama.
struct EsmaEkrani: View {
    @Environment(\.palet) private var palet
    @Environment(Yonlendirici.self) private var yon
    @State private var secili: EsmaIsmi?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text("الأسماء الحسنى").font(.arapca(34, kalin: true)).foregroundStyle(palet.vurgu)
                    Text("“En güzel isimler Allah'ındır, O'na o isimlerle dua edin.” (A'râf 7:180)")
                        .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .padding(.vertical, 8)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(Icerik.esma) { e in
                        Button { secili = e } label: { EsmaKaresi(isim: e) }
                            .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(MotifDeseni(renk: palet.vurgu, aralik: 56).ignoresSafeArea().opacity(0.6))
        .navigationTitle("Esmâ-ül Hüsnâ")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $secili) { e in
            EsmaDetay(baslangic: e).presentationDetents([.large]).presentationDragIndicator(.visible)
        }
        .onAppear {
            if let n = yon.esmaAc, Icerik.esma.indices.contains(n - 1) { secili = Icerik.esma[n - 1] }
            yon.esmaAc = nil
        }
    }
}

struct EsmaKaresi: View {
    @Environment(\.palet) private var palet
    let isim: EsmaIsmi
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                SekizKoseYildiz(ic: 0.7)
                    .stroke(palet.vurgu.opacity(0.35), lineWidth: 1)
                    .frame(width: 70, height: 70)
                Text(isim.arapca)
                    .font(.arapca(isim.arapca.count > 9 ? 15 : 21, kalin: true))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .frame(width: 66)
            }
            .frame(height: 74)
            Text(isim.ad).font(.caption.weight(.medium)).lineLimit(1).minimumScaleFactor(0.7)
            Text("\(isim.no)").font(.caption2).foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .camYuzey(.regular.interactive(), in: .rect(cornerRadius: 18))
    }
}

/// İsmin detayı: anlamı, açıklaması ve o isimle yapılan dualar (Buhârî, Kur'an duaları, âyetler).
struct EsmaDetay: View {
    @Environment(\.palet) private var palet
    let baslangic: EsmaIsmi
    @State private var sira = 0

    var body: some View {
        let liste = Icerik.esma
        let e = liste.indices.contains(sira) ? liste[sira] : baslangic
        let dualar = Icerik.esmaDualari(e.no)
        ScrollView {
            VStack(spacing: 16) {
                ZStack {
                    SekizKoseYildiz(ic: 0.72).fill(palet.vurgu.opacity(0.10)).frame(width: 170, height: 170)
                    SekizKoseYildiz(ic: 0.72).stroke(palet.vurgu.opacity(0.5), lineWidth: 1.5).frame(width: 170, height: 170)
                    SekizKoseYildiz(ic: 0.72).stroke(palet.vurgu.opacity(0.25), lineWidth: 1).frame(width: 134, height: 134).rotationEffect(.degrees(22.5))
                    Text(e.arapca)
                        .font(.arapca(e.arapca.count > 9 ? 28 : 40, kalin: true))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .frame(width: 134)
                }
                .padding(.top, 28)
                VStack(spacing: 8) {
                    Text(e.ad).font(.title.weight(.semibold))
                    Text(e.anlam).font(.headline).multilineTextAlignment(.center)
                    Text(e.aciklama).font(.okuma(17)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .padding(.horizontal, 8)
                if !dualar.isEmpty {
                    BolumBasligi(metin: "Bu isimle dua", simge: "hands.and.sparkles")
                        .padding(.top, 10)
                    ForEach(Array(dualar.enumerated()), id: \.offset) { _, d in EsmaDuaKarti(dua: d) }
                    Text("“En güzel isimler Allah'ındır; O'na o isimlerle dua edin.” (A'râf 7:180)")
                        .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .id(e.no)
        .transition(.opacity)
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button { withAnimation { sira = max(0, sira - 1) } } label: { Label("Önceki", systemImage: "chevron.left") }
                    .disabled(sira == 0)
                Spacer()
                Text("\(e.no) / \(liste.count)").font(.footnote).foregroundStyle(.secondary).monospacedDigit()
                Spacer()
                Button { withAnimation { sira = min(liste.count - 1, sira + 1) } } label: { Label("Sonraki", systemImage: "chevron.right").labelStyle(.titleAndIcon) }
                    .disabled(sira >= liste.count - 1)
            }
            .buttonStyle(.glass)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .onAppear { sira = max(0, baslangic.no - 1) }
    }
}

/// Bir isme özel dua kartı: türü ve kaynağı, Arapçası, okunuşu, anlamı.
struct EsmaDuaKarti: View {
    @Environment(\.palet) private var palet
    @Environment(Depo.self) private var depo
    let dua: EsmaDuasi

    var body: some View {
        let p = depo.ayarlar.okumaPunto
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(dua.tur.uppercased(with: Locale(identifier: "tr_TR")))
                    .font(.kalin(10)).tracking(0.8).foregroundStyle(palet.vurgu)
                Spacer(minLength: 4)
                Text(dua.kaynak).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            Text(dua.baslik).font(.headline)
            Text(dua.arapca)
                .font(.arapca(p + 6))
                .lineSpacing(p * 0.45)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .textSelection(.enabled)
            Text(dua.okunus).font(.system(size: p - 2, design: .serif)).italic().foregroundStyle(palet.vurgu)
                .textSelection(.enabled)
            Text(dua.anlam).font(.okuma(p - 1)).lineSpacing(p * 0.2).textSelection(.enabled)
            if let n = dua.not, !n.isEmpty {
                Text(n).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .camKart()
    }
}
