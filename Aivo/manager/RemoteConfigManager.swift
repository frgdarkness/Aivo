import Foundation
import FirebaseRemoteConfig
import FirebaseCore

class RemoteConfigManager: ObservableObject {
    static let shared = RemoteConfigManager()
    
    private let remoteConfig = RemoteConfig.remoteConfig()
    @Published var isLoading = false
    @Published var statusValue = ""
    @Published var creditPerRequest = 30
    @Published var adminEmail = "hananyogev77@gmail.com"
    @Published var supportUrl = "https://www.google.com/"
    @Published var introSongList: [IntroSongJSON] = []
    @Published var hottestList: [SunoData] = []
    @Published var newList: [SunoData] = []
    @Published var coverModelList: [CoverSongModel] = []
    @Published var songStatus: [SongStatus] = []
    
    private init() {
        setupRemoteConfig()
    }
    
    // MARK: - Setup Remote Config
    private func setupRemoteConfig() {
        Logger.d("### RemoteConfigManager: Setting up Remote Config")
        
        // Set default values
        let defaults: [String: NSObject] = [
            "ADMOB_APP_ID": "ca-app-pub-9821898502051437~6864300948" as NSString,
            "ADMOB_BANNER_AD_ID": "ca-app-pub-3940256099942544/9214589741" as NSString,
            "ADMOB_INTERSTITIAL_AD_ID": "ca-app-pub-3940256099942544/1033173712" as NSString,
            "ADMOB_REWARDED_AD_ID": "ca-app-pub-3940256099942544/5224354917" as NSString,
            "ADMOB_APP_OPEN_AD_ID": "ca-app-pub-3940256099942544/9257395921" as NSString,
            "ADMOB_NATIVE_VIDEO_AD_ID": "ca-app-pub-3940256099942544/1044960115" as NSString,
            "ADMOB_NATIVE_AD_ID": "ca-app-pub-3940256099942544/2247696110" as NSString,
            "STATUS": "Firebase HomeAI IOS defalt status" as NSString,
            "CREDIT_PER_REQUEST": 30 as NSNumber,
            "ADMIN_EMAIL": "hananyogev77@gmail.com" as NSString,
            "SUPPORT_URL": "https://www.google.com/" as NSString
        ]
        
        remoteConfig.setDefaults(defaults)
        
        // Set fetch timeout
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0 // For development
        remoteConfig.configSettings = settings
    }
    
    // MARK: - Fetch Remote Config
    func fetchRemoteConfig() async {
        Logger.d("### RemoteConfigManager: Starting to fetch remote config")
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let status = try await remoteConfig.fetch()
            Logger.d("### RemoteConfigManager: Fetch status: \(status)")
            
            //adminEmail = remoteConfig.value(forKey: "ADMIN_EMAIL") as! String
            //supportUrl = remoteConfig.value(forKey: "SUPPORT_URL") as! String
            
            // Always try to activate, even if fetch didn't get new data
            let activateStatus = try await remoteConfig.activate()
            Logger.d("### RemoteConfigManager: Activate status: \(activateStatus)")
            
            // Check if we have any values (either from fetch or defaults)
            let hasValues = !remoteConfig.allKeys(from: .default).isEmpty || 
                           !remoteConfig.allKeys(from: .remote).isEmpty
            
            if hasValues {
                Logger.d("### RemoteConfigManager: Using available config values")
            } else {
                Logger.d("### RemoteConfigManager: No config values available, using defaults")
            }
            
            // Load ad configuration on main thread
            await MainActor.run {
                AdManager.shared.loadAdConfig()
                
                // Load STATUS value
                statusValue = remoteConfig.configValue(forKey: "STATUS").stringValue
                Logger.d("### RemoteConfigManager: STATUS value: \(statusValue)")
                
                isLoading = false
                Logger.d("### RemoteConfigManager: Remote config fetch completed successfully")
            }
            
            // Build data after fetching remote config
            await buildDataFromRemoteConfig()
            
        } catch {
            Logger.d("### RemoteConfigManager: Error fetching remote config: \(error)")
            await MainActor.run {
                // Even if fetch fails, try to use default values
                AdManager.shared.loadAdConfig()
                statusValue = remoteConfig.configValue(forKey: "STATUS").stringValue
                Logger.d("### RemoteConfigManager: Using default values due to fetch error")
                isLoading = false
            }
            
            // Still try to build data from resources
            await buildDataFromRemoteConfig()
        }
    }
    
    // MARK: - Build Data from Remote Config
    func buildDataFromRemoteConfig() async {
        Logger.d("### RemoteConfigManager: Building data from remote config...")
        
        await MainActor.run {
            // Build hottest songs
            if let songs = parseSunoDataList(from: remoteConfig.configValue(forKey: "HOTTEST_SONGS").stringValue) {
                hottestList = songs
                Logger.d("### RemoteConfigManager: Loaded \(songs.count) hottest songs from remote config")
            } else {
                hottestList = loadSunoDataFromResource(filename: "hottest_songs")
                Logger.d("### RemoteConfigManager: Loaded \(hottestList.count) hottest songs from resource")
            }
            
            // Build new songs
            if let songs = parseSunoDataList(from: remoteConfig.configValue(forKey: "NEW_SONGS").stringValue) {
                newList = songs
                Logger.d("### RemoteConfigManager: Loaded \(songs.count) new songs from remote config")
            } else {
                newList = loadSunoDataFromResource(filename: "new_songs")
                Logger.d("### RemoteConfigManager: Loaded \(newList.count) new songs from resource")
            }
            
            // Build intro songs
            if let introSongs = parseIntroSongList(from: remoteConfig.configValue(forKey: "INTRO_SONGS").stringValue) {
                introSongList = introSongs
                Logger.d("### RemoteConfigManager: Loaded intro songs from remote config")
            } else {
                introSongList = loadIntroSongsFromResource()
                Logger.d("### RemoteConfigManager: Loaded intro songs from resource")
            }
            
            // Build cover models
            if let models = parseCoverModels(from: remoteConfig.configValue(forKey: "COVER_MODEL_LIST").stringValue) {
                coverModelList = models
                Logger.d("### RemoteConfigManager: Loaded \(models.count) cover models from remote config")
            } else {
                coverModelList = loadCoverModelsFromResource()
                Logger.d("### RemoteConfigManager: Loaded \(coverModelList.count) cover models from resource")
            }
            
            // Build song status
            if let status = parseSongStatus(from: remoteConfig.configValue(forKey: "SONG_STATUS").stringValue) {
                songStatus = status
                Logger.d("### RemoteConfigManager: Loaded \(status.count) song statuses from remote config")
            } else {
                songStatus = loadSongStatusFromResource()
                Logger.d("### RemoteConfigManager: Loaded \(songStatus.count) song statuses from resource")
            }
        }
    }
    
    // MARK: - Parse Methods
    
    private func parseSunoDataList(from jsonString: String) -> [SunoData]? {
        guard !jsonString.isEmpty,
              let data = jsonString.data(using: .utf8) else {
            return nil
        }
        
        do {
            let songs = try JSONDecoder().decode([SunoData].self, from: data)
            return songs
        } catch {
            Logger.e("### RemoteConfigManager: Error parsing SunoData list: \(error)")
            return nil
        }
    }
    
    private func parseIntroSongList(from jsonString: String) -> [IntroSongJSON]? {
        guard !jsonString.isEmpty,
              let data = jsonString.data(using: .utf8) else {
            return nil
        }
        
        do {
            let introSongs = try JSONDecoder().decode([IntroSongJSON].self, from: data)
            return introSongs
        } catch {
            Logger.e("### RemoteConfigManager: Error parsing IntroSongJSON list: \(error)")
            return nil
        }
    }
    
    private func parseCoverModels(from jsonString: String) -> [CoverSongModel]? {
        guard !jsonString.isEmpty,
              let data = jsonString.data(using: .utf8) else {
            return nil
        }
        
        do {
            let models = try JSONDecoder().decode([CoverSongModel].self, from: data)
            return models
        } catch {
            Logger.e("### RemoteConfigManager: Error parsing CoverSongModel list: \(error)")
            return nil
        }
    }
    
    private func parseSongStatus(from jsonString: String) -> [SongStatus]? {
        guard !jsonString.isEmpty,
              let data = jsonString.data(using: .utf8) else {
            return nil
        }
        
        do {
            let status = try JSONDecoder().decode([SongStatus].self, from: data)
            return status
        } catch {
            Logger.e("### RemoteConfigManager: Error parsing SongStatus list: \(error)")
            return nil
        }
    }
    
    // MARK: - Load from Resource Methods
    
    private func loadSunoDataFromResource(filename: String) -> [SunoData] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            Logger.d("### RemoteConfigManager: Resource file \(filename).json not found")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let songs = try JSONDecoder().decode([SunoData].self, from: data)
            return songs
        } catch {
            Logger.e("### RemoteConfigManager: Error loading \(filename).json: \(error)")
            return []
        }
    }
    
    private func loadIntroSongsFromResource() -> [IntroSongJSON] {
        guard let url = Bundle.main.url(forResource: "sample_ai_song", withExtension: "json") else {
            Logger.d("### RemoteConfigManager: Resource file sample_ai_song.json not found")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let introSongs = try JSONDecoder().decode([IntroSongJSON].self, from: data)
            return introSongs
        } catch {
            Logger.e("### RemoteConfigManager: Error loading sample_ai_song.json: \(error)")
            return []
        }
    }
    
    private func loadCoverModelsFromResource() -> [CoverSongModel] {
        guard let url = Bundle.main.url(forResource: "cover_song_models", withExtension: "json") else {
            Logger.d("### RemoteConfigManager: Resource file cover_song_models.json not found")
            return CoverSongModel.loadModels() // Fallback to default models
        }
        
        do {
            let data = try Data(contentsOf: url)
            let models = try JSONDecoder().decode([CoverSongModel].self, from: data)
            return models
        } catch {
            Logger.e("### RemoteConfigManager: Error loading cover_song_models.json: \(error)")
            return CoverSongModel.loadModels() // Fallback to default models
        }
    }
    
    private func loadSongStatusFromResource() -> [SongStatus] {
        guard let url = Bundle.main.url(forResource: "song_status", withExtension: "json") else {
            Logger.d("### RemoteConfigManager: Resource file song_status.json not found")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let status = try JSONDecoder().decode([SongStatus].self, from: data)
            return status
        } catch {
            Logger.e("### RemoteConfigManager: Error loading song_status.json: \(error)")
            return []
        }
    }
}
