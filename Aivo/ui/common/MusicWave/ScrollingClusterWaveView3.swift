//
//  ScrollingClusterWaveView 2.swift
//  Aivo
//
//  Created by Huy on 24/10/25.
//


import SwiftUI
import Foundation

struct ScrollingClusterWaveView3: View {
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
    let centerEmphasis: Double      // 0..1 (nhấn vùng giữa theo trục ngang view)
    let ampJitter: Double           // 0..0.5
    let widthJitter: CGFloat        // 0..0.4

    // micro-texture (nhưng không phá cụm)
    let textureAmount: Double       // 0..0.4
    let floorLevel: Double          // 0..0.08 nền rất thấp ở “quãng nghỉ”
    let dynamics: Double            // <1 mở dynamic (0.6–0.8 đẹp)

    // MARK: - “phrase” 3 cụm (như ảnh mẫu)
    /// vị trí tâm mỗi cụm trong chu kỳ (0..1)
    let phraseCenters: [Double]     // mặc định ~ [trái, giữa, phải]
    /// biên độ tương đối mỗi cụm (giữa lớn nhất)
    let phraseAmps: [Double]
    /// độ rộng (sigma) mỗi cụm
    let phraseWidths: [Double]

    // MARK: internals
    private let spacing: CGFloat = 3
    private let barBaseWidth: CGFloat
    private let gains: [Double]
    private let widths: [CGFloat]

    init(
        bars: Int = 52,
        width: CGFloat,
        height: CGFloat,
        speed: Double = 1.05,
        baseHeight: CGFloat = 6,
        peakHeight: CGFloat = 122,
        color: Color = .white,
        mirrorSymmetry: Bool = true,
        centerEmphasis: Double = 0.55,
        ampJitter: Double = 0.2,
        widthJitter: CGFloat = 0.16,
        textureAmount: Double = 0.12,
        floorLevel: Double = 0.02,
        dynamics: Double = 0.66,
        // 3 cụm như hình: trái (thấp hơn, hơi rộng), giữa (cao nhất, rộng), phải (trung bình)
        phraseCenters: [Double] = [0.23, 0.50, 0.78],
        phraseAmps:    [Double] = [0.75, 1.00, 0.82],
        // sigma càng nhỏ cụm càng “nhọn”; 0.045..0.085 hợp lý
        phraseWidths:  [Double] = [0.058, 0.080, 0.062]
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
        self.textureAmount = max(0, min(0.5, textureAmount))
        self.floorLevel = max(0, min(0.1, floorLevel))
        self.dynamics = dynamics

        // phrase params
        self.phraseCenters = phraseCenters
        self.phraseAmps = phraseAmps
        self.phraseWidths = phraseWidths

        // geometry per bar
        let estW = max(2, (width - CGFloat(bars - 1) * spacing) / CGFloat(bars))
        self.barBaseWidth = estW

        var g: [Double] = []
        var ws: [CGFloat] = []
        for i in 0..<bars {
            let r1 = Self.hash01(Double(i) * 13.37 + 7.91)
            let r2 = Self.hash01(Double(i) * 5.17  + 0.33)
            g.append(1.0 + self.ampJitter * (r1 * 2 - 1))                 // ~0.8..1.2
            ws.append(estW * (1.0 + self.widthJitter * CGFloat(r2 * 2 - 1)))
        }
        self.gains = g
        self.widths = ws
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let phase = t * speed  // tăng tuyến tính theo thời gian

            Canvas { ctx, size in
                let totalWidth = widths.reduce(0,+) + CGFloat(bars - 1) * spacing
                var x = (size.width - totalWidth) / 2
                let originY = (size.height - height) / 2
                let nMinus1 = max(1, bars - 1)
                let deltaH = peakHeight - baseHeight

                // mỗi bar lệch một lượng “thời gian” — cuộn **R→L**
                let barStride = 0.08

                for i in 0..<bars {
                    // index để bias đối xứng (đẹp như hình minh họa)
                    let j = mirrorSymmetry ? min(i, bars - 1 - i) : i

                    // vị trí thời gian của bar i (R→L)
                    let tSample = phase + Double(i) * barStride

                    // 1 chu kỳ phrase: lấy phần thập phân 0..1
                    let u = tSample - floor(tSample)

                    // năng lượng cụm: lấy **MAX** của 3 gaussian → rơi xuống gần 0 giữa các cụm
                    var env = 0.0
                    for k in 0..<min(phraseCenters.count, min(phraseAmps.count, phraseWidths.count)) {
                        let c = phraseCenters[k]
                        let a = phraseAmps[k]
                        let s = max(0.005, phraseWidths[k])
                        // khoảng cách tuần hoàn trên trục 0..1 (wrap)
                        let d = wrapDistance(u, c)
                        env = max(env, a * gauss(d, sigma: s))
                    }

                    // thêm comb micro-texture theo i (nhịp dày thưa xen kẽ)
                    let comb = 0.85 + 0.15 * cos(Double(i) * 0.9)
                    // texture noise nhẹ theo thời gian để organic
                    let tex = textureAmount * (Self.fbm(tSample * 1.4, octaves: 3) - 0.5)

                    // bias theo bề ngang (nhấn giữa hình)
                    let ux = Double(j) / Double(nMinus1)
                    let dx = abs(ux - 0.5) * 2.0
                    let spaceBias = 1.0 - centerEmphasis * (dx * dx)

                    // cường độ 0..1
                    var v = max(0, min(1, env * comb + tex)) * spaceBias * gains[j]
                    // mở dynamic + floor
                    v = floorLevel + pow(max(0, min(1, v)), dynamics) * (1 - floorLevel)

                    // chiều cao
                    let h = baseHeight + CGFloat(v) * deltaH
                    let bw = widths[i]
                    let y = originY + (height - h) / 2

                    // vẽ
                    let rect = CGRect(x: x, y: y, width: bw, height: h)
                    let path = Path(roundedRect: rect, cornerSize: CGSize(width: 2, height: 2))
                    ctx.fill(path, with: .color(color))

                    x += bw + spacing
                }
            }
            .frame(width: width, height: height)
        }
    }

    // MARK: - Math helpers
    /// khoảng cách tuần hoàn trên trục [0,1)
    private func wrapDistance(_ a: Double, _ b: Double) -> Double {
        var d = abs(a - b)
        if d > 0.5 { d = 1.0 - d }
        return d
    }

    private func gauss(_ x: Double, sigma: Double) -> Double {
        let s2 = sigma * sigma * 2.0
        return exp(-(x * x) / max(1e-9, s2))
    }

    // noise mượt
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
