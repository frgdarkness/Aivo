import SwiftUI
import StoreKit

// MARK: - Main Daily Gift Popup
struct DailyGiftPopup: View {
    @ObservedObject private var manager = DailyGiftManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var userDefaults = UserDefaultsManager.shared
    
    let onClose: () -> Void
    
    @State private var selectedDay: Int = 0
    @State private var showBonusMissions = false
    
    /// Check if any bonus mission is still available
    private var hasAvailableMissions: Bool {
        userDefaults.canWatchVideoForCredit(maxPerDay: 3)
        || !userDefaults.hasRatedForCredit
        || !manager.dailyShareClaimed
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerSection
            
            // 7-Day Grid
            dayGridSection
            
            // Description of selected day
            descriptionSection
            
            // Claim Button
            claimButtonSection
            
            // Bonus Missions Button
            bonusMissionsButton
        }
        .padding(24)
        .background(
            ZStack {
                Color.black.opacity(0.95)
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                AivoTheme.Primary.orange,
                                .orange.opacity(0.3),
                                .orange,
                                .white.opacity(0.5),
                                AivoTheme.Primary.orange
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
                    .shadow(color: AivoTheme.Primary.orange.opacity(0.5), radius: 10, x: 0, y: 0)
                    .shadow(color: AivoTheme.Primary.orange.opacity(0.3), radius: 20, x: 0, y: 0)
            }
        )
        .cornerRadius(24)
        .padding(.horizontal, 20)
        .onAppear {
            selectedDay = manager.todayDayNumber
        }
        .fullScreenCover(isPresented: $showBonusMissions) {
            BonusMissionsDialog(onClose: { showBonusMissions = false })
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            VStack(spacing: 8) {
                Text("Daily Gift Streak")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.white)
                
                Text("Claim rewards every day to maintain your streak!")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
            .padding(.bottom, 8) // More space between Text and Icon
            
            Image("icon_gift_yes")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88) // 10% increase from 80
                .shadow(color: AivoTheme.Primary.orange.opacity(0.8), radius: 15, x: 0, y: 0)
                .shadow(color: .yellow.opacity(0.6), radius: 25, x: 0, y: 0)
                .shadow(color: .orange.opacity(0.4), radius: 40, x: 0, y: 0)
        }
    }
    
    // MARK: - 7-Day Grid
    private var dayGridSection: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(1...7, id: \.self) { day in
                let reward = manager.dayRewards[day - 1]
                let isToday = day == manager.todayDayNumber
                let isClaimed = (day <= manager.currentStreak && !manager.canClaimToday())
                    || (day < manager.todayDayNumber && manager.canClaimToday())
                let isSelected = selectedDay == day && !isToday
                let hasVIP = reward.trialHours > 0
                
                DaySlotView(
                    day: day,
                    reward: reward,
                    isToday: isToday,
                    isClaimed: isClaimed,
                    isSelected: isSelected,
                    hasVIP: hasVIP
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedDay = day
                    }
                }
            }
        }
        .padding(.horizontal, 2)
    }
    
    // MARK: - Description
    private var descriptionSection: some View {
        Group {
            if selectedDay >= 1 && selectedDay <= 7 {
                let reward = manager.dayRewards[selectedDay - 1]
                let isToday = selectedDay == manager.todayDayNumber
                
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(isToday ? AivoTheme.Primary.orange : .white.opacity(0.35))
                    
                    Text(reward.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isToday ? .white.opacity(0.85) : .white.opacity(0.35))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.06))
                .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Claim Button
    private var claimButtonSection: some View {
        VStack(spacing: 8) {
            Button(action: handleClaim) {
                HStack(spacing: 12) {
                    if manager.canClaimToday() && !subscriptionManager.isUserPremium {
                        Image("icon_ads_white")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    } else if !manager.canClaimToday() {
                        Image("icon_next_day")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                    }
                    
                    Text(claimButtonText)
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    manager.canClaimToday()
                    ? LinearGradient(colors: [AivoTheme.Primary.orange, .red], startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(14)
                .shadow(color: manager.canClaimToday() ? AivoTheme.Primary.orange.opacity(0.3) : .clear, radius: 8, y: 4)
            }
            .disabled(!manager.canClaimToday())
            
            if !subscriptionManager.isUserPremium {
                Text("🔥 Premium users claim without ads!")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AivoTheme.Primary.orange.opacity(0.8))
            }
        }
    }
    
    private var claimButtonText: String {
        if !manager.canClaimToday() {
            return "Come Back Tomorrow"
        }
        return subscriptionManager.isUserPremium ? "Claim Reward 🎁" : "Watch Ad to Claim"
    }
    
    // MARK: - Bonus Missions Button (with notification badge)
    private var bonusMissionsButton: some View {
        VStack(spacing: 16) {
            // Divider with "Bonus" text
            HStack {
                Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
                Text("BONUS")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(.white.opacity(0.3))
                Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1)
            }
            .padding(.top, 4)
            
            Button(action: { showBonusMissions = true }) {
                HStack(spacing: 12) {
                    Image("icon_schedule")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.white)
                        .colorMultiply(.white)
                    
                    Text("Get More Free Credits")
                        .font(.system(size: 17, weight: .bold)) // Matched with Claim button
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(height: 54) // Overall height matched with Claim button
                .background(
                    LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.04)], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .overlay(alignment: .topTrailing) {
                // 🔴 Bell badge aligned to right edge
                if hasAvailableMissions {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 22, height: 22)
                        Image(systemName: "bell.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 4, y: -8) // Positioned where the chevron was
                }
            }
        }
    }
    
    // MARK: - Actions
    private func handleClaim() {
        if subscriptionManager.isUserPremium {
            manager.claim()
        } else {
            AdManager.shared.showRewardAd { success in
                if success { manager.claim() }
            }
        }
    }
}

// MARK: - Day Slot View
struct DaySlotView: View {
    let day: Int
    let reward: DailyGiftManager.DayReward
    let isToday: Bool
    let isClaimed: Bool
    let isSelected: Bool
    let hasVIP: Bool
    
    private var borderColor: Color {
        if isToday {
            return AivoTheme.Primary.orange
        } else if isSelected {
            return .white.opacity(0.5)
        } else if isClaimed {
            return .green.opacity(0.5)
        } else {
            return .white.opacity(0.1)
        }
    }
    
    private var bgColor: Color {
        if isToday {
            return AivoTheme.Primary.orange.opacity(0.15)
        } else {
            return .white.opacity(0.03)
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Day \(day)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(isToday ? AivoTheme.Primary.orange : .white.opacity(0.5))
            
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(bgColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: isToday ? 2 : 1)
                    )
                
                VStack(spacing: 2) {
                    if isClaimed {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 22))
                    } else if hasVIP {
                        // Line 1: credits + coin
                        HStack(spacing: 3) {
                            Text("+\(reward.credits)")
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(.white)
                            Image("icon_coin")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                        }
                        // Line 2: VIP + crown
                        HStack(spacing: 3) {
                            Text(reward.trialHours >= 24 ? "\(reward.trialHours/24)d VIP" : "\(reward.trialHours)h VIP")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundColor(.yellow)
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 10))
                        }
                    } else {
                        HStack(spacing: 3) {
                            Text("+\(reward.credits)")
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(.white)
                            Image("icon_coin")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(height: 60)
        }
    }
}

// MARK: - Bonus Missions Dialog (Separate full screen)
struct BonusMissionsDialog: View {
    @ObservedObject private var manager = DailyGiftManager.shared
    @ObservedObject private var userDefaults = UserDefaultsManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    let onClose: () -> Void
    
    private let maxVideoPerDay = 3
    private let videoRewardAmount = 5
    private let rateRewardAmount = 10
    private let shareRewardAmount = 20
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        Text("Get Free Credits")
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(8)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    
                    Text("Complete missions below to earn free credits!")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
                
                // Missions
                VStack(spacing: 12) {
                    // Watch Video
                    let videoRemaining = userDefaults.remainingVideoCreditViews(maxPerDay: maxVideoPerDay)
                    let videoEnabled = userDefaults.canWatchVideoForCredit(maxPerDay: maxVideoPerDay)
                    missionRow(
                        icon: "play.circle.fill",
                        iconColor: .blue,
                        title: "Watch a Video",
                        subtitle: videoEnabled ? "\(videoRemaining) left today" : "All used today",
                        reward: "+\(videoRewardAmount)",
                        badgeCount: videoEnabled ? videoRemaining : nil,
                        isEnabled: videoEnabled,
                        action: handleWatchVideo
                    )
                    
                    // Rate Us
                    let rateEnabled = !userDefaults.hasRatedForCredit
                    missionRow(
                        icon: "star.fill",
                        iconColor: .yellow,
                        title: "Rate Us",
                        subtitle: rateEnabled ? "One-time reward" : "Completed ✅",
                        reward: "+\(rateRewardAmount)",
                        badgeCount: nil,
                        isEnabled: rateEnabled,
                        action: handleRateApp
                    )
                    
                    // Share
                    let shareEnabled = !manager.dailyShareClaimed
                    missionRow(
                        icon: "square.and.arrow.up.fill",
                        iconColor: .green,
                        title: "Share with Friends",
                        subtitle: shareEnabled ? "Daily reward" : "Done today ✅",
                        reward: "+\(shareRewardAmount)",
                        badgeCount: nil,
                        isEnabled: shareEnabled,
                        action: handleShare
                    )
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Large Native Ad at bottom
                if !subscriptionManager.isPremium {
                    LargeNativeAdContainerView()
                        .frame(height: 320)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
            }
        }
    }
    
    // MARK: - Mission Row
    private func missionRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        reward: String,
        badgeCount: Int?,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: { if isEnabled { action() } }) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(iconColor)
                    .frame(width: 44, height: 44)
                    .background(iconColor.opacity(0.15))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                // Claim pill + badge
                ZStack(alignment: .topTrailing) {
                    HStack(spacing: 4) {
                        Text(reward)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        Image("icon_coin")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                    }
                    .frame(width: 85) // Sync width for all pills (+5, +10, +20)
                    .padding(.vertical, 8)
                    .background(isEnabled ? Color.blue : Color.gray.opacity(0.4))
                    .clipShape(Capsule())
                    
                    // Red badge with remaining count
                    if let count = badgeCount, count > 0 {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 20, height: 20)
                            Text("\(count)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: 8, y: -10)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.06))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
    
    // MARK: - Actions
    private func handleWatchVideo() {
        guard userDefaults.canWatchVideoForCredit(maxPerDay: maxVideoPerDay) else { return }
        AdManager.shared.showRewardAd { success in
            if success {
                userDefaults.markVideoCreditUsed()
                Task { await CreditManager.shared.increaseCredits(by: videoRewardAmount) }
            }
        }
    }
    
    private func handleRateApp() {
        guard !userDefaults.hasRatedForCredit else { return }
        userDefaults.hasRatedForCredit = true
        Task { await CreditManager.shared.increaseCredits(by: rateRewardAmount) }
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    private func handleShare() {
        let shareText = "Check out Aivo - AI Music Creator! Create amazing songs with AI 🎵\nhttps://apps.apple.com/app/id6754759511"
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        activityVC.completionWithItemsHandler = { _, completed, _, _ in
            if completed { manager.claimShareReward() }
        }
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            var topVC = rootVC
            while let presented = topVC.presentedViewController { topVC = presented }
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = topVC.view
                popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
            }
            topVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Overlay
struct DailyGiftPopupOverlay: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            if isPresented {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { isPresented = false }
                    }
                
                DailyGiftPopup(onClose: {
                    withAnimation { isPresented = false }
                })
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isPresented)
    }
}
