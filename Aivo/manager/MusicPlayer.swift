import Foundation
import AVFoundation
import SwiftUI
import MediaPlayer

// MARK: - Music Player Manager
class MusicPlayer: NSObject, ObservableObject {
    static let shared = MusicPlayer()
    
    // MARK: - Published Properties
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var currentSong: SunoData?
    @Published var currentIndex: Int = 0
    
    // MARK: - EQPreset Definition
    struct EQPreset: Identifiable, Codable {
        var id = UUID().uuidString
        var name: String
        var bands: [Double]
        var bass: Double
        var treble: Double
        var isSystem: Bool
        
        static let systemPresets: [EQPreset] = [
            EQPreset(name: "Flat", bands: Array(repeating: 0.0, count: 10), bass: 0, treble: 0, isSystem: true),
            EQPreset(name: "Acoustic", bands: [3, 3, 2, 1, 1, 1, 2, 2, 2, 2], bass: 2, treble: 2, isSystem: true),
            EQPreset(name: "Bass Booster", bands: [5, 4, 3, 2, 0, 0, 0, 0, 0, 0], bass: 5, treble: 0, isSystem: true),
            EQPreset(name: "Bass Reducer", bands: [-5, -4, -3, -2, 0, 0, 0, 0, 0, 0], bass: -5, treble: 0, isSystem: true),
            EQPreset(name: "Classical", bands: [4, 3, 2, 2, -1, -1, 0, 2, 3, 3], bass: 3, treble: 3, isSystem: true),
            EQPreset(name: "Electronic", bands: [4, 3, 0, -2, -3, 0, 1, 3, 4, 4], bass: 4, treble: 4, isSystem: true),
            EQPreset(name: "Hip-Hop", bands: [4, 3, 1, -1, -1, 1, -1, 1, 2, 3], bass: 4, treble: 2, isSystem: true),
            EQPreset(name: "Jazz", bands: [3, 2, 1, 2, -1, -1, 0, 1, 2, 3], bass: 3, treble: 3, isSystem: true),
            EQPreset(name: "Pop", bands: [-1, -1, 0, 2, 4, 4, 2, 0, -1, -1], bass: 2, treble: 2, isSystem: true),
            EQPreset(name: "Rock", bands: [4, 3, 1, 0, -1, -1, 1, 3, 4, 4], bass: 4, treble: 4, isSystem: true)
        ]
    }
    @Published var songs: [SunoData] = []
    @Published var playMode: PlayMode = .sequential
    
    // MARK: - Sleep Timer Properties
    @Published var sleepTimerTimeRemaining: TimeInterval?
    private var sleepTimer: Timer?
    
    // MARK: - Equalizer Properties
    @Published var eqBands: [Double] = Array(repeating: 0.0, count: 10) {
        didSet { updateEqualizer() }
    }
    @Published var bassLevel: Double = 0.0 {
        didSet { updateEqualizer() }
    }
    @Published var trebleLevel: Double = 0.0 {
        didSet { updateEqualizer() }
    }
    @Published var isEqEnabled: Bool = false {
        didSet { updateEqualizer() }
    }
    @Published var selectedPresetId: String? = nil
    @Published var customPresets: [EQPreset] = [] {
        didSet { savePresets() }
    }
    
    // MARK: - Private Properties
    // Replaced AVAudioPlayer with AVAudioEngine stack
    private var engine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    // 12 Bands: 0-9 for UI Sliders, 10 for Bass Shelf, 11 for Treble Shelf
    private var equalizer = AVAudioUnitEQ(numberOfBands: 12)
    private var audioFile: AVAudioFile?
    private var sampleRate: Double = 44100.0
    private var seekOffset: TimeInterval = 0
    private var isSeeking = false
    
    private var playbackTimer: Timer?
    
    // (Removed audioDelegate as AVAudioPlayerDelegate is no longer used)
    
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
        setupAudioEngine()
        setupRemoteTransportControls()
        loadAppliedEQConfig()
    }
    
    // MARK: - EQ Config Persistence
    
    /// Save the current EQ configuration as the "applied" config
    func saveAppliedEQConfig() {
        let config: [String: Any] = [
            "bands": eqBands,
            "bass": bassLevel,
            "treble": trebleLevel,
            "enabled": isEqEnabled,
            "presetId": selectedPresetId ?? ""
        ]
        UserDefaults.standard.set(config, forKey: "applied_eq_config")
        Logger.d("🎚️ [MusicPlayer] Applied EQ config saved")
    }
    
    /// Load the previously applied EQ configuration
    func loadAppliedEQConfig() {
        guard let config = UserDefaults.standard.dictionary(forKey: "applied_eq_config") else { return }
        
        if let bands = config["bands"] as? [Double], bands.count == 10 {
            eqBands = bands
        }
        if let bass = config["bass"] as? Double {
            bassLevel = bass
        }
        if let treble = config["treble"] as? Double {
            trebleLevel = treble
        }
        if let enabled = config["enabled"] as? Bool {
            isEqEnabled = enabled
        }
        if let presetId = config["presetId"] as? String, !presetId.isEmpty {
            selectedPresetId = presetId
        }
        
        Logger.d("🎚️ [MusicPlayer] Applied EQ config loaded")
    }
    
    /// Reset EQ to default flat values
    func resetToDefaultEQ() {
        eqBands = Array(repeating: 0.0, count: 10)
        bassLevel = 0
        trebleLevel = 0
        selectedPresetId = nil
        Logger.d("🎚️ [MusicPlayer] EQ reset to default")
    }
    
    // MARK: - Public Methods
    
    /// Load a song and start playing
    func loadSong(_ song: SunoData, at index: Int, in songs: [SunoData]) {
        let profileID = LocalStorageManager.shared.localProfile?.profileID ?? "Unknown"
        Logger.d("🎵 [MusicPlayer] Song Played - ID: \(song.id), Title: \(song.title), ProfileID: \(profileID)")
        
        // Stop online stream player FIRST to prevent dual playback
        OnlineStreamPlayer.shared.stop()
        
        // Stop current playback first (but don't clear currentSong yet)
        playerNode.stop()
        
        isPlaying = false
        currentTime = 0
        duration = 0
        seekOffset = 0 
        Logger.d("🎵 [MusicPlayer] loadSong: seekOffset reset to 0")
        updateNowPlayingInfo(onlyTime: true) // Immediately update system center
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
        
        // Use new Engine Setup
        setupAudio(with: audioURL, songRaw: song)
        updateNowPlayingInfo()
        
        // Track play count via RTDB (counted after minimum play time threshold)
        PlayCountManager.shared.startTracking(songID: song.id, songName: song.title)
    }
    
    /// Play current song
    func play() {
        if !engine.isRunning {
           try? engine.start()
        }
        playerNode.play()
        
        isPlaying = true
        Logger.d("🎵 [MusicPlayer] Playing (Engine)")
        
        // Stop online player fully if running to prevent UI duplication/persistence
        OnlineStreamPlayer.shared.stop()
        
        startPlaybackTimer()
        updateNowPlayingInfo()
    }
    
    /// Pause current song
    func pause() {
        playerNode.pause()
        isPlaying = false
        Logger.d("🎵 [MusicPlayer] Paused (Engine)")
        
        stopPlaybackTimer()
        updateNowPlayingInfo()
    }
    
    /// Stop current song
    func stop() {
        playerNode.stop()
        engine.stop()
        
        // Stop play count tracking
        PlayCountManager.shared.stopTracking()
        
        isPlaying = false
        currentTime = 0
        duration = 0
        seekOffset = 0 // Reset seek offset
        currentSong = nil
        songs = []
        currentIndex = 0
        stopPlaybackTimer()
        Logger.d("🎵 [MusicPlayer] Stopped and cleared")
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
        guard let file = audioFile else { return }
        if isSeeking { return } // Prevent re-entrant seek
        
        isSeeking = true
        
        // Frame logic
        let frame = AVAudioFramePosition(time * file.processingFormat.sampleRate)
        let totalFrames = AVAudioFrameCount(file.length)
        let remainingFrames = totalFrames > frame ? AVAudioFrameCount(file.length - frame) : 0
        
        playerNode.stop()
        seekOffset = time
        Logger.d("🎵 [MusicPlayer] seek to: \(time), seekOffset set to \(seekOffset)")
        
        if remainingFrames > 0 {
            playerNode.scheduleSegment(file, startingFrame: frame, frameCount: remainingFrames, at: nil) {
                // Segment completed (natural end)
                // We handle natural end via Timer check usually, or use this. 
                // Using Timer is safer for UI sync.
            }
        }
        
        if isPlaying {
            playerNode.play()
        }
        
        currentTime = time
        updateNowPlayingInfo()
        isSeeking = false
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
            updateNowPlayingInfo()
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
        Logger.d("🎵 [MusicPlayer] Added to queue: \(song.title)")
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
    
    // MARK: - Sleep Timer Methods
    
    func startSleepTimer(minutes: Int) {
        cancelSleepTimer()
        
        Logger.d("⏰ [MusicPlayer] Sleep timer started for \(minutes) minutes")
        let totalSeconds = TimeInterval(minutes * 60)
        sleepTimerTimeRemaining = totalSeconds
        
        sleepTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            if let remaining = self.sleepTimerTimeRemaining, remaining > 0 {
                self.sleepTimerTimeRemaining = remaining - 1
            } else {
                self.cancelSleepTimer()
                self.pause() // Stop playback
                Logger.d("⏰ [MusicPlayer] Sleep timer finished, audio paused")
            }
        }
    }
    
    func cancelSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        sleepTimerTimeRemaining = nil
        Logger.d("⏰ [MusicPlayer] Sleep timer cancelled")
    }
    
    // MARK: - Equalizer Methods
    
    private func updateEqualizer() {
        guard isEqEnabled else {
            // Bypass all EQ bands
            for i in 0..<equalizer.bands.count {
                equalizer.bands[i].bypass = true
            }
            return
        }
        
        // Enable bands
        for i in 0..<equalizer.bands.count {
            equalizer.bands[i].bypass = false
        }
        
        // Update 10 bands
        for i in 0..<10 {
            if i < eqBands.count {
                equalizer.bands[i].gain = Float(eqBands[i])
            }
        }
        
        // Update Bass (Band 10)
        equalizer.bands[10].gain = Float(bassLevel)
        
        // Update Treble (Band 11)
        equalizer.bands[11].gain = Float(trebleLevel)
        
        Logger.d("🎚️ [MusicPlayer] EQ Updated")
    }
    
    private func savePresets() {
        if let encoded = try? JSONEncoder().encode(customPresets) {
            UserDefaults.standard.set(encoded, forKey: "saved_eq_presets")
        }
    }
    
    private func loadPresets() {
        if let data = UserDefaults.standard.data(forKey: "saved_eq_presets"),
           let decoded = try? JSONDecoder().decode([EQPreset].self, from: data) {
            customPresets = decoded
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAudioEngine() {
        // Attach Nodes
        engine.attach(playerNode)
        engine.attach(equalizer)
        
        // Connect Player -> EQ -> MainMixer
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        // Use mixer's format for connection to allow conversion
        engine.connect(playerNode, to: equalizer, format: format)
        engine.connect(equalizer, to: engine.mainMixerNode, format: format)
        
        configureEqualizerBands()
        
        do {
            try engine.start()
            Logger.d("✅ [MusicPlayer] Engine started")
        } catch {
            Logger.e("❌ [MusicPlayer] Engine start error: \(error)")
        }
    }
    
    private func configureEqualizerBands() {
        let freqs: [Float] = [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
        
        // Bands 0-9: Graphic EQ
        for i in 0..<10 {
            let band = equalizer.bands[i]
            band.filterType = .parametric
            band.frequency = freqs[i]
            band.bandwidth = 1.0 // Q-factor
            band.gain = 0
            band.bypass = true
        }
        
        // Band 10: Bass (Low Shelf)
        let bassBand = equalizer.bands[10]
        bassBand.filterType = .lowShelf
        bassBand.frequency = 100
        bassBand.gain = 0
        bassBand.bypass = true
        
        // Band 11: Treble (High Shelf)
        let trebleBand = equalizer.bands[11]
        trebleBand.filterType = .highShelf
        trebleBand.frequency = 10000
        bassBand.gain = 0
        bassBand.bypass = true
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // Set category with options to support background playback
            try audioSession.setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true, options: [])
            UIApplication.shared.beginReceivingRemoteControlEvents()
            Logger.d("🎵 [MusicPlayer] Audio session configured for background playback")
        } catch {
            Logger.e("❌ [MusicPlayer] Error setting up audio session: \(error)")
        }
    }
    
    /// Reactivate audio session (call when app becomes active)
    func reactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            Logger.d("🎵 [MusicPlayer] Audio session reactivated")
            
            // Resume playback if it was playing before
            if isPlaying {
                if !engine.isRunning { try? engine.start() }
                playerNode.play()
            }
        } catch {
            Logger.e("❌ [MusicPlayer] Error reactivating audio session: \(error)")
        }
    }
    
    private func setupAudio(with url: URL, songRaw: SunoData) {
        Logger.d("🎵 [MusicPlayer] Setting up audio with URL: \(url.path)")
        
        // If remote, download first logic preserved? 
        // Logic shows url is passed. If local logic was handled by checking fileExists.
        // If it's a remote URL, we should download it (like existing logic did) and THEN setup engine.
        
        if !url.isFileURL {
             // Remote logic reuse
             setupAudioPlayerWithRemoteURL(url) // Note: this needs update to use engine too
             return
        }
        
        // Local File Logic
        setupLocalFile(url: url, song: songRaw)
    }
    
    private func setupLocalFile(url: URL, song: SunoData) {
        do {
            let file = try AVAudioFile(forReading: url)
            self.audioFile = file
            self.sampleRate = file.processingFormat.sampleRate
            self.duration = Double(file.length) / sampleRate
            
            // Validate duration logic? 
            // Existing logic updated song duration. Keeping it simple.
            if self.duration > 0 && song.duration == 0 {
                 // Update duration logic (simplified for brevity)
                 Task { try? await SunoDataManager.shared.updateSunoDataDuration(song.id, duration: self.duration) }
            }
            
            playerNode.stop()
            self.seekOffset = 0 
            self.currentTime = 0
            Logger.d("🎵 [MusicPlayer] setupLocalFile: seekOffset reset to 0")
            playerNode.scheduleFile(file, at: nil) {
                 // Completion
            }
            
            if !engine.isRunning { try? engine.start() }
            playerNode.play()
            
            isPlaying = true
            startPlaybackTimer() // Ensure timer starts for UI updates (seekbar/lyrics)
            updateEqualizer() // Apply EQ
            updateNowPlayingInfo()
            
            Logger.d("🎵 [MusicPlayer] Engine playing local file. Duration: \(duration)")
            
        } catch {
             Logger.e("❌ [MusicPlayer] Failed to load local file: \(error)")
        }
    }
    
    private func setupAudioPlayerWithRemoteURL(_ url: URL) {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("temp_audio_\(UUID().uuidString).wav")
                try data.write(to: tempURL)
                
                await MainActor.run {
                     self.setupLocalFile(url: tempURL, song: self.currentSong ?? SunoData.mock)
                }
            } catch {
                Logger.e("❌ [MusicPlayer] Error downloading remote file: \(error)")
            }
        }
    }
    
    private func startPlaybackTimer() {
        stopPlaybackTimer()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updatePlaybackProgress()
        }
    }
    
    private func updatePlaybackProgress() {
        guard isPlaying, !isSeeking, let nodeTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: nodeTime) else { return }
        
        let currentFrame = playerTime.sampleTime
        var calculatedTime = (Double(currentFrame) / sampleRate) + seekOffset
        
        // Log periodically to avoid spamming too much but enough to see jumps
        if Int(calculatedTime) % 5 == 0 && currentFrame % 10 == 0 {
            // Logger.d("🎵 [MusicPlayer] Progress: frame=\(currentFrame), offset=\(seekOffset), calcTime=\(calculatedTime)")
        }

        if calculatedTime >= 0 {
            self.currentTime = calculatedTime
        }
        
        // Autoplay next if finished
        if duration > 0 && calculatedTime >= duration - 0.2 {
             handlePlaybackFinished()
        }
        
        updateNowPlayingInfo(onlyTime: true)
    }
    
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func handlePlaybackFinished() {
        Logger.d("🎵 [MusicPlayer] Playback finished")
        switch playMode {
        case .sequential: nextSong()
        case .repeatOne: 
             seek(to: 0)
        case .shuffle: nextSong()
        }
    }
    
    // (Removed getLocalFilePath as it is used by caller or we can keep it if separate)
    
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
            
            // Handle Artwork
            if let localCoverPath = SunoDataManager.shared.getLocalCoverPath(for: song.id),
               let image = UIImage(contentsOfFile: localCoverPath.path) {
                
                let artwork = MPMediaItemArtwork(boundsSize: image.size) { size in
                    return image
                }
                nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
            }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
// Removed unused Delegate
// class MusicPlayerAudioDelegate...
