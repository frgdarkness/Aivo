import SwiftUI
import AVFoundation
import Foundation

// MARK: - Play Suno Song Intro Screen
struct PlaySunoSongIntroScreen: View {
    let sunoData: SunoData
    let onIntroCompleted: () -> Void // Callback to SplashScreenView
    
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var audioPlayer: AVAudioPlayer?
    @State private var playbackTimer: Timer?
    @State private var isDownloading = false
    @State private var downloadTask: ProgressiveDownloader?
    @State private var rotationAngle: Double = 0
    @State private var isScrubbing = false
    @State private var scrubTime: TimeInterval = 0
    
    @StateObject private var userDefaultsManager = UserDefaultsManager.shared
    
    init(sunoData: SunoData, onIntroCompleted: @escaping () -> Void) {
        self.sunoData = sunoData
        self.onIntroCompleted = onIntroCompleted
    }
    
    var body: some View {
        ZStack {
            // Custom Background với gradient (tương tự PlayMySongScreen)
            customBackgroundView
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                Spacer()
                
                // Cover image with download progress
                albumArtView
                
                Spacer()
                
                // Song info
                songInfoView
                
                // Lyric container để control height và đẩy các view khác
                lyricContainerView
                
                Spacer()
                
                // Seekbar with play/pause button
                seekBarView
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                Spacer()
                
                // Continue button
                continueButton
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            downloadAndSetupAudio()
        }
        .onDisappear {
            stopAudio()
            playbackTimer?.invalidate()
            downloadTask?.cancel()
            rotationAngle = 0
        }
        .onChange(of: isPlaying) { playing in
            if playing {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    rotationAngle = 0
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Text("HERE'S YOUR SONG")
                .font(.system(size: 24, weight: .black, design: .monospaced))
                .foregroundColor(.white)
            
            Spacer()
            
            // Spacer để balance layout
            Color.clear
                .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
    
    // MARK: - Album Art View with Download Progress
    private var albumArtView: some View {
        ZStack {
            AsyncImage(url: getImageURL()) { phase in
                switch phase {
                case .empty:
                    placeholderView
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholderView
                @unknown default:
                    placeholderView
                }
            }
            .frame(width: 280, height: 280)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .rotationEffect(.degrees(rotationAngle))
            .animation(
                isPlaying
                ? .linear(duration: 8).repeatForever(autoreverses: false)
                : .easeInOut(duration: 0.3),
                value: rotationAngle
            )
            
            // Download progress overlay
            if isDownloading {
                Circle()
                    .fill(Color.black.opacity(0.7))
                    .frame(width: 280, height: 280)
                    .overlay(
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            Text("Downloading...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                    )
            }
        }
    }
    
    private var placeholderView: some View {
        Circle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        AivoTheme.Primary.orange,
                        AivoTheme.Primary.orangeLight,
                        AivoTheme.Primary.orangeAccent
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 280, height: 280)
            .overlay(
                Image(systemName: "music.note")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            )
    }
    
    // MARK: - Song Info View
    private var songInfoView: some View {
        VStack(spacing: 8) {
            Text(sunoData.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.top, 12)
            
//            Text(sunoData.modelName)
//                .font(.subheadline)
//                .foregroundColor(.white.opacity(0.8))
//                .multilineTextAlignment(.center)
//            
//            // Duration display
//            Text(formatDuration(sunoData.duration))
//                .font(.caption)
//                .foregroundColor(.white.opacity(0.6))
//                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }
    
    private func formatDuration(_ duration: Double) -> String {
        if duration <= 0 {
            return "Duration: N/A"
        }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Lyric Container View
    private var lyricContainerView: some View {
        VStack {
            lyricView
        }
        .frame(maxHeight: 200)
    }
    
    // MARK: - Lyric View
    private var lyricView: some View {
        ScrollView {
            VStack(spacing: 8) {
                if let lyric = parseLyric(from: sunoData.prompt) {
                    Text(lyric)
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 20)
                } else {
                    Text("Lyric not available")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.6))
                        .italic()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 16)
        }
        .frame(maxHeight: 150)
        .mask(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .black, location: 0.2),
                    .init(color: .black, location: 0.8),
                    .init(color: .clear, location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Seek Bar View
    private var seekBarView: some View {
        VStack(spacing: 2) {
            // Play/Pause button ở trên bên phải
            HStack {
                Spacer()
                Button(action: togglePlayPause) {
                    Image(systemName: isPlaying ? "pause" : "play")
                        .font(.system(size: 24))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(AivoTheme.Primary.orange, .gray.opacity(0.3))
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            
            Slider(
                value: Binding(
                    get: { isScrubbing ? scrubTime : currentTime },
                    set: { newVal in
                        if isScrubbing {
                            scrubTime = newVal
                        } else {
                            currentTime = newVal
                        }
                    }
                ),
                in: 0...max(0.1, duration),
                onEditingChanged: { editing in
                    if editing {
                        isScrubbing = true
                        scrubTime = currentTime
                    } else {
                        isScrubbing = false
                        currentTime = scrubTime
                        audioPlayer?.currentTime = scrubTime
                    }
                }
            )
            .accentColor(AivoTheme.Primary.orange)
            
            HStack {
                Text(formatTime(isScrubbing ? scrubTime : currentTime))
                    .font(.caption)
                    .foregroundColor(.white)
                Spacer()
                Text(formatTime(duration))
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Continue Button
    private var continueButton: some View {
        Button(action: continueAction) {
            Text("Continue")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AivoTheme.Primary.orange)
                .cornerRadius(12)
                .shadow(color: AivoTheme.Shadow.orange, radius: 10, x: 0, y: 0)
        }
    }
    
    // MARK: - Custom Background View (tương tự PlayMySongScreen)
    private var customBackgroundView: some View {
        GeometryReader { geometry in
            ZStack {
                // Nửa trên: Ảnh cover blur
                VStack {
                    AsyncImage(url: getImageURL()) { phase in
                        switch phase {
                        case .empty:
                            Image("demo_cover")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .blur(radius: 20)
                                .scaleEffect(1.2)
                                .clipped()
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .blur(radius: 20)
                                .scaleEffect(1.2)
                                .clipped()
                        case .failure:
                            Image("demo_cover")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .blur(radius: 20)
                                .scaleEffect(1.2)
                                .clipped()
                        @unknown default:
                            Image("demo_cover")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .blur(radius: 20)
                                .scaleEffect(1.2)
                                .clipped()
                        }
                    }
                    .frame(height: geometry.size.height * 0.55)
                    .clipped()
                    
                    Spacer()
                }
                
                // Nửa dưới: Đen từ 80% để nối tiếp
                VStack {
                    Spacer()
                    Color.black.opacity(0.8)
                        .frame(height: geometry.size.height * 0.45)
                }
                
                // Overlay đen dần từ đỉnh đến cuối
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.black.opacity(0.05), location: 0.0),
                        .init(color: Color.black.opacity(1.0), location: 0.5),
                        .init(color: Color.black.opacity(1.0), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .drawingGroup()
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Helper Functions
    private func getImageURL() -> URL? {
        // Check if local cover exists first (similar to getImageURLForSong)
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let coverPath = documents.appendingPathComponent("SunoData/\(sunoData.id)_cover.jpg")
        if FileManager.default.fileExists(atPath: coverPath.path) {
            return coverPath
        }
        
        // Fallback to source URL
        return URL(string: sunoData.sourceImageUrl)
    }
    
    private func parseLyric(from prompt: String?) -> String? {
        guard let prompt = prompt, !prompt.isEmpty else { return nil }
        
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Case 1: Nếu prompt bắt đầu bằng [ thì giữ nguyên
        if trimmedPrompt.hasPrefix("[") {
            return trimmedPrompt
        }
        
        // Case 2: Kiểm tra trong prompt có ký tự [ không
        if let firstBracketIndex = trimmedPrompt.firstIndex(of: "[") {
            // Cắt chuỗi từ ký tự [ đầu tiên đến hết
            let lyricFromBracket = String(trimmedPrompt[firstBracketIndex...])
            return lyricFromBracket
        }
        
        // Case 3: Không có [ trong prompt → return nil
        return nil
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Audio Functions
    private func downloadAndSetupAudio() {
        guard let url = URL(string: sunoData.audioUrl) else {
            Logger.e("❌ [PlaySunoSongIntro] Invalid audio URL: \(sunoData.audioUrl)")
            return
        }
        
        isDownloading = true
        
        // Set duration from SunoData
        duration = sunoData.duration > 0 ? sunoData.duration : 180
        
        // Create temporary file URL
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(sunoData.id).mp3")
        
        // Use ProgressiveDownloaderIntro for efficient downloading
        let downloader = ProgressiveDownloader(
            destinationURL: tempURL,
            onProgress: { _ in
                // Progress tracking removed - just show downloading status
            },
            onComplete: { fileURL in
                Logger.d("✅ [PlaySunoSongIntro] Download completed")
                
                // Validate file size
                let fileManager = FileManager.default
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                    if let fileSize = attributes[.size] as? Int64 {
                        Logger.d("📊 [PlaySunoSongIntro] Downloaded file size: \(fileSize) bytes")
                        
                        // Check if file size is suspiciously small (< 100KB)
                        if fileSize < 100 * 1024 {
                            Logger.e("❌ [PlaySunoSongIntro] Downloaded file too small (\(fileSize) bytes), likely corrupted")
                            Logger.w("⚠️ [PlaySunoSongIntro] Retrying download...")
                            
                            // Retry download
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                self.downloadAndSetupAudio()
                            }
                            return
                        }
                        
                        Logger.d("✅ [PlaySunoSongIntro] File size validation passed: \(fileSize) bytes")
                    }
                } catch {
                    Logger.e("❌ [PlaySunoSongIntro] Error getting file attributes: \(error)")
                }
                
                DispatchQueue.main.async {
                    self.isDownloading = false
                    self.setupAudioPlayerWithURL(fileURL)
                    
                    // Save to library after successful download
                    // Copy file from temp to Documents and save metadata
                    Task {
                        do {
                            Logger.d("💾 [PlaySunoSongIntro] Saving song to library: \(self.sunoData.title)")
                            
                            // Copy audio file from temp to Documents/SunoData
                            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                            let sunoDataDirectory = documentsPath.appendingPathComponent("SunoData")
                            try FileManager.default.createDirectory(at: sunoDataDirectory, withIntermediateDirectories: true)
                            
                            let ext = fileURL.pathExtension.isEmpty ? "mp3" : fileURL.pathExtension.lowercased()
                            let destinationAudioURL = sunoDataDirectory.appendingPathComponent("\(self.sunoData.id)_audio.\(ext)")
                            
                            // Copy audio file
                            if FileManager.default.fileExists(atPath: fileURL.path) {
                                try? FileManager.default.removeItem(at: destinationAudioURL)
                                try FileManager.default.copyItem(at: fileURL, to: destinationAudioURL)
                                Logger.d("✅ [PlaySunoSongIntro] Copied audio file to: \(destinationAudioURL.path)")
                            }
                            
                            // Download and save cover image (only if imageUrl is not empty)
                            let coverURL: URL
                            if !self.sunoData.imageUrl.isEmpty {
                                guard let imageURL = URL(string: self.sunoData.imageUrl) else {
                                    throw NSError(domain: "PlaySunoSongIntro", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image URL"])
                                }
                                
                                let coverExt = imageURL.pathExtension.isEmpty ? "jpg" : imageURL.pathExtension.lowercased()
                                let destinationCoverURL = sunoDataDirectory.appendingPathComponent("\(self.sunoData.id)_cover.\(coverExt)")
                                
                                let (coverData, _) = try await URLSession.shared.data(from: imageURL)
                                try coverData.write(to: destinationCoverURL)
                                coverURL = destinationCoverURL
                                Logger.d("✅ [PlaySunoSongIntro] Downloaded cover image to: \(coverURL.path)")
                            } else {
                                let placeholderFileName = "\(self.sunoData.id)_cover.jpg"
                                coverURL = sunoDataDirectory.appendingPathComponent(placeholderFileName)
                            }
                            
                            // Create metadata file
                            let metadata = SunoDataMetadata(
                                id: self.sunoData.id,
                                audioUrl: self.sunoData.audioUrl,
                                sourceAudioUrl: self.sunoData.sourceAudioUrl,
                                streamAudioUrl: self.sunoData.streamAudioUrl,
                                sourceStreamAudioUrl: self.sunoData.sourceStreamAudioUrl,
                                imageUrl: self.sunoData.imageUrl,
                                sourceImageUrl: self.sunoData.sourceImageUrl,
                                coverUrl: coverURL.absoluteString,
                                title: self.sunoData.title,
                                modelName: self.sunoData.modelName,
                                duration: self.sunoData.duration,
                                prompt: self.sunoData.prompt,
                                tags: self.sunoData.tags,
                                createTime: self.sunoData.createTime,
                                savedAt: Int64(Date().timeIntervalSince1970 * 1000)
                            )
                            
                            let metadataURL = sunoDataDirectory.appendingPathComponent("\(self.sunoData.id).json")
                            let metadataData = try JSONEncoder().encode(metadata)
                            try metadataData.write(to: metadataURL)
                            
                            await MainActor.run {
                                Logger.d("✅ [PlaySunoSongIntro] Successfully saved song to library: \(metadataURL.path)")
                            }
                        } catch {
                            Logger.e("❌ [PlaySunoSongIntro] Error saving song to library: \(error)")
                        }
                    }
                    
                    // Auto-play after download
                    if !self.isPlaying {
                        self.togglePlayPause()
                    }
                }
            },
            onError: { error in
                Logger.e("❌ [PlaySunoSongIntro] Download error: \(error)")
                
                // Retry on error
                Logger.w("⚠️ [PlaySunoSongIntro] Retrying download...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.downloadAndSetupAudio()
                }
            }
        )
        
        downloadTask = downloader
        downloader.start(url: url)
        Logger.d("📥 [PlaySunoSongIntro] Started download for: \(sunoData.title)")
    }
    
    private func setupAudioPlayerWithURL(_ url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = IntroAudioPlayerDelegate { [self] in
                isPlaying = false
                currentTime = 0
                playbackTimer?.invalidate()
            }
            
            // Use duration from SunoData if available, otherwise from audio player
            if sunoData.duration > 0 {
                duration = sunoData.duration
            } else {
                duration = audioPlayer?.duration ?? 180
            }
            
            // Start timer for progress updates
            startPlaybackTimer()
        } catch {
            Logger.e("❌ [PlaySunoSongIntro] Error setting up audio player: \(error)")
        }
    }
    
    private func startPlaybackTimer() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let player = audioPlayer, player.isPlaying {
                currentTime = player.currentTime
            }
        }
    }
    
    private func togglePlayPause() {
        if isPlaying {
            audioPlayer?.pause()
            playbackTimer?.invalidate()
        } else {
            audioPlayer?.play()
            startPlaybackTimer()
        }
        isPlaying.toggle()
    }
    
    private func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        playbackTimer?.invalidate()
    }
    
    private func continueAction() {
        // Mark intro as completed in UserDefaults
        userDefaultsManager.markIntroAsShowed()
        
        // Call callback to SplashScreenView to navigate to HomeView
        onIntroCompleted()
    }
}

// MARK: - Audio Player Delegate
class IntroAudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    let onFinish: () -> Void
    
    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }
}

// MARK: - Preview
struct PlaySunoSongIntroScreen_Previews: PreviewProvider {
    static var previews: some View {
        let sampleSunoData = SunoData(
            id: "646dc7d8-fc6c-407a-9b52-056aec2405a9",
            audioUrl: "https://musicfile.api.box/NjQ2ZGM3ZDgtZmM2Yy00MDdhLTliNTItMDU2YWVjMjQwNWE5.mp3",
            sourceAudioUrl: "https://cdn1.suno.ai/646dc7d8-fc6c-407a-9b52-056aec2405a9.mp3",
            streamAudioUrl: "https://musicfile.api.box/NjQ2ZGM3ZDgtZmM2Yy00MDdhLTliNTItMDU2YWVjMjQwNWE5",
            sourceStreamAudioUrl: "https://cdn1.suno.ai/646dc7d8-fc6c-407a-9b52-056aec2405a9.mp3",
            imageUrl: "https://musicfile.api.box/NjQ2ZGM3ZDgtZmM2Yy00MDdhLTliNTItMDU2YWVjMjQwNWE5.jpeg",
            sourceImageUrl: "https://cdn2.suno.ai/image_646dc7d8-fc6c-407a-9b52-056aec2405a9.jpeg",
            prompt: "[Verse]\nEyes closed, silhouette in the mist\nFingers trace the memory I can't resist\nHeart beats, syncopated with the night\nChasing shadows, but you're the light\n\nDreaming in whispers, your name on repeat\nEchoes in the silence, my soul's heartbeat\nEvery star a thought, every cloud a sigh\nA galaxy of longing, you and I\n\n[Chorus]\nIn my dreams, you're the rhythm, the rhyme\nEvery second slows, bending time\nI reach, but you're just out of frame\nMy dream state serenade, whisper your name\n\n[Verse 2]\nFootsteps vanish on a moonlit shore\nThe tide pulls me deeper, craving more\nYour laughter's a melody, soft and low\nA haunting refrain in the winds that blow\n\nHands grasp air, searching for your face\nA phantom embrace in this hollow space\nReality's cruel, but the dream's divine\nYou're the verse I rewrite, every time\n\n[Chorus]\nIn my dreams, you're the rhythm, the rhyme\nEvery second slows, bending time\nI reach, but you're just out of frame\nMy dream state serenade, whisper your name",
            modelName: "chirp-bluejay",
            title: "Dream State Serenade",
            tags: "smooth flow with airy keys, smooth, rap, 86 bpm, reflective ambiance, emotional, introspective yet melodic atmosphere, tone, poetic",
            createTime: 1761725963731,
            duration: 145.16
        )
        
        PlaySunoSongIntroScreen(
            sunoData: sampleSunoData,
            onIntroCompleted: {
                print("Preview: Intro completed")
            }
        )
    }
}
