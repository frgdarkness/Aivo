import SwiftUI

// MARK: - Generate Song Screen
struct GenerateSongProcessingScreen: View {
    @State private var isGenerating = true
    @State private var progress: Double = 0.0
    @State private var animationOffset: CGFloat = 0
    @Environment(\.dismiss) private var dismiss
    
    let onComplete: () -> Void
    
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
            Text("Generate Song")
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
                            Animation.easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.1),
                            value: animationOffset
                        )
                }
            }
            .frame(height: 100)
        }
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                animationOffset = 1.0
            }
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
        let baseHeight: CGFloat = 20
        let maxHeight: CGFloat = 80
        let variation = sin(Double(index) * 0.5 + animationOffset * .pi * 2) * 0.5 + 0.5
        return baseHeight + (maxHeight - baseHeight) * CGFloat(variation)
    }
    
    private func startGeneration() {
        // Simulate generation progress
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if progress < 1.0 {
                progress += 0.02
            } else {
                timer.invalidate()
                // Complete generation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete()
                }
            }
        }
    }
}

// MARK: - Preview
struct GenerateSongScreen_Previews: PreviewProvider {
    static var previews: some View {
        GenerateSongProcessingScreen(onComplete: {})
    }
}
