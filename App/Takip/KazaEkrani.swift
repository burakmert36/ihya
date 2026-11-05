import SwiftUI

/// Kaza namazı takibi: Bugün'deki namaz kartından ve Takip › Namaz'dan açılır.
struct KazaEkrani: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                KazaKarti()
                Text("Kaza borcunu her vakit için ayrı tut. Kıldıkça “kıldım” ile düşür; son günlerde işaretlenmemiş vakitleri eklemeyi uygulama kendisi önerir.")
                    .font(.system(size: 12.5, weight: .medium)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 6)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .navigationTitle("Kaza takibi")
        .navigationBarTitleDisplayMode(.inline)
    }
}
