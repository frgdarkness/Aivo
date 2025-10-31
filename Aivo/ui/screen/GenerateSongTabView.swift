import SwiftUI

// MARK: - Generate Song Tab View
struct GenerateSongTabView: View {
    @ObservedObject private var creditManager = CreditManager.shared
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
    @State private var generatedLyrics: String = ""
    @State private var isBPMEnabled: Bool = false
    @State private var bpmValue: Double = 100
    
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
                
                // Mood Selection
                moodSelectionSection
                
                // Genre Selection
                genreSelectionSection
                
                // Advanced Options
                advancedOptionsSection
                
                // Create Button
                createButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Space for bottom navigation
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
        .fullScreenCover(isPresented: $showGenerateSongScreen) {
            GenerateSongProcessingScreen(
                requestType: .generateSong,
                onComplete: {
                    showGenerateSongScreen = false
                }
            )
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
            GenerateLyricsScreen(lyricsText: $generatedLyrics)
        }
        .onChange(of: generatedLyrics) { newValue in
            if !newValue.isEmpty {
                // Parse format: [Title]\n\nLyrics
                if newValue.hasPrefix("[") && newValue.contains("]\n\n") {
                    let components = newValue.components(separatedBy: "]\n\n")
                    if components.count == 2 {
                        let title = String(components[0].dropFirst()) // Remove "["
                        let lyrics = components[1]
                        
                        songName = title
                        songLyrics = lyrics
                        
                        Logger.i("📝 [GenerateSong] Parsed title: \(title)")
                        Logger.i("📝 [GenerateSong] Parsed lyrics length: \(lyrics.count)")
                    } else {
                        songLyrics = newValue
                    }
                } else {
                    songLyrics = newValue
                }
                Logger.i("📝 [GenerateSong] Filled lyrics from generated result")
            }
        }
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

    
    // MARK: - Advanced Options Section
    private var advancedOptionsSection: some View {
            VStack(spacing: 0) {
                // Main container that looks like a button when collapsed
                VStack(spacing: 0) {
                    // Header - always visible
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
                    }
                    .buttonStyle(.plain)
                    
                    // Expandable content
                    if isAdvancedExpanded {
                        VStack(spacing: 16) {
                            Divider()
                                .background(AivoTheme.Primary.orange.opacity(0.3))
                            
                            // Song Name
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Song Name (Optional)")
                                        .font(.system(size: 14, weight: .medium))
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
                                        // Limit to 80 characters
                                        if newValue.count > 80 {
                                            songName = String(newValue.prefix(80))
                                        }
                                    }
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

                            // Instrumental Toggle
                            HStack {
                                Text("Instrumental")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Toggle("", isOn: $isInstrumental)
                                    .toggleStyle(SwitchToggleStyle(tint: AivoTheme.Primary.orange))
                                    .onChange(of: isInstrumental) { newValue in
                                        if newValue {
                                            selectedVocalGender = .random
                                        }
                                    }
                            }
                                
                            // Vocal Gender - Disabled when instrumental
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Vocal Gender")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 6) {
                                    ForEach(LocalVocalGender.allCases, id: \.self) { gender in
                                        Button(action: {
                                            if !isInstrumental {
                                                selectedVocalGender = gender
                                            }
                                        }) {
                                            Text(gender.rawValue)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(selectedVocalGender == gender ? .black : .white)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(selectedVocalGender == gender ? AivoTheme.Primary.orange : Color.gray.opacity(0.3))
                                                )
                                        }
                                        .disabled(isInstrumental)
                                        .opacity(isInstrumental ? 0.5 : 1.0)
                                    }
                                }
                            }
                            
                            // Model Selection
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Model")
                                    .font(.system(size: 14, weight: .medium))
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
                                                    .frame(minWidth: 50) // Min width để các item có cùng kích thước
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 12)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(selectedModel == model ? AivoTheme.Primary.orange : Color.gray.opacity(0.3))
                                                    )
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 4)
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
                    Text("(-20")
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
        .disabled(!isCreateButtonEnabled || !hasEnoughCreditsForGenerate)
        .opacity((!isCreateButtonEnabled || !hasEnoughCreditsForGenerate) ? 0.5 : 1.0)
    }
    
    private var hasEnoughCreditsForGenerate: Bool {
        return creditManager.credits >= 20
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
        // Check credits before starting
        guard creditManager.credits >= 20 else {
            showToastMessage("Not enough credits! You need 20 credits to generate a song.")
            return
        }
        
        print("🎵 [GenerateSong] Starting song generation...")
        print("🎵 [GenerateSong] Input type: \(selectedInputType.rawValue)")
        print("🎵 [GenerateSong] Description: \(songDescription)")
        print("🎵 [GenerateSong] Lyrics: \(songLyrics)")
        print("🎵 [GenerateSong] Moods: \(selectedMoods.map { $0.displayName })")
        print("🎵 [GenerateSong] Genres: \(selectedGenres.map { $0.displayName })")
        print("🎵 [GenerateSong] Song name: \(songName)")
        print("🎵 [GenerateSong] Vocal gender: \(selectedVocalGender.rawValue)")
        print("🎵 [GenerateSong] Model: \(selectedModel.rawValue)")
        
        // Show processing screen
        showGenerateSongScreen = true
        
        // Start generation in background
        Task {
            do {
                let sunoService = SunoAiMusicService.shared
                
                // Build prompt based on input type
                let prompt = buildPrompt()
                let promptLength = prompt.count
                print("🎵 [GenerateSong] Generated prompt (length: \(promptLength)): \(prompt)")
                
                // Check if we need custom mode (prompt > 500 characters)
                let customMode = promptLength > 500
                print("🎵 [GenerateSong] Custom mode: \(customMode)")
                
                // Build style from selected genres (join with comma)
                let style = selectedGenres.map { $0.displayName }.joined(separator: ", ")
                let finalStyle = style.isEmpty ? "Pop" : style
                print("🎵 [GenerateSong] Style: \(finalStyle)")
                
                // Determine vocal gender for API
                let vocalGender: VocalGender
                if isInstrumental {
                    vocalGender = .male // Default for instrumental, will be overridden by instrumental=true
                } else if selectedVocalGender == .random {
                    vocalGender = Bool.random() ? .male : .female
                } else {
                    vocalGender = selectedVocalGender == .male ? .male : .female
                }
                
                print("🎵 [GenerateSong] Calling SunoAiMusicService.generateMusicWithRetry...")
                print("🎵 [GenerateSong] Vocal gender: \(vocalGender.rawValue)")
                print("🎵 [GenerateSong] Instrumental: \(isInstrumental)")
                
                let generatedSongs = try await sunoService.generateMusicWithRetry(
                    prompt: prompt,
                    style: finalStyle,
                    title: songName.isEmpty ? "" : songName,
                    customMode: customMode,
                    instrumental: isInstrumental,
                    model: selectedModel
                )
                
                print("🎵 [GenerateSong] Successfully generated \(generatedSongs.count) songs")
                for (index, song) in generatedSongs.enumerated() {
                    print("🎵 [GenerateSong] Song \(index + 1): \(song.title)")
                }
                
                await MainActor.run {
                    // Close processing screen
                    showGenerateSongScreen = false
                    
                    // Set result and show result screen
                    resultSunoDataList = generatedSongs
                    showToastMessage("Songs generated successfully!")
                    print("🎵 [GenerateSong] Showing result screen...")
                    
                    // Deduct credits only after successful generation
                    Task {
                        await CreditManager.shared.deductForSuccessfulRequest(count: 20)
                        Logger.i("🎵 [GenerateSong] Deducted 20 credits for successful generation")
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showSunoResultScreen = true
                    }
                }
                
            } catch let error as SunoError {
                print("❌ [GenerateSong] Error generating songs: \(error)")
                await MainActor.run {
                    showGenerateSongScreen = false
                    
                    // Show specific error message based on error type
                    let errorMessage: String
                    switch error {
                    case .artistNameNotAllowed:
                        errorMessage = "⚠️ Artist names are not allowed!\n\nPlease remove artist names from your song description and try again.\n\nExample:\n❌ \"Create a song like Ed Sheeran\"\n✅ \"Create a romantic acoustic ballad\""
                    default:
                        errorMessage = "Failed to generate songs: \(error.localizedDescription)"
                    }
                    
                    showToastMessage(errorMessage)
                }
            } catch {
                print("❌ [GenerateSong] Error generating songs: \(error)")
                await MainActor.run {
                    showGenerateSongScreen = false
                    showToastMessage("Failed to generate songs: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func buildPrompt() -> String {
        var prompt = ""
        
        // If lyrics tab is selected and has lyrics, use only lyrics
        if selectedInputType == .lyrics && !songLyrics.isEmpty {
            // Check if lyrics doesn't start with [
            
            // Add genres
            
            let genreData = selectedGenres.map { $0.displayName }.joined(separator: ", ")
            let genreText = selectedGenres.isEmpty ? "" : " (\(genreData))"
            prompt += "Create a\(genreText) song"
            
            
            let moodData = selectedMoods.map { $0.displayName }.joined(separator: ", ")
            let moodText = selectedMoods.isEmpty ? "" : "(\(moodData))"
            prompt += self.selectedMoods.isEmpty ? "" : " with \(moodText) mood"
            
            if isBPMEnabled {
                prompt += ", tempo: \(Int(bpmValue)) BPM"
            }
            
            if (!prompt.isEmpty) {
                prompt += ". "
            }
            
            if !songDescription.isEmpty {
                prompt += songDescription
            }
            prompt += "\nLyric of song:\n"
                        
            if !songLyrics.trimmingCharacters(in: .whitespaces).hasPrefix("[") {
                prompt += "[Verse]\n" + songLyrics
            } else {
                prompt += songLyrics
            }
            
        } else {
            // Add genres
            let genreData = selectedGenres.map { $0.displayName }.joined(separator: ", ")
            let genreText = selectedGenres.isEmpty ? "" : " (\(genreData))"
            prompt += "Create a\(genreText) song"
            
            
            let moodData = selectedMoods.map { $0.displayName }.joined(separator: ", ")
            let moodText = selectedMoods.isEmpty ? "" : "(\(moodData))"
            prompt += self.selectedMoods.isEmpty ? "" : " with \(moodText) mood"
            
            if isBPMEnabled {
                prompt += ", tempo: \(Int(bpmValue)) BPM"
            }
            
            if (!prompt.isEmpty) {
                prompt += ". "
            }
            
            if !songDescription.isEmpty {
                prompt += songDescription
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
        
        guard let url = Bundle.main.url(forResource: "sample_song_prompt", withExtension: "json") else {
            print("❌ [GetInspired] Could not find sample_song_prompt.json")
            showToastMessage("Could not load inspiration prompts")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let prompts = try JSONDecoder().decode([String].self, from: data)
            
            if let randomPrompt = prompts.randomElement() {
                print("💡 [GetInspired] Selected prompt: \(randomPrompt)")
                songDescription = randomPrompt
                showToastMessage("Inspiration loaded!")
            } else {
                print("❌ [GetInspired] No prompts found in file")
                showToastMessage("No inspiration prompts available")
            }
        } catch {
            print("❌ [GetInspired] Error loading prompts: \(error)")
            showToastMessage("Failed to load inspiration prompts")
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
