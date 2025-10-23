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
            startDownloadCurrentSong()
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
            
            // Share
            Button {
                currentFileURL = downloadedFileURLs[currentSong.id]
                showShareSheet = true
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.title3)
                    .foregroundColor(.white.opacity(downloadedFileURLs[currentSong.id] == nil ? 0.4 : 1))
            }
            .disabled(downloadedFileURLs[currentSong.id] == nil)
            
            // Save to Files
            Button {
                currentFileURL = downloadedFileURLs[currentSong.id]
                showExportSheet = true
            } label: {
                Image(systemName: "externaldrive.badge.plus")
                    .font(.title3)
                    .foregroundColor(.white.opacity(downloadedFileURLs[currentSong.id] == nil ? 0.4 : 1))
            }
            .disabled(downloadedFileURLs[currentSong.id] == nil)
            
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
            
            // Songs scroll view
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(sunoDataList.enumerated()), id: \.element.id) { index, song in
                        SongCardView(
                            song: song,
                            isSelected: index == selectedSongIndex,
                            isDownloaded: downloadedFileURLs[song.id] != nil,
                            isDownloading: downloadingSongs.contains(song.id),
                            onTap: {
                                if downloadedFileURLs[song.id] != nil {
                                    selectedSongIndex = index
                                    loadSelectedSong()
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
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("suno_song_\(song.id).\(ext)")
        
        print("📥 [SunoResult] Download destination: \(tmpURL.path)")
        
        let downloader = ProgressiveDownloader(
            destinationURL: tmpURL,
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
        guard let fileURL = downloadedFileURLs[currentSong.id] else { return }
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
    
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Song Card View
struct SongCardView: View {
    let song: SunoData
    let isSelected: Bool
    let isDownloaded: Bool
    let isDownloading: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Song cover
            AsyncImage(url: URL(string: song.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image("demo_cover")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? AivoTheme.Primary.orange : Color.clear,
                        lineWidth: 2
                    )
            )
            .overlay(
                // Download progress
                Group {
                    if isDownloading {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.6))
                            .overlay(
                                Image(systemName: "arrow.down.circle")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            )
                    } else if isDownloaded {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.clear)
                            .overlay(
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            )
                    }
                }
            )
            
            // Song title
            Text(song.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 80)
        }
        .onTapGesture {
            if isDownloaded {
                onTap()
            }
        }
        .opacity(isDownloaded ? 1.0 : 0.6)
    }
}

//// MARK: - Delegate
//class GenerateSongAudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
//    let onFinish: () -> Void
//    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
//    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
//        onFinish()
//    }
//}
//
//// MARK: - UIKit wrappers for SwiftUI
//
///// Save to Files (UIDocumentPicker, iOS 14+)
//struct DocumentExporter: UIViewControllerRepresentable {
//    let fileURL: URL
//    
//    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
//        let vc = UIDocumentPickerViewController(forExporting: [fileURL], asCopy: true)
//        vc.allowsMultipleSelection = false
//        vc.shouldShowFileExtensions = true
//        return vc
//    }
//    
//    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
//}
//
///// Share Sheet (UIActivityViewController)
//struct ActivityView: UIViewControllerRepresentable {
//    let items: [Any]
//    let activities: [UIActivity]? = nil
//    
//    func makeUIViewController(context: Context) -> UIActivityViewController {
//        let vc = UIActivityViewController(activityItems: items, applicationActivities: activities)
//        return vc
//    }
//    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
//}
//
//// MARK: - ProgressiveDownloader
//final class ProgressiveDownloader: NSObject, URLSessionDataDelegate {
//    private let destinationURL: URL
//    private let onProgress: (Double) -> Void
//    private let onComplete: (URL) -> Void
//    private let onError: (Error) -> Void
//
//    private var session: URLSession!
//    private var task: URLSessionDataTask?
//    private var expected: Int64 = 0
//    private var received: Int64 = 0
//    private var handle: FileHandle?
//
//    init(destinationURL: URL,
//         onProgress: @escaping (Double) -> Void,
//         onComplete: @escaping (URL) -> Void,
//         onError: @escaping (Error) -> Void) {
//        self.destinationURL = destinationURL
//        self.onProgress = onProgress
//        self.onComplete = onComplete
//        self.onError = onError
//        super.init()
//
//        let cfg = URLSessionConfiguration.default
//        cfg.waitsForConnectivity = true
//        self.session = URLSession(configuration: cfg, delegate: self, delegateQueue: nil)
//    }
//
//    func start(url: URL) {
//        try? FileManager.default.removeItem(at: destinationURL)
//        FileManager.default.createFile(atPath: destinationURL.path, contents: nil, attributes: nil)
//        do {
//            self.handle = try FileHandle(forWritingTo: destinationURL)
//        } catch {
//            onError(error)
//            return
//        }
//
//        let req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60)
//        let t = session.dataTask(with: req)
//        self.task = t
//        t.resume()
//    }
//
//    func cancel() {
//        task?.cancel()
//        try? handle?.close()
//        handle = nil
//        session.invalidateAndCancel()
//    }
//
//    // MARK: URLSessionDataDelegate
//    func urlSession(_ session: URLSession,
//                    dataTask: URLSessionDataTask,
//                    didReceive response: URLResponse,
//                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
//        expected = response.expectedContentLength
//        received = 0
//        DispatchQueue.main.async { self.onProgress(0) }
//        completionHandler(.allow)
//    }
//
//    func urlSession(_ session: URLSession,
//                    dataTask: URLSessionDataTask,
//                    didReceive data: Data) {
//        do {
//            try handle?.write(contentsOf: data)
//            received += Int64(data.count)
//
//            if expected > 0 {
//                let prog = max(0, min(1, Double(received) / Double(expected)))
//                DispatchQueue.main.async { self.onProgress(prog) }
//            } else {
//                DispatchQueue.main.async {
//                    let current = min(0.9, max(0.0, self.progFromUnknown(self.received)))
//                    self.onProgress(current)
//                }
//            }
//        } catch {
//            DispatchQueue.main.async { self.onError(error) }
//            cancel()
//        }
//    }
//
//    func urlSession(_ session: URLSession,
//                    task: URLSessionTask,
//                    didCompleteWithError error: Error?) {
//        defer {
//            try? handle?.close()
//            handle = nil
//            session.finishTasksAndInvalidate()
//        }
//
//        if let error = error {
//            DispatchQueue.main.async { self.onError(error) }
//            return
//        }
//        
//        DispatchQueue.main.async {
//            self.onProgress(1.0)
//            self.onComplete(self.destinationURL)
//        }
//    }
//
//    private func progFromUnknown(_ bytes: Int64) -> Double {
//        let cap: Double = 5 * 1024 * 1024
//        return min(0.9, Double(bytes) / cap)
//    }
//}

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
