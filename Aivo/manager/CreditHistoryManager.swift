//
//  CreditHistoryManager.swift
//  Aivo
//
//  Created by AI Assistant
//

import Foundation

final class CreditHistoryManager: ObservableObject {
    static let shared = CreditHistoryManager()
    
    @Published var history: [RequestData] = []
    
    private let historyKey = "CreditUsageHistory"
    private let maxHistoryCount = 500 // Giới hạn số lượng history
    
    private init() {
        loadHistory()
    }
    
    // MARK: - History Management
    
    func addRequest(_ requestType: RequestType, cost: Int? = nil) {
        let requestData = RequestData(requestType: requestType, time: Date(), creditCost: cost)
        history.insert(requestData, at: 0) // Thêm vào đầu list
        
        // Giới hạn số lượng history
        if history.count > maxHistoryCount {
            history = Array(history.prefix(maxHistoryCount))
        }
        
        saveHistory()
        Logger.d("📝 [CreditHistory] Added request: \(requestType.displayName) at \(requestData.time)")
    }
    
    func saveHistory() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .secondsSince1970
            let data = try encoder.encode(history)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            Logger.e("❌ [CreditHistory] Failed to save history: \(error)")
        }
    }
    
    func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else {
            Logger.d("📱 [CreditHistory] No history found")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            history = try decoder.decode([RequestData].self, from: data)
            Logger.d("📱 [CreditHistory] Loaded \(history.count) history items")
        } catch {
            Logger.e("❌ [CreditHistory] Failed to load history: \(error)")
            history = []
        }
    }
    
    func clearHistory() {
        history = []
        UserDefaults.standard.removeObject(forKey: historyKey)
        Logger.d("🗑️ [CreditHistory] History cleared")
    }
}

