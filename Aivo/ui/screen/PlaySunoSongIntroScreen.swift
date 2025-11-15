import SwiftUI
import AVFoundation
import Foundation

// MARK: - Play Suno Song Intro Screen
struct PlaySunoSongIntroScreen: View {
    let sunoData: SunoData
    let onIntroCompleted: () -> Void // Callback to SplashScreenView
    
    @StateObject private var musicPlayer = MusicPlayer.shared
    @StateObject private var userDefaultsManager = UserDefaultsManager.shared
    
    @State private var isScrubbing = false
    @State private var scrubTime: TimeInterval = 0
    @State private var rotationAngle: Double = 0
    @State private var coverImageId = UUID() // Force refresh cover image when downloaded
    @State private var coverImageURL: URL? = nil // Cached cover URL to avoid recalculation
    
    // Download states (like GenerateSunoSongResultScreen)
    @State private var downloadedFileURLs: [String: URL] = [:]
    @State private var downloadingSongs: Set<String> = []
    @State private var savedToDevice: Set<String> = []
    @State private var downloadTask: Task<Void, Never>?
    
    init(sunoData: SunoData, onIntroCompleted: @escaping () -> Void) {
        self.sunoData = sunoData
        self.onIntroCompleted = onIntroCompleted
    }
    
    private var resolvedCoverURL: URL? {
        // Local cover nếu đã save
        if let local = SunoDataManager.shared.getLocalCoverPath(for: sunoData.id) {
            return local
        }
        // Remote chính
        if !sunoData.imageUrl.isEmpty, let u = URL(string: sunoData.imageUrl) {
            return u
        }
        // Remote phụ (suno cdn)
        if !sunoData.sourceImageUrl.isEmpty, let u = URL(string: sunoData.sourceImageUrl) {
            return u
        }
        return nil
    }
    
    var body: some View {
        ZStack {
            // Custom Background (like GenerateSunoSongResultScreen)
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
                
                // Lyric container
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
            Logger.d("🎵 [PlaySunoSongIntro] Screen appeared with song: \(sunoData.title)")
            
            // Cache cover image URL once (only from imageUrl)
            if coverImageURL == nil {
                if !sunoData.imageUrl.isEmpty, let url = URL(string: sunoData.imageUrl) {
                    coverImageURL = url
                    Logger.d("🖼️ [PlaySunoSongIntro] Cached cover URL: \(sunoData.imageUrl)")
                } else {
                    Logger.w("⚠️ [PlaySunoSongIntro] imageUrl is empty or invalid for song: \(sunoData.title)")
                }
            }
            
            // Stop any currently playing song from previous screen
            if musicPlayer.isPlaying {
                Logger.d("🛑 [PlaySunoSongIntro] Stopping current playback")
                musicPlayer.pause()
            }
            
            // Reset scrub time
            isScrubbing = false
            scrubTime = 0
            
            // Start download (like GenerateSunoSongResultScreen)
            startDownloadSong()
        }
        .onDisappear {
            downloadTask?.cancel()
        }
        .onChange(of: musicPlayer.isPlaying) { playing in
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
        .onChange(of: musicPlayer.currentSong?.id) { songId in
            // Update rotation when song changes
            if musicPlayer.isPlaying {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
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
            AsyncImage(url: resolvedCoverURL) { phase in
                switch phase {
                case .empty:
                    Image("demo_cover").resizable().aspectRatio(contentMode: .fill)
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .failure(_):
                    Image("demo_cover").resizable().aspectRatio(contentMode: .fill)
                @unknown default:
                    Image("demo_cover").resizable().aspectRatio(contentMode: .fill)
                }
            }
            .frame(width: 280, height: 280)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .rotationEffect(.degrees(rotationAngle))
            .animation(
                musicPlayer.isPlaying
                ? .linear(duration: 8).repeatForever(autoreverses: false)
                : .easeInOut(duration: 0.3),
                value: rotationAngle
            )

            if downloadingSongs.contains(sunoData.id) {
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
        }
        .padding(.horizontal, 40)
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
        let isDownloadingCurrentSong = downloadingSongs.contains(sunoData.id)
        let isCurrentSongDownloaded = downloadedFileURLs[sunoData.id] != nil
        let isSongReady = !isDownloadingCurrentSong && isCurrentSongDownloaded && musicPlayer.duration > 0
        
        return VStack(spacing: 8) {
            // Play/Pause button ở trên bên phải
            HStack {
                Spacer()
                Button(action: { musicPlayer.togglePlayPause() }) {
                    Image(systemName: musicPlayer.isPlaying ? "pause" : "play")
                        .font(.system(size: 24))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(AivoTheme.Primary.orange, .gray.opacity(0.3))
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
                .disabled(!isSongReady)
            }
            
            Slider(
                value: Binding(
                    get: {
                        if !isSongReady {
                            return 0
                        }
                        return isScrubbing ? scrubTime : musicPlayer.currentTime
                    },
                    set: { newVal in
                        if !isSongReady { return }
                        if isScrubbing {
                            scrubTime = newVal
                        } else {
                            musicPlayer.currentTime = newVal
                        }
                    }
                ),
                in: 0...max(0.1, isSongReady ? musicPlayer.duration : 1.0),
                onEditingChanged: { editing in
                    if !isSongReady { return }
                    if editing {
                        isScrubbing = true
                        scrubTime = musicPlayer.currentTime
                    } else {
                        isScrubbing = false
                        musicPlayer.seek(to: scrubTime)
                    }
                }
            )
            .accentColor(AivoTheme.Primary.orange)
            .disabled(!isSongReady)
            .opacity(isSongReady ? 1.0 : 0.5)
            
            HStack {
                Text(formatTime(isSongReady ? (isScrubbing ? scrubTime : musicPlayer.currentTime) : 0))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text(formatTime(isSongReady ? musicPlayer.duration : sunoData.duration))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
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
    
    // MARK: - Custom Background View (like GenerateSunoSongResultScreen)
    private var customBackgroundView: some View {
        GeometryReader { geometry in
            ZStack {
                // Nửa trên: cover blur (ép đúng width)
                VStack(spacing: 0) {
                    AsyncImage(url: resolvedCoverURL) { phase in
                        let base = Group {
                            switch phase {
                            case .empty:
                                Image("demo_cover").resizable().aspectRatio(contentMode: .fill)
                            case .success(let image):
                                image.resizable().aspectRatio(contentMode: .fill)
                            case .failure(_):
                                Image("demo_cover").resizable().aspectRatio(contentMode: .fill)
                            @unknown default:
                                Image("demo_cover").resizable().aspectRatio(contentMode: .fill)
                            }
                        }
                        base
                            .blur(radius: 20)
                            .scaleEffect(1.2)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.55) // ✅ ép width
                    .clipped()

                    Spacer(minLength: 0)
                }

                // Nửa dưới: đen để nối
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Color.black.opacity(0.8)
                        .frame(height: geometry.size.height * 0.45)
                }

                // Overlay tối dần từ trên xuống
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.black.opacity(0.05), location: 0.0),
                        .init(color: Color.black.opacity(1.0),  location: 0.5),
                        .init(color: Color.black.opacity(1.0),  location: 1.0)
                    ]),
                    startPoint: .top, endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Helper Functions
    // Note: Cover URL is now cached in @State coverImageURL, set once in onAppear
    // This avoids recalculation on every render and prevents log spam
    
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
    
    // MARK: - Download Functions (exactly like GenerateSunoSongResultScreen)
    private func startDownloadSong() {
        downloadSong(sunoData)
    }
    
    private func downloadSong(_ song: SunoData) {
        Logger.d("📥 [PlaySunoSongIntro] Starting download for song: \(song.title)")
        Logger.d("📥 [PlaySunoSongIntro] Audio URL: \(song.audioUrl)")
        
        // Log Firebase event for download request
        FirebaseLogger.shared.logEventWithBundle(FirebaseLogger.EVENT_DOWNLOAD_SONG_REQUEST, parameters: [
            "song_id": song.id,
            "song_title": song.title,
            "timestamp": Date().timeIntervalSince1970
        ])
        
        guard let url = URL(string: song.audioUrl) else { 
            Logger.e("❌ [PlaySunoSongIntro] Invalid URL for song: \(song.title)")
            return
        }
        
        downloadingSongs.insert(song.id)
        
        let ext = url.pathExtension.isEmpty ? "mp3" : url.pathExtension.lowercased()
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let sunoDataDirectory = documentsPath.appendingPathComponent("SunoData")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: sunoDataDirectory, withIntermediateDirectories: true)
        
        let fileName = "\(song.id)_audio.\(ext)"
        let localURL = sunoDataDirectory.appendingPathComponent(fileName)
        
        Logger.d("📥 [PlaySunoSongIntro] Download destination: \(localURL.path)")
        
        let downloader = ProgressiveDownloader(
            destinationURL: localURL,
            onProgress: { _ in
                // Progress tracking removed - just show downloading status
            },
            onComplete: { fileURL in
                Logger.d("✅ [PlaySunoSongIntro] Download completed for song: \(song.title)")
                
                // Log Firebase event for download success
                FirebaseLogger.shared.logEventWithBundle(FirebaseLogger.EVENT_DOWNLOAD_SONG_SUCCESS, parameters: [
                    "song_id": song.id,
                    "song_title": song.title,
                    "timestamp": Date().timeIntervalSince1970
                ])
                
                // Validate file size before proceeding
                let fileManager = FileManager.default
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                    if let fileSize = attributes[.size] as? Int64 {
                        Logger.d("📊 [PlaySunoSongIntro] Downloaded file size: \(fileSize) bytes")
                        
                        // Check if file size is suspiciously small (< 100KB)
                        if fileSize < 100 * 1024 {
                            Logger.e("❌ [PlaySunoSongIntro] Downloaded file too small (\(fileSize) bytes), likely corrupted")
                            Logger.w("⚠️ [PlaySunoSongIntro] Retrying download for song: \(song.title)")
                            
                            // Retry download
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                self.downloadSong(song)
                            }
                            return
                        }
                        
                        Logger.d("✅ [PlaySunoSongIntro] File size validation passed: \(fileSize) bytes")
                    }
                } catch {
                    Logger.e("❌ [PlaySunoSongIntro] Error getting file attributes: \(error)")
                }
                
                self.downloadingSongs.remove(song.id)
                self.downloadedFileURLs[song.id] = fileURL
                
                // Save full SunoData to local storage (cover will stay on imageUrl, no need to refresh)
                Task {
                    do {
                        let savedURL = try await SunoDataManager.shared.saveSunoData(song)
                        await MainActor.run {
                            self.savedToDevice.insert(song.id)
                            Logger.d("💾 [PlaySunoSongIntro] Full SunoData saved to device: \(savedURL.path)")
                            // Don't refresh coverImageId - keep showing imageUrl from the start
                        }
                    } catch {
                        Logger.e("❌ [PlaySunoSongIntro] Error saving SunoData: \(error)")
                    }
                }
                
                // Song downloaded successfully - auto-play using MusicPlayer (like GenerateSunoSongResultScreen)
                DispatchQueue.main.async {
                    Logger.d("🎵 [PlaySunoSongIntro] Auto-playing song: \(song.title)")
                    self.musicPlayer.loadSong(song, at: 0, in: [song])
                    Logger.d("🎵 [PlaySunoSongIntro] Song ready for playback: \(song.title)")
                }
            },
            onError: { error in
                Logger.e("❌ [PlaySunoSongIntro] Download error for song \(song.title): \(error)")
                self.downloadingSongs.remove(song.id)
                
                // Retry download on error (with limit)
                Logger.w("⚠️ [PlaySunoSongIntro] Retrying download for song: \(song.title)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.downloadSong(song)
                }
            }
        )
        
        downloader.start(url: url)
    }
    
    private func continueAction() {
        // Mark intro as completed in UserDefaults
        userDefaultsManager.markIntroAsShowed()
        
        // Call callback to SplashScreenView to navigate to HomeView
        onIntroCompleted()
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
