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
}
