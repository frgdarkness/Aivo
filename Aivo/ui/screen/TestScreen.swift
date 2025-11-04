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
    
    // MARK: - Clear Data Section
    private var clearDataSection: some View {
        VStack(spacing: 16) {
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
        
        showToast("All Keychain data cleared")
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

