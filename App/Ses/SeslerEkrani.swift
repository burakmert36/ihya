import SwiftUI

/// Odak sesleri (tasarımdaki OdakSesleri): oynatıcı kartı, karışımlar, her ses için düzey ve uzaklık, alt ayarlar.
struct SeslerEkrani: View {
    @Environment(SesMotoru.self) private var ses
    @Environment(Depo.self) private var depo
    @Environment(\.palet) private var palet
    @State private var adSor = false
    @State private var yeniAd = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text("Uygulamadan çıksan, ekran kilitlense de çalar")
                    .font(.system(size: 12.5, weight: .semibold)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                oynatici
                karisimlar
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(SesTuru.tumu) { t in SesKaresi(tur: t) }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .safeAreaInset(edge: .bottom) { altAyarlar }
        .navigationTitle("Odak sesleri")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if ses.katman.isEmpty, !depo.kayit.sonKatman.isEmpty { ses.yukle(depo.kayit.sonKatman, mesafe: depo.kayit.sonMesafe, baslat: false) }
        }
        .alert("Karışımı kaydet", isPresented: $adSor) {
            TextField("Karışım adı", text: $yeniAd)
            Button("Kaydet") { kaydet() }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("Seçili \(ses.katman.count) ses bu adla saklanır.")
        }
    }

    private var karisimAdi: String {
        depo.kayit.karisimlar.first { $0.katman.keys.sorted() == ses.katman.keys.sorted() }?.ad
            ?? (ses.katman.isEmpty ? "Ses seç" : SesTuru.tumu.filter { ses.katman[$0.id] != nil }.prefix(2).map(\.ad).joined(separator: " ve "))
    }

    private var oynatici: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Button { ses.degistirOynat() } label: {
                    Image(systemName: ses.caliyor ? "pause.fill" : "play.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: 64, height: 64)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.tint(Color(hex: "#1FB25A").opacity(0.9)).interactive(), in: .circle)
                .disabled(ses.katman.isEmpty)
                .accessibilityLabel(ses.caliyor ? "Duraklat" : "Çal")
                VStack(alignment: .leading, spacing: 3) {
                    Text(karisimAdi).font(.system(size: 20, weight: .heavy)).lineLimit(1).minimumScaleFactor(0.7)
                    Text("\(ses.katman.count) katman · \(ses.caliyor ? "çalıyor" : "duraklatıldı")\(ses.katman.isEmpty ? "" : " · " + ses.seciliAdlar)")
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary).lineLimit(2)
                }
            }
            HStack(spacing: 10) {
                Image(systemName: "speaker.fill").font(.system(size: 12)).foregroundStyle(.secondary)
                Slider(value: Binding(get: { ses.anaDuzey }, set: { ses.ana($0) }), in: 0...1)
                    .tint(Color(hex: "#7FC4FF"))
                Text("\(Int((ses.anaDuzey * 100).rounded()))").font(.kalin(14)).monospacedDigit().frame(width: 34, alignment: .trailing)
            }
            HStack(spacing: 6) {
                zamanCipi("Oturumla bitsin", secili: depo.ayarlar.sesOdakta && ses.uykuBitis == nil) {
                    depo.degistir { $0.ayarlar.sesOdakta = true }; ses.uyku(nil)
                }
                zamanCipi("30 dk", secili: uykuDk == 30) { depo.degistir { $0.ayarlar.sesOdakta = false }; ses.uyku(30) }
                zamanCipi("60 dk", secili: uykuDk == 60) { depo.degistir { $0.ayarlar.sesOdakta = false }; ses.uyku(60) }
                zamanCipi("Sınırsız", secili: !depo.ayarlar.sesOdakta && ses.uykuBitis == nil) {
                    depo.degistir { $0.ayarlar.sesOdakta = false }; ses.uyku(nil)
                }
            }
            if let h = ses.hata {
                Label(h, systemImage: "exclamationmark.triangle.fill").font(.system(size: 12, weight: .semibold)).foregroundStyle(Color(hex: "#FFB45C"))
            }
            if ses.katman.count >= SesMotoru.enFazla {
                Text("En çok \(SesMotoru.enFazla) ses birlikte çalar.").font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
            }
        }
        .camKart(kose: 30)
    }

    /// Zamanlayıcının yaklaşık seçimi (30 / 60).
    private var uykuDk: Int? {
        guard let b = ses.uykuBitis else { return nil }
        return b.timeIntervalSinceNow > 31 * 60 ? 60 : 30
    }

    private func zamanCipi(_ ad: String, secili: Bool, _ eylem: @escaping () -> Void) -> some View {
        Button { eylem(); Dokunsal.hafif(0.4) } label: {
            Text(ad).font(.kalin(12)).lineLimit(1).minimumScaleFactor(0.7)
                .foregroundStyle(secili ? Color(hex: "#0D1B2E") : Color.primary)
                .frame(maxWidth: .infinity, minHeight: 34)
                .background(Capsule().fill(secili ? Color.white.opacity(0.92) : Color.white.opacity(0.08)))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(secili ? .isSelected : [])
    }

    private var karisimlar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    yeniAd = ""
                    adSor = true
                } label: {
                    Label("Kaydet", systemImage: "plus").font(.kalin(13)).padding(.horizontal, 14).frame(height: 38)
                }
                .buttonStyle(.plain)
                .glassEffect(palet.cam(etkilesimli: true), in: .capsule)
                .disabled(ses.katman.isEmpty)
                .opacity(ses.katman.isEmpty ? 0.5 : 1)
                ForEach(depo.kayit.karisimlar) { k in
                    let on = ses.katman.keys.sorted() == k.katman.keys.sorted()
                    Button {
                        ses.yukle(k.katman, mesafe: k.mesafe ?? [:], baslat: true)
                        Dokunsal.hafif()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: SesTuru.bul(k.katman.keys.sorted().first ?? "")?.simge ?? "waveform")
                            Text(k.ad).lineLimit(1)
                        }
                        .font(.kalin(13))
                        .foregroundStyle(on ? Color.white : Color.primary)
                        .padding(.horizontal, 14)
                        .frame(height: 38)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(on ? Glass.regular.tint(Color(hex: "#1FB25A").opacity(0.85)).interactive() : palet.cam(etkilesimli: true), in: .capsule)
                    .contextMenu {
                        Button("Sil", systemImage: "trash", role: .destructive) {
                            depo.degistir { $0.karisimlar.removeAll { $0.id == k.id } }
                        }
                    }
                }
                if !ses.katman.isEmpty {
                    Button { ses.hepsiniKis(); Dokunsal.hafif() } label: {
                        Label("Hepsini kıs", systemImage: "speaker.slash").font(.kalin(13)).padding(.horizontal, 14).frame(height: 38)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(palet.cam(etkilesimli: true), in: .capsule)
                }
            }
            .padding(.vertical, 2)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
    }

    private var altAyarlar: some View {
        HStack(spacing: 6) {
            altDugme("Bitince yavaşça kıs", \.sesSondaAzalt)
            altDugme("Ezan vaktinde sustur", \.ezandaSustur)
            altDugme("Kur’an dinlerken kıs", \.kuranDinlerkenKis)
        }
        .padding(6)
        .glassEffect(palet.cam(), in: .rect(cornerRadius: 28))
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }

    private func altDugme(_ ad: String, _ yol: WritableKeyPath<Ayarlar, Bool>) -> some View {
        let on = depo.ayarlar[keyPath: yol]
        return Button {
            depo.degistir { $0.ayarlar[keyPath: yol].toggle() }
            Dokunsal.hafif(0.5)
        } label: {
            Text(ad).font(.kalin(11.5)).multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.8)
                .foregroundStyle(on ? Color.white : Color.secondary)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(RoundedRectangle(cornerRadius: 22).fill(on ? Color(hex: "#3B8EF0").opacity(0.55) : Color.white.opacity(0.04)))
                .contentShape(RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func kaydet() {
        let ad = yeniAd.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ses.katman.isEmpty else { return }
        let k = Karisim(ad: ad.isEmpty ? "Karışım \(depo.kayit.karisimlar.count + 1)" : ad, katman: ses.katman, mesafe: ses.mesafe)
        depo.degistir { $0.karisimlar.insert(k, at: 0) }
        Dokunsal.basari()
    }
}

/// Bir ses kartı: başlığa dokununca açılır/kapanır; "Ses" düzey, "Uzaklık" yakın-uzak.
struct SesKaresi: View {
    @Environment(SesMotoru.self) private var ses
    let tur: SesTuru

    var body: some View {
        let secili = ses.katman[tur.id] != nil
        VStack(alignment: .leading, spacing: 10) {
            Button {
                ses.degistir(tur.id)
                Dokunsal.hafif(0.5)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: tur.simge)
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.white.opacity(secili ? 0.3 : 0.12)))
                        .symbolEffect(.bounce, value: secili)
                    Text(tur.ad).font(.kalin(14)).lineLimit(2).minimumScaleFactor(0.75).multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(tur.ad) \(secili ? "açık" : "kapalı")")
            satir("Ses", renk: Color(hex: "#7FC4FF"), deger: Binding(get: { ses.katman[tur.id] ?? 0.7 }, set: { v in
                if ses.katman[tur.id] == nil { ses.degistir(tur.id) }
                ses.duzey(tur.id, max(0.05, v))
            }))
            satir("Uzaklık", renk: Color(hex: "#FFB45C"), deger: Binding(get: { ses.mesafe[tur.id] ?? 0 }, set: { v in
                if ses.katman[tur.id] == nil { ses.degistir(tur.id) }
                ses.mesafeAyarla(tur.id, v)
            }))
        }
        .padding(12)
        .opacity(secili ? 1 : 0.72)
        .glassEffect(.regular.tint(tur.renk.opacity(secili ? 0.42 : 0.16)).interactive(), in: .rect(cornerRadius: 24))
        .accessibilityAddTraits(secili ? .isSelected : [])
    }

    private func satir(_ ad: String, renk: Color, deger: Binding<Double>) -> some View {
        HStack(spacing: 6) {
            Text(ad).font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary).frame(width: 40, alignment: .leading)
            Slider(value: deger, in: 0...1)
                .tint(renk)
                .controlSize(.mini)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(tur.ad) \(ad.lowercased())")
    }
}
