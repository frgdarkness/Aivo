//
//  FirebaseLogger.swift
//  DreamHomeAI
//
//  Created by AI Assistant on 2025-01-11.
//

import Foundation
import FirebaseAnalytics

class FirebaseLogger {
    static let shared = FirebaseLogger()
    
    private init() {
        // No initialization needed for static Analytics class
    }
    
    // MARK: - Basic Event Logging
    
    /// Log a simple event without parameters
    /// - Parameter event: Event name to log
    func logEvent(_ event: String) {
        Analytics.logEvent(event, parameters: nil)
        Logger.d("Firebase Analytics: Logged event '\(event)'")
    }
    
    /// Log an event with parameters
    /// - Parameters:
    ///   - event: Event name to log
    ///   - parameters: Dictionary of parameters to include with the event
    func logEventWithBundle(_ event: String, parameters: [String: Any]?) {
        Analytics.logEvent(event, parameters: parameters)
        Logger.d("Firebase Analytics: Logged event '\(event)' with parameters: \(parameters ?? [:])")
    }
    
    // MARK: - Screen Tracking
    
    /// Log screen view event
    /// - Parameters:
    ///   - screenName: Name of the screen being viewed
    ///   - screenClass: Class name of the screen (optional)
    func logScreenView(_ screenName: String, screenClass: String? = nil) {
        logEvent(screenName)
//        var parameters: [String: Any] = [
//            AnalyticsParameterScreenName: screenName
//        ]
//        
//        if let screenClass = screenClass {
//            parameters[AnalyticsParameterScreenClass] = screenClass
//        }
//        
//        logEventWithBundle(AnalyticsEventScreenView, parameters: parameters)
    }
    
    // MARK: - User Journey Tracking
    
    /// Log app start event
    func logAppStart() {
        logEvent("startApp")
    }
    
    /// Log app background event
    func logAppBackground() {
        logEvent("app_background")
    }
    
    /// Log app foreground event
    func logAppForeground() {
        logEvent("app_foreground")
    }
    
    // MARK: - Feature Usage Tracking
    
    /// Log when user starts a specific feature
    /// - Parameter feature: Feature name
    func logFeatureStart(_ feature: String) {
        logEventWithBundle("event_feature_start", parameters: [
            "feature_name": feature,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    /// Log when user completes a specific feature
    /// - Parameter feature: Feature name
    func logFeatureComplete(_ feature: String) {
        logEventWithBundle("event_feature_complete", parameters: [
            "feature_name": feature,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // MARK: - Error Tracking
    
    /// Log error events
    /// - Parameters:
    ///   - error: Error description
    ///   - context: Additional context about the error
    func logError(_ error: String, context: String? = nil) {
        var parameters: [String: Any] = [
            "error_message": error,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let context = context {
            parameters["error_context"] = context
        }
        
        logEventWithBundle("event_error", parameters: parameters)
    }
    
    // MARK: - Performance Tracking
    
    /// Log performance metrics
    /// - Parameters:
    ///   - action: Action being measured
    ///   - duration: Duration in seconds
    ///   - success: Whether the action was successful
    func logPerformance(_ action: String, duration: TimeInterval, success: Bool) {
        logEventWithBundle("event_performance", parameters: [
            "action": action,
            "duration": duration,
            "success": success,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
}

// MARK: - Event Constants
extension FirebaseLogger {
    
    // App Events
    static let EVENT_APP_START = "startApp"
    static let EVENT_APP_BACKGROUND = "app_background"
    static let EVENT_APP_FOREGROUND = "app_foreground"
    
    // Screen Events
    static let EVENT_SCREEN_SPLASH = "screen_splash"
    static let EVENT_SCREEN_INTRO = "screen_intro"
    static let EVENT_SCREEN_HOME = "screen_home"
    static let EVENT_SCREEN_LANGUAGE = "screen_language"
    static let EVENT_SCREEN_PAINT = "screen_paint"
    static let EVENT_SCREEN_FLOOR = "screen_floor"
    static let EVENT_SCREEN_REMOVE_OBJECT = "screen_remove_object"
    static let EVENT_SCREEN_REPLACE_OBJECT = "screen_replace_object"
    static let EVENT_SCREEN_ADMIN = "screen_admin"
    static let EVENT_SCREEN_BUY_CREDIT = "screen_buy_credit"
    static let EVENT_SCREEN_DASHBOARD = "screen_dashboard"
    static let EVENT_SCREEN_TOOLS = "screen_tools"
    static let EVENT_SCREEN_CREATE = "screen_create"
    static let EVENT_SCREEN_INTERIOR_DESIGN = "screen_interior_design"
    static let EVENT_SCREEN_EXTERIOR_DESIGN = "screen_exterior_design"
    static let EVENT_SCREEN_DECORATOR = "screen_decorator"
    static let EVENT_SCREEN_SKETCH = "screen_sketch"
    static let EVENT_SCREEN_TEXT_TO_DESIGN = "screen_text_to_design"
    
    // Music App Screen Events
    static let EVENT_SCREEN_SUBSCRIPTION = "screen_subscription"
    static let EVENT_SCREEN_SUBSCRIPTION_INTRO = "screen_subscription_intro"
    static let EVENT_SCREEN_GENERATE_LYRICS = "screen_generate_lyrics"
    static let EVENT_SCREEN_GENERATE_SONG = "screen_generate_song"
    static let EVENT_SCREEN_COVER = "screen_cover"
    static let EVENT_SCREEN_PROFILE = "screen_profile"
    static let EVENT_SCREEN_EXPLORE = "screen_explore"
    static let EVENT_SCREEN_LIBRARY = "screen_library"
    static let EVENT_SCREEN_PLAY_SONG = "screen_play_song"
    static let EVENT_SCREEN_CREDIT_HISTORY = "screen_credit_history"
    
    // Flow Events
    static let EVENT_FETCH_CONFIG_START = "event_fetch_config_start"
    static let EVENT_FETCH_CONFIG_FINISH = "event_fetch_config_finish"
    static let EVENT_GENERATE = "event_generate"
    static let EVENT_DOWNLOAD = "event_download"
    static let EVENT_REMOVE_WATERMARK = "event_remove_watermark"
    static let EVENT_SAVE_DESIGN = "event_save_design"
    static let EVENT_SHARE_DESIGN = "event_share_design"
    static let EVENT_RATE_APP = "event_rate_app"
    static let EVENT_HELP_SUPPORT = "event_help_support"
    
    // Feature Events
    static let EVENT_INTERIOR_DESIGN = "event_interior_design"
    static let EVENT_EXTERIOR_DESIGN = "event_exterior_design"
    static let EVENT_DECORATOR = "event_decorator"
    static let EVENT_FREE_GENERATE = "event_free_generate"
    static let EVENT_PREMIUM_GENERATE = "event_premium_generate"
    
    // Music Generation Events
    static let EVENT_GENERATE_LYRICS_START = "event_generate_lyrics_start"
    static let EVENT_GENERATE_LYRICS_SUCCESS = "event_generate_lyrics_success"
    static let EVENT_GENERATE_LYRICS_FAILED = "event_generate_lyrics_failed"
    static let EVENT_GENERATE_SONG_START = "event_generate_song_start"
    static let EVENT_GENERATE_SONG_SUCCESS = "event_generate_song_success"
    static let EVENT_GENERATE_SONG_FAILED = "event_generate_song_failed"
    static let EVENT_GENERATE_COVER_START = "event_generate_cover_start"
    static let EVENT_GENERATE_COVER_SUCCESS = "event_generate_cover_success"
    static let EVENT_GENERATE_COVER_FAILED = "event_generate_cover_failed"
    
    // Intro Step Events
    static let EVENT_INTRO_STEP_1 = "event_intro_step_1"
    static let EVENT_INTRO_STEP_2 = "event_intro_step_2"
    static let EVENT_INTRO_STEP_3 = "event_intro_step_3"
    
    // Download Events
    static let EVENT_DOWNLOAD_SONG_REQUEST = "event_download_song_request"
    static let EVENT_DOWNLOAD_SONG_SUCCESS = "event_download_song_success"
    
    // Export Events
    static let EVENT_EXPORT_SONG = "event_export_song"
    
    // Error Events
    static let EVENT_ERROR = "event_error"
    static let EVENT_NETWORK_ERROR = "event_network_error"
    static let EVENT_CREDIT_INSUFFICIENT = "event_credit_insufficient"
}
