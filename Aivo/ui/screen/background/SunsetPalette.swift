//
//  SunsetPalette.swift
//  Aivo
//
//  Created by Huy on 20/10/25.
//


import SwiftUI

// MARK: - Palette (vàng–cam thời thượng)
private struct SunsetPalette {
    // bạn có thể tinh chỉnh cho hợp brand
    static let warmBright = Color(red: 1.00, green: 0.83, blue: 0.35) // #FFD36A
    static let warmMid    = Color(red: 1.00, green: 0.61, blue: 0.18) // #FF9B2F
    static let warmDeep   = Color(red: 1.00, green: 0.42, blue: 0.00) // #FF6A00
}

// MARK: - Glow trung tâm (nhẹ như ảnh)
private struct CenterGlow: View {
    var body: some View {
        RadialGradient(
            colors: [
                SunsetPalette.warmMid.opacity(0.22),
                SunsetPalette.warmDeep.opacity(0.12),
                .clear
            ],
            center: .center,
            startRadius: 24,
            endRadius: 340
        )
        .blendMode(.screen)
        .ignoresSafeArea()
    }
}

// MARK: - Vệt chéo
private struct DiagonalBeam: View {
    enum Corner { case topLeft, bottomRight }
    let corner: Corner
    init(_ c: Corner) { self.corner = c }

    var body: some View {
        GeometryReader { geo in
            let maxSide = max(geo.size.width, geo.size.height)
            // kích thước vệt: đủ dài để phủ chéo qua màn
            let beamWidth  = maxSide * 1.65
            let beamHeight = maxSide * 0.28
            let angle: Angle = corner == .topLeft ? .degrees(-28) : .degrees(28)

            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: SunsetPalette.warmBright,                location: 0.0),
                            .init(color: SunsetPalette.warmMid.opacity(0.55),     location: 0.45),
                            .init(color: .clear,                                  location: 1.0)
                        ]),
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(width: beamWidth, height: beamHeight)
                .rotationEffect(angle)
                .offset(x: corner == .topLeft ? -maxSide * 0.08 :  maxSide * 0.10,
                        y: corner == .topLeft ? -maxSide * 0.26 :  maxSide * 0.28)
                .blur(radius: 72)          // mép mềm giống ảnh
                .opacity(0.95)
                .blendMode(.screen)        // phát sáng trên nền đen
                .ignoresSafeArea()
        }
    }
}
