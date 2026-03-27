import Foundation
import StoreKit
import SwiftUI

class AppRatingManager: ObservableObject {
    static let shared = AppRatingManager()
    
    private let kHasRatedApp = "AIVO_HAS_RATED_APP"
    private let kLastRatingShownDate = "AIVO_LAST_RATING_SHOWN_DATE"
    
    @Published var showRatingDialog: Bool = false
    
    private init() {}
    
    var hasRatedApp: Bool {
        get { UserDefaults.standard.bool(forKey: kHasRatedApp) }
        set { UserDefaults.standard.set(newValue, forKey: kHasRatedApp) }
    }
    
    var lastRatingShownDate: Date? {
        get { UserDefaults.standard.object(forKey: kLastRatingShownDate) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: kLastRatingShownDate) }
    }
    
    /// Checks conditions and triggers the custom rating dialog to be shown.
    @MainActor
    func tryShowRateApp() {
        Logger.d("⭐️ [AppRatingManager] Checking conditions to show rating dialog...")
        
        // 1. Check if user already rated
        guard !hasRatedApp else {
            Logger.d("⭐️ [AppRatingManager] hasRatedApp is true. Skip showing.")
            return
        }
        
        // 2. Check if already shown today
        if let lastDate = lastRatingShownDate {
            if Calendar.current.isDateInToday(lastDate) {
                Logger.d("⭐️ [AppRatingManager] Already shown today (lastDate: \(lastDate)). Skip showing.")
                return
            }
        }
        
        Logger.i("⭐️ [AppRatingManager] CONDITIONS MET! Triggering Rating Dialog.")
        
        // 3. Trigger Custom Dialog
        withAnimation {
            showRatingDialog = true
        }
        
        // Update last shown date immediately when we attempt to show
        lastRatingShownDate = Date()
        Logger.d("⭐️ [AppRatingManager] Set lastRatingShownDate to TODAY (\(lastRatingShownDate!))")
    }

    func logStatus() {
        Logger.i("⭐️ [AppRatingManager] STATUS: hasRatedApp = \(hasRatedApp), lastRatingShownDate = \(String(describing: lastRatingShownDate))")
    }
    
    /// Forces the rating dialog to show (e.g. from Profile screen)
    @MainActor
    func forceShowRateApp() {
        withAnimation {
            showRatingDialog = true
        }
    }
    
    /// Call this from the View when user provides a rating
    @MainActor
    func handleRateAction(stars: Int) {
        showRatingDialog = false
        
        Logger.d("⭐️ [AppRatingManager] User rated: \(stars) stars")
        
        if stars >= 4 {
            markAsRated()
            requestSystemReview()
        }
    }
    
    @MainActor
    func dismissDialog() {
        showRatingDialog = false
    }
    
    private func requestSystemReview() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            Logger.i("⭐️ [AppRatingManager] Requesting system review...")
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
    
    /// Call this when we catch a definitive high rating from our custom UI
    func markAsRated() {
        hasRatedApp = true
        Logger.i("⭐️ [AppRatingManager] Marked as rated.")
    }
}
