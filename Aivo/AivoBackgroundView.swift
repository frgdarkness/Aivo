import SwiftUI

// MARK: - Palette
struct AivoPalette {
    let bg        = Color.black
    let glowInner = Color(hex: 0xFFB13B)   // vàng đậm
    let glowOuter = Color(hex: 0xFF6A00)   // cam neon
    let beamStart = Color(hex: 0xFFD179)   // sáng hơn ở mép
    let beamEnd   = Color.clear            // fade ra trong suốt
}

// MARK: - Background
struct AivoBackgroundView: View {
    let p = AivoPalette()
    var body: some View {
        ZStack {
            // 1) Base black
            p.bg.ignoresSafeArea()

            // 2) Center glow (nhẹ như ảnh mẫu)
            RadialGradient(
                colors: [p.glowInner.opacity(0.28),
                         p.glowOuter.opacity(0.18),
                         .clear],
                center: .center,
                startRadius: 30,
                endRadius: 320
            )
            .blendMode(.screen)
            .ignoresSafeArea()

            // 3) Top-left beam (chéo xuống)
            NeonBeam(start: p.beamStart, end: p.beamEnd)
                .rotationEffect(.degrees(-28))
                .offset(x: -40, y: -220)

            // 4) Bottom-right beam (chéo lên)
            NeonBeam(start: p.beamStart, end: p.beamEnd)
                .rotationEffect(.degrees(28))
                .offset(x: 60, y: 260)
        }
    }
}

// MARK: - Beam
private struct NeonBeam: View {
    let start: Color
    let end: Color
    @State private var pulse = false

    var body: some View {
        // Mảng dài mỏng, blur mạnh để thành "vệt sáng"
        RoundedRectangle(cornerRadius: 30)
            .fill(
                LinearGradient(colors: [start, end],
                               startPoint: .leading, endPoint: .trailing)
            )
            .frame(width: 950, height: 280)   // đủ dài để phủ chéo màn
            .blur(radius: 60)
            .opacity(pulse ? 0.75 : 0.6)
            .blendMode(.screen)               // add sáng lên nền đen
            .onAppear {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    pulse.toggle()
                }
            }
            .ignoresSafeArea()
    }
}

// MARK: - Hex helper
extension Color {
    init(hex: UInt, alpha: CGFloat = 1) {
        let r = Double((hex >> 16) & 0xFF)/255
        let g = Double((hex >> 8) & 0xFF)/255
        let b = Double(hex & 0xFF)/255
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: Double(alpha))
    }
}

#Preview {
    AivoBackgroundView()
}
