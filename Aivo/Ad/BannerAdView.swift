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

    /// Khoảng thời gian retry khi load fail (đơn giản)
    var retryDelay: TimeInterval = 5

    final class Container: UIView {
        var banner: GADBannerView?
        var widthConstraint: NSLayoutConstraint?
        var heightConstraint: NSLayoutConstraint?
        var currentWidth: CGFloat = 0
        var adUnitID: String = ""
        var retryDelay: TimeInterval = 5
    }

    func makeUIView(context: Context) -> Container {
        let container = Container()
        container.backgroundColor = .clear
        container.adUnitID = adUnitID
        container.retryDelay = retryDelay

        // Khởi tạo banner theo width ban đầu (có thể bằng 0 -> sẽ update ở updateUIView)
        setupOrUpdateBanner(in: container, context: context)
        return container
    }

    func updateUIView(_ container: Container, context: Context) {
        setupOrUpdateBanner(in: container, context: context)
    }

    // MARK: - Core
    private func setupOrUpdateBanner(in container: Container, context: Context) {
        // Lấy rootVC
        let root = UIApplication.shared.topViewController()

        // Tính width thực tế của container
        let targetWidth = max(container.bounds.width, UIScreen.main.bounds.width - 32) // fallback nếu chưa layout
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

        // Nếu width thay đổi đáng kể -> set lại adSize và reload
        if abs(container.currentWidth - rounded) >= 1 {
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

            // Load request
            container.banner?.load(GoogleMobileAds.Request())
        }
    }

    // MARK: - Coordinator
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, BannerViewDelegate {
        private let parent: BannerAdView

        init(_ parent: BannerAdView) {
            self.parent = parent
        }

        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            // Nhận được ad -> ok
            // Có thể animate hiện banner ở đây nếu ban đầu bạn ẩn nó.
            // VD: bannerView.alpha = 0; UIView.animate(withDuration: 0.25) { bannerView.alpha = 1 }
        }

        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            // Retry đơn giản sau vài giây
            DispatchQueue.main.asyncAfter(deadline: .now() + parent.retryDelay) { [weak bannerView] in
                guard let bannerView = bannerView else { return }
                bannerView.load(GoogleMobileAds.Request())
            }
        }

        func bannerViewWillPresentScreen(_ bannerView: GADBannerView) { }
        func bannerViewWillDismissScreen(_ bannerView: GADBannerView) { }
        func bannerViewDidDismissScreen(_ bannerView: GADBannerView) { }
        func bannerViewDidRecordImpression(_ bannerView: GADBannerView) { }
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
