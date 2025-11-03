//
//  SplashScreenView.swift
//  DemoAdmobIosVer3
//
//  Created by Huy on 2025-10-09.
//

import SwiftUI
import FirebaseCore
import GoogleMobileAds

struct RootView: View {
    @State private var showSplash = true
    @State private var currentScreen: AppScreen = .splash
    @StateObject private var userDefaultsManager = UserDefaultsManager.shared
    
    enum AppScreen {
        case splash
        case selectLanguage
        case interview
        case intro
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
                    // Navigate to intro after interview
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentScreen = .intro
                    }
                }
                .transition(.pushFromRight)
                
            case .intro:
                IntroScreen { 
                    // Callback when intro is completed - navigate to subscription
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentScreen = .subscription
                    }
                }
                .transition(.pushFromRight)
                
            case .subscription:
                SubscriptionScreen {
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
                startLoading()
                
                // Log screen view
                FirebaseLogger.shared.logScreenView(FirebaseLogger.EVENT_SCREEN_SPLASH)
            }
        }
    }
}

// MARK: - Logic
extension SplashScreenView {
    
    private func testLoggerFuncSoLongAbcefgh12345678(){
        Logger.d("test logger for function name so long abcefgh12345678")
    }
    
    private func startLoading() {
        testLoggerFuncSoLongAbcefgh12345678()
        Logger.d("🚀 Splash: Start initialization")
        
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
            
            // Fetch remote config
            Logger.d("🔄 Fetching Remote Config...")
            await remoteConfigManager.fetchRemoteConfig()
            
            // Update progress
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.5)) {
                    progress = 1.0
                }
            }
            
            // Navigate directly to intro (skip language selection and ad)
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
                    // Don't mark as shown here, let user dismiss or purchase
                    nextScreen = .subscription
                    Logger.d("🔍 Splash: Navigating to subscription (user not subscribed)")
                } else {
                    // User is subscribed: Go to home
                    nextScreen = .home
                    Logger.d("🔍 Splash: Navigating to home (user is premium)")
                }
                
                onSplashCompleted(nextScreen)
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
