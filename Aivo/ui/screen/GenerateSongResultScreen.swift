import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

// MARK: - Generate Song Result Screen
struct GenerateSongResultScreen: View {
    let audioUrl: String
    let onClose: () -> Void
    
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
    
    // NEW: giữ URL sau khi tải xong để Export/Share
    @State private var downloadedFileURL: URL?
    // NEW: control hiển thị sheet
    @State private var showExportSheet = false
    @State private var showShareSheet = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            AivoSunsetBackground()
            
            VStack(spacing: 0) {
                headerView
                coverImageView
                songTitleView
                Spacer()
                seekBarView
                bottomControlsView
            }
        }
        .onAppear {
            startDownload()
        }
        .onDisappear {
            stopAudio()
            playbackTimer?.invalidate()
            downloadTask?.cancel()
        }
        // MARK: - Sheets cho Export/Share
        .sheet(isPresented: $showExportSheet) {
            if let url = downloadedFileURL {
                DocumentExporter(fileURL: url)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = downloadedFileURL {
                ActivityView(items: [url])
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack(spacing: 12) {
            Text("HERE'S YOUR SONG")
                .font(.system(size: 24, weight: .black, design: .monospaced))
                .foregroundColor(.white)
            
            Spacer()
            
            // NEW: Share
            Button {
                showShareSheet = true
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.title3)
                    .foregroundColor(.white.opacity(downloadedFileURL == nil ? 0.4 : 1))
            }
            .disabled(downloadedFileURL == nil)
            
            // NEW: Save to Files
            Button {
                showExportSheet = true
            } label: {
                Image(systemName: "externaldrive.badge.plus")
                    .font(.title3)
                    .foregroundColor(.white.opacity(downloadedFileURL == nil ? 0.4 : 1))
            }
            .disabled(downloadedFileURL == nil)
            
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
    
    // MARK: - Cover Image View with Progress Animation
    private var coverImageView: some View {
        ZStack {
            Image("demo_cover")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 280, height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: AivoTheme.Shadow.orange, radius: 20, x: 0, y: 10)
            
            if isDownloading {
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
            Text("AI Generated Song")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text("Your personalized music")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
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
    
    @State private var downloader: ProgressiveDownloader?
    
    // MARK: - Download with Live Progress
    private func startDownload() {
        guard let url = URL(string: audioUrl) else { return }
        isDownloading = true
        downloadProgress = 0

        let ext = url.pathExtension.isEmpty ? "mp3" : url.pathExtension.lowercased()
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("generated_song.\(ext)")

        let d = ProgressiveDownloader(
            destinationURL: tmpURL,
            onProgress: { prog in
                withAnimation(.linear(duration: 0.06)) {
                    self.downloadProgress = prog
                }
            },
            onComplete: { fileURL in
                self.isDownloading = false
                self.downloadProgress = 1.0
                self.downloadedFileURL = fileURL      // NEW: giữ URL để Export/Share
                self.setupAudioPlayerWithURL(fileURL)
            },
            onError: { error in
                print("Download error: \(error)")
                self.isDownloading = false
            }
        )
        self.downloader = d
        d.start(url: url)
    }
    
    // MARK: - Audio Setup & Controls
    private func setupAudioPlayerWithURL(_ url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = GenerateSongAudioPlayerDelegate { [self] in
                isPlaying = false
                currentTime = 0
                playbackTimer?.invalidate()
            }
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 0
            
            let success = audioPlayer?.play() ?? false
            isPlaying = success
            if !success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let retry = self.audioPlayer?.play() ?? false
                    self.isPlaying = retry
                }
            }
            startPlaybackTimer()
        } catch {
            print("Error setting up audio player:", error)
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
}

// MARK: - Delegate
class GenerateSongAudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
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
    
    func persistToDocuments(_ src: URL, fileName: String) -> URL? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dst = docs.appendingPathComponent(fileName)
        do {
            if FileManager.default.fileExists(atPath: dst.path) { try FileManager.default.removeItem(at: dst) }
            try FileManager.default.copyItem(at: src, to: dst)
            return dst
        } catch {
            print("Persist error:", error); return nil
        }
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

// MARK: - ProgressiveDownloader giữ nguyên code bạn
// (đặt ProgressiveDownloader của bạn bên dưới như đã gửi)


// MARK: - Preview
struct GenerateSongResultScreen_Previews: PreviewProvider {
    static var previews: some View {
        GenerateSongResultScreen(
            audioUrl: "https://example.com/song.mp3",
            onClose: {}
        )
    }
}

final class ProgressiveDownloader: NSObject, URLSessionDataDelegate {
    private let destinationURL: URL
    private let onProgress: (Double) -> Void
    private let onComplete: (URL) -> Void
    private let onError: (Error) -> Void

    private var session: URLSession!
    private var task: URLSessionDataTask?
    private var expected: Int64 = 0
    private var received: Int64 = 0
    private var handle: FileHandle?

    init(destinationURL: URL,
         onProgress: @escaping (Double) -> Void,
         onComplete: @escaping (URL) -> Void,
         onError: @escaping (Error) -> Void) {
        self.destinationURL = destinationURL
        self.onProgress = onProgress
        self.onComplete = onComplete
        self.onError = onError
        super.init()

        let cfg = URLSessionConfiguration.default
        cfg.waitsForConnectivity = true
        self.session = URLSession(configuration: cfg, delegate: self, delegateQueue: nil)
    }

    func start(url: URL) {
        // Dọn file cũ
        try? FileManager.default.removeItem(at: destinationURL)
        FileManager.default.createFile(atPath: destinationURL.path, contents: nil, attributes: nil)
        do {
            self.handle = try FileHandle(forWritingTo: destinationURL)
        } catch {
            onError(error)
            return
        }

        let req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60)
        let t = session.dataTask(with: req)
        self.task = t
        t.resume()
    }

    func cancel() {
        task?.cancel()
        try? handle?.close()
        handle = nil
        session.invalidateAndCancel()
    }

    // MARK: URLSessionDataDelegate
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        expected = response.expectedContentLength // -1 nếu server không báo
        received = 0
        DispatchQueue.main.async { self.onProgress(0) }
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive data: Data) {
        do {
            try handle?.write(contentsOf: data)
            received += Int64(data.count)

            if expected > 0 {
                let prog = max(0, min(1, Double(received) / Double(expected)))
                DispatchQueue.main.async { self.onProgress(prog) }
            } else {
                // Không có Content-Length → có thể hiển thị indeterminate
                // Ở đây tăng dần tới 0.9 cho cảm giác tiến triển
                DispatchQueue.main.async {
                    let current = min(0.9, max(0.0, self.progFromUnknown(self.received)))
                    self.onProgress(current)
                }
            }
        } catch {
            DispatchQueue.main.async { self.onError(error) }
            cancel()
        }
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        defer {
            try? handle?.close()
            handle = nil
            session.finishTasksAndInvalidate()
        }

        if let error = error {
            DispatchQueue.main.async { self.onError(error) }
            return
        }
        // Đảm bảo 100% khi kết thúc
        DispatchQueue.main.async {
            self.onProgress(1.0)
            self.onComplete(self.destinationURL)
        }
    }

    // Khi không biết total size, tạo 1 hàm tuyến tính giả lập từ byte nhận được (tuỳ biến nếu muốn)
    private func progFromUnknown(_ bytes: Int64) -> Double {
        // ví dụ: sau ~5MB coi như 90%
        let cap: Double = 5 * 1024 * 1024
        return min(0.9, Double(bytes) / cap)
    }
}
