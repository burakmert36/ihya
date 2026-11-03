import SwiftUI

/// Esmâ-ül Hüsnâ: sade bir ızgara, sekiz köşeli yıldız motifi; dokununca anlam ve açıklama.
struct EsmaEkrani: View {
    @State private var secili: EsmaIsmi?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text("الأسماء الحسنى").font(.arapca(34, kalin: true)).foregroundStyle(Color.ihya)
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
        .background(MotifDeseni(renk: .ihya, aralik: 56).ignoresSafeArea().opacity(0.6))
        .navigationTitle("Esmâ-ül Hüsnâ")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $secili) { e in
            EsmaDetay(baslangic: e).presentationDetents([.medium, .large])
        }
    }
}

struct EsmaKaresi: View {
    let isim: EsmaIsmi
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                SekizKoseYildiz(ic: 0.7)
                    .stroke(Color.ihya.opacity(0.35), lineWidth: 1)
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
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 18))
    }
}

struct EsmaDetay: View {
    let baslangic: EsmaIsmi
    @State private var sira = 0

    var body: some View {
        let liste = Icerik.esma
        let e = liste.indices.contains(sira) ? liste[sira] : baslangic
        VStack(spacing: 18) {
            ZStack {
                SekizKoseYildiz(ic: 0.72).fill(Color.ihya.opacity(0.10)).frame(width: 190, height: 190)
                SekizKoseYildiz(ic: 0.72).stroke(Color.ihya.opacity(0.5), lineWidth: 1.5).frame(width: 190, height: 190)
                SekizKoseYildiz(ic: 0.72).stroke(Color.ihya.opacity(0.25), lineWidth: 1).frame(width: 150, height: 150).rotationEffect(.degrees(22.5))
                Text(e.arapca)
                    .font(.arapca(e.arapca.count > 9 ? 30 : 44, kalin: true))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .frame(width: 150)
            }
            .padding(.top, 24)
            VStack(spacing: 8) {
                Text(e.ad).font(.title.weight(.semibold))
                Text(e.anlam).font(.headline).multilineTextAlignment(.center)
                Text(e.aciklama).font(.okuma(17)).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .id(e.no)
            .transition(.opacity)
            Spacer(minLength: 0)
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
            .padding(.bottom, 16)
        }
        .onAppear { sira = max(0, baslangic.no - 1) }
    }
}
