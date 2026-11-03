import SwiftUI

struct SeslerEkrani: View {
    @Environment(SesMotoru.self) private var ses
    @Environment(Depo.self) private var depo
    @State private var adSor = false
    @State private var yeniAd = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                kontrol
                karisimlar
                if !ses.katman.isEmpty { seviyeler }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(SesTuru.tumu) { t in
                        SesKaresi(tur: t, secili: ses.katman[t.id] != nil) { ses.degistir(t.id); Dokunsal.hafif(0.5) }
                    }
                }
                VStack(spacing: 0) {
                    Toggle("Odak süresince", isOn: depo.ayar(\.sesOdakta))
                        .padding(.vertical, 6)
                    Divider()
                    Toggle("Sonda sesi yavaşça azalt", isOn: depo.ayar(\.sesSondaAzalt))
                        .padding(.vertical, 6)
                }
                .camKart()
                Text("“Odak süresince” açıksa son seçtiğin sesler odak başlayınca çalar, bitince durur.")
                    .font(.footnote).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .navigationTitle("Sesler")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if ses.katman.isEmpty, !depo.kayit.sonKatman.isEmpty { ses.yukle(depo.kayit.sonKatman, baslat: false) }
        }
        .alert("Karışımı kaydet", isPresented: $adSor) {
            TextField("Karışım adı", text: $yeniAd)
            Button("Kaydet") { kaydet() }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("Seçili \(ses.katman.count) ses bu adla saklanır.")
        }
    }

    private var kontrol: some View {
        HStack(spacing: 14) {
            Button { ses.degistirOynat() } label: {
                Image(systemName: ses.caliyor ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .frame(width: 56, height: 56)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.circle)
            .disabled(ses.katman.isEmpty)
            VStack(alignment: .leading, spacing: 6) {
                Text(ses.seciliAdlar).font(.subheadline.weight(.medium)).lineLimit(2)
                HStack(spacing: 8) {
                    Image(systemName: "speaker.fill").font(.caption).foregroundStyle(.secondary)
                    Slider(value: Binding(get: { ses.anaDuzey }, set: { ses.ana($0) }), in: 0...1)
                }
            }
            Button("Hepsini kıs") { ses.hepsiniKis(); Dokunsal.hafif() }
                .buttonStyle(.glass)
                .disabled(ses.katman.isEmpty)
        }
        .camKart()
    }

    private var karisimlar: some View {
        VStack(alignment: .leading, spacing: 10) {
            BolumBasligi(metin: "Karışımlarım", simge: "square.stack.3d.up")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button {
                        yeniAd = ""
                        adSor = true
                    } label: {
                        Label("Yeni", systemImage: "plus").font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14).padding(.vertical, 9)
                    }
                    .buttonStyle(.glass)
                    .disabled(ses.katman.isEmpty)
                    ForEach(depo.kayit.karisimlar) { k in
                        Button {
                            ses.yukle(k.katman, baslat: true)
                            Dokunsal.hafif()
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(k.ad).font(.subheadline.weight(.medium))
                                Text(k.katman.keys.compactMap { SesTuru.bul($0)?.ad }.sorted().joined(separator: ", "))
                                    .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                            }
                            .frame(maxWidth: 170, alignment: .leading)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Capsule().fill(ses.katman == k.katman ? Color.ihya.opacity(0.16) : Color.secondary.opacity(0.08)))
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Sil", systemImage: "trash", role: .destructive) {
                                depo.degistir { $0.karisimlar.removeAll { $0.id == k.id } }
                            }
                        }
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            if depo.kayit.karisimlar.isEmpty {
                Text("Sesleri seç, “Yeni” ile en çok \(SesMotoru.enFazla) sesi adıyla sakla.").font(.footnote).foregroundStyle(.secondary)
            }
        }
    }

    private var seviyeler: some View {
        VStack(spacing: 12) {
            ForEach(SesTuru.tumu.filter { ses.katman[$0.id] != nil }) { t in
                HStack(spacing: 10) {
                    Image(systemName: t.simge).frame(width: 24).foregroundStyle(Color.ihya)
                    Text(t.ad).font(.subheadline).frame(width: 118, alignment: .leading).lineLimit(1)
                    Slider(value: Binding(get: { ses.katman[t.id] ?? 0.7 }, set: { ses.duzey(t.id, $0) }), in: 0.05...1)
                }
            }
        }
        .camKart()
    }

    private func kaydet() {
        let ad = yeniAd.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ses.katman.isEmpty else { return }
        let k = Karisim(ad: ad.isEmpty ? "Karışım \(depo.kayit.karisimlar.count + 1)" : ad, katman: ses.katman)
        depo.degistir { $0.karisimlar.insert(k, at: 0) }
        Dokunsal.basari()
    }
}

struct SesKaresi: View {
    let tur: SesTuru
    let secili: Bool
    let sec: () -> Void
    var body: some View {
        Button(action: sec) {
            VStack(spacing: 8) {
                Image(systemName: tur.simge)
                    .font(.title2)
                    .symbolEffect(.bounce, value: secili)
                Text(tur.ad).font(.caption).multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.85)
            }
            .foregroundStyle(secili ? Color.ihya : Color.primary)
            .frame(maxWidth: .infinity, minHeight: 86)
            .padding(.horizontal, 6)
        }
        .buttonStyle(.plain)
        .glassEffect(secili ? Glass.regular.tint(Color.ihya.opacity(0.25)).interactive() : Glass.regular.interactive(), in: .rect(cornerRadius: 18))
        .accessibilityAddTraits(secili ? .isSelected : [])
    }
}
