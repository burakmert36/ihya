import SwiftUI

struct BugunEkrani: View {
    @Environment(Depo.self) private var depo
    @Environment(VakitServisi.self) private var vakit
    @Environment(Yonlendirici.self) private var yon

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                baslik
                SonrakiVakitKarti()
                NamazTakibi()
                OdakOzeti()
                if let h = Icerik.gunun(Icerik.hadisler) { GununHadisi(hadis: h) }
                if let s = Icerik.gunun(Icerik.sozler, kaydir: 3) { GununSozu(soz: s) }
                kisayollar
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(alignment: .top) {
            LinearGradient(colors: [Color.ihya.opacity(0.16), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 320)
                .ignoresSafeArea()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: Rota.ayarlar) { Image(systemName: "gearshape") }
                    .accessibilityLabel("Ayarlar")
            }
        }
        .toolbarTitleDisplayMode(.inline)
    }

    private var baslik: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("İhya")
                    .font(.system(size: 44, weight: .semibold, design: .serif))
                Spacer()
                Text("إحياء")
                    .font(.arapca(34, kalin: true))
                    .foregroundStyle(Color.ihya)
            }
            Text("\(Tarihler.gunAyGun.string(from: .now)) · \(vakit.hicri(.now))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }

    private var kisayollar: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                kisayol("Kıble", "location.north.line", .kible)
                kisayol("Dualar", "hands.sparkles", .dualar)
                kisayol("Esmâ", "sparkles", .esma)
                kisayol("Günler", "calendar", .diniGunler)
            }
        }
    }

    private func kisayol(_ ad: String, _ simge: String, _ rota: Rota) -> some View {
        Button {
            yon.sekme = .kitaplik
            yon.kitaplikYol = [rota]
        } label: {
            VStack(spacing: 6) {
                Image(systemName: simge).font(.title3)
                Text(ad).font(.caption)
            }
            .frame(maxWidth: .infinity, minHeight: 64)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 18))
    }
}

/// Sıradaki vakit ve geri sayım; altında günün altı vakti.
struct SonrakiVakitKarti: View {
    @Environment(VakitServisi.self) private var vakit

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { an in
            let d = vakit.durum(an.date)
            let bugun = vakit.vakitler(an.date)
            NavigationLink(value: Rota.vakitler) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(VakitAdi.vaktine(d.sonraki))
                                .font(.headline)
                            Text(vakit.konumAdi)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(timerInterval: an.date...max(an.date, d.sonrakiZaman), countsDown: true)
                            .font(.system(size: 34, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .multilineTextAlignment(.trailing)
                    }
                    HStack(spacing: 0) {
                        ForEach(0..<6, id: \.self) { i in
                            VStack(spacing: 3) {
                                Text(VakitAdi.adlar[i]).font(.caption2)
                                Text(Tarihler.saat.string(from: bugun[i])).font(.footnote.weight(.semibold)).monospacedDigit()
                            }
                            .foregroundStyle(i == d.simdiki ? Color.ihya : .primary)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                            .background {
                                if i == d.simdiki { Capsule().fill(Color.ihya.opacity(0.14)) }
                            }
                        }
                    }
                }
                .camKart(.ihya)
            }
            .buttonStyle(.plain)
        }
    }
}

/// Beş vakit namaz takibi: dokununca ses, ışıltı ve titreşim.
struct NamazTakibi: View {
    @Environment(Depo.self) private var depo
    @State private var isilti: [Int: Int] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                BolumBasligi(metin: "Bugünkü namazlar", simge: "checkmark.circle")
                Text("\(VakitAdi.namazlar.filter { depo.kilindi($0.0) }.count)/5")
                    .font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
            }
            HStack(spacing: 0) {
                ForEach(0..<VakitAdi.namazlar.count, id: \.self) { k in
                    let v = VakitAdi.namazlar[k]
                    let kilindi = depo.kilindi(v.0)
                    Button { degistir(v.0) } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(kilindi ? Color.ihya : Color.secondary.opacity(0.12))
                                    .frame(width: 46, height: 46)
                                Image(systemName: kilindi ? "checkmark" : "moon.stars")
                                    .font(.system(size: kilindi ? 18 : 15, weight: .semibold))
                                    .foregroundStyle(kilindi ? Color.white : Color.secondary)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                            .overlay {
                                if let s = isilti[v.0] { IsiltiPatlamasi().id(s) }
                            }
                            Text(v.1).font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(v.1) namazı \(kilindi ? "kılındı" : "kılınmadı")")
                }
            }
        }
        .camKart()
    }

    private func degistir(_ i: Int) {
        let simdi = !depo.kilindi(i)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { depo.namazDegistir(i) }
        if simdi {
            isilti[i, default: 0] += 1
            Efekt.cal("efekt_isilti", duzey: 0.6)
            Dokunsal.hafif(0.9)
        } else {
            Dokunsal.hafif(0.4)
        }
    }
}

struct OdakOzeti: View {
    @Environment(Depo.self) private var depo
    @Environment(Yonlendirici.self) private var yon

    var body: some View {
        let bugun = depo.kayit.oturumlar.filter { Calendar.current.isDateInToday($0.baslangic) }
        let dk = bugun.filter { $0.durum == .tamam }.reduce(0) { $0 + $1.sure }
        VStack(alignment: .leading, spacing: 12) {
            BolumBasligi(metin: "Bugünkü odak", simge: "leaf")
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dk.sureMetni).font(.title2.weight(.semibold))
                    Text(bugun.isEmpty ? "Henüz bitki dikmedin." : "\(bugun.filter { $0.durum == .tamam }.count) bitki · \(depo.kayit.tohum) tohum")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: -10) {
                    ForEach(bugun.suffix(5)) { o in
                        BitkiResmi(tur: o.tur, dk: o.sure, tohum: o.tohum, lod: 0.6, kurudu: o.durum == .vazgecildi, sigdir: true)
                            .frame(width: 40, height: 48)
                    }
                }
            }
            Button {
                yon.sekme = .odak
            } label: {
                Label("Odaklan", systemImage: "leaf.fill").frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
        }
        .camKart()
    }
}

struct GununHadisi: View {
    @Environment(Depo.self) private var depo
    let hadis: Hadis
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            BolumBasligi(metin: "Günün hadisi", simge: "text.quote")
            Text(hadis.metin).font(.okuma(17)).lineSpacing(3)
            HStack {
                Text("\(hadis.ravi) · \(hadis.kaynak)").font(.caption).foregroundStyle(.secondary)
                Spacer()
                BegenDugmesi(tur: .hadis, anahtar: String(hadis.no))
                ShareLink(item: "\(hadis.metin)\n\n\(hadis.kaynak)") { Image(systemName: "square.and.arrow.up") }
                    .accessibilityLabel("Paylaş")
            }
        }
        .camKart()
    }
}

struct GununSozu: View {
    let soz: Soz
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            BolumBasligi(metin: soz.ayetMi ? "Günün âyeti" : "Günün sözü", simge: soz.ayetMi ? "book.closed" : "quote.opening")
            Text(soz.soz).font(.okuma(17)).lineSpacing(3)
            HStack {
                Text("\(soz.kisi) · \(soz.kaynak)").font(.caption).foregroundStyle(.secondary)
                Spacer()
                BegenDugmesi(tur: .soz, anahtar: soz.id)
            }
        }
        .camKart()
    }
}

/// Kalp: beğen ve kaydet.
struct BegenDugmesi: View {
    @Environment(Depo.self) private var depo
    let tur: Favori.Tur
    let anahtar: String
    var body: some View {
        let begenildi = depo.begenildi(tur, anahtar)
        Button {
            depo.begen(tur, anahtar)
            Dokunsal.hafif(begenildi ? 0.4 : 0.9)
        } label: {
            Image(systemName: begenildi ? "heart.fill" : "heart")
                .foregroundStyle(begenildi ? Color.pink : Color.secondary)
                .symbolEffect(.bounce, value: begenildi)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(begenildi ? "Kaydedildi" : "Kaydet")
    }
}

/// Dokunuşta çevreye saçılan küçük yıldızlar.
struct IsiltiPatlamasi: View {
    var renk: Color = Color(red: 1, green: 0.78, blue: 0.25)
    @State private var acik = false
    var body: some View {
        ZStack {
            ForEach(0..<10, id: \.self) { i in
                let a = Double(i) / 10 * 2 * .pi
                Image(systemName: "sparkle")
                    .font(.system(size: i.isMultiple(of: 2) ? 10 : 7, weight: .bold))
                    .foregroundStyle(renk)
                    .offset(x: acik ? cos(a) * 34 : 0, y: acik ? sin(a) * 34 : 0)
                    .scaleEffect(acik ? 0.3 : 1.1)
                    .opacity(acik ? 0 : 1)
            }
        }
        .allowsHitTesting(false)
        .onAppear { withAnimation(.easeOut(duration: 0.75)) { acik = true } }
    }
}
