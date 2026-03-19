import SwiftUI
import GoogleMobileAds

// Use namespace to avoid naming conflicts
typealias GADNativeAdView = GoogleMobileAds.NativeAdView

import UIKit
import GoogleMobileAds

// MARK: - Compact Native Ad (Dark Theme + Compliant MediaView)
// Layout:
// ┌──────────────────────────────────────────────┐
// │ AD                                           │
// │ ┌────────┐  Headline text...       ┌──────┐ │
// │ │ Media  │  Body description...    │ CTA  │ │
// │ │120x120 │  🔸 icon  Advertiser   │      │ │
// │ └────────┘                         └──────┘ │
// └──────────────────────────────────────────────┘
// Height: ~140pt
final class CompactNativeAdUIView: GADNativeAdView {
    // MARK: - Subviews
    private let iconImageView = UIImageView()
    private let adBadgeLabel = UILabel()
    private let headlineLabel = UILabel()
    private let bodyLabel = UILabel()
    private let media = GoogleMobileAds.MediaView()
    private let callToActionButton = UIButton(type: .system)
    private let advertiserLabel = UILabel()

    private let paddingH: CGFloat = 12
    private let paddingV: CGFloat = 10

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        mapNativeAssets()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        mapNativeAssets()
    }

    // MARK: - UI Setup
    private func setupUI() {
        // Dark background matching Aivo theme
        backgroundColor = UIColor(white: 0.08, alpha: 1.0)
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.15).cgColor
        clipsToBounds = true

        // ── AD badge (top-left) ──
        adBadgeLabel.text = " AD "
        adBadgeLabel.font = .systemFont(ofSize: 9, weight: .bold)
        adBadgeLabel.textColor = .black
        adBadgeLabel.backgroundColor = UIColor(red: 1.0, green: 0.75, blue: 0.1, alpha: 1.0)
        adBadgeLabel.textAlignment = .center
        adBadgeLabel.layer.cornerRadius = 3
        adBadgeLabel.layer.masksToBounds = true
        adBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(adBadgeLabel)

        // ── Media view (left thumbnail, 120x120 minimum for AdMob policy) ──
        media.translatesAutoresizingMaskIntoConstraints = false
        media.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        media.layer.cornerRadius = 8
        media.layer.masksToBounds = true
        media.contentMode = .scaleAspectFill
        addSubview(media)

        // ── Headline ──
        headlineLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        headlineLabel.textColor = .white
        headlineLabel.numberOfLines = 2
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false

        // ── Body ──
        bodyLabel.font = .systemFont(ofSize: 12)
        bodyLabel.textColor = UIColor(white: 0.55, alpha: 1.0)
        bodyLabel.numberOfLines = 2
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false

        // ── Icon (small, beside advertiser) ──
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.layer.cornerRadius = 4
        iconImageView.layer.masksToBounds = true
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.backgroundColor = UIColor(white: 0.15, alpha: 1.0)

        // ── Advertiser label ──
        advertiserLabel.font = .systemFont(ofSize: 11, weight: .medium)
        advertiserLabel.textColor = UIColor(white: 0.45, alpha: 1.0)
        advertiserLabel.numberOfLines = 1
        advertiserLabel.translatesAutoresizingMaskIntoConstraints = false

        // Icon + Advertiser row
        let advertiserRow = UIStackView(arrangedSubviews: [iconImageView, advertiserLabel])
        advertiserRow.axis = .horizontal
        advertiserRow.alignment = .center
        advertiserRow.spacing = 6
        advertiserRow.translatesAutoresizingMaskIntoConstraints = false

        // Right text stack: headline → body → advertiser row
        let textStack = UIStackView(arrangedSubviews: [headlineLabel, bodyLabel, advertiserRow])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 3
        textStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textStack)

        // ── CTA button (pill) ──
        callToActionButton.translatesAutoresizingMaskIntoConstraints = false
        callToActionButton.backgroundColor = UIColor(red: 1.0, green: 0.55, blue: 0.1, alpha: 1.0)
        callToActionButton.setTitleColor(.black, for: .normal)
        callToActionButton.titleLabel?.font = .systemFont(ofSize: 11, weight: .bold)
        callToActionButton.layer.cornerRadius = 12
        callToActionButton.layer.masksToBounds = true
        callToActionButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 12)
        addSubview(callToActionButton)

        // MARK: - Constraints
        NSLayoutConstraint.activate([
            // AD badge (top-left)
            adBadgeLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            adBadgeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: paddingH),

            // Media (left side, 120x120)
            media.topAnchor.constraint(equalTo: adBadgeLabel.bottomAnchor, constant: 6),
            media.leadingAnchor.constraint(equalTo: leadingAnchor, constant: paddingH),
            media.widthAnchor.constraint(equalToConstant: 120),
            media.heightAnchor.constraint(equalToConstant: 120),
            media.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -paddingV),

            // Icon size
            iconImageView.widthAnchor.constraint(equalToConstant: 18),
            iconImageView.heightAnchor.constraint(equalToConstant: 18),

            // Text stack (right of media)
            textStack.topAnchor.constraint(equalTo: media.topAnchor, constant: 2),
            textStack.leadingAnchor.constraint(equalTo: media.trailingAnchor, constant: 10),
            textStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -paddingH),

            // CTA button (bottom-right)
            callToActionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -paddingH),
            callToActionButton.bottomAnchor.constraint(equalTo: media.bottomAnchor),
            callToActionButton.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    private func mapNativeAssets() {
        mediaView = media
        iconView = iconImageView
        headlineView = headlineLabel
        bodyView = bodyLabel
        callToActionView = callToActionButton
        advertiserView = advertiserLabel
    }

    // MARK: - Helpers
    func applyPlaceholderForMissingIcon() {
        iconImageView.image = nil
        iconImageView.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        iconImageView.isHidden = false
    }

    func clearIconBackgroundIfNeeded() {
        iconImageView.backgroundColor = .clear
        iconImageView.contentMode = .scaleAspectFill
    }
}

// Keep old name for backward compatibility
typealias RichNativeAdUIView = CompactNativeAdUIView

// MARK: - SwiftUI Container
struct NativeAdContainerView: UIViewRepresentable {
    func makeUIView(context: Context) -> CompactNativeAdUIView {
        let view = CompactNativeAdUIView()
        AdManager.shared.getNativeAd { ad in
            guard let ad = ad else {
                Logger.w("NativeAdContainerView: no native ad available")
                return
            }
            DispatchQueue.main.async {
                view.nativeAd = ad
                (view.headlineView as? UILabel)?.text = ad.headline
                (view.bodyView as? UILabel)?.text = ad.body
                (view.callToActionView as? UIButton)?.setTitle(ad.callToAction, for: .normal)
                (view.advertiserView as? UILabel)?.text = ad.advertiser ?? ""
                view.mediaView?.mediaContent = ad.mediaContent

                if let icon = ad.icon?.image {
                    (view.iconView as? UIImageView)?.image = icon
                    view.clearIconBackgroundIfNeeded()
                } else {
                    view.applyPlaceholderForMissingIcon()
                }
            }
        }
        return view
    }

    func updateUIView(_ uiView: CompactNativeAdUIView, context: Context) {}
}

#Preview {
    VStack {
        NativeAdContainerView()
            .frame(height: 160)
            .padding(.horizontal, 20)
        Spacer()
    }
    .background(Color.black)
}
