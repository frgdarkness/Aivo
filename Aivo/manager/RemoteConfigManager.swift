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
    
    private init() {
        setupRemoteConfig()
    }
    
    // MARK: - Setup Remote Config
    private func setupRemoteConfig() {
        print("### RemoteConfigManager: Setting up Remote Config")
        
        // Set default values
        let defaults: [String: NSObject] = [
            "ADMOB_APP_ID": "ca-app-pub-9821898502051437~6864300948" as NSString,
            "ADMOB_BANNER_AD_ID": "ca-app-pub-3940256099942544/9214589741" as NSString,
            "ADMOB_INTERSTITIAL_AD_ID": "ca-app-pub-3940256099942544/1033173712" as NSString,
            "ADMOB_REWARDED_AD_ID": "ca-app-pub-3940256099942544/5224354917" as NSString,
            "ADMOB_APP_OPEN_AD_ID": "ca-app-pub-3940256099942544/9257395921" as NSString,
            "ADMOB_NATIVE_VIDEO_AD_ID": "ca-app-pub-3940256099942544/1044960115" as NSString,
            "ADMOB_NATIVE_AD_ID": "ca-app-pub-3940256099942544/2247696110" as NSString,
            "STATUS": "Firebase HomeAI IOS defalt status" as NSString
        ]
        
        remoteConfig.setDefaults(defaults)
        
        // Set fetch timeout
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0 // For development
        remoteConfig.configSettings = settings
    }
    
    // MARK: - Fetch Remote Config
    func fetchRemoteConfig() async {
        print("### RemoteConfigManager: Starting to fetch remote config")
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let status = try await remoteConfig.fetch()
            print("### RemoteConfigManager: Fetch status: \(status)")
            
            // Always try to activate, even if fetch didn't get new data
            let activateStatus = try await remoteConfig.activate()
            print("### RemoteConfigManager: Activate status: \(activateStatus)")
            
            // Check if we have any values (either from fetch or defaults)
            let hasValues = !remoteConfig.allKeys(from: .default).isEmpty || 
                           !remoteConfig.allKeys(from: .remote).isEmpty
            
            if hasValues {
                print("### RemoteConfigManager: Using available config values")
            } else {
                print("### RemoteConfigManager: No config values available, using defaults")
            }
            
            // Load ad configuration on main thread
            await MainActor.run {
                AdManager.shared.loadAdConfig()
                
                // Load STATUS value
                statusValue = remoteConfig.configValue(forKey: "STATUS").stringValue
                print("### RemoteConfigManager: STATUS value: \(statusValue)")
                
                isLoading = false
                print("### RemoteConfigManager: Remote config fetch completed successfully")
            }
            
        } catch {
            print("### RemoteConfigManager: Error fetching remote config: \(error)")
            await MainActor.run {
                // Even if fetch fails, try to use default values
                AdManager.shared.loadAdConfig()
                statusValue = remoteConfig.configValue(forKey: "STATUS").stringValue
                print("### RemoteConfigManager: Using default values due to fetch error")
                isLoading = false
            }
        }
    }
}
