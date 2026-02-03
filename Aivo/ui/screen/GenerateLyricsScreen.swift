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
                        .submitLabel(.done)
                        .onSubmit {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                        .onChange(of: text) { newValue in
                            if newValue.count > maxChars {
                                text = String(newValue.prefix(maxChars))
                            }
                        }
                }
            } else {
                // iOS 15 fallback: TextField (single line)
                ZStack(alignment: .topLeading) {
                    TextField("", text: $text)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(8)
                        .frame(
                            minHeight: estimatedHeight(lines: minLines),
                            maxHeight: estimatedHeight(lines: maxLines)
                        )
                        .background(bg)
                        .lineLimit(1)
                        .submitLabel(.done)
                        .onSubmit {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
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
    @Binding var lyrics: String
    @Binding var songName: String
    
    // Configuration State
    @State private var config = LyricConfiguration()
    @State private var isGenerating: Bool = false
    @State private var showLyricVariationInfo = false
    
    // UI State
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var showMoodSheet = false
    @State private var showGenreSheet = false
    @State private var lyricsResults: [LyricsResult] = []
    
    // Premium gating & Services
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var creditManager = CreditManager.shared
    @ObservedObject private var remoteConfig = RemoteConfigManager.shared
    @ObservedObject private var profileManager = ProfileManager.shared
    @State private var showPremiumAlert = false
    @State private var showInsufficientCreditsAlert = false
    @State private var showSubscriptionScreen = false
    @State private var showBuyCreditDialog = false
    @State private var showServerErrorAlert = false
    @State private var showResultScreen = false

    var body: some View {
        ZStack {
            // Background
            AivoSunsetBackground()

            VStack(spacing: 0) {
                // Header
                headerView
                    .frame(height: 60)

                ScrollView {
                    mainContent
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                }
                
                generateButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
        }
        .overlay(
            toastOverlay
        )
        .onAppear {
            // Log screen view
            AnalyticsLogger.shared.logScreenView(AnalyticsLogger.EVENT.EVENT_SCREEN_GENERATE_LYRICS)
        }
        .sheet(isPresented: $showMoodSheet) {
            SelectMultiMoodScreen(
                initialSelectedMoods: config.moods,
                onDone: { moods in config.moods = moods },
                onCancel: {}
            )
        }
        .sheet(isPresented: $showGenreSheet) {
            SelectMultiGenreScreen(
                initialSelectedGenres: config.genres,
                onDone: { genres in config.genres = genres },
                onCancel: {}
            )
        }
        .fullScreenCover(isPresented: $showSubscriptionScreen) {
            SubscriptionScreenIntro()
        }
        .fullScreenCover(isPresented: $showResultScreen) {
            GenerateLyricResultScreen(
                results: lyricsResults,
                selectedLyrics: $lyrics,
                selectedSongName: $songName,
                onSelect: { _, _ in
                    dismiss()
                }
            )
        }
        .alert("Server Error", isPresented: $showServerErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("There was a server error. Please try again in a few minutes.")
        }
        .alert("Lyric Variation", isPresented: $showLyricVariationInfo) {
            Button("Got it", role: .cancel) { }
        } message: {
            Text("Choose how many lyric versions you want to generate at once, making it easier to compare and select the best one.")
        }
        .alert("Premium Feature", isPresented: $showPremiumAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Go Premium") {
                showSubscriptionScreen = true
            }
        } message: {
            Text("Lyrics generation is only available for Premium members.")
        }
        .alert("Insufficient Credits", isPresented: $showInsufficientCreditsAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Buy More") {
                 showSubscriptionScreen = true 
            }
        } message: {
            let baseCost = config.mode == .simple ? 10 : (config.mode == .custom ? 15 : 20)
            let totalCost = baseCost * config.lyricCount
            Text("You need \(totalCost) credits to generate lyrics. Please purchase more credits to continue.")
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    // MARK: - Subviews
    private var mainContent: some View {
        VStack(spacing: 24) {
             // Mode Selection
             modePickerSection
             
             // Input Section (always shown)
             inputSection

             // Structure (Custom/Advance)
             if config.mode == .custom || config.mode == .advance {
                 structureSelectionSection
             }
             
             // Extended Sections
             if config.mode == .custom || config.mode == .advance {
                 customOptionsSection
             }
             
             if config.mode == .advance {
                 advanceOptionsSection
             }
             
             // Lyric Variation
             lyricVariationSection
         }
    }
    
    private var toastOverlay: some View {
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

    // MARK: - Sections
    private var modePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Mode")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                HStack(spacing: 4) {
                    Text("\(config.mode == .simple ? 10 : (config.mode == .custom ? 15 : 20))")
                        .font(.system(size: 14, weight: .bold))
                    Image("icon_coin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                }
                .foregroundColor(.yellow)
            }
            
            HStack(spacing: 0) {
                let modes = LyricGenerationMode.allCases
                ForEach(Array(modes.enumerated()), id: \.element) { index, mode in
                    Button(action: {
                        withAnimation { config.mode = mode }
                    }) {
                        Text(mode.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(config.mode == mode ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(config.mode == mode ? Color.white : Color.clear)
                            )
                    }
                    
                    if index < modes.count - 1 {
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 1, height: 20)
                    }
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AivoTheme.Primary.orange.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Prompt
            VStack(alignment: .leading, spacing: 8) {
                Text("Describe Your Song")
                    .font(.headline)
                    .foregroundColor(.white)

                PromptInput(
                    text: $config.prompt,
                    maxChars: 500,
                    minLines: 4,
                    maxLines: 8,
                    placeholder: "Enter a prompt (e.g. A love song about rain)"
                )
            }
            
            // Language
            VStack(alignment: .leading, spacing: 8) {
                Text("Language")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("English", text: $config.language)
                    .padding(12)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AivoTheme.Primary.orange.opacity(0.3), lineWidth: 1)
                    )
                    .foregroundColor(.white)
            }
        }
    }
    
    private var structureSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Structure")
                .font(.headline)
                .foregroundColor(.white)
            
            if #available(iOS 16.0, *) {
                FlowLayout(spacing: 8) {
                    structureButtons
                }
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                    structureButtons
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var structureButtons: some View {
        ForEach(SongStructurePart.allCases.sorted { $0.order < $1.order }) { part in
            let isMandatory = (part == .verse || part == .chorus)
            let isSelected = config.structure.contains(part) || isMandatory
            
            Button(action: {
                if isMandatory { return }
                if config.structure.contains(part) {
                    if config.structure.count > 1 {
                        config.structure.remove(part)
                    }
                } else {
                    config.structure.insert(part)
                }
            }) {
                Text(part.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .black : .white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isSelected ? Color.white : Color.white.opacity(0.1))
                    )
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? Color.white : AivoTheme.Primary.orange, lineWidth: isSelected ? 0 : 1)
                            .opacity(isSelected ? 0 : 0.3)
                    )
                    .opacity(isMandatory ? 0.8 : 1.0)
            }
            .disabled(isMandatory)
        }
    }
    
    private var customOptionsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Mood & Genre
            VStack(alignment: .leading, spacing: 16) {
                // Mood
                selectionRow(title: "Mood", items: config.moods.map { $0.displayName }) {
                    showMoodSheet = true
                }
                
                // Genre
                selectionRow(title: "Genre", items: config.genres.map { $0.displayName }) {
                    showGenreSheet = true
                }
            }
            
            // Length & Perspective
            HStack(spacing: 16) {
                menuPicker(title: "Length", selection: $config.length, options: LyricLength.allCases)
                menuPicker(title: "Perspective", selection: $config.perspective, options: LyricPerspective.allCases)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var advanceOptionsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Advanced Options")
                .font(.headline)
                .foregroundColor(AivoTheme.Primary.orange)
            
            // Scheme & Style
            HStack(spacing: 16) {
                menuPicker(title: "Rhyme Scheme", selection: $config.rhymeScheme, options: RhymeScheme.allCases)
                menuPicker(title: "Writing Style", selection: $config.writingStyle, options: WritingStyle.allCases)
            }
            
            // Avoid
            VStack(alignment: .leading, spacing: 12) {
                Text("Avoid")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                if #available(iOS 16.0, *) {
                    FlowLayout(spacing: 8) {
                        avoidButtons
                    }
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                        avoidButtons
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AivoTheme.Primary.orange.opacity(0.5), lineWidth: 1)
                )
        )
    }
    
    private var avoidButtons: some View {
        ForEach(LyricAvoidance.allCases) { item in
            Button(action: {
                if config.avoid.contains(item) {
                    config.avoid.remove(item)
                } else {
                    config.avoid.insert(item)
                }
            }) {
                Text(item.rawValue)
                    .font(.system(size: 13))
                    .foregroundColor(config.avoid.contains(item) ? .black : .white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(config.avoid.contains(item) ? Color.white : Color.white.opacity(0.1))
                    )
                    .overlay(
                        Capsule()
                            .stroke(config.avoid.contains(item) ? Color.white : AivoTheme.Primary.orange, lineWidth: config.avoid.contains(item) ? 0 : 1)
                            .opacity(config.avoid.contains(item) ? 0 : 0.3)
                    )
            }
        }
    }
    
    private var currentLyricCost: Int {
        switch config.mode {
        case .simple: return 10
        case .custom: return 15
        case .advance: return 20
        }
    }
    
    private var totalCost: Int {
        return currentLyricCost * config.lyricCount
    }

    private var lyricVariationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text("Lyric Variation")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Button(action: {
                    withAnimation {
                        showLyricVariationInfo = true
                    }
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("= \(totalCost)")
                        .font(.system(size: 16, weight: .bold))
                    Image("icon_coin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                }
                .foregroundColor(.yellow)
            }
            
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { count in
                    Button(action: {
                        withAnimation { config.lyricCount = count }
                    }) {
                        Text("\(count)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(config.lyricCount == count ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(config.lyricCount == count ? Color.white : Color.white.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(config.lyricCount == count ? Color.white : AivoTheme.Primary.orange.opacity(0.3), lineWidth: config.lyricCount == count ? 0 : 1)
                            )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Generate Button
    private var generateButton: some View {
        Button(action: { generateLyrics() }) {
            HStack(spacing: 12) {
                if isGenerating {
                    ProgressView()
                        .tint(.black)
                        .scaleEffect(0.8)
                }

                if !subscriptionManager.isPremium && remoteConfig.enableOneTimeFreeTry && !profileManager.hasUsedFreeLyricGeneration {
                    Text(isGenerating ? "Generating..." : "Generate First Lyric Free")
                        .font(.headline)
                        .fontWeight(.bold)
                } else {
                    Text(isGenerating ? "Generating..." : "Generate Lyrics")
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AivoTheme.Primary.orange)
            )
            .shadow(color: AivoTheme.Shadow.orange, radius: 10, x: 0, y: 0)
        }
        .disabled(config.prompt.isEmpty || isGenerating)
        .opacity((config.prompt.isEmpty || isGenerating) ? 0.5 : 1.0)
    }
    
    // MARK: - Components Helper
    private func selectionRow(title: String, items: [String], action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Button(action: action) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .padding(6)
                        .background(Circle().fill(AivoTheme.Primary.orange))
                        .foregroundColor(.black)
                }
            }
            
            if items.isEmpty {
                Text("Any")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(items, id: \.self) { item in
                            Text(item)
                                .font(.system(size: 13))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(Color.white.opacity(0.2)))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func menuPicker<T: RawRepresentable & Hashable>(title: String, selection: Binding<T>, options: [T]) -> some View where T.RawValue == String {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(action: { selection.wrappedValue = option }) {
                        HStack {
                            Text(option.rawValue)
                            if selection.wrappedValue == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selection.wrappedValue.rawValue)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.4)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.2), lineWidth: 1))
            }
        }
    }

    // MARK: - Actions
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func generateLyrics() {
        // Check premium status
        let isFreeTry = !subscriptionManager.isPremium && remoteConfig.enableOneTimeFreeTry && !profileManager.hasUsedFreeLyricGeneration

        if isFreeTry {
             performGeneration(isFreeTry: true)
             return
        }

        if !isFreeTry {
            guard subscriptionManager.isPremium else {
                showPremiumAlert = true
                return
            }
            
            // Check credits
            let baseCost = config.mode == .simple ? 10 : (config.mode == .custom ? 15 : 20)
            let totalCost = baseCost * config.lyricCount
            guard creditManager.credits >= totalCost else {
                showInsufficientCreditsAlert = true
                return
            }
        }
        
        performGeneration(isFreeTry: false)
    }
    
    private func performGeneration(isFreeTry: Bool) {
        hideKeyboard()
        isGenerating = true
        lyricsResults = []
        
        let baseCost = config.mode == .simple ? 10 : (config.mode == .custom ? 15 : 20)
        let totalCost = baseCost * config.lyricCount

        Logger.i("📝 [GenerateLyrics] Starting lyrics generation with Gemini...")
        
        // Log Firebase event
        AnalyticsLogger.shared.logEventWithBundle(AnalyticsLogger.EVENT.EVENT_GENERATE_LYRICS_START, parameters: [
            "mode": config.mode.rawValue,
            "count": config.lyricCount,
            "timestamp": Date().timeIntervalSince1970
        ])

        Task {
            do {
                // Use config directly
                let results = try await GeminiSongService.shared.generateLyrics(config: config)

                Logger.i("✅ [GenerateLyrics] Generated \(results.count) lyrics variations")

                await MainActor.run {
                    isGenerating = false
                    lyricsResults = results
                    showToastMessage("Lyrics generated successfully!")
                    
                    if isFreeTry {
                        ProfileManager.shared.setHasUsedFreeLyricGeneration(true)
                    } else {
                        // Deduct credits only after successful generation
                        Task {
                            await CreditManager.shared.deductForSuccessfulRequest(count: totalCost)
                            Logger.i("📝 [GenerateLyrics] Deducted \(totalCost) credits for successful lyrics generation")
                            // Save to history
                            CreditHistoryManager.shared.addRequest(.generateLyric)
                            
                            // Try to show rating dialog with delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                AppRatingManager.shared.tryShowRateApp()
                            }
                        }
                    }
                    
                    // Log Firebase success event
                    AnalyticsLogger.shared.logEventWithBundle(AnalyticsLogger.EVENT.EVENT_GENERATE_LYRICS_SUCCESS, parameters: [
                        "results_count": results.count,
                        "timestamp": Date().timeIntervalSince1970
                    ])
                    
                    // Show result screen
                    showResultScreen = true
                }
            } catch {
                Logger.e("❌ [GenerateLyrics] Error: \(error)")
                
                // Log Firebase failed event
                AnalyticsLogger.shared.logEventWithBundle(AnalyticsLogger.EVENT.EVENT_GENERATE_LYRICS_FAILED, parameters: [
                    "error_type": String(describing: type(of: error)),
                    "error_message": error.localizedDescription,
                    "timestamp": Date().timeIntervalSince1970
                ])
                
                await MainActor.run {
                    isGenerating = false
                    showToastMessage("Failed to generate lyrics: \(error.localizedDescription)")
                }
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

// MARK: - FlowLayout Helper
@available(iOS 16.0, *)
struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var height: CGFloat = 0
        for row in rows {
            if let maxHeight = row.map({ $0.sizeThatFits(.unspecified).height }).max() {
                height += maxHeight
            }
        }
        height += CGFloat(max(0, rows.count - 1)) * spacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for view in row {
                view.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += view.sizeThatFits(.unspecified).width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        var rows: [[LayoutSubviews.Element]] = [[]]
        var currentWidth: CGFloat = 0
        let maxWidth = proposal.width ?? 0

        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            if currentWidth + viewSize.width > maxWidth {
                rows.append([view])
                currentWidth = viewSize.width + spacing
            } else {
                rows[rows.count - 1].append(view)
                currentWidth += viewSize.width + spacing
            }
        }
        return rows
    }
}

// MARK: - Preview
struct GenerateLyricsScreen_Previews: PreviewProvider {
    static var previews: some View {
        GenerateLyricsScreen(lyrics: .constant(""), songName: .constant(""))
    }
}
