import SwiftUI
import AVFoundation

// MARK: - Play My Song Screen
struct PlayMySongScreen: View {
    let songs: [SunoData]
    let initialIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var musicPlayer = MusicPlayer.shared
    @State private var isScrubbing = false
    @State private var scrubTime: TimeInterval = 0
    @State private var isFavorite = false
    @State private var showPlaylist = false
    @State private var localSongs: [SunoData] = []
    @State private var isLoading = true
    @State private var showMenu = false
    @State private var showExportSheet = false
    @State private var currentFileURL: URL?
    @State private var showDeleteAlert = false
    
    init(songs: [SunoData], initialIndex: Int = 0) {
        self.songs = songs
        self.initialIndex = initialIndex
    }
    
    private var currentSong: SunoData? {
        return musicPlayer.currentSong
    }
    
    private var displaySongs: [SunoData] {
        return musicPlayer.songs.isEmpty ? songs : musicPlayer.songs
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
                    // Header with close button
                    HStack {
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
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("No songs available")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Please try again later")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            print("🎵 [PlayMySong] onAppear - songs.count: \(songs.count), initialIndex: \(initialIndex)")
            print("🎵 [PlayMySong] onAppear - musicPlayer.currentSong: \(musicPlayer.currentSong?.title ?? "nil")")
            
            // Simply load songs for display - MusicPlayer should already be set up by caller
            loadSongsForDisplay()
            
            // Force rotation animation to start if music is playing
            if musicPlayer.isPlaying {
                // Trigger animation by toggling the rotation state
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // This will trigger the rotation animation
                }
            }
        }
        .onDisappear {
            // Don't stop music when dismissing - let it continue playing
            // Music will continue through MusicPlayer and show in PlayingBannerView
        }
        .onTapGesture {
            showMenu = false
        }
        .sheet(isPresented: $showPlaylist) {
            playlistView
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = currentFileURL {
                DocumentExporter(fileURL: url)
            }
        }
        .alert("Delete Song", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteCurrentSong()
            }
        } message: {
            Text("Are you sure you want to delete this song? This action cannot be undone.")
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
            
            // Title
            Text("Now Playing")
                .font(.system(size: 22))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.leading, 6)
            
            Spacer()
            
            // Right side buttons
            HStack(spacing: 12) {
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
                
                // Menu Button
                Button(action: {
                    showMenu.toggle()
                }) {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .overlay(alignment: .topTrailing) {
            if showMenu {
                menuView
            }
        }
    }
    
    // MARK: - Menu View
    private var menuView: some View {
        VStack(alignment: .trailing, spacing: 0) {
            VStack(spacing: 0) {
                Button(action: {
                    exportCurrentSong()
                    showMenu = false
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                        Text("Export to Device")
                            .font(.system(size: 16, weight: .medium))
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                Button(action: {
                    showDeleteAlert = true
                    showMenu = false
                }) {
                    HStack {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                        Text("Delete Song")
                            .font(.system(size: 16, weight: .medium))
                        Spacer()
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .frame(width: 120)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .padding(.top, 60)
        .padding(.trailing, 20)
        .onTapGesture {
            showMenu = false
        }
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
            .rotationEffect(.degrees(musicPlayer.isPlaying ? 360 : 0))
            .animation(
                musicPlayer.isPlaying ? 
                .linear(duration: 10).repeatForever(autoreverses: false) : 
                .easeInOut(duration: 0.5),
                value: musicPlayer.isPlaying
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
                    get: { isScrubbing ? scrubTime : musicPlayer.currentTime },
                    set: { newVal in
                        if isScrubbing { scrubTime = newVal } else { musicPlayer.currentTime = newVal }
                    }
                ),
                in: 0...max(0.1, musicPlayer.duration),
                onEditingChanged: { editing in
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
            
            HStack {
                Text(formatTime(isScrubbing ? scrubTime : musicPlayer.currentTime))
                    .font(.caption)
                    .foregroundColor(.white)
                Spacer()
                Text(formatTime(musicPlayer.duration))
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
                musicPlayer.changePlayMode()
            }) {
                Image(systemName: musicPlayer.playMode.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            
            // Previous Button
            Button(action: {
                musicPlayer.previousSong()
            }) {
                Image(systemName: "backward.end.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            
            // Play/Pause Button
            Button(action: {
                musicPlayer.togglePlayPause()
            }) {
                Image(systemName: musicPlayer.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.black)
                    .frame(width: 70, height: 70)
                    .background(AivoTheme.Primary.orange)
                    .clipShape(Circle())
                    .shadow(color: AivoTheme.Shadow.orange, radius: 10, x: 0, y: 5)
            }
            
            // Next Button
            Button(action: {
                musicPlayer.nextSong()
            }) {
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
                                isCurrentSong: index == musicPlayer.currentIndex,
                                isPlaying: index == musicPlayer.currentIndex && musicPlayer.isPlaying,
                                onTap: {
                                    musicPlayer.loadSong(song, at: index, in: displaySongs)
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
    private func loadSongsForDisplay() {
        print("🎵 [PlayMySong] Loading songs for display...")
        isLoading = true
        
        // Use the songs passed from caller
        localSongs = songs
        isLoading = false
        
        print("🎵 [PlayMySong] Loaded \(songs.count) songs for display")
        print("🎵 [PlayMySong] Current song: \(musicPlayer.currentSong?.title ?? "nil")")
    }
    
    
    private func exportCurrentSong() {
        guard let song = currentSong else { return }
        
        print("📤 [PlayMySong] Exporting current song: \(song.title)")
        
        // Try to find local file first
        let localFilePath = getLocalFilePath(for: song)
        
        if FileManager.default.fileExists(atPath: localFilePath.path) {
            print("📤 [PlayMySong] Using local file for export: \(localFilePath.path)")
            currentFileURL = localFilePath
            showExportSheet = true
        } else {
            print("📤 [PlayMySong] Local file not found, trying to download...")
            // If local file doesn't exist, try to download it
            Task {
                do {
                    let downloadedURL = try await SunoDataManager.shared.saveSunoData(song)
                    await MainActor.run {
                        self.currentFileURL = downloadedURL
                        self.showExportSheet = true
                    }
                } catch {
                    print("❌ [PlayMySong] Error downloading song for export: \(error)")
                }
            }
        }
    }
    
    private func getLocalFilePath(for song: SunoData) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let sunoDataPath = documentsPath.appendingPathComponent("SunoData")
        
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
            let filePath = sunoDataPath.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: filePath.path) {
                print("🎵 [PlayMySong] Found local file: \(fileName)")
                return filePath
            }
        }
        
        // Default fallback
        let audioFileName = "\(song.id)_audio.mp3"
        return sunoDataPath.appendingPathComponent(audioFileName)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func deleteCurrentSong() {
        guard let song = currentSong else { return }
        
        print("🗑️ [PlayMySong] Deleting song: \(song.title)")
        
        Task {
            do {
                // Delete from SunoDataManager
                try await SunoDataManager.shared.deleteSunoData(song)
                
                // Delete local audio file
                let localFilePath = getLocalFilePath(for: song)
                if FileManager.default.fileExists(atPath: localFilePath.path) {
                    try FileManager.default.removeItem(at: localFilePath)
                    print("🗑️ [PlayMySong] Deleted local file: \(localFilePath.path)")
                }
                
                await MainActor.run {
                    // Remove from current songs list
                    if let index = musicPlayer.songs.firstIndex(where: { $0.id == song.id }) {
                        var updatedSongs = musicPlayer.songs
                        updatedSongs.remove(at: index)
                        musicPlayer.songs = updatedSongs
                        
                        // If this was the current song, move to next
                        if index == musicPlayer.currentIndex {
                            if !updatedSongs.isEmpty {
                                let nextIndex = min(index, updatedSongs.count - 1)
                                musicPlayer.loadSong(updatedSongs[nextIndex], at: nextIndex, in: updatedSongs)
                            } else {
                                musicPlayer.stop()
                            }
                        } else if index < musicPlayer.currentIndex {
                            musicPlayer.currentIndex -= 1
                        }
                    }
                    
                    // Update local songs for display
                    loadSongsForDisplay()
                }
                
                print("✅ [PlayMySong] Song deleted successfully")
            } catch {
                print("❌ [PlayMySong] Error deleting song: \(error)")
            }
        }
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
                        .foregroundColor(AivoTheme.Primary.orange)
                } else {
                    Image(systemName: "pause.circle.fill")
                        .font(.title3)
                        .foregroundColor(AivoTheme.Primary.orange)
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
                        .stroke(isCurrentSong ? AivoTheme.Primary.orange : Color.clear, lineWidth: 2)
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
