//
//  ScrollingWaveView 2.swift
//  Aivo
//
//  Created by Huy on 24/10/25.
//


import SwiftUI

struct ScrollingWaveView2: View {
    // Public params
    let bars: Int
    let width: CGFloat
    let height: CGFloat
    let speed: Double

    let baseHeight: CGFloat
    let peakHeight: CGFloat
    let mirrorSymmetry: Bool
    let centerEmphasis: Double
    let roughness: Double
    let ampJitter: Double
    let widthJitter: CGFloat
    let color: Color

    // Tăng biên độ & tách quãng nghỉ
    let intensity: Double
    let dynamics: Double
    let restThreshold: Double
    let restSharpness: Double
    let floorLevel: Double
    let transientStrength: Double

    // internals
    private let spacing: CGFloat = 3
    private let barBaseWidth: CGFloat
    private let gains: [Double]
    private let widths: [CGFloat]

    init(
        bars: Int = 52,
        width: CGFloat,
        height: CGFloat,
        speed: Double = 0.95,
        baseHeight: CGFloat = 6,
        peakHeight: CGFloat = 120,
        mirrorSymmetry: Bool = true,
        centerEmphasis: Double = 0.55,
        roughness: Double = 0.7,
        ampJitter: Double = 0.25,
        widthJitter: CGFloat = 0.18,
        color: Color = .white,
        intensity: Double = 1.65,
        dynamics: Double = 0.7,
        restThreshold: Double = 0.66,
        restSharpness: Double = 0.14,
        floorLevel: Double = 0.03,
        transientStrength: Double = 0.55
    ) {
        self.bars = bars
        self.width = width
        self.height = height
        self.speed = speed
        self.baseHeight = baseHeight
        self.peakHeight = peakHeight
        self.mirrorSymmetry = mirrorSymmetry
        self.centerEmphasis = max(0, min(1, centerEmphasis))
        self.roughness = max(0, min(1, roughness))
        self.ampJitter = max(0, min(0.6, ampJitter))
        self.widthJitter = max(0, min(0.6, widthJitter))
        self.color = color

        self.intensity = intensity
        self.dynamics = dynamics
        self.restThreshold = restThreshold
        self.restSharpness = restSharpness
        self.floorLevel = floorLevel
        self.transientStrength = max(0, min(1, transientStrength))

        // width & jitter
        let estW = max(2, (width - CGFloat(bars - 1) * spacing) / CGFloat(bars))
        self.barBaseWidth = estW

        var g: [Double] = []
        var ws: [CGFloat] = []
        for i in 0..<bars {
            let r1 = Self.hash01(Double(i) * 13.37 + 7.91)
            let r2 = Self.hash01(Double(i) * 5.17  + 0.33)
            g.append(1.0 + self.ampJitter * (r1 * 2 - 1))
            ws.append(estW * (1.0 + self.widthJitter * CGFloat(r2 * 2 - 1)))
        }
        self.gains = g
        self.widths = ws
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let phase = t * speed

            Canvas { ctx, size in
                let totalWidth = widths.reduce(0,+) + CGFloat(bars - 1) * spacing
                var x = (size.width - totalWidth) / 2
                let originY = (size.height - height) / 2
                let nMinus1 = max(1, bars - 1)
                let deltaH = peakHeight - baseHeight

                // envelope chậm để tạo “đoạn nghỉ” rõ ràng
                let phraseRaw = Self.fbm(phase * 0.25, octaves: 3, roughness: 0.35)
                let gate = smoothstep(restThreshold - restSharpness,
                                      restThreshold + restSharpness,
                                      phraseRaw)

                for i in 0..<bars {
                    let j = mirrorSymmetry ? min(i, bars - 1 - i) : i
                    let samplePos = phase + Double(bars - i) * 0.085

                    let f = Self.fbm(samplePos, octaves: 4, roughness: roughness)

                    // transient rời (tạo cảm giác từng “tiếng/âm” bật lên)
                    let trRaw = Self.valueNoise(samplePos * 3.7)
                    let spike = max(0.0, (trRaw - 0.65) / 0.35)
                    let trans = transientStrength * spike

                    // bias giữa
                    let u = Double(j) / Double(nMinus1)
                    let d = abs(u - 0.5) * 2.0
                    let bias = 1.0 - centerEmphasis * (d * d)

                    // tổng cường độ → gate nghỉ → mở dynamic/biên độ
                    var v = (0.75 * f + 0.25 * trans) * bias * gains[j]
                    v = floorLevel + (v * gate) * (1.0 - floorLevel)
                    v = pow(max(0, min(1, v)) * intensity, dynamics)
                    v = max(0, min(1, v))

                    let h = baseHeight + CGFloat(v) * deltaH
                    let bw = widths[i]
                    let y = originY + (height - h) / 2

                    let rect = CGRect(x: x, y: y, width: bw, height: h)
                    let path = Path(roundedRect: rect, cornerSize: CGSize(width: 2, height: 2))
                    ctx.fill(path, with: .color(color))

                    x += bw + spacing
                }
            }
            .frame(width: width, height: height)
        }
    }

    // MARK: - Noise helpers
    private static func hash01(_ x: Double) -> Double {
        let s = sin(x * 12.9898) * 43758.5453
        return s - floor(s)
    }
    private static func valueNoise(_ x: Double) -> Double {
        let i = floor(x)
        let f = x - i
        let u = f * f * (3 - 2 * f)
        let a = hash01(i)
        let b = hash01(i + 1.0)
        return a * (1 - u) + b * u
    }
    private static func fbm(_ x: Double, octaves: Int, roughness: Double) -> Double {
        var amp = 0.5, freq = 1.0, sum = 0.0, norm = 0.0
        let r = max(0.0, min(1.0, roughness))
        for _ in 0..<max(1, octaves) {
            sum += amp * valueNoise(x * freq)
            norm += amp
            amp *= 0.5 + 0.5 * (1.0 - r)
            freq *= 2.02
        }
        return sum / max(1e-6, norm)
    }
    private func smoothstep(_ a: Double, _ b: Double, _ x: Double) -> Double {
        if x <= a { return 0 }
        if x >= b { return 1 }
        let t = (x - a) / (b - a)
        return t * t * (3 - 2 * t)
    }
}
