import PDFKit
import SwiftUI
import UniformTypeIdentifiers

/// Kullanıcının kendi PDF kitapları. Dosyalar Documents/Kitaplar altında, yalnız bu telefonda durur.
enum KitapDeposu {
    static var klasor: URL {
        let u = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Kitaplar", isDirectory: true)
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }

    static func url(_ k: Kitap) -> URL { klasor.appendingPathComponent(k.dosya) }

    static func bilgi(_ url: URL) -> (ad: String, toplam: Int) {
        let belge = PDFDocument(url: url)
        let baslik = (belge?.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let ad = (baslik?.isEmpty == false ? baslik! : url.deletingPathExtension().lastPathComponent)
        return (ad, belge?.pageCount ?? 0)
    }

    /// Seçilen PDF'i kopyalar; aynı adlı dosya varsa ada numara ekler.
    static func ice(_ kaynak: URL) throws -> Kitap {
        let erisim = kaynak.startAccessingSecurityScopedResource()
        defer { if erisim { kaynak.stopAccessingSecurityScopedResource() } }
        var hedef = klasor.appendingPathComponent(kaynak.lastPathComponent)
        var n = 2
        while FileManager.default.fileExists(atPath: hedef.path) {
            hedef = klasor.appendingPathComponent("\(kaynak.deletingPathExtension().lastPathComponent) \(n).pdf")
            n += 1
        }
        try FileManager.default.copyItem(at: kaynak, to: hedef)
        let b = bilgi(hedef)
        return Kitap(ad: b.ad, dosya: hedef.lastPathComponent, toplam: b.toplam)
    }

    /// Dosyalar uygulamasıyla klasöre konmuş ama listede olmayan PDF'leri bulur.
    static func yeniler(_ bilinen: [Kitap]) -> [Kitap] {
        let adlar = Set(bilinen.map(\.dosya))
        let dosyalar = (try? FileManager.default.contentsOfDirectory(at: klasor, includingPropertiesForKeys: nil)) ?? []
        return dosyalar.filter { $0.pathExtension.lowercased() == "pdf" && !adlar.contains($0.lastPathComponent) }.map { u in
            let b = bilgi(u)
            return Kitap(ad: b.ad, dosya: u.lastPathComponent, toplam: b.toplam)
        }
    }
}

struct KitaplarEkrani: View {
    @Environment(Depo.self) private var depo
    @Environment(Yonlendirici.self) private var yon
    @State private var ice = false
    @State private var hata: String?

    var body: some View {
        List {
            if depo.kayit.kitaplar.isEmpty {
                ContentUnavailableView {
                    Label("Henüz kitap yok", systemImage: "books.vertical")
                } description: {
                    Text("PDF kitaplarını ekle; kaldığın sayfa hatırlanır.")
                } actions: {
                    Button("PDF ekle") { ice = true }.buttonStyle(.glassProminent)
                }
                .listRowBackground(Color.clear)
            }
            if !depo.kayit.kitaplar.isEmpty {
                Section {
                    Button { yon.odakAc(konu: "Kitap") } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Odakla oku").font(.kalin(15))
                                Text("Odak başlar; kitap okudukça fidanın büyür").font(.system(size: 12.5, weight: .medium)).foregroundStyle(.secondary)
                            }
                        } icon: { Image(systemName: "leaf.fill").foregroundStyle(Color(hex: "#1FB25A")) }
                    }
                }
            }
            ForEach(depo.kayit.kitaplar) { k in
                NavigationLink(value: Rota.kitap(k.id)) { KitapSatiri(kitap: k) }
            }
            .onDelete { sirala in
                let silinen = sirala.map { depo.kayit.kitaplar[$0] }
                for k in silinen { try? FileManager.default.removeItem(at: KitapDeposu.url(k)) }
                depo.degistir { $0.kitaplar.remove(atOffsets: sirala) }
            }
            Section {
                EmptyView()
            } footer: {
                Text("Kitaplar yalnız bu telefonda saklanır. Dosyalar uygulamasında “İhya › Kitaplar” klasörüne koyduğun PDF'ler de burada görünür.")
            }
        }
        .navigationTitle("Kitaplarım")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { ice = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("PDF ekle")
            }
        }
        .fileImporter(isPresented: $ice, allowedContentTypes: [.pdf], allowsMultipleSelection: true) { sonuc in
            switch sonuc {
            case .success(let urller):
                var yeni: [Kitap] = []
                for u in urller {
                    do { yeni.append(try KitapDeposu.ice(u)) } catch { hata = "“\(u.lastPathComponent)” eklenemedi." }
                }
                if !yeni.isEmpty { depo.degistir { $0.kitaplar.insert(contentsOf: yeni, at: 0) } }
            case .failure:
                hata = "Dosya açılamadı."
            }
        }
        .alert("Olmadı", isPresented: Binding(get: { hata != nil }, set: { if !$0 { hata = nil } })) {
            Button("Tamam", role: .cancel) {}
        } message: { Text(hata ?? "") }
        .task {
            let yeni = KitapDeposu.yeniler(depo.kayit.kitaplar)
            if !yeni.isEmpty { depo.degistir { $0.kitaplar.append(contentsOf: yeni) } }
        }
    }
}

private struct KitapSatiri: View {
    @Environment(\.palet) private var palet
    let kitap: Kitap
    @State private var kapak: UIImage?

    var body: some View {
        HStack(spacing: 14) {
            Group {
                if let kapak { Image(uiImage: kapak).resizable().scaledToFill() } else { Color.secondary.opacity(0.12) }
            }
            .frame(width: 46, height: 62)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 4) {
                Text(kitap.ad).font(.body.weight(.medium)).lineLimit(2)
                if kitap.toplam > 0 {
                    ProgressView(value: Double(kitap.sayfa + 1), total: Double(kitap.toplam)).tint(palet.vurgu)
                    Text("Sayfa \(kitap.sayfa + 1) / \(kitap.toplam)").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .task(id: kitap.dosya) {
            let url = KitapDeposu.url(kitap)
            kapak = await Task.detached(priority: .utility) { () -> UIImage? in
                PDFDocument(url: url)?.page(at: 0)?.thumbnail(of: CGSize(width: 92, height: 124), for: .mediaBox)
            }.value
        }
    }
}

struct OkumaEkrani: View {
    let kitapID: UUID
    @Environment(Depo.self) private var depo
    @Environment(Yonlendirici.self) private var yon
    @Environment(OdakMotoru.self) private var odak
    @Environment(\.colorScheme) private var sistem

    var body: some View {
        if let k = depo.kayit.kitaplar.first(where: { $0.id == kitapID }) {
            let koyu = depo.ayarlar.okumaKoyu ?? (sistem == .dark)
            PDFGorunumu(url: KitapDeposu.url(k), baslangic: k.sayfa) { yeni in
                depo.degistir { kayit in
                    if let i = kayit.kitaplar.firstIndex(where: { $0.id == kitapID }) {
                        kayit.kitaplar[i].sayfa = yeni
                        kayit.kitaplar[i].son = .now
                    }
                }
            }
            .koyuOkuma(koyu)
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle(k.ad)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .uyanikTut()
            .toolbar {
                if odak.hal == .bos {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { yon.odakAc(konu: "Kitap", kitap: kitapID) } label: { Image(systemName: "leaf") }
                            .accessibilityLabel("Odakla oku: okuma süresi bahçene sayılsın")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        depo.degistir { $0.ayarlar.okumaKoyu = !koyu }
                    } label: { Image(systemName: koyu ? "sun.max" : "moon") }
                        .accessibilityLabel(koyu ? "Açık okuma" : "Koyu okuma")
                }
                ToolbarItem(placement: .bottomBar) {
                    Text("\(k.sayfa + 1) / \(max(k.toplam, 1))").font(.footnote).monospacedDigit().foregroundStyle(.secondary)
                }
            }
        } else {
            ContentUnavailableView("Kitap bulunamadı", systemImage: "book")
        }
    }
}

private extension View {
    @ViewBuilder func koyuOkuma(_ etkin: Bool) -> some View {
        if etkin { self.colorInvert().hueRotation(.degrees(180)) } else { self }
    }
}

struct PDFGorunumu: UIViewRepresentable {
    let url: URL
    let baslangic: Int
    let degisti: (Int) -> Void

    func makeCoordinator() -> Koordinator { Koordinator(degisti) }

    func makeUIView(context: Context) -> PDFView {
        let v = PDFView()
        v.autoScales = true
        v.displayMode = .singlePageContinuous
        v.displayDirection = .vertical
        v.pageShadowsEnabled = false
        v.backgroundColor = .systemBackground
        v.document = PDFDocument(url: url)
        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Koordinator.sayfaDegisti(_:)), name: .PDFViewPageChanged, object: v)
        let hedef = baslangic
        Task { @MainActor in
            if let p = v.document?.page(at: hedef) { v.go(to: p) }
            context.coordinator.hazir = true
        }
        return v
    }

    func updateUIView(_ v: PDFView, context: Context) {}

    static func dismantleUIView(_ v: PDFView, coordinator: Koordinator) {
        NotificationCenter.default.removeObserver(coordinator)
    }

    final class Koordinator: NSObject {
        let degisti: (Int) -> Void
        var hazir = false
        init(_ d: @escaping (Int) -> Void) { degisti = d }

        @objc func sayfaDegisti(_ n: Notification) {
            guard hazir, let v = n.object as? PDFView, let p = v.currentPage, let d = v.document else { return }
            degisti(d.index(for: p))
        }
    }
}
