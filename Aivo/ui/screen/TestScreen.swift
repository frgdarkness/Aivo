//
//  TestScreen.swift
//  Aivo
//
//  Created for testing and debugging purposes
//

import SwiftUI
import Security

struct TestScreen: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var creditManager = CreditManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var localStorage = LocalStorageManager.shared
    
    @State private var creditAmount: String = ""
    @State private var isPremium: Bool = false
    @State private var showClearDataAlert = false
    @State private var showClearKeychainAlert = false
    @State private var showSuccessToast = false
    @State private var toastMessage = ""
    
    var body: some View {
        ZStack {
            // Background
            AivoSunsetBackground()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Set Credit Section
                        setCreditSection
                        
                        // Daily Gift Debug Section
                        dailyGiftDebugSection
                        
                        // Clear Data Buttons
                        clearDataSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .alert("Clear All Data", isPresented: $showClearDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearAllData()
            }
        } message: {
            Text("This will delete all app data including profile, credits, subscriptions, and settings. This action cannot be undone.")
        }
        .alert("Clear All Keychain Data", isPresented: $showClearKeychainAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearAllKeychainData()
            }
        } message: {
            Text("This will delete all data stored in Keychain including profileID. This action cannot be undone.")
        }
        .onAppear {
            // Load premium status khi mở màn hình
            isPremium = subscriptionManager.isPremium
        }
        .onChange(of: subscriptionManager.isPremium) { newValue in
            // Update state khi premium status thay đổi
            isPremium = newValue
        }
        .overlay(
            // Toast Message
            VStack {
                Spacer()
                if showSuccessToast {
                    Text(toastMessage)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(8)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: showSuccessToast)
                }
            }
        )
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(8)
            }
            
            Spacer()
            
            Text("Test Screen")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Placeholder to keep title centered
            Image(systemName: "chevron.left")
                .font(.title2)
                .foregroundColor(.clear)
                .padding(8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
    
    // MARK: - Set Credit Section
    private var setCreditSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Set Premium Toggle
            VStack(alignment: .leading, spacing: 12) {
                Text("Set Premium")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                HStack {
                    Text(isPremium ? "Premium Active" : "Not Premium")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Toggle("", isOn: $isPremium)
                        .toggleStyle(SwitchToggleStyle(tint: AivoTheme.Primary.orange))
                        .onChange(of: isPremium) { newValue in
                            togglePremiumStatus(newValue)
                        }
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            // Set Credit
            VStack(alignment: .leading, spacing: 12) {
                Text("Set Credit")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    TextField("Enter credit amount", text: $creditAmount)
                        .keyboardType(.numberPad)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.15))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    
                    Button(action: {
                        applyCredit()
                    }) {
                        Text("Apply")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(width: 80, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AivoTheme.Primary.orange)
                            )
                    }
                    .disabled(creditAmount.isEmpty || Int(creditAmount) == nil)
                    .opacity(creditAmount.isEmpty || Int(creditAmount) == nil ? 0.5 : 1.0)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
        )
    }
    
    // MARK: - Daily Gift Debug Section
    private var dailyGiftDebugSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🎁 Daily Gift Debug")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text("Current Streak: Day \(DailyGiftManager.shared.currentStreak) | Can Claim: \(DailyGiftManager.shared.canClaimToday() ? "✅" : "❌")")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
            
            // Set Streak Buttons (1-7)
            Text("Set Streak Day:")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(1...7, id: \.self) { day in
                    Button(action: {
                        DailyGiftManager.shared.debugSetStreak(day)
                        showToast("Streak set to Day \(day) ✅")
                    }) {
                        Text("Day \(day)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(DailyGiftManager.shared.currentStreak == day ? AivoTheme.Primary.orange : Color.white.opacity(0.15))
                            )
                    }
                }
            }
            
            // Reset Buttons
            HStack(spacing: 12) {
                Button(action: {
                    DailyGiftManager.shared.debugResetToday()
                    showToast("Daily gift reset for today ✅")
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14))
                        Text("Reset Today")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.orange.opacity(0.7)))
                }
                
                Button(action: {
                    DailyGiftManager.shared.debugResetCreditMissions()
                    showToast("Credit missions reset ✅")
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14))
                        Text("Reset Missions")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.cyan.opacity(0.7)))
                }
            }
            
            Button(action: {
                DailyGiftManager.shared.debugClearTrial()
                showToast("Premium Trial cleared ✅")
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "crown.slash.fill")
                        .font(.system(size: 14))
                    Text("Clear Premium Trial")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.6)))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
        )
    }
    
    // MARK: - Clear Data Section
    private var clearDataSection: some View {
        VStack(spacing: 16) {
            // Reset Free First Time
            Button(action: {
                resetFreeFirstTime()
            }) {
                HStack {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 18))
                    Text("Reset Free First Time")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.7))
                )
            }
            
            Button(action: {
                clearIntroStatus()
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 18))
                    Text("Clear Intro Status")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.7))
                )
            }
            
            Button(action: {
                UserDefaults.standard.removeObject(forKey: "CommunityLastReloadTime")
                showToast("Reload timer reset ✅")
            }) {
                HStack {
                    Image(systemName: "clock.arrow.counterclockwise")
                        .font(.system(size: 18))
                    Text("Reset Reload Timer")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.teal.opacity(0.7))
                )
            }
            
            Button(action: {
                clearRewardData()
            }) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 18))
                    Text("Clear All Reward Data")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.purple.opacity(0.7))
                )
            }
            
            Button(action: {
                clearRateStatus()
            }) {
                HStack {
                    Image(systemName: "star.fill")
                        .font(.system(size: 18))
                    Text("Clear Rate Status")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.8))
                )
            }
            
            Button(action: {
                showClearDataAlert = true
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18))
                    Text("Clear All Data")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.7))
                )
            }
            
            Button(action: {
                showClearKeychainAlert = true
            }) {
                HStack {
                    Image(systemName: "key.fill")
                        .font(.system(size: 18))
                    Text("Clear All Keychain Data")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.7))
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    private func togglePremiumStatus(_ isPremium: Bool) {
        // Update premium status through CreditManager
        // This will update both CreditManager and LocalStorageManager
        Task { @MainActor in
            if isPremium {
                // Set to premium with yearly period (default for testing)
                //CreditManager.shared.updatePremiumStatus(true, period: .yearly)
                SubscriptionManager.shared.setPremiumDebug(isPremiumEnable: true)
                showToast("Premium status set to Active")
            } else {
                // Remove premium status
                //CreditManager.shared.updatePremiumStatus(false)
                SubscriptionManager.shared.setPremiumDebug(isPremiumEnable: false)
                showToast("Premium status set to Inactive")
            }
            
            // Refresh SubscriptionManager status để sync với CreditManager
            await subscriptionManager.refreshStatus()
        }
    }
    
    private func applyCredit() {
        guard let amount = Int(creditAmount), amount >= 0 else {
            showToast("Invalid credit amount")
            return
        }
        
        // Set credits directly
        Task {
            await MainActor.run {
                CreditManager.shared.setCredits(amount)
            }
        }
        showToast("Credits set to \(amount)")
        creditAmount = ""
    }
    
    private func clearAllData() {
        // Clear all UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        
        // Clear all app data directories
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        
        if let documentsURL = documentsURL {
            let contents = try? fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            contents?.forEach { url in
                try? fileManager.removeItem(at: url)
            }
        }
        
        // Reset singleton instances
        // Note: This will require app restart to fully take effect
        localStorage.clearLocalProfile()
        
        // Clear subscription manager processed transactions
        UserDefaults.standard.removeObject(forKey: "ProcessedSubscriptionTransactionIDs")
        
        // Clear credit history
        CreditHistoryManager.shared.clearHistory()
        
        showToast("All app data cleared")
        
        // Force app restart or show message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            exit(0)
        }
    }
    
    private func clearAllKeychainData() {
        // Use KeychainManager's method to clear all data
        KeychainManager.shared.clearAllKeychainData()
        
        // Also update in-memory state to reflect immediate change
        Task { @MainActor in
            CreditManager.shared.credits = 0
            // Reset profileID in LocalStorage as well to sync with Keychain deletion
            localStorage.clearLocalProfile()
        }
        
        showToast("All Keychain data cleared ✅")
    }
    
    private func clearIntroStatus() {
        UserDefaultsManager.shared.resetOnboarding()
        // Reset also the first start logged flags to re-trigger analytical events
        UserDefaults.standard.removeObject(forKey: "AIVO_HAS_LOGGED_FIRST_START")
        UserDefaults.standard.removeObject(forKey: "AIVO_HAS_LOGGED_FIRST_START_FIREBASE")
        
        showToast("Intro & Start flags cleared. Restart app to see intro.")
    }
    
    private func clearRewardData() {
        // Clear weeklyRewardChecked (local flag)
        UserDefaults.standard.removeObject(forKey: "AIVO_WeeklyRewardChecked")
        // Clear billboard intro shown flag
        UserDefaults.standard.removeObject(forKey: "AIVO_BillboardIntroShown")
        // Clear weeklyRewardTag from profile
        LocalStorageManager.shared.updateWeeklyRewardTag("")
        // Reset pending reward in manager
        WeeklyRewardManager.shared.dismissReward()
        
        showToast("All reward data cleared")
    }
    
    private func resetFreeFirstTime() {
        // 1. Reset Keychain-based flags (The primary ones)
        KeychainManager.shared.saveBool(false, forKey: KeychainManager.freeTrialSongKey)
        KeychainManager.shared.saveBool(false, forKey: KeychainManager.freeTrialCoverKey)
        KeychainManager.shared.saveBool(false, forKey: KeychainManager.freeTrialLyricKey)
        
        // 2. Reset legacy AppStorage/UserDefaults flags if they exist
        UserDefaults.standard.removeObject(forKey: "has_used_free_lyric_generation")
        
        // 3. Reset daily usage flags to allow immediate testing of free experience
        UserDefaultsManager.shared.dailyFreeGenerateUsed = false
        UserDefaultsManager.shared.dailyExportCount = 0
        UserDefaultsManager.shared.dailyVideoCreditUsedCount = 0
        
        // 4. Notify managers to update UI
        ProfileManager.shared.objectWillChange.send()
        UserDefaultsManager.shared.objectWillChange.send()
        
        showToast("Free first time reset ✅ (Song, Cover, Lyric + Daily states)")
    }
    
    private func clearRateStatus() {
        UserDefaults.standard.removeObject(forKey: "AIVO_HAS_RATED_APP")
        UserDefaults.standard.removeObject(forKey: "AIVO_LAST_RATING_SHOWN_DATE")
        AppRatingManager.shared.showRatingDialog = false
        showToast("Rate status cleared ✅")
    }
    
    private func showToast(_ message: String) {
        toastMessage = message
        showSuccessToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showSuccessToast = false
        }
    }
}

#Preview {
    TestScreen()
}

