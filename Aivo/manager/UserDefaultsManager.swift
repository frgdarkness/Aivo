//
//  UserDefaultsManager.swift
//  DreamHomeAI
//
//  Created by AI Assistant on 2025-01-01.
//

import Foundation
import SwiftUI

class UserDefaultsManager: ObservableObject {
    static let shared = UserDefaultsManager()
    
    private init() {}
    
    // MARK: - Keys
    private enum Keys {
        static let isLanguageShowed = "isLanguageShowed"
        static let isIntroShowed = "isIntroShowed"
        static let selectedLanguageCode = "selectedLanguageCode"
        static let selectedLanguageName = "selectedLanguageName"
        static let lastSubscriptionPromptDate = "lastSubscriptionPromptDate"
        static let userCredits = "userCredits"
        static let dailySuggestSubscription = "dailySuggestSubscription"
        // Free credit states
        static let lastDailyRewardDate = "lastDailyRewardDate"
        static let dailyVideoCreditUsedCount = "dailyVideoCreditUsedCount"
        static let lastVideoCreditDate = "lastVideoCreditDate"
        static let hasRatedForCredit = "hasRatedForCredit"
        // Daily free generate time
        static let lastDailyFreeGenerateDate = "lastDailyFreeGenerateDate"
        static let dailyFreeGenerateUsed = "dailyFreeGenerateUsed"
    }
    
    // MARK: - Language Selection
    var isLanguageShowed: Bool {
        get {
            UserDefaults.standard.bool(forKey: Keys.isLanguageShowed)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.isLanguageShowed)
            objectWillChange.send()
        }
    }
    
    // MARK: - Intro Selection
    var isIntroShowed: Bool {
        get {
            UserDefaults.standard.bool(forKey: Keys.isIntroShowed)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.isIntroShowed)
            objectWillChange.send()
        }
    }
    
    // MARK: - Selected Language
    var selectedLanguageCode: String? {
        get {
            UserDefaults.standard.string(forKey: Keys.selectedLanguageCode)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.selectedLanguageCode)
        }
    }
    
    var selectedLanguageName: String? {
        get {
            UserDefaults.standard.string(forKey: Keys.selectedLanguageName)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.selectedLanguageName)
        }
    }
    
    // MARK: - Helper Methods
    func setLanguageSelected(_ language: LanguageData) {
        //selectedLanguageCode = language.code
        selectedLanguageName = language.name
        isLanguageShowed = true
    }
    
    func markIntroAsShowed() {
        isIntroShowed = true
    }
    
    func resetOnboarding() {
        isLanguageShowed = false
        isIntroShowed = false
        selectedLanguageCode = nil
        selectedLanguageName = nil
    }
    
    func clearAllDataExceptIntroAndLanguage() {
        // Lưu lại giá trị intro và language
        let savedIsLanguageShowed = isLanguageShowed
        let savedIsIntroShowed = isIntroShowed
        let savedLanguageCode = selectedLanguageCode
        
        // Clear tất cả UserDefaults
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        
        // Khôi phục lại intro và language flags
        isLanguageShowed = savedIsLanguageShowed
        isIntroShowed = savedIsIntroShowed
        selectedLanguageCode = savedLanguageCode
        
        // Reset các giá trị khác về mặc định
        userCredits = 0
        dailySuggestSubscription = false
        lastSubscriptionPromptDate = nil
        // Reset free credit related
        lastDailyRewardDate = nil
        dailyVideoCreditUsedCount = 0
        lastVideoCreditDate = nil
        hasRatedForCredit = false
        // Reset daily free generate time
        lastDailyFreeGenerateDate = nil
        dailyFreeGenerateUsed = false
    }
    
    // MARK: - Navigation Logic
    func shouldShowLanguageSelection() -> Bool {
        return !isLanguageShowed
    }
    
    func shouldShowIntro() -> Bool {
        return isLanguageShowed && !isIntroShowed
    }
    
    func shouldGoDirectlyToHome() -> Bool {
        return isLanguageShowed && isIntroShowed
    }
    
    // MARK: - Credit Management
    var userCredits: Int {
        get {
            UserDefaults.standard.integer(forKey: Keys.userCredits)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.userCredits)
            objectWillChange.send()
        }
    }
    
    var lastSubscriptionPromptDate: Date? {
        get {
            UserDefaults.standard.object(forKey: Keys.lastSubscriptionPromptDate) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.lastSubscriptionPromptDate)
        }
    }
    
    func shouldShowSubscriptionPrompt() -> Bool {
        // Kiểm tra subscription status - chỉ show nếu chưa có subscription
        // Note: Subscription status được check từ SubscriptionManager, không cần check credit
        
        // Reset flag mỗi ngày mới
        resetDailySuggestSubscription()
        
        // Kiểm tra flag dailySuggestSubscription
        guard !dailySuggestSubscription else { return false }
        
        // Kiểm tra xem đã hiển thị hôm nay chưa
        if let lastPromptDate = lastSubscriptionPromptDate {
            let calendar = Calendar.current
            if calendar.isDateInToday(lastPromptDate) {
                return false
            }
        }
        
        // Nếu thỏa mãn điều kiện thì hiển thị
        return true
    }
    
    var dailySuggestSubscription: Bool {
        get {
            UserDefaults.standard.bool(forKey: Keys.dailySuggestSubscription)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.dailySuggestSubscription)
            objectWillChange.send()
        }
    }
    
    func markSubscriptionPromptShown() {
        lastSubscriptionPromptDate = Date()
        dailySuggestSubscription = true
    }
    
    func resetDailySuggestSubscription() {
        // Reset flag mỗi ngày mới
        if let lastPromptDate = lastSubscriptionPromptDate {
            let calendar = Calendar.current
            if !calendar.isDateInToday(lastPromptDate) {
                dailySuggestSubscription = false
            }
        }
    }

    // MARK: - Free Credit (Daily Reward / Watch Video / Rate)
    var lastDailyRewardDate: Date? {
        get { UserDefaults.standard.object(forKey: Keys.lastDailyRewardDate) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: Keys.lastDailyRewardDate) }
    }
    
    var dailyVideoCreditUsedCount: Int {
        get { UserDefaults.standard.integer(forKey: Keys.dailyVideoCreditUsedCount) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.dailyVideoCreditUsedCount); objectWillChange.send() }
    }
    
    var lastVideoCreditDate: Date? {
        get { UserDefaults.standard.object(forKey: Keys.lastVideoCreditDate) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: Keys.lastVideoCreditDate) }
    }
    
    var hasRatedForCredit: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.hasRatedForCredit) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.hasRatedForCredit); objectWillChange.send() }
    }
    
    func resetDailyFreeCreditStatesIfNeeded() {
        let calendar = Calendar.current
        // Reset daily reward marker if not today
        if let lastReward = lastDailyRewardDate, !calendar.isDateInToday(lastReward) {
            lastDailyRewardDate = nil
        }
        // Reset video used count if not today
        if let lastVideoDate = lastVideoCreditDate, !calendar.isDateInToday(lastVideoDate) {
            dailyVideoCreditUsedCount = 0
            lastVideoCreditDate = nil
        }
        // hasRatedForCredit is one-time; do not reset
    }
    
    func canClaimDailyReward() -> Bool {
        if let lastReward = lastDailyRewardDate {
            return !Calendar.current.isDateInToday(lastReward)
        }
        return true
    }
    
    func markDailyRewardClaimed() {
        lastDailyRewardDate = Date()
    }
    
    func remainingVideoCreditViews(maxPerDay: Int = 3) -> Int {
        resetDailyFreeCreditStatesIfNeeded()
        return max(0, maxPerDay - dailyVideoCreditUsedCount)
    }
    
    func canWatchVideoForCredit(maxPerDay: Int = 3) -> Bool {
        return remainingVideoCreditViews(maxPerDay: maxPerDay) > 0
    }
    
    func markVideoCreditUsed() {
        dailyVideoCreditUsedCount = dailyVideoCreditUsedCount + 1
        lastVideoCreditDate = Date()
    }
    
    // MARK: - Daily Free Generate Time
    var lastDailyFreeGenerateDate: Date? {
        get { UserDefaults.standard.object(forKey: Keys.lastDailyFreeGenerateDate) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: Keys.lastDailyFreeGenerateDate) }
    }
    
    var dailyFreeGenerateUsed: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.dailyFreeGenerateUsed) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.dailyFreeGenerateUsed); objectWillChange.send() }
    }
    
    func resetDailyFreeGenerateStateIfNeeded() {
        let calendar = Calendar.current
        
        // Reset daily free generate marker if not today
        if let lastGenerate = lastDailyFreeGenerateDate, !calendar.isDateInToday(lastGenerate) {
            Logger.d("UserDefaultsManager: Resetting daily free generate state (new day)")
            dailyFreeGenerateUsed = false
            lastDailyFreeGenerateDate = nil
        }
    }
        
    func canUseDailyFreeGenerate() -> Bool {
        resetDailyFreeGenerateStateIfNeeded()
        let canUse = !dailyFreeGenerateUsed
        Logger.d("UserDefaultsManager: canUseDailyFreeGenerate = \(canUse) (dailyFreeGenerateUsed = \(dailyFreeGenerateUsed))")
        return canUse
    }
    
    func markDailyFreeGenerateUsed() {
        dailyFreeGenerateUsed = true
        lastDailyFreeGenerateDate = Date()
    }
}
