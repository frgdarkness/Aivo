//
//  AivoApp.swift
//  Aivo
//
//  Created by Huy on 18/10/25.
//

import SwiftUI
import SwiftData
import FirebaseCore
import GoogleMobileAds
import FBSDKCoreKit
import FBAudienceNetwork
import AppTrackingTransparency
import AppsFlyerLib

class AppDelegate: NSObject, UIApplicationDelegate, AppsFlyerLibDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        //FirebaseApp.configure()
        
        // Initialize Google Mobile Ads SDK
        MobileAds.shared.start(completionHandler: nil)
        
        // Load app open ad after SDK initialization
        AppOpenAdManager.shared.loadAd()
        
        // Log app start event to both Firebase and AppsFlyer
        FirebaseLogger.shared.logAppStart()
        AppsFlyerLogger.shared.logAppStart()
        
        // 🔥 AppsFlyer Configuration
        AppsFlyerLib.shared().appsFlyerDevKey = "2DJteu5ecJUiAFiBYaCf5Q"
        AppsFlyerLib.shared().appleAppID = "6754759511"
        AppsFlyerLib.shared().delegate = self // ✅ Set delegate to receive callbacks
        
        // 🐛 Enable debug mode - CRITICAL for seeing logs
        AppsFlyerLib.shared().isDebug = true
        
        // 📊 Enable verbose logs (more detailed)
        //AppsFlyerLib.shared().logLevel = .debug
        
        // ⏱️ Wait for ATT authorization
        AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
        
        // 📝 Log AppsFlyer configuration
        print("🔥 [AppsFlyer] Initialized with:")
        print("🔥 [AppsFlyer] Dev Key: 2DJteu5ecJUiAFiBYaCf5Q")
        print("🔥 [AppsFlyer] Apple App ID: 6754759511")
        print("🔥 [AppsFlyer] Debug Mode: true")
        print("🔥 [AppsFlyer] Delegate: \(String(describing: AppsFlyerLib.shared().delegate))")
        
        NotificationCenter.default.addObserver(self, selector: NSSelectorFromString("sendLaunch"), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        
        
        ApplicationDelegate.shared.application(
              application,
              didFinishLaunchingWithOptions: launchOptions
            )
        
        // ✅ CRITICAL: Activate Facebook App Events for conversion tracking
        AppEvents.shared.activateApp()
        
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                // Update Facebook tracking based on ATT status
                DispatchQueue.main.async {
                    if status == .authorized {
                        FBAdSettings.setAdvertiserTrackingEnabled(true)
                    } else {
                        FBAdSettings.setAdvertiserTrackingEnabled(false)
                    }
                }
            }
        } else {
            FBAdSettings.setAdvertiserTrackingEnabled(true)
        }
        FBAudienceNetworkAds.initialize(with: nil, completionHandler: nil)

        
        // Initialize CreditStoreManager and fetch products
        DispatchQueue.main.async {
            CreditStoreManager.shared.fetchProducts()
            // Initialize SubscriptionManager (it auto-fetches products and checks status on init)
            _ = SubscriptionManager.shared
        }
        
        // Initialize profile with local-first approach
        Task {
            do {
                let profile = await ProfileSyncManager.shared.loadProfileOnStartup()
                Logger.d("✅ Profile loaded on startup: \(profile.profileID)")
                
                // Check subscription status on app startup and update premium status
                await SubscriptionManager.shared.checkSubscriptionStatus()
                
                // Check and grant bonus credits for subscription (separate from purchase flow)
                await SubscriptionManager.shared.checkBonusCreditForSubscription()
            } catch {
                Logger.d("❌ Failed to load profile on startup: \(error)")
            }
        }
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Show app open ad when app becomes active
        //AppOpenAdManager.shared.showAdIfAvailable()
        
        // ✅ CRITICAL: Activate Facebook App Events when app becomes active
        // This ensures Facebook can track app opens and conversions
        AppEvents.shared.activateApp()
        
        // 🔥 Start AppsFlyer SDK
        print("🔥 [AppsFlyer] Starting SDK...")
        AppsFlyerLib.shared().start()
        
        // Reactivate audio session for background playback support
        MusicPlayer.shared.reactivateAudioSession()
    }
    
    // SceneDelegate support
    @objc func sendLaunch() {
        AppsFlyerLib.shared().start()
    }
    
    func application(
            _ app: UIApplication,
            open url: URL,
            options: [UIApplication.OpenURLOptionsKey : Any] = [:]
        ) -> Bool {
            AppsFlyerLib.shared().handleOpen(url, options: options)
            return ApplicationDelegate.shared.application(
                app,
                open: url,
                sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                annotation: options[UIApplication.OpenURLOptionsKey.annotation]
            )
        }
    
    
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        AppsFlyerLib.shared().continue(userActivity, restorationHandler: nil)
        return true
    }
    
    // MARK: - AppsFlyerLibDelegate Methods
    
    /// Called when conversion data is received (organic/non-organic install)
    func onConversionDataSuccess(_ conversionInfo: [AnyHashable : Any]) {
        print("🔥 [AppsFlyer] ✅ Conversion Data Success:")
        for (key, value) in conversionInfo {
            print("🔥 [AppsFlyer]   \(key): \(value)")
        }
        
        // Check if organic or non-organic install
        if let status = conversionInfo["af_status"] as? String {
            if status == "Non-organic" {
                if let mediaSource = conversionInfo["media_source"] as? String,
                   let campaign = conversionInfo["campaign"] as? String {
                    print("🔥 [AppsFlyer] 📊 Non-organic install from: \(mediaSource), Campaign: \(campaign)")
                }
            } else {
                print("🔥 [AppsFlyer] 🌱 Organic install")
            }
        }
    }
    
    /// Called when conversion data fails
    func onConversionDataFail(_ error: Error) {
        print("🔥 [AppsFlyer] ❌ Conversion Data Failed: \(error.localizedDescription)")
    }
    
    /// Called when app is opened via deep link
    func onAppOpenAttribution(_ attributionData: [AnyHashable : Any]) {
        print("🔥 [AppsFlyer] 🔗 Deep Link Attribution Data:")
        for (key, value) in attributionData {
            print("🔥 [AppsFlyer]   \(key): \(value)")
        }
    }
    
    /// Called when deep link attribution fails
    func onAppOpenAttributionFailure(_ error: Error) {
        print("🔥 [AppsFlyer] ❌ Deep Link Attribution Failed: \(error.localizedDescription)")
    }
}

@main
struct AivoApp: App {
    
    // ✅ CRITICAL: Connect AppDelegate to SwiftUI lifecycle
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var languageManager = LanguageManager.shared
    
    init() {
        // Configure Firebase before any Firebase services are used
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
                .environmentObject(RemoteConfigManager.shared)
                .environmentObject(AdManager.shared)
                .environmentObject(LanguageManager.shared)
                .environment(\.locale, languageManager.locale)
                //.id(languageManager.currentLanguageCode) // ép SwiftUI rebuild toàn bộ
        }
    }
}
