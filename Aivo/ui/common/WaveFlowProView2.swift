//
//  WaveFlowProView 2.swift
//  Aivo
//
//  Created by Huy on 24/10/25.
//


import SwiftUI

struct WaveFlowProView2: View {
    enum Flow { case left, right }

    // MARK: Public params
    let bars: Int
    let width: CGFloat
    let height: CGFloat

    /// Nhịp / tempo
    let bpm: Double                  // ví dụ 100–140 cho EDM/Pop
    let barsPerCycle: Int            // số ô nhịp (bar) trong 1 chu kỳ animation (1–2 là đẹp)
    let stepsPerBeat: Int            // 4 = 16-step/4 beat (classic)
    let swing: Double                // 0..0.3 (0.12 ~ 55% swing)

    /// Hình học cột
    let baseHeight: CGFloat
    let peakHeight: CGFloat
    let flow: Flow

    /// “Phong cách” hiển thị
    let centerEmphasis: Double       // 0..1 nhấn trung tâm
    let roughness: Double            // 0..0.3 gồ ghề tinh tế

    // Nội bộ
    private let framesPerCycle = 120
    private let lut: [[CGFloat]]
    private let barWidth: CGFloat
    private let spacing: CGFloat
    private let period: Double

    init(
        bars: Int,
        width: CGFloat,
        height: CGFloat,
        bpm: Double = 120,
        barsPerCycle: Int = 2,
        stepsPerBeat: Int = 4,
        swing: Double = 0.12,
        baseHeight: CGFloat,
        peakHeight: CGFloat,
        flow: Flow,
        centerEmphasis: Double = 0.35,
        roughness: Double = 0.15
    ) {
        self.bars = bars
        self.width = width
        self.height = height
        self.bpm = bpm
        self.barsPerCycle = max(1, barsPerCycle)
        self.stepsPerBeat = max(1, stepsPerBeat)
        self.swing = max(0, min(0.35, swing))
        self.baseHeight = baseHeight
        self.peakHeight = peakHeight
        self.flow = flow
        self.centerEmphasis = max(0, min(1, centerEmphasis))
        self.roughness = max(0, min(0.4, roughness))

        // 1 beat = 60/bpm (s). 1 bar = 4 beat.
        let beatsPerBar = 4.0
        let beatsPerCycle = beatsPerBar * Double(self.barsPerCycle)
        self.period = (60.0 / bpm) * beatsPerCycle   // chu kỳ animation khớp BPM

        // geometry
        let s: CGFloat = 3
        let w = max(2, (width - s * CGFloat(bars - 1)) / CGFloat(bars))
        self.barWidth = w
        self.spacing = s

        // precompute LUT theo nhịp
        self.lut = WaveFlowProView2.buildLUT(
            bars: bars,
            frames: framesPerCycle,
            baseHeight: baseHeight,
            peakHeight: peakHeight,
            flowRight: (flow == .right),
            centerEmphasis: self.centerEmphasis,
            roughness: self.roughness,
            // beat params
            barsPerCycle: self.barsPerCycle,
            stepsPerBeat: self.stepsPerBeat,
            swing: self.swing
        )
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let phase = (t.truncatingRemainder(dividingBy: period)) / period

            let f = phase * Double(framesPerCycle)
            let i0 = Int(f) % framesPerCycle
            let i1 = (i0 + 1) % framesPerCycle
            let frac = CGFloat(f - floor(f))

            Canvas { ctx, size in
                let totalWidth = CGFloat(bars) * barWidth + CGFloat(bars - 1) * spacing
                let originX = (size.width - totalWidth) / 2
                let originY = (size.height - height) / 2

                for i in 0..<bars {
                    let h0 = lut[i0][i]
                    let h1 = lut[i1][i]
                    let h = h0 + (h1 - h0) * frac
                    let x = originX + CGFloat(i) * (barWidth + spacing)
                    let y = originY + (height - h) / 2

                    let rect = CGRect(x: x, y: y, width: barWidth, height: h)
                    let path = Path(roundedRect: rect, cornerSize: CGSize(width: 2, height: 2))
                    ctx.fill(path, with: .color(.white))
                }
            }
            .frame(width: width, height: height)
        }
    }

    // MARK: - LUT builder (beat-driven)
    private static func buildLUT(
        bars: Int,
        frames: Int,
        baseHeight: CGFloat,
        peakHeight: CGFloat,
        flowRight: Bool,
        centerEmphasis: Double,
        roughness: Double,
        barsPerCycle: Int,
        stepsPerBeat: Int,
        swing: Double
    ) -> [[CGFloat]] {

        let minH = baseHeight
        let maxH = peakHeight
        let amp = max(0, maxH - minH)

        // nhấn mạnh trung tâm (parabolic)
        let centerBias: [Double] = (0..<bars).map { i in
            let u = Double(i) / Double(max(1, bars - 1))
            let d = abs(u - 0.5) * 2.0
            return (1.0 - centerEmphasis * (d * d))
        }

        // hướng flow
        let dir: Double = flowRight ? 1.0 : -1.0
        let phaseShiftPerBar = dir * 2.0 * .pi / Double(bars) * 0.8

        // ===== Beat grid =====
        let beatsPerBar = 4
        let totalBeats = beatsPerBar * barsPerCycle
        let totalSteps = totalBeats * stepsPerBeat    // ví dụ 2 bar * 4 * 4 = 32 steps

        // Pattern 16-step: Kick/Snare/Hat (0..1 cường độ). Bạn có thể chỉnh.
        // map vào totalSteps (kể cả khi không phải 16).
        func patternAt(step s: Int) -> Double {
            // pattern 16-step mẫu: K . . . | . S . . | K . . . | . S . .
            let pat16: [Double] = [
                1.0, 0.15, 0.2, 0.15,
                0.2, 0.85, 0.25, 0.2,
                0.9, 0.2, 0.2, 0.15,
                0.2, 0.8, 0.25, 0.2
            ]
            let idx = (s * 16) / max(1, totalSteps)    // scale về 16
            return pat16[idx.clamped(0, 15)]
        }

        // Swing: dời step lẻ đi một chút (0..0.3)
        func onset(ofStep s: Int) -> Double {
            let beatStep = 1.0 / Double(stepsPerBeat)      // khoảng cách step theo beat
            let base = Double(s) * (beatStep / Double(totalBeats)) // 0..1 trong chu kỳ
            let isOdd = (s % 2) == 1
            return base + (isOdd ? swing * (beatStep / Double(totalBeats)) : 0.0)
        }

        // ADSR mini cho mỗi hit: attack rất nhanh, decay ngắn → "nảy"
        @inline(__always)
        func adsrPulse(_ x: Double, attack: Double, decay: Double) -> Double {
            // x >= 0: attack nhanh rồi decay exp
            if x < 0 { return 0 }
            // attack shape (ease-out): 1 - e^{-x/a}
            let a = 1.0 - exp(-x / max(1e-4, attack))
            // decay: e^{-x/d}
            let d = exp(-x / max(1e-4, decay))
            return a * d
        }

        // Sóng cơ sở mịn (tạo chuyển động giữa các hit)
        @inline(__always)
        func baseWave(_ x: Double) -> Double {
            let w1 = sin(x * 2.0 * .pi)
            let w2 = 0.45 * sin(x * 4.0 * .pi + 0.6)
            let w3 = 0.25 * sin(x * 6.0 * .pi + 1.1)
            return (w1 + w2 + w3 + 1.0) * 0.5
        }

        // noise mượt, đổi chậm (deterministic)
        func slowNoise(_ i: Int, _ f: Int) -> Double {
            let k = f / 6
            let a = sin(Double(i) * 12.9898 + Double(k) * 78.233) * 43758.5453
            return a - floor(a) // 0..1
        }

        var table = Array(repeating: Array(repeating: minH, count: bars), count: frames)

        for f in 0..<frames {
            let x = Double(f) / Double(frames) // 0..1 trong 1 chu kỳ
            // vị trí theo beat (0..totalBeats)
            let beatPos = x * Double(totalBeats)

            // Tạo envelope nhịp: tổng các hit gần nhất (khoảng 2–3 hit trước)
            var envBeat = 0.0
            let stepFloat = beatPos * Double(stepsPerBeat)
            let stepIndex = Int(floor(stepFloat))
            for k in stride(from: 0, through: 3, by: 1) { // cộng 4 hit gần nhất
                let s = (stepIndex - k + totalSteps * 1000) % totalSteps
                let onset01 = onset(ofStep: s)             // onset trong 0..1
                var dt = x - onset01
                if dt < -0.5 { dt += 1 }                   // wrap qua chu kỳ
                if dt < 0.5 && dt >= 0 {
                    // attack 30–60ms, decay 120–200ms quy đổi theo chu kỳ
                    let att = 0.03
                    let dec = 0.14
                    let p = adsrPulse(dt, attack: att, decay: dec) * patternAt(step: s)
                    envBeat += p
                }
            }
            // chuẩn hóa nhẹ
            envBeat = min(1.0, envBeat * 1.2)

            // breathing nền để không bị “tắt” khi giữa các hit
            let breathing = 0.5 - 0.5 * cos(x * 2.0 * .pi)
            let baseEnv = 0.35 + 0.4 * breathing + 0.6 * envBeat

            for i in 0..<bars {
                // pha lệch theo cột để tạo flow
                let xi = x + Double(i) * (phaseShiftPerBar / (2.0 * .pi))

                // nền mịn + noise
                var v = baseWave(xi)
                if roughness > 0 {
                    let n = slowNoise(i, f) * 2.0 - 1.0
                    v = (v + roughness * 0.35 * n).clamped01()
                }

                // áp envelope và bias
                v *= baseEnv
                v *= centerBias[i]
                v = v.clamped01()

                table[f][i] = minH + CGFloat(v) * amp
            }
        }
        return table
    }
}

private extension Int {
    func clamped(_ lower: Int, _ upper: Int) -> Int {
        return Swift.max(lower, Swift.min(self, upper))
    }}
private extension Double {
    func clamped01() -> Double { max(0.0, min(1.0, self)) }
}
