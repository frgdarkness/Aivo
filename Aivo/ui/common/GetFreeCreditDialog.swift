//
//  GetFreeCreditDialog 2.swift
//  DreamHomeAI
//
//  Created by Huy on 10/10/25.
//


import SwiftUI
import StoreKit

struct GetFreeCreditDialog: View {
    @ObservedObject private var creditManager = CreditManager.shared
    @ObservedObject private var userDefaults = UserDefaultsManager.shared
    
    let onClose: () -> Void
    
    // NEW: Toast state
    @State private var toast: SimpleToast?
    
    // Config cố định
    private let dailyRewardAmount: Int = 5
    private let videoRewardAmount: Int = 5
    private let rateRewardAmount: Int = 10
    private let maxVideoPerDay: Int = 3
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Get Free Credit")
                    .font(.title3).bold()
                    .foregroundColor(.white)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(8)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            
            Text("Complete the actions below to earn free credits.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
            
            // Action list
            VStack(spacing: 14) {
                actionRow(
                    icon: Image("icon_gift_box"),
                    title: "Daily Gift",
                    rightText: "+\(dailyRewardAmount)",
                    rightEnabled: userDefaults.canClaimDailyReward(),
                    onTap: handleDailyReward
                )
                
                actionRow(
                    icon: Image("icon_watch_ads"),
                    title: "Watch a Video",
                    rightText: "+\(videoRewardAmount)",
                    rightEnabled: userDefaults.canWatchVideoForCredit(maxPerDay: maxVideoPerDay),
                    badgeCount: userDefaults.remainingVideoCreditViews(maxPerDay: maxVideoPerDay),
                    onTap: handleWatchVideo
                )
                
                actionRow(
                    icon: Image("icon_star_cool"),
                    title: "Rate Us",
                    rightText: "+\(rateRewardAmount)",
                    rightEnabled: !userDefaults.hasRatedForCredit,
                    onTap: handleRateApp
                )
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.95), Color.black.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.45), radius: 18, x: 0, y: 8)
        .padding(.horizontal, 28)
        .onAppear {
            userDefaults.resetDailyFreeCreditStatesIfNeeded()
        }
        .simpleToast($toast)
    }
    
    // MARK: - Toast helper
    private func showRewardToast(_ amount: Int, prefix: String = "rewarded") {
        toast = SimpleToast(
            message: "\(prefix) \(amount) credits",
            icon: "checkmark.circle.fill",
            duration: 2.0
        )
    }
    
    // MARK: - Action Row
    private func actionRow(
        icon: Image,
        title: String,
        rightText: String,
        rightEnabled: Bool,
        badgeCount: Int? = nil,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: { if rightEnabled { onTap() } }) {
            HStack {
                // Left icon circle
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 50, height: 50)
                    icon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                }
                .padding(.leading, 12)
                
                // Title
                Text(title)
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                // Pill + Badge
                ZStack(alignment: .topTrailing) {
                    HStack(spacing: 4) {
                        Text(rightText)
                            .foregroundColor(.white)
                            .font(.system(size: 15, weight: .bold))
                        
                        Image("icon_coin")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                    }
                    .frame(width: 64, height: 32)
                    .background(rightEnabled ? Color.blue : Color.gray.opacity(0.4))
                    .clipShape(Capsule())
                    
                    if let count = badgeCount, count > 0 {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 20, height: 20)
                            Text("\(count)")
                                .foregroundColor(.white)
                                .font(.system(size: 11, weight: .bold))
                        }
                        .offset(x: 8, y: -10)
                    }
                }
                .padding(.trailing, 12)
            }
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.08))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .disabled(!rightEnabled)
        .opacity(rightEnabled ? 1 : 0.6)
    }
    
    // MARK: - Actions
    private func handleDailyReward() {
        guard userDefaults.canClaimDailyReward() else { return }
        userDefaults.markDailyRewardClaimed()
        
        // Update UI immediately
        creditManager.credits += dailyRewardAmount
        
        Task {
            await creditManager.increaseCredits(by: dailyRewardAmount)
        }
        showRewardToast(dailyRewardAmount, prefix: "Daily gift")
    }
    
    private func handleWatchVideo() {
        guard userDefaults.canWatchVideoForCredit(maxPerDay: maxVideoPerDay) else { return }
        AdManager.shared.showRewardAd { success in
            if success {
                userDefaults.markVideoCreditUsed()
                Task {
                    await creditManager.increaseCredits(by: videoRewardAmount)
                }
                showRewardToast(videoRewardAmount, prefix: "Rewarded")
            }
        }
    }
    
    private func handleRateApp() {
        guard !userDefaults.hasRatedForCredit else { return }
        userDefaults.hasRatedForCredit = true
        
        // Update UI immediately
        creditManager.credits += rateRewardAmount
        
        Task {
            await creditManager.increaseCredits(by: rateRewardAmount)
        }
        showRewardToast(rateRewardAmount, prefix: "Rewarded")
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

// MARK: - Overlay Helper
struct GetFreeCreditDialogOverlay: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            if isPresented {
                Color.black.opacity(0.45).ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { 
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isPresented = false 
                        }
                    }
                
                GetFreeCreditDialog(onClose: { 
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isPresented = false 
                    }
                })
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isPresented)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        GetFreeCreditDialogOverlay(isPresented: .constant(true))
    }
}
