import SwiftUI

extension Depo {
    /// Şu an geçerli okuma teması ("kendiliğinden" seçiliyse akşamdan imsaka gece).
    func okumaTemasi(_ v: VakitServisi) -> OkumaTemasi { ayarlar.etkinOkumaTemasi(gece: v.geceMi()) }
}

/// Mavi ışığı azaltan amber katman (okuma ekranlarında).
private struct SicakIsik: ViewModifier {
    @Environment(Depo.self) private var depo
    func body(content: Content) -> some View {
        content.overlay {
            Color(red: 1, green: 0.66, blue: 0.32)
                .opacity(depo.ayarlar.sicakIsik * 0.42)
                .blendMode(.multiply)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

extension View {
    func sicakIsik() -> some View { modifier(SicakIsik()) }
}

/// Okuma ayarları: tema, yazı boyutu, satır arası, sıcak ışık, ekranın açık kalması.
struct OkumaAyarlariSayfasi: View {
    @Environment(Depo.self) private var depo
    @Environment(VakitServisi.self) private var vakit
    @Environment(\.palet) private var palet
    @Environment(\.dismiss) private var kapat

    var body: some View {
        let a = depo.ayarlar
        let etkin = depo.okumaTemasi(vakit)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Önizleme
                    VStack(alignment: .leading, spacing: 8) {
                        Text("“Amellerin Allah'a en sevgili olanı, az olsa bile en devamlı yapılanıdır.”")
                            .font(.okuma(a.okumaPunto))
                            .lineSpacing(a.satirBoslugu(a.okumaPunto))
                        Text("Buhârî, 6464").font(.caption.weight(.bold)).foregroundStyle(Color.altin)
                    }
                    .okumaKarti()
                    .sicakIsik()

                    bolum("Tema") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                            ForEach(OkumaTemasi.allCases) { t in
                                let secili = a.okumaTemasi == t
                                Button { depo.degistir { $0.ayarlar.okumaTemasi = t }; Dokunsal.hafif(0.5) } label: {
                                    VStack(spacing: 6) {
                                        ZStack {
                                            if t == .otomatik {
                                                HStack(spacing: 0) {
                                                    Color(hex: OkumaTemasi.gunduz.zemin)
                                                    Color(hex: OkumaTemasi.gece.zemin)
                                                }
                                            } else {
                                                Color(hex: t.zemin)
                                            }
                                            Text("Aa").font(.system(size: 17, weight: .semibold, design: .serif))
                                                .foregroundStyle(Color(hex: t == .otomatik ? "#8A8172" : t.yazi))
                                        }
                                        .frame(height: 48)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(secili ? palet.vurgu : Color.primary.opacity(0.15), lineWidth: secili ? 2 : 1))
                                        Text(t.ad).font(.system(size: 10.5, weight: .bold)).lineLimit(1).minimumScaleFactor(0.7)
                                            .foregroundStyle(secili ? palet.vurgu : .secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(t.ad) teması")
                                .accessibilityAddTraits(secili ? .isSelected : [])
                            }
                        }
                        if a.okumaTemasi == .otomatik {
                            Text("Akşam ezanından imsaka kadar gece, öbür saatlerde gündüz teması. Şu an: \(etkin.ad).")
                                .font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                        }
                    }

                    bolum("Yazı boyutu") {
                        HStack(spacing: 12) {
                            Image(systemName: "textformat.size.smaller").foregroundStyle(.secondary)
                            Slider(value: depo.ayar(\.okumaPunto), in: 14...30, step: 1)
                            Image(systemName: "textformat.size.larger").foregroundStyle(.secondary)
                            Text("\(Int(a.okumaPunto))").font(.kalin(14)).monospacedDigit().frame(width: 26)
                        }
                    }

                    bolum("Satır arası") {
                        CamSegment(secenekler: [0, 1, 2], secili: depo.ayar(\.satirAraligi), ad: { ["Sık", "Rahat", "Geniş"][$0] })
                    }

                    bolum("Sıcak ışık") {
                        HStack(spacing: 12) {
                            Image(systemName: "sun.min").foregroundStyle(.secondary)
                            Slider(value: depo.ayar(\.sicakIsik), in: 0...1)
                                .tint(Color(red: 1, green: 0.62, blue: 0.25))
                            Image(systemName: "sun.max.fill").foregroundStyle(Color(red: 1, green: 0.62, blue: 0.25))
                        }
                        Text("Okuma ekranlarına mavi ışığı azaltan amber bir katman koyar; gece okurken gözü yormaz.")
                            .font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                    }

                    Toggle(isOn: depo.ayar(\.ekranAcik)) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Okurken ekran kapanmasın").font(.kalin(15))
                            Text("Kur'an, hadis, dua ve kitap okurken ekran kararmaz.").font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                        }
                    }
                    .camKart(kose: 22, ic: 14)
                }
                .padding(16)
            }
            .sahne(.ayarlar)
            .navigationTitle("Okuma")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Bitti") { kapat() } } }
        }
    }

    private func bolum<I: View>(_ baslik: String, @ViewBuilder _ icerik: () -> I) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            BolumBasligi(metin: baslik)
            icerik()
        }
        .camKart(kose: 22, ic: 14)
    }
}
