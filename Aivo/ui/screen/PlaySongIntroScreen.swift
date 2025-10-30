import SwiftUI
import AVFoundation

// MARK: - Play Song Screen
struct PlaySongIntroScreen: View {
    let songData: SongCreationData?
    let audioUrl: String? // Deprecated: Use sunoData instead
    let sunoData: SunoData? // New parameter for SunoData
    let onIntroCompleted: () -> Void // Callback to SplashScreenView
    
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 180 // Default 3 minutes
    @State private var audioPlayer: AVAudioPlayer?
    @State private var showLyrics = false
    @State private var playbackTimer: Timer?
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0.0
    @Environment(\.dismiss) private var dismiss
    
    @State private var isScrubbing = false
    @State private var scrubTime: TimeInterval = 0
    
    @StateObject private var userDefaultsManager = UserDefaultsManager.shared
    
    // Hard-coded song for fallback
    private let song = Song.tokyo
    
    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 20)
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
                VStack {
                    Image(systemName: "music.note")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                }
            )
            .shadow(color: AivoTheme.Shadow.orange, radius: 20, x: 0, y: 10)
    }
    
    init(songData: SongCreationData?, audioUrl: String? = nil, sunoData: SunoData? = nil, onIntroCompleted: @escaping () -> Void) {
        self.songData = songData
        self.audioUrl = audioUrl
        self.sunoData = sunoData
        self.onIntroCompleted = onIntroCompleted
    }
    
    var body: some View {
        ZStack {
            // Background
            AivoSunsetBackground()
            
            VStack(spacing: 0) {
                // Header
                headerView
                songCoverView
                // Main content
                VStack(spacing: 0) {
                    // Song info (empty now)
                    songInfoView
                    
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
                        in: 0...duration,
                        onEditingChanged: { editing in
                            if editing {
                                // bắt đầu kéo → khóa cập nhật từ player
                                isScrubbing = true
                                scrubTime = currentTime
                                // (tuỳ chọn) tạm dừng player nếu muốn
                                // audioPlayer?.pause()
                            } else {
                                // thả tay → seek và mở khóa
                                isScrubbing = false
                                currentTime = scrubTime
                                audioPlayer?.currentTime = scrubTime
                                // (tuỳ chọn) phát tiếp nếu trước đó đang phát
                                // if isPlaying { audioPlayer?.play() }
                            }
                        }
                    )
                    .accentColor(AivoTheme.Primary.orange)
                    .padding(.top, 14)
                    .padding(.horizontal, 20)
                    
                    // Lyrics section - Fill remaining height
                    lyricsSection
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Bottom controls
                bottomControlsView
            }
        }
        .onAppear {
            setupAudioPlayer()
        }
        .onDisappear {
            stopAudio()
            playbackTimer?.invalidate()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
//            Button(action: { dismiss() }) {
//                Image(systemName: "chevron.left")
//                    .font(.title2)
//                    .foregroundColor(.white)
//            }
            
            Text("HERE'S YOUR SONG")
                .font(.system(size: 24, weight: .black, design: .monospaced))
                .foregroundColor(.white)
            
            Spacer()
            
            // Remove copy icon
            Color.clear
                .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
    
    // MARK: - Song Cover View
    private var songCoverView: some View {
        VStack(spacing: 0) {
            // Cover image from SunoData or gradient placeholder
            ZStack {
                if let sunoData = sunoData, let imageUrl = URL(string: sunoData.imageUrl) {
                    AsyncImage(url: imageUrl) { phase in
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
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: AivoTheme.Shadow.orange, radius: 20, x: 0, y: 10)
                } else {
                    placeholderView
                }
                
                // Song title at bottom left
                VStack {
                    Spacer()
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(sunoData?.title ?? "AI Tokyo")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("\(songData?.mood.displayName ?? "Energetic") \(songData?.genre.displayName ?? "Electronic") for \(songData?.theme.displayName ?? "My City")")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.leading, 16)
                        .padding(.bottom, 16)
                        Spacer()
                    }
                }
                .frame(width: 280, height: 280)
                
                // Play/Pause button at bottom right
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: togglePlayPause) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }
                }
                .frame(width: 280, height: 280)
            }
        }
    }
    
    // MARK: - Song Info View
    private var songInfoView: some View {
        EmptyView()
    }
    
    // MARK: - Lyrics Section
    // MARK: - Lyrics Section (card bo cong, margin = 20, title cố định, chỉ lời scroll)
    private var lyricsSection: some View {
        // bọc để set margin giống button + chừa đáy
        VStack(spacing: 0) {
            ZStack {
                // card nền đen xám + bo góc
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AivoTheme.Background.card) // màu đen xám của bạn
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AivoTheme.Primary.orange.opacity(0.25), lineWidth: 1)
                    )

                // nội dung trong card
                VStack(alignment: .leading, spacing: 12) {
                    // Title cố định (không scroll)
                    Text("Lyrics")
                        .font(.title2).fontWeight(.bold)
                        .foregroundColor(AivoTheme.Primary.orange)

                    Divider()
                        .overlay(AivoTheme.Primary.orange.opacity(0.15))

                    // Chỉ phần lời là scroll
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(lyricsArray, id: \.self) { line in
                                if line.hasPrefix("[") {
                                    Text(line)
                                        .font(.headline).fontWeight(.bold)
                                        .foregroundColor(AivoTheme.Primary.orange)
                                } else {
                                    Text(line)
                                        .foregroundColor(.white)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(.bottom, 4) // đừng để dính sát đáy card khi scroll
                    }
                }
                .padding(16) // padding bên trong card
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // card tự giãn phần còn lại
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous)) // nội dung scroll không tràn góc
        }
        .padding(.top, 20)
        .padding(.horizontal, 20)   // = với Button Continue
        .padding(.bottom, 12)       // margin bottom một chút trước khu vực nút
    }

    
    // MARK: - Bottom Controls View
    private var bottomControlsView: some View {
        VStack(spacing: 12) {
            // Progress bar
//            Slider(value: $currentTime, in: 0...duration) { editing in
//                if !editing {
//                    // Seek to new position when user finishes dragging
//                    audioPlayer?.currentTime = currentTime
//                }
//            }
//            .accentColor(AivoTheme.Primary.orange)
//            .padding(.top, 8)
            
            // Continue button
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
        .padding(.horizontal, 20)
        .padding(.bottom, 18)
        .padding(.top, 16)
        .background(
            Rectangle()
                .fill(AivoTheme.Background.primary)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: -5)
        )
    }
    
    // MARK: - Computed Properties
    private var lyricsArray: [String] {
        // Parse lyrics from SunoData prompt if available
        if let sunoData = sunoData, !sunoData.prompt.isEmpty {
            return parseLyrics(from: sunoData.prompt)
        }
        
        // Fallback to default lyrics
        return [
            "[Verse 1]",
            "In the neon lights of Tokyo",
            "Where the future meets the past",
            "AI dreams are coming true",
            "This moment's built to last",
            "",
            "[Chorus]",
            "Tokyo, Tokyo, city of tomorrow",
            "Where technology and culture blend",
            "Tokyo, Tokyo, let the music follow",
            "This is where the journey ends",
            "",
            "[Verse 2]",
            "Robots dance in harmony",
            "With the rhythm of the street",
            "Every beat tells a story",
            "Of the people that we meet",
            "",
            "[Chorus]",
            "Tokyo, Tokyo, city of tomorrow",
            "Where technology and culture blend",
            "Tokyo, Tokyo, let the music follow",
            "This is where the journey ends"
        ]
    }
    
    private func parseLyrics(from prompt: String) -> [String] {
        // Split by newlines and filter empty lines
        let lines = prompt.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        return lines.isEmpty ? ["Lyric not available"] : lines
    }
    
    // MARK: - Audio Setup
    private func setupAudioPlayer() {
        // Priority: sunoData.audioUrl > audioUrl > local file
        if let sunoData = sunoData, !sunoData.audioUrl.isEmpty {
            // Download and play from SunoData
            downloadAndPlayAudio(from: sunoData.audioUrl)
        } else if let audioUrl = audioUrl, !audioUrl.isEmpty {
            // Download and play external audio
            downloadAndPlayAudio(from: audioUrl)
        } else {
            // Play local audio file as fallback
            playLocalAudio()
        }
    }
    
    private func downloadAndPlayAudio(from urlString: String) {
        guard let url = URL(string: urlString) else {
            print("Invalid audio URL")
            return
        }
        
        isDownloading = true
        
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                
                // Update download progress
                await MainActor.run {
                    downloadProgress = 1.0
                }
                
                // Create temporary file
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_audio.mp3")
                try data.write(to: tempURL)
                
                await MainActor.run {
                    setupAudioPlayerWithURL(tempURL)
                    isDownloading = false
                }
            } catch {
                print("Error downloading audio: \(error)")
                await MainActor.run {
                    isDownloading = false
                    // Fallback to local audio
                    playLocalAudio()
                }
            }
        }
    }
    
    private func playLocalAudio() {
        guard let url = Bundle.main.url(forResource: song.audioFileName, withExtension: "mp3") else {
            print("Audio file not found")
            return
        }
        
        setupAudioPlayerWithURL(url)
    }
    
    private func setupAudioPlayerWithURL(_ url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = AudioPlayerDelegate { [self] in
                isPlaying = false
                currentTime = 0
                playbackTimer?.invalidate()
            }
            // Use duration from SunoData if available, otherwise from audio player
            if let sunoData = sunoData, sunoData.duration > 0 {
                duration = sunoData.duration
            } else {
                duration = audioPlayer?.duration ?? 180
            }
            
            // Start timer for progress updates
            startPlaybackTimer()
        } catch {
            print("Error setting up audio player: \(error)")
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
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func continueAction() {
        // Mark intro as completed in UserDefaults
        userDefaultsManager.markIntroAsShowed()
        
        // Call callback to SplashScreenView to navigate to HomeView
        onIntroCompleted()
    }
}

// MARK: - Audio Player Delegate
class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    let onFinish: () -> Void
    
    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }
}

// MARK: - Preview
struct PlaySongScreen_Previews: PreviewProvider {
    static var previews: some View {
        PlaySongIntroScreen(
            songData: SongCreationData(
                mood: .energetic,
                genre: .electronic,
                theme: .myCity
            ),
            audioUrl: nil,
            onIntroCompleted: {}
        )
    }
}
