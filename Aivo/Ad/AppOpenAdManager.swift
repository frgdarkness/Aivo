import Foundation
import GoogleMobileAds
import UIKit

protocol AppOpenAdManagerDelegate: AnyObject {
    func appOpenAdDidReceiveAd()
    func appOpenAdDidFailToReceiveAd(with error: Error)
    func appOpenAdWillPresentScreen()
    func appOpenAdDidDismissScreen()
}

class AppOpenAdManager: NSObject {
    /// The app open ad.
    var appOpenAd: AppOpenAd?
    /// Maintains a reference to the delegate.
    weak var appOpenAdManagerDelegate: AppOpenAdManagerDelegate?
    /// Keeps track of if an app open ad is loading.
    var isLoadingAd = false
    /// Keeps track of if an app open ad is showing.
    var isShowingAd = false
    /// Keeps track of the time when an app open ad was loaded to discard expired ad.
    var loadTime: Date?
    /// For more interval details, see https://support.google.com/admob/answer/9341964
    let timeoutInterval: TimeInterval = 4 * 3600 // 4 hours
    
    // Callback for completion
    private var adCallback: ((Bool) -> Void)?
    
    static let shared = AppOpenAdManager()
    
    private override init() {
        super.init()
    }
    
    func loadAdNew() async {
        // Do not load ad if there is an unused ad or one is already loading.
        if isLoadingAd || isAdAvailable() {
            return
        }
        isLoadingAd = true
        
        do {
            appOpenAd = try await AppOpenAd.load(
                with: "ca-app-pub-3940256099942544/5575463023", request: Request())
            appOpenAd?.fullScreenContentDelegate = self
            loadTime = Date()
        } catch {
            Logger.d("App open ad failed to load with error: \(error.localizedDescription)")
            appOpenAd = nil
            loadTime = nil
        }
        isLoadingAd = false
    }
    
    // MARK: - New Interface Methods (similar to AdManager)
    func preloadAppOpenAd(onFinish: @escaping (Bool) -> Void) {
        // Kiểm tra đã có loadedAd chưa
        if appOpenAd != nil && isAdAvailable() {
            Logger.d("AppOpenAdManager: App open ad already loaded")
            onFinish(true)
            return
        }
        
        // Kiểm tra có đang loading không
        if isLoadingAd {
            Logger.d("AppOpenAdManager: App open ad is already loading")
            onFinish(false)
            return
        }
        
        // Bắt đầu load mới
        isLoadingAd = true
        let request = GADRequest()
        
        AppOpenAd.load(
            with: AdManager.shared.ADMOB_APP_OPEN_AD_ID,
            request: request
        ) { [weak self] ad, error in
            DispatchQueue.main.async {
                self?.isLoadingAd = false
                
                if let error = error {
                    Logger.e("AppOpenAdManager: Failed to load app open ad: \(error.localizedDescription)")
                    onFinish(false)
                    return
                }
                
                self?.appOpenAd = ad
                self?.appOpenAd?.fullScreenContentDelegate = self
                self?.loadTime = Date()
                Logger.d("AppOpenAdManager: App open ad loaded successfully")
                onFinish(true)
            }
        }
    }
    
    func showAppOpenAd(onFinish: @escaping (Bool) -> Void) {
        adCallback = onFinish
        Logger.d("AppOpenAdManager: Show app open ad")
        
        // Kiểm tra xem có loadedAd chưa
        if let ad = appOpenAd, isAdAvailable() {
            guard let topVC = UIApplication.shared.topViewController() else {
                Logger.w("AppOpenAdManager: No top view controller found")
                adCallback = nil
                onFinish(false)
                return
            }
            
            isShowingAd = true
            ad.present(from: topVC)
            Logger.d("AppOpenAdManager: App open ad shown successfully")
            return
        }
        
        // Nếu đang preload → chờ tối đa 10s
        if isLoadingAd {
            Logger.d("⌛ Waiting for app open ad to finish loading...")
            waitForAdLoaded(timeout: 10) { [weak self] success in
                guard let self = self else { return }
                if success, let ad = self.appOpenAd, let root = UIApplication.shared.topViewController() {
                    self.isShowingAd = true
                    ad.present(from: root)
                    Logger.d("✅ App open ad presented after waiting")
                } else {
                    Logger.w("❌ Timeout waiting for app open ad")
                    self.adCallback?(false)
                    self.adCallback = nil
                }
            }
            return
        }
        
        // Nếu không có ad → load ngay và show
        Logger.d("🔄 Loading app open ad on demand...")
        preloadAppOpenAd { [weak self] success in
            guard let self = self else { return }
            if success, let ad = self.appOpenAd, let root = UIApplication.shared.topViewController() {
                self.isShowingAd = true
                ad.present(from: root)
                Logger.d("✅ App open ad loaded and presented")
            } else {
                Logger.e("❌ Failed to load app open ad on demand")
                self.adCallback?(false)
                self.adCallback = nil
            }
        }
    }
    
    private func waitForAdLoaded(timeout: Int = 10, checkInterval: Double = 1.0, completion: @escaping (Bool) -> Void) {
        var elapsed = 0
        Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { timer in
            elapsed += 1
            // Kiểm tra ad đã có chưa
            if self.appOpenAd != nil && self.isAdAvailable() {
                timer.invalidate()
                completion(true)
            } else if elapsed >= timeout {
                timer.invalidate()
                completion(false)
            }
        }
    }
    
    /// Request an app open ad.
    func loadAd() {
        // Do not load ad if there is an unused ad or one is already loading.
        if isLoadingAd || isAdAvailable() {
            return
        }
        
        isLoadingAd = true
        Logger.d("AppOpenAdManager: Start loading app open ad")
        
        let request = GADRequest()
        AppOpenAd.load(
            with: AdManager.shared.ADMOB_APP_OPEN_AD_ID,
            request: Request()
        ) { [weak self] appOpenAd, error in
            self?.isLoadingAd = false
            
            if let error = error {
                Logger.e("AppOpenAdManager: Failed to load app open ad: \(error.localizedDescription)")
                self?.appOpenAdManagerDelegate?.appOpenAdDidFailToReceiveAd(with: error)
                return
            }
            
            Logger.d("AppOpenAdManager: App open ad loaded successfully")
            self?.appOpenAd = appOpenAd
            self?.appOpenAd?.fullScreenContentDelegate = self
            self?.loadTime = Date()
            self?.appOpenAdManagerDelegate?.appOpenAdDidReceiveAd()
        }
    }
    
    /// Check if ad exists and can be shown.
    func isAdAvailable() -> Bool {
        // Check if ad exists and hasn't expired.
        return appOpenAd != nil && wasLoadTimeLessThanNHoursAgo(timeoutInterval)
    }
    
    /// Check if ad was loaded within the last n hours.
    func wasLoadTimeLessThanNHoursAgo(_ timeoutInterval: TimeInterval) -> Bool {
        guard let loadTime = loadTime else {
            return false
        }
        
        let now = Date()
        let timeIntervalBetweenNowAndLoadTime = now.timeIntervalSince(loadTime)
        return timeIntervalBetweenNowAndLoadTime < timeoutInterval
    }
    
    /// Show the app open ad if available.
    func showAdIfAvailable() {
        // If the app open ad is already showing, do not show the ad again.
        if isShowingAd {
            Logger.w("AppOpenAdManager: App open ad is already showing")
            return
        }
        
        // If the app open ad is not available yet, invoke the callback then load the ad.
        if !isAdAvailable() {
            Logger.d("AppOpenAdManager: App open ad is not ready yet")
            loadAd()
            return
        }
        
        guard let appOpenAd = appOpenAd else {
            Logger.w("AppOpenAdManager: App open ad is nil")
            loadAd()
            return
        }
        
        guard let rootViewController = UIApplication.shared.topViewController() else {
            Logger.w("AppOpenAdManager: Root view controller is unavailable")
            return
        }
        
        Logger.d("AppOpenAdManager: Will present app open ad")
        isShowingAd = true
        appOpenAd.present(from: rootViewController)
    }
}

// MARK: - GADFullScreenContentDelegate
extension AppOpenAdManager: FullScreenContentDelegate {
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        Logger.d("AppOpenAdManager: App open ad will present full screen content")
        appOpenAdManagerDelegate?.appOpenAdWillPresentScreen()
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Logger.d("AppOpenAdManager: App open ad did dismiss full screen content")
        appOpenAd = nil
        isShowingAd = false
        appOpenAdManagerDelegate?.appOpenAdDidDismissScreen()
        
        // Call completion callback
        adCallback?(true)
        adCallback = nil
        
        // Load a new ad for next time.
        loadAd()
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Logger.e("AppOpenAdManager: App open ad failed to present full screen content: \(error.localizedDescription)")
        appOpenAd = nil
        isShowingAd = false
        appOpenAdManagerDelegate?.appOpenAdDidFailToReceiveAd(with: error)
        
        // Call completion callback with failure
        adCallback?(false)
        adCallback = nil
        
        // Load a new ad for next time.
        loadAd()
    }
}
