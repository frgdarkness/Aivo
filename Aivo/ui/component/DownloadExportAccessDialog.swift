import SwiftUI

// MARK: - Download/Export Access Type
enum DownloadExportAction {
    case download
    case export

    var icon: String {
        switch self {
        case .download: return "arrow.down.circle.fill"
        case .export:   return "square.and.arrow.up.fill"
        }
    }

    var title: String {
        switch self {
        case .download: return "Download Song"
        case .export:   return "Export to Device"
        }
    }

    var subtitle: String {
        switch self {
        case .download: return "Download Song"
        case .export:   return "Export to Device"
        }
    }

    var description: String {
        switch self {
        case .download:
            return "Save this song to your device and listen offline anytime."
        case .export:
            return "Export this track as an audio file to share or use in your projects."
        }
    }

    var watchAdsLabel: String {
        switch self {
        case .download: return "Watch a short video"
        case .export:   return "Watch a short video"
        }
    }
}

// MARK: - DownloadExportAccessDialog
struct DownloadExportAccessDialog: View {
    let action: DownloadExportAction
    let onGoPremium: () -> Void
    let onWatchAds: () -> Void
    let onDismiss: () -> Void

    // Gold gradient colors
    private let goldStart = Color(red: 1.0, green: 0.82, blue: 0.28)
    private let goldEnd   = Color(red: 1.0, green: 0.52, blue: 0.05)

    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // Card
            VStack(spacing: 0) {
                headerSection
                descriptionSection
                optionsSection
                cancelSection
            }
            .frame(maxWidth: iPadScale(330))
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(white: 0.13),
                                Color(white: 0.09)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.18), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.55), radius: 32, x: 0, y: 12)
            .padding(.horizontal, 28)
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: iPadScaleSmall(12)) {
            // Icon badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [goldStart.opacity(0.18), goldEnd.opacity(0.06)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: iPadScale(68), height: iPadScale(68))
                    .overlay(
                        Circle()
                            .stroke(goldStart.opacity(0.35), lineWidth: 1.5)
                    )

                Image(systemName: action.icon)
                    .font(.system(size: iPadScale(30), weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [goldStart, goldEnd],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            Text(action.subtitle)
                .font(.system(size: iPadScale(18), weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .padding(.top, iPadScaleSmall(28))
        .padding(.horizontal, iPadScaleSmall(20))
    }

    // MARK: - Description
    private var descriptionSection: some View {
        Text(action.description)
            .font(.system(size: iPadScale(14)))
            .foregroundColor(.white.opacity(0.65))
            .lineSpacing(4)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, iPadScaleSmall(14))
            .padding(.horizontal, iPadScaleSmall(24))
    }

    // MARK: - Options
    private var optionsSection: some View {
        VStack(spacing: iPadScaleSmall(12)) {
            // Go Premium button (primary)
            Button(action: onGoPremium) {
                HStack(spacing: iPadScaleSmall(10)) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: iPadScale(16), weight: .semibold))
                        .foregroundColor(.black)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Go Premium")
                            .font(.system(size: iPadScale(15), weight: .bold))
                            .foregroundColor(.black)
                        Text("Unlimited downloads & exports")
                            .font(.system(size: iPadScale(11), weight: .medium))
                            .foregroundColor(.black.opacity(0.65))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: iPadScale(12), weight: .bold))
                        .foregroundColor(.black.opacity(0.6))
                }
                .padding(.horizontal, iPadScaleSmall(16))
                .frame(height: iPadScale(58))
                .background(
                    RoundedRectangle(cornerRadius: iPadScale(14))
                        .fill(
                            LinearGradient(
                                colors: [goldStart, goldEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: goldEnd.opacity(0.4), radius: 10, x: 0, y: 4)
            }

            // Watch Ads button (secondary)
            Button(action: onWatchAds) {
                HStack(spacing: iPadScaleSmall(10)) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: iPadScale(16), weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(action.watchAdsLabel)
                            .font(.system(size: iPadScale(15), weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                        Text("Watch 1 short ad — it's free")
                            .font(.system(size: iPadScale(11), weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: iPadScale(12), weight: .bold))
                        .foregroundColor(.white.opacity(0.35))
                }
                .padding(.horizontal, iPadScaleSmall(16))
                .frame(height: iPadScale(54))
                .background(
                    RoundedRectangle(cornerRadius: iPadScale(14))
                        .fill(Color.white.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: iPadScale(14))
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, iPadScaleSmall(20))
        .padding(.top, iPadScaleSmall(20))
    }

    // MARK: - Cancel
    private var cancelSection: some View {
        Button(action: onDismiss) {
            Text("Maybe later")
                .font(.system(size: iPadScale(14), weight: .medium))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.top, iPadScaleSmall(12))
        .padding(.bottom, iPadScaleSmall(22))
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        AivoSunsetBackground()
        DownloadExportAccessDialog(
            action: .download,
            onGoPremium: {},
            onWatchAds: {},
            onDismiss: {}
        )
    }
}
