import SwiftUI
import AVFoundation

// MARK: - PreferenceKey để đo chiều cao header
private struct HeaderHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Play My Song Screen
struct PlayMySongScreen: View {
    let songs: [SunoData]
    let initialIndex: Int
    @Environment(\.dismiss) private var dismiss

    @StateObject private var musicPlayer = MusicPlayer.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
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
    @State private var rotationAngle: Double = 0
    @State private var headerHeight: CGFloat = 0   // <- chiều cao header
    @State private var showEditSheet = false
    @State private var showPremiumAlert = false
    @State private var showSubscriptionScreen = false

    init(songs: [SunoData], initialIndex: Int = 0) {
        self.songs = songs
        self.initialIndex = initialIndex
    }

    private var currentSong: SunoData? { musicPlayer.currentSong }
    private var displaySongs: [SunoData] { musicPlayer.songs.isEmpty ? songs : musicPlayer.songs }

    var body: some View {
        ZStack {
            // Custom Background với gradient
            customBackgroundView

            // MAIN CONTENT
            Group {
                if isLoading {
                    loadingView
                } else if currentSong != nil {
                    mainContent
                } else {
                    emptyView
                }
            }
        }
        // ✅ MENU OVERLAY Ở TẦNG NGOÀI CÙNG
        .overlay {
            if showMenu {
                ZStack(alignment: .topTrailing) {
                    // blocker để bắt tap ngoài menu
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .onTapGesture { 
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                showMenu = false
                            }
                        }

                    menuView
                        .padding(.top, headerHeight + 8 + 50) // đặt dưới header
                        .padding(.trailing, 20)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
                .zIndex(2)
            }
        }
        .sheet(isPresented: $showPlaylist) { playlistView }
        .sheet(isPresented: $showExportSheet) {
            if let url = currentFileURL { DocumentExporter(fileURL: url) }
        }
        .alert("Delete Song", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { deleteCurrentSong() }
        } message: {
            Text("Are you sure you want to delete this song? This action cannot be undone.")
        }
        .fullScreenCover(isPresented: $showSubscriptionScreen) {
            SubscriptionScreen()
        }
        .alert("Premium Feature", isPresented: $showPremiumAlert) {
            Button("Upgrade Now") {
                showSubscriptionScreen = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This feature is exclusive to Premium members. Do you want to upgrade now?")
        }
        .overlay {
            if showEditSheet, let song = currentSong {
                EditSongInfoDialog(song: song) {
                    showEditSheet = false
                }
            }
        }
        .onAppear { onAppearTasks() }
        .onDisappear {
            // Reset animation state immediately when dismissing to prevent lag
            rotationAngle = 0
        }
        .onChange(of: musicPlayer.isPlaying) { isPlaying in
            if isPlaying {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) { rotationAngle = 0 }
            }
        }
        .onChange(of: currentSong?.id) { songId in
            // Update favorite state when song changes
            if let songId = songId {
                isFavorite = FavoriteManager.shared.isFavorite(songId: songId)
            }
        }
        .onChange(of: musicPlayer.currentSong) { _ in
            // Force refresh UI when MusicPlayer changes song
            // This helps update cover image when playing next song
        }
    }

    // MARK: - Các block view tách gọn
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView().scaleEffect(1.5).tint(.white)
            Text("Loading songs...").font(.headline).foregroundColor(.white)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2).foregroundColor(.white)
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
            Text("No songs available").font(.headline).foregroundColor(.white)
            Text("Please try again later").font(.subheadline).foregroundColor(.white.opacity(0.7))
            Spacer()
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            headerView
            Spacer()
            albumArtView
                .zIndex(0) // dưới menu
            Spacer()
            songInfoView
            
            // Lyric container để control height và đẩy các view khác
            lyricContainerView
            
            Spacer()
            playbackControlsView
            Spacer()
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            // Back Button
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title2).foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }

            Text("Now Playing")
                .font(.system(size: 22))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.leading, 6)

            Spacer()

            HStack(spacing: 12) {
                Button(action: { toggleFavorite() }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundColor(isFavorite ? .red : .white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }

                Button(action: { 
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { 
                        showMenu.toggle() 
                    } 
                }) {
                    Image(systemName: "ellipsis")
                        .font(.title2).foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        // đo chiều cao header để đặt menu ngay bên dưới
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: HeaderHeightKey.self, value: geo.size.height)
            }
        )
        .onPreferenceChange(HeaderHeightKey.self) { headerHeight = $0 }
    }

    // MARK: - Menu (chiều ngang ôm theo item dài nhất)
    private var menuView: some View {
        VStack(alignment: .leading, spacing: 0) {         // <- căn trái toàn bộ
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    showMenu = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showEditSheet = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "pencil").font(.system(size: 16))
                    Text("Edit Song Info")
                        .font(.system(size: 16, weight: .medium))
                        .multilineTextAlignment(.leading)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            Divider().background(Color.white.opacity(0.2))

            Button {
                exportCurrentSong()
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    showMenu = false
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up").font(.system(size: 16))
                    Text("Export to Device")
                        .font(.system(size: 16, weight: .medium))
                        .multilineTextAlignment(.leading)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            Divider().background(Color.white.opacity(0.2))

            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    showMenu = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showDeleteAlert = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash").font(.system(size: 16))
                    Text("Delete Song")
                        .font(.system(size: 16, weight: .medium))
                        .multilineTextAlignment(.leading)
                }
                .foregroundColor(.red)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .fixedSize(horizontal: true, vertical: false)      // <- ôm theo item dài nhất
        .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 6)
        .transition(.opacity)
    }

    // MARK: - Album Art
    private var albumArtView: some View {
        AsyncImage(url: getImageURLForSong(currentSong)) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            Image("demo_cover").resizable().aspectRatio(contentMode: .fill)
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
    }

    // MARK: - Song Info
    private var songInfoView: some View {
        VStack(spacing: 8) {
            Text(currentSong?.title ?? "Unknown Title")
                .font(.title2).fontWeight(.bold)
                .foregroundColor(.white).multilineTextAlignment(.center).lineLimit(2)

            Text(currentSong?.modelName ?? "Unknown Artist")
                .font(.subheadline).foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            // Duration display
            Text(formatDuration(currentSong?.duration ?? 0))
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
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
    
    // MARK: - Lyric Container
    private var lyricContainerView: some View {
        VStack {
            lyricView
        }
        .frame(maxHeight: 200) // Container height để đẩy các view khác
    }
    
    // MARK: - Lyric View
    private var lyricView: some View {
        ScrollView {
            VStack(spacing: 8) {
                if let lyric = parseLyric(from: currentSong?.prompt) {
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
        .frame(maxHeight: 150) // Lyric view max height 150pt
        .mask(
            // Gradient mask: trên/dưới nhạt, giữa đậm
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0.0),      // Trên: trong suốt
                    .init(color: .black, location: 0.2),      // Chuyển đậm dần
                    .init(color: .black, location: 0.8),      // Giữa: đậm
                    .init(color: .clear, location: 1.0)       // Dưới: trong suốt
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Playback Controls
    private var playbackControlsView: some View {
        VStack(spacing: 20) {
            seekBarView
            controlButtonsView
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }

    private var seekBarView: some View {
        VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: { isScrubbing ? scrubTime : musicPlayer.currentTime },
                    set: { v in if isScrubbing { scrubTime = v } else { musicPlayer.currentTime = v } }
                ),
                in: 0...max(0.1, musicPlayer.duration),
                onEditingChanged: { editing in
                    if editing {
                        isScrubbing = true; scrubTime = musicPlayer.currentTime
                    } else {
                        isScrubbing = false; musicPlayer.seek(to: scrubTime)
                    }
                }
            )
            .accentColor(AivoTheme.Primary.orange)

            HStack {
                Text(formatTime(isScrubbing ? scrubTime : musicPlayer.currentTime))
                    .font(.caption).foregroundColor(.white)
                Spacer()
                Text(formatTime(musicPlayer.duration))
                    .font(.caption).foregroundColor(.white)
            }
        }
    }

    private var controlButtonsView: some View {
        HStack(spacing: 30) {
            Button(action: { musicPlayer.changePlayMode() }) {
                Image(systemName: musicPlayer.playMode.icon)
                    .font(.title2).foregroundColor(.white).frame(width: 44, height: 44)
            }
            Button(action: { musicPlayer.previousSong() }) {
                Image(systemName: "backward.end.fill")
                    .font(.title2).foregroundColor(.white).frame(width: 44, height: 44)
            }
            Button(action: { musicPlayer.togglePlayPause() }) {
                Image(systemName: musicPlayer.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 32)).foregroundColor(.black)
                    .frame(width: 70, height: 70)
                    .background(AivoTheme.Primary.orange)
                    .clipShape(Circle())
                    .shadow(color: AivoTheme.Shadow.orange, radius: 10, x: 0, y: 5)
            }
            Button(action: { musicPlayer.nextSong() }) {
                Image(systemName: "forward.end.fill")
                    .font(.title2).foregroundColor(.white).frame(width: 44, height: 44)
            }
            Button(action: { showPlaylist = true }) {
                Image(systemName: "list.bullet")
                    .font(.title2).foregroundColor(.white).frame(width: 44, height: 44)
            }
        }
    }

    // MARK: - Playlist View (giữ nguyên như trước)
    private var playlistView: some View {
        ZStack {
            AivoSunsetBackground()
            VStack(spacing: 0) {
                HStack {
                    Text("Playlist").font(.title2).fontWeight(.bold).foregroundColor(.white)
                    Spacer()
                    Button("Done") { showPlaylist = false }.foregroundColor(.white)
                }
                .padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 20)

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

    // MARK: - Helpers
    private func onAppearTasks() {
        isLoading = true
        localSongs = songs
        isLoading = false
        
        // Load favorite state when opening song
        if let song = currentSong {
            isFavorite = FavoriteManager.shared.isFavorite(songId: song.id)
        }
        
        if musicPlayer.isPlaying {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
            }
        }
    }
    
    private func toggleFavorite() {
        guard let song = currentSong else { return }
        
        isFavorite = FavoriteManager.shared.toggleFavorite(songId: song.id)
        
        print("❤️ [Favorite] \(isFavorite ? "Added" : "Removed") favorite: \(song.title)")
    }

    private func exportCurrentSong() {
        // Check subscription first
        guard subscriptionManager.isPremium else {
            showPremiumAlert = true
            return
        }
        
        guard let song = currentSong else { return }
        let localFilePath = getLocalFilePath(for: song)
        if FileManager.default.fileExists(atPath: localFilePath.path) {
            currentFileURL = localFilePath
            showExportSheet = true
        } else {
            Task {
                do {
                    let downloadedURL = try await SunoDataManager.shared.saveSunoData(song)
                    await MainActor.run {
                        currentFileURL = downloadedURL
                        showExportSheet = true
                    }
                } catch { print("❌ Export error: \(error)") }
            }
        }
    }

    private func getLocalFilePath(for song: SunoData) -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = documents.appendingPathComponent("SunoData")
        let names = [
            "\(song.id)_audio.mp3", "\(song.id)_audio.wav", "\(song.id)_audio.m4a",
            "\(song.id).mp3", "\(song.id).wav", "\(song.id).m4a"
        ]
        for name in names {
            let p = dir.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: p.path) { return p }
        }
        return dir.appendingPathComponent("\(song.id)_audio.mp3")
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60, s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }

    private func deleteCurrentSong() {
        guard let song = currentSong else { return }
        Task {
            do {
                try await SunoDataManager.shared.deleteSunoData(song)
                let local = getLocalFilePath(for: song)
                if FileManager.default.fileExists(atPath: local.path) {
                    try FileManager.default.removeItem(at: local)
                }
                await MainActor.run {
                    if let idx = musicPlayer.songs.firstIndex(where: { $0.id == song.id }) {
                        var arr = musicPlayer.songs
                        arr.remove(at: idx)
                        musicPlayer.songs = arr
                        if idx == musicPlayer.currentIndex {
                            if !arr.isEmpty {
                                let next = min(idx, arr.count - 1)
                                musicPlayer.loadSong(arr[next], at: next, in: arr)
                            } else { musicPlayer.stop() }
                        } else if idx < musicPlayer.currentIndex {
                            musicPlayer.currentIndex -= 1
                        }
                    }
                }
            } catch { print("❌ Delete error: \(error)") }
        }
    }
    
    // MARK: - Lyric Parsing
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
    
    // MARK: - Custom Background
    private var customBackgroundView: some View {
        GeometryReader { geometry in
            ZStack {
                // Nửa trên: Ảnh cover blur
                VStack {
                    AsyncImage(url: getImageURLForSong(currentSong)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .blur(radius: 20)
                            .scaleEffect(1.2)
                            .clipped()  // Clip early to prevent overflow issues
                    } placeholder: {
                        Image("demo_cover")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .blur(radius: 20)
                            .scaleEffect(1.2)
                            .clipped()
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
                        .init(color: Color.black.opacity(0.05), location: 0.0),    // 5% ở đỉnh
                        .init(color: Color.black.opacity(1.0), location: 0.5),      // 80% ở giữa
                        .init(color: Color.black.opacity(1.0), location: 1.0)       // 100% ở cuối
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .drawingGroup()  // ✅ OPTIMIZATION: Render to single layer to reduce lag
        }
        .ignoresSafeArea()
    }
}

// MARK: - Playlist Row (giữ nguyên)
struct PlaylistSongRowView: View {
    let song: SunoData
    let isCurrentSong: Bool
    let isPlaying: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: song.imageUrl)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Image("demo_cover").resizable().aspectRatio(contentMode: .fill)
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(song.title).font(.headline).fontWeight(.medium).foregroundColor(.white).lineLimit(1)
                Text(song.modelName).font(.subheadline).foregroundColor(.white.opacity(0.7)).lineLimit(1)
            }

            Spacer()

            if isCurrentSong {
                (isPlaying ? Image(systemName: "speaker.wave.2.fill") : Image(systemName: "pause.circle.fill"))
                    .font(.title3).foregroundColor(AivoTheme.Primary.orange)
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
        .onTapGesture { onTap() }
    }
}

// MARK: - Edit Song Info Dialog
struct EditSongInfoDialog: View {
    let song: SunoData
    let onDismiss: () -> Void
    
    @State private var editedTitle: String
    @State private var editedModelName: String
    @State private var isSaving = false
    
    init(song: SunoData, onDismiss: @escaping () -> Void) {
        self.song = song
        self.onDismiss = onDismiss
        self._editedTitle = State(initialValue: song.title)
        self._editedModelName = State(initialValue: song.modelName)
    }
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // Dialog Content
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Edit Song Info")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.1))
                )
                
                VStack(spacing: 20) {
                    // Song Title Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Song Title")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        TextField("Enter title", text: $editedTitle)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.15))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    // Artist Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Artist")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        TextField("Enter artist", text: $editedModelName)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.15))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        Button(action: onDismiss) {
                            Text("Cancel")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(10)
                        }
                        
                        Button(action: saveChanges) {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Save")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(AivoTheme.Primary.orange)
                        .cornerRadius(10)
                        .disabled(isSaving || editedTitle.isEmpty || editedModelName.isEmpty)
                        .opacity(isSaving || editedTitle.isEmpty || editedModelName.isEmpty ? 0.5 : 1.0)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .background(
                ZStack {
                    // Base: Đen với gradient nhẹ
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.15, green: 0.12, blue: 0.16), // Dark purple-black
                                    Color(red: 0.08, green: 0.06, blue: 0.1)  // Darker black
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    // Border accent cam vàng
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    AivoTheme.Primary.orange,
                                    AivoTheme.Primary.orange.opacity(0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
                .shadow(color: AivoTheme.Shadow.orange.opacity(0.5), radius: 30, x: 0, y: 15)
            )
            .padding(.horizontal, 40)
            .frame(maxWidth: 400)
        }
    }
    
    private func saveChanges() {
        isSaving = true
        
        Task {
            do {
                // Update metadata file
                try await SunoDataManager.shared.updateSunoData(song.id, title: editedTitle, modelName: editedModelName)
                
                await MainActor.run {
                    // Update MusicPlayer's current song if it's the edited one
                    if let currentSong = MusicPlayer.shared.currentSong, currentSong.id == song.id {
                        // Create updated song data
                        let updatedSong = SunoData(
                            id: currentSong.id,
                            audioUrl: currentSong.audioUrl,
                            sourceAudioUrl: currentSong.sourceAudioUrl,
                            streamAudioUrl: currentSong.streamAudioUrl,
                            sourceStreamAudioUrl: currentSong.sourceStreamAudioUrl,
                            imageUrl: currentSong.imageUrl,
                            sourceImageUrl: currentSong.sourceImageUrl,
                            prompt: currentSong.prompt,
                            modelName: editedModelName,
                            title: editedTitle,
                            tags: currentSong.tags,
                            createTime: currentSong.createTime,
                            duration: currentSong.duration
                        )
                        
                        // Update in MusicPlayer
                        if let index = MusicPlayer.shared.songs.firstIndex(where: { $0.id == song.id }) {
                            var songs = MusicPlayer.shared.songs
                            songs[index] = updatedSong
                            MusicPlayer.shared.songs = songs
                        }
                        
                        MusicPlayer.shared.currentSong = updatedSong
                    }
                    
                    isSaving = false
                    onDismiss()
                    
                    Logger.d("✅ [EditSong] Successfully updated: \(editedTitle) by \(editedModelName)")
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    Logger.e("❌ [EditSong] Error updating song info: \(error)")
                }
            }
        }
    }
}

// MARK: - Helper Functions
func getImageURLForSong(_ song: SunoData?) -> URL? {
    guard let song = song else { return nil }
    
    // Check if local cover exists first
    if let localCoverPath = SunoDataManager.shared.getLocalCoverPath(for: song.id) {
        return localCoverPath
    }
    
    // Fallback to source URL
    return URL(string: song.sourceImageUrl)
}
