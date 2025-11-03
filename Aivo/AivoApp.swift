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

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
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
        
        // Log app start event
        FirebaseLogger.shared.logAppStart()
        
        ApplicationDelegate.shared.application(
              application,
              didFinishLaunchingWithOptions: launchOptions
            )
        
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { _ in }
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
        
        // Reactivate audio session for background playback support
        MusicPlayer.shared.reactivateAudioSession()
    }
    
    func application(
            _ app: UIApplication,
            open url: URL,
            options: [UIApplication.OpenURLOptionsKey : Any] = [:]
        ) -> Bool {
            ApplicationDelegate.shared.application(
                app,
                open: url,
                sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                annotation: options[UIApplication.OpenURLOptionsKey.annotation]
            )
        }
}

@main
struct AivoApp: App {
    
    
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
