import SwiftUI

// MARK: - Premium Feature Type
enum PremiumFeatureType {
    case song
    case cover
    case lyric
    
    var hasFreeTrial: Bool {
        let profileManager = ProfileManager.shared
        let remoteConfig = RemoteConfigManager.shared
        guard remoteConfig.enableFreeFirstTime else { return false }
        
        switch self {
        case .song: return !profileManager.hasUsedFreeSongGeneration
        case .cover: return !profileManager.hasUsedFreeCoverGeneration
        case .lyric: return !profileManager.hasUsedFreeLyricGeneration
        }
    }
    
    // MARK: - Content when user HAS free trial
    var freeTrialTitle: String {
        switch self {
        case .song: return "Generate AI Song"
        case .cover: return "Create AI Cover"
        case .lyric: return "Generate AI Lyrics"
        }
    }
    
    var freeTrialBody: String {
        switch self {
        case .song:
            return "Turn your ideas into full songs with AI — lyrics, style, and vocals in seconds."
        case .cover:
            return "Transform any song with AI voice models to create unique covers! While unlimited creation is a Premium feature, we have a welcome gift to start your cover journey."
        case .lyric:
            return "Generate creative, professional lyrics for your songs with AI! While unlimited creation is a Premium feature, we have a welcome gift to start writing."
        }
    }
    
    var freeTrialHint: String {
        return "🎁 Your first trial is FREE. Watch a short video to generate your first masterpiece."
    }
    
    // MARK: - Content when user has USED free trial
    var usedTrialTitle: String {
        switch self {
        case .song: return "Ready for Next Hit?"
        case .cover: return "Ready for More Covers?"
        case .lyric: return "Ready for More Lyrics?"
        }
    }
    
    var usedTrialBullets: [String] {
        switch self {
        case .song:
            return [
                "Create AI songs with custom lyrics, styles, and vocals in seconds.",
                "Unlock Premium for unlimited creation",
                "Get 1,000 credits every week"
            ]
        case .cover:
            return [
                "Create AI covers with any voice model in seconds.",
                "Unlock Premium for unlimited creation",
                "Get 1,000 credits every week"
            ]
        case .lyric:
            return [
                "Generate professional AI lyrics for any mood or genre.",
                "Unlock Premium for unlimited creation",
                "Get 1,000 credits every week"
            ]
        }
    }
    
    var usedTrialHint: String {
        return "💡 Don't forget: You can checkin every day to earn free credits and get Premium trial (Day 4 & Day 7)."
    }
}

// MARK: - Premium Feature Dialog
struct PremiumFeatureDialog: View {
    let featureType: PremiumFeatureType
    let onGoPremium: () -> Void
    let onTryFree: () -> Void
    let onDismiss: () -> Void
    var onCheckDailyGift: (() -> Void)? = nil
    
    private var hasFree: Bool { featureType.hasFreeTrial }
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            
            // Dialog card
            VStack(alignment: .leading, spacing: 0) {
                // Header
                headerSection
                
                // Body text
                bodySection
                
                // Hint box
                hintSection
                
                // Buttons
                buttonsSection
            }
            .frame(maxWidth: iPadScale(320))
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(white: 0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 10)
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack(spacing: iPadScaleSmall(12)) {
            Image(systemName: hasFree ? "music.note.list" : "crown.fill")
                .font(.system(size: iPadScale(30)))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.75, blue: 0.1),
                            Color(red: 1.0, green: 0.5, blue: 0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(hasFree ? featureType.freeTrialTitle : featureType.usedTrialTitle)
                    .font(.system(size: iPadScale(19), weight: .bold))
                    .foregroundColor(.white)
                
                Text("Premium Access")
                    .font(.system(size: iPadScale(13), weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
        }
        .padding(.top, iPadScaleSmall(24))
        .padding(.horizontal, iPadScaleSmall(20))
    }
    
    // MARK: - Body
    private var bodySection: some View {
        Group {
            if hasFree {
                Text(featureType.freeTrialBody)
                    .font(.system(size: iPadScale(14)))
                    .foregroundColor(.white.opacity(0.75))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(alignment: .leading, spacing: iPadScaleSmall(8)) {
                    ForEach(featureType.usedTrialBullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .font(.system(size: iPadScale(14), weight: .bold))
                                .foregroundColor(AivoTheme.Primary.orange)
                            Text(bullet)
                                .font(.system(size: iPadScale(14)))
                                .foregroundColor(.white.opacity(0.75))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(.top, iPadScaleSmall(14))
        .padding(.horizontal, iPadScaleSmall(20))
    }
    
    // MARK: - Hint
    private var hintSection: some View {
        Group {
            if hasFree {
                // Orange/gold hint for free trial
                Text(featureType.freeTrialHint)
                    .font(.system(size: iPadScale(13), weight: .semibold))
                    .foregroundColor(Color(red: 1.0, green: 0.75, blue: 0.1))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(iPadScaleSmall(12))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 1.0, green: 0.75, blue: 0.1).opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 1.0, green: 0.75, blue: 0.1).opacity(0.2), lineWidth: 1)
                    )
            } else {
                // Subtle hint for daily gift
                Text(featureType.usedTrialHint)
                    .font(.system(size: iPadScale(13)))
                    .foregroundColor(.white.opacity(0.6))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(iPadScaleSmall(12))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.05))
                    )
            }
        }
        .padding(.top, iPadScaleSmall(14))
        .padding(.horizontal, iPadScaleSmall(20))
    }
    
    // MARK: - Buttons
    private var buttonsSection: some View {
        VStack(spacing: iPadScaleSmall(10)) {
            if hasFree {
                // === Free trial state ===
                HStack(spacing: iPadScaleSmall(12)) {
                    // Try Free
                    Button(action: onTryFree) {
                        HStack(spacing: 6) {
                            Text("Create Free")
                                .font(.system(size: iPadScale(15), weight: .semibold))
                            //Image("icon_ads")
                            //    .renderingMode(.template)
                            //    .resizable()
                            //    .scaledToFit()
                            //    .frame(width: iPadScale(22), height: iPadScale(22))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: iPadScale(44))
                        .background(
                            RoundedRectangle(cornerRadius: iPadScale(10))
                                .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                        )
                    }
                    
                    // Go Premium
                    Button(action: onGoPremium) {
                        Text("Go Premium")
                            .font(.system(size: iPadScale(15), weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: iPadScale(44))
                            .background(
                                RoundedRectangle(cornerRadius: iPadScale(10))
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 1.0, green: 0.75, blue: 0.1),
                                                Color(red: 1.0, green: 0.5, blue: 0.0)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                }
            } else {
                // === Used trial state ===
                // Unlock Premium Now (full width)
                Button(action: onGoPremium) {
                    Text("Unlock Premium")
                        .font(.system(size: iPadScale(15), weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: iPadScale(44))
                        .background(
                            RoundedRectangle(cornerRadius: iPadScale(10))
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.75, blue: 0.1),
                                            Color(red: 1.0, green: 0.5, blue: 0.0)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                
                // Check Daily Gift
                Button(action: {
                    if let onCheckDailyGift = onCheckDailyGift {
                        onCheckDailyGift()
                    } else {
                        onDismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default.post(
                                name: NSNotification.Name("ShowDailyGiftPopup"),
                                object: nil
                            )
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        Image("icon_gift_yes")
                            .resizable()
                            .scaledToFit()
                            .frame(width: iPadScale(20), height: iPadScale(20))
                        
                        Text("Get Free Credits")
                            .font(.system(size: iPadScale(14), weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .frame(height: iPadScale(38))
                    .background(
                        RoundedRectangle(cornerRadius: iPadScale(10))
                            .fill(Color.white.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: iPadScale(10))
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                }
            }
        }
        .padding(.horizontal, iPadScaleSmall(20))
        .padding(.top, iPadScaleSmall(20))
        .padding(.bottom, iPadScaleSmall(24))
    }
}

// MARK: - Insufficient Credits Dialog (for Premium users)
struct InsufficientCreditsDialog: View {
    let creditsRequired: Int
    let creditsAvailable: Int
    let featureType: PremiumFeatureType
    let onBuyCredits: () -> Void
    let onDismiss: () -> Void
    
    private var featureAction: String {
        switch featureType {
        case .song: return "AI songs"
        case .cover: return "AI covers"
        case .lyric: return "AI lyrics"
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: iPadScaleSmall(12)) {
                    Image("icon_coin_512")
                        .resizable()
                        .scaledToFit()
                        .frame(width: iPadScale(36), height: iPadScale(36))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("You're out of credits")
                            .font(.system(size: iPadScale(19), weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Need \(creditsRequired) credits to continue")
                            .font(.system(size: iPadScale(13), weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                }
                .padding(.top, iPadScaleSmall(24))
                .padding(.horizontal, iPadScaleSmall(20))
                
                // Body
                Text("Top up credits to keep creating your \(featureAction). Don't forget checkin every day to earn free credits!")
                    .font(.system(size: iPadScale(14)))
                    .foregroundColor(.white.opacity(0.75))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, iPadScaleSmall(14))
                    .padding(.horizontal, iPadScaleSmall(20))
                
                // Buttons
                VStack(spacing: iPadScaleSmall(10)) {
                    // Buy Credits
                    Button(action: onBuyCredits) {
                        Text("Buy Credits")
                            .font(.system(size: iPadScale(15), weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: iPadScale(44))
                            .background(
                                RoundedRectangle(cornerRadius: iPadScale(10))
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 1.0, green: 0.75, blue: 0.1),
                                                Color(red: 1.0, green: 0.5, blue: 0.0)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                    
                    // Get Free Credits
                    Button(action: {
                        onDismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default.post(
                                name: NSNotification.Name("ShowDailyGiftPopup"),
                                object: nil
                            )
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image("icon_gift_yes")
                                .resizable()
                                .scaledToFit()
                                .frame(width: iPadScale(20), height: iPadScale(20))
                            
                            Text("Get Free Credits")
                                .font(.system(size: iPadScale(14), weight: .semibold))
                        }
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .frame(height: iPadScale(38))
                        .background(
                            RoundedRectangle(cornerRadius: iPadScale(10))
                                .fill(Color.white.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: iPadScale(10))
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, iPadScaleSmall(20))
                .padding(.top, iPadScaleSmall(20))
                .padding(.bottom, iPadScaleSmall(24))
            }
            .frame(maxWidth: iPadScale(320))
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(white: 0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 10)
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        AivoSunsetBackground()
        PremiumFeatureDialog(
            featureType: .song,
            onGoPremium: {},
            onTryFree: {},
            onDismiss: {}
        )
    }
}
