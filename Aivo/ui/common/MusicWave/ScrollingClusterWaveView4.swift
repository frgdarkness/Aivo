//
//  ScrollingClusterWaveView 2.swift
//  Aivo
//
//  Created by Huy on 24/10/25.
//


//
//  ScrollingClusterWaveView.swift
//  Aivo
//
//  Created by Huy on 24/10/25.
//

import SwiftUI
import Foundation   // lround()

struct ScrollingClusterWaveView4: View {
    // MARK: - Public
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
    let centerEmphasis: Double      // 0..1
    let ampJitter: Double           // 0..0.5
    let widthJitter: CGFloat        // 0..0.4

    // “đặc tính cụm/tiếng”
    let shortProb: Double           // xác suất tiếng ngắn
    let shortBarsRange: ClosedRange<Int> // 5...7
    let longBarsRange: ClosedRange<Int>  // 10...16
    let clustersPerInterval: Int    // 2–3 cụm/mỗi khoảng
    let clusterSpacing: Double      // ~0.55 s “nhịp độ” cụm
    let dynamics: Double            // pow curve (<1 mở dynamic)
    let floorLevel: Double          // sàn khi nghỉ (0.02–0.05)
    let textureAmount: Double       // 0..0.4 gồ ghề nhẹ

    // MARK: - internals
    private let spacing: CGFloat = 2.5
    private let barBaseWidth: CGFloat
    private let gains: [Double]
    private let widths: [CGFloat]

    init(
        bars: Int = 52,
        width: CGFloat,
        height: CGFloat,
        speed: Double = 0.95,
        baseHeight: CGFloat = 6,
        peakHeight: CGFloat = 118,
        color: Color = .white,
        mirrorSymmetry: Bool = true,
        centerEmphasis: Double = 0.6,
        ampJitter: Double = 0.22,
        widthJitter: CGFloat = 0.14,
        shortProb: Double = 0.65,
        shortBarsRange: ClosedRange<Int> = 5...7,
        longBarsRange: ClosedRange<Int> = 8...12,      // ✅ cụm dài vừa phải để thấy rõ biên
        clustersPerInterval: Int = 3,
        clusterSpacing: Double = 0.65,                 // ✅ tách cụm hơn
        dynamics: Double = 0.66,
        floorLevel: Double = 0.02,
        textureAmount: Double = 0.12
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
        self.floorLevel = floorLevel
        self.textureAmount = max(0, min(0.5, textureAmount))

        // base width & jitter
        let estW = max(2, (width - CGFloat(bars - 1) * spacing) / CGFloat(bars))
        self.barBaseWidth = estW

        var g: [Double] = []
        var ws: [CGFloat] = []
        for i in 0..<bars {
            let r1 = Self.hash01(Double(i) * 13.37 + 7.91)
            let r2 = Self.hash01(Double(i) * 5.17  + 0.33)
            g.append(1.0 + self.ampJitter * (r1 * 2 - 1))                 // ~0.78..1.22
            ws.append(estW * (1.12 + self.widthJitter * CGFloat(r2 * 2 - 1))) // ✅ to cột thêm ~12%
        }
        self.gains = g
        self.widths = ws
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            // phase tăng tuyến tính → cuộn từ **phải sang trái**
            let t = timeline.date.timeIntervalSinceReferenceDate
            let phase = t * speed

            Canvas { ctx, size in
                let totalWidth = widths.reduce(0,+) + CGFloat(bars - 1) * spacing
                var x = (size.width - totalWidth) / 2
                let originY = (size.height - height) / 2
                let nMinus1 = max(1, bars - 1)
                let deltaH = peakHeight - baseHeight

                // ✅ stride cho 1 bar — chỉnh 0.085–0.1 để cụm 5–10 cột
                let barStride = 0.095

                for i in 0..<bars {
                    // index dùng cho bias đối xứng
                    let j = mirrorSymmetry ? min(i, bars - 1 - i) : i

                    // ✅ R→L: i càng lớn (ở bên phải) → thời điểm mới hơn
                    let tSample = phase + Double(i) * barStride

                    // ✅ năng lượng lấy **MAX** cụm → rơi thật sâu giữa các cụm
                    let (clusterVal, localPhase) = clusterFieldMax(tSample: tSample, barStride: barStride)

                    // ✅ “độ chênh cột” trong cùng 1 cụm (không đều nhau):
                    //    dùng comb theo index và pha cục bộ trong cụm
                    let comb = 0.82 + 0.18 * cos(Double(i) * 0.85 + localPhase * 5.6)

                    // texture nhẹ để organic, không phá cụm
                    let tex = textureAmount * (Self.fbm(tSample * 1.5, octaves: 3) - 0.5)

                    // bias giữa theo bề ngang view
                    let u = Double(j) / Double(nMinus1)
                    let d = abs(u - 0.5) * 2.0
                    let bias = 1.0 - centerEmphasis * (d * d)

                    // tổng cường độ 0..1
                    var v = max(0, min(1, clusterVal * comb + tex)) * bias * gains[j]
                    // mở dynamic + sàn
                    v = floorLevel + pow(max(0, min(1, v)), dynamics) * (1 - floorLevel)

                    // map height
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

    // MARK: - Cluster field (tạo “tiếng” ngắn/dài, trả về MAX và pha cục bộ)
    /// Trả về (năng lượng 0..1, localPhase [-π..π]) của cụm trội nhất tại thời điểm t
    private func clusterFieldMax(tSample t: Double, barStride: Double) -> (Double, Double) {
        // xem xét cụm trong cửa sổ ±2 khoảng
        let k0 = Int(floor((t - clusterSpacing * 2) / clusterSpacing))
        let k1 = Int(floor((t + clusterSpacing * 2) / clusterSpacing))

        var maxVal = 0.0
        var pickedPhase = 0.0

        for k in k0...k1 {
            let count = 1 + Int(Double(clustersPerInterval - 1) * Self.hash01(Double(k) * 2.123))

            for idx in 0..<count {
                let off = Self.hash01(Double(k * 31 + idx) * 1.137) * clusterSpacing * 0.92
                let chooseShort = Self.hash01(Double(k * 17 + idx) * 0.777) < shortProb

                let shortLerp = Self.lerp(
                    Double(shortBarsRange.lowerBound),
                    Double(shortBarsRange.upperBound),
                    Self.hash01(Double(k * 13 + idx) * 4.17)
                )
                let longLerp = Self.lerp(
                    Double(longBarsRange.lowerBound),
                    Double(longBarsRange.upperBound),
                    Self.hash01(Double(k * 19 + idx) * 3.11)
                )

                // số cột mong muốn cho cụm (5–7 / 8–12)
                let barCount = chooseShort
                    ? clamp(Int(lround(shortLerp)), shortBarsRange.lowerBound, shortBarsRange.upperBound)
                    : clamp(Int(lround(longLerp)),  longBarsRange.lowerBound,  longBarsRange.upperBound)

                // sigma theo số cột (đỉnh nhọn, rìa nhỏ)
                let sigma = max(1e-4, (Double(barCount) * barStride) / 2.355)

                // biên độ cụm (0.7..1.0) để đỉnh rõ
                let amp = 0.7 + 0.3 * Self.hash01(Double(k) * 8.88 + Double(idx) * 3.77)

                let center = Double(k) * clusterSpacing + off
                let dt = t - center

                // đóng góp của cụm này
                let g = amp * gauss(dt, sigma: sigma)

                if g > maxVal {
                    maxVal = g
                    // pha cục bộ trong cụm để làm “comb” lệch cột
                    pickedPhase = dt / sigma    // ~[-n..n]
                }
            }
        }
        // clamp 0..1
        return (min(1.0, maxVal), pickedPhase)
    }

    private func gauss(_ x: Double, sigma: Double) -> Double {
        let s2 = sigma * sigma * 2.0
        return exp(-(x * x) / max(1e-9, s2))
    }

    // MARK: - Noise utils
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

private extension ScrollingClusterWaveView4 {
    static func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }
}
