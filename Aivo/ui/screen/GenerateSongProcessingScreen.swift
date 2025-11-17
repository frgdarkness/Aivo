import SwiftUI

// MARK: - Generate Song Processing Screen
struct GenerateSongProcessingScreen: View {
    let requestType: RequestType
    let onComplete: () -> Void
    let onCancel: (() -> Void)?
    
    @State private var isGenerating = true
    @State private var progress: Double = 0.0
    @State private var animationOffset: CGFloat = 0
    @State private var isAnimating = false
    @State private var randomSeed: Double = 0
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var showCancelAlert = false
    @Environment(\.dismiss) private var dismiss
    
    // Initialize with request type, onComplete, and optional onCancel
    init(requestType: RequestType, onComplete: @escaping () -> Void, onCancel: (() -> Void)? = nil) {
        self.requestType = requestType
        self.onComplete = onComplete
        self.onCancel = onCancel
    }
    
    var body: some View {
        ZStack {
            // Background
            AivoSunsetBackground()
            VStack(spacing: 40) {
                // Title
                
                
                // Animation Area
                animationView
                
                // Status Text
                statusView
                
                // Progress Bar
                //progressView
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            VStack(spacing: 0) {
                
                
                // Header
                headerView
                
                titleView.padding(.top, 40)
                
                Spacer()
                // Content
                
                
                Spacer()
            }
        }
        .onAppear {
            startProgressAnimation()
            startWaveAnimation()
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
                showCancelAlert = true
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .alert("Cancel Generation?", isPresented: $showCancelAlert) {
            Button("Cancel", role: .cancel) {
                // User cancelled the alert, do nothing
            }
            Button("Yes, Exit", role: .destructive) {
                // User confirmed cancellation
                Logger.i("⚠️ [ProcessingScreen] User confirmed cancellation")
                isGenerating = false
                onCancel?()
                dismiss()
            }
        } message: {
            Text("If you exit now, the generation process will be cancelled.")
        }
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
//    private var animationView: some View {
//        ZStack {
//            Circle()
//                .stroke(Color.white.opacity(0.18), lineWidth: 2)
//                .frame(width: 220, height: 220)
//
//            WaveFlowProView(
//                bars: 28,                 // nhiều cột hơn nhìn “pro” hơn
//                width: 170,
//                height: 110,
//                period: 4.2,              // chu kỳ ~4–5s
//                baseHeight: 12,
//                peakHeight: 92,
//                flow: .right,             // flow trái -> phải
//                pulsePerCycle: 2,         // 2 nhịp trong một chu kỳ
//                centerEmphasis: 0.35,     // nhấn mạnh vùng trung tâm
//                roughness: 0.18           // độ “gồ ghề” nhỏ, nhìn thật
//            )
//        }
//        .padding(.top, 8)
//    }
    
    private var animationView: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.18), lineWidth: 2)
                .frame(width: 220, height: 220)

            LottieView(name: "lottie_wave_loop", loopMode: .loop, speed: 2.0)
                        .frame(width: 200, height: 200)
                        .clipShape(Circle()) // nếu muốn animation gọn trong hình tròn
                        .shadow(color: .yellow.opacity(0.4), radius: 10, x: 0, y: 0)
            Circle()
                .stroke(
                    LinearGradient(colors: [.yellow.opacity(0.8), .orange.opacity(0.4)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 3
                )
                .frame(width: 220, height: 220)
            // New Music Wave Animation
//            MusicWaveAnimationView()
//                .frame(width: 180, height: 100)
//                .clipShape(Circle())

//            WaveFlowProView2(
//                bars: 28,
//                width: 170,
//                height: 110,
//                bpm: 128,                 // tốc độ cảm giác nhanh hơn, có nhịp rõ
//                barsPerCycle: 2,          // 2 ô nhịp/chu kỳ
//                stepsPerBeat: 4,          // 16-step
//                swing: 0.12,              // một chút swing cho "groove"
//                baseHeight: 12,
//                peakHeight: 92,
//                flow: .right,
//                centerEmphasis: 0.35,
//                roughness: 0.12
//            )
            
//            WaveFlowProView3(
//                bars: 42,
//                width: 220,
//                height: 140,
//                bpm: 128,
//                barsPerCycle: 2,
//                stepsPerBeat: 4,
//                swing: 0.12,
//                baseHeight: 8,
//                peakHeight: 110,
//                flow: .right,
//                mirrorSymmetry: true,          // giống ảnh mẫu
//                centerEmphasis: 0.45,
//                roughness: 0.10,
//                ampJitter: 0.25,
//                phaseJitter: 0.6,
//                widthJitter: 0.20,
//                groupiness: 0.65
//            ).padding(.horizontal, 10)
            
//            ScrollingWaveView(
//                    bars: 52,
//                    width: 220,
//                    height: 140,
//                    speed: 0.9,                // nhanh/chậm cuộn
//                    baseHeight: 6,
//                    peakHeight: 115,
//                    mirrorSymmetry: true,
//                    centerEmphasis: 0.5,
//                    roughness: 0.6,            // nhiều octave hơn → organic
//                    ampJitter: 0.22,
//                    widthJitter: 0.18,
//                    color: .white
//                )
            
//            ScrollingClusterWaveView(
//                bars: 52,
//                width: 220,
//                height: 140,
//                speed: 1.0,                 // chạy nhanh/chậm
//                baseHeight: 6,
//                peakHeight: 118,
//                color: .white,
//                mirrorSymmetry: true,
//                centerEmphasis: 0.6,
//                ampJitter: 0.22,
//                widthJitter: 0.18,
//                shortProb: 0.65,            // nhiều tiếng ngắn hơn
//                shortBarsRange: 5...7,
//                longBarsRange: 10...16,
//                clustersPerInterval: 3,     // 2–3 cụm/đoạn
//                clusterSpacing: 0.55,       // khoảng cách giữa các cụm
//                dynamics: 0.7,
//                floorLevel: 0.03,
//                textureAmount: 0.16
//            ).padding(.horizontal, 20)
    
//            ScrollingClusterWaveView2(
//                bars: 52,
//                width: 220,
//                height: 140,
//                speed: 1.1,
//                baseHeight: 6,
//                peakHeight: 120,
//                color: .white,
//                mirrorSymmetry: true,
//                centerEmphasis: 0.6,
//                ampJitter: 0.22,
//                widthJitter: 0.18,
//                shortProb: 0.65,
//                shortBarsRange: 5...7,
//                longBarsRange: 10...16,
//                clustersPerInterval: 3,
//                clusterSpacing: 0.7,
//                dynamics: 0.65,
//                floorLevel: 0.02,
//                textureAmount: 0.12
//            )
            
//            ScrollingClusterWaveView3(
//                                bars: 60,                 // nhiều bar mịn hơn
//                                width: 220,
//                                height: 140,
//                                speed: 1.1,               // tốc độ chạy
//                                baseHeight: 6,
//                                peakHeight: 120,
//                                color: .white,
//                                mirrorSymmetry: true,     // đối xứng 2 bên
//                                centerEmphasis: 0.55,     // tập trung giữa
//                                ampJitter: 0.2,
//                                widthJitter: 0.16,
//                                textureAmount: 0.1,       // "rung" nhẹ
//                                floorLevel: 0.02,
//                                dynamics: 0.65,
//                                phraseCenters: [0.23, 0.50, 0.78],   // 3 cụm (trái, giữa, phải)
//                                phraseAmps: [0.75, 1.0, 0.82],       // cụm giữa to nhất
//                                phraseWidths: [0.06, 0.08, 0.06]     // độ rộng từng cụm
//                            )
            
//            ScrollingClusterWaveView4(
//                bars: 52,
//                width: 220,
//                height: 140,
//                speed: 1.0,
//                baseHeight: 6,
//                peakHeight: 122,
//                color: .white,
//                mirrorSymmetry: true,
//                centerEmphasis: 0.6,
//                ampJitter: 0.2,
//                widthJitter: 0.14,
//                shortProb: 0.65,
//                shortBarsRange: 5...7,
//                longBarsRange: 8...12,
//                clustersPerInterval: 3,
//                clusterSpacing: 0.7,
//                dynamics: 0.64,
//                floorLevel: 0.02,
//                textureAmount: 0.1
//            )

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
            
            Text("(2-5 Min)")
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
