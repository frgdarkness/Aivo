//
//  ScrollingWaveView.swift
//  Aivo
//
//  Created by Huy on 24/10/25.
//


import SwiftUI

struct ScrollingWaveView: View {
    // MARK: - Public params
    let bars: Int
    let width: CGFloat
    let height: CGFloat

    /// tốc độ cuộn (đơn vị: chu kỳ / giây). 0.6–1.2 là đẹp
    let speed: Double

    /// hình học & phong cách
    let baseHeight: CGFloat         // chiều cao tối thiểu mỗi bar
    let peakHeight: CGFloat         // chiều cao tối đa
    let mirrorSymmetry: Bool        // đối xứng 2 bên cho shape đẹp như ảnh
    let centerEmphasis: Double      // 0..1 nhấn mạnh vùng trung tâm
    let roughness: Double           // 0..1 độ “gồ ghề” (fBm octave)
    let ampJitter: Double           // 0..0.5 biên độ hơi khác nhau theo bar
    let widthJitter: CGFloat        // 0..0.4 độ rộng bar hơi khác nhau
    let color: Color

    // MARK: - internals
    private let spacing: CGFloat = 3
    private let barBaseWidth: CGFloat
    private let gains: [Double]
    private let widths: [CGFloat]

    init(
        bars: Int = 48,
        width: CGFloat,
        height: CGFloat,
        speed: Double = 0.8,
        baseHeight: CGFloat = 8,
        peakHeight: CGFloat = 120,
        mirrorSymmetry: Bool = true,
        centerEmphasis: Double = 0.45,
        roughness: Double = 0.55,
        ampJitter: Double = 0.22,
        widthJitter: CGFloat = 0.18,
        color: Color = .white
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

        // base width & jitter
        let estW = max(2, (width - CGFloat(bars - 1) * spacing) / CGFloat(bars))
        self.barBaseWidth = estW

        var g: [Double] = []
        var ws: [CGFloat] = []
        for i in 0..<bars {
            let r1 = Self.hash01(Double(i) * 13.37 + 7.91)
            let r2 = Self.hash01(Double(i) * 5.17  + 0.33)
            g.append(1.0 + ampJitter * (r1 * 2 - 1))                 // ~0.78..1.22
            ws.append(estW * (1.0 + widthJitter * CGFloat(r2 * 2 - 1)))
        }
        self.gains = g
        self.widths = ws
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            // phase tăng tuyến tính theo thời gian → cuộn từ phải sang trái
            let t = timeline.date.timeIntervalSinceReferenceDate
            let phase = t * speed    // đơn vị: chu kỳ

            Canvas { ctx, size in
                let totalWidth = widths.reduce(0,+) + CGFloat(bars - 1) * spacing
                var x = (size.width - totalWidth) / 2
                let originY = (size.height - height) / 2
                let nMinus1 = max(1, bars - 1)
                let deltaH = peakHeight - baseHeight

                for i in 0..<bars {
                    // đối xứng: dùng thông số theo index gần tâm
                    let j = mirrorSymmetry ? min(i, bars - 1 - i) : i

                    // vị trí sample theo trục “thời gian” để cuộn R→L:
                    // dùng phase + offset giảm dần theo i (i càng lớn → ở bên phải → giá trị sớm hơn)
                    let samplePos = phase + Double(bars - i) * 0.08

                    // fBm noise (0..1) mịn, nhiều octave → nhìn giống nhạc
                    let f = Self.fbm(samplePos, octaves: 4, roughness: roughness)

                    // envelope theo không gian (nhấn giữa)
                    let u = Double(j) / Double(nMinus1)
                    let d = abs(u - 0.5) * 2.0
                    let bias = 1.0 - centerEmphasis * (d * d)

                    // cường độ cuối 0..1
                    var v = f * bias * gains[j]
                    if v < 0 { v = 0 }; if v > 1 { v = 1 }

                    // height
                    let h = baseHeight + CGFloat(v) * deltaH
                    let bw = widths[i]
                    let y = originY + (height - h) / 2

                    // draw
                    let rect = CGRect(x: x, y: y, width: bw, height: h)
                    let path = Path(roundedRect: rect, cornerSize: CGSize(width: 2, height: 2))
                    ctx.fill(path, with: .color(color))

                    x += bw + spacing
                }
            }
            .frame(width: width, height: height)
        }
    }

    // MARK: - Noise helpers (value noise + smoothstep + fBm)
    /// deterministic 0..1
    private static func hash01(_ x: Double) -> Double {
        let s = sin(x * 12.9898) * 43758.5453
        return s - floor(s)
    }

    /// value noise 1D, smooth bằng Hermite
    private static func valueNoise(_ x: Double) -> Double {
        let i = floor(x)
        let f = x - i
        let u = f * f * (3 - 2 * f)              // smoothstep
        let a = hash01(i)
        let b = hash01(i + 1.0)
        return a * (1 - u) + b * u               // 0..1
    }

    /// fractal Brownian motion (0..1) — cộng nhiều octave
    private static func fbm(_ x: Double, octaves: Int, roughness: Double) -> Double {
        var amp = 0.5
        var freq = 1.0
        var sum = 0.0
        var norm = 0.0
        let r = max(0.0, min(1.0, roughness))
        for _ in 0..<max(1, octaves) {
            let v = valueNoise(x * freq)
            sum += amp * v
            norm += amp
            amp *= 0.5 + 0.5 * (1.0 - r)         // giảm biên độ theo roughness
            freq *= 2.02                          // octave tiếp theo
        }
        return (sum / max(1e-6, norm))            // 0..1
    }
}
