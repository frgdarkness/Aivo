//
//  APIError.swift
//  DreamHomeAI
//
//  Created by AI Assistant on 2024-12-21.
//

import Foundation

// MARK: - API Error
enum APIError: Error, LocalizedError, Equatable {
    // Network Errors
    case noInternetConnection
    case requestTimeout
    case serverUnavailable
    case invalidURL
    case networkError(Error)
    
    // Authentication Errors
    case unauthorized
    case forbidden
    case tokenExpired
    case invalidCredentials
    
    // Client Errors
    case badRequest(String?)
    case notFound
    case validationError([String])
    case rateLimitExceeded
    case paymentRequired
    
    // Server Errors
    case internalServerError
    case serviceUnavailable
    case badGateway
    
    // AI Service Errors
    case aiServiceError(String)
    case imageProcessingFailed
    case unsupportedImageFormat
    case imageTooLarge
    case aiQuotaExceeded
    case modelNotAvailable
    
    // Data Errors
    case decodingError
    case encodingError
    case invalidResponse
    case missingData
    
    // Business Logic Errors
    case subscriptionRequired
    case designLimitReached
    case invalidDesignParameters
    case duplicateRequest
    
    // Unknown
    case unknown(String?)
    
    // MARK: - Error Descriptions
    var errorDescription: String? {
        switch self {
        // Network Errors
        case .noInternetConnection:
            return "No internet connection. Please check your network settings."
        case .requestTimeout:
            return "Request timed out. Please try again."
        case .serverUnavailable:
            return "Server is currently unavailable. Please try again later."
        case .invalidURL:
            return "Invalid URL configuration."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
            
        // Authentication Errors
        case .unauthorized:
            return "You are not authorized to perform this action."
        case .forbidden:
            return "Access forbidden. Please check your permissions."
        case .tokenExpired:
            return "Your session has expired. Please sign in again."
        case .invalidCredentials:
            return "Invalid email or password."
            
        // Client Errors
        case .badRequest(let message):
            return message ?? "Invalid request. Please check your input."
        case .notFound:
            return "The requested resource was not found."
        case .validationError(let errors):
            return "Validation failed: \(errors.joined(separator: ", "))"
        case .rateLimitExceeded:
            return "Too many requests. Please wait before trying again."
        case .paymentRequired:
            return "Payment required to access this feature."
            
        // Server Errors
        case .internalServerError:
            return "Internal server error. Please try again later."
        case .serviceUnavailable:
            return "Service temporarily unavailable. Please try again later."
        case .badGateway:
            return "Bad gateway. Please try again later."
            
        // AI Service Errors
        case .aiServiceError(let message):
            return "AI service error: \(message)"
        case .imageProcessingFailed:
            return "Failed to process image. Please try with a different image."
        case .unsupportedImageFormat:
            return "Unsupported image format. Please use JPG, PNG, or HEIC."
        case .imageTooLarge:
            return "Image is too large. Please use an image smaller than 10MB."
        case .aiQuotaExceeded:
            return "AI processing quota exceeded. Please upgrade your plan."
        case .modelNotAvailable:
            return "AI model is currently unavailable. Please try again later."
            
        // Data Errors
        case .decodingError:
            return "Failed to decode server response."
        case .encodingError:
            return "Failed to encode request data."
        case .invalidResponse:
            return "Invalid response from server."
        case .missingData:
            return "Missing required data."
            
        // Business Logic Errors
        case .subscriptionRequired:
            return "This feature requires a premium subscription."
        case .designLimitReached:
            return "You've reached your monthly design limit. Upgrade to continue."
        case .invalidDesignParameters:
            return "Invalid design parameters. Please check your settings."
        case .duplicateRequest:
            return "Duplicate request detected. Please wait for the current operation to complete."
            
        // Unknown
        case .unknown(let message):
            return message ?? "An unknown error occurred."
        }
    }
    
    // MARK: - Error Codes
    var code: Int {
        switch self {
        // Network Errors (1000-1099)
        case .noInternetConnection: return 1001
        case .requestTimeout: return 1002
        case .serverUnavailable: return 1003
        case .invalidURL: return 1004
        case .networkError: return 1099
            
        // Authentication Errors (1100-1199)
        case .unauthorized: return 1101
        case .forbidden: return 1102
        case .tokenExpired: return 1103
        case .invalidCredentials: return 1104
            
        // Client Errors (1200-1299)
        case .badRequest: return 1201
        case .notFound: return 1202
        case .validationError: return 1203
        case .rateLimitExceeded: return 1204
        case .paymentRequired: return 1205
            
        // Server Errors (1300-1399)
        case .internalServerError: return 1301
        case .serviceUnavailable: return 1302
        case .badGateway: return 1303
            
        // AI Service Errors (1400-1499)
        case .aiServiceError: return 1401
        case .imageProcessingFailed: return 1402
        case .unsupportedImageFormat: return 1403
        case .imageTooLarge: return 1404
        case .aiQuotaExceeded: return 1405
        case .modelNotAvailable: return 1406
            
        // Data Errors (1500-1599)
        case .decodingError: return 1501
        case .encodingError: return 1502
        case .invalidResponse: return 1503
        case .missingData: return 1504
            
        // Business Logic Errors (1600-1699)
        case .subscriptionRequired: return 1601
        case .designLimitReached: return 1602
        case .invalidDesignParameters: return 1603
        case .duplicateRequest: return 1604
            
        // Unknown (9999)
        case .unknown: return 9999
        }
    }
    
    // MARK: - Recovery Suggestions
    var recoverySuggestion: String? {
        switch self {
        case .noInternetConnection:
            return "Check your Wi-Fi or cellular connection and try again."
        case .requestTimeout:
            return "Check your internet connection and try again."
        case .unauthorized, .tokenExpired:
            return "Please sign in again to continue."
        case .subscriptionRequired, .designLimitReached:
            return "Upgrade to a premium plan to access this feature."
        case .unsupportedImageFormat:
            return "Please select a JPG, PNG, or HEIC image."
        case .imageTooLarge:
            return "Please compress your image or select a smaller one."
        case .rateLimitExceeded:
            return "Please wait a few minutes before trying again."
        case .validationError:
            return "Please check your input and try again."
        default:
            return "Please try again. If the problem persists, contact support."
        }
    }
    
    // MARK: - User-Friendly Title
    var title: String {
        switch self {
        case .noInternetConnection:
            return "No Internet Connection"
        case .unauthorized, .forbidden, .tokenExpired:
            return "Authentication Error"
        case .subscriptionRequired, .designLimitReached:
            return "Subscription Required"
        case .aiServiceError, .imageProcessingFailed, .modelNotAvailable:
            return "AI Processing Error"
        case .unsupportedImageFormat, .imageTooLarge:
            return "Image Error"
        case .rateLimitExceeded:
            return "Rate Limit Exceeded"
        case .serverUnavailable, .serviceUnavailable, .internalServerError:
            return "Server Error"
        default:
            return "Error"
        }
    }
    
    // MARK: - Should Retry
    var shouldRetry: Bool {
        switch self {
        case .requestTimeout, .serverUnavailable, .serviceUnavailable, .badGateway, .networkError:
            return true
        case .rateLimitExceeded:
            return true // After delay
        case .modelNotAvailable:
            return true // After delay
        default:
            return false
        }
    }
    
    // MARK: - Retry Delay
    var retryDelay: TimeInterval {
        switch self {
        case .rateLimitExceeded:
            return 60.0 // 1 minute
        case .modelNotAvailable:
            return 30.0 // 30 seconds
        case .requestTimeout, .serverUnavailable:
            return 5.0 // 5 seconds
        default:
            return 2.0 // 2 seconds
        }
    }
    
    // MARK: - Is Critical
    var isCritical: Bool {
        switch self {
        case .internalServerError, .serviceUnavailable, .badGateway:
            return true
        case .aiServiceError, .imageProcessingFailed:
            return true
        default:
            return false
        }
    }
}

// MARK: - APIError + HTTP Status Code
extension APIError {
    init(httpStatusCode: Int, message: String? = nil) {
        switch httpStatusCode {
        case 400:
            self = .badRequest(message)
        case 401:
            self = .unauthorized
        case 402:
            self = .paymentRequired
        case 403:
            self = .forbidden
        case 404:
            self = .notFound
        case 422:
            self = .validationError([message].compactMap { $0 })
        case 429:
            self = .rateLimitExceeded
        case 500:
            self = .internalServerError
        case 502:
            self = .badGateway
        case 503:
            self = .serviceUnavailable
        default:
            self = .unknown(message)
        }
    }
}

// MARK: - APIError + Equatable
extension APIError {
    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.noInternetConnection, .noInternetConnection),
             (.requestTimeout, .requestTimeout),
             (.serverUnavailable, .serverUnavailable),
             (.invalidURL, .invalidURL),
             (.unauthorized, .unauthorized),
             (.forbidden, .forbidden),
             (.tokenExpired, .tokenExpired),
             (.invalidCredentials, .invalidCredentials),
             (.notFound, .notFound),
             (.rateLimitExceeded, .rateLimitExceeded),
             (.paymentRequired, .paymentRequired),
             (.internalServerError, .internalServerError),
             (.serviceUnavailable, .serviceUnavailable),
             (.badGateway, .badGateway),
             (.imageProcessingFailed, .imageProcessingFailed),
             (.unsupportedImageFormat, .unsupportedImageFormat),
             (.imageTooLarge, .imageTooLarge),
             (.aiQuotaExceeded, .aiQuotaExceeded),
             (.modelNotAvailable, .modelNotAvailable),
             (.decodingError, .decodingError),
             (.encodingError, .encodingError),
             (.invalidResponse, .invalidResponse),
             (.missingData, .missingData),
             (.subscriptionRequired, .subscriptionRequired),
             (.designLimitReached, .designLimitReached),
             (.invalidDesignParameters, .invalidDesignParameters),
             (.duplicateRequest, .duplicateRequest):
            return true
        case (.badRequest(let lhsMessage), .badRequest(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.validationError(let lhsErrors), .validationError(let rhsErrors)):
            return lhsErrors == rhsErrors
        case (.aiServiceError(let lhsMessage), .aiServiceError(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.unknown(let lhsMessage), .unknown(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.networkError(let lhsError), .networkError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
