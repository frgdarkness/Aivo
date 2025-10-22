import Foundation
import Combine

// MARK: - Response Models
struct VoiceCoverResponse: Codable {
    let status: String
    let tip: String?
    let eta: Int?
    let message: String?
    let fetchResult: String?
    let id: Int?
    let output: [String]
    let futureLinks: [String]?
    let proxyLinks: [String]?
    let audioTime: Double?
    let meta: VoiceCoverMeta?
    
    enum CodingKeys: String, CodingKey {
        case status, tip, eta, message, id, output, meta
        case fetchResult = "fetch_result"
        case futureLinks = "future_links"
        case proxyLinks = "proxy_links"
        case audioTime = "audio_time"
    }
}

struct VoiceCoverMeta: Codable {
    let algorithm: String?
    let backupVoiceVolumeDelta: Int?
    let base64: String?
    let damping: Double?
    let dryness: Double?
    let emotion: String?
    let filename: String?
    let hopLength: Int?
    let metaId: String?
    let inputSoundClip: String?
    let instrumentVolumeDelta: Int?
    let isYoutube: Bool?
    let language: String?
    let leadVoiceVolumeDelta: Int?
    let mix: Double?
    let modelId: String?
    let originality: Double?
    let paths: String?
    let pitch: String?
    let radius: Int?
    let rate: Double?
    let reverbSize: Double?
    let seed: Int?
    let speed: Int?
    let temp: String?
    let trackId: String?
    let webhook: String?
    let wetness: Double?
    
    enum CodingKeys: String, CodingKey {
        case algorithm, base64, damping, dryness, emotion, filename, language, mix, originality, paths, pitch, radius, rate, seed, speed, temp, webhook, wetness
        case backupVoiceVolumeDelta = "backup_voice_volume_delta"
        case hopLength = "hop_length"
        case metaId = "id"
        case inputSoundClip = "input_sound_clip"
        case instrumentVolumeDelta = "instrument_volume_delta"
        case isYoutube = "is_youtube"
        case leadVoiceVolumeDelta = "lead_voice_volume_delta"
        case modelId = "model_id"
        case reverbSize = "reverb_size"
        case trackId = "track_id"
    }
}

struct VoiceFetchResponse: Codable {
    let status: String
    let id: Int?
    let message: String?
    let output: [String]
    let proxyLinks: [String]?
    let tip: String?
    
    enum CodingKeys: String, CodingKey {
        case status, id, message, output, tip
        case proxyLinks = "proxy_links"
    }
}

// MARK: - ModelsLabService
class ModelsLabService: ObservableObject {
    static let shared = ModelsLabService()
    
    private let baseURL = "https://modelslab.com/api/v6"
    private let fetchBaseURL = "https://modelslab.com/api/v7"
    private let apiKey: String
    
    private init() {
        // TODO: Add your API key here
        self.apiKey = "q42Xos0qPPrZuwBiH8fmJLv4c5aH4XFd0MQGEIo1nFPiruTYP0fFIFcznqcL"
    }
    
    // MARK: - Voice Cover API
    func voiceCover(audioUrl: String, modelID: String, language: String = "english") async throws -> VoiceCoverResponse {
        Logger.d("voiceCover(audioUrl: \(audioUrl), modelID: \(modelID), language: \(language))")
        guard let url = URL(string: "\(baseURL)/voice/voice_cover") else {
            throw ModelsLabError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        
        let requestBody: [String: Any] = [
            "init_audio": audioUrl,
            "model_id": "trump",
            "language": "english",
            "key": apiKey
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            Logger.e("Error serializing request body: \(error)")
            throw ModelsLabError.invalidRequestBody
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            Logger.e("Error getting HTTP response")
            throw ModelsLabError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ModelsLabError.httpError(httpResponse.statusCode)
        }
        
        // Log raw response data for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            Logger.d("Raw API Response: \(responseString)")
        }
        
        do {
            let voiceCoverResponse = try JSONDecoder().decode(VoiceCoverResponse.self, from: data)
            Logger.d("Decoded Response: \(voiceCoverResponse)")
            return voiceCoverResponse
        } catch {
            Logger.e("Error decoding VoiceCoverResponse: \(error)")
            throw ModelsLabError.decodingError(error)
        }
    }
    
    // MARK: - Fetch Voice Result
    func fetchVoiceResult(id: Int) async -> String? {
        let maxRetries = 30
        let retryInterval: TimeInterval = 5.0
        
        for attempt in 1...maxRetries {
            do {
                let result = try await performFetchRequest(id: id)
                
                if result.status == "success" && !result.output.isEmpty {
                    // Return the first output URL
                    return result.output.first
                } else if result.status == "processing" {
                    // Still processing, wait and retry
                    if attempt < maxRetries {
                        try await Task.sleep(nanoseconds: UInt64(retryInterval * 1_000_000_000))
                        continue
                    } else {
                        // Max retries reached
                        return nil
                    }
                } else {
                    // Error status
                    return nil
                }
            } catch {
                print("Fetch attempt \(attempt) failed: \(error)")
                if attempt < maxRetries {
                    try? await Task.sleep(nanoseconds: UInt64(retryInterval * 1_000_000_000))
                } else {
                    return nil
                }
            }
        }
        
        return nil
    }
    
    private func performFetchRequest(id: Int) async throws -> VoiceFetchResponse {
        guard let url = URL(string: "\(fetchBaseURL)/voice/fetch/\(id)") else {
            throw ModelsLabError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        
        let requestBody: [String: Any] = [
            "key": apiKey
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            Logger.e("Error serializing request body: \(error)")
            throw ModelsLabError.invalidRequestBody
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ModelsLabError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ModelsLabError.httpError(httpResponse.statusCode)
        }
        
        // Log raw response data for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            Logger.d("Raw Fetch API Response: \(responseString)")
        }
        
        do {
            let fetchResponse = try JSONDecoder().decode(VoiceFetchResponse.self, from: data)
            Logger.d("Decoded Fetch Response: \(fetchResponse)")
            return fetchResponse
        } catch {
            Logger.e("Error decoding VoiceFetchResponse: \(error)")
            throw ModelsLabError.decodingError(error)
        }
    }
    
    // MARK: - Convenience Method
    func processVoiceCover(audioUrl: String, modelID: String) async -> String? {
        do {
            let voiceCoverResponse = try await voiceCover(audioUrl: audioUrl, modelID: modelID)
            
            guard let id = voiceCoverResponse.id else {
                print("No ID received from voice cover response")
                return nil
            }
            
            // Start fetching the result
            return await fetchVoiceResult(id: id)
        } catch {
            print("Voice cover request failed: \(error)")
            return nil
        }
    }
}

// MARK: - Error Types
enum ModelsLabError: Error, LocalizedError {
    case invalidURL
    case invalidRequestBody
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case apiKeyMissing
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidRequestBody:
            return "Invalid request body"
        case .invalidResponse:
            return "Invalid response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .apiKeyMissing:
            return "API key is missing"
        }
    }
}

// MARK: - Usage Example
/*
// Example usage:
let modelsLabService = ModelsLabService.shared

// Method 1: Step by step
Task {
    do {
        let response = try await modelsLabService.voiceCover(
            audioUrl: "https://example.com/audio.mp3",
            modelID: "vegeta"
        )
        
        if let id = response.id {
            let resultUrl = await modelsLabService.fetchVoiceResult(id: id)
            print("Final result URL: \(resultUrl ?? "Failed")")
        }
    } catch {
        print("Error: \(error)")
    }
}

// Method 2: All in one
Task {
    let resultUrl = await modelsLabService.processVoiceCover(
        audioUrl: "https://example.com/audio.mp3",
        modelID: "vegeta"
    )
    print("Final result URL: \(resultUrl ?? "Failed")")
}
*/
