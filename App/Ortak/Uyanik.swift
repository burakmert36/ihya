import SwiftUI

/// Okurken ekran kararmasın: açık okuma ekranı sayılır, hiçbiri kalmayınca sistem ayarına döner.
@MainActor
enum EkranUyanik {
    private static var sayac = 0
    static func ac() {
        sayac += 1
        UIApplication.shared.isIdleTimerDisabled = true
    }
    static func kapat() {
        sayac = max(0, sayac - 1)
        if sayac == 0 { UIApplication.shared.isIdleTimerDisabled = false }
    }
}

private struct UyanikTut: ViewModifier {
    @Environment(Depo.self) private var depo
    @State private var acik = false
    func body(content: Content) -> some View {
        content
            .onAppear {
                guard depo.ayarlar.ekranAcik, !acik else { return }
                acik = true
                EkranUyanik.ac()
            }
            .onDisappear {
                guard acik else { return }
                acik = false
                EkranUyanik.kapat()
            }
    }
}

extension View {
    /// "Okurken ekran kapanmasın" ayarı açıksa bu ekran görünürken ekran kararmaz.
    func uyanikTut() -> some View { modifier(UyanikTut()) }
}
