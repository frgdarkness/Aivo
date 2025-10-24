//
//  WaveFlowProView 2.swift
//  Aivo
//
//  Created by Huy on 24/10/25.
//


import SwiftUI

struct WaveFlowProView3: View {
    enum Flow { case left, right }

    // MARK: - Public params
    let bars: Int
    let width: CGFloat
    let height: CGFloat

    // tempo / nhịp
    let bpm: Double                 // 110–140 đẹp
    let barsPerCycle: Int           // 1–2
    let stepsPerBeat: Int           // 4 = 16-step
    let swing: Double               // 0..0.25 (0.1–0.16 có groove)

    // hình học & style
    let baseHeight: CGFloat
    let peakHeight: CGFloat
    let flow: Flow
    let mirrorSymmetry: Bool        // đối xứng trung tâm như ảnh mẫu
    let centerEmphasis: Double      // 0..1 (0.3–0.6)
    let roughness: Double           // 0..0.3 noise mượt
    let ampJitter: Double           // 0..0.5 biên độ khác nhau theo bar
    let phaseJitter: Double         // 0..π pha lệch per-bar
    let widthJitter: CGFloat        // 0..0.4 độ rộng bar khác nhau
    let groupiness: Double          // 0..1 tạo “cụm” bar phồng/xẹp chậm

    // Nội bộ
    private let framesPerCycle = 120
    private let period: Double
    private let barBaseWidth: CGFloat
    private let spacing: CGFloat = 3
    // seeds cố định → deterministic
    private let gain: [Double]
    private let phi: [Double]
    private let wFactor: [CGFloat]

    init(
        bars: Int,
        width: CGFloat,
        height: CGFloat,
        bpm: Double = 126,
        barsPerCycle: Int = 2,
        stepsPerBeat: Int = 4,
        swing: Double = 0.12,
        baseHeight: CGFloat,
        peakHeight: CGFloat,
        flow: Flow = .right,
        mirrorSymmetry: Bool = true,
        centerEmphasis: Double = 0.4,
        roughness: Double = 0.12,
        ampJitter: Double = 0.25,
        phaseJitter: Double = 0.6,
        widthJitter: CGFloat = 0.22,
        groupiness: Double = 0.6
    ) {
        self.bars = bars
        self.width = width
        self.height = height
        self.bpm = bpm
        self.barsPerCycle = max(1, barsPerCycle)
        self.stepsPerBeat = max(1, stepsPerBeat)
        self.swing = max(0, min(0.3, swing))
        self.baseHeight = baseHeight
        self.peakHeight = peakHeight
        self.flow = flow
        self.mirrorSymmetry = mirrorSymmetry
        self.centerEmphasis = max(0, min(1, centerEmphasis))
        self.roughness = max(0, min(0.4, roughness))
        self.ampJitter = max(0, min(0.6, ampJitter))
        self.phaseJitter = max(0, min(.pi, phaseJitter))
        self.widthJitter = max(0, min(0.6, widthJitter))
        self.groupiness = max(0, min(1, groupiness))

        // 1 beat = 60/bpm (s). 1 bar = 4 beat.
        let beatsPerBar = 4.0
        let beatsPerCycle = beatsPerBar * Double(self.barsPerCycle)
        self.period = (60.0 / bpm) * beatsPerCycle

        // base width (sau sẽ nhân wFactor per-bar)
        let estW = max(2, (width - spacing * CGFloat(bars - 1)) / CGFloat(bars))
        self.barBaseWidth = estW

        // seed deterministic
        var g: [Double] = []
        var p: [Double] = []
        var wf: [CGFloat] = []
        for i in 0..<bars {
            let r1 = Self.hash01(Double(i) * 13.37 + 7.91)
            let r2 = Self.hash01(Double(i) * 2.71 + 0.33)
            let r3 = Self.hash01(Double(i) * 5.19 + 9.99)
            g.append(1.0 + ampJitter * (r1 * 2 - 1))                           // ~0.75..1.25
            p.append((r2 * 2 - 1) * Double(self.phaseJitter))                   // -phaseJitter..+phaseJitter
            wf.append(1.0 + widthJitter * CGFloat(r3 * 2 - 1))                  // width jitter
        }
        self.gain = g
        self.phi = p
        self.wFactor = wf
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let phase = (t.truncatingRemainder(dividingBy: period)) / period
            let flowDir: Double = (flow == .right) ? 1 : -1

            Canvas { ctx, size in
                // tính tổng width thật với jitter để căn giữa
                let widths: [CGFloat] = (0..<bars).map { barBaseWidth * wFactor[$0] }
                let totalWidth = widths.reduce(0, +) + CGFloat(bars - 1) * spacing
                var x = (size.width - totalWidth) / 2
                let originY = (size.height - height) / 2

                for i in 0..<bars {
                    // mirror: dùng param chung cho 2 phía để được hình “đối xứng”
                    let j = mirrorSymmetry ? min(i, bars - 1 - i) : i

                    let centerBias = biasTowardCenter(i: i, n: bars, k: centerEmphasis)

                    // beat envelope (attack nhanh + decay ngắn theo grid)
                    let env = beatEnvelope(phase: phase,
                                           stepsPerBeat: stepsPerBeat,
                                           barsPerCycle: barsPerCycle,
                                           swing: swing)

                    // lfo chậm theo nhóm để “phồng/xẹp” từng cụm bar
                    let cluster = groupiness * groupedLFO(phase: phase, index: j)

                    // base wave mịn + pha lệch per-bar + flow theo cột
                    let base = baseWave(phase
                                        + Double(j) * 0.8 / Double(bars) * flowDir
                                        + phi[j] / (2 * .pi))

                    // noise mượt rất nhẹ đổi chậm theo thời gian
                    let n = (roughness > 0 ? (roughness * (WaveFlowProView3.hash01(Double(j) * 11.1 + floor(phase * 60)) * 2 - 1)) : 0)

                    // tổng hợp giá trị 0..1
                    var v = (0.55 * base + 0.25 * cluster + 0.2 * env + n)
                    v = max(0, min(1, v))
                    v *= centerBias
                    v *= gain[j]

                    // map chiều cao
                    let h = baseHeight + CGFloat(v) * (peakHeight - baseHeight)

                    let bw = barBaseWidth * wFactor[i]
                    let y = originY + (height - h) / 2

                    let rect = CGRect(x: x, y: y, width: bw, height: h)
                    let path = Path(roundedRect: rect, cornerSize: CGSize(width: 2, height: 2))
                    ctx.fill(path, with: .color(.white))

                    x += bw + spacing
                }
            }
            .frame(width: width, height: height)
        }
    }

    // === Building blocks ===

    private func biasTowardCenter(i: Int, n: Int, k: Double) -> Double {
        let u = Double(i) / Double(max(1, n - 1))
        let d = abs(u - 0.5) * 2.0
        return 1.0 - k * (d * d)                  // parabolic
    }

    private func baseWave(_ x: Double) -> Double {
        // nhiều harmonic cho cảm giác “thật”
        let w1 = sin(2 * .pi * x)
        let w2 = 0.45 * sin(4 * .pi * x + 0.6)
        let w3 = 0.25 * sin(6 * .pi * x + 1.1)
        return (w1 + w2 + w3 + 1) * 0.5          // 0..1
    }

    /// ADSR per beat grid → “nảy” theo nhịp
    private func beatEnvelope(phase: Double, stepsPerBeat: Int, barsPerCycle: Int, swing: Double) -> Double {
        let totalBeats = 4 * barsPerCycle
        let totalSteps = totalBeats * stepsPerBeat
        let stepFloat = phase * Double(totalSteps)
        let iStep = Int(floor(stepFloat))
        var energy = 0.0

        // cộng 3 hit gần nhất
        for k in 0..<3 {
            let s = (iStep - k + totalSteps) % totalSteps
            let onset = onsetOf(step: s, totalSteps: totalSteps, stepsPerBeat: stepsPerBeat, swing: swing)
            var dt = phase - onset
            if dt < -0.5 { dt += 1 }    // wrap
            if dt >= 0 && dt < 0.5 {
                // attack & decay nhanh (đơn vị là phần của chu kỳ)
                let att = 0.03
                let dec = 0.14
                let a = 1 - exp(-dt / max(1e-4, att))
                let d = exp(-dt / max(1e-4, dec))
                let pat = pattern16Mapped(step: s, totalSteps: totalSteps) // 0..1
                energy += a * d * pat
            }
        }
        return min(1, energy * 1.1)
    }

    private func onsetOf(step s: Int, totalSteps: Int, stepsPerBeat: Int, swing: Double) -> Double {
        let base = Double(s) / Double(totalSteps)
        // swing cho step lẻ
        let isOdd = (s % 2) == 1
        let stepSize = 1.0 / Double(totalSteps)
        return base + (isOdd ? swing * stepSize : 0)
    }

    /// nhóm bar phồng/xẹp chậm → “cụm” sống động
    private func groupedLFO(phase: Double, index: Int) -> Double {
        // 3 gaussian centers di chuyển chậm
        let c1 = 0.25 + 0.10 * sin(2 * .pi * (phase * 0.5))
        let c2 = 0.55 + 0.08 * sin(2 * .pi * (phase * 0.4 + 0.3))
        let c3 = 0.80 + 0.06 * sin(2 * .pi * (phase * 0.37 + 0.7))
        let u = Double(index) / Double(max(1, bars - 1))
        func g(_ c: Double, _ s: Double) -> Double {
            let d = (u - c)
            return exp(-(d * d) / (2 * s * s))
        }
        // trọng số tổng hợp
        return (g(c1, 0.09) + g(c2, 0.07) + g(c3, 0.05)) / 3.0
    }

    // Pattern 16-step: K . . . | . S . . | K . . . | . S . .
    private func pattern16Mapped(step s: Int, totalSteps: Int) -> Double {
        let pat16: [Double] = [
            1.0, 0.15, 0.2, 0.15,
            0.2, 0.85, 0.25, 0.2,
            0.9, 0.2, 0.2, 0.15,
            0.2, 0.8, 0.25, 0.2
        ]
        let idx = (s * 16) / max(1, totalSteps)
        return pat16[idx.clamped(0, 15)]
    }

    // hash 0..1 deterministic
    private static func hash01(_ x: Double) -> Double {
        let s = sin(x * 12.9898) * 43758.5453
        return s - floor(s)
    }
}

// helpers
private extension Int {
    func clamped(_ lower: Int, _ upper: Int) -> Int {
        Swift.max(lower, Swift.min(self, upper))
    }
}
