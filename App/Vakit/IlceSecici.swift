import SwiftUI

/// Diyanet takvimi için ülke, şehir ve ilçe seçimi (ezanvakti.emushaf.net listeleri).
struct IlceSecici: View {
    @Environment(Depo.self) private var depo
    @Environment(VakitServisi.self) private var vakit
    @Environment(\.palet) private var palet
    @Environment(\.dismiss) private var kapat

    @State private var ulke = VakitServisi.Yer(id: 2, ad: "Türkiye")
    @State private var sehir: VakitServisi.Yer?
    @State private var liste: [VakitServisi.Yer] = []
    @State private var ulkeler: [VakitServisi.Yer] = []
    @State private var yukleniyor = false
    @State private var hata = false
    @State private var arama = ""

    var body: some View {
        let tr = Locale(identifier: "tr_TR")
        let q = arama.trimmingCharacters(in: .whitespaces)
        let suzulmus = q.isEmpty ? liste : liste.filter { $0.ad.range(of: q, options: [.caseInsensitive, .diacriticInsensitive], locale: tr) != nil }
        ScrollView {
            LazyVStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text(sehir == nil ? "\(ulke.ad) · şehir seç" : "\(sehir!.ad) · ilçe seç").font(.kalin(15))
                    Spacer()
                    if sehir != nil {
                        Button { sehir = nil; arama = ""; Task { await yukle() } } label: { Label("Şehirler", systemImage: "chevron.left").font(.kalin(13)) }
                            .buttonStyle(.glass)
                    } else {
                        Menu {
                            ForEach(ulkeler) { u in Button(u.ad) { ulke = u; arama = ""; Task { await yukle() } } }
                        } label: { Label("Ülke", systemImage: "globe").font(.kalin(13)) }
                        .buttonStyle(.glass)
                        .disabled(ulkeler.isEmpty)
                    }
                }
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField(sehir == nil ? "Şehir ara" : "İlçe ara", text: $arama).autocorrectionDisabled()
                }
                .padding(.horizontal, 16).frame(height: 44)
                .camYuzey(palet.cam(), in: .capsule)
                if yukleniyor {
                    ProgressView().padding(.top, 30)
                } else if hata {
                    VStack(spacing: 10) {
                        Text("Liste indirilemedi. İnternet bağlantını kontrol et.").font(.system(size: 14, weight: .semibold)).multilineTextAlignment(.center)
                        Button("Tekrar dene") { Task { await yukle() } }.buttonStyle(.glass)
                    }
                    .padding(.top, 30)
                }
                ForEach(suzulmus) { y in
                    let secili = sehir != nil && y.id == depo.ayarlar.ilceKodu
                    Button { sec(y) } label: {
                        HStack {
                            Text(y.ad).font(.system(size: 16, weight: .semibold))
                            Spacer()
                            Image(systemName: secili ? "checkmark.circle.fill" : "chevron.right")
                                .font(.system(size: secili ? 18 : 13, weight: .bold))
                                .foregroundStyle(secili ? palet.vurgu : .secondary)
                        }
                        .padding(.horizontal, 16).frame(height: 50)
                        .contentShape(Rectangle())
                        .camYuzey(palet.cam(etkilesimli: true), in: .rect(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                }
                Text("Vakitler Diyanet İşleri Başkanlığı'nın ilçe takviminden gelir; seçince otuz günlük takvim iner ve internetsiz de kullanılır.")
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    .padding(.top, 10)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("İlçe")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await yukle()
            if ulkeler.isEmpty { ulkeler = await VakitServisi.liste("ulkeler", adAnahtari: "UlkeAdi", idAnahtari: "UlkeID") ?? [] }
        }
    }

    private func yukle() async {
        yukleniyor = true
        hata = false
        defer { yukleniyor = false }
        let sonuc: [VakitServisi.Yer]?
        if let s = sehir {
            sonuc = await VakitServisi.liste("ilceler/\(s.id)", adAnahtari: "IlceAdi", idAnahtari: "IlceID")
        } else {
            sonuc = await VakitServisi.liste("sehirler/\(ulke.id)", adAnahtari: "SehirAdi", idAnahtari: "SehirID")
        }
        liste = sonuc ?? []
        hata = sonuc == nil
    }

    private func sec(_ y: VakitServisi.Yer) {
        arama = ""
        if let s = sehir {
            let ad = y.ad == s.ad || y.ad.localizedCaseInsensitiveContains("merkez") ? s.ad : "\(s.ad) · \(y.ad)"
            depo.degistir {
                $0.ayarlar.ilceKodu = y.id
                $0.ayarlar.ilceAdi = ad
                $0.ayarlar.konumKipi = .bursa
            }
            Dokunsal.basari()
            kapat()
        } else {
            sehir = y
            Task { await yukle() }
        }
    }
}
