//
//  BeatDrivenWaveView.swift
//  Aivo
//
//  Created by Huy on 24/10/25.
//


import SwiftUI

struct BeatDrivenWaveView: View {
    enum Flow { case left, right }

    // MARK: Public API
    let bars: Int
    let width: CGFloat
    let height: CGFloat

    let bpm: Double                 // 110–140 đẹp
    let swing: Double               // 0..0.25 (0.1–0.16 có groove)
    let mirrorSymmetry: Bool        // đối xứng trái-phải

    // shape
    let baseHeight: CGFloat         // chiều cao nền khi “im”
    let peakHeight: CGFloat         // chiều cao tối đa
    let flow: Flow
    let centerEmphasis: Double      // 0..1 nhấn trung tâm
    let ampJitter: Double           // 0..0.5 khác nhau per bar
    let widthJitter: CGFloat        // 0..0.4 khác nhau per bar

    // pattern 16-step (0..1) — có thể thay tuỳ style
    // K . . . | . S . . | K . . . | . S . .
    let pattern: [Double] = [
        1.00, 0.10, 0.18, 0.12,
        0.18, 0.90, 0.22, 0.16,
        0.95, 0.14, 0.18, 0.12,
        0.16, 0.88, 0.22, 0.16
    ]

    // MARK: internals
    private let barBaseWidth: CGFloat
    private let spacing: CGFloat = 3
    private let gains: [Double]
    private let widths: [CGFloat]
    private let period: Double      // 1 measure (4 beat)
    private let stepCount = 16      // 16-step / measure
    private let stepsPerBeat = 4

    init(
        bars: Int,
        width: CGFloat,
        height: CGFloat,
        bpm: Double = 128,
        swing: Double = 0.12,
        mirrorSymmetry: Bool = true,
        baseHeight: CGFloat = 8,
        peakHeight: CGFloat = 110,
        flow: Flow = .right,
        centerEmphasis: Double = 0.45,
        ampJitter: Double = 0.25,
        widthJitter: CGFloat = 0.2
    ) {
        self.bars = bars
        self.width = width
        self.height = height
        self.bpm = bpm
        self.swing = max(0, min(0.3, swing))
        self.mirrorSymmetry = mirrorSymmetry
        self.baseHeight = baseHeight
        self.peakHeight = peakHeight
        self.flow = flow
        self.centerEmphasis = max(0, min(1, centerEmphasis))
        self.ampJitter = max(0, min(0.6, ampJitter))
        self.widthJitter = max(0, min(0.6, widthJitter))

        // 1 measure (4 beat)
        self.period = (60.0 / bpm) * 4.0

        // base width và jitter
        let estW = max(2, (width - CGFloat(bars - 1) * spacing) / CGFloat(bars))
        self.barBaseWidth = estW

        var g: [Double] = []
        var ws: [CGFloat] = []
        for i in 0..<bars {
            let r1 = Self.hash01(Double(i) * 13.37 + 7.91)
            let r2 = Self.hash01(Double(i) * 5.17  + 3.33)
            g.append(1.0 + ampJitter * (r1 * 2 - 1))                // ~0.75..1.25
            ws.append(estW * (1.0 + widthJitter * CGFloat(r2 * 2 - 1)))
        }
        self.gains = g
        self.widths = ws
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate
            let phase = (now.truncatingRemainder(dividingBy: period)) / period // 0..1 measure

            Canvas { ctx, size in
                // tổng width để căn giữa
                let totalWidth: CGFloat = widths.reduce(0, +) + CGFloat(bars - 1) * spacing
                var x: CGFloat = (size.width - totalWidth) / 2
                let originY: CGFloat = (size.height - height) / 2
                let dir: Double = (flow == .right) ? 1.0 : -1.0
                let barCountMinus1 = max(1, bars - 1)

                for i in 0..<bars {
                    // --- chỉ số dùng cho đối xứng
                    let j: Int = mirrorSymmetry ? min(i, bars - 1 - i) : i

                    // --- bias theo tâm
                    let bias: Double = {
                        let u = Double(i) / Double(barCountMinus1)
                        let d = abs(u - 0.5) * 2.0
                        return 1.0 - centerEmphasis * (d * d)
                    }()

                    // --- envelope theo beat (chỉ nở ở nhịp)
                    let env: Double = beatEnvelope(phase: phase, swing: swing)

                    // --- độ “lan” quanh tâm (gaussian) để tạo shape giống audio
                    let u: Double = Double(j) / Double(barCountMinus1)
                    let spreadCore: Double = exp(-pow(u - 0.5, 2.0) / (2.0 * 0.17 * 0.17))
                    let spread: Double = spreadCore * 0.9 + 0.1

                    // --- LFO chậm + flow lệch pha nhẹ giữa các bar
                    let flowShift: Double = dir * Double(j) * 0.015
                    let lfo: Double = 0.07 * sin(2.0 * .pi * (phase + flowShift) * 3.0 + Double(j) * 0.23)

                    // --- tổng cường độ 0..1 (tách từng bước cho dễ type-check)
                    var v: Double = env * spread
                    v += lfo
                    if v < 0 { v = 0 }
                    if v > 1 { v = 1 }
                    v *= bias
                    v *= gains[j]

                    // --- map chiều cao (rõ kiểu CGFloat)
                    let deltaH: CGFloat = peakHeight - baseHeight
                    let h: CGFloat = baseHeight + CGFloat(v) * deltaH

                    // --- kích thước/position
                    let bw: CGFloat = widths[i]
                    let y: CGFloat = originY + (height - h) / 2.0

                    // --- vẽ bar
                    let rect = CGRect(x: x, y: y, width: bw, height: h)
                    let path = Path(roundedRect: rect, cornerSize: CGSize(width: 2, height: 2))
                    ctx.fill(path, with: .color(.white))

                    x += bw + spacing
                }
            }
            .frame(width: width, height: height)
        }
    }

    // MARK: - Beat envelope (ADSR trên grid 16-step)
    /// Chỉ tạo năng lượng khi tới hit; giữa các step hầu như xẹp.
    private func beatEnvelope(phase: Double, swing: Double) -> Double {
        // phase 0..1 → step 0..15
        let stepPos = phase * Double(stepCount)
        let baseStep = Int(floor(stepPos))
        let local = stepPos - floor(stepPos)

        // swing: step lẻ vào muộn hơn 1 chút
        let isOdd = (baseStep % 2) == 1
        let swingShift = isOdd ? swing / Double(stepCount) : 0
        var t = local - swingShift
        if t < 0 { t += 1 } // wrap

        // velocity (random nhẹ mỗi vòng để giống nhạc thật)
        let veloBase = pattern[baseStep]
        let jitter = (Self.hash01(floor(phase * 64) + Double(baseStep)) * 0.2 - 0.1)
        let velocity = max(0, min(1, veloBase + jitter))

        // ADSR cực ngắn → “nảy”
        let attack = 0.06
        let decay  = 0.22
        let env = adsrPulse(t, attack: attack, decay: decay) * velocity

        // cộng “đuôi” từ step trước để không gãy khúc
        let prevStep = (baseStep - 1 + stepCount) % stepCount
        let prevVelo = pattern[prevStep]
        let prevJit  = (Self.hash01(floor(phase * 64) + Double(prevStep)) * 0.2 - 0.1)
        let prevVel  = max(0, min(1, prevVelo + prevJit))
        let prevEnv  = adsrPulse(t + 1.0, attack: attack, decay: decay) * prevVel // t+1: lùi về step trước

        return min(1.0, env + prevEnv * 0.6)
    }

    // ADSR: attack nhanh, decay ngắn
    private func adsrPulse(_ x: Double, attack: Double, decay: Double) -> Double {
        guard x >= 0 && x < 1 else { return 0 }
        let a = 1.0 - exp(-x / max(attack, 1e-4))
        let d = exp(-x / max(decay, 1e-4))
        return a * d
    }

    private func centerBias(_ i: Int, _ n: Int, k: Double) -> Double {
        let u = Double(i) / Double(max(1, n - 1))
        let d = abs(u - 0.5) * 2.0
        return 1.0 - k * (d * d)
    }

    private func gaussian(_ u: Double, center c: Double, sigma s: Double) -> Double {
        let d = u - c
        return exp(-(d*d) / (2*s*s))
    }

    // deterministic 0..1
    private static func hash01(_ x: Double) -> Double {
        let s = sin(x * 12.9898) * 43758.5453
        return s - floor(s)
    }
}
