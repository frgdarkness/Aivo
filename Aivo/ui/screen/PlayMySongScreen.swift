import SwiftUI
import AVFoundation

// MARK: - Play My Song Screen
struct PlayMySongScreen: View {
    let songs: [SunoData]
    let initialIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentIndex: Int
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var audioPlayer: AVAudioPlayer?
    @State private var playbackTimer: Timer?
    @State private var isScrubbing = false
    @State private var scrubTime: TimeInterval = 0
    @State private var isFavorite = false
    @State private var playMode: PlayMode = .sequential
    @State private var showPlaylist = false
    @State private var localSongs: [SunoData] = []
    @State private var isLoading = true
    
    enum PlayMode: String, CaseIterable {
        case shuffle = "shuffle"
        case sequential = "sequential"
        case repeatOne = "repeat_one"
        
        var icon: String {
            switch self {
            case .shuffle: return "shuffle"
            case .sequential: return "arrow.clockwise"
            case .repeatOne: return "repeat.1"
            }
        }
    }
    
    init(songs: [SunoData], initialIndex: Int = 0) {
        self.songs = songs
        self.initialIndex = initialIndex
        self._currentIndex = State(initialValue: initialIndex)
    }
    
    private var currentSong: SunoData? {
        guard currentIndex >= 0 && currentIndex < localSongs.count else { return nil }
        return localSongs[currentIndex]
    }
    
    private var displaySongs: [SunoData] {
        return localSongs.isEmpty ? songs : localSongs
    }
    
    var body: some View {
        ZStack {
            // Background
            AivoSunsetBackground()
            
            if isLoading {
                // Loading State
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    
                    Text("Loading songs...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            } else if let currentSong = currentSong {
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    Spacer()
                    
                    // Album Art with Rotation
                    albumArtView
                    
                    Spacer()
                    
                    // Song Info
                    songInfoView
                    
                    Spacer()
                    
                    // Playback Controls
                    playbackControlsView
                    
                    Spacer()
                }
            } else {
                // No Song State
                VStack(spacing: 20) {
                    Image(systemName: "music.note")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("No songs available")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            loadLocalSongs()
        }
        .onDisappear {
            stopAudio()
        }
        .sheet(isPresented: $showPlaylist) {
            playlistView
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Back Button
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Title
            Text("Now Playing")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
            
            // Favorite Button
            Button(action: {
                isFavorite.toggle()
            }) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.title2)
                    .foregroundColor(isFavorite ? .red : .white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - Album Art View
    private var albumArtView: some View {
        ZStack {
            // Blurred background
            AsyncImage(url: URL(string: currentSong?.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 20)
                    .scaleEffect(1.2)
            } placeholder: {
                Image("demo_cover")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 20)
                    .scaleEffect(1.2)
            }
            .frame(width: 300, height: 300)
            .clipped()
            
            // Circular album art with rotation
            AsyncImage(url: URL(string: currentSong?.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image("demo_cover")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            .frame(width: 280, height: 280)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .rotationEffect(.degrees(isPlaying ? 360 : 0))
            .animation(
                isPlaying ? 
                .linear(duration: 10).repeatForever(autoreverses: false) : 
                .easeInOut(duration: 0.5),
                value: isPlaying
            )
        }
    }
    
    // MARK: - Song Info View
    private var songInfoView: some View {
        VStack(spacing: 8) {
            // Song Title
            Text(currentSong?.title ?? "Unknown Title")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Artist/Model
            Text(currentSong?.modelName ?? "Unknown Artist")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Playback Controls View
    private var playbackControlsView: some View {
        VStack(spacing: 20) {
            // Seek Bar
            seekBarView
            
            // Control Buttons
            controlButtonsView
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
    
    // MARK: - Seek Bar View
    private var seekBarView: some View {
        VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: { isScrubbing ? scrubTime : currentTime },
                    set: { newVal in
                        if isScrubbing { scrubTime = newVal } else { currentTime = newVal }
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
            .accentColor(.green)
            
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
    
    // MARK: - Control Buttons View
    private var controlButtonsView: some View {
        HStack(spacing: 30) {
            // Play Mode Button
            Button(action: {
                cyclePlayMode()
            }) {
                Image(systemName: playMode.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            
            // Previous Button
            Button(action: previousSong) {
                Image(systemName: "backward.end.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            
            // Play/Pause Button
            Button(action: togglePlayPause) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.black)
                    .frame(width: 70, height: 70)
                    .background(Color.green)
                    .clipShape(Circle())
                    .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            
            // Next Button
            Button(action: nextSong) {
                Image(systemName: "forward.end.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            
            // Playlist Button
            Button(action: {
                showPlaylist = true
            }) {
                Image(systemName: "list.bullet")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
        }
    }
    
    // MARK: - Playlist View
    private var playlistView: some View {
        ZStack {
            // Background
            AivoSunsetBackground()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Playlist")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Done") {
                        showPlaylist = false
                    }
                    .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                // Songs List
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(displaySongs.enumerated()), id: \.element.id) { index, song in
                            PlaylistSongRowView(
                                song: song,
                                isCurrentSong: index == currentIndex,
                                isPlaying: index == currentIndex && isPlaying,
                                onTap: {
                                    currentIndex = index
                                    stopAudio()
                                    loadSong(at: index)
                                    showPlaylist = false
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadLocalSongs() {
        print("🎵 [PlayMySong] Loading local songs...")
        isLoading = true
        
        Task {
            do {
                let localSongsList = try await SunoDataManager.shared.loadAllSavedSunoData()
                await MainActor.run {
                    self.localSongs = localSongsList
                    self.isLoading = false
                    print("🎵 [PlayMySong] Loaded \(localSongsList.count) local songs")
                    
                    // Setup audio player after loading
                    if !localSongsList.isEmpty {
                        setupAudioPlayer()
                    }
                }
            } catch {
                print("❌ [PlayMySong] Error loading local songs: \(error)")
                await MainActor.run {
                    self.localSongs = []
                    self.isLoading = false
                    // Fallback to original songs if local loading fails
                    setupAudioPlayer()
                }
            }
        }
    }
    
    private func setupAudioPlayer() {
        loadSong(at: currentIndex)
    }
    
    private func loadSong(at index: Int) {
        guard index >= 0 && index < displaySongs.count else { return }
        
        let song = displaySongs[index]
        print("🎵 [PlayMySong] Loading song: \(song.title)")
        print("🎵 [PlayMySong] Audio URL: \(song.audioUrl)")
        
        // Try to load from local file first, then fallback to URL
        let localFilePath = getLocalFilePath(for: song)
        let audioURL: URL
        
        if FileManager.default.fileExists(atPath: localFilePath.path) {
            print("🎵 [PlayMySong] Using local file: \(localFilePath.path)")
            audioURL = localFilePath
        } else {
            print("🎵 [PlayMySong] Local file not found, using remote URL")
            guard let url = URL(string: song.audioUrl) else { 
                print("❌ [PlayMySong] Invalid audio URL: \(song.audioUrl)")
                return 
            }
            audioURL = url
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.delegate = PlayMySongAudioDelegate { [self] in
                print("🎵 [PlayMySong] Audio playback finished")
                handlePlaybackFinished()
            }
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 0
            
            print("🎵 [PlayMySong] Audio player prepared. Duration: \(duration) seconds")
            
            // Auto-play
            let success = audioPlayer?.play() ?? false
            isPlaying = success
            print("🎵 [PlayMySong] Auto-play result: \(success)")
            
            startPlaybackTimer()
        } catch {
            print("❌ [PlayMySong] Error setting up audio player: \(error)")
        }
    }
    
    private func getLocalFilePath(for song: SunoData) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let sunoDataPath = documentsPath.appendingPathComponent("SunoData")
        let audioFileName = "\(song.id).mp3"
        return sunoDataPath.appendingPathComponent(audioFileName)
    }
    
    private func handlePlaybackFinished() {
        switch playMode {
        case .sequential:
            nextSong()
        case .repeatOne:
            currentTime = 0
            audioPlayer?.currentTime = 0
            audioPlayer?.play()
        case .shuffle:
            let randomIndex = Int.random(in: 0..<displaySongs.count)
            currentIndex = randomIndex
            stopAudio()
            loadSong(at: randomIndex)
        }
    }
    
    private func startPlaybackTimer() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let player = audioPlayer {
                currentTime = player.currentTime
            }
        }
    }
    
    private func togglePlayPause() {
        if isPlaying {
            audioPlayer?.pause()
        } else {
            audioPlayer?.play()
        }
        isPlaying.toggle()
    }
    
    private func previousSong() {
        let newIndex = currentIndex > 0 ? currentIndex - 1 : displaySongs.count - 1
        currentIndex = newIndex
        stopAudio()
        loadSong(at: newIndex)
    }
    
    private func nextSong() {
        let newIndex = currentIndex < displaySongs.count - 1 ? currentIndex + 1 : 0
        currentIndex = newIndex
        stopAudio()
        loadSong(at: newIndex)
    }
    
    private func cyclePlayMode() {
        let allModes = PlayMode.allCases
        if let currentModeIndex = allModes.firstIndex(of: playMode) {
            let nextIndex = (currentModeIndex + 1) % allModes.count
            playMode = allModes[nextIndex]
        }
    }
    
    private func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Audio Player Delegate
class PlayMySongAudioDelegate: NSObject, AVAudioPlayerDelegate {
    private let onFinish: () -> Void
    
    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("🎵 [AudioPlayerDelegate] Audio playback finished successfully: \(flag)")
        onFinish()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("❌ [AudioPlayerDelegate] Audio decode error: \(error?.localizedDescription ?? "Unknown error")")
    }
}

// MARK: - Playlist Song Row View
struct PlaylistSongRowView: View {
    let song: SunoData
    let isCurrentSong: Bool
    let isPlaying: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Album Art
            AsyncImage(url: URL(string: song.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image("demo_cover")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Song Info
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(song.modelName)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Status Indicator
            if isCurrentSong {
                if isPlaying {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "pause.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentSong ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCurrentSong ? Color.green : Color.clear, lineWidth: 2)
                )
        )
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Preview
struct PlayMySongScreen_Previews: PreviewProvider {
    static var previews: some View {
        PlayMySongScreen(
            songs: [
                SunoData(
                    id: "1",
                    audioUrl: "https://example.com/song1.mp3",
                    sourceAudioUrl: "",
                    streamAudioUrl: "",
                    sourceStreamAudioUrl: "",
                    imageUrl: "https://example.com/image1.jpg",
                    sourceImageUrl: "",
                    prompt: "Test song 1",
                    modelName: "V5",
                    title: "Starlit Reverie",
                    tags: "test",
                    createTime: 0,
                    duration: 180
                ),
                SunoData(
                    id: "2",
                    audioUrl: "https://example.com/song2.mp3",
                    sourceAudioUrl: "",
                    streamAudioUrl: "",
                    sourceStreamAudioUrl: "",
                    imageUrl: "https://example.com/image2.jpg",
                    sourceImageUrl: "",
                    prompt: "Test song 2",
                    modelName: "V5",
                    title: "Midnight Dreams",
                    tags: "test",
                    createTime: 0,
                    duration: 200
                )
            ],
            initialIndex: 0
        )
    }
}
