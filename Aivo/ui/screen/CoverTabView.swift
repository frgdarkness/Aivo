import SwiftUI
import Kingfisher

// MARK: - Cover Tab View
struct CoverTabView: View {
    @State private var selectedSong = ""
    @State private var songName = ""  // Add song name state
    @State private var lyric: String = ""
    @State private var selectedVoiceType: VoiceType = .otherVoice
    @State private var youtubeUrl = ""
    @State private var selectedLanguage: CoverLanguage = .english
    @State private var selectedModel: CoverSongModel? = nil
    @State private var availableModels: [CoverSongModel] = []
    @State private var showProcessingScreen = false
    @State private var showPlaySongScreen = false
    @State private var resultAudioUrl: String?
    @State private var cachedSunoData: SunoData?
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var verifiedYouTubeURL: String?
    @State private var isVerifyingYouTube = false
    @State private var youtubeVerificationStatus: VerificationStatus = .none
    @State private var showSongSelectionDialog = false
    @State private var selectedSongForCover: SelectedSong? = nil
    @State private var selectedAudioFileURL: URL? = nil
    @State private var showModelSelectionScreen = false
    
    enum SourceType { case song, youtube }
    @State private var selectedSource: SourceType = .song
    
    enum VerificationStatus {
        case none
        case verifying
        case success
        case failed
    }
    
    var body: some View {
        let _ = onAppear {
            if availableModels.isEmpty {
                availableModels = CoverSongModel.loadModels()
            }
        }
        
        return Group {
        ScrollView {
            VStack(spacing: 24) {
                // Song Selection (Card-Tab đơn giản)
                songSelectionSection

                // Song Name Input
                songNameSection

                // Language Selection
                languageSelectionSection

                // Model Selection
                modelSelectionSection

                // Generate Button
                generateButton

                Spacer(minLength: 100) // Space for bottom nav
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .fullScreenCover(isPresented: $showProcessingScreen) {
            GenerateSongProcessingScreen(
                requestType: .coverSong,
                onComplete: {
                    showProcessingScreen = false
                }
            )
        }
        .fullScreenCover(isPresented: $showPlaySongScreen) {
            if let sunoData = cachedSunoData {
                GenerateSunoSongResultScreen(
                    sunoDataList: [sunoData],
                    onClose: {
                        showPlaySongScreen = false
                        // Clear form data after closing result screen
                        clearFormData()
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showModelSelectionScreen) {
            SelectModelScreen(
                availableModels: availableModels,
                initialSelected: selectedModel,
                onDone: { model in
                    if let model = model {
                        // If the selected model is beyond the first 8, move it to the front
                        if let currentIndex = availableModels.firstIndex(where: { $0.id == model.id }) {
                            if currentIndex >= 8 {
                                var reordered = availableModels
                                let picked = reordered.remove(at: currentIndex)
                                reordered.insert(picked, at: 0)
                                availableModels = reordered
                            }
                        } else {
                            // In case model not present (safety), insert at front
                            availableModels.insert(model, at: 0)
                        }
                        selectedModel = model
                    } else {
                        selectedModel = nil
                    }
                    showModelSelectionScreen = false
                },
                onCancel: {
                    showModelSelectionScreen = false
                }
            )
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
            if availableModels.isEmpty {
                availableModels = CoverSongModel.loadModels()
                Logger.i("📋 [CoverTab] Loaded \(availableModels.count) cover models")
            }
        }
        .songSelectionDialog(
            isPresented: $showSongSelectionDialog,
            onSelectSong: { selectedSong, audioFileURL in
                selectedSongForCover = selectedSong
                selectedAudioFileURL = audioFileURL
                
                // Auto-fill song name if empty
                songName = selectedSong.title + " (cover)"
                lyric = selectedSong.sunoData?.prompt ?? ""
                
                Logger.i("🎵 [CoverTab] Selected song: \(selectedSong.title)")
                Logger.i("🎵 [CoverTab] Auto-filled song name: \(songName)")
                if let fileURL = audioFileURL {
                    Logger.d("📁 [CoverTab] Audio file URL: \(fileURL.path)")
                }
            }
        )
        }
    }

    // MARK: - Song Selection Section
    private var songSelectionSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // === Tabs ===
            HStack(alignment: .bottom, spacing: 0) {
                TagLabel(
                    title: "Pick a Song",
                    isSelected: selectedSource == .song,
                    selectedColor: AivoTheme.Primary.orange
                ) {
                    selectedSource = .song
                    //withAnimation(.easeInOut(duration: 0.25)) { selectedSource = .song }
                }
                .zIndex(selectedSource == .song ? 1 : 0)

                TagLabel(
                    title: "Youtube",
                    isSelected: selectedSource == .youtube,
                    selectedColor: AivoTheme.Secondary.goldenSun
                ) {
                    selectedSource = .youtube
                    //withAnimation(.easeInOut(duration: 0.25)) { selectedSource = .youtube }
                }
                .padding(.leading, -8)
                .zIndex(selectedSource == .youtube ? 1 : 0)

                Spacer()
            }

            // Thanh nhỏ cam phía dưới (giữ nguyên nếu bạn thích)
            Rectangle()
                .fill(AivoTheme.Primary.orange)
                .frame(width: 40, height: 20)
                .padding(.top, -10)

            // === CARD NỘI DUNG ===
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AivoTheme.Primary.orange, lineWidth: 1)
                )
                .overlay(
                    Group {
                        if selectedSource == .song {
                            // 📀 Trường hợp PICK A SONG
                            Button(action: {
                                showSongSelectionDialog = true
                            }) {
                                Text(selectedSongForCover?.title ?? "Click to select a song")
                                    .font(.headline.weight(.semibold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        } else {
                            // 🎥 Trường hợp YOUTUBE
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Copy youtube link to here:")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    // Verification icon
                                    if youtubeVerificationStatus != .none {
                                        Image(systemName: youtubeVerificationStatus == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(youtubeVerificationStatus == .success ? .green : .red)
                                    }
                                }

                                HStack(spacing: 8) {
                                    TextField("https://www.youtube.com/watch?v=...", text: $selectedSong)
                                        .foregroundColor(.white)
                                        .padding(10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.gray.opacity(0.25))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(youtubeVerificationStatus == .success ? Color.green.opacity(0.3) : (youtubeVerificationStatus == .failed ? Color.red.opacity(0.3) : AivoTheme.Primary.orange.opacity(0.3)), lineWidth: 1)
                                        )
                                        .disabled(youtubeVerificationStatus == .verifying)
                                    
                                    Button(action: {
                                        verifyYouTubeLink()
                                    }) {
                                        if isVerifyingYouTube {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            Text("Verify")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.black)
                                        }
                                    }
                                    .frame(width: 60, height: 38)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(youtubeVerificationStatus == .success ? Color.green.opacity(0.8) : AivoTheme.Primary.orange)
                                    )
                                    .disabled(isVerifyingYouTube)
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                )
                .frame(maxWidth: .infinity, minHeight: 120)
                .padding(.top, -10)
        }
    }

    // MARK: - Song Name Section
    private var songNameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New Song Name (Optional)")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 8) {
                TextField("", text: $songName)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(16)
                    
                
                if !songName.isEmpty {
                    Button(action: {
                        songName = ""
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18))
                            .foregroundColor(.red.opacity(0.8))
                    }.padding(.trailing, 12)
                }
            }.background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AivoTheme.Primary.orange.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Language Selection Section
    private var languageSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Language")
                .font(.headline)
                .foregroundColor(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CoverLanguage.allCases, id: \.self) { language in
                        Button(action: { selectedLanguage = language }) {
                            Text(language.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(selectedLanguage == language ? .black : .white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedLanguage == language ? AivoTheme.Primary.orange : Color.gray.opacity(0.3))
                                )
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Model Selection Section (Replaces Artist Selection)
    private var modelSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Voice Model")
                .font(.headline)
                .foregroundColor(.white)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 6) {
                ForEach(Array(availableModels.prefix(8))) { model in
                    Button(action: { 
                        selectedModel = selectedModel?.id == model.id ? nil : model 
                    }) {
                        VStack(spacing: 4) {
                            KFImage(URL(string: model.thumbUrl))
                                .placeholder { ProgressView().frame(width: 70, height: 70) }
                                .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 120, height: 120)))
                                .loadDiskFileSynchronously()
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            Text(model.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .frame(width: 90, height: 110)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.3))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedModel?.id == model.id ? AivoTheme.Primary.orange : Color.clear, lineWidth: 3)
                        )
                    }
                }
                if availableModels.count > 8 {
                    Button(action: { showModelSelectionScreen = true }) {
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.3))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "ellipsis")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                            Text("More")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .frame(width: 90, height: 110)
                    }
                }
            }
        }
    }

    // MARK: - Generate Button
    private var generateButton: some View {
        Button(action: {
            if isGenerateEnabled {
                generateCoverSong()
            }
        }) {
            HStack(spacing: 8) {
                Text("Generate")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                Image(systemName: "mic.fill")
                    .font(.title3)
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AivoTheme.Primary.orange)
            .cornerRadius(12)
            .disabled(!isGenerateEnabled)
            .opacity(isGenerateEnabled ? 1.0 : 0.5)
            .shadow(color: isGenerateEnabled ? AivoTheme.Shadow.orange : Color.clear, radius: 10, x: 0, y: 0)
        }
        .disabled(!isGenerateEnabled)
    }
    
    // MARK: - Helper Properties
    private var isGenerateEnabled: Bool {
        if selectedSource == .song {
            return selectedSongForCover != nil && selectedModel != nil
        } else {
            // YouTube cần verify thành công
            return youtubeVerificationStatus == .success && verifiedYouTubeURL != nil
        }
    }

    // MARK: - Actions
    private func generateCoverSong() {
        Logger.i("🎤 [CoverTab] Starting cover song generation...")
        Logger.d("🎤 [CoverTab] Source: \(selectedSource == .song ? "Song" : "YouTube")")
        Logger.d("🎤 [CoverTab] Song Name: \(songName)")
        Logger.d("🎤 [CoverTab] Selected Model: \(selectedModel?.displayName ?? "None")")
        Logger.d("🎤 [CoverTab] Model ID: \(selectedModel?.modelName ?? "default")")
        
        // Show processing screen
        showProcessingScreen = true
        
        // Start generation in background
        Task {
            do {
                let modelsLabService = ModelsLabService.shared
                let coverModelID = selectedModel?.modelName ?? "arianagrande"
                let resultUrl: String?
                
                // Handle different sources
                if selectedSource == .song {
                    // Pick a Song flow - need to process selected song
                    guard let selectedSong = selectedSongForCover else {
                        Logger.e("❌ [CoverTab] No song selected")
                        await MainActor.run {
                            showProcessingScreen = false
                            showToastMessage("Please select a song")
                        }
                        return
                    }
                    
                    Logger.i("🎵 [CoverTab] Selected song: \(selectedSong.title)")
                    
                    // Check if song has audio file from device picker
                    if let deviceFileURL = selectedAudioFileURL {
                        Logger.d("📁 [CoverTab] Using audio file from device picker")
                        do {
                            _ = deviceFileURL.startAccessingSecurityScopedResource()
                            defer { deviceFileURL.stopAccessingSecurityScopedResource() }
                            
                            let fileData = try Data(contentsOf: deviceFileURL)
                            let fileName = deviceFileURL.lastPathComponent
                            
                            resultUrl = await modelsLabService.processVoiceCoverWithFile(
                                fileData: fileData,
                                fileName: fileName,
                                modelID: coverModelID
                            )
                        } catch {
                            Logger.e("❌ [CoverTab] Error reading file from device: \(error)")
                            await MainActor.run {
                                showProcessingScreen = false
                                showToastMessage("Error reading audio file")
                            }
                            return
                        }
                    // Check if song has local audio file
                    } else if let localURL = getLocalAudioURL(for: selectedSong) {
                        Logger.d("📁 [CoverTab] Using local audio file")
                        let fileData = try Data(contentsOf: localURL)
                        let fileName = "\(selectedSong.title).mp3"
                        
                        resultUrl = await modelsLabService.processVoiceCoverWithFile(
                            fileData: fileData,
                            fileName: fileName,
                            modelID: coverModelID
                        )
                    } else if let audioUrl = selectedSong.audioUrl {
                        Logger.d("🔗 [CoverTab] Using remote audio URL")
                        resultUrl = await modelsLabService.processVoiceCover(
                            audioUrl: audioUrl,
                            modelID: coverModelID
                        )
                    } else {
                        Logger.e("❌ [CoverTab] No audio URL or file available")
                        await MainActor.run {
                            showProcessingScreen = false
                            showToastMessage("Song has no audio available")
                        }
                        return
                    }
                    
                } else {
                    // YouTube flow
                    guard let normalizedURL = verifiedYouTubeURL else {
                        Logger.e("❌ [CoverTab] No verified URL available")
                        await MainActor.run {
                            showProcessingScreen = false
                            showToastMessage("Please verify YouTube URL first")
                        }
                        return
                    }
                    
                    Logger.i("🔗 [CoverTab] Using verified URL: \(normalizedURL)")
                    
                    resultUrl = await modelsLabService.processVoiceCover(
                        audioUrl: normalizedURL,
                        modelID: coverModelID
                    )
                }
                
                Logger.i("🎤 [CoverTab] Cover song generated successfully!")
                Logger.d("🎤 [CoverTab] Result URL: \(resultUrl ?? "nil")")
                
                await MainActor.run {
                    // Close processing screen
                    showProcessingScreen = false
                    
                    if let resultUrl = resultUrl {
                        // Create and cache SunoData
                        cachedSunoData = createSunoDataFromCoverResult(audioUrl: resultUrl)
                        //resultAudioUrl = resultUrl
                        showToastMessage("Cover song generated successfully!")
                        
                        Logger.i("🎵 [CoverTab] Opening GenerateSunoSongResultScreen with cover result")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            showPlaySongScreen = true
                        }
                    } else {
                        showToastMessage("Failed to generate cover song")
                    }
                }
                
            } catch {
                Logger.e("❌ [CoverTab] Error generating cover song: \(error)")
                await MainActor.run {
                    showProcessingScreen = false
                    showToastMessage("Failed to generate cover song: \(error.localizedDescription)")
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
    
    // MARK: - Helper Methods
    private func verifyYouTubeLink() {
        Logger.i("🔍 [CoverTab] Verifying YouTube link: \(selectedSong)")
        
        isVerifyingYouTube = true
        youtubeVerificationStatus = .verifying
        
        Task {
            // Step 1: Normalize URL
            if let normalizedURL = YouTubeUtils.normalizeYouTubeURL(selectedSong) {
                Logger.d("✅ [CoverTab] URL normalized successfully: \(normalizedURL)")
                
                // Step 2: Fetch metadata to verify link works
                do {
                    let (title, channel, _) = try await YouTubeUtils.fetchYouTubeBasicMeta(url: normalizedURL)
                    
                    // Step 3: Extract song info
                    let (artist, song) = YouTubeUtils.splitArtistTitle(from: title)
                    let finalSongName = song ?? title
                    
                    Logger.i("✅ [CoverTab] YouTube link verified successfully")
                    Logger.d("🎵 [CoverTab] Title: \(title)")
                    Logger.d("🎵 [CoverTab] Extracted song: \(finalSongName)")
                    
                    await MainActor.run {
                        verifiedYouTubeURL = normalizedURL
                        youtubeVerificationStatus = .success
                        isVerifyingYouTube = false
                        
                        // Auto-fill song name if empty
                        
                        songName = finalSongName + " (cover)"
                        Logger.i("🎵 [CoverTab] Auto-filled song name: \(songName)")
                        
                    }
                    
                } catch {
                    Logger.e("❌ [CoverTab] Error fetching metadata: \(error)")
                    await MainActor.run {
                        youtubeVerificationStatus = .failed
                        isVerifyingYouTube = false
                        verifiedYouTubeURL = nil
                        showToastMessage("Invalid YouTube URL")
                    }
                }
            } else {
                Logger.e("❌ [CoverTab] Failed to normalize YouTube URL")
                await MainActor.run {
                    youtubeVerificationStatus = .failed
                    isVerifyingYouTube = false
                    verifiedYouTubeURL = nil
                    showToastMessage("Invalid YouTube URL")
                }
            }
        }
    }
    
    private func clearFormData() {
        Logger.i("🧹 [CoverTab] Clearing form data")
        
        selectedSong = ""
        songName = ""
        selectedModel = nil
        resultAudioUrl = nil
        cachedSunoData = nil
        verifiedYouTubeURL = nil
        youtubeVerificationStatus = .none
        isVerifyingYouTube = false
        
        Logger.i("✅ [CoverTab] Form data cleared")
    }
    
    private func getLocalAudioURL(for song: SelectedSong) -> URL? {
        // Try to find local audio file in SunoData directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let sunoDataDirectory = documentsPath.appendingPathComponent("SunoData")
        
        // Try different possible file names
        let possibleFileNames = [
            "\(song.id)_audio.mp3",
            "\(song.id)_audio.wav",
            "\(song.id)_audio.m4a",
            "\(song.id).mp3",
            "\(song.id).wav",
            "\(song.id).m4a"
        ]
        
        for fileName in possibleFileNames {
            let filePath = sunoDataDirectory.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: filePath.path) {
                Logger.d("📁 [CoverTab] Found local audio file: \(filePath.path)")
                return filePath
            }
        }
        
        Logger.w("⚠️ [CoverTab] No local audio file found for song: \(song.title)")
        return nil
    }
    
    private func createSunoDataFromCoverResult(audioUrl: String) -> SunoData {
        Logger.i("🎵 [CoverTab] Creating SunoData from cover result")
        Logger.d("🎵 [CoverTab] Audio URL: \(audioUrl)")
        Logger.d("🎵 [CoverTab] Song Name: \(songName)")
        Logger.d("🎵 [CoverTab] Selected Model: \(selectedModel?.displayName ?? "None")")
        
        // Generate unique ID
        let uniqueId = "cover_\(UUID().uuidString.prefix(8))"
        
        // Create title: song title + " cover"
        let finalTitle = songName.isEmpty ? "Cover Song" : "\(songName)"
        
        // Create model name: model display name + " cover"
        let modelName = selectedModel?.displayName ?? "Unknown Artist"
        let finalModelName = "\(modelName) cover"
        
        Logger.d("🎵 [CoverTab] Generated ID: \(uniqueId)")
        Logger.d("🎵 [CoverTab] Generated Title: \(finalTitle)")
        Logger.d("🎵 [CoverTab] Generated Model Name: \(finalModelName)")
        
        let sunoData = SunoData(
            id: uniqueId,
            audioUrl: audioUrl,
            sourceAudioUrl: audioUrl,
            streamAudioUrl: "",
            sourceStreamAudioUrl: "",
            imageUrl: "",
            sourceImageUrl: "",
            prompt: lyric.isEmpty ? "Voice cover of \(songName.isEmpty ? "song" : songName)" : lyric,
            modelName: finalModelName,
            title: finalTitle,
            tags: "cover,voice,ai",
            createTime: Int64(Int(Date().timeIntervalSince1970)),
            duration: 0 // Will be updated by MusicPlayer
        )
        
        Logger.i("✅ [CoverTab] SunoData created successfully: \(sunoData)")
        return sunoData
    }
}

// MARK: - Supporting Enums
enum VoiceType: String, CaseIterable {
    case myVoice = "My voice"
    case otherVoice = "Other voice"
    
    var icon: String {
        switch self {
        case .myVoice: return "mic.fill"
        case .otherVoice: return "person.2.fill"
        }
    }
}

enum Artist: String, CaseIterable {
    case donald = "Dony"
    case edSheeran = "Ed 5heeran"
    case taylorSwift = "T4yl0r"
    case katyPerry = "K4ty Perry"
    case maroon5 = "Mar0on 5"
    case mrBeast = "Mr. Be4st"
    case elonMusk = "El0n"
    case shakira = "Sh4kira"
    case snoopDogg = "Sn00p"
    
    var name: String {
        return self.rawValue
    }
    
    var emoji: String {
        switch self {
        case .donald: return "👨‍💼"
        case .edSheeran: return "🎸"
        case .taylorSwift: return "🎤"
        case .katyPerry: return "🐅"
        case .maroon5: return "🎵"
        case .mrBeast: return "💰"
        case .elonMusk: return "🚀"
        case .shakira: return "💃"
        case .snoopDogg: return "🌿"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .donald: return .orange
        case .edSheeran: return .red
        case .taylorSwift: return .blue
        case .katyPerry: return .pink
        case .maroon5: return .purple
        case .mrBeast: return .green
        case .elonMusk: return .gray
        case .shakira: return .yellow
        case .snoopDogg: return .brown
        }
    }
}

// MARK: - TagLabel Component
struct TagLabel0: View {
    let title: String
    let isSelected: Bool
    let selectedColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? selectedColor : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.clear : Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }
}

private struct TagLabel: View {
    let title: String
    let isSelected: Bool
    let selectedColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(isSelected ? .subheadline.weight(.semibold)
                                 : .footnote.weight(.semibold))
                .foregroundColor(.black)
                //.foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, isSelected ? 16 : 12)
                .padding(.vertical,   isSelected ? 10 : 8)
                .background(
                    selectedColor
                        .clipShape(
                            RoundedCorner(
                                radius: 8,
                                corners: [.topLeft, .topRight] // ✅ chỉ bo cong 2 góc trên
                            )
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
struct CoverTabView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AivoSunsetBackground()
            CoverTabView()
        }
    }
}

private struct TabChip: View {
    let title: String
    let systemIcon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemIcon)
                Text(title)
            }
            // ↑ font to hơn khi chọn (đẩy layout thật)
            .font(isSelected ? .subheadline.weight(.semibold)
                             : .footnote.weight(.semibold))
            .foregroundColor(isSelected ? .black : .white)

            // ↑ padding lớn hơn khi chọn (kích thước thật, không scale)
            .padding(.horizontal, isSelected ? 16 : 12)
            .padding(.vertical,   isSelected ? 9  : 7)

            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isSelected ? AivoTheme.Primary.orange : Color.gray.opacity(0.25))
            )
        }
        .buttonStyle(.plain)
    }
}
