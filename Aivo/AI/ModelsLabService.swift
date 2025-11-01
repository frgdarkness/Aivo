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
    
    // Timeout configuration
    private let requestTimeout: TimeInterval = 200.0  // 60 seconds
    private let fetchTimeout: TimeInterval = 30.0    // 30 seconds for fetch requests
    
    private init() {
        Logger.i("Initializing ModelsLabService")
        self.apiKey = "q42Xos0qPPrZuwBiH8fmJLv4c5aH4XFd0MQGEIo1nFPiruTYP0fFIFcznqcL"
        Logger.d("API Key configured: \(apiKey.prefix(10))...")
    }
    
    // MARK: - Voice Cover API
    func voiceCover(audioUrl: String, modelID: String, language: String = "english") async throws -> VoiceCoverResponse {
        Logger.i("🎤 Starting voice cover request")
        Logger.d("Parameters - audioUrl: \(audioUrl)")
        Logger.d("Parameters - modelID: \(modelID)")
        Logger.d("Parameters - language: \(language)")

        guard let url = URL(string: "\(baseURL)/voice/voice_cover") else {
            Logger.e("❌ Invalid URL: \(baseURL)/voice/voice_cover")
            throw ModelsLabError.invalidURL
        }

        Logger.d("📡 Request URL: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.timeoutInterval = requestTimeout

        Logger.d("⏱️ Request timeout set to: \(requestTimeout) seconds")

        let requestBody: [String: Any] = [
            "init_audio": audioUrl,
            "model_id": modelID,
            "language": language,
            "key": apiKey
        ]

        Logger.d("📦 Request body: \(requestBody)")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            Logger.d("✅ Request body serialized successfully")
        } catch {
            Logger.e("❌ Error serializing request body: \(error)")
            throw ModelsLabError.invalidRequestBody
        }

        let maxAttempts = 5
        let retryDelayNs: UInt64 = 2_000_000_000 // 2 seconds

        for attempt in 1...maxAttempts {
            Logger.i("🚀 Sending voice cover request (attempt \(attempt)/\(maxAttempts))...")
            let startTime = Date()

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                let duration = Date().timeIntervalSince(startTime)

                Logger.i("📥 Response received in \(String(format: "%.2f", duration)) seconds")
                Logger.d("📊 Response data size: \(data.count) bytes")

                guard let httpResponse = response as? HTTPURLResponse else {
                    Logger.e("❌ Invalid HTTP response type")
                    throw ModelsLabError.invalidResponse
                }

                Logger.d("📈 HTTP Status Code: \(httpResponse.statusCode)")
                Logger.d("📋 Response Headers: \(httpResponse.allHeaderFields)")

                guard httpResponse.statusCode == 200 else {
                    Logger.e("❌ HTTP Error: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        Logger.e("📄 Error Response Body: \(responseString)")
                    }
                    throw ModelsLabError.httpError(httpResponse.statusCode)
                }

                if let responseString = String(data: data, encoding: .utf8) {
                    Logger.d("📄 Raw API Response: \(responseString)")
                }

                do {
                    let voiceCoverResponse = try JSONDecoder().decode(VoiceCoverResponse.self, from: data)
                    let statusLower = voiceCoverResponse.status.lowercased()
                    let messageLower = (voiceCoverResponse.message ?? "").lowercased()
                    Logger.i("✅ Voice cover response decoded successfully")
                    Logger.d("📋 Response Status: \(voiceCoverResponse.status)")
                    Logger.d("🆔 Response ID: \(voiceCoverResponse.id ?? -1)")
                    Logger.d("💬 Response Message: \(voiceCoverResponse.message ?? "No message")")
                    Logger.d("⏳ ETA: \(voiceCoverResponse.eta ?? -1) seconds")

                    let shouldRetry = (statusLower == "failed") && (
                        messageLower.contains("try again") ||
                        messageLower.contains("something went wrong")
                    )

                    if shouldRetry && attempt < maxAttempts {
                        Logger.w("⚠️ Retryable server error detected. Retrying in 2s (attempt \(attempt+1)/\(maxAttempts))...")
                        try? await Task.sleep(nanoseconds: retryDelayNs)
                        continue
                    }

                    return voiceCoverResponse
                } catch {
                    Logger.e("❌ Error decoding VoiceCoverResponse: \(error)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        Logger.e("📄 Failed to decode response: \(responseString)")
                    }
                    throw ModelsLabError.decodingError(error)
                }
            } catch let error as NSError {
                Logger.e("❌ Network request failed (attempt \(attempt))")
                Logger.e("🔍 Error Domain: \(error.domain)")
                Logger.e("🔍 Error Code: \(error.code)")
                Logger.e("🔍 Error Description: \(error.localizedDescription)")
                Logger.e("🔍 Error UserInfo: \(error.userInfo)")

                if error.code == NSURLErrorTimedOut {
                    Logger.e("⏰ Request timed out after \(requestTimeout) seconds")
                    if attempt < maxAttempts {
                        Logger.w("⚠️ Retrying in 2s due to timeout...")
                        try? await Task.sleep(nanoseconds: retryDelayNs)
                        continue
                    }
                    throw ModelsLabError.requestTimeout
                } else {
                    if attempt < maxAttempts {
                        Logger.w("⚠️ Network error. Retrying in 2s...")
                        try? await Task.sleep(nanoseconds: retryDelayNs)
                        continue
                    }
                    Logger.e("🌐 Network error: \(error)")
                    throw ModelsLabError.networkError(error)
                }
            }
        }

        // Should never reach here
        throw ModelsLabError.invalidResponse
    }
    
    // MARK: - Fetch Voice Result
    func fetchVoiceResult(id: Int) async -> String? {
        Logger.i("🔄 Starting fetch voice result for ID: \(id)")
        
        let maxRetries = 30
        let retryInterval: TimeInterval = 10.0
        
        Logger.d("📊 Max retries: \(maxRetries)")
        Logger.d("⏱️ Retry interval: \(retryInterval) seconds")
        
        for attempt in 1...maxRetries {
            // Check cancellation at start of each loop iteration
            try? Task.checkCancellation()
            if Task.isCancelled {
                Logger.i("⚠️ Fetch cancelled at attempt \(attempt)")
                return nil
            }
            
            Logger.d("🔄 Fetch attempt \(attempt)/\(maxRetries)")
            
            do {
                let result = try await performFetchRequest(id: id)
                
                // Check cancellation after API call
                try Task.checkCancellation()
                
                Logger.d("📋 Fetch response status: \(result.status)")
                Logger.d("📋 Fetch response ID: \(result.id ?? -1)")
                Logger.d("📋 Fetch response message: \(result.message ?? "No message")")
                Logger.d("📋 Output count: \(result.output.count)")
                
                if result.status == "success" && !result.output.isEmpty {
                    let outputUrl = result.output.first!
                    Logger.i("✅ Fetch successful! Output URL: \(outputUrl)")
                    return outputUrl
                } else if result.status == "processing" {
                    Logger.d("⏳ Still processing...")
                    if attempt < maxRetries {
                        Logger.d("⏱️ Waiting \(retryInterval) seconds before retry...")
                        // Check cancellation before sleep
                        try Task.checkCancellation()
                        try await Task.sleep(nanoseconds: UInt64(retryInterval * 1_000_000_000))
                        // Check cancellation after sleep
                        try Task.checkCancellation()
                        continue
                    } else {
                        Logger.w("⚠️ Max retries reached, still processing")
                        return nil
                    }
                } else {
                    Logger.e("❌ Error status: \(result.status)")
                    Logger.e("💬 Error message: \(result.message ?? "No message")")
                    return nil
                }
            } catch is CancellationError {
                Logger.i("⚠️ Fetch cancelled during attempt \(attempt)")
                return nil
            } catch {
                // Check cancellation before handling error
                if Task.isCancelled {
                    Logger.i("⚠️ Fetch cancelled, stopping retries")
                    return nil
                }
                
                Logger.e("❌ Fetch attempt \(attempt) failed: \(error)")
                if attempt < maxRetries {
                    Logger.d("⏱️ Waiting \(retryInterval) seconds before retry...")
                    // Check cancellation before sleep
                    try? Task.checkCancellation()
                    if Task.isCancelled {
                        Logger.i("⚠️ Fetch cancelled, stopping retries")
                        return nil
                    }
                    try? await Task.sleep(nanoseconds: UInt64(retryInterval * 1_000_000_000))
                } else {
                    Logger.e("❌ Max retries reached, giving up")
                    return nil
                }
            }
        }
        
        Logger.e("❌ All fetch attempts failed")
        return nil
    }
    
    private func performFetchRequest(id: Int) async throws -> VoiceFetchResponse {
        Logger.d("🔍 Performing fetch request for ID: \(id)")
        
        guard let url = URL(string: "\(fetchBaseURL)/voice/fetch/\(id)") else {
            Logger.e("❌ Invalid fetch URL: \(fetchBaseURL)/voice/fetch/\(id)")
            throw ModelsLabError.invalidURL
        }
        
        Logger.d("📡 Fetch URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.timeoutInterval = fetchTimeout
        
        Logger.d("⏱️ Fetch timeout set to: \(fetchTimeout) seconds")
        
        let requestBody: [String: Any] = [
            "key": apiKey
        ]
        
        Logger.d("📦 Fetch request body: \(requestBody)")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            Logger.d("✅ Fetch request body serialized successfully")
        } catch {
            Logger.e("❌ Error serializing fetch request body: \(error)")
            throw ModelsLabError.invalidRequestBody
        }
        
        Logger.d("🚀 Sending fetch request...")
        let startTime = Date()
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let duration = Date().timeIntervalSince(startTime)
            
            Logger.d("📥 Fetch response received in \(String(format: "%.2f", duration)) seconds")
            Logger.d("📊 Fetch response data size: \(data.count) bytes")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                Logger.e("❌ Invalid fetch HTTP response type")
                throw ModelsLabError.invalidResponse
            }
            
            Logger.d("📈 Fetch HTTP Status Code: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                Logger.e("❌ Fetch HTTP Error: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    Logger.e("📄 Fetch Error Response Body: \(responseString)")
                }
                throw ModelsLabError.httpError(httpResponse.statusCode)
            }
            
            // Log raw response data for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                Logger.d("📄 Raw Fetch API Response: \(responseString)")
            }
            
            do {
                let fetchResponse = try JSONDecoder().decode(VoiceFetchResponse.self, from: data)
                Logger.d("✅ Fetch response decoded successfully")
                return fetchResponse
            } catch {
                Logger.e("❌ Error decoding VoiceFetchResponse: \(error)")
                if let responseString = String(data: data, encoding: .utf8) {
                    Logger.e("📄 Failed to decode fetch response: \(responseString)")
                }
                throw ModelsLabError.decodingError(error)
            }
        } catch let error as NSError {
            Logger.e("❌ Fetch network request failed")
            Logger.e("🔍 Error Domain: \(error.domain)")
            Logger.e("🔍 Error Code: \(error.code)")
            Logger.e("🔍 Error Description: \(error.localizedDescription)")
            
            if error.code == NSURLErrorTimedOut {
                Logger.e("⏰ Fetch request timed out after \(fetchTimeout) seconds")
                throw ModelsLabError.requestTimeout
            } else {
                Logger.e("🌐 Fetch network error: \(error)")
                throw ModelsLabError.networkError(error)
            }
        }
    }
    
    // MARK: - File Upload to tmpfiles.org
    func uploadFileToTmpFiles(fileData: Data, fileName: String) async throws -> String {
        Logger.i("📤 Uploading file to tmpfiles.org")
        Logger.d("📤 File name: \(fileName)")
        Logger.d("📤 File size: \(fileData.count) bytes")
        
        guard let url = URL(string: "https://tmpfiles.org/api/v1/upload") else {
            Logger.e("❌ Invalid tmpfiles URL")
            throw ModelsLabError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ModelsLabError.invalidResponse
            }
            
            Logger.d("📈 Upload HTTP Status: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                Logger.e("❌ Upload failed with status: \(httpResponse.statusCode)")
                throw ModelsLabError.httpError(httpResponse.statusCode)
            }
            
            // Parse response
            if let responseString = String(data: data, encoding: .utf8) {
                Logger.d("📄 Upload response: \(responseString)")
                
                // Extract URL from response
                // Response format: {"status": "success", "data": {"url": "https://tmpfiles.org/..."}}
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataDict = json["data"] as? [String: Any],
                   let urlString = dataDict["url"] as? String {
                    
                    // Normalize URL to direct download format
                    // http://tmpfiles.org/5359783/file.mp3 -> http://tmpfiles.org/dl/5359783/file.mp3
                    let normalizedURL = urlString.replacingOccurrences(of: "/tmpfiles.org/", with: "/tmpfiles.org/dl/")
                    
                    Logger.i("✅ File uploaded successfully!")
                    Logger.d("🔗 Original URL: \(urlString)")
                    Logger.d("🔗 Normalized URL: \(normalizedURL)")
                    return normalizedURL
                }
            }
            
            Logger.e("❌ Failed to parse upload response")
            throw ModelsLabError.invalidResponse
            
        } catch {
            Logger.e("❌ Upload error: \(error)")
            throw ModelsLabError.networkError(error)
        }
    }
    
    // MARK: - Convenience Method With File Upload
    func processVoiceCoverWithFile(fileData: Data, fileName: String, modelID: String) async -> String? {
        Logger.i("🎵 Starting voice cover process with file upload")
        Logger.d("🎵 File name: \(fileName)")
        Logger.d("🎵 File size: \(fileData.count) bytes")
        Logger.d("🎵 Model ID: \(modelID)")
        
        do {
            // Check cancellation before starting
            try Task.checkCancellation()
            
            // Step 1: Upload file to tmpfiles.org
            Logger.i("📤 Step 1: Uploading file to tmpfiles.org...")
            let uploadedUrl = try await uploadFileToTmpFiles(fileData: fileData, fileName: fileName)
            
            // Check cancellation after upload
            try Task.checkCancellation()
            
            Logger.i("✅ Step 1 completed! Uploaded URL: \(uploadedUrl)")
            
            // Step 2: Process voice cover with uploaded URL
            Logger.i("📤 Step 2: Processing voice cover with uploaded URL...")
            let resultUrl = await processVoiceCover(audioUrl: uploadedUrl, modelID: modelID)
            
            if let url = resultUrl {
                Logger.i("🎉 Complete voice cover process with file successful!")
                Logger.i("🔗 Final result URL: \(url)")
            } else {
                Logger.e("❌ Complete voice cover process with file failed")
            }
            
            return resultUrl
            
        } catch is CancellationError {
            Logger.i("⚠️ Voice cover with file was cancelled")
            return nil
        } catch {
            // Check cancellation before handling error
            if Task.isCancelled {
                Logger.i("⚠️ Task cancelled, ignoring error")
                return nil
            }
            Logger.e("❌ Voice cover with file failed: \(error)")
            Logger.e("🔍 Error details: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Convenience Method
    func processVoiceCover(audioUrl: String, modelID: String) async -> String? {
        Logger.i("🎵 Starting complete voice cover process")
        Logger.d("🎵 Audio URL: \(audioUrl)")
        Logger.d("🎵 Model ID: \(modelID)")
        
        do {
            // Check cancellation before starting
            try Task.checkCancellation()
            
            Logger.i("📤 Step 1: Sending voice cover request...")
            let voiceCoverResponse = try await voiceCover(audioUrl: audioUrl, modelID: modelID)
            
            // Check cancellation after API call
            try Task.checkCancellation()
            
            guard let id = voiceCoverResponse.id else {
                Logger.e("❌ No ID received from voice cover response")
                Logger.e("📋 Response status: \(voiceCoverResponse.status)")
                Logger.e("💬 Response message: \(voiceCoverResponse.message ?? "No message")")
                return nil
            }
            
            Logger.i("✅ Step 1 completed! Received ID: \(id)")
            Logger.i("📤 Step 2: Starting to fetch result...")
            
            // Start fetching the result
            let resultUrl = await fetchVoiceResult(id: id)
            
            // Check cancellation after fetch
            try Task.checkCancellation()
            
            if let url = resultUrl {
                Logger.i("🎉 Complete voice cover process successful!")
                Logger.i("🔗 Final result URL: \(url)")
            } else {
                Logger.e("❌ Complete voice cover process failed - no result URL")
            }
            
            return resultUrl
        } catch is CancellationError {
            Logger.i("⚠️ Voice cover process was cancelled")
            return nil
        } catch {
            // Check cancellation before handling error
            if Task.isCancelled {
                Logger.i("⚠️ Task cancelled, ignoring error")
                return nil
            }
            Logger.e("❌ Voice cover request failed: \(error)")
            Logger.e("🔍 Error details: \(error.localizedDescription)")
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
    case requestTimeout
    case networkError(Error)
    
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
        case .requestTimeout:
            return "Request timed out"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
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
