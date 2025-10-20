//
//  FirebaseError.swift
//  DreamHomeAI
//
//  Created by Huy on 14/10/25.
//
import Foundation

enum FirebaseError: Error, LocalizedError {
    case profileNotFound
    case purchaseNotFound
    case noCurrentProfile
    case insufficientCredits
    case networkError
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .profileNotFound: return "Profile not found"
        case .purchaseNotFound: return "Purchase not found"
        case .noCurrentProfile: return "No current profile available"
        case .insufficientCredits: return "Insufficient credits"
        case .networkError: return "Network error occurred"
        case .invalidData: return "Invalid data format"
        }
    }
}
