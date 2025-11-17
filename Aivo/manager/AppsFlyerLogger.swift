//
//  AppsFlyerLogger.swift
//  Aivo
//
//  Created by AI Assistant on 2025-01-17.
//

import Foundation
import AppsFlyerLib

class AppsFlyerLogger {
    static let shared = AppsFlyerLogger()
    
    private init() {
        // Private initializer for singleton
    }
    
    // MARK: - Basic Event Logging
    
    /// Log a simple event without parameters
    /// - Parameter event: Event name to log
    func logEvent(_ event: String) {
        AppsFlyerLib.shared().logEvent(event, withValues: nil)
        Logger.d("🔥 AppsFlyer: Logged event '\(event)'")
    }
    
    /// Log an event with parameters
    /// - Parameters:
    ///   - event: Event name to log
    ///   - parameters: Dictionary of parameters to include with the event
    func logEventWithBundle(_ event: String, parameters: [String: Any]?) {
        AppsFlyerLib.shared().logEvent(event, withValues: parameters)
        Logger.d("🔥 AppsFlyer: Logged event '\(event)' with parameters: \(parameters ?? [:])")
    }
    
    // MARK: - Screen Tracking
    
    /// Log screen view event
    /// - Parameters:
    ///   - screenName: Name of the screen being viewed
    ///   - screenClass: Class name of the screen (optional)
    func logScreenView(_ screenName: String, screenClass: String? = nil) {
        var parameters: [String: Any] = [
            "screen_name": screenName
        ]
        
        if let screenClass = screenClass {
            parameters["screen_class"] = screenClass
        }
        
        logEventWithBundle("af_screen_view", parameters: parameters)
    }
    
    // MARK: - User Journey Tracking
    
    /// Log app start event
    func logAppStart() {
        logEvent("app_start")
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
        logEventWithBundle("feature_start", parameters: [
            "feature_name": feature,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    /// Log when user completes a specific feature
    /// - Parameter feature: Feature name
    func logFeatureComplete(_ feature: String) {
        logEventWithBundle("feature_complete", parameters: [
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
        
        logEventWithBundle("af_error", parameters: parameters)
    }
    
    // MARK: - Performance Tracking
    
    /// Log performance metrics
    /// - Parameters:
    ///   - action: Action being measured
    ///   - duration: Duration in seconds
    ///   - success: Whether the action was successful
    func logPerformance(_ action: String, duration: TimeInterval, success: Bool) {
        logEventWithBundle("af_performance", parameters: [
            "action": action,
            "duration": duration,
            "success": success,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // MARK: - Revenue Events (AppsFlyer Specific)
    
    /// Log purchase event (in-app purchase)
    /// - Parameters:
    ///   - productId: Product identifier
    ///   - price: Price of the product
    ///   - currency: Currency code (e.g., "USD")
    func logPurchase(productId: String, price: Double, currency: String) {
        logEventWithBundle(AFEventPurchase, parameters: [
            AFEventParamContentId: productId,
            AFEventParamRevenue: price,
            AFEventParamCurrency: currency,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    /// Log subscription event
    /// - Parameters:
    ///   - productId: Subscription product identifier
    ///   - price: Subscription price
    ///   - currency: Currency code
    func logSubscribe(productId: String, price: Double, currency: String) {
        logEventWithBundle(AFEventSubscribe, parameters: [
            AFEventParamContentId: productId,
            AFEventParamRevenue: price,
            AFEventParamCurrency: currency,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // MARK: - Custom Music App Events
    
    /// Log song generation event
    /// - Parameters:
    ///   - inputType: Type of input (description/lyrics)
    ///   - hasSongName: Whether user provided song name
    ///   - model: Model used (V3/V3.5)
    func logGenerateSong(inputType: String, hasSongName: Bool, model: String) {
        logEventWithBundle("generate_song", parameters: [
            "input_type": inputType,
            "has_song_name": hasSongName,
            "model": model,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    /// Log lyrics generation event
    /// - Parameter success: Whether generation was successful
    func logGenerateLyrics(success: Bool) {
        logEventWithBundle("generate_lyrics", parameters: [
            "success": success,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    /// Log cover song generation event
    /// - Parameter success: Whether generation was successful
    func logGenerateCover(success: Bool) {
        logEventWithBundle("generate_cover", parameters: [
            "success": success,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    /// Log song play event
    /// - Parameters:
    ///   - songId: Song identifier
    ///   - duration: Play duration in seconds
    func logPlaySong(songId: String, duration: TimeInterval) {
        logEventWithBundle("play_song", parameters: [
            "song_id": songId,
            "duration": duration,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    /// Log song download event
    /// - Parameter songId: Song identifier
    func logDownloadSong(songId: String) {
        logEventWithBundle("download_song", parameters: [
            "song_id": songId,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    /// Log song share event
    /// - Parameters:
    ///   - songId: Song identifier
    ///   - platform: Share platform (e.g., "instagram", "facebook")
    func logShareSong(songId: String, platform: String) {
        logEventWithBundle(AFEventShare, parameters: [
            AFEventParamContentId: songId,
            AFEventParamContentType: "song",
            "platform": platform,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
}

// MARK: - Event Constants
extension AppsFlyerLogger {
    
    // App Events
    static let EVENT_APP_START = "app_start"
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
    static let EVENT_FETCH_CONFIG_START = "fetch_config_start"
    static let EVENT_FETCH_CONFIG_FINISH = "fetch_config_finish"
    static let EVENT_GENERATE = "generate"
    static let EVENT_DOWNLOAD = "download"
    static let EVENT_REMOVE_WATERMARK = "remove_watermark"
    static let EVENT_SAVE_DESIGN = "save_design"
    static let EVENT_SHARE_DESIGN = "share_design"
    static let EVENT_RATE_APP = "rate_app"
    static let EVENT_HELP_SUPPORT = "help_support"
    
    // Feature Events
    static let EVENT_INTERIOR_DESIGN = "interior_design"
    static let EVENT_EXTERIOR_DESIGN = "exterior_design"
    static let EVENT_DECORATOR = "decorator"
    static let EVENT_FREE_GENERATE = "free_generate"
    static let EVENT_PREMIUM_GENERATE = "premium_generate"
    
    // Music Generation Events
    static let EVENT_GENERATE_LYRICS_START = "generate_lyrics_start"
    static let EVENT_GENERATE_LYRICS_SUCCESS = "generate_lyrics_success"
    static let EVENT_GENERATE_LYRICS_FAILED = "generate_lyrics_failed"
    static let EVENT_GENERATE_SONG_START = "generate_song_start"
    static let EVENT_GENERATE_SONG_SUCCESS = "generate_song_success"
    static let EVENT_GENERATE_SONG_FAILED = "generate_song_failed"
    static let EVENT_GENERATE_COVER_START = "generate_cover_start"
    static let EVENT_GENERATE_COVER_SUCCESS = "generate_cover_success"
    static let EVENT_GENERATE_COVER_FAILED = "generate_cover_failed"
    
    // Intro Step Events
    static let EVENT_INTRO_STEP_1 = "intro_step_1"
    static let EVENT_INTRO_STEP_2 = "intro_step_2"
    static let EVENT_INTRO_STEP_3 = "intro_step_3"
    
    // Download Events
    static let EVENT_DOWNLOAD_SONG_REQUEST = "download_song_request"
    static let EVENT_DOWNLOAD_SONG_SUCCESS = "download_song_success"
    
    // Export Events
    static let EVENT_EXPORT_SONG = "export_song"
    
    // Error Events
    static let EVENT_ERROR = "error"
    static let EVENT_NETWORK_ERROR = "network_error"
    static let EVENT_CREDIT_INSUFFICIENT = "credit_insufficient"
}

