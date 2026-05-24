import SwiftUI
import GoogleMobileAds
import Combine

/// SwiftUI wrapper for a native ad that renders at the bottom of screens.
/// Style: compact banner-like native ad with icon, headline, body, media view, and CTA button.
struct BasicNativeAdView: View {
    @StateObject private var viewModel = NativeAdViewModel()
    var isCtaButtonOntop: Bool = false
    var isIntroMode: Bool = false
    var topPadding: CGFloat = 16
    var reloadTrigger: Int? = nil
    
    private let adBgColor = Color(red: 31/255, green: 34/255, blue: 37/255) // #1F2225
    
    var body: some View {
        VStack(spacing: 0) {
            if let nativeAd = viewModel.nativeAd {
                NativeAdContentView(nativeAd: nativeAd, isCtaButtonOntop: isCtaButtonOntop, isIntroMode: isIntroMode)
                    .frame(height: isIntroMode ? 260 : 272)
                    .background(adBgColor)
                    .cornerRadius(isIntroMode ? 0 : 20)
            } else {
                ShimmerAdView(isCtaButtonOntop: isCtaButtonOntop, isIntroMode: isIntroMode)
                    .frame(height: isIntroMode ? 260 : 272)
                    .background(adBgColor)
                    .cornerRadius(isIntroMode ? 0 : 20)
            }
        }
        .padding(.top, isIntroMode ? 0 : topPadding)
        .background(isIntroMode ? adBgColor.ignoresSafeArea(edges: .bottom) : Color.clear.ignoresSafeArea())
        .onChange(of: reloadTrigger) { _ in
            Task { @MainActor in
                viewModel.loadAd()
            }
        }
    }
}

// MARK: - ViewModel
class NativeAdViewModel: ObservableObject {
    @Published var nativeAd: GADNativeAd?
    
    init() {
        Task { @MainActor in
            loadAd()
        }
    }
    
    @MainActor
    func loadAd(retry: Bool = true) {
        AdManager.shared.getNativeAd { [weak self] ad in
            DispatchQueue.main.async {
                if let ad = ad {
                    self?.nativeAd = ad
                } else if retry {
                    AdManager.shared.preloadNative { _ in
                        Task { @MainActor [weak self] in
                            self?.loadAd(retry: false)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Shimmer Placeholder
struct ShimmerAdView: View {
    var isCtaButtonOntop: Bool = false
    var isIntroMode: Bool = false
    @State private var isAnimating = false
    
    private let adBgColor = Color(red: 31/255, green: 34/255, blue: 37/255) // #1F2225
    private let shimmerColor = Color.gray.opacity(0.3)
    
    var body: some View {
        VStack(spacing: 12) {
            if isCtaButtonOntop {
                // CTA Button
                RoundedRectangle(cornerRadius: 8)
                    .fill(shimmerColor)
                    .frame(height: 44)
                
                // Media View
                RoundedRectangle(cornerRadius: 8)
                    .fill(shimmerColor)
                    .frame(height: 130)
                
                // Top Row
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(shimmerColor)
                        .frame(width: 48, height: 48)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(shimmerColor)
                            .frame(height: 14)
                            .frame(maxWidth: 150)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(shimmerColor)
                            .frame(height: 12)
                    }
                    Spacer()
                }
            } else {
                // Top Row
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(shimmerColor)
                        .frame(width: 48, height: 48)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(shimmerColor)
                            .frame(height: 14)
                            .frame(maxWidth: 150)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(shimmerColor)
                            .frame(height: 12)
                    }
                    Spacer()
                }
                
                // Media View
                RoundedRectangle(cornerRadius: 8)
                    .fill(shimmerColor)
                    .frame(height: 130)
                
                // CTA Button
                RoundedRectangle(cornerRadius: 8)
                    .fill(shimmerColor)
                    .frame(height: 44)
            }
        }
        .padding(.top, 12)
        .padding(.horizontal, 12)
        .padding(.bottom, isIntroMode ? 0 : 12)
        .overlay(
            GeometryReader { geometry in
                LinearGradient(
                    gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.2), Color.clear]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(20))
                .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
                .animation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
            }
        )
        .mask(Rectangle())
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - UIKit Bridge for NativeAdView
struct NativeAdContentView: UIViewRepresentable {
    let nativeAd: GADNativeAd
    var isCtaButtonOntop: Bool = false
    var isIntroMode: Bool = false
    
    func makeUIView(context: Context) -> NativeAdView {
        let adView = NativeAdView()
        adView.backgroundColor = .clear // Handled by SwiftUI
        
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 12
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.isLayoutMarginsRelativeArrangement = true
        
        let bottomPadding: CGFloat = isIntroMode ? 0 : 12
        mainStack.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: bottomPadding, right: 12)
        
        // Top Row: Icon + Texts
        let topStack = UIStackView()
        topStack.axis = .horizontal
        topStack.spacing = 10
        topStack.alignment = .center
        
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFill
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 8
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        iconView.setContentHuggingPriority(.required, for: .vertical)
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.setContentCompressionResistancePriority(.required, for: .vertical)
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 48),
            iconView.heightAnchor.constraint(equalTo: iconView.widthAnchor)
        ])
        
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 2
        
        let headlineStack = UIStackView()
        headlineStack.axis = .horizontal
        headlineStack.spacing = 6
        headlineStack.alignment = .center
        
        let adBadge = UILabel()
        adBadge.text = "Ad"
        adBadge.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        adBadge.textColor = .white
        adBadge.backgroundColor = UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0) // fallback blue
        adBadge.textAlignment = .center
        adBadge.layer.cornerRadius = 3
        adBadge.clipsToBounds = true
        adBadge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            adBadge.widthAnchor.constraint(equalToConstant: 20),
            adBadge.heightAnchor.constraint(equalToConstant: 14)
        ])
        
        let headlineLabel = UILabel()
        headlineLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        headlineLabel.textColor = .white
        headlineLabel.numberOfLines = 1
        
        headlineStack.addArrangedSubview(adBadge)
        headlineStack.addArrangedSubview(headlineLabel)
        
        let bodyLabel = UILabel()
        bodyLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        bodyLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        bodyLabel.numberOfLines = 2
        bodyLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        textStack.addArrangedSubview(headlineStack)
        textStack.addArrangedSubview(bodyLabel)
        
        topStack.addArrangedSubview(iconView)
        topStack.addArrangedSubview(textStack)
        
        // Media View
        let mediaView = MediaView()
        mediaView.backgroundColor = .black // Keep black background for whole mediaView frame
        mediaView.layer.cornerRadius = 8
        mediaView.clipsToBounds = true
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mediaView.heightAnchor.constraint(equalToConstant: 130)
        ])
        
        // CTA Button
        let ctaButton = UIButton(type: .system)
        ctaButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        ctaButton.setTitleColor(.white, for: .normal)
        ctaButton.backgroundColor = UIColor(red: 0.7, green: 0.3, blue: 1.0, alpha: 1.0) // fallback purple
        ctaButton.layer.cornerRadius = 8
        ctaButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        ctaButton.isUserInteractionEnabled = false // AdView handles taps
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ctaButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        if isCtaButtonOntop {
            mainStack.addArrangedSubview(ctaButton)
            mainStack.addArrangedSubview(mediaView)
            mainStack.addArrangedSubview(topStack)
        } else {
            mainStack.addArrangedSubview(topStack)
            mainStack.addArrangedSubview(mediaView)
            mainStack.addArrangedSubview(ctaButton)
        }
        
        adView.addSubview(mainStack)
        
        // Zero padding because padding is handled by SwiftUI outer wrapper
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: adView.topAnchor),
            mainStack.bottomAnchor.constraint(equalTo: adView.bottomAnchor),
            mainStack.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: adView.trailingAnchor)
        ])
        
        // Assign subviews
        adView.iconView = iconView
        adView.headlineView = headlineLabel
        adView.bodyView = bodyLabel
        adView.mediaView = mediaView
        adView.callToActionView = ctaButton
        
        return adView
    }
    
    func updateUIView(_ adView: NativeAdView, context: Context) {
        adView.nativeAd = nativeAd
        
        (adView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        (adView.headlineView as? UILabel)?.text = nativeAd.headline
        (adView.bodyView as? UILabel)?.text = nativeAd.body
        (adView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction ?? "Install", for: .normal)
        
        if let mediaView = adView.mediaView {
            mediaView.mediaContent = nativeAd.mediaContent
        }
    }
}
