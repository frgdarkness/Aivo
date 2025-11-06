import SwiftUI

// MARK: - Multiline Prompt (iOS 15+ compatible)
struct PromptInput: View {
    @Binding var text: String
    let maxChars: Int
    let minLines: Int
    let maxLines: Int
    let placeholder: String

    // style chung
    private var bg: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.black.opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AivoTheme.Primary.orange.opacity(0.3), lineWidth: 1)
            )
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if #available(iOS 16.0, *) {
                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.55)) // hint sáng hơn
                            .padding(12)
                    }

                    TextField("", text: $text, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(12)
                        .padding(.bottom, 28) // chừa chỗ cho counter
                        .background(bg)
                        .lineLimit(minLines...maxLines)
                        .onChange(of: text) { newValue in
                            if newValue.count > maxChars {
                                text = String(newValue.prefix(maxChars))
                            }
                        }
                }
            } else {
                // iOS 15 fallback: TextEditor + placeholder thủ công
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(8) // TextEditor có inset riêng
                        .frame(
                            minHeight: estimatedHeight(lines: minLines),
                            maxHeight: estimatedHeight(lines: maxLines)
                        )
                        .background(bg)
                        .onChange(of: text) { newValue in
                            if newValue.count > maxChars {
                                text = String(newValue.prefix(maxChars))
                            }
                        }

                    if text.isEmpty {
                        Text(placeholder)
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.55))
                            .padding(14)
                    }
                }
                .padding(.bottom, 28) // chừa chỗ cho counter
            }

            // Counter chung
            Text("\(text.count) / \(maxChars)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .padding(.trailing, 8)
                .padding(.bottom, 8)
        }
    }

    // Ước lượng chiều cao theo số dòng cho iOS 15 (TextEditor không có lineLimit)
    private func estimatedHeight(lines: Int) -> CGFloat {
        let lineHeight: CGFloat = 20.5 // ~line height cho font 16
        return lineHeight * CGFloat(lines) + 16 // +padding
    }
}

// MARK: - Generate Lyrics Screen
struct GenerateLyricsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var creditManager = CreditManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Binding var lyricsText: String

    @State private var prompt: String = ""
    @State private var isGenerating: Bool = false
    @State private var lyricsResults: [LyricsResult] = []
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var progress: Double = 0.0
    @State private var showPremiumAlert = false
    @State private var showSubscriptionScreen = false
    @State private var showServerErrorAlert = false

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
        .onAppear {
            // Log screen view
            FirebaseLogger.shared.logScreenView(FirebaseLogger.EVENT_SCREEN_GENERATE_LYRICS)
        }
        .fullScreenCover(isPresented: $showSubscriptionScreen) {
            SubscriptionScreenIntro()
//            if SubscriptionManager.shared.isPremium {
//                SubscriptionScreen()
//            } else {
//                SubscriptionScreenIntro()
//            }
        }
        .alert("Server Error", isPresented: $showServerErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("There was a server error. Please try again in a few minutes.")
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            Text("Generate Lyrics")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Spacer()

            Button(action: { dismiss() }) {
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

                PromptInput(
                    text: $prompt,
                    maxChars: 200,
                    minLines: 5,
                    maxLines: 10,
                    placeholder: "Enter a prompt for the lyrics..."
                )
            }

            // Generate Button
            Button(action: { generateLyrics() }) {
                HStack(spacing: 12) {
                    if isGenerating {
                        ProgressView()
                            .tint(.black)
                            .scaleEffect(0.8)
                    }

                    Text(isGenerating ? "Generating..." : "Generate Lyrics")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    // Credit cost display (only show when not generating)
                    if !isGenerating {
                        HStack(spacing: 2) {
                            Text("(-4")
                                .font(.headline)
                                .fontWeight(.bold)
                            Image("icon_coin")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 17, height: 17)
                            Text(")")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.black.opacity(0.8))
                    }
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

                Button(action: { copyAllLyrics() }) {
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
            Button(action: { copyLyrics(result.text, title: result.title) }) {
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
    private var hasEnoughCreditsForLyrics: Bool {
        return creditManager.credits >= 4
    }
    
    // Hide keyboard helper
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func generateLyrics() {
        guard !prompt.isEmpty else { return }
        
        // Hide keyboard first
        hideKeyboard()
        
        // Check subscription first
        guard subscriptionManager.isPremium else {
            showSubscriptionScreen = true
            return
        }
        
        // Check credits before starting
        guard creditManager.credits >= 4 else {
            showToastMessage("Not enough credits! You need 4 credits to generate lyrics.")
            return
        }

        isGenerating = true
        lyricsResults = []

        Logger.i("📝 [GenerateLyrics] Starting lyrics generation...")
        Logger.d("📝 [GenerateLyrics] Prompt: \(prompt)")
        
        // Log Firebase event
        FirebaseLogger.shared.logEventWithBundle(FirebaseLogger.EVENT_GENERATE_LYRICS_START, parameters: [
            "prompt_length": prompt.count,
            "timestamp": Date().timeIntervalSince1970
        ])

        Task {
            do {
                let sunoService = SunoAiMusicService.shared
                let results = try await sunoService.generateLyricsWithRetry(prompt: prompt)

                Logger.i("✅ [GenerateLyrics] Generated \(results.count) lyrics variations")

                await MainActor.run {
                    isGenerating = false
                    lyricsResults = results
                    showToastMessage("Lyrics generated successfully!")
                    
                    // Log Firebase success event
                    FirebaseLogger.shared.logEventWithBundle(FirebaseLogger.EVENT_GENERATE_LYRICS_SUCCESS, parameters: [
                        "results_count": results.count,
                        "timestamp": Date().timeIntervalSince1970
                    ])
                    
                    // Deduct credits only after successful generation
                    Task {
                        await CreditManager.shared.deductForSuccessfulRequest(count: 4)
                        Logger.i("📝 [GenerateLyrics] Deducted 4 credits for successful lyrics generation")
                        // Save to history
                        CreditHistoryManager.shared.addRequest(.generateLyric)
                    }
                }
            } catch let sunoError as SunoError {
                Logger.e("❌ [GenerateLyrics] Error: \(sunoError)")
                
                // Log Firebase failed event
                FirebaseLogger.shared.logEventWithBundle(FirebaseLogger.EVENT_GENERATE_LYRICS_FAILED, parameters: [
                    "error_type": String(describing: type(of: sunoError)),
                    "error_message": sunoError.localizedDescription,
                    "timestamp": Date().timeIntervalSince1970
                ])
                
                await MainActor.run {
                    isGenerating = false
                    
                    // Check if it's HTTP 500 error
                    if case .httpError(let code) = sunoError, code == 500 {
                        showServerErrorAlert = true
                    } else {
                        showToastMessage("Failed to generate lyrics: \(sunoError.localizedDescription)")
                    }
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

    private func copyLyrics(_ text: String, title: String) {
        UIPasteboard.general.string = text
        lyricsText = "[\(title)]\n\n\(text)"
        showToastMessage("Lyrics copied to clipboard!")
    }

    private func copyAllLyrics() {
        let allText = lyricsResults.map { "[\($0.title)]\n\n\($0.text)" }
            .joined(separator: "\n\n---\n\n")
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
