//
//  AivoSunsetBackground.swift
//  Aivo
//
//  Created by Huy on 20/10/25.
//


import SwiftUI

struct AivoSunsetBackground: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Đốm sáng trung tâm rất nhẹ (tuỳ chọn)
            CenterGlow()

            // Tam giác chéo phía TRÊN – đỉnh tại góc trên-phải
            CornerTriangleGlow(corner: .topTrailing)

            // Tam giác chéo phía DƯỚI – đỉnh tại góc dưới-trái
            CornerTriangleGlow(corner: .bottomLeading)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Palette vàng-cam thời thượng
fileprivate enum Sunset {
    static let bright = Color(red: 1.00, green: 0.83, blue: 0.35) // #FFD36A
    static let mid    = Color(red: 1.00, green: 0.61, blue: 0.18) // #FF9B2F
    static let deep   = Color(red: 1.00, green: 0.42, blue: 0.00) // #FF6A00
}

// MARK: - Glow trung tâm (nhẹ)
fileprivate struct CenterGlow: View {
    var body: some View {
        RadialGradient(colors: [Sunset.mid.opacity(0.18), Sunset.deep.opacity(0.10), .clear],
                       center: .center, startRadius: 24, endRadius: 340)
            .blendMode(.screen)
            .ignoresSafeArea()
    }
}

// MARK: - “Tam giác” chéo với tâm gradient đặt ở GÓC
fileprivate struct CornerTriangleGlow: View {
    enum Corner { case topTrailing, bottomLeading }
    let corner: Corner

    // độ sâu tam giác ăn vào màn hình (0.0…1.0)
    var depth: CGFloat = 0.42
    // độ mờ mép
    var blur: CGFloat = 70
    // độ mạnh ánh sáng
    var strength: CGFloat = 1.0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            // 1) RadialGradient đặt TÂM ở ngay GÓC cần sáng nhất
            let center: UnitPoint = (corner == .topTrailing) ? .topTrailing : .bottomLeading
            let endRadius = hypot(w, h) // đủ lớn phủ toàn bộ khi mask

            let glow = Rectangle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: Sunset.bright.opacity(0.95 * strength), location: 0.00),
                            .init(color: Sunset.mid.opacity(0.60 * strength),    location: 0.35),
                            .init(color: Sunset.deep.opacity(0.40 * strength),   location: 0.60),
                            .init(color: .clear,                                 location: 1.00)
                        ]),
                        center: center,
                        startRadius: 0,
                        endRadius: endRadius
                    )
                )
                .blendMode(.screen)

            // 2) Mask bằng một PATH hình TAM GIÁC bám vào góc
            glow
                .mask(
                    Path { p in
                        switch corner {
                        case .topTrailing:
                            // cạnh trên & cạnh phải + cạnh chéo xuống
                            p.move(to: CGPoint(x: 0, y: 0))               // trái-trên
                            p.addLine(to: CGPoint(x: w, y: 0))            // phải-trên
                            p.addLine(to: CGPoint(x: w, y: h * depth))    // phải xuống 1 đoạn
                            p.addLine(to: CGPoint(x: w * (1 - depth), y: 0)) // chéo về trong
                            p.closeSubpath()
                        case .bottomLeading:
                            // cạnh dưới & cạnh trái + cạnh chéo lên
                            p.move(to: CGPoint(x: 0, y: h))               // trái-dưới
                            p.addLine(to: CGPoint(x: 0, y: h * (1 - depth))) // trái lên 1 đoạn
                            p.addLine(to: CGPoint(x: w * depth, y: h))    // chéo vào trong
                            p.addLine(to: CGPoint(x: 0, y: h))            // đóng
                            p.closeSubpath()
                        }
                    }
                )
                .blur(radius: blur)     // mép mềm đúng kiểu ảnh
                .opacity(0.95)
                .ignoresSafeArea()
        }
    }
}

#Preview {
    AivoBackgroundView()
}

