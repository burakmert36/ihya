import SwiftUI

/// Bugün başlığındaki seri hapı; dokununca seri sayfası açılır.
struct SeriHapi: View {
    @Environment(Depo.self) private var depo
    @Environment(VakitServisi.self) private var vakit
    @Environment(Yonlendirici.self) private var yon
    @Environment(\.palet) private var palet
    @State private var acik = false
    @State private var kutlanan: Int?

    var body: some View {
        let d = depo.seriDurumu(vakit)
        Button { acik = true; Dokunsal.hafif(0.5) } label: {
            HStack(spacing: 5) {
                if d.telafi != nil {
                    Image(systemName: "arrow.uturn.backward.circle.fill").font(.system(size: 13, weight: .bold)).foregroundStyle(.orange)
                    Text("Seriyi kurtar").font(.kalin(13))
                } else {
                    FilizSimgesi().frame(width: 14, height: 14)
                    Text(d.seri > 0 ? "\(d.seri) gün seri" : "Seri başlat").font(.kalin(13))
                    if d.rahmet > 0 {
                        Image(systemName: "cloud.rain.fill").font(.system(size: 11, weight: .bold)).foregroundStyle(Color(hex: "#5AB4FF"))
                    }
                }
            }
            .foregroundStyle(palet.vurgu)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .camYuzey(palet.cam(etkilesimli: true), in: .capsule)
        .accessibilityLabel(d.telafi != nil ? "Seri kırıldı, kurtarılabilir" : "\(d.seri) gün seri, \(d.rahmet) rahmet yağmuru")
        .sheet(isPresented: $acik) {
            SeriSayfasi().sahne(.bugun).presentationDetents([.large])
        }
        .sheet(item: Binding(get: { kutlanan.map { KutlamaTasi(n: $0) } }, set: { kutlanan = $0?.n })) { t in
            SeriKutlama(tas: t.n).sahne(.bugun).presentationDetents([.medium])
        }
        .task(id: d.seri) { kutlamaBak(d) }
        .onAppear { if yon.seriAc { yon.seriAc = false; acik = true } }
        .onChange(of: yon.seriAc) { _, v in if v { yon.seriAc = false; acik = true } }
    }

    /// Yeni bir kilometre taşına ulaşıldıysa bir kez kutlar; seri düşerse eşik de düşer ki yeniden kutlanabilsin.
    private func kutlamaBak(_ d: SeriDurumu) {
        guard !EkranGoruntusu.etkin else { return }
        let tas = d.ulasilanTas ?? 0
        if tas > depo.kayit.kutlananSeri {
            depo.degistir { $0.kutlananSeri = tas }
            kutlanan = tas
        } else if tas < depo.kayit.kutlananSeri, d.telafi == nil {
            depo.degistir { $0.kutlananSeri = tas }
        }
    }
}

private struct KutlamaTasi: Identifiable { let n: Int; var id: Int { n } }

/// Seri sayfası: sayı, bugünün durumu, telafi, rahmet yağmuru ve kilometre taşları.
struct SeriSayfasi: View {
    @Environment(Depo.self) private var depo
    @Environment(VakitServisi.self) private var vakit
    @Environment(\.palet) private var palet
    @Environment(\.dismiss) private var kapat

    var body: some View {
        let d = depo.seriDurumu(vakit)
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    VStack(spacing: 4) {
                        FilizSimgesi().fill(palet.vurgu).frame(width: 46, height: 46)
                        Text("\(d.seri)").font(.system(size: 64, weight: .heavy)).monospacedDigit().contentTransition(.numericText())
                        Text(d.seri == 1 ? "günlük seri" : "günlük seri").font(.kalin(15)).foregroundStyle(.secondary)
                        if d.enUzun > d.seri {
                            Text("En uzun serin: \(d.enUzun) gün").font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 10)

                    durumKarti(d)
                    if let t = d.telafi { telafiKarti(t) }
                    rahmetKarti(d)
                    taslar(d)

                    Text("Gün sınırı gece yarısı değil imsaktır: yatsıdan sonra diktiğin fidan o güne sayılır. Bir günün sayılması için en az bir odak oturumunu tamamlaman yeter.")
                        .font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(16)
            }
            .navigationTitle("Seri")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Bitti") { kapat() } } }
        }
    }

    private func durumKarti(_ d: SeriDurumu) -> some View {
        let yarin = Calendar.current.date(byAdding: .day, value: 1, to: vakit.imsakGunu(.now))!
        return HStack(spacing: 12) {
            Image(systemName: d.bugunDikildi ? "checkmark.seal.fill" : "hourglass")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(d.bugunDikildi ? palet.vurgu : .orange)
            VStack(alignment: .leading, spacing: 3) {
                Text(d.bugunDikildi ? "Bugün yeşerdi" : "Bugün henüz fidan yok").font(.kalin(16))
                Text(d.bugunDikildi ? "Yarın imsaktan sonra yeni gün başlar." : "İmsaka kadar (\(Tarihler.saat.string(from: vakit.imsak(yarin)))) bir odak oturumu yeter.")
                    .font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .camKart(kose: 24)
    }

    private func telafiKarti(_ t: SeriDurumu.Telafi) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Serin kurtarılabilir", systemImage: "arrow.uturn.backward.circle.fill").font(.kalin(16)).foregroundStyle(.orange)
            Text("Bir gün boş geçti. \(Tarihler.gunAy.string(from: t.bitis)) \(Tarihler.saat.string(from: t.bitis))'e kadar \(t.kalan) fidan daha dikersen \(t.onceki) günlük serin kaldığı yerden sürer.")
                .font(.system(size: 14, weight: .medium))
            HStack(spacing: 6) {
                ForEach(0..<Seri.telafiDikim, id: \.self) { i in
                    Circle().fill(i < Seri.telafiDikim - t.kalan ? AnyShapeStyle(Color.orange) : AnyShapeStyle(Color.primary.opacity(0.1)))
                        .frame(width: 14, height: 14)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .camKart(Color.orange, kose: 24)
    }

    private func rahmetKarti(_ d: SeriDurumu) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Rahmet yağmuru").font(.kalin(16))
                Spacer()
                HStack(spacing: 6) {
                    ForEach(0..<Seri.enFazlaRahmet, id: \.self) { i in
                        Image(systemName: i < d.rahmet ? "cloud.rain.fill" : "cloud")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(i < d.rahmet ? Color(hex: "#5AB4FF") : Color.secondary)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(d.rahmet) rahmet yağmuru birikmiş")
            }
            Text("Fidan diktiğin her \(Seri.rahmetGun) günde bir rahmet yağmuru kazanırsın (en çok \(Seri.enFazlaRahmet) birikir). Boş geçen bir günü kendiliğinden kapatır; serin kırılmaz.")
                .font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)
            if d.rahmet < Seri.enFazlaRahmet {
                Text("Sonraki yağmura \(d.rahmeteKalan) gün").font(.kalin(13)).foregroundStyle(palet.vurgu)
            }
            if !d.rahmetGunleri.isEmpty {
                Text("Rahmetle kapanan günler: " + d.rahmetGunleri.suffix(3).map { Tarihler.gunAy.string(from: $0) }.joined(separator: ", "))
                    .font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
            }
        }
        .camKart(kose: 24)
    }

    private func taslar(_ d: SeriDurumu) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Kilometre taşları").font(.kalin(16))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(Seri.taslar, id: \.self) { n in
                    let ulasti = d.enUzun >= n
                    VStack(spacing: 4) {
                        ZStack {
                            SekizKoseYildiz(ic: 0.72).fill(ulasti ? palet.vurgu.opacity(0.25) : Color.primary.opacity(0.05))
                            SekizKoseYildiz(ic: 0.72).stroke(ulasti ? palet.vurgu : Color.secondary.opacity(0.4), lineWidth: 1.2)
                            Text("\(n)").font(.system(size: 17, weight: .heavy)).monospacedDigit()
                                .foregroundStyle(ulasti ? palet.vurgu : .secondary)
                        }
                        .frame(width: 58, height: 58)
                        Text(SeriKutlama.ad(n)).font(.system(size: 11.5, weight: .bold)).foregroundStyle(.secondary).lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(n) gün, \(ulasti ? "ulaşıldı" : "henüz değil")")
                }
            }
        }
        .camKart(kose: 24)
    }
}

/// Kilometre taşı kutlaması.
struct SeriKutlama: View {
    let tas: Int
    @Environment(\.palet) private var palet
    @Environment(\.accessibilityReduceMotion) private var hareketiAzalt
    @Environment(\.dismiss) private var kapat
    @State private var belir = false

    static func ad(_ n: Int) -> String {
        switch n {
        case 3: "İlk adımlar"
        case 7: "Bir hafta"
        case 30: "Bir ay"
        case 40: "Kırk gün"
        case 100: "Yüz gün"
        case 365: "Bir yıl"
        default: "\(n) gün"
        }
    }

    static func soz(_ n: Int) -> String {
        switch n {
        case 3: "“Amellerin Allah'a en sevgili olanı, az olsa bile en devamlı yapılanıdır.”"
        case 7: "Bir haftadır her gün bir fidan. Bahçen seninle büyüyor."
        case 30: "Bir ay boyunca her gün. Bu artık bir alışkanlık."
        case 40: "Kırk gün: kalbin yeni bir huya alıştığı süre."
        case 100: "Yüz gündür bahçeni hiç boş bırakmadın."
        default: "Bir yıl boyunca her gün. Bahçen bir orman oldu."
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                SekizKoseYildiz(ic: 0.72).fill(palet.vurgu.opacity(0.18)).frame(width: 150, height: 150)
                SekizKoseYildiz(ic: 0.72).stroke(palet.vurgu, lineWidth: 2).frame(width: 150, height: 150)
                    .rotationEffect(.degrees(belir ? 22.5 : 0))
                Text("\(tas)").font(.system(size: 54, weight: .heavy)).foregroundStyle(palet.vurgu)
            }
            .scaleEffect(belir ? 1 : 0.6)
            .padding(.top, 24)
            Text(SeriKutlama.ad(tas)).font(.system(size: 26, weight: .heavy))
            Text(SeriKutlama.soz(tas)).font(.okuma(17)).multilineTextAlignment(.center).foregroundStyle(.secondary)
                .padding(.horizontal, 24)
            if tas == 3 {
                Text("Buhârî, 6464").font(.caption.weight(.bold)).foregroundStyle(Color.altin)
            }
            AnaDugme(baslik: "ELHAMDÜLİLLAH", yukseklik: 34) { kapat() }
                .padding(.horizontal, 24)
            Spacer(minLength: 0)
        }
        .onAppear {
            if hareketiAzalt { belir = true } else { withAnimation(.spring(response: 0.6, dampingFraction: 0.55)) { belir = true } }
            Efekt.cal("efekt_kutlama", duzey: 0.7)
            Dokunsal.basari()
        }
    }
}
