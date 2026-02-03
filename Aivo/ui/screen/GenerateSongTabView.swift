import SwiftUI

// MARK: - Generate Song Tab View
struct GenerateSongTabView: View {
    @ObservedObject private var creditManager = CreditManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var remoteConfig = RemoteConfigManager.shared
    
    private var creditsRequired: Int {
        generationMode.cost
    }
    @State private var selectedInputType: InputType = .description
    @State private var songDescription = ""
    @State private var songLyrics = ""
    @State private var selectedMoods: [SongMood] = []
    @State private var selectedGenres: [SongGenre] = []
    @State private var showMultiMoodScreen = false
    @State private var showMultiGenreScreen = false
    @State private var showGenerateSongScreen = false
    @State private var showSunoResultScreen = false
    @State private var resultSunoDataList: [SunoData] = []
    @State private var isAdvancedExpanded = false
    @State private var songName = ""
    @State private var isVocalEnabled = false
    @State private var selectedVocalGender: LocalVocalGender = .random
    @State private var isInstrumental = false
    @State private var selectedModel: SunoModel = .V5
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var showGenerateLyricsScreen = false
    // @State private var generatedLyrics: String = "" // Removed, using direct binding instead
    @State private var isBPMEnabled: Bool = false
    @State private var bpmValue: Double = 100
    @State private var generationTask: Task<Void, Never>?
    @State private var showPremiumAlert = false
    @ObservedObject private var backgroundManager = BackgroundGenerationManager.shared

    @State private var showSubscriptionScreen = false
    @State private var showArtistNameAlert = false
    @State private var selectedLanguage: String = "English"
    @State private var showBackgroundBusyAlert = false

    // MARK: - New Generation State
    @State private var generationMode: GenerationMode = .simple
    @State private var selectedStructure: Set<SongStructurePart> = [.verse, .chorus]
    
    // Vocal Options
    @State private var isVocalExpanded = false
    @State private var selectedVocalIntensity: VocalIntensity? = nil
    @State private var selectedVocalTexture: VocalTexture? = nil
    
    // Advanced Options
    @State private var selectedTempo: SongTempo? = nil
    @State private var selectedProductionStyle: ProductionStyle? = nil
    @State private var selectedMixPriority: MixPriority? = nil
    
    enum InputType: String, CaseIterable {
        case description = "Song Description"
        case lyrics = "Lyrics"
    }
    
    enum LocalVocalGender: String, CaseIterable {
        case male = "Male"
        case female = "Female"
        case random = "Random"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Song Input Section
                songInputSection
                
                // Mode Selection
                modeSelectionSection
                
                // Mood Selection
                moodSelectionSection
                
                // Genre Selection
                genreSelectionSection
                
                // Song Name
                songNameSection
                
                // Structure & Vocal (Custom / Advance)
                if generationMode == .custom || generationMode == .advanced {
                    structureSelectionSection
                    vocalOptionsSection
                }
                
                // Advanced Options (Advance Only)
                if generationMode == .advanced {
                    advancedOptionsSection
                }
                
                // Model Selection
                modelSelectionSection
                
                // Create Button
                createButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Space for bottom navigation
        }
        .onAppear {
            // Log screen view to both Firebase and AppsFlyer
            AnalyticsLogger.shared.logScreenView(AnalyticsLogger.EVENT.EVENT_SCREEN_GENERATE_SONG)
        }
        .fullScreenCover(isPresented: $showMultiMoodScreen) {
            SelectMultiMoodScreen(
                initialSelectedMoods: selectedMoods,
                onDone: { selectedMoods in
                    self.selectedMoods = selectedMoods
                },
                onCancel: {
                    // Do nothing, just dismiss
                }
            )
        }
        .fullScreenCover(isPresented: $showMultiGenreScreen) {
            SelectMultiGenreScreen(
                initialSelectedGenres: selectedGenres,
                onDone: { selectedGenres in
                    self.selectedGenres = selectedGenres
                },
                onCancel: {
                    // Do nothing, just dismiss
                }
            )
        }
        // GenerateSongProcessingScreen
        .fullScreenCover(isPresented: $showGenerateSongScreen) {
            GenerateSongProcessingScreen(
                requestType: .generateSong,
                onBackgroundProcess: {
                    // Just dismiss the screen, let task run in background
                    showGenerateSongScreen = false
                    showToastMessage("Generation continuing in background...")
                },
                onCancel: {
                    // Cancel generation process
                    Logger.i("⚠️ [GenerateSong] Generation cancelled by user")
                    backgroundManager.cancelGeneration()
                    showGenerateSongScreen = false
                    showToastMessage("Generation cancelled")
                }
            )
            .onChange(of: backgroundManager.isGenerating) { isGenerating in
                 // If generation stops (success or error) while this screen is open, dismiss it
                 if !isGenerating {
                     showGenerateSongScreen = false
                 }
            }
        }

        .fullScreenCover(isPresented: $showSunoResultScreen) {
            GenerateSunoSongResultScreen(
                sunoDataList: resultSunoDataList,
                onClose: {
                    showSunoResultScreen = false
                }
            )
        }
        .fullScreenCover(isPresented: $showGenerateLyricsScreen) {
            GenerateLyricsScreen(lyrics: $songLyrics, songName: $songName)
        }
        .fullScreenCover(isPresented: $showSubscriptionScreen) {
            SubscriptionScreenIntro()
//            if SubscriptionManager.shared.isPremium {
//                SubscriptionScreen()
//            } else {
//                SubscriptionScreenIntro()
//            }
        }
        .alert("Content Policy Violation", isPresented: $showArtistNameAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This content violates our policy due to the use of an artist name. Please remove it and try again.")
        }
        .alert("A task is already running", isPresented: $showBackgroundBusyAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please wait for the current generation task to finish before starting a new one.")
        }
        .onChange(of: backgroundManager.isGenerating) { isGenerating in
            if !isGenerating {
                if let error = backgroundManager.error {
                    if let sunoError = error as? SunoError, case .artistNameNotAllowed = sunoError {
                        showArtistNameAlert = true
                    } else {
                        showToastMessage(error.localizedDescription)
                    }
                }
            }
        }
        // Parsing logic removed. Bindings are updated directly in GenerateLyricsScreen.
        .overlay(
            // Toast Message
            VStack {
                Spacer()
                if showToast {
                    Text(toastMessage)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color.black.opacity(0.9))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 50)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: showToast)
                }
            }
        )
    }
    
    // MARK: - Song Input Section
    private var songInputSection: some View {
        // animation khi đổi tab & đổi chiều cao vùng nhập
        let expandAnim = Animation.spring(response: 0.35, dampingFraction: 0.9, blendDuration: 0.2)

        return VStack(spacing: 12) {
            // Input Type Tabs
            HStack(spacing: 0) {
                ForEach(InputType.allCases, id: \.self) { type in
                    Button {
                        withAnimation(expandAnim) {
                            selectedInputType = type
                        }
                    } label: {
                        Text(type.rawValue)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(selectedInputType == type ? .white : .white.opacity(0.7))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedInputType == type ? AivoTheme.Primary.orange : .clear)
                            )
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
            )

            // Input Field
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text(selectedInputType == .description ? "Describe the Song" : "Enter lyrics")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)

                    Spacer()

                    
                    Button(action: {
                        if selectedInputType == .lyrics {
                            showGenerateLyricsScreen = true
                        } else {
                            getInspired()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text(selectedInputType == .lyrics ? "Generate Lyrics" : "Get Inspired")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.12))
                        )
                    }
                    
                }
                .padding(.top, 0)
                
                let lyrics = """
                Verse 1:
                I still remember the rain on that night
                When you held my hand, and it all felt right
                We were two hearts learning how to beat
                Now I walk alone on this empty street
                
                Chorus:
                And I hope you're smiling where you are
                Even if we drifted far
                ...
                """

                let insets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
                let editorHeight: CGFloat = (selectedInputType == .description) ? 120 : 200
                let expandAnim = Animation.spring(response: 0.35, dampingFraction: 0.9, blendDuration: 0.2)

                ZStack(alignment: .topLeading) {
                    // Card nền
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.30))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AivoTheme.Primary.orange.opacity(0.30), lineWidth: 1)
                        )
                        .frame(height: editorHeight)
                        .animation(expandAnim, value: selectedInputType)

                    // Placeholder (đặt đúng vị trí theo insets)
                    Group {
                        if selectedInputType == .description, songDescription.isEmpty {
                            Text("Describe the music and topic you want (e.g. make a chill song about overcoming my biggest regret)")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.75)) // hint bớt mờ
                                .padding(EdgeInsets(top: insets.top, leading: insets.left, bottom: 0, trailing: insets.right))
                        } else if selectedInputType == .lyrics, songLyrics.isEmpty {
                            Text(lyrics)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.75))
                                .padding(EdgeInsets(top: insets.top, leading: insets.left, bottom: 0, trailing: insets.right))
                        }
                    }

                    // TextEditor đã tuỳ biến (căn top đúng, cuộn nội bộ)
                    if selectedInputType == .description {
                        PaddedTextEditor(text: $songDescription,
                                         font: .systemFont(ofSize: 14),
                                         textColor: .white,
                                         insets: insets,
                                         autocap: .sentences,
                                         autocorrect: true)
                        .frame(height: editorHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .animation(expandAnim, value: selectedInputType)
                        .onChange(of: songDescription) { newValue in
                            // Limit to 500 characters
                            if newValue.count > 500 {
                                songDescription = String(newValue.prefix(500))
                            }
                        }
                    } else {
                        PaddedTextEditor(text: $songLyrics,
                                         font: .systemFont(ofSize: 14),
                                         textColor: .white,
                                         insets: insets,
                                         autocap: .none,
                                         autocorrect: false)
                        .frame(height: editorHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .animation(expandAnim, value: selectedInputType)
                        .onChange(of: songLyrics) { newValue in
                            // Limit to 3000 characters
                            if newValue.count > 3000 {
                                songLyrics = String(newValue.prefix(3000))
                            }
                        }
                    }

                    // Counter dưới-phải (nằm trong khung, không tràn)
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("\(selectedInputType == .description ? songDescription.count : songLyrics.count) / \(selectedInputType == .description ? 500 : 3000)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.trailing, 10)
                                .padding(.bottom, 8)
                        }
                    }
                    .frame(height: editorHeight)
                }
                
                // Language Selection (only for description mode)
                if selectedInputType == .description {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Language")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        
                        TextField("Enter language (e.g., English, Vietnamese, Spanish)", text: $selectedLanguage)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black.opacity(0.30))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(AivoTheme.Primary.orange.opacity(0.30), lineWidth: 1)
                                    )
                            )
                    }
                    .padding(.top, 2)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.easeInOut(duration: 0.3), value: selectedInputType)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AivoTheme.Primary.orange, lineWidth: 1)
                )
        )
    }

    
    // MARK: - Mood Selection Section
    private var moodSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Mood (Optional)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(SongMood.getHottest().prefix(10), id: \.self) { mood in
                        Button(action: {
                            toggleMoodSelection(mood)
                        }) {
                            Text(mood.displayName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedMoods.contains(mood) ? AivoTheme.Secondary.coralRed : Color.gray.opacity(0.3))
                                )
                        }
                    }
                    
                    Button(action: {
                        showMultiMoodScreen = true
                    }) {
                        Text("More")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Genre Selection Section
    private var genreSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Genre (Optional)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(SongGenre.getHottest().prefix(10), id: \.self) { genre in
                        Button(action: {
                            toggleGenreSelection(genre)
                        }) {
                            VStack(spacing: 3) {
                                Image(genre.icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 72, height: 72)
                                    .clipShape(RoundedRectangle(cornerRadius: 8)) // 🟡 Bo góc ảnh
                                    .padding(.top, 4)
                                
                                Text(genre.displayName)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 86, height: 100)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedGenres.contains(genre) ?
                                          AivoTheme.Primary.orangeDark :
                                          Color.gray.opacity(0.3))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedGenres.contains(genre) ?
                                            AivoTheme.Primary.orange :
                                            Color.clear, lineWidth: 2)
                            )
                        }
                    }
                    
                    // Nút "More"
                    Button(action: {
                        showMultiGenreScreen = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                            
                            Text("More")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .frame(width: 88, height: 88)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    
    // MARK: - Mode Selection Section
    private var modeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Mode")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                HStack(spacing: 4) {
                    Text("\(generationMode.cost)")
                        .font(.system(size: 14, weight: .bold))
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 14))
                }
                .foregroundColor(.yellow)
            }
            
            HStack(spacing: 0) {
                let modes = GenerationMode.allCases
                ForEach(Array(modes.enumerated()), id: \.element) { index, mode in
                    Button(action: {
                        withAnimation { generationMode = mode }
                    }) {
                        Text(mode.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(generationMode == mode ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(generationMode == mode ? Color.white : Color.clear)
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

    // MARK: - Structure Selection Section
    private var structureSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Structure")
                .font(.system(size: 16, weight: .medium))
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
    }
    
    private var structureButtons: some View {
        ForEach(SongStructurePart.allCases.sorted { $0.order < $1.order }) { part in
            let isMandatory = (part == .verse || part == .chorus)
            let isSelected = selectedStructure.contains(part) || isMandatory
            
            Button(action: {
                if isMandatory { return }
                if selectedStructure.contains(part) {
                    if selectedStructure.count > 1 {
                        selectedStructure.remove(part)
                    }
                } else {
                    selectedStructure.insert(part)
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

    // MARK: - Vocal Options Section
    private var vocalOptionsSection: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                   isVocalExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Vocal Settings")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("🎤")
                        .font(.system(size: 16))
                    
                    Spacer()
                    
                    Image(systemName: isVocalExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if isVocalExpanded {
                VStack(spacing: 0) {
                    Divider().background(AivoTheme.Primary.orange.opacity(0.3)).padding(.bottom, 16)
                    
                    // Vocal Gender
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gender")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack(spacing: 6) {
                            ForEach(LocalVocalGender.allCases, id: \.self) { gender in
                                Button(action: {
                                    selectedVocalGender = gender
                                }) {
                                    Text(gender.rawValue)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(selectedVocalGender == gender ? .black : .white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedVocalGender == gender ? Color.white : Color.white.opacity(0.1))
                                        )
                                }
                            }
                        }
                    }
                    .padding(.bottom, 16)
                    .disabled(isInstrumental)
                    .opacity(isInstrumental ? 0.5 : 1.0)
                    
                    // Vocal Intensity
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Intensity")
                             .font(.system(size: 14, weight: .medium))
                             .foregroundColor(.white.opacity(0.8))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(VocalIntensity.allCases, id: \.self) { intensity in
                                    let isSelected = selectedVocalIntensity == intensity
                                    Button(action: {
                                        selectedVocalIntensity = isSelected ? nil : intensity
                                    }) {
                                        Text(intensity.rawValue)
                                            .font(.system(size: 13))
                                            .foregroundColor(isSelected ? .black : .white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(isSelected ? Color.white : Color.white.opacity(0.1))
                                            )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 16)
                    .disabled(isInstrumental)
                    .opacity(isInstrumental ? 0.5 : 1.0)
                    
                    // Vocal Texture
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Texture")
                             .font(.system(size: 14, weight: .medium))
                             .foregroundColor(.white.opacity(0.8))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(VocalTexture.allCases, id: \.self) { texture in
                                    let isSelected = selectedVocalTexture == texture
                                    Button(action: {
                                        selectedVocalTexture = isSelected ? nil : texture
                                    }) {
                                        Text(texture.rawValue)
                                            .font(.system(size: 13))
                                            .foregroundColor(isSelected ? .black : .white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(isSelected ? Color.white : Color.white.opacity(0.1))
                                            )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 16)
                    .disabled(isInstrumental)
                    .opacity(isInstrumental ? 0.5 : 1.0)
                    
                     
                     // Instrumental Toggle
                     Toggle(isOn: $isInstrumental) {
                         Text("Instrumental (No Vocals)")
                             .font(.system(size: 16, weight: .medium))
                             .foregroundColor(.white)
                     }
                     .toggleStyle(SwitchToggleStyle(tint: AivoTheme.Primary.orange))
                     .padding(.bottom, 16)
                }
                .padding(.horizontal, 16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.2))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AivoTheme.Primary.orange, lineWidth: 1))
        )
    }
    // MARK: - Song Name Section
    private var songNameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
             HStack {
                 Text("Song Name (Optional)")
                     .font(.system(size: 16, weight: .medium))
                     .foregroundColor(.white)
                 Spacer()
                 Text("\(songName.count) / 80")
                     .font(.system(size: 11))
                     .foregroundColor(.white.opacity(0.5))
             }
             
             TextField("Name", text: $songName)
                 .font(.system(size: 14))
                 .foregroundColor(.white)
                 .padding(12)
                 .background(
                     RoundedRectangle(cornerRadius: 8)
                         .fill(Color.white.opacity(0.1))
                 )
                 .onChange(of: songName) { newValue in
                     if newValue.count > 80 { songName = String(newValue.prefix(80)) }
                 }
        }
    }
    
    // MARK: - Model Selection Section
    private var modelSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Model")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SunoModel.allCases, id: \.self) { model in
                        Button(action: {
                            selectedModel = model
                        }) {
                            Text(model.rawValue)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selectedModel == model ? .black : .white)
                                .frame(minWidth: 50)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedModel == model ? AivoTheme.Primary.orange : Color.gray.opacity(0.3))
                                )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Advanced Options Section
    private var advancedOptionsSection: some View {
            VStack(spacing: 0) {
                // Main container that looks like a button when collapsed
                VStack(spacing: 0) {
                    // Header - always visible, full area clickable
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isAdvancedExpanded.toggle()
                        }
                    }) {
                        HStack {
                            Text("Advanced Options")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text("🥁")
                                .font(.system(size: 16))
                            
                            Spacer()
                            
                            Image(systemName: isAdvancedExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    // Expandable content
                    if isAdvancedExpanded {
                        VStack(spacing: 16) {
                            Divider()
                                .background(AivoTheme.Primary.orange.opacity(0.3))
                            
                            // Tempo Picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tempo")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(SongTempo.allCases, id: \.self) { tempo in
                                            let isSelected = selectedTempo == tempo
                                            Button(action: {
                                                selectedTempo = isSelected ? nil : tempo
                                            }) {
                                                Text(tempo.rawValue)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(isSelected ? .black : .white)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 8)
                                                    .background(
                                                        Capsule()
                                                            .fill(isSelected ? Color.white : Color.white.opacity(0.1))
                                                    )
                                            }
                                        }
                                    }
                                }
                                .disabled(isBPMEnabled)
                                .opacity(isBPMEnabled ? 0.5 : 1.0)
                            }
                            
                            // BPM Toggle + Slider
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("BPM (Beats Per Minute)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)

                                    
                                    Toggle("", isOn: $isBPMEnabled)
                                        .toggleStyle(SwitchToggleStyle(tint: AivoTheme.Primary.orange))
                                }

                                HStack(spacing: 12) {
                                    Text("40")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))

                                    Slider(value: $bpmValue, in: 40...200, step: 1)
                                        .accentColor(AivoTheme.Primary.orange)
                                        .disabled(!isBPMEnabled)

                                    Text("200")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .opacity(isBPMEnabled ? 1.0 : 0.5)

                                HStack {
                                    Spacer()
                                    Text("= \(Int(bpmValue)) bpm")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(isBPMEnabled ? AivoTheme.Secondary.goldenSun : .white.opacity(0.3))
                                }
                            }
                            
                            // Production Style
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Production Style")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(ProductionStyle.allCases, id: \.self) { style in
                                            let isSelected = selectedProductionStyle == style
                                            Button(action: {
                                                selectedProductionStyle = isSelected ? nil : style
                                            }) {
                                                Text(style.rawValue)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(isSelected ? .black : .white)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 8)
                                                    .background(
                                                        Capsule()
                                                            .fill(isSelected ? Color.white : Color.white.opacity(0.1))
                                                    )
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Mix Priority
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Mix Priority")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(MixPriority.allCases, id: \.self) { mix in
                                            let isSelected = selectedMixPriority == mix
                                            Button(action: {
                                                selectedMixPriority = isSelected ? nil : mix
                                            }) {
                                                Text(mix.rawValue)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(isSelected ? .black : .white)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 8)
                                                    .background(
                                                        Capsule()
                                                            .fill(isSelected ? Color.white : Color.white.opacity(0.1))
                                                    )
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AivoTheme.Primary.orange, lineWidth: 1)
                        )
                )
            }
        }
    
    // MARK: - Create Button
    private var createButton: some View {
        Button(action: {
            generateSong()
        }) {
            HStack(spacing: 8) {
                Text(selectedInputType == .description ? "Create with Description" : "Create with Lyrics")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                // Credit cost display
                HStack(spacing: 2) {
                    Text("(-\(creditsRequired)")
                        .font(.system(size: 16, weight: .semibold))
                    Image("icon_coin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                    Text(")")
                        .font(.system(size: 16, weight: .semibold))
                    
                }
                .foregroundColor(.black.opacity(0.8))
                
                .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AivoTheme.Primary.orange)
            )
        }
        .disabled(!isCreateButtonEnabled)
        .opacity((!isCreateButtonEnabled) ? 0.5 : 1.0)
    }
    
    private var hasEnoughCreditsForGenerate: Bool {
        return creditManager.credits >= creditsRequired
    }
    
    private var isCreateButtonEnabled: Bool {
        if selectedInputType == .description {
            return !songDescription.isEmpty
        } else {
            return !songLyrics.isEmpty
        }
    }
    
    // MARK: - Helper Methods
    private func generateSong() {
        // Check background generation status first
        if BackgroundGenerationManager.shared.isGenerating {
            showBackgroundBusyAlert = true
            return
        }
        
        // Check subscription first
        guard subscriptionManager.isPremium else {
            showSubscriptionScreen = true
            return
        }
        
        // Check credits before starting
        guard creditManager.credits >= creditsRequired else {
            showToastMessage("Not enough credits! You need \(creditsRequired) credits to generate a song.")
            return
        }
        
        print("🎵 [GenerateSong] Starting song generation via BackgroundManager...")
        
        // Log to both Firebase and AppsFlyer
        AnalyticsLogger.shared.logEventWithBundle(AnalyticsLogger.EVENT.EVENT_GENERATE_SONG_START, parameters: [
            "input_type": selectedInputType.rawValue,
            "has_song_name": !songName.isEmpty,
            "is_instrumental": isInstrumental,
            "model": selectedModel.rawValue,
            "moods_count": selectedMoods.count,
            "genres_count": selectedGenres.count,
            "timestamp": Date().timeIntervalSince1970
        ])
        
        // Build prompt and parameters
        let prompt = buildPrompt()
        let customMode = prompt.count > 500
        
        let style = selectedGenres.map { $0.displayName }.joined(separator: ", ")
        let finalStyle = style.isEmpty ? nil : style
        
        let vocalGender: VocalGender
        if isInstrumental {
            vocalGender = .male
        } else if selectedVocalGender == .random {
            vocalGender = Bool.random() ? .male : .female
        } else {
            vocalGender = selectedVocalGender == .male ? .male : .female
        }
        
        // Show processing screen
        showGenerateSongScreen = true
        
        // Start background generation
        BackgroundGenerationManager.shared.startGeneration(
            prompt: prompt,
            style: finalStyle,
            title: songName,
            customMode: customMode,
            instrumental: isInstrumental,
            model: selectedModel,
            vocalGender: vocalGender,
            selectedMoods: selectedMoods,
            selectedGenres: selectedGenres
        )
        // showToastMessage("Generation started in background! You can continue using the app.")
        
        // Note: Credit deduction handled by Manager/Server side logic or dependent on success?
        // Ideally we should deduct here? No, if it fails immediately in background we want to not deduct.
        // We will add deduction logic to BackgroundGenerationManager completion block later.
    }
    
    private func buildPrompt() -> String {
        var prompt = ""
        
        // 1. Core Request & Genre
        let genreData = selectedGenres.map { $0.displayName }.joined(separator: ", ")
        let genreText = selectedGenres.isEmpty ? "" : " \(genreData)"
        
        prompt += "Create a\(genreText) song"
        
        // 2. Mood
        if !selectedMoods.isEmpty {
            let moodData = selectedMoods.map { $0.displayName }.joined(separator: ", ")
            prompt += " with \(moodData) mood"
        }
        
        // 3. Vocals (New)
        if isInstrumental {
            prompt += ", instrumental"
        } else {
            var vocalTerms: [String] = []
            
            // Gender
            if selectedVocalGender != .random {
                vocalTerms.append(selectedVocalGender.rawValue)
            }
            
            // Intensity
            if let intensity = selectedVocalIntensity, intensity != .random {
                vocalTerms.append(intensity.rawValue.lowercased())
            }
            
            // Texture
            if let texture = selectedVocalTexture, texture != .random {
                vocalTerms.append(texture.rawValue.lowercased())
            }
            
            if !vocalTerms.isEmpty {
                prompt += ", featuring " + vocalTerms.joined(separator: " ") + " vocals"
            }
        }
        
        // 4. Production & Mix (New)
        if let style = selectedProductionStyle {
            prompt += ", \(style.rawValue) production"
        }
        
        if let priority = selectedMixPriority {
            prompt += ", \(priority.rawValue) mix"
        }
        
        // 5. Structure
        if (generationMode == .custom || generationMode == .advanced) && !selectedStructure.isEmpty {
             let parts = selectedStructure.sorted { $0.order < $1.order }.map { $0.rawValue }
             prompt += ", structure: (" + parts.joined(separator: ", ") + ")"
        }
        
        // 6. Tempo (Updated)
        if isBPMEnabled {
            prompt += ", tempo: \(Int(bpmValue)) BPM"
        } else if let tempo = selectedTempo {
            prompt += ", \(tempo.rawValue) tempo"
        }
        
        prompt += ". "
        
        // 7. User Description
        if !songDescription.isEmpty {
            prompt += songDescription + ". "
        }
        
        // 8. Lyrics Handling
        if selectedInputType == .description {
             if !selectedLanguage.isEmpty {
                 prompt += "\nNote: Generate the song in \(selectedLanguage) language."
             }
        } else if selectedInputType == .lyrics && !songLyrics.isEmpty {
             prompt += "\nLyric of song:\n"
             if !songLyrics.trimmingCharacters(in: .whitespaces).hasPrefix("[") {
                 prompt += "[Verse]\n" + songLyrics
             } else {
                 prompt += songLyrics
             }
        }
        
        return prompt
    }
    
    private func toggleMoodSelection(_ mood: SongMood) {
        if selectedMoods.contains(mood) {
            selectedMoods.removeAll { $0 == mood }
        } else {
            if selectedMoods.count >= 3 {
                selectedMoods.removeFirst()
            }
            selectedMoods.append(mood)
        }
    }
    
    private func toggleGenreSelection(_ genre: SongGenre) {
        if selectedGenres.contains(genre) {
            selectedGenres.removeAll { $0 == genre }
        } else {
            if selectedGenres.count >= 5 {
                selectedGenres.removeFirst()
            }
            selectedGenres.append(genre)
        }
    }
    
    private func getInspired() {
        print("💡 [GetInspired] Loading sample prompts...")
        
        // Use prompts from RemoteConfigManager (loaded from remote or local)
        let prompts = remoteConfig.sampleSongPrompts
        
        if !prompts.isEmpty {
            if let randomPrompt = prompts.randomElement() {
                print("💡 [GetInspired] Selected prompt: \(randomPrompt)")
                songDescription = randomPrompt
                //showToastMessage("Inspiration loaded!")
            } else {
                print("❌ [GetInspired] No prompts found in list")
                showToastMessage("No inspiration prompts available")
            }
        } else {
            print("❌ [GetInspired] No prompts available")
            showToastMessage("Could not load inspiration prompts")
        }
    }
    
    private func showToastMessage(_ message: String) {
        toastMessage = message
        showToast = true
        
        // Longer timeout for detailed error messages
        let timeout = message.contains("⚠️") ? 8.0 : 3.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            showToast = false
        }
    }
}

// MARK: - PaddedTextEditor
struct PaddedTextEditor: UIViewRepresentable {
    @Binding var text: String
    var font: UIFont = .systemFont(ofSize: 14)
    var textColor: UIColor = .white
    var insets: UIEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    var autocap: UITextAutocapitalizationType = .sentences
    var autocorrect: Bool = true

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.backgroundColor = .clear
        tv.textContainerInset = insets
        tv.textContainer.lineFragmentPadding = 0
        tv.isScrollEnabled = true
        tv.alwaysBounceVertical = true
        tv.showsVerticalScrollIndicator = true
        tv.font = font
        tv.textColor = textColor
        tv.autocapitalizationType = autocap
        tv.autocorrectionType = autocorrect ? .yes : .no
        tv.delegate = context.coordinator
        
        // Add toolbar with Done button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: context.coordinator, action: #selector(Coordinator.dismissKeyboard))
        doneButton.tintColor = .black
        toolbar.items = [flexSpace, doneButton]
        tv.inputAccessoryView = toolbar
        
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        uiView.font = font
        uiView.textColor = textColor
        uiView.textContainerInset = insets
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: PaddedTextEditor
        init(_ parent: PaddedTextEditor) { self.parent = parent }
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text ?? ""
        }
        @objc func dismissKeyboard() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

// MARK: - Preview
struct GenerateSongTabView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AivoSunsetBackground()
            GenerateSongTabView()
        }
    }
}
