import SwiftUI
import GoogleMobileAds

// MARK: - Helpers to find top VC
extension UIApplication {
    func topViewController() -> UIViewController? {
        guard let scene = connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first
        else { return nil }
        return window.rootViewController?.topMostViewController()
    }
}

extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = presentedViewController { return presented.topMostViewController() }
        if let nav = self as? UINavigationController { return nav.visibleViewController?.topMostViewController() ?? self }
        if let tab = self as? UITabBarController { return tab.selectedViewController?.topMostViewController() ?? self }
        return self
    }
}

// MARK: - BannerAdView
struct BannerAdView: UIViewRepresentable {
    /// Bạn có thể truyền adUnitID khác; mặc định dùng từ AdManager (nếu có)
    var adUnitID: String = AdManager.shared.ADMOB_BANNER_AD_ID

    /// Maximum number of retries on ad load failure
    private let maxRetries = 3
    /// Base retry delay in seconds (will use exponential backoff)
    private let baseRetryDelay: TimeInterval = 10

    final class Container: UIView {
        var banner: GADBannerView?
        var widthConstraint: NSLayoutConstraint?
        var heightConstraint: NSLayoutConstraint?
        var currentWidth: CGFloat = 0
        var adUnitID: String = ""
        var hasLoadedOnce: Bool = false  // Prevent duplicate loads from updateUIView
    }

    func makeUIView(context: Context) -> Container {
        let container = Container()
        container.backgroundColor = .clear
        container.adUnitID = adUnitID

        // Khởi tạo banner theo width ban đầu (có thể bằng 0 -> sẽ update ở updateUIView)
        setupOrUpdateBanner(in: container, context: context)
        return container
    }

    func updateUIView(_ container: Container, context: Context) {
        // Only setup if banner hasn't been created yet (first-time layout)
        // Avoid reloading ad on every SwiftUI redraw
        if container.banner == nil {
            setupOrUpdateBanner(in: container, context: context)
        } else if !container.hasLoadedOnce {
            // Banner exists but hasn't loaded yet (width was 0 initially)
            setupOrUpdateBanner(in: container, context: context)
        }
    }

    // MARK: - Core
    private func setupOrUpdateBanner(in container: Container, context: Context) {
        // Lấy rootVC
        let root = UIApplication.shared.topViewController()

        // Tính width thực tế của container
        let targetWidth = max(container.bounds.width, UIScreen.main.bounds.width) // full width edge-to-edge
        let rounded = floor(targetWidth)

        // Nếu chưa có banner -> tạo
        if container.banner == nil {
            let banner = GADBannerView()
            banner.adUnitID = container.adUnitID
            banner.rootViewController = root
            banner.delegate = context.coordinator

            container.addSubview(banner)
            banner.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                banner.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                banner.centerYAnchor.constraint(equalTo: container.centerYAnchor)
            ])

            container.banner = banner
            container.currentWidth = 0 // ép tính lại size
        }

        // Nếu width thay đổi đáng kể VÀ chưa từng load -> set adSize và load lần đầu
        if abs(container.currentWidth - rounded) >= 1 && !container.hasLoadedOnce {
            container.currentWidth = rounded
            let adSize = currentOrientationAnchoredAdaptiveBanner(width: rounded)
            container.banner?.adSize = adSize

            // Cập nhật constraint chiều cao nếu muốn giữ khung ổn định
            if let h = container.heightConstraint {
                h.isActive = false
            }
            let newHeight = CGFloat(adSize.size.height)
            let h = container.heightAnchor.constraint(equalToConstant: newHeight)
            h.priority = .defaultHigh
            h.isActive = true
            container.heightConstraint = h

            // (Re)set rootVC nếu cần
            if container.banner?.rootViewController !== root, let root = root {
                container.banner?.rootViewController = root
            }

            // Load request (only once)
            container.hasLoadedOnce = true
            container.banner?.load(GoogleMobileAds.Request())
            Logger.d("🎯 [BannerAd] Initial load request sent")
        }
    }

    // MARK: - Coordinator
    func makeCoordinator() -> Coordinator { Coordinator(maxRetries: maxRetries, baseRetryDelay: baseRetryDelay) }

    final class Coordinator: NSObject, BannerViewDelegate {
        private var retryCount = 0
        private let maxRetries: Int
        private let baseRetryDelay: TimeInterval

        init(maxRetries: Int, baseRetryDelay: TimeInterval) {
            self.maxRetries = maxRetries
            self.baseRetryDelay = baseRetryDelay
            super.init()
        }

        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            // Reset retry count on success
            retryCount = 0
            Logger.d("🎯 [BannerAd] ✅ Ad received successfully")
        }

        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            retryCount += 1

            if retryCount > maxRetries {
                Logger.w("🎯 [BannerAd] ❌ Max retries (\(maxRetries)) reached, stopping. Error: \(error.localizedDescription)")
                return
            }

            // Exponential backoff: 30s, 60s, 120s
            let delay = baseRetryDelay * pow(2.0, Double(retryCount - 1))
            Logger.d("🎯 [BannerAd] ⏳ Retry \(retryCount)/\(maxRetries) in \(Int(delay))s. Error: \(error.localizedDescription)")

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak bannerView] in
                guard let bannerView = bannerView else { return }
                bannerView.load(GoogleMobileAds.Request())
            }
        }

        func bannerViewWillPresentScreen(_ bannerView: GADBannerView) { }
        func bannerViewWillDismissScreen(_ bannerView: GADBannerView) { }
        func bannerViewDidDismissScreen(_ bannerView: GADBannerView) { }
        func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
            Logger.d("🎯 [BannerAd] 📊 Impression recorded")
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        Text("Demo Banner (Adaptive)")
            .font(.headline)

        BannerAdView()
            .frame(height: 60) // chiều cao khung; bên trong sẽ set lại theo adSize
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal, 16)

        Spacer()
    }
    .onAppear {
        // Bảo đảm SDK đã start trước khi load banner
        MobileAds.shared.start()
    }
}
