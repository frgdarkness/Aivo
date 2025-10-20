import SwiftUI
import GoogleMobileAds

// Use namespace to avoid naming conflicts
typealias GADNativeAdView = GoogleMobileAds.NativeAdView
// GADNativeAd đã được định nghĩa trong AdManager.swift

// Native ad renderer: headline + icon + media + body + ad badge
import UIKit
import GoogleMobileAds

final class RichNativeAdUIView: GADNativeAdView {
    // MARK: - Subviews
    private let topLine = UIView()
    private let iconImageView = UIImageView()
    private let adBadgeLabel = UILabel()
    private let headlineLabel = UILabel()
    private let bodyLabel = UILabel()
    private let media = GoogleMobileAds.MediaView()
    private let callToActionButton = UIButton(type: .system)

    // Config
    private let paddingH: CGFloat = 8
    private let paddingV: CGFloat = 4

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

    // MARK: - UI
    private func setupUI() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 8
        clipsToBounds = true

        // Top separator (only top)
        topLine.backgroundColor = UIColor(white: 0.92, alpha: 1.0)
        topLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topLine)
        NSLayoutConstraint.activate([
            topLine.topAnchor.constraint(equalTo: topAnchor),
            topLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            topLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            topLine.heightAnchor.constraint(equalToConstant: 1)
        ])

        // Icon (left)
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.layer.cornerRadius = 6
        iconImageView.layer.masksToBounds = true
        iconImageView.contentMode = .scaleAspectFill
        addSubview(iconImageView)
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: paddingH),
            iconImageView.topAnchor.constraint(equalTo: topLine.bottomAnchor, constant: paddingV),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40)
        ])

        // AD badge
        adBadgeLabel.text = "AD"
        adBadgeLabel.font = .systemFont(ofSize: 10, weight: .bold)
        adBadgeLabel.textColor = .white
        adBadgeLabel.backgroundColor = UIColor(red: 1, green: 0.8, blue: 0, alpha: 1)
        adBadgeLabel.textAlignment = .center
        adBadgeLabel.layer.cornerRadius = 3
        adBadgeLabel.layer.masksToBounds = true
        adBadgeLabel.setContentHuggingPriority(.required, for: .horizontal)
        adBadgeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Headline (max 1 line)
        headlineLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        headlineLabel.numberOfLines = 1
        headlineLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // Title row: [AD][Headline]
        let titleRow = UIStackView(arrangedSubviews: [adBadgeLabel, headlineLabel])
        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = 6

        // Body (max 1 line)
        bodyLabel.font = .systemFont(ofSize: 12)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 1

        // Right stack (to the right of icon): titleRow then body
        let rightTextStack = UIStackView(arrangedSubviews: [titleRow, bodyLabel])
        rightTextStack.axis = .vertical
        rightTextStack.alignment = .fill
        rightTextStack.spacing = 4
        rightTextStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rightTextStack)

        NSLayoutConstraint.activate([
            rightTextStack.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            rightTextStack.topAnchor.constraint(equalTo: iconImageView.topAnchor),
            rightTextStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -paddingH)
        ])

        // Media view (fixed height 180)
        media.translatesAutoresizingMaskIntoConstraints = false
        media.backgroundColor = UIColor.systemGray6
        addSubview(media)
        NSLayoutConstraint.activate([
            media.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            media.leadingAnchor.constraint(equalTo: leadingAnchor, constant: paddingH),
            media.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -paddingH),
            media.heightAnchor.constraint(equalToConstant: 180)
        ])

        // CTA button (reduced height 44)
        callToActionButton.translatesAutoresizingMaskIntoConstraints = false
        callToActionButton.backgroundColor = .systemBlue
        callToActionButton.setTitleColor(.white, for: .normal)
        callToActionButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        callToActionButton.layer.cornerRadius = 8
        callToActionButton.layer.masksToBounds = true
        addSubview(callToActionButton)
        NSLayoutConstraint.activate([
            callToActionButton.topAnchor.constraint(equalTo: media.bottomAnchor, constant: 8),
            callToActionButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: paddingH),
            callToActionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -paddingH),
            callToActionButton.heightAnchor.constraint(equalToConstant: 44),
            callToActionButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -paddingV)
        ])
    }

    private func mapNativeAssets() {
        mediaView = media
        iconView = iconImageView
        headlineView = headlineLabel
        bodyView = bodyLabel
        callToActionView = callToActionButton
        // adBadgeView không có sẵn trong iOS SDK; giữ label thủ công
    }

    // MARK: - Public bind helper (optional)
    func applyPlaceholderForMissingIcon() {
        // nếu không có icon, giữ kích thước & nền xám nhạt
        iconImageView.image = nil
        iconImageView.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        iconImageView.isHidden = false
        iconImageView.contentMode = .center
    }

    func clearIconBackgroundIfNeeded() {
        iconImageView.backgroundColor = .clear
        iconImageView.contentMode = .scaleAspectFill
    }
}

struct NativeAdContainerView: UIViewRepresentable {
    func makeUIView(context: Context) -> RichNativeAdUIView {
        let view = RichNativeAdUIView()
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

    func updateUIView(_ uiView: RichNativeAdUIView, context: Context) {}
}

#Preview {
    NativeAdContainerView()
        .frame(height: 320)
        .background(Color(UIColor.systemGray6))
}

