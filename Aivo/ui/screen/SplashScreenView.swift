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
        case intro
        case buyCredit
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
                            currentScreen = .intro
                        }
                    }
                }
                .transition(.pushFromRight)
                
            case .intro:
                IntroScreen {
                    userDefaultsManager.markIntroAsShowed()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentScreen = .buyCredit
                    }
                }
                .transition(.pushFromRight)
                
            case .buyCredit:
                BuyCreditScreen {
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
    @State private var progress: Double = 0.0
    @State private var isInitialized = false
    @State private var hasNavigated = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 20) {
                    Image("AppIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .cornerRadius(20)
                    
                    Text("DreamHome AI")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .frame(maxHeight: UIScreen.main.bounds.height / 3)
                
                Spacer()
                
                VStack(spacing: 16) {
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .white))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                        .padding(.horizontal, 40)
                    
                    Text("splash.description")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
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
        withAnimation(.easeInOut(duration: 1.2)) {
            progress = 0.3
        }
        
        Task {
            // Initialize Firebase
            if FirebaseApp.app() == nil {
                FirebaseApp.configure()
                Logger.d("✅ Firebase configured")
            } else {
                Logger.d("✅ Firebase already configured")
            }
            
            // Fetch remote config
            Logger.d("🔄 Fetching Remote Config...")
            await remoteConfigManager.fetchRemoteConfig()
            
            // Load ad config from Remote Config
            adManager.loadAdConfig()
            
            // Initialize AdMob SDK
            await MainActor.run {
                adManager.startSDK()
                adManager.preloadNative { _ in }
                Logger.d("✅ AdMob SDK started")
            }
            
            // Update progress
            await MainActor.run {
                withAnimation(.easeInOut(duration: 1.0)) {
                    progress = 0.7
                }
            }
            
            // Preload app open ad
            await MainActor.run {
                adManager.preloadAppOpenAd { isLoaded in
                    Logger.d("✅ App open ad preload result: \(isLoaded)")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showAdAndContinue()
                    }
                }
            }
        }
    }
    
    private func showAdAndContinue() {
        guard !hasNavigated else { return } // tránh show lại khi view reload
        hasNavigated = true
        
        adManager.showAppOpenAd { success in
            Logger.d("✅ App open ad finished (success=\(success)) → Navigate to next screen")
            
            // Delay 0.3s để tránh crash UI sau khi ad đóng
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // Determine next screen based on user preferences
                let nextScreen: RootView.AppScreen
                
                // Debug: Print current state
                Logger.d("🔍 Splash: shouldShowLanguageSelection = \(userDefaultsManager.shouldShowLanguageSelection())")
                Logger.d("🔍 Splash: shouldShowIntro = \(userDefaultsManager.shouldShowIntro())")
                Logger.d("🔍 Splash: shouldShowBuyCreditPrompt = \(userDefaultsManager.shouldShowBuyCreditPrompt())")
                
                if userDefaultsManager.shouldShowLanguageSelection() {
                    nextScreen = .selectLanguage
                    Logger.d("🔍 Splash: Navigating to selectLanguage")
                } else if userDefaultsManager.shouldShowIntro() {
                    nextScreen = .intro
                    Logger.d("🔍 Splash: Navigating to intro")
                } else if userDefaultsManager.shouldShowBuyCreditPrompt() {
                    userDefaultsManager.markBuyCreditPromptShown()
                    nextScreen = .buyCredit
                    Logger.d("🔍 Splash: Navigating to buyCredit")
                } else {
                    nextScreen = .home
                    Logger.d("🔍 Splash: Navigating to home")
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
