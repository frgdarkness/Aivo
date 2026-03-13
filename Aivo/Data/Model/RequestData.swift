//
//  RequestData.swift
//  Aivo
//
//  Created by AI Assistant
//

import Foundation

struct RequestData: Codable, Identifiable {
    let id: String
    let requestType: RequestType
    let time: Date
    let creditCost: Int
    
    init(id: String = UUID().uuidString, requestType: RequestType, time: Date = Date(), creditCost: Int? = nil) {
        self.id = id
        self.requestType = requestType
        self.time = time
        self.creditCost = creditCost ?? requestType.creditCost
    }

    // MARK: - Migration Support
    
    enum CodingKeys: String, CodingKey {
        case id, requestType, time, creditCost
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        requestType = try container.decode(RequestType.self, forKey: .requestType)
        time = try container.decode(Date.self, forKey: .time)
        // Nếu không có creditCost (data cũ), dùng giá trị default từ requestType
        creditCost = try container.decodeIfPresent(Int.self, forKey: .creditCost) ?? requestType.creditCost
    }
}

