//
//  FacebookEventLogger.swift
//  Aivo
//
//  Created for Facebook App Events tracking
//

import Foundation
import FBSDKCoreKit

/// Helper class to log events to Facebook App Events for conversion tracking
final class FacebookEventLogger {
    static let shared = FacebookEventLogger()
    
    private init() {}
    
    // MARK: - Purchase Events
    
    /// Log purchase event to Facebook App Events
    /// - Parameters:
    ///   - amount: Purchase amount (in app currency)
    ///   - currency: Currency code (e.g., "USD", "VND")
    ///   - productID: Product identifier
    ///   - parameters: Additional parameters
    func logPurchase(amount: Double, currency: String = "USD", productID: String? = nil, parameters: [String: Any]? = nil) {
        var params: [AppEvents.ParameterName: Any] = [
            .currency: currency,
            .numItems: 1
        ]
        
        if let productID = productID {
            params[.contentID] = productID
        }
        
        // Note: Facebook SDK only accepts AppEvents.ParameterName enum values
        // Custom string parameters are not supported in logPurchase
        if parameters != nil {
            Logger.d("📱 [FacebookEventLogger] Additional parameters provided but only standard parameters are supported for purchases")
        }
        
        AppEvents.shared.logPurchase(
            amount: amount,
            currency: currency,
            parameters: params
        )
        
        Logger.d("📱 [FacebookEventLogger] Logged purchase: \(amount) \(currency), productID: \(productID ?? "N/A")")
    }
    
    /// Log subscription purchase
    /// - Parameters:
    ///   - amount: Subscription amount
    ///   - currency: Currency code
    ///   - productID: Product identifier
    ///   - period: Subscription period (weekly, monthly, yearly)
    func logSubscriptionPurchase(amount: Double, currency: String = "USD", productID: String, period: String) {
        let params: [AppEvents.ParameterName: Any] = [
            .contentID: productID
        ]
        
        // Log purchase event
        AppEvents.shared.logPurchase(
            amount: amount,
            currency: currency,
            parameters: params
        )
        
        // Also log a custom event for subscription tracking
        AppEvents.shared.logEvent(
            AppEvents.Name("subscription_purchase"),
            parameters: [
                .contentID: productID,
                .currency: currency
            ]
        )
        
        Logger.d("📱 [FacebookEventLogger] Logged subscription purchase: \(amount) \(currency), period: \(period)")
    }
    
    // MARK: - Custom Events
    
    /// Log custom event to Facebook
    /// - Parameters:
    ///   - eventName: Event name
    ///   - parameters: Event parameters (must use AppEvents.ParameterName enum)
    func logEvent(_ eventName: String, parameters: [AppEvents.ParameterName: Any]? = nil) {
        AppEvents.shared.logEvent(
            AppEvents.Name(eventName),
            parameters: parameters ?? [:]
        )
        
        Logger.d("📱 [FacebookEventLogger] Logged event: \(eventName)")
    }
    
    /// Log app install event (should be called on first launch)
    func logAppInstall() {
        AppEvents.shared.logEvent(.achievedLevel)
        Logger.d("📱 [FacebookEventLogger] Logged app install event")
    }
    
    /// Log app open event
    func logAppOpen() {
        // activateApp() is already called in AppDelegate
        // This is for additional tracking if needed
        // Use a custom event name for app open tracking
        AppEvents.shared.logEvent(AppEvents.Name("app_open"))
        Logger.d("📱 [FacebookEventLogger] Logged app open event")
    }
}

