import SwiftUI

struct DualarEkrani: View {
    @Environment(Depo.self) private var depo
    @State private var tema: String?

    var body: some View {
        let temalar = Icerik.duaTemalari.filter { tema == nil || $0.id == tema }
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                if let d = Icerik.duaDefteri {
                    NavigationLink(value: Rota.duaDefteri) {
                        HStack(spacing: 14) {
                            Image(systemName: "book.pages")
                                .font(.title2)
                                .foregroundStyle(Color.ihya)
                                .frame(width: 48, height: 48)
                                .background(Circle().fill(Color.ihya.opacity(0.14)))
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Dua Defterim").font(.headline)
                                Text(d.baslik).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.ihya.opacity(0.10)))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        KonuCipi(ad: "Tümü", renk: .ihya, secili: tema == nil) { tema = nil }
                        ForEach(Icerik.duaTemalari) { t in
                            KonuCipi(ad: t.ad, renk: .ihya, secili: tema == t.id) { tema = tema == t.id ? nil : t.id }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
                ForEach(temalar) { t in
                    Label(t.ad, systemImage: t.simge)
                        .font(.title3.weight(.semibold))
                        .padding(.top, 10)
                        .padding(.horizontal, 16)
                    ForEach(t.dualar) { d in DuaKarti(dua: d).padding(.horizontal, 16) }
                }
                Text("Âyet mealleri Diyanet İşleri meali; hadisler Sahîh-i Buhârî. Okunuşlar Türkçe harflerle yaklaşık telaffuzdur; doğru okuyuş için Arapça metne ve bir hocaya başvur.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }
            .padding(.bottom, 24)
        }
        .okumaAlani()
        .navigationTitle("Dualar")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DuaKarti: View {
    @Environment(Depo.self) private var depo
    let dua: Dua
    var body: some View {
        let p = depo.ayarlar.okumaPunto
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text(dua.baslik).font(.headline)
                Spacer()
                BegenDugmesi(tur: .dua, anahtar: dua.id)
            }
            if let ar = dua.arapca, !ar.isEmpty {
                Text(ar)
                    .font(.arapca(p + 8))
                    .lineSpacing(p * 0.5)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .textSelection(.enabled)
            }
            Text(dua.okunus).font(.system(size: p - 1, design: .serif)).italic().foregroundStyle(Color.ihya)
                .textSelection(.enabled)
            Text(dua.anlam).font(.okuma(p)).lineSpacing(p * 0.25).textSelection(.enabled)
            if let n = dua.not, !n.isEmpty {
                Text(n).font(.footnote).foregroundStyle(.secondary)
            }
            Text(dua.kaynak).font(.caption.weight(.medium)).foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.primary.opacity(0.045)))
    }
}

/// Kullanıcının kendi dua derlemesi; tekrar sayılı başlangıç zikirleri dokunarak sayılır.
struct DuaDefteriEkrani: View {
    @Environment(Depo.self) private var depo
    @State private var sayaclar: [String: Int] = [:]

    var body: some View {
        if let d = Icerik.duaDefteri {
            let p = depo.ayarlar.okumaPunto
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    Text(d.baslik).font(.system(size: 28, weight: .semibold, design: .serif)).padding(.top, 8)
                    BolumBasligi(metin: "Başlangıç", simge: "sunrise")
                    ForEach(d.giris, id: \.self) { o in DefterKarti(oge: o, sayac: sayacBagi(o)) }
                    ForEach(Array(d.bolumler.enumerated()), id: \.element.id) { i, b in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(i + 1). \(b.baslik)").font(.title3.weight(.semibold))
                            if let a = b.aciklama { Text(a).font(.footnote).foregroundStyle(.secondary) }
                        }
                        .padding(.top, 12)
                        if let ogeler = b.ogeler {
                            ForEach(ogeler, id: \.self) { o in DefterKarti(oge: o, sayac: sayacBagi(o)) }
                        }
                        if let ayetler = b.ayetler {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Bismillâhirrahmânirrahîm").font(.system(size: p, design: .serif)).italic().frame(maxWidth: .infinity)
                                ForEach(ayetler, id: \.no) { a in
                                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                                        Text("\(a.no)")
                                            .font(.caption.weight(.semibold)).monospacedDigit()
                                            .foregroundStyle(Color.ihya)
                                            .frame(width: 26, alignment: .trailing)
                                        Text(a.okunus).font(.okuma(p)).textSelection(.enabled)
                                    }
                                }
                            }
                            .padding(18)
                            .background(RoundedRectangle(cornerRadius: 20).fill(Color.primary.opacity(0.045)))
                        }
                        if let m = b.metin {
                            Text(m).font(.okuma(p)).lineSpacing(p * 0.3).textSelection(.enabled)
                                .padding(18)
                                .background(RoundedRectangle(cornerRadius: 20).fill(Color.primary.opacity(0.045)))
                        }
                    }
                    BolumBasligi(metin: "Kapanış", simge: "sunset").padding(.top, 8)
                    DefterKarti(oge: d.kapanis, sayac: nil)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .okumaAlani()
            .navigationTitle("Dua Defterim")
            .navigationBarTitleDisplayMode(.inline)
        } else {
            ContentUnavailableView("Dua defteri bulunamadı", systemImage: "book.pages")
        }
    }

    private func sayacBagi(_ o: DefterOgesi) -> Binding<Int>? {
        guard let t = o.tekrar, t > 1 else { return nil }
        return Binding(get: { sayaclar[o.baslik] ?? 0 }, set: { sayaclar[o.baslik] = min(t, $0) })
    }
}

struct DefterKarti: View {
    @Environment(Depo.self) private var depo
    let oge: DefterOgesi
    let sayac: Binding<Int>?

    var body: some View {
        let p = depo.ayarlar.okumaPunto
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(oge.baslik).font(.headline)
                Spacer()
                if let sayac, let t = oge.tekrar {
                    Button {
                        if sayac.wrappedValue < t {
                            withAnimation(.snappy) { sayac.wrappedValue += 1 }
                            if sayac.wrappedValue == t { Dokunsal.basari() }
                        } else {
                            sayac.wrappedValue = 0
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: sayac.wrappedValue == t ? "checkmark" : "plus")
                                .font(.footnote.weight(.bold))
                                .contentTransition(.symbolEffect(.replace))
                            Text("\(sayac.wrappedValue)/\(t)")
                                .font(.subheadline.weight(.semibold)).monospacedDigit()
                                .contentTransition(.numericText(value: Double(sayac.wrappedValue)))
                        }
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .background(Capsule().fill(sayac.wrappedValue == t ? Color.ihya : Color.ihya.opacity(0.15)))
                        .foregroundStyle(sayac.wrappedValue == t ? Color.white : Color.ihya)
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.increase, trigger: sayac.wrappedValue)
                    .accessibilityLabel("Sayaç \(sayac.wrappedValue) / \(t)")
                } else if let t = oge.tekrar, t > 1 {
                    Text("\(t) kere").font(.caption).foregroundStyle(.secondary)
                }
            }
            if let o = oge.okunus { Text(o).font(.okuma(p)).italic().lineSpacing(p * 0.25).textSelection(.enabled) }
            if let a = oge.anlam { Text(a).font(.system(size: p - 2)).foregroundStyle(.secondary).lineSpacing(p * 0.2).textSelection(.enabled) }
            if let n = oge.not { Text(n).font(.footnote).foregroundStyle(.secondary).padding(.top, 2) }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.primary.opacity(0.045)))
    }
}
