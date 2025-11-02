//
//  KeychainManager.swift
//  DreamHomeAI
//
//  Created by Huy on 14/10/25.
//
import Foundation
import Security

final class KeychainManager {
    static let shared = KeychainManager()
    private let service = "com.dreamhome.profile"
    private let profileIDKey = "profileID"
    private let processedTransactionIDsKey = "ProcessedTransactionIDs"
    private let creditsKey = "Credits"
    private let lastBonusDateKey = "LastBonusCreditDate"
    private init() {}
    
    func saveProfileID(_ profileID: String) {
        guard let data = profileID.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: profileIDKey,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func getProfileID() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: profileIDKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let id = String(data: data, encoding: .utf8) else { return nil }
        return id
    }
    
    func deleteProfileID() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: profileIDKey
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Processed Transaction IDs (Keychain storage for persistence across reinstalls)
    
    func saveProcessedTransactionIDs(_ ids: [String]) {
        guard let data = try? JSONEncoder().encode(ids) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: processedTransactionIDsKey,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func getProcessedTransactionIDs() -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: processedTransactionIDsKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let ids = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return ids
    }
    
    func deleteProcessedTransactionIDs() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: processedTransactionIDsKey
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    func clearAllKeychainData() {
        // Delete all items for this service
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Credits Storage
    
    func saveCredits(_ credits: Int) {
        guard let data = String(credits).data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: creditsKey,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
        Logger.d("KeychainManager: Saved credits=\(credits) to Keychain")
    }
    
    func getCredits() -> Int? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: creditsKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let creditsString = String(data: data, encoding: .utf8),
              let credits = Int(creditsString) else {
            return nil
        }
        Logger.d("KeychainManager: Loaded credits=\(credits) from Keychain")
        return credits
    }
    
    func deleteCredits() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: creditsKey
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Last Bonus Date Storage
    
    func saveLastBonusDate(_ date: Date) {
        let timestamp = date.timeIntervalSince1970
        guard let data = String(timestamp).data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: lastBonusDateKey,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
        Logger.d("KeychainManager: Saved lastBonusDate=\(date) to Keychain")
    }
    
    func getLastBonusDate() -> Date? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: lastBonusDateKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let timestampString = String(data: data, encoding: .utf8),
              let timestamp = Double(timestampString) else {
            return nil
        }
        let date = Date(timeIntervalSince1970: timestamp)
        Logger.d("KeychainManager: Loaded lastBonusDate=\(date) from Keychain")
        return date
    }
    
    func deleteLastBonusDate() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: lastBonusDateKey
        ]
        SecItemDelete(query as CFDictionary)
    }
}
