import SwiftUI

struct KonularEkrani: View {
    @Environment(Depo.self) private var depo
    @State private var duzenlenen: Konu?

    static let renkler = ["#2F80ED", "#27AE60", "#F2994A", "#9B51E0", "#EB5757", "#00A3A3", "#F2C94C", "#8D6E63", "#E26DBA", "#56657F"]

    var body: some View {
        List {
            ForEach(depo.kayit.konular) { k in
                Button { duzenlenen = k } label: {
                    HStack(spacing: 12) {
                        Circle().fill(Color(hex: k.renk)).frame(width: 14, height: 14)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(k.ad).foregroundStyle(.primary)
                            if !k.aciklama.isEmpty { Text(k.aciklama).font(.caption).foregroundStyle(.secondary).lineLimit(2) }
                        }
                    }
                }
            }
            .onDelete { s in depo.degistir { $0.konular.remove(atOffsets: s) } }
            .onMove { s, h in depo.degistir { $0.konular.move(fromOffsets: s, toOffset: h) } }
        }
        .navigationTitle("Odak konuları")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { EditButton() }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    duzenlenen = Konu(ad: "", renk: KonularEkrani.renkler[depo.kayit.konular.count % KonularEkrani.renkler.count])
                } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Konu ekle")
            }
        }
        .sheet(item: $duzenlenen) { k in
            KonuDuzenle(konu: k) { yeni in
                depo.degistir { kayit in
                    if let i = kayit.konular.firstIndex(where: { $0.id == yeni.id }) { kayit.konular[i] = yeni } else { kayit.konular.append(yeni) }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

struct KonuDuzenle: View {
    @Environment(\.dismiss) private var kapat
    @State var konu: Konu
    let kaydet: (Konu) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Ad (ör. Ders, Kur'ân, Kitap)", text: $konu.ad)
                Section("Renk") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 14) {
                        ForEach(KonularEkrani.renkler, id: \.self) { r in
                            Circle()
                                .fill(Color(hex: r))
                                .frame(width: 34, height: 34)
                                .overlay { if konu.renk == r { Image(systemName: "checkmark").font(.footnote.weight(.bold)).foregroundStyle(.white) } }
                                .onTapGesture { konu.renk = r }
                                .accessibilityAddTraits(konu.renk == r ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 6)
                }
                Section("Açıklama") {
                    TextField("İsteğe bağlı", text: $konu.aciklama, axis: .vertical).lineLimit(2...5)
                }
            }
            .navigationTitle(konu.ad.isEmpty ? "Yeni konu" : konu.ad)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Vazgeç") { kapat() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        var k = konu
                        k.ad = k.ad.trimmingCharacters(in: .whitespacesAndNewlines)
                        kaydet(k)
                        kapat()
                    }
                    .disabled(konu.ad.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
