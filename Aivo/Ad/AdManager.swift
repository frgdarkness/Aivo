import Foundation
import GoogleMobileAds
import FirebaseRemoteConfig
import UIKit

// Use namespace to avoid naming conflicts
typealias GADRequest = GoogleMobileAds.Request
typealias GADBannerView = GoogleMobileAds.BannerView
typealias GADInterstitialAd = GoogleMobileAds.InterstitialAd
typealias GADRewardedAd = GoogleMobileAds.RewardedAd
typealias GADAdLoader = GoogleMobileAds.AdLoader
typealias GADNativeAd = GoogleMobileAds.NativeAd
typealias GADAdLoaderDelegate = GoogleMobileAds.AdLoaderDelegate
typealias GADNativeAdLoaderDelegate = GoogleMobileAds.NativeAdLoaderDelegate

// Định nghĩa kích thước banner
let kGADAdSizeBanner = GoogleMobileAds.AdSize(size: CGSize(width: 320, height: 50), flags: 0)

final class AdManager: NSObject, ObservableObject {
    static let shared = AdManager()
    
    @Published var ADMOB_APP_ID = "ca-app-pub-9821898502051437~6864300948"
    @Published var ADMOB_BANNER_AD_ID = "ca-app-pub-9821898502051437/8508237870"
    @Published var ADMOB_INTERSTITIAL_AD_ID = "ca-app-pub-9821898502051437/9563450620"
    @Published var ADMOB_REWARDED_AD_ID = "ca-app-pub-9821898502051437/9423849826"
    @Published var ADMOB_APP_OPEN_AD_ID = "ca-app-pub-9821898502051437/2449324819"
    @Published var ADMOB_NATIVE_VIDEO_AD_ID = "ca-app-pub-9821898502051437/9292003791"
    @Published var ADMOB_NATIVE_AD_ID = "ca-app-pub-9821898502051437/9292003791"

    private(set) var bannerView: GADBannerView?
    private(set) var interstitial: GADInterstitialAd?
    private(set) var rewardedAd: GADRewardedAd?
    private(set) var nativeAd: GADNativeAd?

    // MARK: Banner preload (double-buffer)
     private var isLoadingBanner = false
     private var bannerReady: GADBannerView?     // banner đã sẵn sàng để trả ra show
     private var bannerStandby: GADBannerView?   // banner đang tải kế tiếp

     // MARK: Native preload (single buffer)
     private var isLoadingNative = false
     private var adLoader: GADAdLoader?
    
    
    // Loading states
    private var isLoadingInterstitial = false
    private var isLoadingRewarded = false
    
    // Ad callbacks
    private var rewardAdCallback: ((Bool) -> Void)?
    private var interstitialAdCallback: ((Bool) -> Void)?

    private var loadingVC: AdLoadingViewController?
    
    private override init() { super.init() }

    func startSDK() {
        MobileAds.shared.start(completionHandler: nil)
    }
    
    func loadAdConfig() {
        Logger.d("AdManager: Loading ad configuration from Remote Config")
        
        let remoteConfig = RemoteConfig.remoteConfig()
        
        // Load ad configuration values
        ADMOB_APP_ID = remoteConfig.configValue(forKey: "ADMOB_APP_ID").stringValue
        ADMOB_BANNER_AD_ID = remoteConfig.configValue(forKey: "ADMOB_BANNER_AD_ID").stringValue
        ADMOB_INTERSTITIAL_AD_ID = remoteConfig.configValue(forKey: "ADMOB_INTERSTITIAL_AD_ID").stringValue
        ADMOB_REWARDED_AD_ID = remoteConfig.configValue(forKey: "ADMOB_REWARDED_AD_ID").stringValue
        ADMOB_APP_OPEN_AD_ID = remoteConfig.configValue(forKey: "ADMOB_APP_OPEN_AD_ID").stringValue
        ADMOB_NATIVE_VIDEO_AD_ID = remoteConfig.configValue(forKey: "ADMOB_NATIVE_VIDEO_AD_ID").stringValue
        ADMOB_NATIVE_AD_ID = remoteConfig.configValue(forKey: "ADMOB_NATIVE_AD_ID").stringValue
        
        // Log loaded values
        Logger.d("AdManager: Loaded ad configuration:")
        Logger.d("ADMOB_APP_ID: \(ADMOB_APP_ID)")
        Logger.d("ADMOB_BANNER_AD_ID: \(ADMOB_BANNER_AD_ID)")
        Logger.d("ADMOB_INTERSTITIAL_AD_ID: \(ADMOB_INTERSTITIAL_AD_ID)")
        Logger.d("ADMOB_REWARDED_AD_ID: \(ADMOB_REWARDED_AD_ID)")
        Logger.d("ADMOB_APP_OPEN_AD_ID: \(ADMOB_APP_OPEN_AD_ID)")
        Logger.d("ADMOB_NATIVE_VIDEO_AD_ID: \(ADMOB_NATIVE_VIDEO_AD_ID)")
        Logger.d("ADMOB_NATIVE_AD_ID: \(ADMOB_NATIVE_AD_ID)")
    }
    
    private func presentLoadingFullScreen() {
        guard loadingVC == nil, let top = UIApplication.shared.topViewController() else { return }
        let vc = AdLoadingViewController()
        vc.modalPresentationStyle = .fullScreen        // ÉP full-screen khi present
        vc.isModalInPresentation = true
        loadingVC = vc
        top.present(vc, animated: true)
    }

    private func dismissLoadingFullScreen(completion: (() -> Void)? = nil) {
        guard let vc = loadingVC else { completion?(); return }
        loadingVC = nil
        vc.dismiss(animated: true, completion: completion)
    }

    func preloadAll(presentingViewController: UIViewController?) {
        preloadInterstitial { _ in }
        preloadRewardedAd { _ in }
        preloadNative { _ in }
        preloadAppOpenAd { _ in }
    }
    
    // MARK: - App Open Ad Methods
    func preloadAppOpenAd() {
        Logger.d("AdManager: Preloading app open ad")
        AppOpenAdManager.shared.loadAd()
    }
    
    func preloadAppOpenAd(onFinish: @escaping (Bool) -> Void) {
        Logger.d("AdManager: Preloading app open ad with callback")
        AppOpenAdManager.shared.preloadAppOpenAd(onFinish: onFinish)
    }
    
    func showAppOpenAd() {
        Logger.d("AdManager: Showing app open ad")
        AppOpenAdManager.shared.showAdIfAvailable()
    }
    
    func showAppOpenAd(onFinish: @escaping (Bool) -> Void) {
        Logger.d("AdManager: Showing app open ad with callback")
        AppOpenAdManager.shared.showAppOpenAd(onFinish: onFinish)
    }
    
    func isAppOpenAdAvailable() -> Bool {
        return AppOpenAdManager.shared.isAdAvailable()
    }

    // MARK: - Interstitial Ad Methods
    func preloadInterstitial(onFinish: @escaping (Bool) -> Void) {
        // Kiểm tra đã có loadedAd chưa
        if interstitial != nil {
            Logger.d("AdManager: Interstitial ad already loaded")
            onFinish(true)
            return
        }
        
        // Kiểm tra có đang loading không
        if isLoadingInterstitial {
            Logger.d("AdManager: Interstitial ad is already loading")
            onFinish(false)
            return
        }
        
        // Bắt đầu load mới
        isLoadingInterstitial = true
        let request = GADRequest()
        
        GADInterstitialAd.load(with: ADMOB_INTERSTITIAL_AD_ID, request: request) { [weak self] ad, error in
            DispatchQueue.main.async {
                self?.isLoadingInterstitial = false
                
                if let error = error {
                    Logger.e("AdManager: Failed to load interstitial ad: \(error.localizedDescription)")
                    onFinish(false)
                    return
                }
                
                self?.interstitial = ad
                // Set delegate để handle dismiss callback
                self?.interstitial?.fullScreenContentDelegate = self
                Logger.d("AdManager: Interstitial ad loaded successfully")
                onFinish(true)
            }
        }
    }

    func showInterAd(onFinish: @escaping (Bool) -> Void) {
        interstitialAdCallback = onFinish
        Logger.d("AdManager: Show interstitial ad")
        
        // Kiểm tra xem có loadedAd chưa
        if let interstitial = interstitial {
            // Có rồi thì show luôn
            guard let topVC = UIApplication.shared.topViewController() else {
                Logger.w("AdManager: No top view controller found")
                interstitialAdCallback = nil
                onFinish(false)
                return
            }
            
            interstitial.present(from: topVC)
            Logger.d("AdManager: Interstitial ad shown successfully")
            return
        }
        
        // Nếu đang preload → show loading full screen & đợi
        if isLoadingInterstitial {
            Logger.d("⌛ Waiting for interstitial to finish loading...")
            presentLoadingFullScreen()
            
            waitForAdLoaded(timeout: 10) { [weak self] success in
                DispatchQueue.main.async {
                    self?.dismissLoadingFullScreen {
                        guard let self = self else { return }
                        if success {
                            self.showInterAd(onFinish: onFinish)
                        } else {
                            Logger.w("❌ Timeout waiting for interstitial")
                            self.interstitialAdCallback = nil
                            onFinish(false)
                        }
                    }
                }
            }
            return
        }
        
        // Nếu không có ad → load ngay và show, show loading full screen
        Logger.d("🔄 Loading interstitial ad on demand...")
        presentLoadingFullScreen()
        
        preloadInterstitial { [weak self] success in
            DispatchQueue.main.async {
                self?.dismissLoadingFullScreen {
                    guard let self = self else { return }
                    if success {
                        self.showInterAd(onFinish: onFinish)
                    } else {
                        self.interstitialAdCallback = nil
                        onFinish(false)
                    }
                }
            }
        }
    }
    
    private func waitForAdLoaded(timeout: Int = 10, checkInterval: Double = 1.0, completion: @escaping (Bool) -> Void) {
        var elapsed = 0
        Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { timer in
            elapsed += 1
            // Kiểm tra ad đã có chưa
            if self.interstitial != nil || self.rewardedAd != nil {
                timer.invalidate()
                completion(true)
            } else if elapsed >= timeout {
                timer.invalidate()
                completion(false)
            }
        }
    }

    // MARK: - Rewarded Ad Methods
    func preloadRewardedAd(onFinish: @escaping (Bool) -> Void) {
        Logger.d("preloadRewardedAd")
        // Kiểm tra đã có loadedAd chưa
        if rewardedAd != nil {
            Logger.d("AdManager: Rewarded ad already loaded")
            onFinish(true)
            return
        }
        
        // Kiểm tra có đang loading không
        if isLoadingRewarded {
            Logger.d("AdManager: Rewarded ad is already loading")
            onFinish(false)
            return
        }
        
        // Bắt đầu load mới
        isLoadingRewarded = true
        let request = GADRequest()
        
        GADRewardedAd.load(with: ADMOB_REWARDED_AD_ID, request: request) { [weak self] ad, error in
            DispatchQueue.main.async {
                self?.isLoadingRewarded = false
                
                if let error = error {
                    Logger.e("AdManager: Failed to load rewarded ad: \(error.localizedDescription)")
                    onFinish(false)
                    return
                }
                
                self?.rewardedAd = ad
                // Set delegate để handle reward callback
                self?.rewardedAd?.fullScreenContentDelegate = self
                Logger.d("AdManager: Rewarded ad loaded successfully")
                onFinish(true)
            }
        }
    }

    func showRewardAd(onFinish: @escaping (Bool) -> Void) {
        rewardAdCallback = onFinish
        Logger.d("showRewardAd")

        if let rewardedAd = rewardedAd {
            guard let topVC = UIApplication.shared.topViewController() else {
                Logger.w("AdManager: No top view controller found")
                rewardAdCallback = nil
                onFinish(false)
                return
            }
            rewardedAd.present(from: topVC) {}
            Logger.d("AdManager: Rewarded ad shown successfully")
            return
        }

        // Đang loading → show loading full screen & đợi
        if isLoadingRewarded {
            Logger.d("⌛ Waiting for rewarded ad to finish loading...")
            presentLoadingFullScreen()

            waitForAdLoaded(timeout: 10) { [weak self] success in
                DispatchQueue.main.async {
                    self?.dismissLoadingFullScreen {
                        guard let self = self else { return }
                        if success {
                            self.showRewardAd(onFinish: onFinish)
                        } else {
                            Logger.w("❌ Timeout waiting for rewarded ad")
                            self.rewardAdCallback = nil
                            onFinish(false)
                        }
                    }
                }
            }
            return
        }

        // Chưa load → bắt đầu load, show loading full screen
        Logger.d("has not loaded rewarded ad -> start preloading now...")
        presentLoadingFullScreen()

        preloadRewardedAd { [weak self] success in
            DispatchQueue.main.async {
                self?.dismissLoadingFullScreen {
                    guard let self = self else { return }
                    if success {
                        self.showRewardAd(onFinish: onFinish)
                    } else {
                        self.rewardAdCallback = nil
                        onFinish(false)
                    }
                }
            }
        }
    }


    func preloadNative(onFinish: @escaping (Bool) -> Void) {
        // Đã có sẵn ad -> không cần load lại
        if nativeAd != nil {
            Logger.d("AdManager: Native ad already loaded")
            onFinish(true)
            return
        }

        // Nếu đang load thì báo lại
        if isLoadingNative {
            Logger.d("AdManager: Native ad is already loading")
            onFinish(false)
            return
        }

        // Bắt đầu load mới
        isLoadingNative = true
        let request = GADRequest()

        adLoader = GADAdLoader(
            adUnitID: ADMOB_NATIVE_AD_ID,
            rootViewController: nil,
            adTypes: [.native],
            options: []
        )
        adLoader?.delegate = self
        adLoader?.load(request)

        // Lưu completion để callback khi load xong
        //nativeLoadCompletion = onFinish
    }

    func getNativeAd(onFinish: @escaping (GADNativeAd?) -> Void) {
        Logger.d("AdManager: Get native ad")

        // Nếu đã có sẵn ad thì trả về luôn
        if let ad = nativeAd {
            Logger.d("AdManager: Return cached native ad immediately")
            onFinish(ad)
            // Sau khi trả -> clear và preload tiếp cho vòng sau
            self.nativeAd = nil
            self.preloadNative { _ in }
            return
        }

        // Nếu đang load -> chờ
        if isLoadingNative {
            Logger.d("⌛ Waiting for native ad to finish loading...")
            waitForAdLoaded(timeout: 10) { [weak self] success in
                guard let self = self else { return }
                if success, let ad = self.nativeAd {
                    Logger.d("✅ Native ad returned after waiting")
                    onFinish(ad)
                    self.nativeAd = nil
                    self.preloadNative { _ in } // chuẩn bị vòng sau
                } else {
                    Logger.w("❌ Timeout waiting for native ad")
                    onFinish(nil)
                }
            }
            return
        }

        // Nếu không có ad và cũng không đang load -> load ngay
        Logger.d("🔄 Loading native ad on demand...")
        preloadNative { [weak self] success in
            guard let self = self else { return }
            if success, let ad = self.nativeAd {
                Logger.d("✅ Native ad loaded and returned")
                onFinish(ad)
                self.nativeAd = nil
                self.preloadNative { _ in } // preload lại vòng sau
            } else {
                Logger.e("❌ Failed to load native ad on demand")
                onFinish(nil)
            }
        }
    }

    // MARK: - Legacy Methods (for backward compatibility)
    func preloadInterstitial() {
        preloadInterstitial { _ in }
    }

    func showInterstitial(from viewController: UIViewController?) {
        showInterAd { _ in }
    }
}

extension AdManager: GADAdLoaderDelegate, GADNativeAdLoaderDelegate {
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        DispatchQueue.main.async {
            Logger.d("AdManager: Native ad loaded successfully")
            self.isLoadingNative = false
            self.nativeAd = nativeAd
        }
    }

    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        DispatchQueue.main.async {
            Logger.e("AdManager: Failed to load native ad: \(error.localizedDescription)")
            self.isLoadingNative = false
        }
    }
}

// MARK: - GADFullScreenContentDelegate
extension AdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        // Kiểm tra loại ad để handle đúng
        if ad is GADRewardedAd {
            Logger.d("AdManager: Rewarded ad dismissed")
            
            // Clear ad và gọi callback với true (user đã xem xong ad)
            rewardedAd = nil
            rewardAdCallback?(true)
            rewardAdCallback = nil
            
            // Preload ad mới cho lần sau
            preloadRewardedAd { _ in }
        } else if ad is GADInterstitialAd {
            Logger.d("AdManager: Interstitial ad dismissed")
            
            // Clear ad và gọi callback với true (user đã xem xong ad)
            interstitial = nil
            interstitialAdCallback?(true)
            interstitialAdCallback = nil
            
            // Preload ad mới cho lần sau
            preloadInterstitial { _ in }
        }
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        // Kiểm tra loại ad để handle đúng
        if ad is GADRewardedAd {
            Logger.e("AdManager: Failed to present rewarded ad: \(error.localizedDescription)")
            
            // Clear ad và gọi callback với false
            rewardedAd = nil
            rewardAdCallback?(false)
            rewardAdCallback = nil
        } else if ad is GADInterstitialAd {
            Logger.e("AdManager: Failed to present interstitial ad: \(error.localizedDescription)")
            
            // Clear ad và gọi callback với false
            interstitial = nil
            interstitialAdCallback?(false)
            interstitialAdCallback = nil
        }
    }
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        if ad is GADRewardedAd {
            Logger.d("AdManager: Rewarded ad will present")
        } else if ad is GADInterstitialAd {
            Logger.d("AdManager: Interstitial ad will present")
        }
    }
}


