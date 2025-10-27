import SwiftUI

// MARK: - Generate Lyrics Screen
struct GenerateLyricsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var lyricsText: String
    
    @State private var prompt: String = ""
    @State private var isGenerating: Bool = false
    @State private var lyricsResults: [LyricsResult] = []
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var progress: Double = 0.0
    
    var body: some View {
        ZStack {
            // Background
            AivoSunsetBackground()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Input Section (always shown)
                        inputSection
                        
                        // Results Section (shown after generation)
                        if !isGenerating && !lyricsResults.isEmpty {
                            resultsSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
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
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Text("Generate Lyrics")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
    }
    
    // MARK: - Input Section
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Prompt Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Describe Your Song")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ZStack(alignment: .topLeading) {
                    if prompt.isEmpty {
                        Text("Enter a prompt for the lyrics...")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.5))  // ✅ Brighter hint color
                            .padding(.horizontal, 12)
                            .padding(.vertical, 14)
                    }
                    
                    TextField("", text: $prompt, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.3))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AivoTheme.Primary.orange.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .lineLimit(5...10)
                }
            }
            
            // Generate Button
            Button(action: {
                generateLyrics()
            }) {
                HStack(spacing: 12) {
                    if isGenerating {
                        ProgressView()
                            .tint(.black)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    
                    Text(isGenerating ? "Generating..." : "Generate Lyrics")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AivoTheme.Primary.orange)
                )
                .shadow(color: AivoTheme.Shadow.orange, radius: 10, x: 0, y: 0)
            }
            .disabled(prompt.isEmpty || isGenerating)
            .opacity((prompt.isEmpty || isGenerating) ? 0.5 : 1.0)
            
            // Generating Animation (shown below button)
            if isGenerating {
                generatingAnimation
            }
        }
    }
    
    // MARK: - Generating Animation
    private var generatingAnimation: some View {
        VStack(spacing: 16) {
            // Compact Animation
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.18), lineWidth: 2)
                    .frame(width: 220, height: 220)
                
                LottieView(name: "lottie_wave_loop", loopMode: .loop, speed: 2.0)
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())
                    .shadow(color: .yellow.opacity(0.4), radius: 10, x: 0, y: 0)
                
                Circle()
                    .stroke(
                        LinearGradient(colors: [.yellow.opacity(0.8), .orange.opacity(0.4)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 3
                    )
                    .frame(width: 220, height: 220)
            }
            
            // Status
            VStack(spacing: 4) {
                Text("Generating...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("AI is creating your lyrics")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }
    
    // MARK: - Results Section
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Generated Lyrics")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    copyAllLyrics()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy All")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.15))
                    )
                }
            }
            
            ForEach(lyricsResults) { result in
                lyricsCard(for: result)
            }
        }
    }
    
    // MARK: - Lyrics Card
    private func lyricsCard(for result: LyricsResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(result.title)
                .font(.headline)
                .foregroundColor(AivoTheme.Primary.orange)
            
            // Lyrics Text
            Text(result.text)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(6)
            
            // Copy Button
            Button(action: {
                copyLyrics(result.text)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.on.doc")
                    Text("Copy")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.15))
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AivoTheme.Primary.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Helper Methods
    private func generateLyrics() {
        guard !prompt.isEmpty else { return }
        
        isGenerating = true
        lyricsResults = []
        
        Logger.i("📝 [GenerateLyrics] Starting lyrics generation...")
        Logger.d("📝 [GenerateLyrics] Prompt: \(prompt)")
        
        Task {
            do {
                let sunoService = SunoAiMusicService.shared
                let results = try await sunoService.generateLyricsWithRetry(prompt: prompt)
                
                Logger.i("✅ [GenerateLyrics] Generated \(results.count) lyrics variations")
                
                await MainActor.run {
                    isGenerating = false
                    lyricsResults = results
                    showToastMessage("Lyrics generated successfully!")
                }
                
            } catch {
                Logger.e("❌ [GenerateLyrics] Error: \(error)")
                await MainActor.run {
                    isGenerating = false
                    showToastMessage("Failed to generate lyrics: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func copyLyrics(_ text: String) {
        UIPasteboard.general.string = text
        lyricsText = text
        showToastMessage("Lyrics copied to clipboard!")
    }
    
    private func copyAllLyrics() {
        let allText = lyricsResults.map { "[\($0.title)]\n\n\($0.text)" }.joined(separator: "\n\n---\n\n")
        UIPasteboard.general.string = allText
        lyricsText = allText
        showToastMessage("All lyrics copied!")
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
struct GenerateLyricsScreen_Previews: PreviewProvider {
    static var previews: some View {
        GenerateLyricsScreen(lyricsText: .constant(""))
    }
}

