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
    
    init(id: String = UUID().uuidString, requestType: RequestType, time: Date = Date()) {
        self.id = id
        self.requestType = requestType
        self.time = time
    }
}

