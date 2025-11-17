//
//  AdHostViewController.swift
//  DreamHomeAI
//
//  Created by Huy on 16/10/25.
//


import GoogleMobileAds
import UIKit

final class AdHostViewController: UIViewController, FullScreenContentDelegate {

    private var rewardedAd: GADRewardedAd?
    private var onFinish: (() -> Void)?

    static func present(with ad: GADRewardedAd, completion: @escaping () -> Void) {
        guard let top = UIApplication.shared.topViewController() else {
            completion()
            return
        }
        let host = AdHostViewController()
        host.modalPresentationStyle = .overFullScreen
        host.modalTransitionStyle = .crossDissolve
        host.rewardedAd = ad
        host.onFinish = completion

        top.present(host, animated: false) {
            // Gắn delegate mạnh mẽ trên host VC (không bị giải phóng sớm)
            ad.fullScreenContentDelegate = host
            ad.present(from: host) {
                // userDidEarnRewardHandler – không cần làm gì ở đây
                Logger.d("🎬 Reward ad presented")
                AnalyticsLogger.shared.logEvent("event_reward_ad_presented")
            }
        }
    }

    // MARK: - GADFullScreenContentDelegate
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Logger.d("🎬 Reward ad dismissed")
        dismiss(animated: false) { [onFinish] in onFinish?() }
    }

    func ad(_ ad: FullScreenPresentingAd,
            didFailToPresentFullScreenContentWithError error: Error) {
        Logger.e("❌ Reward ad failed to present: \(error.localizedDescription)")
        dismiss(animated: false) { [onFinish] in onFinish?() }
    }
}
