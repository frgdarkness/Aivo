import SwiftUI

// MARK: - Generate Song Processing Screen
struct GenerateSongProcessingScreen: View {
    let requestType: RequestType
    let onComplete: () -> Void
    
    @State private var isGenerating = true
    @State private var progress: Double = 0.0
    @State private var animationOffset: CGFloat = 0
    @State private var isAnimating = false
    @State private var randomSeed: Double = 0
    @State private var showToast = false
    @State private var toastMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    // Initialize with request type only
    init(requestType: RequestType, onComplete: @escaping () -> Void) {
        self.requestType = requestType
        self.onComplete = onComplete
    }
    
    var body: some View {
        ZStack {
            // Background
            AivoSunsetBackground()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                VStack(spacing: 40) {
                    // Title
                    titleView
                    
                    // Animation Area
                    animationView
                    
                    // Status Text
                    statusView
                    
                    // Progress Bar
                    progressView
                    
                    // Cancel Button
                    cancelButton
                }
                .padding(.horizontal, 40)
                .padding(.top, 60)
                
                Spacer()
            }
        }
        .onAppear {
            startProgressAnimation()
        }
        .overlay(
            // Toast Message
            VStack {
                Spacer()
                if showToast {
                    Text(toastMessage)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(8)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: showToast)
                }
            }
        )
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Spacer()
            
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - Title View
    private var titleView: some View {
        VStack(spacing: 8) {
            Text(requestType.displayName)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text("Just a Moment!")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Animation View (pro)
    private var animationView: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.18), lineWidth: 2)
                .frame(width: 220, height: 220)

            WaveFlowProView(
                bars: 28,                 // nhiều cột hơn nhìn “pro” hơn
                width: 170,
                height: 110,
                period: 4.2,              // chu kỳ ~4–5s
                baseHeight: 12,
                peakHeight: 92,
                flow: .right,             // flow trái -> phải
                pulsePerCycle: 2,         // 2 nhịp trong một chu kỳ
                centerEmphasis: 0.35,     // nhấn mạnh vùng trung tâm
                roughness: 0.18           // độ “gồ ghề” nhỏ, nhìn thật
            )
        }
        .padding(.top, 8)
    }

    
    // MARK: - Status View
    private var statusView: some View {
        VStack(spacing: 8) {
            Text("We'll let you know once it's done!")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("(2-3 Min)")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    // MARK: - Progress View
    private var progressView: some View {
        VStack(spacing: 12) {
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 8)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AivoTheme.Primary.orange)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 8)
            
            // Progress Text
            Text("\(Int(progress * 100))%")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Cancel Button
    private var cancelButton: some View {
        Button(action: {
            dismiss()
        }) {
            Text("Cancel")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    // MARK: - Helper Methods
    private func waveHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 15
        let maxHeight: CGFloat = 85
        
        // Create random seed for this specific bar
        let barSeed = Double(index) * 0.1 + randomSeed
        let timeOffset = Double(index) * 0.3 + animationOffset
        
        // Multiple wave patterns with different frequencies
        let wave1 = sin(timeOffset * 2.0 + barSeed) * 0.3
        let wave2 = sin(timeOffset * 3.5 + barSeed * 1.3) * 0.25
        let wave3 = sin(timeOffset * 1.2 + barSeed * 0.7) * 0.2
        let wave4 = sin(timeOffset * 5.0 + barSeed * 2.1) * 0.15
        
        // Add random noise for more realistic effect
        let randomNoise = (sin(barSeed * 7.0 + animationOffset * 8.0) * 0.1)
        
        // Combine all waves
        let combinedWave = wave1 + wave2 + wave3 + wave4 + randomNoise
        
        // Add occasional random spikes for more dynamic effect
        let spikeChance = sin(barSeed * 11.0 + animationOffset * 3.0)
        let randomSpike = spikeChance > 0.8 ? (sin(barSeed * 13.0) * 0.3) : 0
        
        let finalWave = combinedWave + randomSpike
        let normalizedWave = (finalWave + 1.0) / 2.0 // Normalize to 0-1
        
        // Ensure wave stays within bounds
        let clampedWave = max(0, min(1, normalizedWave))
        
        return baseHeight + (maxHeight - baseHeight) * CGFloat(clampedWave)
    }
    
    private func startWaveAnimation() {
        // Initialize random seed
        randomSeed = Double.random(in: 0...1000)
        
        // Start continuous animation with random variations
        Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
            withAnimation(.linear(duration: 0.08)) {
                animationOffset += 0.15
                
                // Occasionally change random seed for more variation
                if Int.random(in: 1...20) == 1 {
                    randomSeed += Double.random(in: -50...50)
                }
            }
            
            // Toggle animation state for wave height changes
            if !isAnimating {
                isAnimating = true
            }
        }
    }
    
    private func startProgressAnimation() {
        // Simulate progress for UI only
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if progress < 1.0 {
                progress += 0.02
            } else {
                timer.invalidate()
            }
        }
    }
    
    private func showToastMessage(_ message: String) {
        toastMessage = message
        showToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            showToast = false
        }
    }
}

// MARK: - Preview
struct GenerateSongProcessingScreen_Previews: PreviewProvider {
    static var previews: some View {
        GenerateSongProcessingScreen(
            requestType: .generateSong,
            onComplete: {}
        )
    }
}
