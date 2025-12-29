//
//  AnalyticsLogger.swift
//  Aivo
//
//  Created by AI Assistant on 2025-01-17.
//  
//  Unified analytics logger that sends events to both Firebase and AppsFlyer
//

import Foundation

class AnalyticsLogger {
    static let shared = AnalyticsLogger()
    
    private init() {}
    
    // MARK: - Basic Event Logging
    
    /// Log a simple event to both Firebase and AppsFlyer
    /// - Parameter event: Event name to log
    func logEvent(_ event: String) {
        FirebaseLogger.shared.logEvent(event)
        AppsFlyerLogger.shared.logEvent(event)
    }
    
    /// Log an event with parameters to both Firebase and AppsFlyer
    /// - Parameters:
    ///   - event: Event name to log
    ///   - parameters: Dictionary of parameters to include with the event
    func logEventWithBundle(_ event: String, parameters: [String: Any]?) {
        FirebaseLogger.shared.logEventWithBundle(event, parameters: parameters)
        AppsFlyerLogger.shared.logEventWithBundle(event, parameters: parameters)
    }
    
    // MARK: - Screen Tracking
    
    /// Log screen view event to both platforms
    /// - Parameters:
    ///   - screenName: Name of the screen being viewed
    ///   - screenClass: Class name of the screen (optional)
    func logScreenView(_ screenName: String, screenClass: String? = nil) {
        FirebaseLogger.shared.logScreenView(screenName, screenClass: screenClass)
        AppsFlyerLogger.shared.logScreenView(screenName, screenClass: screenClass)
    }
    
    // MARK: - User Journey Tracking
    
    /// Log app start event to both platforms (every time app starts)
    func logAppStart() {
        FirebaseLogger.shared.logAppStart()
        AppsFlyerLogger.shared.logAppStart()
    }
    
    /// Log first start event to both platforms (only once after install)
    func logFirstStart() {
        FirebaseLogger.shared.logFirstStart()
        AppsFlyerLogger.shared.logFirstStart()
    }
    
    /// Log app background event to both platforms
    func logAppBackground() {
        FirebaseLogger.shared.logAppBackground()
        AppsFlyerLogger.shared.logAppBackground()
    }
    
    /// Log app foreground event to both platforms
    func logAppForeground() {
        FirebaseLogger.shared.logAppForeground()
        AppsFlyerLogger.shared.logAppForeground()
    }
    
    // MARK: - Feature Usage Tracking
    
    /// Log when user starts a specific feature
    /// - Parameter feature: Feature name
    func logFeatureStart(_ feature: String) {
        FirebaseLogger.shared.logFeatureStart(feature)
        AppsFlyerLogger.shared.logFeatureStart(feature)
    }
    
    /// Log when user completes a specific feature
    /// - Parameter feature: Feature name
    func logFeatureComplete(_ feature: String) {
        FirebaseLogger.shared.logFeatureComplete(feature)
        AppsFlyerLogger.shared.logFeatureComplete(feature)
    }
    
    // MARK: - Error Tracking
    
    /// Log error events to both platforms
    /// - Parameters:
    ///   - error: Error description
    ///   - context: Additional context about the error
    func logError(_ error: String, context: String? = nil) {
        FirebaseLogger.shared.logError(error, context: context)
        AppsFlyerLogger.shared.logError(error, context: context)
    }
    
    // MARK: - Performance Tracking
    
    /// Log performance metrics to both platforms
    /// - Parameters:
    ///   - action: Action being measured
    ///   - duration: Duration in seconds
    ///   - success: Whether the action was successful
    func logPerformance(_ action: String, duration: TimeInterval, success: Bool) {
        FirebaseLogger.shared.logPerformance(action, duration: duration, success: success)
        AppsFlyerLogger.shared.logPerformance(action, duration: duration, success: success)
    }
}

// MARK: - Convenience Extensions
extension AnalyticsLogger {
    
    /// Quick access to event constants (using Firebase constants for compatibility)
    static let EVENT = FirebaseLogger.self
}

