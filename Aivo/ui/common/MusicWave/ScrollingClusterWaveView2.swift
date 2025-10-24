//
//  ScrollingClusterWaveView 2.swift
//  Aivo
//
//  Created by Huy on 24/10/25.
//


import SwiftUI
import Foundation   // lround()

struct ScrollingClusterWaveView2: View {
    // MARK: Public
    let bars: Int
    let width: CGFloat
    let height: CGFloat
    /// tốc độ cuộn (chu kỳ/giây) — chạy **phải → trái**
    let speed: Double

    let baseHeight: CGFloat
    let peakHeight: CGFloat
    let color: Color

    // nhấn giữa & organic
    let mirrorSymmetry: Bool
    let centerEmphasis: Double
    let ampJitter: Double
    let widthJitter: CGFloat

    // đặc tính "tiếng/cụm"
    let shortProb: Double
    let shortBarsRange: ClosedRange<Int> // 5...7
    let longBarsRange: ClosedRange<Int>  // 10...16
    let clustersPerInterval: Int         // 2–3
    let clusterSpacing: Double           // ~0.6s giữa các cụm
    let dynamics: Double                 // <1 mở dynamic (0.6–0.8)
    let floorLevel: Double               // 0.0..0.08
    let textureAmount: Double            // 0..0.4

    // MARK: internals
    private let spacing: CGFloat = 3
    private let barBaseWidth: CGFloat
    private let gains: [Double]
    private let widths: [CGFloat]

    init(
        bars: Int = 52,
        width: CGFloat,
        height: CGFloat,
        speed: Double = 1.0,
        baseHeight: CGFloat = 6,
        peakHeight: CGFloat = 118,
        color: Color = .white,
        mirrorSymmetry: Bool = true,
        centerEmphasis: Double = 0.6,
        ampJitter: Double = 0.24,
        widthJitter: CGFloat = 0.18,
        shortProb: Double = 0.65,
        shortBarsRange: ClosedRange<Int> = 5...7,
        longBarsRange: ClosedRange<Int> = 10...16,
        clustersPerInterval: Int = 3,
        clusterSpacing: Double = 0.7,
        dynamics: Double = 0.68,
        floorLevel: Double = 0.02,
        textureAmount: Double = 0.14
    ) {
        self.bars = bars
        self.width = width
        self.height = height
        self.speed = speed
        self.baseHeight = baseHeight
        self.peakHeight = peakHeight
        self.color = color
        self.mirrorSymmetry = mirrorSymmetry
        self.centerEmphasis = max(0, min(1, centerEmphasis))
        self.ampJitter = max(0, min(0.6, ampJitter))
        self.widthJitter = max(0, min(0.6, widthJitter))
        self.shortProb = max(0, min(1, shortProb))
        self.shortBarsRange = shortBarsRange
        self.longBarsRange = longBarsRange
        self.clustersPerInterval = max(1, clustersPerInterval)
        self.clusterSpacing = clusterSpacing
        self.dynamics = dynamics
        self.floorLevel = max(0, min(0.1, floorLevel))
        self.textureAmount = max(0, min(0.5, textureAmount))

        let estW = max(2, (width - CGFloat(bars - 1) * spacing) / CGFloat(bars))
        self.barBaseWidth = estW

        var g: [Double] = []
        var ws: [CGFloat] = []
        for i in 0..<bars {
            let r1 = Self.hash01(Double(i) * 13.37 + 7.91)
            let r2 = Self.hash01(Double(i) * 5.17  + 0.33)
            g.append(1.0 + self.ampJitter * (r1 * 2 - 1))                 // ~0.75..1.25
            ws.append(estW * (1.0 + self.widthJitter * CGFloat(r2 * 2 - 1)))
        }
        self.gains = g
        self.widths = ws
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let phase = t * speed     // tăng tuyến tính theo thời gian

            Canvas { ctx, size in
                let totalWidth = widths.reduce(0,+) + CGFloat(bars - 1) * spacing
                var x = (size.width - totalWidth) / 2
                let originY = (size.height - height) / 2
                let nMinus1 = max(1, bars - 1)
                let deltaH = peakHeight - baseHeight

                // mỗi bar lệch một lượng thời gian — R→L
                let barStride = 0.08

                for i in 0..<bars {
                    // đối xứng theo tâm để hình đẹp như ảnh
                    let j = mirrorSymmetry ? min(i, bars - 1 - i) : i

                    // R→L: i càng lớn (bên phải) → mẫu thời gian lớn hơn
                    let tSample = phase + Double(i) * barStride

                    // Năng lượng theo các CỤM (max, không average) → rơi gần 0 giữa các cụm
                    let clusterVal = clusterFieldMax(tSample: tSample, barStride: barStride)

                    // chút texture nhẹ để organic mà không phá cụm
                    let tex = textureAmount * (Self.fbm(tSample * 1.5, octaves: 3) - 0.5)

                    // bias giữa
                    let u = Double(j) / Double(nMinus1)
                    let d = abs(u - 0.5) * 2.0
                    let bias = 1.0 - centerEmphasis * (d * d)

                    // cường độ 0..1
                    var v = max(0, min(1, clusterVal + tex)) * bias * gains[j]
                    // mở dynamic và đẩy về sàn khi nghỉ
                    v = floorLevel + pow(max(0, min(1, v)), dynamics) * (1 - floorLevel)

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

    // MARK: - Cluster field (3–n cụm/đoạn, đỉnh giữa lớn, rìa nhỏ)
    /// Dùng MAX của các gaussian-cluster để thấy cụm tách bạch.
    private func clusterFieldMax(tSample t: Double, barStride: Double) -> Double {
        // xem xét cụm trong cửa sổ ±2 khoảng
        let k0 = Int(floor((t - clusterSpacing * 2) / clusterSpacing))
        let k1 = Int(floor((t + clusterSpacing * 2) / clusterSpacing))

        var maxVal = 0.0

        for k in k0...k1 {
            let count = 1 + Int(Double(clustersPerInterval - 1) * Self.hash01(Double(k) * 2.123))
            for idx in 0..<count {
                let off = Self.hash01(Double(k * 31 + idx) * 1.137) * clusterSpacing * 0.92

                // short or long cluster
                let chooseShort = Self.hash01(Double(k * 17 + idx) * 0.777) < shortProb

                let shortLerp = Self.lerp(Double(shortBarsRange.lowerBound),
                                          Double(shortBarsRange.upperBound),
                                          Self.hash01(Double(k * 13 + idx) * 4.17))
                let longLerp  = Self.lerp(Double(longBarsRange.lowerBound),
                                          Double(longBarsRange.upperBound),
                                          Self.hash01(Double(k * 19 + idx) * 3.11))

                let shortCount = clamp(Int(lround(shortLerp)),
                                       shortBarsRange.lowerBound,
                                       shortBarsRange.upperBound)
                let longCount  = clamp(Int(lround(longLerp)),
                                       longBarsRange.lowerBound,
                                       longBarsRange.upperBound)

                let barCount = chooseShort ? shortCount : longCount

                // FWHM ~ barsWanted → sigma ≈ bars / 2.355; thu hẹp một chút (0.85)
                let sigma = max(1e-4, (Double(barCount) * barStride) / 2.355 * 0.85)

                // biên độ (0.7..1.0) để đỉnh rõ
                let amp = 0.7 + 0.3 * Self.hash01(Double(k) * 8.88 + Double(idx) * 3.77)

                let center = Double(k) * clusterSpacing + off
                let g = amp * gauss(t - center, sigma: sigma)

                if g > maxVal { maxVal = g }
            }
        }
        // clamp 0..1
        return min(1.0, maxVal)
    }

    private func gauss(_ x: Double, sigma: Double) -> Double {
        let s2 = sigma * sigma * 2.0
        return exp(-(x * x) / max(1e-9, s2))
    }

    // MARK: - Noise helpers
    private static func hash01(_ x: Double) -> Double {
        let s = sin(x * 12.9898) * 43758.5453
        return s - floor(s)
    }
    private static func valueNoise(_ x: Double) -> Double {
        let i = floor(x)
        let f = x - i
        let u = f * f * (3 - 2 * f)   // smoothstep
        let a = hash01(i)
        let b = hash01(i + 1.0)
        return a * (1 - u) + b * u
    }
    private static func fbm(_ x: Double, octaves: Int) -> Double {
        var amp = 0.5, freq = 1.0, sum = 0.0, norm = 0.0
        for _ in 0..<max(1, octaves) {
            sum += amp * valueNoise(x * freq)
            norm += amp
            amp *= 0.55
            freq *= 2.02
        }
        return sum / max(1e-6, norm) // 0..1
    }
}

// MARK: - Small helpers
@inline(__always)
private func clamp<T: Comparable>(_ x: T, _ lo: T, _ hi: T) -> T { max(lo, min(hi, x)) }

private extension ScrollingClusterWaveView2 {
    static func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }
}
