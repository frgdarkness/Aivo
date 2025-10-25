import Foundation
import AVFoundation
import SwiftUI

// MARK: - Music Player Manager
class MusicPlayer: NSObject, ObservableObject {
    static let shared = MusicPlayer()
    
    // MARK: - Published Properties
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var currentSong: SunoData?
    @Published var currentIndex: Int = 0
    @Published var songs: [SunoData] = []
    @Published var playMode: PlayMode = .sequential
    
    // MARK: - Private Properties
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    private var audioDelegate: MusicPlayerAudioDelegate?
    
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
    }
    
    // MARK: - Public Methods
    
    /// Load a song and start playing
    func loadSong(_ song: SunoData, at index: Int, in songs: [SunoData]) {
        Logger.d("🎵 [MusicPlayer] Loading song: \(song.title)")
        Logger.d("songInfo: \(song)")
        // Stop current playback first (but don't clear currentSong yet)
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        stopPlaybackTimer()
        
        // Now set the new song
        self.currentSong = song
        self.currentIndex = index
        self.songs = songs
        
        // Try to load from local file first
        let localFilePath = getLocalFilePath(for: song)
        let audioURL: URL
        
        if FileManager.default.fileExists(atPath: localFilePath.path) {
            Logger.d("🎵 [MusicPlayer] Using local file: \(localFilePath.path)")
            audioURL = localFilePath
        } else {
            Logger.d("🎵 [MusicPlayer] Local file not found, using remote URL")
            guard let url = URL(string: song.audioUrl) else {
                Logger.e("❌ [MusicPlayer] Invalid audio URL: \(song.audioUrl)")
                return
            }
            audioURL = url
        }
        
        setupAudioPlayer(with: audioURL)
    }
    
    /// Play current song
    func play() {
        guard let player = audioPlayer else { return }
        
        let success = player.play()
        isPlaying = success
        Logger.d("🎵 [MusicPlayer] Play result: \(success)")
        
        if success {
            startPlaybackTimer()
        }
    }
    
    /// Pause current song
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        Logger.d("🎵 [MusicPlayer] Paused")
        
        stopPlaybackTimer()
    }
    
    /// Stop current song
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        currentSong = nil
        songs = []
        currentIndex = 0
        stopPlaybackTimer()
        Logger.d("🎵 [MusicPlayer] Stopped and cleared")
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
        audioPlayer?.currentTime = time
        currentTime = time
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
            currentTime = 0
            audioPlayer?.currentTime = 0
            play()
        }
    }
    
    /// Play previous song
    func previousSong() {
        guard !songs.isEmpty else { return }
        
        let newIndex = currentIndex > 0 ? currentIndex - 1 : songs.count - 1
        loadSong(songs[newIndex], at: newIndex, in: songs)
    }
    
    /// Change play mode
    func changePlayMode() {
        let allModes = PlayMode.allCases
        if let currentModeIndex = allModes.firstIndex(of: playMode) {
            let nextIndex = (currentModeIndex + 1) % allModes.count
            playMode = allModes[nextIndex]
            Logger.d("🎵 [MusicPlayer] Play mode changed to: \(playMode.rawValue)")
        }
    }
    
    /// Clear current playlist
    func clearPlaylist() {
        stop()
        currentSong = nil
        currentIndex = 0
        songs = []
        Logger.d("🎵 [MusicPlayer] Playlist cleared")
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            Logger.d("🎵 [MusicPlayer] Audio session configured")
        } catch {
            Logger.e("❌ [MusicPlayer] Error setting up audio session: \(error)")
        }
    }
    
    private func setupAudioPlayer(with url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioDelegate = MusicPlayerAudioDelegate { [weak self] in
                self?.handlePlaybackFinished()
            }
            audioPlayer?.delegate = audioDelegate
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 0
            
            Logger.d("🎵 [MusicPlayer] Audio player prepared. Duration: \(duration) seconds")
            
            // Auto-play
            play()
            
        } catch {
            Logger.e("❌ [MusicPlayer] Error setting up audio player: \(error)")
        }
    }
    
    private func startPlaybackTimer() {
        stopPlaybackTimer()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            if let player = self?.audioPlayer {
                self?.currentTime = player.currentTime
            }
        }
    }
    
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func handlePlaybackFinished() {
        Logger.d("🎵 [MusicPlayer] Playback finished, play mode: \(playMode.rawValue)")
        
        switch playMode {
        case .sequential:
            nextSong()
        case .repeatOne:
            currentTime = 0
            audioPlayer?.currentTime = 0
            play()
        case .shuffle:
            nextSong()
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
                Logger.d("🎵 [MusicPlayer] Found local file: \(fileName)")
                return filePath
            }
        }
        
        // Default fallback
        let audioFileName = "\(song.id)_audio.mp3"
        return sunoDataPath.appendingPathComponent(audioFileName)
    }
}

// MARK: - Audio Player Delegate
class MusicPlayerAudioDelegate: NSObject, AVAudioPlayerDelegate {
    private let onFinish: () -> Void
    
    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Logger.d("🎵 [MusicPlayerDelegate] Audio playback finished successfully: \(flag)")
        onFinish()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Logger.e("❌ [MusicPlayerDelegate] Audio decode error: \(error?.localizedDescription ?? "Unknown error")")
    }
}
