import SwiftUI

// MARK: - Generate Song Processing Screen
struct GenerateSongProcessingScreen: View {
    let requestType: RequestType
    let youtubeUrl: String?
    let coverLanguage: String?
    let coverModelID: String?
    let onComplete: () -> Void
    
    @State private var isGenerating = true
    @State private var progress: Double = 0.0
    @State private var animationOffset: CGFloat = 0
    @State private var isAnimating = false
    @State private var randomSeed: Double = 0
    @State private var resultAudioUrl: String?
    @State private var showPlaySongScreen = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    // Initialize with default values for generateSong
    init(requestType: RequestType, youtubeUrl: String? = nil, coverLanguage: String? = nil, coverModelID: String? = nil, onComplete: @escaping () -> Void) {
        self.requestType = requestType
        self.youtubeUrl = youtubeUrl
        self.coverLanguage = coverLanguage
        self.coverModelID = coverModelID
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
            startGeneration()
        }
        .fullScreenCover(isPresented: $showPlaySongScreen) {
            if let audioUrl = resultAudioUrl {
                PlaySongIntroScreen(
                    songData: nil,
                    audioUrl: audioUrl,
                    onIntroCompleted: {
                        showPlaySongScreen = false
                        onComplete()
                    }
                )
            }
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
    
    // MARK: - Animation View
    private var animationView: some View {
        ZStack {
            // Circular background
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                .frame(width: 200, height: 200)
            
            // Sound wave animation
            HStack(spacing: 3) {
                ForEach(0..<20, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white)
                        .frame(width: 4)
                        .frame(height: waveHeight(for: index))
                        .animation(
                            Animation.easeInOut(duration: 0.2)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.1),
                            value: animationOffset
                        )
                }
            }
            .frame(height: 100)
        }
        .onAppear {
            startWaveAnimation()
        }
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
    
    private func startGeneration() {
        Task {
            do {
                let modelsLabService = ModelsLabService.shared
                
                switch requestType {
                case .coverSong:
                    guard let youtubeUrl = youtubeUrl,
                          let coverLanguage = coverLanguage,
                          let coverModelID = coverModelID else {
                        showToastMessage("Missing required data for cover song")
                        return
                    }
                    
                    // Call ModelsLabService for voice cover
                    do {
                        let resultUrl = try await modelsLabService.processVoiceCover(audioUrl: youtubeUrl, modelID: coverModelID)
                            
                        
                        resultAudioUrl = resultUrl
                        showToastMessage("Cover song generated successfully!")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            showPlaySongScreen = true
                        }
                    } catch {
                        showToastMessage("Failed to generate cover song: \(error.localizedDescription)")
                    }
                    
                case .generateSong:
                    // For now, simulate generation for generateSong
                    // TODO: Implement actual song generation API
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        showToastMessage("Song generation completed!")
                        // For demo, use hardcoded audio
                        resultAudioUrl = Bundle.main.url(forResource: "ai_tokyo", withExtension: "mp3")?.absoluteString
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            showPlaySongScreen = true
                        }
                    }
                }
            }
        }
        
        // Simulate progress for UI
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
            requestType: .coverSong,
            youtubeUrl: "https://www.youtube.com/watch?v=example",
            coverLanguage: "english",
            coverModelID: "vegeta",
            onComplete: {}
        )
    }
}
