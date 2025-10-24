import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

// MARK: - Generate Suno Song Result Screen
struct GenerateSunoSongResultScreen: View {
    let sunoDataList: [SunoData]
    let onClose: () -> Void
    
    @State private var selectedSongIndex: Int = 0
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var audioPlayer: AVAudioPlayer?
    @State private var playbackTimer: Timer?
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0.0
    @State private var isScrubbing = false
    @State private var scrubTime: TimeInterval = 0
    @State private var downloadTask: Task<Void, Never>?
    
    // Download states for each song
    @State private var downloadedFileURLs: [String: URL] = [:]
    @State private var downloadingSongs: Set<String> = []
    @State private var savedToDevice: Set<String> = []
    
    // Export/Share
    @State private var showExportSheet = false
    @State private var showShareSheet = false
    @State private var currentFileURL: URL?
    
    @Environment(\.dismiss) private var dismiss
    
    private var currentSong: SunoData {
        sunoDataList[selectedSongIndex]
    }
    
    var body: some View {
        ZStack {
            // Background
            AivoSunsetBackground()
            
            VStack(spacing: 0) {
                headerView
                coverImageView
                songTitleView
                
                Spacer()
                // Songs List
                songsListView
                
                seekBarView
                bottomControlsView
            }
        }
        .onAppear {
            print("🎵 [SunoResult] Screen appeared with \(sunoDataList.count) songs")
            for (index, song) in sunoDataList.enumerated() {
                print("🎵 [SunoResult] Song \(index + 1): \(song.title) - \(song.duration)s")
            }
            startDownloadAllSongs()
        }
        .onDisappear {
            stopAudio()
            playbackTimer?.invalidate()
            downloadTask?.cancel()
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = currentFileURL {
                DocumentExporter(fileURL: url)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = currentFileURL {
                ActivityView(items: [url])
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack(spacing: 12) {
            Text("HERE'S YOUR SONGS")
                .font(.system(size: 24, weight: .black, design: .monospaced))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                onClose()
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
    
    // MARK: - Cover Image View
    private var coverImageView: some View {
        ZStack {
            // Cover image from Suno
            AsyncImage(url: URL(string: currentSong.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image("demo_cover")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            .frame(width: 280, height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: AivoTheme.Shadow.orange, radius: 20, x: 0, y: 10)
            
            // Download progress overlay
            if downloadingSongs.contains(currentSong.id) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.7))
                    .frame(width: 280, height: 280)
                    .overlay(
                        VStack {
                            Text("\(Int(downloadProgress * 100))%")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            Text("Downloading...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    )
            }
        }
    }
    
    // MARK: - Song Title View
    private var songTitleView: some View {
        VStack(spacing: 8) {
            Text(currentSong.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Duration: \(formatDuration(currentSong.duration))")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.top, 20)
    }
    
    // MARK: - Songs List View
    private var songsListView: some View {
        VStack(spacing: 12) {
            // Downloading status
            if !downloadingSongs.isEmpty {
                HStack {
                    Text("Downloading \(downloadingSongs.count)/\(sunoDataList.count)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            
            // Songs vertical list
            ScrollView {
                LazyVStack(spacing: 6) {
                       ForEach(Array(sunoDataList.enumerated()), id: \.element.id) { index, song in
                           SunoSongRowView(
                               song: song,
                               isSelected: index == selectedSongIndex,
                               isDownloaded: downloadedFileURLs[song.id] != nil,
                               isDownloading: downloadingSongs.contains(song.id),
                               isSavedToDevice: savedToDevice.contains(song.id),
                               onTap: {
                                   if downloadedFileURLs[song.id] != nil {
                                       selectedSongIndex = index
                                       loadSelectedSong()
                                   }
                               },
                               onSave: {
                                   if let fileURL = downloadedFileURLs[song.id] {
                                       saveToDevice(fileURL: fileURL, song: song)
                                   }
                               },
                               onExport: {
                                   if let fileURL = downloadedFileURLs[song.id] {
                                       currentFileURL = fileURL
                                       showExportSheet = true
                                   }
                               }
                           )
                       }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 20)
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
            .accentColor(AivoTheme.Primary.orange)
            .padding(.horizontal, 20)
            
            HStack {
                Text(formatTime(isScrubbing ? scrubTime : currentTime))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text(formatTime(duration))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 30)
    }
    
    // MARK: - Bottom Controls
    private var bottomControlsView: some View {
        HStack(spacing: 40) {
            Button(action: rewind10s) {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            
            Button(action: togglePlayPause) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.black)
                    .frame(width: 70, height: 70)
                    .background(AivoTheme.Primary.orange)
                    .clipShape(Circle())
                    .shadow(color: AivoTheme.Shadow.orange, radius: 10, x: 0, y: 0)
            }
            
            Button(action: forward10s) {
                Image(systemName: "goforward.10")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Helper Methods
    private func startDownloadAllSongs() {
        print("📥 [SunoResult] Starting download for all \(sunoDataList.count) songs")
        for song in sunoDataList {
            downloadSong(song)
        }
    }
    
    private func startDownloadCurrentSong() {
        downloadSong(currentSong)
    }
    
    private func downloadSong(_ song: SunoData) {
        print("📥 [SunoResult] Starting download for song: \(song.title)")
        print("📥 [SunoResult] Audio URL: \(song.audioUrl)")
        
        guard let url = URL(string: song.audioUrl) else { 
            print("❌ [SunoResult] Invalid URL for song: \(song.title)")
            return 
        }
        
        downloadingSongs.insert(song.id)
        downloadProgress = 0
        
        let ext = url.pathExtension.isEmpty ? "mp3" : url.pathExtension.lowercased()
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let sunoDataDirectory = documentsPath.appendingPathComponent("SunoData")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: sunoDataDirectory, withIntermediateDirectories: true)
        
        let fileName = "\(song.id)_audio.\(ext)"
        let localURL = sunoDataDirectory.appendingPathComponent(fileName)
        
        print("📥 [SunoResult] Download destination: \(localURL.path)")
        
        let downloader = ProgressiveDownloader(
            destinationURL: localURL,
            onProgress: { prog in
                withAnimation(.linear(duration: 0.06)) {
                    self.downloadProgress = prog
                }
            },
            onComplete: { fileURL in
                print("✅ [SunoResult] Download completed for song: \(song.title)")
                self.downloadingSongs.remove(song.id)
                self.downloadProgress = 1.0
                self.downloadedFileURLs[song.id] = fileURL
                
                // Save full SunoData to local storage
                Task {
                    do {
                        let savedURL = try await SunoDataManager.shared.saveSunoData(song)
                        await MainActor.run {
                            self.savedToDevice.insert(song.id)
                            print("💾 [SunoResult] Full SunoData saved to device: \(savedURL.path)")
                        }
                    } catch {
                        print("❌ [SunoResult] Error saving SunoData: \(error)")
                    }
                }
                
                // If this is the current song, setup audio player
                if song.id == self.currentSong.id {
                    print("🎵 [SunoResult] Setting up audio player for current song")
                    self.setupAudioPlayerWithURL(fileURL)
                }
            },
            onError: { error in
                print("❌ [SunoResult] Download error for song \(song.title): \(error)")
                self.downloadingSongs.remove(song.id)
            }
        )
        
        downloader.start(url: url)
    }
    
    private func loadSelectedSong() {
        guard let fileURL = downloadedFileURLs[currentSong.id] else { 
            print("⚠️ [SunoResult] Song not downloaded yet: \(currentSong.title)")
            return 
        }
        
        // Stop current audio before loading new song
        print("🎵 [SunoResult] Stopping current audio before loading new song")
        stopAudio()
        
        print("🎵 [SunoResult] Loading selected song: \(currentSong.title)")
        setupAudioPlayerWithURL(fileURL)
    }
    
    private func setupAudioPlayerWithURL(_ url: URL) {
        print("🎵 [SunoResult] Setting up audio player with URL: \(url.path)")
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            print("🎵 [SunoResult] Audio session configured successfully")
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = GenerateSongAudioPlayerDelegate { [self] in
                print("🎵 [SunoResult] Audio playback finished")
                isPlaying = false
                currentTime = 0
                playbackTimer?.invalidate()
            }
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 0
            
            print("🎵 [SunoResult] Audio player prepared. Duration: \(duration) seconds")
            
            let success = audioPlayer?.play() ?? false
            isPlaying = success
            print("🎵 [SunoResult] Auto-play result: \(success)")
            
            if !success {
                print("🎵 [SunoResult] Auto-play failed, retrying in 0.5 seconds...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let retry = self.audioPlayer?.play() ?? false
                    print("🎵 [SunoResult] Retry result: \(retry)")
                    self.isPlaying = retry
                }
            }
            startPlaybackTimer()
        } catch {
            print("❌ [SunoResult] Error setting up audio player: \(error)")
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
        if isPlaying { audioPlayer?.pause() } else { audioPlayer?.play() }
        isPlaying.toggle()
    }
    
    private func rewind10s() {
        let newTime = max(0, currentTime - 10)
        audioPlayer?.currentTime = newTime
        currentTime = newTime
    }
    
    private func forward10s() {
        let newTime = min(duration, currentTime + 10)
        audioPlayer?.currentTime = newTime
        currentTime = newTime
    }
    
    private func stopAudio() {
        print("🎵 [SunoResult] Stopping audio completely")
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func saveToDevice(fileURL: URL, song: SunoData) {
        print("💾 [SunoResult] Saving song to device: \(song.title)")
        // Song is already saved to Documents directory during download
        // This method is for future use if we need additional save functionality
        savedToDevice.insert(song.id)
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Song Row View
import SwiftUI

struct SunoSongRowView: View {
    let song: SunoData
    let isSelected: Bool
    let isDownloaded: Bool
    let isDownloading: Bool
    let isSavedToDevice: Bool
    let onTap: () -> Void
    let onSave: () -> Void
    let onExport: () -> Void

    var body: some View {
        // Card nền
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? AivoTheme.Primary.orange : .clear, lineWidth: 2)
                )

            // Nội dung: ảnh (trái sát), info (giữa), nút (phải sát)
            HStack(spacing: 12) {
                let coverSize: CGFloat = 60

                ZStack {
                    // Ảnh
                    AsyncImage(url: URL(string: song.imageUrl)) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image("demo_cover").resizable().scaledToFill()
                    }
                    .frame(width: coverSize, height: coverSize)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                // Khóa frame để overlay bám đúng khung ảnh
                .frame(width: coverSize, height: coverSize)
                .overlay { // lớp che mờ khi đang tải
                    if isDownloading {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.55))
                    }
                }
                // Icon download luôn ở CENTER
                .overlay(alignment: .center) {
                    if isDownloading {
                        Image(systemName: "arrow.down.circle")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                // Badge "đã tải" ở góc (chỉ hiện khi không còn tải)
                .overlay(alignment: .center) {
                    if !isDownloading && isDownloaded {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .background(Color.white)
                            .clipShape(Circle())
                            .padding(4)
                    }
                }
                .padding(.leading, 12)

                // INFO: chiếm toàn bộ phần còn lại
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.headline).fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1).truncationMode(.tail)

                    HStack(spacing: 14) {
                        Label(formatDuration(song.duration), systemImage: "clock.fill")
                            .labelStyle(.titleAndIcon)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)

                        Label(song.modelName, systemImage: "music.note")
                            .labelStyle(.titleAndIcon)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading) // <- chiếm hết
                .layoutPriority(1) // ưu tiên không bị bóp

                // BUTTONS: sát mép phải card
                HStack(spacing: 8) {
                    // Export button
                    Button {
                        onExport()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle().fill(Color.blue.opacity(0.8))
                            )
                    }
                    .disabled(!isDownloaded)
                    
                    // Save button
                    Button {
                        if isSavedToDevice {
                            onSave()
                        }
                    } label: {
                        Image(systemName: isSavedToDevice ? "checkmark.circle.fill" : "externaldrive.badge.plus")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle().fill(isSavedToDevice ? .green : AivoTheme.Primary.orange)
                            )
                    }
                    .disabled(!isDownloaded)
                }
                .padding(.trailing, 12) // sát mép phải card
            }
            .frame(height: 76) // chiều cao hàng nhất quán
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .onTapGesture { if isDownloaded { onTap() } }
        .opacity(isDownloaded ? 1.0 : 0.6)
        .padding(.vertical, 4)           // chỉ padding dọc
        // .padding(.horizontal, 12)      // nếu muốn card cách hai mép List; nếu cần “sát” list, bỏ dòng này

        // Nếu dùng trong List và muốn sát 2 mép của cell:
        // .listRowInsets(EdgeInsets())        // bỏ inset mặc định của List
        // .listRowSeparator(.hidden)          // tùy chọn: ẩn separator
    }

    private func formatDuration(_ duration: Double) -> String {
        let m = Int(duration) / 60
        let s = Int(duration) % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - UIKit wrappers for SwiftUI

/// Save to Files (UIDocumentPicker, iOS 14+)
struct DocumentExporter: UIViewControllerRepresentable {
    let fileURL: URL
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let vc = UIDocumentPickerViewController(forExporting: [fileURL], asCopy: true)
        vc.allowsMultipleSelection = false
        vc.shouldShowFileExtensions = true
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
}

/// Share Sheet (UIActivityViewController)
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    let activities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: items, applicationActivities: activities)
        return vc
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview
struct GenerateSunoSongResultScreen_Previews: PreviewProvider {
    static var previews: some View {
        GenerateSunoSongResultScreen(
            sunoDataList: [
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
                    title: "Test Song 1",
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
                    title: "Test Song 2",
                    tags: "test",
                    createTime: 0,
                    duration: 200
                )
            ],
            onClose: {}
        )
    }
}
