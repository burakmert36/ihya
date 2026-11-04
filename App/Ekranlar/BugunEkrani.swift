import SwiftUI

struct BugunEkrani: View {
    @Environment(Depo.self) private var depo
    @Environment(VakitServisi.self) private var vakit
    @Environment(Yonlendirici.self) private var yon
    @Environment(\.palet) private var palet

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                SahneBasligi(ust: "\(Tarihler.ustSatir()) · \(BugunEkrani.hicriKisa(vakit.hicri(.now)))", baslik: "İhya") {
                    HStack(spacing: 8) {
                        SeriHapi()
                        NavigationLink(value: Rota.ayarlar) {
                            Image(systemName: "gearshape").font(.system(size: 15, weight: .semibold)).frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                        .camYuzey(palet.cam(etkilesimli: true), in: .circle)
                        .accessibilityLabel("Ayarlar")
                    }
                    .padding(.bottom, 4)
                }
                SonrakiVakitKarti()
                NamazTakibi()
                BugunkuBahce()
                if let s = Icerik.gunun(Icerik.sozler.filter { $0.soz.count <= 110 }, kaydir: 3) { GununSozu(soz: s) }
                kisayollar
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .altCubukPayi()
        .toolbar(.hidden, for: .navigationBar)
    }

    /// "23 Cemaziyelevvel 1448" → "23 C.EVVEL 1448"
    static func hicriKisa(_ h: String) -> String {
        let tr = Locale(identifier: "tr_TR")
        let kisa = ["Cemaziyelevvel": "C.EVVEL", "Cemaziyelahir": "C.ÂHİR", "Rebiulevvel": "R.EVVEL", "Rebiulahir": "R.ÂHİR"]
        return h.split(separator: " ").map { p in kisa[String(p)] ?? String(p).uppercased(with: tr) }.joined(separator: " ")
    }

    private var kisayollar: some View {
        let k = palet.koyu
        return GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                CamDugme(baslik: "Odaklan", renk: Color(hex: k ? "#7CF0A4" : "#0E6A33")) { yon.odakAc() }
                CamDugme(baslik: "Sesler", renk: Color(hex: k ? "#9CC8FF" : "#1F4E8C")) { yon.ac(.sesler) }
                CamDugme(baslik: "Zikir", renk: Color(hex: k ? "#D3B5FF" : "#5B2E91")) { yon.ac(.zikir) }
                CamDugme(baslik: "Kur'an", renk: Color(hex: k ? "#F2C98A" : "#5A3A10")) {
                    let s = depo.kayit.kuranSon
                    yon.ac(.sure(s.first ?? 1, s.count > 1 ? s[1] : 1))
                }
            }
        }
    }
}

/// Sıradaki vakit, saniyeli geri sayım ve günün altı vakti çizgisi.
struct SonrakiVakitKarti: View {
    @Environment(VakitServisi.self) private var vakit
    @Environment(Yonlendirici.self) private var yon
    @Environment(\.palet) private var palet

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { an in
            let d = vakit.durum(an.date)
            let bugun = vakit.vakitler(an.date)
            let k = bugun.firstIndex { $0 > an.date }
            let kalan = max(0, Int(d.sonrakiZaman.timeIntervalSince(an.date)))
            Button { yon.ac(.vakitler) } label: {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        (Text("Sıradaki vakit · ").foregroundStyle(.secondary) + Text(k.map { VakitAdi.adlar[$0] } ?? "İmsak (yarın)").foregroundStyle(palet.vurgu))
                            .font(.kalin(13))
                        Spacer()
                        Text("\(Tarihler.saat.string(from: d.sonrakiZaman)) · \(vakit.konumAdi)")
                            .font(.system(size: 12, weight: .bold)).foregroundStyle(.secondary)
                    }
                    Text(String(format: "%02d:%02d:%02d", kalan / 3600, kalan % 3600 / 60, kalan % 60))
                        .font(.system(size: 46, weight: .heavy)).monospacedDigit().tracking(-1)
                        .contentTransition(.numericText(countsDown: true))
                    HStack(alignment: .top, spacing: 4) {
                        ForEach(0..<6, id: \.self) { j in
                            let gecti = k == nil || j < (k ?? 0)
                            let simdi = j == k
                            VStack(spacing: 4) {
                                Capsule()
                                    .fill(gecti ? AnyShapeStyle(LinearGradient(colors: [Color(hex: "#57D67E"), Color(hex: "#1BA552")], startPoint: .leading, endPoint: .trailing))
                                          : simdi ? AnyShapeStyle(LinearGradient(colors: [Color(hex: "#FFC65C"), Color(hex: "#FF9F43")], startPoint: .leading, endPoint: .trailing))
                                          : AnyShapeStyle(Color.primary.opacity(0.12)))
                                    .frame(height: 6)
                                Text(VakitAdi.adlar[j]).font(.kalin(10.5))
                                    .foregroundStyle(simdi ? Color(hex: palet.koyu ? "#FFB45C" : "#C25E00") : gecti ? palet.vurgu : Color.secondary)
                                    .lineLimit(1).minimumScaleFactor(0.8)
                                Text(Tarihler.saat.string(from: bugun[j])).font(.system(size: 10.5, weight: .semibold)).monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal, 2)
                .camKart(kose: 30)
            }
            .buttonStyle(.plain)
        }
    }
}

/// Beş vakit namaz takibi: dokununca ses, ışıltı ve titreşim.
struct NamazTakibi: View {
    @Environment(Depo.self) private var depo
    @Environment(VakitServisi.self) private var vakit
    @Environment(\.palet) private var palet
    @State private var isilti: [Int: Int] = [:]

    var body: some View {
        let kilinan = VakitAdi.namazlar.filter { depo.kilindi($0.0) }.count
        let saatler = vakit.vakitler(.now)
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Namazlarım").font(.kalin(15))
                Spacer()
                Text("\(kilinan)/5 kılındı").font(.kalin(12)).foregroundStyle(palet.vurgu)
            }
            HStack(spacing: 6) {
                ForEach(0..<VakitAdi.namazlar.count, id: \.self) { k in
                    let v = VakitAdi.namazlar[k]
                    let kilindi = depo.kilindi(v.0)
                    let vakti = saatler.indices.contains(v.0) && Date() >= saatler[v.0]
                    Button { degistir(v.0) } label: {
                        VStack(spacing: 3) {
                            Image(systemName: kilindi ? "checkmark" : "circle")
                                .font(.system(size: 13, weight: .heavy))
                                .contentTransition(.symbolEffect(.replace))
                            Text(v.1).font(.kalin(11)).lineLimit(1).minimumScaleFactor(0.8)
                        }
                        .foregroundStyle(kilindi ? Color.white : vakti ? Color(hex: palet.koyu ? "#FFB45C" : "#C25E00") : Color.secondary)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(kilindi ? AnyShapeStyle(LinearGradient(colors: [Color(r: 96, g: 236, b: 150, a: 0.95), Color(r: 20, g: 158, b: 82, a: 0.92)], startPoint: .top, endPoint: .bottom))
                                      : AnyShapeStyle(Color.white.opacity(palet.koyu ? 0.08 : 0.45)))
                                .shadow(color: kilindi ? Color(r: 20, g: 150, b: 70, a: 0.3) : .clear, radius: 7, y: 6)
                        }
                        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.primary.opacity(kilindi ? 0 : 0.08), lineWidth: 1))
                        .overlay { if let s = isilti[v.0] { IsiltiPatlamasi().id(s) } }
                        .contentShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(v.1) namazı \(kilindi ? "kılındı" : "kılınmadı")")
                }
            }
        }
        .camKart(ic: 14)
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

/// Bugünkü bahçe: günlük hedefe göre ilerleme ve bugün dikilenler.
struct BugunkuBahce: View {
    @Environment(Depo.self) private var depo
    @Environment(Yonlendirici.self) private var yon
    @Environment(\.palet) private var palet

    var body: some View {
        let bugun = depo.bugunkuOturumlar
        let tamam = bugun.filter { $0.durum == .tamam }
        let dk = Int(tamam.reduce(0) { $0 + $1.sure }.rounded())
        let hedef = max(10, depo.ayarlar.gunlukHedef)
        Button { yon.takipBolum = .bahce; yon.sec(.takip) } label: {
            HStack(spacing: 12) {
                HStack(alignment: .bottom, spacing: 2) {
                    if tamam.isEmpty {
                        FilizSimgesi().fill(palet.vurgu.opacity(0.35)).frame(width: 44, height: 44).frame(width: 58, height: 68)
                    } else {
                        ForEach(tamam.suffix(2)) { o in
                            BitkiResmi(tur: o.tur, dk: Double(o.plan), tohum: o.tohum, lod: 0.7, sigdir: true)
                                .frame(width: 58, height: 68)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Bugünkü bahçe").font(.kalin(15))
                        Spacer()
                        Text("\(dk) / \(hedef) dk").font(.kalin(12)).foregroundStyle(.secondary).monospacedDigit()
                    }
                    IlerlemeCubugu(oran: Double(dk) / Double(hedef))
                    Text(ozet(tamam, dk: dk, hedef: hedef))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
            }
            .camKart(ic: 14)
        }
        .buttonStyle(.plain)
    }

    private func ozet(_ liste: [OdakOturumu], dk: Int, hedef: Int) -> String {
        let parcalar = liste.suffix(2).reversed().map { o in
            "\(BitkiKatalogu.ad(o.tur)) · \(depo.konu(o.konu)?.ad ?? (o.ad.isEmpty ? "Odak" : o.ad)) \(o.plan) dk"
        }
        let bas = parcalar.isEmpty ? "Henüz bitki dikmedin." : parcalar.joined(separator: ", ") + "."
        return dk >= hedef ? "\(bas) Günlük hedef tamam." : "\(bas) \(hedef - dk) dk daha ile hedef tamam."
    }
}

struct GununSozu: View {
    @Environment(Yonlendirici.self) private var yon
    let soz: Soz
    var body: some View {
        Button { yon.ac(.sozler) } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text("\(soz.ayetMi ? "GÜNÜN ÂYETİ" : "GÜNÜN SÖZÜ") · \(soz.kisi)")
                        .font(.kalin(10.5)).tracking(1).foregroundStyle(Color.altin)
                        .lineLimit(1)
                    Spacer()
                    BegenDugmesi(tur: .soz, anahtar: soz.id)
                }
                Text("“\(soz.soz)”").font(.system(size: 18, weight: .medium, design: .serif)).lineSpacing(3)
                    .multilineTextAlignment(.leading)
                Text(soz.kaynak).font(.system(size: 11, weight: .bold)).foregroundStyle(Color(hex: "#7A6A48"))
            }
            .kremKart()
        }
        .buttonStyle(.plain)
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
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
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
