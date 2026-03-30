import SwiftUI
import GoogleMobileAds

// Use namespace to avoid naming conflicts
typealias GADNativeAdView = GoogleMobileAds.NativeAdView

import UIKit
import GoogleMobileAds

// MARK: - Horizontal Card Native Ad
// Layout:
// ┌──────────────────────────────────────────────┐
// │ ┌──────────────────────┐  ┌────────────────┐ │
// │ │ 🔸 Icon              │  │            AD  │ │
// │ │ Headline text...     │  │   MediaView    │ │
// │ │ Body description...  │  │   (4/7 width)  │ │
// │ │ [CTA Button]         │  │                │ │
// │ └──────────────────────┘  └────────────────┘ │
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
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        let scale: CGFloat = isIPad ? 1.4 : 1.0
        let m = margin * (isIPad ? 1.3 : 1.0) // scaled margin
        
        backgroundColor = UIColor(white: 0.08, alpha: 1.0)
        layer.cornerRadius = 12 * (isIPad ? 1.2 : 1.0)
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.15).cgColor
        clipsToBounds = true

        // ── MediaView (right 4/7) ──
        media.translatesAutoresizingMaskIntoConstraints = false
        media.backgroundColor = UIColor.black
        media.layer.cornerRadius = 8 * (isIPad ? 1.2 : 1.0)
        media.layer.masksToBounds = true
        media.contentMode = .scaleAspectFill
        addSubview(media)

        // ── AD badge (top-right, overlaying media — custom label, not native asset) ──
        adBadgeLabel.text = " AD "
        adBadgeLabel.font = .systemFont(ofSize: 9 * scale, weight: .bold)
        adBadgeLabel.textColor = .black
        adBadgeLabel.backgroundColor = UIColor(red: 1.0, green: 0.75, blue: 0.1, alpha: 1.0)
        adBadgeLabel.textAlignment = .center
        adBadgeLabel.layer.cornerRadius = 2 * scale
        adBadgeLabel.layer.masksToBounds = true
        adBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(adBadgeLabel)

        // ── Icon (left side, top) ──
        let iconSize: CGFloat = isIPad ? 44 : 32
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.layer.cornerRadius = 6 * (isIPad ? 1.2 : 1.0)
        iconImageView.layer.masksToBounds = true
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        addSubview(iconImageView)

        // ── Headline ──
        headlineLabel.font = .systemFont(ofSize: 14 * scale, weight: .semibold)
        headlineLabel.textColor = .white
        headlineLabel.numberOfLines = 2
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headlineLabel)

        // ── Body ──
        bodyLabel.font = .systemFont(ofSize: 12 * scale)
        bodyLabel.textColor = UIColor(white: 0.55, alpha: 1.0)
        bodyLabel.numberOfLines = 3
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bodyLabel)

        // ── CTA button ──
        let ctaHeight: CGFloat = isIPad ? 34 : 24
        callToActionButton.translatesAutoresizingMaskIntoConstraints = false
        callToActionButton.backgroundColor = UIColor(red: 1.0, green: 0.55, blue: 0.1, alpha: 1.0)
        callToActionButton.setTitleColor(.black, for: .normal)
        callToActionButton.titleLabel?.font = .systemFont(ofSize: 12 * scale, weight: .bold)
        callToActionButton.layer.cornerRadius = ctaHeight / 2
        callToActionButton.layer.masksToBounds = true
        let ctaPadH: CGFloat = isIPad ? 20 : 14
        callToActionButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: ctaPadH, bottom: 5, right: ctaPadH)
        addSubview(callToActionButton)

        let gap: CGFloat = isIPad ? 14 : 10

        // MARK: - Constraints
        NSLayoutConstraint.activate([
            // Media (right side, 4/7 width, equal margin all 4 sides)
            media.topAnchor.constraint(equalTo: topAnchor, constant: m),
            media.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -m),
            media.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -m),
            media.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 4.0 / 7.0, constant: -(m * 2 * 4.0 / 7.0)),

            // AD badge (top-right, on top of media)
            adBadgeLabel.topAnchor.constraint(equalTo: media.topAnchor, constant: 6),
            adBadgeLabel.trailingAnchor.constraint(equalTo: media.trailingAnchor, constant: -6),

            // Icon (left side, top-left of left area)
            iconImageView.topAnchor.constraint(equalTo: media.topAnchor),
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: m),
            iconImageView.widthAnchor.constraint(equalToConstant: iconSize),
            iconImageView.heightAnchor.constraint(equalToConstant: iconSize),

            // Headline (right of icon, same top)
            headlineLabel.topAnchor.constraint(equalTo: iconImageView.topAnchor),
            headlineLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            headlineLabel.trailingAnchor.constraint(equalTo: media.leadingAnchor, constant: -gap),

            // Body (below icon, full width of left area)
            bodyLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 6),
            bodyLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: m),
            bodyLabel.trailingAnchor.constraint(equalTo: media.leadingAnchor, constant: -gap),

            // CTA button (bottom-left of left area)
            callToActionButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: m),
            callToActionButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -m),
            callToActionButton.heightAnchor.constraint(equalToConstant: ctaHeight),
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

// MARK: - Large Vertical Native Ad
// Layout:
// ┌──────────────────────────────────────────────┐
// │  🔸 Icon  [AD] Title headline...             │
// │                Body description...            │
// │ ┌────────────────────────────────────────────┐│
// │ │                                            ││
// │ │            MediaView (full width)          ││
// │ │                                            ││
// │ └────────────────────────────────────────────┘│
// │ [          CTA Button (full width)          ] │
// └──────────────────────────────────────────────┘
final class LargeNativeAdUIView: GADNativeAdView {
    // MARK: - Subviews
    private let iconImageView = UIImageView()
    private let adBadgeLabel = UILabel()
    private let headlineLabel = UILabel()
    private let bodyLabel = UILabel()
    private let media = GoogleMobileAds.MediaView()
    private let callToActionButton = UIButton(type: .system)
    // Stack to center title+body vertically against icon
    private let textStack = UIStackView()
    // HStack for AD badge + headline
    private let titleRow = UIStackView()
    
    private let margin: CGFloat = 12

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

    private func setupUI() {
        let m = margin
        
        backgroundColor = UIColor(white: 0.08, alpha: 1.0)
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = UIColor(white: 0.2, alpha: 1.0).cgColor
        clipsToBounds = true

        // ── Icon ──
        let iconSize: CGFloat = 40
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.layer.cornerRadius = 8
        iconImageView.layer.masksToBounds = true
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        addSubview(iconImageView)

        // ── AD badge (left of title) ──
        adBadgeLabel.text = " AD "
        adBadgeLabel.font = .systemFont(ofSize: 11, weight: .bold)
        adBadgeLabel.textColor = .black
        adBadgeLabel.backgroundColor = UIColor(red: 1.0, green: 0.75, blue: 0.1, alpha: 1.0)
        adBadgeLabel.textAlignment = .center
        adBadgeLabel.layer.cornerRadius = 3
        adBadgeLabel.layer.masksToBounds = true
        adBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        adBadgeLabel.setContentHuggingPriority(.required, for: .horizontal)
        adBadgeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        // ── Headline ──
        headlineLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        headlineLabel.textColor = .white
        headlineLabel.numberOfLines = 1
        headlineLabel.lineBreakMode = .byTruncatingTail
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false

        // ── Title row: [AD badge] [Headline] ──
        titleRow.axis = .horizontal
        titleRow.spacing = 6
        titleRow.alignment = .center
        titleRow.translatesAutoresizingMaskIntoConstraints = false
        titleRow.addArrangedSubview(adBadgeLabel)
        titleRow.addArrangedSubview(headlineLabel)

        // ── Body ──
        bodyLabel.font = .systemFont(ofSize: 13)
        bodyLabel.textColor = UIColor(white: 0.55, alpha: 1.0)
        bodyLabel.numberOfLines = 1
        bodyLabel.lineBreakMode = .byTruncatingTail
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false

        // ── Text stack (title row + body), centered vertically ──
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.addArrangedSubview(titleRow)
        textStack.addArrangedSubview(bodyLabel)
        addSubview(textStack)

        // ── MediaView (full width, center) ──
        media.translatesAutoresizingMaskIntoConstraints = false
        media.backgroundColor = .black
        media.layer.cornerRadius = 10
        media.layer.masksToBounds = true
        media.contentMode = .scaleAspectFill
        addSubview(media)

        // ── CTA button (full width, bottom) ──
        let ctaHeight: CGFloat = 40
        callToActionButton.translatesAutoresizingMaskIntoConstraints = false
        callToActionButton.backgroundColor = UIColor(red: 1.0, green: 0.55, blue: 0.1, alpha: 1.0)
        callToActionButton.setTitleColor(.black, for: .normal)
        callToActionButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        callToActionButton.layer.cornerRadius = ctaHeight / 2
        callToActionButton.layer.masksToBounds = true
        callToActionButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        addSubview(callToActionButton)

        // MARK: - Constraints
        NSLayoutConstraint.activate([
            // Icon (top-left)
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: m),
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: m),
            iconImageView.widthAnchor.constraint(equalToConstant: iconSize),
            iconImageView.heightAnchor.constraint(equalToConstant: iconSize),

            // AD badge height
            adBadgeLabel.heightAnchor.constraint(equalToConstant: 18),

            // Text stack (centered vertically relative to icon)
            textStack.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
            textStack.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 10),
            textStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -m),

            // MediaView (full width, below header section)
            media.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 10),
            media.leadingAnchor.constraint(equalTo: leadingAnchor, constant: m),
            media.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -m),
            media.bottomAnchor.constraint(equalTo: callToActionButton.topAnchor, constant: -10),

            // CTA button (full width, bottom)
            callToActionButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: m),
            callToActionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -m),
            callToActionButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -m),
            callToActionButton.heightAnchor.constraint(equalToConstant: ctaHeight),
        ])
    }

    private func mapNativeAssets() {
        mediaView = media
        iconView = iconImageView
        headlineView = headlineLabel
        bodyView = bodyLabel
        callToActionView = callToActionButton
    }

    func applyPlaceholderForMissingIcon() {
        iconImageView.image = nil
        iconImageView.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
    }

    func clearIconBackgroundIfNeeded() {
        iconImageView.backgroundColor = .clear
        iconImageView.contentMode = .scaleAspectFill
    }
}

// MARK: - SwiftUI Container (Large)
struct LargeNativeAdContainerView: UIViewRepresentable {
    func makeUIView(context: Context) -> LargeNativeAdUIView {
        let view = LargeNativeAdUIView()
        AdManager.shared.getNativeAd { ad in
            guard let ad = ad else {
                Logger.w("LargeNativeAdContainerView: no native ad available")
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

    func updateUIView(_ uiView: LargeNativeAdUIView, context: Context) {}
}
