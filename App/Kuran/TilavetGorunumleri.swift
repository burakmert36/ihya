import SwiftUI

/// Hafızın rozeti: sekiz köşeli yıldızın içinde kısa Arapça adı.
struct HafizRozeti: View {
    let hafiz: Hafiz
    var boyut: CGFloat = 44
    var body: some View {
        let renk = Color(hex: hafiz.renk)
        ZStack {
            Circle().fill(renk.opacity(0.22))
            SekizKoseYildiz(ic: 0.74).stroke(renk.opacity(0.9), lineWidth: 1.2).padding(boyut * 0.06)
            Text(hafiz.kisa)
                .font(.arapca(boyut * 0.3, kalin: true))
                .foregroundStyle(renk)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(width: boyut * 0.7)
        }
        .frame(width: boyut, height: boyut)
        .accessibilityHidden(true)
    }
}

/// Okuyucunun altındaki tilavet çubuğu: boştayken "Dinle", çalarken okunan âyet ve denetimler.
struct TilavetCubugu: View {
    let sure: Int
    /// Ekranın üstündeki âyet ("buradan dinle" için).
    let baslangic: () -> Int
    @Environment(Depo.self) private var depo
    @Environment(\.palet) private var palet
    @State private var t = TilavetMotoru.ortak
    @State private var hafizSec = false

    var body: some View {
        let buSure = t.etkin && t.sure == sure
        VStack(spacing: 8) {
            if let h = t.hata, !t.caliyor {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.exclamationmark").foregroundStyle(.orange)
                    Text(h).font(.system(size: 12.5, weight: .semibold)).lineLimit(2)
                    Spacer(minLength: 4)
                    if buSure { Button("Tekrar dene") { t.devamEt() }.font(.kalin(12.5)) }
                }
                .padding(.horizontal, 14).padding(.vertical, 8)
                .camYuzey(palet.cam(), in: .capsule)
            }
            if buSure { etkin } else { bos }
        }
        .sheet(isPresented: $hafizSec) { HafizSecici().presentationDetents([.medium, .large]) }
    }

    private var bos: some View {
        let n = baslangic()
        return HStack(spacing: 10) {
            Button { hafizSec = true } label: { HafizRozeti(hafiz: t.hafiz, boyut: 42) }
                .buttonStyle(.plain)
                .accessibilityLabel("Hafız seç, şu an \(t.hafiz.ad)")
            VStack(alignment: .leading, spacing: 1) {
                Text(t.etkin ? "Başka sûre çalıyor" : "Dinle").font(.kalin(15))
                Text(t.hafiz.ad).font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 4)
            if n > 1 {
                Button("\(n). âyetten") { t.cal(sure: sure, ayet: n); Dokunsal.hafif(0.5) }
                    .font(.kalin(13))
                    .buttonStyle(.glass)
            }
            Button { t.cal(sure: sure, ayet: 1); Dokunsal.hafif(0.6) } label: {
                Label("Baştan", systemImage: "play.fill").font(.kalin(13)).foregroundStyle(palet.dolguMetin)
            }
            .buttonStyle(.glassProminent)
            .tint(palet.dolgu)
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .camYuzey(palet.cam(), in: .rect(cornerRadius: 28))
    }

    private var etkin: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button { hafizSec = true } label: { HafizRozeti(hafiz: t.hafiz, boyut: 44) }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Hafız seç, şu an \(t.hafiz.ad)")
                VStack(alignment: .leading, spacing: 2) {
                    (Text(t.ayet == 0 ? "Besmele" : "\(t.ayet). âyet").font(.kalin(16))
                     + Text("  / \(t.sureAyetSayisi)").font(.system(size: 12, weight: .bold)).foregroundStyle(.secondary))
                        .contentTransition(.numericText())
                    Text(altSatir).font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer(minLength: 2)
                Button { t.onceki(); Dokunsal.hafif(0.4) } label: {
                    Image(systemName: "backward.fill").font(.system(size: 17, weight: .bold)).frame(width: 34, height: 40)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Önceki âyet")
                Button { t.degistirOynat(); Dokunsal.hafif(0.6) } label: {
                    ZStack {
                        if t.bekliyor {
                            ProgressView().tint(palet.dolguMetin)
                        } else {
                            Image(systemName: t.caliyor ? "pause.fill" : "play.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(palet.dolguMetin)
                                .contentTransition(.symbolEffect(.replace))
                        }
                    }
                    .frame(width: 50, height: 50)
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .camYuzey(.regular.tint(palet.dolgu.opacity(0.9)).interactive(), in: .circle)
                .accessibilityLabel(t.caliyor ? "Durdur" : "Çal")
                Button { t.sonraki(); Dokunsal.hafif(0.4) } label: {
                    Image(systemName: "forward.fill").font(.system(size: 17, weight: .bold)).frame(width: 34, height: 40)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Sonraki âyet")
                menu
            }
            IlerlemeCubugu(oran: Double(max(0, t.ayet)) / Double(max(1, t.sureAyetSayisi)), yukseklik: 4)
        }
        .padding(12)
        .camYuzey(palet.cam(), in: .rect(cornerRadius: 28))
    }

    private var altSatir: String {
        var p = [t.hafiz.ad]
        if t.tekrar != 1 { p.append(t.tekrar == 0 ? "sürekli tekrar" : "\(t.tekrar) kez") }
        if t.hiz != 1 { p.append(t.hiz.formatted(.number.precision(.fractionLength(0...2)).locale(Locale(identifier: "tr_TR"))) + "×") }
        if let o = t.indirmeler[t.indirmeAnahtari(sure)] { p.append("iniyor %\(Int(o * 100))") }
        return p.joined(separator: " · ")
    }

    private var menu: some View {
        Menu {
            Picker("Hafız", selection: Binding(get: { t.hafiz.id }, set: { v in
                t.hafizSec(Hafiz.bul(v))
                depo.degistir { $0.ayarlar.tilavetHafiz = v }
            })) {
                ForEach(Hafiz.Grup.allCases, id: \.self) { g in
                    Section(g.ad) { ForEach(Hafiz.grup(g)) { h in Text(h.ad).tag(h.id) } }
                }
            }
            .pickerStyle(.menu)
            Picker("Tekrar", selection: Binding(get: { t.tekrar }, set: { t.tekrarAyarla($0) })) {
                Text("Bir kez").tag(1)
                Text("3 kez").tag(3)
                Text("5 kez").tag(5)
                Text("7 kez").tag(7)
                Text("Sürekli").tag(0)
            }
            .pickerStyle(.menu)
            Picker("Hız", selection: Binding(get: { Double(t.hiz) }, set: { v in
                t.hizAyarla(Float(v))
                depo.degistir { $0.ayarlar.tilavetHiz = v }
            })) {
                Text("0,75×").tag(0.75)
                Text("1×").tag(1.0)
                Text("1,25×").tag(1.25)
                Text("1,5×").tag(1.5)
            }
            .pickerStyle(.menu)
            Toggle("Okunan âyeti takip et", isOn: Binding(get: { t.takip }, set: { v in t.takip = v; depo.degistir { $0.ayarlar.tilavetTakip = v } }))
            Toggle("Sûre bitince sonrakine geç", isOn: Binding(get: { t.devam }, set: { v in t.devam = v; depo.degistir { $0.ayarlar.tilavetDevam = v } }))
            Divider()
            if let o = t.indirmeler[t.indirmeAnahtari(sure)] {
                Button("İndirmeyi durdur (%\(Int(o * 100)))", systemImage: "stop.circle") { t.indirmeyiDurdur() }
            } else if t.indirildi(sure) {
                Label("Sûre telefonda, internetsiz çalar", systemImage: "checkmark.circle")
            } else {
                Button("Sûreyi indir (internetsiz dinle)", systemImage: "arrow.down.circle") { t.sureyiIndir(sure) }
            }
            Button("Tilaveti kapat", systemImage: "xmark.circle", role: .destructive) { t.dur() }
        } label: {
            Image(systemName: "ellipsis.circle").font(.system(size: 22, weight: .medium)).frame(width: 34, height: 40)
        }
        .accessibilityLabel("Tilavet ayarları")
    }
}

/// Hafız seçimi: Mescid-i Harâm imamları.
struct HafizSecici: View {
    @Environment(Depo.self) private var depo
    @Environment(\.dismiss) private var kapat
    @Environment(\.palet) private var palet
    @State private var t = TilavetMotoru.ortak

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    Text("Kâbe ve Mescid-i Nebevî imamlarından, bir de huzur veren seslerden tilavet. Okunan âyet ekranda vurgulanır. Dinledikçe telefona iner; bir sûreyi indirirsen internetsiz dinlersin.")
                        .font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 4)
                    ForEach(Hafiz.Grup.allCases, id: \.self) { g in
                        BolumBasligi(metin: g.ad).frame(maxWidth: .infinity, alignment: .leading).padding(.top, 6)
                        ForEach(Hafiz.grup(g)) { h in
                            let secili = h == t.hafiz
                            Button {
                                t.hafizSec(h)
                                depo.degistir { $0.ayarlar.tilavetHafiz = h.id }
                                Dokunsal.hafif(0.6)
                                kapat()
                            } label: {
                                HStack(spacing: 12) {
                                    HafizRozeti(hafiz: h, boyut: 50)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(h.ad).font(.kalin(16))
                                        Text(h.unvan).font(.system(size: 12.5, weight: .semibold)).foregroundStyle(.secondary)
                                    }
                                    Spacer(minLength: 4)
                                    Text(h.arapca).font(.arapca(17)).foregroundStyle(palet.vurgu).lineLimit(1).minimumScaleFactor(0.6)
                                    Image(systemName: secili ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 20)).foregroundStyle(secili ? palet.vurgu : .secondary)
                                }
                                .padding(12)
                                .contentShape(Rectangle())
                                .camYuzey(palet.cam(secili ? palet.vurgu.opacity(0.2) : nil, etkilesimli: true), in: .rect(cornerRadius: 22))
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(secili ? .isSelected : [])
                        }
                    }
                    Text("Kayıtlar: EveryAyah ve mp3quran arşivleri.")
                        .font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                        .padding(.top, 6)
                }
                .padding(16)
            }
            .sahne(.kuran)
            .navigationTitle("Hafız")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Bitti") { kapat() } } }
        }
    }
}

/// Kur'an sekmesindeki dinleme kartı: boştayken kaldığın yerden dinlet, çalarken kısa denetim.
struct DinleKarti: View {
    @Environment(Depo.self) private var depo
    @Environment(Yonlendirici.self) private var yon
    @Environment(\.palet) private var palet
    @State private var t = TilavetMotoru.ortak
    @State private var kuran = KuranDeposu.ortak
    @State private var hafizSec = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(t.etkin ? "ŞİMDİ DİNLENİYOR" : "KÂBE İMAMLARINDAN DİNLE").font(.kalin(11)).tracking(1.2).foregroundStyle(.secondary)
                Spacer()
                Button { hafizSec = true } label: {
                    Label("Hafız", systemImage: "person.wave.2").font(.kalin(12.5))
                }
                .buttonStyle(.glass)
                .controlSize(.small)
            }
            HStack(spacing: 12) {
                HafizRozeti(hafiz: t.hafiz, boyut: 50)
                VStack(alignment: .leading, spacing: 2) {
                    if t.etkin {
                        Text("\(kuran.sure(t.sure)?.ad ?? "") · " + (t.ayet == 0 ? "Besmele" : "\(t.ayet). âyet"))
                            .font(.kalin(17)).contentTransition(.numericText())
                        Text(t.hafiz.ad).font(.system(size: 12.5, weight: .semibold)).foregroundStyle(.secondary)
                    } else {
                        Text(t.hafiz.ad).font(.kalin(17))
                        Text("Âyet âyet takipli tilavet").font(.system(size: 12.5, weight: .semibold)).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 4)
                if t.etkin {
                    Button { t.degistirOynat(); Dokunsal.hafif(0.6) } label: {
                        Image(systemName: t.caliyor ? "pause.fill" : "play.fill")
                            .font(.system(size: 19, weight: .bold)).foregroundStyle(palet.dolguMetin)
                            .contentTransition(.symbolEffect(.replace))
                            .frame(width: 48, height: 48).contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .camYuzey(.regular.tint(palet.dolgu.opacity(0.9)).interactive(), in: .circle)
                    .accessibilityLabel(t.caliyor ? "Durdur" : "Çal")
                }
            }
            HStack(spacing: 10) {
                if t.etkin {
                    Button { yon.ac(.sure(t.sure, max(1, t.ayet))) } label: {
                        Label("Takip et", systemImage: "text.viewfinder").font(.kalin(13.5)).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                    Button { t.dur() } label: {
                        Label("Kapat", systemImage: "xmark").font(.kalin(13.5))
                    }
                    .buttonStyle(.glass)
                } else {
                    let son = depo.kayit.kuranSon
                    let s = son.first ?? 1, a = son.count > 1 ? son[1] : 1
                    Button {
                        t.cal(sure: s, ayet: a)
                        yon.ac(.sure(s, a))
                    } label: {
                        Label(son.isEmpty ? "Fâtiha'dan dinle" : "Kaldığın yerden dinle", systemImage: "play.fill")
                            .font(.kalin(14)).foregroundStyle(palet.dolguMetin).frame(maxWidth: .infinity, minHeight: 26)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(palet.dolgu)
                }
            }
        }
        .camKart(kose: 26)
        .sheet(isPresented: $hafizSec) { HafizSecici().presentationDetents([.medium, .large]) }
    }
}
