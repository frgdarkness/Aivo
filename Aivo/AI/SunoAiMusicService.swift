import Foundation

// MARK: - Suno AI Music Service
class SunoAiMusicService: ObservableObject {
    static let shared = SunoAiMusicService()
    
    private let baseURL = "https://api.sunoapi.org/api/v1"
    private let apiKey: String
    
    private init() {
        // TODO: Load API key from secure storage or configuration
        self.apiKey = "b2be57d4918711da650ba24b053bb22a" // Replace with actual API key
    }
    
    // MARK: - Generate Music
    func generateMusic(
        prompt: String,
        style: String? = nil,
        title: String? = nil,
        customMode: Bool = false,
        instrumental: Bool = false,
        model: SunoModel = .V5,
        negativeTags: String? = nil,
        vocalGender: VocalGender? = nil,
        styleWeight: Double? = nil,
        weirdnessConstraint: Double? = nil,
        audioWeight: Double? = nil,
        callBackUrl: String? = nil
    ) async throws -> String {
        
        print("🎵 [SunoAI] Starting music generation...")
        print("🎵 [SunoAI] Prompt: \(prompt)")
        print("🎵 [SunoAI] Model: \(model.rawValue)")
        print("🎵 [SunoAI] Custom Mode: \(customMode)")
        print("🎵 [SunoAI] Instrumental: \(instrumental)")
        
        let url = URL(string: "\(baseURL)/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = SunoGenerateRequest(
            prompt: prompt,
            style: style,
            title: title,
            customMode: customMode,
            instrumental: instrumental,
            model: model,
            negativeTags: negativeTags,
            vocalGender: vocalGender,
            styleWeight: styleWeight,
            weirdnessConstraint: weirdnessConstraint,
            audioWeight: audioWeight,
            callBackUrl: "https://api.example.com/callback"
        )
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
            
            print("🎵 [SunoAI] Request URL: \(url)")
            print("🎵 [SunoAI] Request body: \(String(data: jsonData, encoding: .utf8) ?? "Unable to convert to string")")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            print("🎵 [SunoAI] Response received")
            print("🎵 [SunoAI] Response data: \(String(data: data, encoding: .utf8) ?? "Unable to convert to string")")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [SunoAI] Invalid response type")
                throw SunoError.invalidResponse
            }
            
            print("🎵 [SunoAI] HTTP Status: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                print("❌ [SunoAI] HTTP Error: \(httpResponse.statusCode)")
                throw SunoError.httpError(httpResponse.statusCode)
            }
            
            // Try to decode response with detailed error handling
            do {
                let generateResponse = try JSONDecoder().decode(SunoGenerateResponse.self, from: data)
                print("🎵 [SunoAI] Decoded response successfully")
                print("🎵 [SunoAI] Response code: \(generateResponse.code)")
                print("🎵 [SunoAI] Response message: \(generateResponse.msg)")
                
                guard generateResponse.code == 200 else {
                    print("❌ [SunoAI] API Error: \(generateResponse.msg)")
                    throw SunoError.apiError(generateResponse.msg)
                }
                
                guard let data = generateResponse.data else {
                    print("❌ [SunoAI] No data in response")
                    throw SunoError.invalidResponse
                }
                
                print("🎵 [SunoAI] Task ID: \(data.taskId)")
                return data.taskId
                
            } catch let decodingError as DecodingError {
                print("❌ [SunoAI] Decoding Error: \(decodingError)")
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("❌ [SunoAI] Key not found: \(key), context: \(context)")
                case .valueNotFound(let type, let context):
                    print("❌ [SunoAI] Value not found: \(type), context: \(context)")
                case .typeMismatch(let type, let context):
                    print("❌ [SunoAI] Type mismatch: \(type), context: \(context)")
                case .dataCorrupted(let context):
                    print("❌ [SunoAI] Data corrupted: \(context)")
                @unknown default:
                    print("❌ [SunoAI] Unknown decoding error")
                }
                throw decodingError
            }
            
        } catch {
            print("❌ [SunoAI] Generate music error: \(error)")
            throw error
        }
    }
    
    // MARK: - Get Music Generation Details
    func getMusicGenerationDetails(taskId: String) async throws -> SunoTaskDetails {
        print("🔍 [SunoAI] Getting music generation details for task: \(taskId)")
        
        let url = URL(string: "\(baseURL)/generate/record-info?taskId=\(taskId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        print("🔍 [SunoAI] Request URL: \(url)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            print("🔍 [SunoAI] Response received")
            print("🔍 [SunoAI] Response data: \(String(data: data, encoding: .utf8) ?? "Unable to convert to string")")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [SunoAI] Invalid response type")
                throw SunoError.invalidResponse
            }
            
            print("🔍 [SunoAI] HTTP Status: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                print("❌ [SunoAI] HTTP Error: \(httpResponse.statusCode)")
                throw SunoError.httpError(httpResponse.statusCode)
            }
            
            // Try to decode response with detailed error handling
            do {
                let detailsResponse = try JSONDecoder().decode(SunoDetailsResponse.self, from: data)
                print("🔍 [SunoAI] Decoded response successfully")
                print("🔍 [SunoAI] Response code: \(detailsResponse.code)")
                print("🔍 [SunoAI] Response message: \(detailsResponse.msg)")
                
                guard detailsResponse.code == 200 else {
                    print("❌ [SunoAI] API Error: \(detailsResponse.msg)")
                    throw SunoError.apiError(detailsResponse.msg)
                }
                
                guard let data = detailsResponse.data else {
                    print("❌ [SunoAI] No data in response")
                    throw SunoError.invalidResponse
                }
                
                print("🔍 [SunoAI] Task status: \(data.status.rawValue)")
                return data
                
            } catch let decodingError as DecodingError {
                print("❌ [SunoAI] Decoding Error: \(decodingError)")
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("❌ [SunoAI] Key not found: \(key), context: \(context)")
                case .valueNotFound(let type, let context):
                    print("❌ [SunoAI] Value not found: \(type), context: \(context)")
                case .typeMismatch(let type, let context):
                    print("❌ [SunoAI] Type mismatch: \(type), context: \(context)")
                case .dataCorrupted(let context):
                    print("❌ [SunoAI] Data corrupted: \(context)")
                @unknown default:
                    print("❌ [SunoAI] Unknown decoding error")
                }
                throw decodingError
            }
            
        } catch {
            print("❌ [SunoAI] Error getting music details: \(error)")
            throw error
        }
    }
    
    // MARK: - Complete Music Generation Flow
    func generateMusicWithRetry(
        prompt: String,
        style: String? = nil,
        title: String? = nil,
        customMode: Bool = false,
        instrumental: Bool = false,
        model: SunoModel = .V5,
        negativeTags: String? = nil,
        vocalGender: VocalGender? = nil,
        styleWeight: Double? = nil,
        weirdnessConstraint: Double? = nil,
        audioWeight: Double? = nil,
        callBackUrl: String? = nil
    ) async throws -> [SunoData] {
        
        print("🚀 [SunoAI] Starting complete music generation flow...")
        
        // Step 1: Generate music
        print("🚀 [SunoAI] Step 1: Generating music...")
        let taskId = try await generateMusic(
            prompt: prompt,
            style: style,
            title: title,
            customMode: customMode,
            instrumental: instrumental,
            model: model,
            negativeTags: negativeTags,
            vocalGender: vocalGender,
            styleWeight: styleWeight,
            weirdnessConstraint: weirdnessConstraint,
            audioWeight: audioWeight,
            callBackUrl: callBackUrl
        )
        
        print("🚀 [SunoAI] Step 1 completed. Task ID: \(taskId)")
        
        // Step 2: Wait 20 seconds before first check
        print("🚀 [SunoAI] Step 2: Waiting 20 seconds before first check...")
        try await Task.sleep(nanoseconds: 20_000_000_000) // 20 seconds
        print("🚀 [SunoAI] Step 2 completed. Starting polling...")
        
        // Step 3: Poll for results (20 times, every 20 seconds)
        let maxRetries = 20
        let retryInterval: UInt64 = 20_000_000_000 // 20 seconds in nanoseconds
        
        for attempt in 1...maxRetries {
            print("🚀 [SunoAI] Step 3: Polling attempt \(attempt)/\(maxRetries)...")
            
            do {
                let taskDetails = try await getMusicGenerationDetails(taskId: taskId)
                
                print("🚀 [SunoAI] Polling result - Status: \(taskDetails.status.rawValue)")
                
                switch taskDetails.status {
                case .SUCCESS:
                    let sunoData = taskDetails.response?.sunoData ?? []
                    print("🚀 [SunoAI] SUCCESS! Generated \(sunoData.count) songs")
                    for (index, song) in sunoData.enumerated() {
                        print("🚀 [SunoAI] Song \(index + 1): \(song.title) - Duration: \(song.duration)s")
                    }
                    return sunoData
                    
                case .PENDING, .TEXT_SUCCESS, .FIRST_SUCCESS:
                    print("⏳ [SunoAI] Still processing... Status: \(taskDetails.status.rawValue)")
                    if attempt < maxRetries {
                        print("⏳ [SunoAI] Waiting 20 seconds before next attempt...")
                        try await Task.sleep(nanoseconds: retryInterval)
                    }
                    
                case .CREATE_TASK_FAILED, .GENERATE_AUDIO_FAILED, .CALLBACK_EXCEPTION, .SENSITIVE_WORD_ERROR:
                    print("❌ [SunoAI] Generation failed with status: \(taskDetails.status.rawValue)")
                    throw SunoError.generationFailed(taskDetails.status.rawValue)
                }
                
            } catch {
                print("❌ [SunoAI] Polling attempt \(attempt) failed: \(error)")
                if attempt == maxRetries {
                    print("❌ [SunoAI] All polling attempts failed")
                    throw error
                }
                // Wait before retry
                print("⏳ [SunoAI] Continuing to next attempt...")
                try await Task.sleep(nanoseconds: retryInterval)
            }
        }
        
        // If we get here, max retries exceeded
        print("❌ [SunoAI] Timeout exceeded after \(maxRetries) attempts")
        throw SunoError.timeoutExceeded
    }
}

// MARK: - Convenience Methods

// MARK: - Convenience Methods
extension SunoAiMusicService {
    
    /// Simple music generation with minimal parameters
    func generateSimpleMusic(prompt: String, instrumental: Bool = false) async throws -> [SunoData] {
        return try await generateMusicWithRetry(
            prompt: prompt,
            customMode: false,
            instrumental: instrumental,
            model: .V5
        )
    }
    
    /// Custom music generation with full control
    func generateCustomMusic(
        prompt: String,
        style: String,
        title: String,
        instrumental: Bool = false,
        model: SunoModel = .V5
    ) async throws -> [SunoData] {
        return try await generateMusicWithRetry(
            prompt: prompt,
            style: style,
            title: title,
            customMode: false,
            instrumental: instrumental,
            model: model
        )
    }
}
