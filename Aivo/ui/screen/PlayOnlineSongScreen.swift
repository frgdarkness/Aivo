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
struct PlayOnlineSongScreen: View {
    let songs: [SunoData]
    let initialIndex: Int
    @Environment(\.dismiss) private var dismiss

    @StateObject private var streamPlayer = OnlineStreamPlayer.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var isScrubbing = false
    @State private var scrubTime: TimeInterval = 0
    @State private var isDownloaded = false
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0
    @State private var showPlaylist = false
    @State private var localSongs: [SunoData] = []
    @State private var isLoading = true
    @State private var showExportSheet = false
    @State private var currentFileURL: URL?
    @State private var isRotating: Bool = false
    @State private var headerHeight: CGFloat = 0
    @State private var showPremiumAlert = false
    @State private var showSubscriptionScreen = false
    @State private var timestampedLyrics: TimestampedLyricsData?
    @State private var lyricSentences: [PlayOnlineLyricSentence] = []
    @State private var currentSentenceIndex: Int = 0
    @State private var cachedCoverImageURL: URL?

    init(songs: [SunoData], initialIndex: Int = 0) {
        self.songs = songs
        self.initialIndex = initialIndex
    }

    private var currentSong: SunoData? { streamPlayer.currentSong }
    private var displaySongs: [SunoData] { streamPlayer.songs.isEmpty ? songs : streamPlayer.songs }

    var body: some View {
        ZStack {
            // Custom Background với gradient
            customBackgroundView

            // MAIN CONTENT
            VStack(spacing: 0) {
                Group {
                    if isLoading {
                        loadingView
                    } else if currentSong != nil {
                        mainContent
                    } else {
                        emptyView
                    }
                }
                
                // Banner Ad at very bottom, full width, for non-premium users
                if !subscriptionManager.isPremium {
                    BannerAdView()
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .sheet(isPresented: $showPlaylist) { playlistView }
        .sheet(isPresented: $showExportSheet) {
            if let url = currentFileURL {
                DocumentExporter(fileURL: url)
            }
        }
        .fullScreenCover(isPresented: $showSubscriptionScreen) {
            SubscriptionScreenIntro()
//            if SubscriptionManager.shared.isPremium {
//                SubscriptionScreen()
//            } else {
//                SubscriptionScreenIntro()
//            }
        }
        .alert("Export Limit Reached", isPresented: $showPremiumAlert) {
            Button("Upgrade to Premium", role: .none) {
                showSubscriptionScreen = true
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text("You have used all 3 free downloads for today. Upgrade to Premium for unlimited downloads and VIP features.")
        }
        .onAppear { onAppearTasks() }
        .onDisappear {
            // Reset animation state immediately when dismissing to prevent lag
            isRotating = false
        }
        .onChange(of: streamPlayer.currentSong?.id) { songId in
            // Stop any ongoing animation and reset rotation immediately when song changes
            isRotating = false
            
            // Load timestamped lyrics and check download state when song changes
            if let songId = songId {
                loadTimestampedLyrics(for: songId)
                checkIfDownloaded(songId: songId)
                
                // Cache cover image URL to prevent reload
                if let coverURL = getImageURLForSong(currentSong) {
                    cachedCoverImageURL = coverURL
                }
            }
        }
        .onChange(of: streamPlayer.isPlaying) { isPlaying in
            // Update rotation when playing state changes
            updateRotationState()
        }
        .onChange(of: streamPlayer.duration) { duration in
            // Update rotation when duration becomes available
            if duration > 0 {
                updateRotationState()
            }
        }
        .onChange(of: streamPlayer.currentTime) { currentTime in
            // Update current sentence based on playback time
            updateCurrentSentence(for: currentTime)
        }
        .onChange(of: streamPlayer.currentSong) { _ in
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
                    .font(.system(size: iPadScale(22))).foregroundColor(.white)
                    .frame(width: iPadScale(44), height: iPadScale(44))
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }

            Text("Now Playing")
                .font(.system(size: iPadScale(22)))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.leading, 6)

            Spacer()

            HStack(spacing: iPadScaleSmall(12)) {
                // Download Button
                Button(action: { downloadCurrentSong() }) {
                    ZStack {
                        if isDownloading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(DeviceScale.isIPad ? 1.4 : 0.8)
                        } else {
                            Image(systemName: isDownloaded ? "checkmark.circle.fill" : "arrow.down.circle")
                                .font(.system(size: iPadScale(22)))
                                .foregroundColor(isDownloaded ? .green : .white)
                        }
                    }
                    .frame(width: iPadScale(44), height: iPadScale(44))
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
                }
                .disabled(isDownloaded || isDownloading)

                // Export Button
                Button(action: { exportCurrentSong() }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: iPadScale(22))).foregroundColor(.white)
                        .frame(width: iPadScale(44), height: iPadScale(44))
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

    // MARK: - Album Art
    private var albumArtView: some View {
        AsyncImage(url: cachedCoverImageURL ?? getImageURLForSong(currentSong)) { phase in
            Group {
                switch phase {
                case .empty:
                    Image("demo_cover")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure(_):
                    Image("demo_cover")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                @unknown default:
                    Image("demo_cover")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
        }
        .frame(width: DeviceScale.isIPad ? 420 : 280, height: DeviceScale.isIPad ? 420 : 280)
        .clipShape(Circle())
        //.shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        // Use rotation3DEffect instead of rotationEffect for better GPU performance
        .rotation3DEffect(
            .degrees(isRotating ? 360 : 0),
            axis: (x: 0, y: 0, z: 1),
            perspective: 2.0
        )
        // Apply smooth animation mapped to state value to prevent interference from other state changes like downloading
        .animation(isRotating ? .linear(duration: 8).repeatForever(autoreverses: false) : .linear(duration: 0), value: isRotating)
        .drawingGroup() // Optimize rendering to single layer - reduces compositing overhead
    }

    // MARK: - Song Info
    private var songInfoView: some View {
        VStack(spacing: 6) {
            Text(currentSong?.title ?? "Unknown Title")
                .font(.system(size: iPadScale(22), weight: .bold))
                .foregroundColor(.white).multilineTextAlignment(.center).lineLimit(2)
                .padding(.top, iPadScaleSmall(12))
            
            Text(currentSong?.username ?? "Aivo Music")
                .font(.system(size: iPadScale(15)))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
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
        .frame(maxHeight: DeviceScale.isIPad ? 280 : 200) // Container height
    }
    
    // MARK: - Lyric View
    private var lyricView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: iPadScaleSmall(8)) {
                    if !lyricSentences.isEmpty {
                        // Display sentences from timestamped lyrics
                        ForEach(Array(lyricSentences.enumerated()), id: \.offset) { index, sentence in
                            Text(sentence.text)
                                .font(.system(size: iPadScale(16)))
                                .foregroundColor(.white)
                                .opacity(index == currentSentenceIndex ? 1.0 : 0.55)
                                .multilineTextAlignment(.center)
                                .lineSpacing(iPadScaleSmall(6))
                                .padding(.horizontal, 20)
                                .id(index) // ID for scroll proxy
                        }
                    } else if let lyric = parseLyric(from: currentSong?.prompt) {
                        // Fallback to prompt lyrics if no timestamped lyrics
                        Text(lyric)
                            .font(.system(size: iPadScale(16)))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineSpacing(iPadScaleSmall(6))
                            .padding(.horizontal, 20)
                    } else {
                        Text("Lyric not available")
                            .font(.system(size: iPadScale(16)))
                            .foregroundColor(.white.opacity(0.6))
                            .italic()
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 16)
            }
            .frame(maxHeight: DeviceScale.isIPad ? 260 : 150) // Lyric view max height
            .mask(
                // Gradient mask
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: .black, location: 0.25),
                        .init(color: .black, location: 0.75),
                        .init(color: .clear, location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .onChange(of: currentSentenceIndex) { newIndex in
                // Scroll to current sentence with animation
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }

    // MARK: - Playback Controls
    private var playbackControlsView: some View {
        VStack(spacing: 20) {
            seekBarView
            controlButtonsView
        }
        .padding(.horizontal, 20)
        .padding(.bottom, DeviceScale.isIPad ? 60 : 40)
    }

    private var seekBarView: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .leading) {
                // Background Track (dark gray - always visible, shows unloaded portion)
                GeometryReader { geo in
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: geo.size.width, height: 4)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
                .frame(height: 20)
                
                // Buffer Track (lighter gray - shows loaded/buffered portion)
                GeometryReader { geo in
                    let duration = max(0.1, streamPlayer.duration)
                    
                    // Calculate total buffered width from all loaded ranges
                    let maxBufferedTime = streamPlayer.loadedTimeRanges.map { $0.end.seconds }.max() ?? 0
                    let bufferWidth = geo.size.width * CGFloat(maxBufferedTime / duration)
                    
                    // Only show buffer bar when actually buffered
                    if maxBufferedTime > 0 {
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: min(bufferWidth, geo.size.width), height: 4)
                            .position(x: min(bufferWidth, geo.size.width) / 2, y: geo.size.height / 2)
                    }
                }
                .frame(height: 20) // Match slider interactive area
                
                // Native Slider
                Slider(
                    value: Binding(
                        get: { isScrubbing ? scrubTime : streamPlayer.currentTime },
                        set: { newValue in
                            scrubTime = newValue
                        }
                    ),
                    in: 0...max(0.1, streamPlayer.duration),
                    onEditingChanged: { editing in
                        if editing {
                            isScrubbing = true
                            scrubTime = streamPlayer.currentTime
                        } else {
                            // Perform the seek
                            streamPlayer.seek(to: scrubTime)
                            
                            // Delay resetting isScrubbing to prevent "jump back" jitter
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                isScrubbing = false
                            }
                        }
                    }
                )
                .accentColor(AivoTheme.Primary.orange)
            }

            HStack {
                Text(formatTime(isScrubbing ? scrubTime : streamPlayer.currentTime))
                    .font(.system(size: iPadScale(14))).foregroundColor(.white)
                Spacer()
                Text(formatTime(streamPlayer.duration))
                    .font(.system(size: iPadScale(14))).foregroundColor(.white)
            }
        }
    }

    private var controlButtonsView: some View {
        HStack(spacing: iPadScale(30)) {
            Button(action: { streamPlayer.changePlayMode() }) {
                Image(systemName: streamPlayer.playMode.icon)
                    .font(.system(size: iPadScale(22))).foregroundColor(.white).frame(width: iPadScale(44), height: iPadScale(44))
            }
            Button(action: { streamPlayer.previousSong() }) {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: iPadScale(22))).foregroundColor(.white).frame(width: iPadScale(44), height: iPadScale(44))
            }
            Button(action: { streamPlayer.togglePlayPause() }) {
                Image(systemName: streamPlayer.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: iPadScale(32))).foregroundColor(.black)
                    .frame(width: iPadScale(70), height: iPadScale(70))
                    .background(AivoTheme.Primary.orange)
                    .clipShape(Circle())
                    .shadow(color: AivoTheme.Shadow.orange, radius: 10, x: 0, y: 5)
            }
            Button(action: { streamPlayer.nextSong() }) {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: iPadScale(22))).foregroundColor(.white).frame(width: iPadScale(44), height: iPadScale(44))
            }
            Button(action: { showPlaylist = true }) {
                Image(systemName: "list.bullet")
                    .font(.system(size: iPadScale(22))).foregroundColor(.white).frame(width: iPadScale(44), height: iPadScale(44))
            }
        }
    }

    // MARK: - Playlist View
    private var playlistView: some View {
        ZStack {
            AivoSunsetBackground()
            
            // Dark overlay to make background darker
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Playlist")
                        .font(.system(size: iPadScale(22), weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Done") {
                        showPlaylist = false
                    }
                    .font(.system(size: iPadScale(16)))
                    .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // Subtitle with queue info
                HStack {
                    if !displaySongs.isEmpty {
                        Text("Next • \(displaySongs.count) songs")
                            .font(.system(size: iPadScale(15)))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // Song list
                if displaySongs.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text("No songs in queue")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollViewReader { proxy in
                        List {
                            ForEach(Array(displaySongs.enumerated()), id: \.offset) { index, song in
                                PlaylistRowView(
                                    song: song,
                                    index: index,
                                    isCurrent: index == streamPlayer.currentIndex,
                                    isPlaying: streamPlayer.isPlaying,
                                    onTap: {
                                        streamPlayer.loadSong(song, at: index, in: displaySongs)
                                    },
                                    onTogglePlayPause: {
                                        streamPlayer.togglePlayPause()
                                    },
                                    onDelete: {
                                        deleteSong(at: IndexSet(integer: index))
                                    }
                                )
                                .id(index)
                            }
                            .onMove { fromOffsets, toOffset in
                                moveSong(from: fromOffsets, to: toOffset)
                            }
                        }
                        .listStyle(.plain)
                        .environment(\.editMode, .constant(.active))
                        .onAppear {
                            // Scroll to currently playing song when playlist opens
                            if streamPlayer.currentIndex < displaySongs.count {
                                let currentSong = displaySongs[streamPlayer.currentIndex]
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation {
                                        proxy.scrollTo(streamPlayer.currentIndex, anchor: .center)
                                    }
                                }
                            }
                        }
                    }
                    .onAppear {
                        // Set brighter color for move handles
                        UITableView.appearance().tintColor = UIColor.white
                    }
                }
            }
        }
    }
    
    
    // MARK: - Playlist Actions
    private func moveSong(from fromOffsets: IndexSet, to toOffset: Int) {
        var mutableSongs = displaySongs
        mutableSongs.move(fromOffsets: fromOffsets, toOffset: toOffset)
        
        // Update streamPlayer's song list and adjust current index
        let oldIndex = streamPlayer.currentIndex
        streamPlayer.songs = mutableSongs
        
        // Recalculate current index after move
        if let movedIndex = fromOffsets.first {
            if movedIndex == oldIndex {
                // Current song was moved
                streamPlayer.currentIndex = toOffset > movedIndex ? toOffset - 1 : toOffset
            } else if movedIndex < oldIndex && toOffset > oldIndex {
                streamPlayer.currentIndex = oldIndex - 1
            } else if movedIndex > oldIndex && toOffset <= oldIndex {
                streamPlayer.currentIndex = oldIndex + 1
            }
        }
    }
    
    private func deleteSong(at indexSet: IndexSet) {
        var mutableSongs = displaySongs
        let oldIndex = streamPlayer.currentIndex
        
        // Check if we're deleting the currently playing song
        let deletingCurrentSong = indexSet.contains(oldIndex)
        
        mutableSongs.remove(atOffsets: indexSet)
        streamPlayer.songs = mutableSongs
        
        if deletingCurrentSong {
            // If current song deleted, play the song at the same index (or stop if empty)
            if !mutableSongs.isEmpty {
                let newIndex = min(oldIndex, mutableSongs.count - 1)
                streamPlayer.loadSong(mutableSongs[newIndex], at: newIndex, in: mutableSongs)
            }
        } else {
            // Adjust current index if needed
            let deletedBeforeCurrent = indexSet.filter { $0 < oldIndex }.count
            streamPlayer.currentIndex = oldIndex - deletedBeforeCurrent
        }
    }

    // MARK: - Timestamped Lyrics
    private func loadTimestampedLyrics(for songId: String) {
        if let lyrics = TimestampedLyricsManager.shared.getTimestampedLyrics(for: songId) {
            Logger.i("🎤 [PlayOnline] Loaded timestamped lyrics for song: \(songId)")
            Logger.d("🎤 [PlayOnline] Total words: \(lyrics.alignedWords.count)")
            Logger.d("🎤 [PlayOnline] Waveform data points: \(lyrics.waveformData.count)")
            Logger.d("🎤 [PlayOnline] Hoot CER: \(lyrics.hootCer)")
            Logger.d("🎤 [PlayOnline] Is streamed: \(lyrics.isStreamed)")
            
            // Store timestamped lyrics
            timestampedLyrics = lyrics
            
            // Parse lyrics into sentences
            parseLyricSentences(from: lyrics)
            
            // Log first few words as example
            let firstWords = lyrics.alignedWords.prefix(5)
            for word in firstWords {
                Logger.d("🎤 [PlayOnline] Word: '\(word.word)' | Start: \(word.startS)s | End: \(word.endS)s")
            }
        } else {
            Logger.d("🎤 [PlayOnline] No timestamped lyrics found for song: \(songId)")
            timestampedLyrics = nil
            lyricSentences = []
            currentSentenceIndex = 0
        }
    }
    
    // MARK: - Parse Lyric Sentences
    private func parseLyricSentences(from lyrics: TimestampedLyricsData) {
        var sentences: [PlayOnlineLyricSentence] = []
        var currentSentenceWords: [AlignedWord] = []
        var currentSentenceText = ""
        var pendingNewSentenceText: String? = nil
        var pendingNewSentenceFirstWord: AlignedWord? = nil
        
        for word in lyrics.alignedWords {
            let wordText = word.word
            
            // Process pending new sentence text first
            if let pendingText = pendingNewSentenceText {
                if !pendingText.isEmpty, let pendingWord = pendingNewSentenceFirstWord {
                    // Has pending text and word - use them as first part of new sentence
                    currentSentenceText = pendingText
                    currentSentenceWords = [pendingWord]
                    pendingNewSentenceText = nil
                    pendingNewSentenceFirstWord = nil
                } else {
                    // Pending text is empty string - this word is the first word of new sentence
                    // Start new sentence with this word
                    currentSentenceText = wordText
                    currentSentenceWords = [word]
                    // Clear pending and continue to next iteration since we've already processed this word
                    pendingNewSentenceText = nil
                    pendingNewSentenceFirstWord = nil
                    continue
                }
            }
            
            // Check for double newline first (paragraph break)
            if wordText.contains("\n\n") {
                let parts = wordText.components(separatedBy: "\n\n")
                
                // Add text before \n\n to current sentence
                if let beforeNewline = parts.first, !beforeNewline.trimmingCharacters(in: .whitespaces).isEmpty {
                    if currentSentenceWords.isEmpty {
                        currentSentenceText = beforeNewline.trimmingCharacters(in: .whitespaces)
                    } else {
                        currentSentenceText += " " + beforeNewline.trimmingCharacters(in: .whitespaces)
                    }
                    currentSentenceWords.append(word)
                }
                
                // End current sentence if it has content
                if !currentSentenceWords.isEmpty {
                    let startTime = currentSentenceWords.first?.startS ?? word.startS
                    sentences.append(PlayOnlineLyricSentence(
                        text: currentSentenceText.trimmingCharacters(in: .whitespacesAndNewlines),
                        startTime: startTime,
                        words: currentSentenceWords
                    ))
                }
                
                // Prepare new sentence with text after \n\n
                if parts.count > 1 {
                    let afterNewline = parts.last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    if !afterNewline.isEmpty {
                        // Text after \n\n - this word contains the first word of new sentence
                        pendingNewSentenceText = afterNewline
                        pendingNewSentenceFirstWord = word
                    } else {
                        // No text after \n\n - next word will be first word of new sentence
                        pendingNewSentenceText = ""
                        pendingNewSentenceFirstWord = nil
                    }
                } else {
                    currentSentenceText = ""
                    currentSentenceWords = []
                }
            } else if wordText.contains("\n") {
                // Single newline - end of sentence/line
                let parts = wordText.components(separatedBy: "\n")
                
                // Add text before \n to current sentence
                if let beforeNewline = parts.first, !beforeNewline.trimmingCharacters(in: .whitespaces).isEmpty {
                    if currentSentenceWords.isEmpty {
                        currentSentenceText = beforeNewline.trimmingCharacters(in: .whitespaces)
                    } else {
                        currentSentenceText += " " + beforeNewline.trimmingCharacters(in: .whitespaces)
                    }
                    currentSentenceWords.append(word)
                }
                
                // End current sentence if it has content
                if !currentSentenceWords.isEmpty {
                    let startTime = currentSentenceWords.first?.startS ?? word.startS
                    sentences.append(PlayOnlineLyricSentence(
                        text: currentSentenceText.trimmingCharacters(in: .whitespacesAndNewlines),
                        startTime: startTime,
                        words: currentSentenceWords
                    ))
                }
                
                // Prepare new sentence with text after \n
                if parts.count > 1 {
                    let afterNewline = parts.last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    if !afterNewline.isEmpty {
                        // Text after \n - this word contains the first word of new sentence
                        // Use this word's startS as the startTime for the new sentence
                        pendingNewSentenceText = afterNewline
                        pendingNewSentenceFirstWord = word
                    } else {
                        // Word ends with \n but no text after - next word will be first word of new sentence
                        pendingNewSentenceText = ""
                        pendingNewSentenceFirstWord = nil
                    }
                } else {
                    currentSentenceText = ""
                    currentSentenceWords = []
                }
            } else {
                // Regular word (no newline) - add to current sentence
                if currentSentenceWords.isEmpty {
                    // First word of sentence - use its startS as sentence startTime
                    currentSentenceText = wordText
                    currentSentenceWords = [word]
                } else {
                    // Append word to sentence with space
                    currentSentenceText += " " + wordText
                    currentSentenceWords.append(word)
                }
            }
        }
        
        // Add last sentence if exists
        if !currentSentenceWords.isEmpty {
            let startTime = currentSentenceWords.first?.startS ?? 0
            sentences.append(PlayOnlineLyricSentence(
                text: currentSentenceText.trimmingCharacters(in: .whitespacesAndNewlines),
                startTime: startTime,
                words: currentSentenceWords
            ))
        }
        
        lyricSentences = sentences
        currentSentenceIndex = 0
        
        Logger.d("🎤 [PlayOnline] Parsed \(sentences.count) sentences from lyrics")
        for (index, sentence) in sentences.enumerated() {
            Logger.d("🎤 [PlayOnline] Sentence \(index): '\(sentence.text.prefix(50))' | Start: \(sentence.startTime)s")
        }
    }
    
    // MARK: - Update Current Sentence
    private func updateCurrentSentence(for currentTime: TimeInterval) {
        guard !lyricSentences.isEmpty else { return }
        
        // Find the sentence that should be playing based on currentTime
        var newIndex = 0
        
        for (index, sentence) in lyricSentences.enumerated() {
            // Check if currentTime is within this sentence's time range
            let nextSentenceStartTime = index < lyricSentences.count - 1 
                ? lyricSentences[index + 1].startTime 
                : Double.infinity
            
            if currentTime >= sentence.startTime && currentTime < nextSentenceStartTime {
                newIndex = index
                break
            }
            
            // If we've passed all sentences, use the last one
            if index == lyricSentences.count - 1 && currentTime >= sentence.startTime {
                newIndex = index
            }
        }
        
        // Update index if changed (avoid unnecessary updates)
        if newIndex != currentSentenceIndex {
            currentSentenceIndex = newIndex
        }
    }
    
    // MARK: - Helpers
    private func onAppearTasks() {
        isLoading = true
        localSongs = songs
        
        // Load the initial song into the stream player only if it's not already playing it
        if !songs.isEmpty {
            let initialSong = songs[initialIndex]
            if streamPlayer.currentSong?.id != initialSong.id {
                streamPlayer.loadSong(initialSong, at: initialIndex, in: songs)
            }
            
            // Trigger rotation check after a short delay to ensure player state is updated
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                updateRotationState()
            }
        }
        
        isLoading = false
        
        // Check download state when opening song
        if let song = currentSong {
            checkIfDownloaded(songId: song.id)
            
            // Load timestamped lyrics when opening song
            loadTimestampedLyrics(for: song.id)
            
            // Cache cover image URL on appear
            if let coverURL = getImageURLForSong(song) {
                cachedCoverImageURL = coverURL
            }
        }
        
        // Initialize rotation state based on playing status
        updateRotationState()
    }
    
    private func updateRotationState() {
        // Only rotate when playing AND duration is available
        // Don't check isBuffering as it can be inconsistent
        let shouldRotate = streamPlayer.isPlaying && streamPlayer.duration > 0
        
        if shouldRotate {
            // Start rotation animation smoothly
            if !isRotating {
                // First time starting - reset and animate
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isRotating = true
                }
            }
        } else {
            // Stop rotation immediately
            isRotating = false
        }
    }
    
    private func checkIfDownloaded(songId: String) {
        // Check if song exists in local storage
        let localPath = getLocalFilePath(for: currentSong!)
        isDownloaded = FileManager.default.fileExists(atPath: localPath.path)
    }
    
    private func downloadCurrentSong() {
        guard let song = currentSong, !isDownloaded, !isDownloading else { return }
        
        // Non-premium users must watch a reward ad before downloading
        if !subscriptionManager.isPremium {
            Logger.d("📢 [Download] Non-premium user, showing reward ad before download...")
            AdManager.shared.showRewardAd { [self] _ in
                Logger.d("📢 [Download] Reward ad completed, proceeding with download")
                self.performDownload(song: song)
            }
        } else {
            performDownload(song: song)
        }
    }
    
    private func performDownload(song: SunoData) {
        isDownloading = true
        downloadProgress = 0
        
        Task {
            do {
                Logger.d("📥 [PlayOnline] Starting download for: \(song.title)")
                
                // Download and save the song
                let savedURL = try await SunoDataManager.shared.saveSunoData(song)
                
                await MainActor.run {
                    isDownloading = false
                    isDownloaded = true
                    downloadProgress = 1.0
                    Logger.i("✅ [PlayOnline] Downloaded successfully: \(song.title)")
                }
            } catch {
                Logger.e("❌ [PlayOnline] Download failed: \(error)")
                await MainActor.run {
                    isDownloading = false
                    downloadProgress = 0
                }
            }
        }
    }

    private func exportCurrentSong() {
        guard let song = currentSong else { return }
        
        // Non-premium users must watch a reward ad before exporting
        if !subscriptionManager.isPremium {
            Logger.d("📢 [Export] Non-premium user, showing reward ad before export...")
            AdManager.shared.showRewardAd { [self] _ in
                Logger.d("📢 [Export] Reward ad completed, proceeding with export")
                self.performExport(song: song)
            }
        } else {
            performExport(song: song)
        }
    }
    
    private func performExport(song: SunoData) {
        // Log Firebase event for export
        AnalyticsLogger.shared.logEventWithBundle(AnalyticsLogger.EVENT.EVENT_EXPORT_SONG, parameters: [
            "song_id": song.id,
            "song_title": song.title,
            "is_premium": subscriptionManager.isPremium,
            "timestamp": Date().timeIntervalSince1970
        ])
        
        Task {
            var sourceURL: URL?
            let localFilePath = getLocalFilePath(for: song)
            
            if FileManager.default.fileExists(atPath: localFilePath.path) {
                sourceURL = localFilePath
            } else {
                do {
                    sourceURL = try await SunoDataManager.shared.saveSunoData(song)
                } catch {
                    print("❌ Export error (download): \(error)")
                    return
                }
            }
            
            guard let validSourceURL = sourceURL else { return }
            
            // Prepare metadata (Cover Image)
            var coverImage: UIImage?
            // Try local cover first
            if let coverPath = SunoDataManager.shared.getLocalCoverPath(for: song.id),
               let data = try? Data(contentsOf: coverPath) {
                coverImage = UIImage(data: data)
            } 
            // Fallback to download cover if needed
            else if let url = URL(string: song.imageUrl), let data = try? Data(contentsOf: url) {
                coverImage = UIImage(data: data)
            }
            
            let finalURL = await prepareExportFileWithMetadata(sourceURL: validSourceURL, song: song, coverImage: coverImage)
            
            await MainActor.run {
                currentFileURL = finalURL
                showExportSheet = true
            }
        }
    }
    
    // Inject metadata and save to temp
    private func prepareExportFileWithMetadata(sourceURL: URL, song: SunoData, coverImage: UIImage?) async -> URL {
        return await withCheckedContinuation { continuation in
            // Sanitize song title for filename
            let sanitizedTitle = song.title
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: ":", with: "-")
                .replacingOccurrences(of: "?", with: "")
                .replacingOccurrences(of: "*", with: "")
                .replacingOccurrences(of: "\"", with: "")
                .replacingOccurrences(of: "<", with: "")
                .replacingOccurrences(of: ">", with: "")
                .replacingOccurrences(of: "|", with: "")
            
            let tempDir = FileManager.default.temporaryDirectory
            // Output as m4a for better metadata support
            let outputURL = tempDir.appendingPathComponent("\(sanitizedTitle).m4a")
            
            try? FileManager.default.removeItem(at: outputURL)
            
            MetadataInjector.injectMetadata(
                sourceURL: sourceURL,
                outputURL: outputURL,
                title: song.title,
                artist: song.modelName,
                artwork: coverImage
            ) { result in
                switch result {
                case .success(let url):
                    continuation.resume(returning: url)
                case .failure(let error):
                    print("⚠️ Metadata injection failed: \(error). Falling back to simple copy.")
                    // Fallback: Copy original file to temp with correct name
                    // If source is mp3, output will be mp3 named .m4a? No, keep original extension if fallback.
                    // But simplified: just try to copy to the target path (might fail if ext mismatch, so let's make a fallback path)
                    
                    let fallbackExtension = sourceURL.pathExtension
                    let fallbackURL = tempDir.appendingPathComponent("\(sanitizedTitle).\(fallbackExtension)")
                    try? FileManager.default.removeItem(at: fallbackURL)
                    try? FileManager.default.copyItem(at: sourceURL, to: fallbackURL)
                    continuation.resume(returning: fallbackURL)
                }
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
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.6)
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

// MARK: - PlayOnline-specific Lyric Sentence Model
struct PlayOnlineLyricSentence: Identifiable {
    let id = UUID()
    let text: String
    let startTime: Double
    let words: [AlignedWord]
}

// MARK: - Preview
struct PlayOnlineSongScreen_Previews: PreviewProvider {
    static var previews: some View {
        // Create mock songs
        let mockSongs = [
            SunoData(
                id: "preview_song_1",
                audioUrl: "https://example.com/audio1.mp3",
                sourceAudioUrl: "https://example.com/audio1.mp3",
                imageUrl: "",
                sourceImageUrl: "",
                prompt: "[Verse 1]\nThis is a preview song\nWith some sample lyrics\n\n[Chorus]\nSing along with me\nThis is just a preview",
                modelName: "Preview Artist",
                title: "Preview Song",
                tags: "preview,test",
                createTime: Int64(Date().timeIntervalSince1970),
                duration: 180.0
            ),
            SunoData(
                id: "preview_song_2",
                audioUrl: "https://example.com/audio2.mp3",
                sourceAudioUrl: "https://example.com/audio2.mp3",
                imageUrl: "",
                sourceImageUrl: "",
                prompt: "[Verse 1]\nAnother preview track\nFor testing purposes",
                modelName: "Another Artist",
                title: "Second Preview",
                tags: "preview,test",
                createTime: Int64(Date().timeIntervalSince1970),
                duration: 200.0
            )
        ]
        
        // Setup OnlineStreamPlayer with first song for preview
        let player = OnlineStreamPlayer.shared
        player.currentSong = mockSongs.first
        player.songs = mockSongs
        player.currentIndex = 0
        player.currentTime = 45.0
        player.duration = 180.0
        player.isPlaying = false
        
        return PlayOnlineSongScreen(songs: mockSongs, initialIndex: 0)
            .previewDisplayName("Play Online Song Screen")
    }
}


