//
//  WaveFlowProView.swift
//  Aivo
//
//  Created by Huy on 23/10/25.
//


import SwiftUI

struct WaveFlowProView: View {
    enum Flow { case left, right }

    let bars: Int
    let width: CGFloat
    let height: CGFloat
    let period: Double
    let baseHeight: CGFloat
    let peakHeight: CGFloat
    let flow: Flow
    let pulsePerCycle: Int        // số nhịp/chu kỳ (1–3 đẹp)
    let centerEmphasis: Double    // 0..1 nhấn trung tâm (0.3–0.5)
    let roughness: Double         // 0..0.3 “gồ ghề” tinh tế

    // Số keyframe/cycle: 120 là đủ mượt; có nội suy nên CPU hầu như không đổi
    private let framesPerCycle = 120

    private let lut: [[CGFloat]]
    private let barWidth: CGFloat
    private let spacing: CGFloat

    init(
        bars: Int,
        width: CGFloat,
        height: CGFloat,
        period: Double,
        baseHeight: CGFloat,
        peakHeight: CGFloat,
        flow: Flow,
        pulsePerCycle: Int,
        centerEmphasis: Double,
        roughness: Double
    ) {
        self.bars = bars
        self.width = width
        self.height = height
        self.period = period
        self.baseHeight = baseHeight
        self.peakHeight = peakHeight
        self.flow = flow
        self.pulsePerCycle = max(1, pulsePerCycle)
        self.centerEmphasis = max(0, min(1, centerEmphasis))
        self.roughness = max(0, min(0.4, roughness))

        // geometry
        let s: CGFloat = 3
        let w = max(2, (width - s * CGFloat(bars - 1)) / CGFloat(bars))
        self.barWidth = w
        self.spacing = s

        // precompute
        self.lut = WaveFlowProView.buildLUT(
            bars: bars,
            frames: framesPerCycle,
            baseHeight: baseHeight,
            peakHeight: peakHeight,
            flowRight: (flow == .right),
            pulsePerCycle: self.pulsePerCycle,
            centerEmphasis: self.centerEmphasis,
            roughness: self.roughness
        )
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            // vị trí trong chu kỳ (0..1)
            let t = timeline.date.timeIntervalSinceReferenceDate
            let phase = (t.truncatingRemainder(dividingBy: period)) / period

            // nội suy giữa 2 frame trong LUT để mượt
            let f = phase * Double(framesPerCycle)
            let i0 = Int(f) % framesPerCycle
            let i1 = (i0 + 1) % framesPerCycle
            let frac = CGFloat(f - floor(f))

            Canvas { ctx, size in
                let totalWidth = CGFloat(bars) * barWidth + CGFloat(bars - 1) * spacing
                let originX = (size.width - totalWidth) / 2
                let originY = (size.height - height) / 2

                // vẽ bar
                for i in 0..<bars {
                    let h0 = lut[i0][i]
                    let h1 = lut[i1][i]
                    let h = h0 + (h1 - h0) * frac  // linear interpolation
                    let x = originX + CGFloat(i) * (barWidth + spacing)
                    let y = originY + (height - h) / 2

                    let rounded = CGRect(x: x, y: y, width: barWidth, height: h)
                    let path = Path(roundedRect: rounded, cornerSize: CGSize(width: 2, height: 2))
                    ctx.fill(path, with: .color(.white))
                }
            }
            .frame(width: width, height: height)
        }
    }

    // MARK: - LUT builder
    private static func buildLUT(
        bars: Int,
        frames: Int,
        baseHeight: CGFloat,
        peakHeight: CGFloat,
        flowRight: Bool,
        pulsePerCycle: Int,
        centerEmphasis: Double,
        roughness: Double
    ) -> [[CGFloat]] {

        let minH = baseHeight
        let maxH = peakHeight
        let amp = max(0, maxH - minH)

        // nhấn mạnh trung tâm theo curve parabolic (smile curve)
        let centerBias: [Double] = (0..<bars).map { i in
            let u = Double(i) / Double(max(1, bars - 1))           // 0..1
            let d = abs(u - 0.5) * 2.0                             // 0 giữa → 1 ở rìa
            let bias = 1.0 - centerEmphasis * (d * d)              // parabolic toward center
            return bias                                             // ~0.65..1.0 tùy centerEmphasis
        }

        // pha lệch trên trục bar tạo flow
        let dir: Double = flowRight ? 1.0 : -1.0
        let phaseShiftPerBar = dir * 2.0 * .pi / Double(bars) * 0.8

        // pulse nhịp để nhìn “có nhạc”
        // dùng sin^2 để luôn dương, sắc nét hơn sin trơn
        func pulse(_ x: Double) -> Double {
            let w = sin(x * 2.0 * .pi * Double(pulsePerCycle))
            return w * w // 0..1
        }

        // sóng cơ sở + harmonic tinh tế (deterministic)
        func baseWave(_ x: Double) -> Double {
            // gọn, không nặng CPU: 3 harmonic
            let w1 = sin(x * 2.0 * .pi)
            let w2 = 0.45 * sin(x * 4.0 * .pi + 0.6)
            let w3 = 0.25 * sin(x * 6.0 * .pi + 1.1)
            // normalize về 0..1
            return (w1 + w2 + w3 + 1.0) * 0.5
        }

        // hash noise mượt (deterministic theo bar, không random mỗi frame)
        func hashNoise(_ i: Int, _ k: Int) -> Double {
            // noise nhẹ nhàng 0..1, thay đổi rất chậm theo frame
            let a = sin(Double(i) * 12.9898 + Double(k) * 78.233) * 43758.5453
            return (a - floor(a)) // frac
        }

        var table = Array(repeating: Array(repeating: minH, count: bars), count: frames)

        for f in 0..<frames {
            let x = Double(f) / Double(frames) // 0..1 over cycle

            // envelope tổng thể: mix pulse + breathing
            // breathing chậm, pulse cho nhịp nổi bật
            let breathing = 0.5 - 0.5 * cos(x * 2.0 * .pi)        // 0..1..0
            let env = (0.55 + 0.45 * breathing) * (0.75 + 0.25 * pulse(x))

            for i in 0..<bars {
                // pha theo bar để tạo flow
                let xi = x + Double(i) * phaseShiftPerBar / (2.0 * .pi)

                // giá trị cơ sở
                var v = baseWave(xi)

                // roughness rất nhẹ: thêm noise “thật” nhưng deterministic
                if roughness > 0 {
                    // noise thay đổi cực chậm theo frame, không nhấp nháy
                    let slowK = f / 6     // đổi noise mỗi ~6 frame
                    let n = hashNoise(i, slowK) * 2.0 - 1.0        // -1..1
                    v = (v + roughness * 0.35 * n).clamped01()
                }

                // áp envelope tổng và center bias
                v *= env
                v *= centerBias[i]
                v = v.clamped01()

                // map ra chiều cao
                table[f][i] = minH + CGFloat(v) * amp
            }
        }
        return table
    }
}

private extension Double {
    func clamped01() -> Double { max(0.0, min(1.0, self)) }
}
