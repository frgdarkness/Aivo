import SwiftUI
import GoogleMobileAds

// Use namespace to avoid naming conflicts
typealias GADNativeAdView = GoogleMobileAds.NativeAdView

import UIKit
import GoogleMobileAds

// MARK: - Horizontal Card Native Ad
// Layout:
// ┌──────────────────────────────────────────────┐
// │ AD                                           │
// │ ┌────────────────┐  ┌──────────────────────┐ │
// │ │                │  │ 🔸 Icon              │ │
// │ │   MediaView    │  │ Headline text...     │ │
// │ │   (4/7 width)  │  │ Body description...  │ │
// │ │                │  │        [CTA Button]  │ │
// │ └────────────────┘  └──────────────────────┘ │
// └──────────────────────────────────────────────┘
// Height: 150pt
final class CompactNativeAdUIView: GADNativeAdView {
    // MARK: - Subviews
    private let iconImageView = UIImageView()
    private let adBadgeLabel = UILabel()
    private let headlineLabel = UILabel()
    private let bodyLabel = UILabel()
    private let media = GoogleMobileAds.MediaView()
    private let callToActionButton = UIButton(type: .system)

    private let margin: CGFloat = 10

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
        backgroundColor = UIColor(white: 0.08, alpha: 1.0)
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.15).cgColor
        clipsToBounds = true

        // ── MediaView (left 4/7) ──
        media.translatesAutoresizingMaskIntoConstraints = false
        media.backgroundColor = UIColor.black
        media.layer.cornerRadius = 8
        media.layer.masksToBounds = true
        media.contentMode = .scaleAspectFill
        addSubview(media)

        // ── AD badge (top-left, overlaying media — custom label, not native asset) ──
        adBadgeLabel.text = " AD "
        adBadgeLabel.font = .systemFont(ofSize: 9, weight: .bold)
        adBadgeLabel.textColor = .black
        adBadgeLabel.backgroundColor = UIColor(red: 1.0, green: 0.75, blue: 0.1, alpha: 1.0)
        adBadgeLabel.textAlignment = .center
        adBadgeLabel.layer.cornerRadius = 2
        adBadgeLabel.layer.masksToBounds = true
        adBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(adBadgeLabel)

        // ── Icon (right side, top) ──
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.layer.cornerRadius = 6
        iconImageView.layer.masksToBounds = true
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        addSubview(iconImageView)

        // ── Headline ──
        headlineLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        headlineLabel.textColor = .white
        headlineLabel.numberOfLines = 2
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headlineLabel)

        // ── Body ──
        bodyLabel.font = .systemFont(ofSize: 12)
        bodyLabel.textColor = UIColor(white: 0.55, alpha: 1.0)
        bodyLabel.numberOfLines = 3
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bodyLabel)

        // ── CTA button ──
        callToActionButton.translatesAutoresizingMaskIntoConstraints = false
        callToActionButton.backgroundColor = UIColor(red: 1.0, green: 0.55, blue: 0.1, alpha: 1.0)
        callToActionButton.setTitleColor(.black, for: .normal)
        callToActionButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        callToActionButton.layer.cornerRadius = 12
        callToActionButton.layer.masksToBounds = true
        callToActionButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 14, bottom: 5, right: 14)
        addSubview(callToActionButton)

        // MARK: - Constraints
        NSLayoutConstraint.activate([
            // AD badge (top-left, on top of media)
            adBadgeLabel.topAnchor.constraint(equalTo: media.topAnchor, constant: 6),
            adBadgeLabel.leadingAnchor.constraint(equalTo: media.leadingAnchor, constant: 6),

            // Media (left side, 4/7 width, equal margin all 4 sides)
            media.topAnchor.constraint(equalTo: topAnchor, constant: margin),
            media.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin),
            media.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -margin),
            media.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 4.0 / 7.0, constant: -(margin * 2 * 4.0 / 7.0)),

            // Icon (right side, top-left of right area)
            iconImageView.topAnchor.constraint(equalTo: media.topAnchor),
            iconImageView.leadingAnchor.constraint(equalTo: media.trailingAnchor, constant: 10),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),

            // Headline (right of icon, same top)
            headlineLabel.topAnchor.constraint(equalTo: iconImageView.topAnchor),
            headlineLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            headlineLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin),

            // Body (below headline)
            bodyLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 4),
            bodyLabel.leadingAnchor.constraint(equalTo: media.trailingAnchor, constant: 10),
            bodyLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin),

            // CTA button (bottom-right of right area)
            callToActionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin),
            callToActionButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -margin),
            callToActionButton.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    private func mapNativeAssets() {
        mediaView = media
        iconView = iconImageView
        headlineView = headlineLabel
        bodyView = bodyLabel
        callToActionView = callToActionButton
    }

    // MARK: - Helpers
    func applyPlaceholderForMissingIcon() {
        iconImageView.image = nil
        iconImageView.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
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
            .frame(height: 150)
            .padding(.horizontal, 20)
        Spacer()
    }
    .background(Color.black)
}
