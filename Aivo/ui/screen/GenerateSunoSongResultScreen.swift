import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

// MARK: - Generate Suno Song Result Screen
struct GenerateSunoSongResultScreen: View {
    let sunoDataList: [SunoData]
    let onClose: () -> Void
    
    @State private var selectedSongIndex: Int = 0
    @State private var isScrubbing = false
    @State private var scrubTime: TimeInterval = 0
    @State private var downloadTask: Task<Void, Never>?
    
    @StateObject private var musicPlayer = MusicPlayer.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    // Download states for each song
    @State private var downloadedFileURLs: [String: URL] = [:]
    @State private var downloadingSongs: Set<String> = []
    @State private var savedToDevice: Set<String> = []
    
    // Export/Share
    @State private var showExportSheet = false
    @State private var showShareSheet = false
    @State private var currentFileURL: URL?
    
    // Download warning alert
    @State private var showDownloadAlert = false
    
    // Premium alert for export
    @State private var showPremiumAlert = false
    @State private var showSubscriptionScreen = false
    
    @Environment(\.dismiss) private var dismiss
    
    private var currentSong: SunoData {
        guard selectedSongIndex >= 0 && selectedSongIndex < sunoDataList.count else {
            Logger.e("❌ [SunoResult] Invalid selectedSongIndex: \(selectedSongIndex), list count: \(sunoDataList.count)")
            // Return first song as fallback, or create a dummy if empty
            return sunoDataList.first ?? SunoData(
                id: "error",
                audioUrl: "",
                sourceAudioUrl: "",
                streamAudioUrl: "",
                sourceStreamAudioUrl: "",
                imageUrl: "",
                sourceImageUrl: "",
                prompt: "",
                modelName: "Error",
                title: "Error",
                tags: "",
                createTime: 0,
                duration: 0
            )
        }
        return sunoDataList[selectedSongIndex]
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
            // Log screen view
            FirebaseLogger.shared.logScreenView(FirebaseLogger.EVENT_SCREEN_PLAY_SONG)
            
            Logger.d("🎵 [SunoResult] Screen appeared with \(sunoDataList.count) songs")
            
            // Always reset to 0 when screen appears to ensure valid index
            selectedSongIndex = 0
            
            // Stop any currently playing song from previous screen to avoid showing wrong seekbar progress
            if musicPlayer.isPlaying {
                Logger.d("🛑 [SunoResult] Stopping current playback to avoid showing wrong seekbar")
                musicPlayer.pause()
            }
            
            // Reset scrub time
            isScrubbing = false
            scrubTime = 0
            
            for (index, song) in sunoDataList.enumerated() {
                Logger.d("🎵 [SunoResult] Song \(index + 1): \(song.title) - \(song.duration)s")
            }
            
            if !sunoDataList.isEmpty {
                startDownloadAllSongs()
            } else {
                Logger.e("❌ [SunoResult] sunoDataList is empty!")
            }
        }
        .onDisappear {
            downloadTask?.cancel()
        }
        .onChange(of: musicPlayer.currentIndex) { newIndex in
            // Sync selectedSongIndex with MusicPlayer's currentIndex
            if selectedSongIndex != newIndex && newIndex >= 0 && newIndex < sunoDataList.count {
                Logger.d("🎵 [SunoResult] Syncing selectedSongIndex: \(selectedSongIndex) -> \(newIndex)")
                selectedSongIndex = newIndex
                // Load the new song if it's downloaded
                if downloadedFileURLs[sunoDataList[newIndex].id] != nil {
                    loadSelectedSong()
                }
            } else if newIndex < 0 || newIndex >= sunoDataList.count {
                Logger.e("❌ [SunoResult] Invalid newIndex from MusicPlayer: \(newIndex), list count: \(sunoDataList.count)")
            }
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
        .alert("Download in Progress", isPresented: $showDownloadAlert) {
            Button("Still Exit", role: .destructive) {
                // Force exit even while downloading
                cancelAllDownloads()
                onClose()
                dismiss()
            }
            Button("Cancel", role: .cancel) {
                // Stay on screen, continue downloading
            }
        } message: {
            Text("\(downloadingSongs.count) song(s) are still downloading. Do you want to exit anyway?")
        }
        .fullScreenCover(isPresented: $showSubscriptionScreen) {
            if SubscriptionManager.shared.isPremium {
                SubscriptionScreen()
            } else {
                SubscriptionScreenIntro()
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
                handleCloseButton()
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
            // Cover image from Suno - use getImageURL to support local covers
            AsyncImage(url: getImageURL(for: currentSong)) { phase in
                switch phase {
                case .empty:
                    Image("demo_cover")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Image("demo_cover")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                @unknown default:
                    Image("demo_cover")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .frame(width: 280, height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: AivoTheme.Shadow.orange, radius: 20, x: 0, y: 10)
            .id("\(currentSong.id)_\(selectedSongIndex)") // Force refresh when song changes
            
            // Download progress overlay
            if downloadingSongs.contains(currentSong.id) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.7))
                    .frame(width: 280, height: 280)
                    .overlay(
                        VStack {
                            Text("Downloading...")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            Text("\(downloadingSongs.count) songs")
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
                                       // Validate index before setting
                                       if index >= 0 && index < sunoDataList.count {
                                           selectedSongIndex = index
                                           loadSelectedSong()
                                       } else {
                                           Logger.e("❌ [SunoResult] Invalid index \(index) for song list count \(sunoDataList.count)")
                                       }
                                   }
                               },
                               onSave: {
                                   if let fileURL = downloadedFileURLs[song.id] {
                                       saveToDevice(fileURL: fileURL, song: song)
                                   }
                               },
                               onExport: {
                                   // Check subscription first
                                   if subscriptionManager.isPremium {
                                       if let fileURL = downloadedFileURLs[song.id] {
                                           currentFileURL = fileURL
                                           showExportSheet = true
                                       }
                                   } else {
                                       showSubscriptionScreen = true
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
        let isDownloadingCurrentSong = downloadingSongs.contains(currentSong.id)
        let isCurrentSongDownloaded = downloadedFileURLs[currentSong.id] != nil
        let isSongReady = !isDownloadingCurrentSong && isCurrentSongDownloaded && musicPlayer.duration > 0
        
        return VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: { 
                        // If downloading or not ready, return 0, otherwise use normal logic
                        if !isSongReady {
                            return 0
                        }
                        return isScrubbing ? scrubTime : musicPlayer.currentTime
                    },
                    set: { newVal in
                        if !isSongReady { return } // Prevent changes when not ready
                        if isScrubbing { scrubTime = newVal } else { musicPlayer.currentTime = newVal }
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
            .padding(.horizontal, 20)
            
            HStack {
                Text(formatTime(isSongReady ? (isScrubbing ? scrubTime : musicPlayer.currentTime) : 0))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text(formatTime(isSongReady ? musicPlayer.duration : currentSong.duration))
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
            
            Button(action: musicPlayer.togglePlayPause) {
                Image(systemName: musicPlayer.isPlaying ? "pause.fill" : "play.fill")
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
    private func handleCloseButton() {
        // Check if there are songs still downloading
        if !downloadingSongs.isEmpty {
            // Show alert asking user if they want to exit
            showDownloadAlert = true
        } else {
            // No downloads in progress, close immediately
            onClose()
            dismiss()
        }
    }
    
    private func cancelAllDownloads() {
        Logger.d("🛑 [SunoResult] Cancelling all downloads")
        // Cancel download task if exists
        downloadTask?.cancel()
        downloadTask = nil
        
        // Clear downloading set
        downloadingSongs.removeAll()
        
        // Optionally: cancel individual download operations if you have references
        // For now, we just clear the state
        Logger.d("✅ [SunoResult] All downloads cancelled")
    }
    
    private func startDownloadAllSongs() {
        Logger.d("📥 [SunoResult] Starting download for all \(sunoDataList.count) songs")
        for song in sunoDataList {
            downloadSong(song)
        }
    }
    
    private func startDownloadCurrentSong() {
        downloadSong(currentSong)
    }
    
    // MARK: - Helper Methods
    private func getImageURL(for song: SunoData) -> URL? {
        // Check if local cover exists first
        if let localCoverPath = SunoDataManager.shared.getLocalCoverPath(for: song.id) {
            return localCoverPath
        }
        
        // Fallback to source URL or regular image URL
        return URL(string: song.sourceImageUrl.isEmpty ? song.imageUrl : song.sourceImageUrl)
    }
    
    private func downloadSong(_ song: SunoData) {
        Logger.d("📥 [SunoResult] Starting download for song: \(song.title)")
        Logger.d("📥 [SunoResult] Audio URL: \(song.audioUrl)")
        
        guard let url = URL(string: song.audioUrl) else { 
            Logger.e("❌ [SunoResult] Invalid URL for song: \(song.title)")
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
        
        Logger.d("📥 [SunoResult] Download destination: \(localURL.path)")
        
        let downloader = ProgressiveDownloader(
            destinationURL: localURL,
            onProgress: { prog in
                // Progress tracking removed - just show downloading status
            },
            onComplete: { fileURL in
                Logger.d("✅ [SunoResult] Download completed for song: \(song.title)")
                
                // Validate file size before proceeding
                let fileManager = FileManager.default
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                    if let fileSize = attributes[.size] as? Int64 {
                        Logger.d("📊 [SunoResult] Downloaded file size: \(fileSize) bytes")
                        
                        // Check if file size is suspiciously small (< 100KB)
                        if fileSize < 100 * 1024 {
                            Logger.e("❌ [SunoResult] Downloaded file too small (\(fileSize) bytes), likely corrupted")
                            Logger.w("⚠️ [SunoResult] Retrying download for song: \(song.title)")
                            
                            // Retry download
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                self.downloadSong(song)
                            }
                            return
                        }
                        
                        Logger.d("✅ [SunoResult] File size validation passed: \(fileSize) bytes")
                    }
                } catch {
                    Logger.e("❌ [SunoResult] Error getting file attributes: \(error)")
                }
                
                self.downloadingSongs.remove(song.id)
                self.downloadedFileURLs[song.id] = fileURL
                
                // Save full SunoData to local storage
                Task {
                    do {
                        let savedURL = try await SunoDataManager.shared.saveSunoData(song)
                        await MainActor.run {
                            self.savedToDevice.insert(song.id)
                            Logger.d("💾 [SunoResult] Full SunoData saved to device: \(savedURL.path)")
                        }
                    } catch {
                        Logger.e("❌ [SunoResult] Error saving SunoData: \(error)")
                    }
                }
                
                // Song downloaded successfully - auto-play first song
                if song.id == self.sunoDataList.first?.id {
                    Logger.d("🎵 [SunoResult] Auto-playing first song: \(song.title)")
                    self.musicPlayer.loadSong(song, at: 0, in: self.sunoDataList)
                }
                Logger.d("🎵 [SunoResult] Song ready for playback: \(song.title)")
            },
            onError: { error in
                Logger.e("❌ [SunoResult] Download error for song \(song.title): \(error)")
                self.downloadingSongs.remove(song.id)
                
                // Retry download on error (with limit)
                Logger.w("⚠️ [SunoResult] Retrying download for song: \(song.title)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.downloadSong(song)
                }
            }
        )
        
        downloader.start(url: url)
    }
    
    private func loadSelectedSong() {
        guard downloadedFileURLs[currentSong.id] != nil else { 
            Logger.d("⚠️ [SunoResult] Song not downloaded yet: \(currentSong.title)")
            return 
        }
        
        Logger.d("🎵 [SunoResult] Loading selected song: \(currentSong.title)")
        
        // Use MusicPlayer to play the song
        musicPlayer.loadSong(currentSong, at: selectedSongIndex, in: sunoDataList)
        Logger.d("🎵 [SunoResult] Song loaded into MusicPlayer")
    }
    
    
    private func rewind10s() {
        let newTime = max(0, musicPlayer.currentTime - 10)
        musicPlayer.seek(to: newTime)
    }
    
    private func forward10s() {
        let newTime = min(musicPlayer.duration, musicPlayer.currentTime + 10)
        musicPlayer.seek(to: newTime)
    }
    
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func saveToDevice(fileURL: URL, song: SunoData) {
        Logger.d("💾 [SunoResult] Saving song to device: \(song.title)")
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
                    // Ảnh - Check local first, then use source URL
                    AsyncImage(url: getImageURL(for: song)) { image in
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
                    // Save button (trái)
                    Button {
//                        if isSavedToDevice {
//                            onSave()
//                        }
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle().fill(isSavedToDevice ? .green : Color.gray.opacity(0.8))
                            )
                    }
                    .disabled(!isDownloaded)
                    
                    // Export button (phải)
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
