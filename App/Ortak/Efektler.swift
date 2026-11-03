import SwiftUI

/// Tamamlanan odak için kısa konfeti yağmuru (yaklaşık 3 saniye; sonra görünüm kaldırılır).
struct KonfetiYagmuru: View {
    private struct Parca {
        let x: Double, hiz: Double, agirlik: Double, salinim: Double, faz: Double, donus: Double, renk: Color, gecikme: Double
        static func rastgele() -> Parca {
            let renkler: [Color] = [.ihya, Color(red: 1, green: 0.78, blue: 0.25), Color(red: 0.95, green: 0.42, blue: 0.48), Color(red: 0.35, green: 0.62, blue: 0.98), Color(red: 0.72, green: 0.52, blue: 0.95)]
            return Parca(x: .random(in: 0...1), hiz: .random(in: 60...180), agirlik: .random(in: 0.6...1.2), salinim: .random(in: 2...5),
                         faz: .random(in: 0...6), donus: .random(in: -6...6), renk: renkler.randomElement()!, gecikme: .random(in: 0...0.5))
        }
    }

    @State private var parcalar: [Parca] = (0..<70).map { _ in Parca.rastgele() }
    @State private var baslangic = Date()

    var body: some View {
        TimelineView(.animation) { an in
            Canvas { ctx, boyut in
                let t0 = an.date.timeIntervalSince(baslangic)
                for p in parcalar {
                    let t = t0 - p.gecikme
                    guard t > 0 else { continue }
                    let y = -20 + p.hiz * t + 0.5 * 360 * t * t * p.agirlik
                    guard y < boyut.height + 20 else { continue }
                    var c = ctx
                    c.translateBy(x: p.x * boyut.width + sin(t * p.salinim + p.faz) * 18, y: y)
                    c.rotate(by: .radians(t * p.donus))
                    c.opacity = max(0, 1 - t / 3.2)
                    c.fill(Path(roundedRect: CGRect(x: -4, y: -2.5, width: 8, height: 5), cornerRadius: 1.5), with: .color(p.renk))
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

/// Yeni tür açılınca: dönen ışınlar, sıçrayan rozet, ışıltılar, ses ve titreşim.
struct KilitKutlamasi: View {
    let tur: BitkiTuru
    let kapat: () -> Void
    @State private var asama = 0
    @State private var aci = 0.0

    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
                .onTapGesture { kapat() }
            VStack(spacing: 20) {
                ZStack {
                    ForEach(0..<12, id: \.self) { i in
                        Capsule()
                            .fill(LinearGradient(colors: [Color(hex: tur.renk).opacity(0.55), .clear], startPoint: .bottom, endPoint: .top))
                            .frame(width: 14, height: 150)
                            .offset(y: -95)
                            .rotationEffect(.degrees(Double(i) * 30 + aci))
                    }
                    .opacity(asama >= 1 ? 1 : 0)
                    Circle()
                        .fill(Color(hex: tur.renk).opacity(0.18))
                        .frame(width: 210, height: 210)
                        .scaleEffect(asama >= 1 ? 1 : 0.2)
                    BitkiResmi(tur: tur.id, dk: Double(tur.dk), tohum: 7, cerceve: CGRect(x: -4, y: -10, width: 108, height: 128))
                        .frame(width: 180, height: 210)
                        .scaleEffect(asama >= 1 ? 1 : 0.1)
                        .rotationEffect(.degrees(asama >= 1 ? 0 : -25))
                    if asama >= 2 {
                        IsiltiPatlamasi().scaleEffect(4)
                    }
                }
                .frame(height: 300)
                VStack(spacing: 6) {
                    Text("Yeni tür açıldı").font(.subheadline.weight(.semibold)).foregroundStyle(Color(hex: tur.renk))
                    Text(tur.ad).font(.system(size: 36, weight: .bold, design: .rounded))
                    Text(tur.not).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 30)
                }
                .opacity(asama >= 2 ? 1 : 0)
                .offset(y: asama >= 2 ? 0 : 20)
                Button { kapat() } label: { Text("Harika").font(.headline).frame(maxWidth: 220) }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .opacity(asama >= 2 ? 1 : 0)
            }
        }
        .task {
            Efekt.cal("efekt_kilit", duzey: 0.8)
            Dokunsal.kutlama()
            withAnimation(.spring(response: 0.55, dampingFraction: 0.5)) { asama = 1 }
            withAnimation(.linear(duration: 14).repeatForever(autoreverses: false)) { aci = 360 }
            try? await Task.sleep(nanoseconds: 450_000_000)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { asama = 2 }
        }
    }
}
