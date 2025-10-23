//
//  WaveFlowView.swift
//  Aivo
//
//  Created by Huy on 23/10/25.
//


import SwiftUI

/// Vẽ dải sóng nhạc “flow” mượt, lặp lại theo chu kỳ. Dùng Canvas + LUT để giảm CPU.
struct WaveFlowView: View {
    let bars: Int
    let width: CGFloat
    let height: CGFloat
    let period: Double          // giây cho 1 chu kỳ (ví dụ 4.5s)
    let baseHeight: CGFloat
    let peakHeight: CGFloat

    // số keyframe trong 1 chu kỳ (fps 40 cho 4.5s ≈ 180 mẫu là đủ mượt)
    private let framesPerCycle = 180

    // LUT: [frameIndex][bar] => height
    private let lut: [[CGFloat]]
    private let barWidth: CGFloat
    private let spacing: CGFloat

    init(bars: Int, width: CGFloat, height: CGFloat, period: Double, baseHeight: CGFloat, peakHeight: CGFloat) {
        self.bars = bars
        self.width = width
        self.height = height
        self.period = period
        self.baseHeight = baseHeight
        self.peakHeight = peakHeight

        // tính chiều rộng cột + spacing hợp lý
        let s: CGFloat = 3   // spacing giữa các bar
        let w = max(2, (width - s * CGFloat(bars - 1)) / CGFloat(bars))
        self.barWidth = w
        self.spacing = s

        // Precompute LUT 1 lần trong init
        self.lut = WaveFlowView.buildLUT(
            bars: bars,
            frames: framesPerCycle,
            baseHeight: baseHeight,
            peakHeight: peakHeight
        )
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            // where am I in the cycle?
            let t = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period)
            let progress = t / period
            let idx = min(lut.count - 1, Int(progress * Double(framesPerCycle)))

            Canvas { context, size in
                // center horizontally inside given width, vertically center within `height`
                let totalWidth = CGFloat(bars) * barWidth + CGFloat(bars - 1) * spacing
                let originX = (size.width - totalWidth) / 2
                let originY = (size.height - height) / 2

                for i in 0..<bars {
                    let h = min(height, lut[idx][i]) // height per bar from LUT
                    let x = originX + CGFloat(i) * (barWidth + spacing)
                    let y = originY + (height - h) / 2  // vertically centered within the band

                    var rect = Path(roundedRect: CGRect(x: x, y: y, width: barWidth, height: h), cornerSize: CGSize(width: 2, height: 2))
                    context.fill(rect, with: .color(.white))
                }
            }
            .frame(width: width, height: height)
        }
    }

    /// Tạo LUT mượt, có “flow” trái → phải + nhịp “thở” theo chu kỳ.
    private static func buildLUT(bars: Int, frames: Int, baseHeight: CGFloat, peakHeight: CGFloat) -> [[CGFloat]] {
        let minH = baseHeight
        let maxH = peakHeight
        let amp = max(0, maxH - minH)

        // Pha lệch giữa các bar để tạo cảm giác dòng chảy sang phải
        let phaseShiftPerBar = Double.pi * 2.0 / Double(bars) * 0.75

        // Tạo “envelope” chậm (0..1..0) cho cả dải → cảm giác phồng xẹp theo chu kỳ
        func envelope(_ x: Double) -> Double {
            // cosine bell: 0 → 1 → 0 trong 1 chu kỳ
            return 0.5 - 0.5 * cos(x * 2.0 * .pi)
        }

        // Sóng cơ sở (nhẹ nhàng) + harmonic phụ để có chi tiết, nhưng vẫn deterministic
        func baseWave(_ x: Double) -> Double {
            let w1 = sin(x * 2.0 * .pi)                          // fundamental
            let w2 = 0.4 * sin(x * 4.0 * .pi + 0.6)              // 2nd harmonic lệch pha
            let w3 = 0.25 * sin(x * 6.0 * .pi + 1.3)             // 3rd harmonic
            // normalize về 0..1
            return (w1 + w2 + w3 + 1.0) * 0.5
        }

        // Nhẹ nhàng “dị dạng” theo index cột để không đều tăm tắp
        let barBias: [Double] = (0..<bars).map { i in
            let u = Double(i) / Double(max(1, bars-1))
            return 0.85 + 0.3 * sin(u * 2.0 * .pi + 0.9)  // 0.55..1.15
        }

        var table = Array(repeating: Array(repeating: minH, count: bars), count: frames)

        for f in 0..<frames {
            let x = Double(f) / Double(frames) // 0..1
            let env = envelope(x)              // 0..1..0
            for i in 0..<bars {
                // tiến trình riêng cho mỗi bar có lệch pha theo i → cảm giác “chảy”
                let xi = x + Double(i) * phaseShiftPerBar / (2.0 * .pi)
                var v = baseWave(xi).clamped01()
                // áp envelope global
                v = (0.35 + 0.65 * env) * v
                // lệch theo bias của bar
                v *= barBias[i]
                // clamp lại
                v = v.clamped01()
                // map sang chiều cao
                table[f][i] = minH + CGFloat(v) * amp
            }
        }
        return table
    }
}

private extension Double {
    func clamped01() -> Double { max(0.0, min(1.0, self)) }
}
