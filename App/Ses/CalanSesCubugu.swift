import SwiftUI

/// Odak sesleri seçiliyken her ekranda alt çubuğun üstünde durur: çal/durdur, sesler ekranına git, kapat.
struct CalanSesCubugu: View {
    @Environment(SesMotoru.self) private var ses
    @Environment(Yonlendirici.self) private var yon
    @Environment(\.palet) private var palet

    var body: some View {
        if !ses.katman.isEmpty {
            HStack(spacing: 10) {
                Button { ses.degistirOynat(); Dokunsal.hafif(0.6) } label: {
                    Image(systemName: ses.caliyor ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .bold))
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: 40, height: 40).contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(ses.caliyor ? "Odak seslerini durdur" : "Odak seslerini çal")
                Button { yon.sesleriAc() } label: {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(ses.seciliAdlar).font(.kalin(13.5)).lineLimit(1)
                        Text(ses.caliyor ? "Odak sesleri çalıyor" : "Duraklatıldı").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Sesler ekranını açar")
                Button { ses.hepsiniKis(); Dokunsal.hafif(0.4) } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).frame(width: 36, height: 36).contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Odak seslerini kapat")
            }
            .padding(.leading, 8).padding(.trailing, 6).padding(.vertical, 4)
            .camYuzey(palet.cam(etkilesimli: true), in: .capsule)
            .padding(.horizontal, 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
