import SwiftUI

struct MusicWaveAnimationView: View {
    @State private var animationOffset: CGFloat = 0
    @State private var isAnimating = false
    
    let waveCount = 16
    let waveHeight: CGFloat = 60
    let waveWidth: CGFloat = 2.5
    let spacing: CGFloat = 3
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: spacing) {
                ForEach(0..<waveCount, id: \.self) { index in
                    WaveBar(
                        index: index,
                        totalWaves: waveCount,
                        animationOffset: animationOffset,
                        waveHeight: waveHeight,
                        waveWidth: waveWidth
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                startAnimation()
            }
        }
    }
    
    private func startAnimation() {
        isAnimating = true
        print("🎵 [MusicWave] Starting animation...")
        
        // Continuous animation from right to left
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            animationOffset = 1.0
        }
        
        // Debug timer to check animation
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            print("🎵 [MusicWave] Animation offset: \(animationOffset)")
            if !isAnimating {
                timer.invalidate()
            }
        }
    }
}

struct WaveBar: View {
    let index: Int
    let totalWaves: Int
    let animationOffset: CGFloat
    let waveHeight: CGFloat
    let waveWidth: CGFloat
    
    @State private var currentHeight: CGFloat = 0
    
    var body: some View {
        RoundedRectangle(cornerRadius: waveWidth / 2)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        AivoTheme.Primary.orange.opacity(0.9),
                        AivoTheme.Primary.orange,
                        AivoTheme.Primary.orange.opacity(0.7)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: waveWidth, height: currentHeight)
            .onAppear {
                updateHeight()
            }
            .onChange(of: animationOffset) { _ in
                updateHeight()
            }
    }
    
    private func updateHeight() {
        // Create a wave that moves from right to left
        let wavePosition = Double(index) / Double(totalWaves)
        let wavePhase = wavePosition + Double(animationOffset)
        
        // Create a traveling wave effect with multiple frequencies
        let wave1 = sin(wavePhase * .pi * 2) * 0.5 + 0.5
        let wave2 = sin(wavePhase * .pi * 4 + 0.3) * 0.3 + 0.7
        let wave3 = sin(wavePhase * .pi * 6 + 0.6) * 0.2 + 0.8
        
        // Combine waves for more complex pattern
        let combinedWave = (wave1 + wave2 + wave3) / 3
        
        // Add envelope for more realistic wave shape
        let envelope = sin(wavePosition * .pi) * 0.3 + 0.7
        
        // Calculate final height with more dynamic range
        let baseHeight = waveHeight * 0.05
        let maxHeight = waveHeight * 0.95
        let finalHeight = baseHeight + (maxHeight - baseHeight) * CGFloat(combinedWave * envelope)
        
        // Ensure minimum height
        let minHeight = waveHeight * 0.02
        let clampedHeight = max(minHeight, finalHeight)
        
        if index == 0 {
            print("🎵 [WaveBar] Index: \(index), Phase: \(wavePhase), Height: \(clampedHeight)")
        }
        
        withAnimation(.easeInOut(duration: 0.05)) {
            currentHeight = clampedHeight
        }
    }
}

// MARK: - Preview
struct MusicWaveAnimationView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            MusicWaveAnimationView()
                .frame(width: 200, height: 100)
        }
    }
}
