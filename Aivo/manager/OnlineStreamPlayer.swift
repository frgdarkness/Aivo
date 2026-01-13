import Foundation
import AVFoundation
import SwiftUI
import MediaPlayer

// MARK: - Online Stream Player
class OnlineStreamPlayer: NSObject, ObservableObject {
    static let shared = OnlineStreamPlayer()
    
    // MARK: - Published Properties
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var currentSong: SunoData?
    @Published var currentIndex: Int = 0
    @Published var songs: [SunoData] = []
    @Published var playMode: PlayMode = .sequential
    @Published var loadedTimeRanges: [CMTimeRange] = [] // For buffering visualization
    @Published var isBuffering = false
    
    // MARK: - Private Properties
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var loadedTimeRangesObserver: NSKeyValueObservation?
    private var playbackLikelyToKeepUpObserver: NSKeyValueObservation?
    
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
    
    private override init() {
        super.init()
        setupAudioSession()
        setupRemoteTransportControls()
        setupNotifications()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods
    
    /// Load a song and start streaming
    func loadSong(_ song: SunoData, at index: Int, in songs: [SunoData]) {
        Logger.d("🎵 [OnlineStreamPlayer] Loading song: \\(song.title)")
        
        // Clean up previous player
        cleanup()
        
        // Set new song
        self.currentSong = song
        self.currentIndex = index
        self.songs = songs
        
        // Create URL from song's audio URL
        guard let url = URL(string: song.audioUrl) else {
            Logger.e("❌ [OnlineStreamPlayer] Invalid audio URL: \\(song.audioUrl)")
            return
        }
        
        // Create player item and player
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // Setup observers
        setupPlayerObservers()
        
        // Auto-play
        play()
        updateNowPlayingInfo()
    }
    
    /// Play current song
    func play() {
        guard let player = player else { return }
        
        player.play()
        isPlaying = true
        Logger.d("🎵 [OnlineStreamPlayer] Playing")
        updateNowPlayingInfo()
    }
    
    /// Pause current song
    func pause() {
        guard let player = player else { return }
        
        player.pause()
        isPlaying = false
        Logger.d("🎵 [OnlineStreamPlayer] Paused")
        updateNowPlayingInfo()
    }
    
    /// Stop current song
    func stop() {
        cleanup()
        currentSong = nil
        songs = []
        currentIndex = 0
        Logger.d("🎵 [OnlineStreamPlayer] Stopped and cleared")
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    /// Toggle play/pause
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    /// Seek to specific time
    func seek(to time: TimeInterval) {
        guard let player = player else { return }
        
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: cmTime) { [weak self] _ in
            self?.updateNowPlayingInfo()
        }
    }
    
    /// Play next song
    func nextSong() {
        guard !songs.isEmpty else { return }
        
        let newIndex: Int
        switch playMode {
        case .sequential:
            newIndex = currentIndex < songs.count - 1 ? currentIndex + 1 : 0
        case .repeatOne:
            newIndex = currentIndex
        case .shuffle:
            newIndex = Int.random(in: 0..<songs.count)
        }
        
        if newIndex != currentIndex {
            loadSong(songs[newIndex], at: newIndex, in: songs)
        } else {
            // Repeat current song
            seek(to: 0)
            play()
        }
    }
    
    /// Play previous song
    func previousSong() {
        guard !songs.isEmpty else { return }
        
        let newIndex = currentIndex > 0 ? currentIndex - 1 : songs.count - 1
        loadSong(songs[newIndex], at: newIndex, in: songs)
    }
    
    /// Add song to the end of the current queue
    func addToQueue(_ song: SunoData) {
        songs.append(song)
        Logger.d("🎵 [OnlineStreamPlayer] Added to queue: \\(song.title)")
    }
    
    /// Change play mode
    func changePlayMode() {
        let allModes = PlayMode.allCases
        if let currentModeIndex = allModes.firstIndex(of: playMode) {
            let nextIndex = (currentModeIndex + 1) % allModes.count
            playMode = allModes[nextIndex]
            Logger.d("🎵 [OnlineStreamPlayer] Play mode changed to: \\(playMode.rawValue)")
        }
    }
    
    /// Clear current playlist
    func clearPlaylist() {
        stop()
        currentSong = nil
        currentIndex = 0
        songs = []
        Logger.d("🎵 [OnlineStreamPlayer] Playlist cleared")
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true, options: [])
            UIApplication.shared.beginReceivingRemoteControlEvents()
            Logger.d("🎵 [OnlineStreamPlayer] Audio session configured for background playback")
        } catch {
            Logger.e("❌ [OnlineStreamPlayer] Error setting up audio session: \\(error)")
        }
    }
    
    private func setupPlayerObservers() {
        guard let playerItem = playerItem, let player = player else { return }
        
        // Time observer for current time updates
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            
            // Update duration if available
            let durationSeconds = playerItem.asset.duration.seconds
            if durationSeconds.isFinite {
                self.duration = durationSeconds
            }
        }
        
        // Status observer
        statusObserver = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard let self = self else { return }
            
            switch item.status {
            case .readyToPlay:
                Logger.d("🎵 [OnlineStreamPlayer] Ready to play")
                let durationSeconds = item.asset.duration.seconds
                if durationSeconds.isFinite {
                    self.duration = durationSeconds
                }
            case .failed:
                Logger.e("❌ [OnlineStreamPlayer] Failed to load: \(item.error?.localizedDescription ?? "Unknown error")")
            case .unknown:
                Logger.d("🎵 [OnlineStreamPlayer] Status unknown")
            @unknown default:
                break
            }
        }
        
        // Loaded time ranges observer (for buffering visualization)
        loadedTimeRangesObserver = playerItem.observe(\.loadedTimeRanges, options: [.new]) { [weak self] item, _ in
            guard let self = self else { return }
            self.loadedTimeRanges = item.loadedTimeRanges.map { $0.timeRangeValue }
        }
        
        // Playback likely to keep up observer (for buffering state)
        playbackLikelyToKeepUpObserver = playerItem.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, _ in
            guard let self = self else { return }
            self.isBuffering = !item.isPlaybackLikelyToKeepUp
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }
    
    @objc private func playerDidFinishPlaying() {
        Logger.d("🎵 [OnlineStreamPlayer] Playback finished, play mode: \\(playMode.rawValue)")
        
        switch playMode {
        case .sequential:
            nextSong()
        case .repeatOne:
            seek(to: 0)
            play()
        case .shuffle:
            nextSong()
        }
    }
    
    private func cleanup() {
        // Remove time observer
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        
        // Remove KVO observers
        statusObserver?.invalidate()
        loadedTimeRangesObserver?.invalidate()
        playbackLikelyToKeepUpObserver?.invalidate()
        
        statusObserver = nil
        loadedTimeRangesObserver = nil
        playbackLikelyToKeepUpObserver = nil
        
        // Clean up player
        player?.pause()
        player = nil
        playerItem = nil
        
        isPlaying = false
        currentTime = 0
        duration = 0
        loadedTimeRanges = []
        isBuffering = false
    }
    
    // MARK: - Lock Screen / Control Center Controls
    
    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Play Command
        commandCenter.playCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            if !self.isPlaying {
                self.play()
                return .success
            }
            return .commandFailed
        }
        
        // Pause Command
        commandCenter.pauseCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            if self.isPlaying {
                self.pause()
                return .success
            }
            return .commandFailed
        }
        
        // Toggle Play/Pause
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            self.togglePlayPause()
            return .success
        }
        
        // Next Track
        commandCenter.nextTrackCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            self.nextSong()
            return .success
        }
        
        // Previous Track
        commandCenter.previousTrackCommand.addTarget { [weak self] event in
            guard let self = self else { return .commandFailed }
            self.previousSong()
            return .success
        }
        
        // Scrubbing / Seek
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self, let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self.seek(to: event.positionTime)
            return .success
        }
    }
    
    private func updateNowPlayingInfo(onlyTime: Bool = false) {
        guard let song = currentSong else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
        
        // Always update time-sensitive data
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        
        if !onlyTime {
            // Update metadata (Title, Artist, Artwork)
            nowPlayingInfo[MPMediaItemPropertyTitle] = song.title
            nowPlayingInfo[MPMediaItemPropertyArtist] = song.modelName.isEmpty ? "Aivo AI" : song.modelName
            
            // Handle Artwork - try to load from remote URL
            if let imageURL = URL(string: song.imageUrl) {
                Task {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: imageURL)
                        if let image = UIImage(data: data) {
                            await MainActor.run {
                                let artwork = MPMediaItemArtwork(boundsSize: image.size) { size in
                                    return image
                                }
                                var updatedInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
                                updatedInfo[MPMediaItemPropertyArtwork] = artwork
                                MPNowPlayingInfoCenter.default().nowPlayingInfo = updatedInfo
                            }
                        }
                    } catch {
                        Logger.e("❌ [OnlineStreamPlayer] Failed to load artwork: \\(error)")
                    }
                }
            }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    /// Get buffered percentage for a given time
    func getBufferedPercentage(at time: TimeInterval) -> Double {
        guard duration > 0 else { return 0 }
        
        for range in loadedTimeRanges {
            let start = range.start.seconds
            let end = range.end.seconds
            
            if time >= start && time <= end {
                return min(end / duration, 1.0)
            }
        }
        
        return 0
    }
}
