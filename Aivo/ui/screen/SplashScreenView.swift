//
//  SplashScreenView.swift
//  DemoAdmobIosVer3
//
//  Created by Huy on 2025-10-09.
//

import SwiftUI
import FirebaseCore
import GoogleMobileAds
import AppTrackingTransparency
import FBAudienceNetwork

struct RootView: View {
    @State private var showSplash = true
    @State private var currentScreen: AppScreen = .splash
    @StateObject private var userDefaultsManager = UserDefaultsManager.shared
    @ObservedObject private var ratingManager = AppRatingManager.shared
    @State private var toast: SimpleToast? = nil
    
    enum AppScreen {
        case splash
        case selectLanguage
        case interview
        case introSample
        case intro
        case inputUsername
        case subscription
        case home
    }
    
    var body: some View {
        ZStack {
            switch currentScreen {
            case .splash:
                SplashScreenView { nextScreen in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentScreen = nextScreen
                    }
                }
                .transition(.opacity)
                
            case .selectLanguage:
                LanguageAwareView {
                    SelectLanguageScreen { language in
                        //userDefaultsManager.setLanguageSelected(language)
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentScreen = .interview
                        }
                    }
                }
                .transition(.pushFromRight)
                
            case .interview:
                InterviewScreen {
                    // Navigate to intro sample after interview
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentScreen = .introSample
                    }
                }
                .transition(.pushFromRight)
                
            case .introSample:
                IntroSampleScreen {
                    // Navigate to intro after sample screen
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentScreen = .intro
                    }
                }
                .transition(.pushFromRight)
                
            case .intro:
                IntroScreen(
                    onIntroCompleted: {
                        // Song creation completed - go to input username
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentScreen = .inputUsername
                        }
                    },
                    onSkip: {
                        // Skip intro - go directly to input username
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentScreen = .inputUsername
                        }
                    }
                )
                .transition(.pushFromRight)
                
            case .inputUsername:
                InputUsernameScreen {
                    // After username input, go to subscription
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentScreen = .subscription
                    }
                }
                .transition(.pushFromRight)
                
            case .subscription:
                SubscriptionView {
                    // When subscription screen is dismissed (user taps X), navigate to home
                    // This allows user to skip subscription and use app with limited features
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentScreen = .home
                    }
                }
                .transition(.pushFromRight)
                
            case .home:
                HomeView()
                    .transition(.pushFromRight)
            }
        }
        .overlay(
            Group {
                if ratingManager.showRatingDialog {
                    RateAppDialog(
                        isPresented: $ratingManager.showRatingDialog,
                        onRate: { stars in
                            if stars >= 4 {
                                // Show encouraging toast
                                toast = SimpleToast(
                                message: "Thanks for the love! 💛 A quick App Store rating would help us a lot!",
                                    icon: "star.fill",
                                    duration: 5.0
                                )
                                
                                // Dismiss custom dialog immediately so they see the app/toast
                                ratingManager.dismissDialog()
                                
                                // Show real rate prompt after a delay to let them read the toast
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    ratingManager.handleRateAction(stars: stars)
                                }
                            } else {
                                ratingManager.handleRateAction(stars: stars)
                            }
                        },
                        onDismiss: {
                            ratingManager.dismissDialog()
                        }
                    )
                    .zIndex(9999) // Topmost
                }
            }
        )
        .simpleToast($toast)
    }
}

struct SplashScreenView: View {
    let onSplashCompleted: (RootView.AppScreen) -> Void
    
    @StateObject private var remoteConfigManager = RemoteConfigManager.shared
    @StateObject private var adManager = AdManager.shared
    @StateObject private var userDefaultsManager = UserDefaultsManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var progress: Double = 0.0
    @State private var isInitialized = false
    @State private var hasNavigated = false
    
    var body: some View {
        ZStack {
            // Aivo Background with Orange Gradient
            AivoSunsetBackground()
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 20) {
                    Image("AppIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .cornerRadius(20)
                        .shadow(color: AivoTheme.Shadow.orange, radius: 15, x: 0, y: 0)
                    
                    Text("AIVO")
                        .aivoText(.title)
                        .shadow(color: AivoTheme.Shadow.orange, radius: 10, x: 0, y: 0)
                    
                    Text("AI Music Creator")
                        .aivoText(.subtitle)
                        .opacity(0.9)
                }
                .frame(maxHeight: UIScreen.main.bounds.height / 3)
                
                Spacer()
                
                VStack(spacing: 16) {
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: AivoTheme.Primary.orange))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                        .padding(.horizontal, 40)
                    
                
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            if !isInitialized {
                isInitialized = true
                
                // Log screen view
                AnalyticsLogger.shared.logScreenView(AnalyticsLogger.EVENT.EVENT_SCREEN_SPLASH)
                
                // Request ATT first (only on first install), then start loading
                requestATTThenLoad()
            }
        }
    }
}

// MARK: - Logic
extension SplashScreenView {
    
    private func testLoggerFuncSoLongAbcefgh12345678(){
        Logger.d("test logger for function name so long abcefgh12345678")
    }
    
    /// Request ATT on first install, then proceed to loading
    private func requestATTThenLoad() {
        if #available(iOS 14, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
            if status == .notDetermined {
                // First time: show ATT dialog, wait for response, then load
                Logger.i("🔐 ATT: Requesting authorization...")
                // Small delay so Splash UI is visible first
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    ATTrackingManager.requestTrackingAuthorization { result in
                        DispatchQueue.main.async {
                            self.handleATTResult(result)
                            self.startLoading()
                        }
                    }
                }
            } else {
                // Already determined (from previous launch): skip ATT, load directly
                Logger.i("🔐 ATT: Already determined (\(status.rawValue))")
                handleATTResult(status)
                startLoading()
            }
        } else {
            FBAdSettings.setAdvertiserTrackingEnabled(true)
            startLoading()
        }
    }
    
    private func handleATTResult(_ status: ATTrackingManager.AuthorizationStatus) {
        switch status {
        case .authorized:
            Logger.i("🔐 ATT: Authorized ✅")
            FBAdSettings.setAdvertiserTrackingEnabled(true)
        case .denied:
            Logger.i("🔐 ATT: Denied")
            FBAdSettings.setAdvertiserTrackingEnabled(false)
        case .restricted:
            Logger.i("🔐 ATT: Restricted")
            FBAdSettings.setAdvertiserTrackingEnabled(false)
        case .notDetermined:
            Logger.i("🔐 ATT: Not Determined")
            FBAdSettings.setAdvertiserTrackingEnabled(false)
        @unknown default:
            FBAdSettings.setAdvertiserTrackingEnabled(false)
        }
    }
    
    private func startLoading() {
        testLoggerFuncSoLongAbcefgh12345678()
        Logger.d("🚀 Splash: Start initialization")
        AppRatingManager.shared.logStatus()
        
        // Progress step 1
        withAnimation(.easeInOut(duration: 0.5)) {
            progress = 0.5
        }
        
        Task {
            // Initialize Firebase
            if FirebaseApp.app() == nil {
                FirebaseApp.configure()
                Logger.d("✅ Firebase configured")
            } else {
                Logger.d("✅ Firebase already configured")
            }
            
            // Check subscription status first
            Logger.d("🔄 Checking Subscription Status...")
            await subscriptionManager.refreshStatus()
            
            // Preload App Open Ad in parallel (only for non-premium users)
            let isPremium = SubscriptionManager.shared.isPremium
            if !isPremium {
                Logger.d("📢 Splash: Preloading App Open Ad for non-premium user...")
                AppOpenAdManager.shared.preloadAppOpenAd { success in
                    Logger.d("📢 Splash: App Open Ad preload result: \(success)")
                }
            }
            
            // Fetch remote config
            Logger.d("🔄 Fetching Remote Config...")
            await remoteConfigManager.fetchRemoteConfig()
            
            // Update progress
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.5)) {
                    progress = 1.0
                }
            }
            
            // Determine next screen
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                guard !hasNavigated else { return }
                hasNavigated = true
                
                let nextScreen: RootView.AppScreen
                
                // Debug: Print current state
                Logger.d("🔍 Splash: shouldShowIntro = \(userDefaultsManager.shouldShowIntro())")
                Logger.d("🔍 Splash: shouldShowSubscriptionPrompt = \(userDefaultsManager.shouldShowSubscriptionPrompt())")
                Logger.d("🔍 Splash: isPremium = \(SubscriptionManager.shared.isPremium)")
                
                if userDefaultsManager.shouldShowIntro() {
                    // First time: Show interview first, then intro, then subscription
                    nextScreen = .interview
                    Logger.d("🔍 Splash: Navigating to interview (first time)")
                } else if !SubscriptionManager.shared.isPremium {
                    // Not first time, but not subscribed: Show subscription directly
                    nextScreen = .subscription
                    Logger.d("🔍 Splash: Navigating to subscription (user not subscribed)")
                } else {
                    // User is subscribed: Go to home
                    nextScreen = .home
                    Logger.d("🔍 Splash: Navigating to home (user is premium)")
                }
                
                // Show App Open Ad before navigating (only for non-premium returning users)
                if !SubscriptionManager.shared.isPremium && !userDefaultsManager.shouldShowIntro() {
                    Logger.d("📢 Splash: Showing App Open Ad before navigation...")
                    AppOpenAdManager.shared.showAppOpenAd { _ in
                        Logger.d("📢 Splash: App Open Ad dismissed, navigating to \(nextScreen)")
                        onSplashCompleted(nextScreen)
                    }
                } else {
                    // Premium user or first-time user: skip ad
                    onSplashCompleted(nextScreen)
                }
            }
        }
    }
}

extension AnyTransition {
    static var pushFromRight: AnyTransition {
        .asymmetric(insertion: .move(edge: .trailing),  // màn mới từ phải vào
                    removal:   .move(edge: .leading))   // màn cũ trượt sang trái
    }
    
    static var pushFromLeft: AnyTransition {
        .asymmetric(insertion: .move(edge: .leading),
                    removal:   .move(edge: .trailing))
    }
}

#Preview {
    SplashScreenView() {_ in
        
    }
}
