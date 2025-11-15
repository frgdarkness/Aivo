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
            
            // ✅ CRITICAL: Check raw JSON for error message BEFORE decoding
            // This prevents infinite retry loops when server returns error with artist name
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let responseData = json["data"] as? [String: Any],
               let status = responseData["status"] as? String,
               status == "SENSITIVE_WORD_ERROR" {
                let errorMsg = (responseData["errorMessage"] as? String ?? "").lowercased()
                print("❌ [SunoAI] Detected SENSITIVE_WORD_ERROR before decode: \(errorMsg)")
                
                // Check if error contains "artist name" - stop immediately
                if errorMsg.contains("artist name") {
                    print("❌ [SunoAI] Artist name detected in error message - stopping immediately")
                    throw SunoError.artistNameNotAllowed
                }
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
                    
                    // Check if error is about null sunoData and status is SENSITIVE_WORD_ERROR
                    if String(describing: type).contains("Array") && context.codingPath.contains(where: { $0.stringValue == "sunoData" }) {
                        // Try to parse raw JSON to check status
                        do {
                            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let responseData = json["data"] as? [String: Any],
                               let status = responseData["status"] as? String,
                               status == "SENSITIVE_WORD_ERROR" {
                                let errorMsg = responseData["errorMessage"] as? String ?? ""
                                print("❌ [SunoAI] Detected SENSITIVE_WORD_ERROR: \(errorMsg)")
                                if errorMsg.contains("artist name") {
                                    throw SunoError.artistNameNotAllowed
                                } else {
                                    throw SunoError.generationFailed(status)
                                }
                            }
                        } catch let sunoError as SunoError {
                            throw sunoError
                        } catch {
                            // Fall through to original error
                        }
                    }
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
        
        // Check cancellation before API call
        try Task.checkCancellation()
        
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
        
        // Check cancellation after API call
        try Task.checkCancellation()
        
        print("🚀 [SunoAI] Step 1 completed. Task ID: \(taskId)")
        
        // Step 2: Wait 20 seconds before first check
        print("🚀 [SunoAI] Step 2: Waiting 20 seconds before first check...")
        try await Task.sleep(nanoseconds: 20_000_000_000) // 20 seconds
        
        // Check cancellation after initial wait
        try Task.checkCancellation()
        
        print("🚀 [SunoAI] Step 2 completed. Starting polling...")
        
        // Step 3: Poll for results (20 times, every 20 seconds)
        let maxRetries = 20
        let retryInterval: UInt64 = 20_000_000_000 // 20 seconds in nanoseconds
        
        for attempt in 1...maxRetries {
            // Check cancellation at start of each loop iteration
            try Task.checkCancellation()
            
            print("🚀 [SunoAI] Step 3: Polling attempt \(attempt)/\(maxRetries)...")
            
            do {
                let taskDetails = try await getMusicGenerationDetails(taskId: taskId)
                
                // Check cancellation after API call
                try Task.checkCancellation()
                
                print("🚀 [SunoAI] Polling result - Status: \(taskDetails.status.rawValue)")
                
                switch taskDetails.status {
                case .SUCCESS:
                    guard let sunoData = taskDetails.response?.sunoData, !sunoData.isEmpty else {
                        print("❌ [SunoAI] No songs generated despite SUCCESS status")
                        throw SunoError.invalidResponse
                    }
                    print("🚀 [SunoAI] SUCCESS! Generated \(sunoData.count) songs")
                    for (index, song) in sunoData.enumerated() {
                        print("🚀 [SunoAI] Song \(index + 1): \(song.title) - Duration: \(song.duration)s")
                    }
                    
                    // Update modelName to "AIVO music" for all items before returning
                    let updatedSunoData = sunoData.map { song in
                        SunoData(
                            id: song.id,
                            audioUrl: song.audioUrl,
                            sourceAudioUrl: song.sourceAudioUrl,
                            streamAudioUrl: song.streamAudioUrl,
                            sourceStreamAudioUrl: song.sourceStreamAudioUrl,
                            imageUrl: song.imageUrl,
                            sourceImageUrl: song.sourceImageUrl,
                            prompt: song.prompt,
                            modelName: "AIVO music",
                            title: song.title,
                            tags: song.tags,
                            createTime: song.createTime,
                            duration: song.duration
                        )
                    }
                    
                    // Fetch timestamped lyrics for each song after generation success
                    Task {
                        await fetchTimestampedLyricsForSongs(taskId: taskId, songs: updatedSunoData)
                    }
                    
                    return updatedSunoData
                    
                case .PENDING, .TEXT_SUCCESS, .FIRST_SUCCESS:
                    print("⏳ [SunoAI] Still processing... Status: \(taskDetails.status.rawValue)")
                    if attempt < maxRetries {
                        print("⏳ [SunoAI] Waiting 20 seconds before next attempt...")
                        // Check cancellation before sleep
                        try Task.checkCancellation()
                        try await Task.sleep(nanoseconds: retryInterval)
                        // Check cancellation after sleep
                        try Task.checkCancellation()
                    }
                    
                case .CREATE_TASK_FAILED, .GENERATE_AUDIO_FAILED, .CALLBACK_EXCEPTION:
                    print("❌ [SunoAI] Generation failed with status: \(taskDetails.status.rawValue)")
                    throw SunoError.generationFailed(taskDetails.status.rawValue)
                    
                case .SENSITIVE_WORD_ERROR:
                    print("❌ [SunoAI] Sensitive word error: \(taskDetails.errorMessage ?? "Unknown")")
                    let errorMsg = taskDetails.errorMessage ?? ""
                    
                    // Check if error is about artist name
                    if errorMsg.contains("artist name") {
                        throw SunoError.artistNameNotAllowed
                    } else {
                        throw SunoError.generationFailed(taskDetails.status.rawValue)
                    }
                }
                
            } catch is CancellationError {
                print("⚠️ [SunoAI] Task cancelled during polling")
                throw CancellationError()
            } catch let sunoError as SunoError {
                // ✅ CRITICAL: Stop immediately for artist name error - no retry
                if case .artistNameNotAllowed = sunoError {
                    print("❌ [SunoAI] Artist name error detected - stopping polling immediately")
                    throw sunoError
                }
                
                // Check cancellation before handling other errors
                if Task.isCancelled {
                    print("⚠️ [SunoAI] Task cancelled, stopping polling")
                    throw CancellationError()
                }
                
                print("❌ [SunoAI] Polling attempt \(attempt) failed: \(sunoError)")
                if attempt == maxRetries {
                    print("❌ [SunoAI] All polling attempts failed")
                    throw sunoError
                }
                // Wait before retry
                print("⏳ [SunoAI] Continuing to next attempt...")
                try Task.checkCancellation()
                try await Task.sleep(nanoseconds: retryInterval)
            } catch {
                // Check cancellation before handling error
                if Task.isCancelled {
                    print("⚠️ [SunoAI] Task cancelled, stopping polling")
                    throw CancellationError()
                }
                
                print("❌ [SunoAI] Polling attempt \(attempt) failed: \(error)")
                if attempt == maxRetries {
                    print("❌ [SunoAI] All polling attempts failed")
                    throw error
                }
                // Wait before retry
                print("⏳ [SunoAI] Continuing to next attempt...")
                try Task.checkCancellation()
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
    
    // MARK: - Generate Lyrics
    func generateLyrics(prompt: String) async throws -> String {
        // Check cancellation before starting
        try Task.checkCancellation()
        
        Logger.i("📝 [SunoAI] Starting lyrics generation...")
        Logger.d("📝 [SunoAI] Prompt: \(prompt)")
        
        guard let url = URL(string: "\(baseURL)/lyrics") else {
            Logger.e("❌ [SunoAI] Invalid lyrics URL")
            throw SunoError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "prompt": prompt,
            "callBackUrl": "https://api.example.com/callback"
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
            
            Logger.d("📝 [SunoAI] Request URL: \(url)")
            Logger.d("📝 [SunoAI] Request body: \(String(data: jsonData, encoding: .utf8) ?? "Unable to convert")")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            Logger.d("📝 [SunoAI] Response received")
            Logger.d("📝 [SunoAI] Response data: \(String(data: data, encoding: .utf8) ?? "Unable to convert")")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                Logger.e("❌ [SunoAI] Invalid response type")
                throw SunoError.invalidResponse
            }
            
            Logger.d("📝 [SunoAI] HTTP Status: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                Logger.e("❌ [SunoAI] HTTP Error: \(httpResponse.statusCode)")
                throw SunoError.httpError(httpResponse.statusCode)
            }
            
            let lyricsResponse = try JSONDecoder().decode(SunoLyricsResponse.self, from: data)
            Logger.i("📝 [SunoAI] Response code: \(lyricsResponse.code)")
            Logger.i("📝 [SunoAI] Response msg: \(lyricsResponse.msg)")
            
            guard lyricsResponse.code == 200 else {
                Logger.e("❌ [SunoAI] API Error: \(lyricsResponse.msg)")
                throw SunoError.apiError(lyricsResponse.msg)
            }
            
            guard let data = lyricsResponse.data else {
                Logger.e("❌ [SunoAI] No data in response")
                throw SunoError.invalidResponse
            }
            
            Logger.i("✅ [SunoAI] Task ID: \(data.taskId)")
            
            // Check cancellation after API call
            try Task.checkCancellation()
            
            return data.taskId
            
        } catch is CancellationError {
            Logger.i("⚠️ [SunoAI] Lyrics generation cancelled")
            throw CancellationError()
        } catch {
            // Check cancellation before rethrowing
            if Task.isCancelled {
                throw CancellationError()
            }
            Logger.e("❌ [SunoAI] Generate lyrics error: \(error)")
            throw error
        }
    }
    
    // MARK: - Get Lyrics Generation Details
    func getLyricsGenerationDetails(taskId: String) async throws -> SunoLyricsDetails {
        Logger.i("🔍 [SunoAI] Getting lyrics generation details for task: \(taskId)")
        
        guard let url = URL(string: "\(baseURL)/lyrics/record-info?taskId=\(taskId)") else {
            Logger.e("❌ [SunoAI] Invalid lyrics details URL")
            throw SunoError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        Logger.d("🔍 [SunoAI] Request URL: \(url)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            Logger.d("🔍 [SunoAI] Response received")
            Logger.d("🔍 [SunoAI] Response data: \(String(data: data, encoding: .utf8) ?? "Unable to convert")")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                Logger.e("❌ [SunoAI] Invalid response type")
                throw SunoError.invalidResponse
            }
            
            Logger.d("🔍 [SunoAI] HTTP Status: \(httpResponse.statusCode)")
            
            // Stop immediately if server returns 500 error (internal server error)
            if httpResponse.statusCode == 500 {
                Logger.e("❌ [SunoAI] Server error 500 - stopping retry")
                throw SunoError.httpError(500)
            }
            
            guard httpResponse.statusCode == 200 else {
                Logger.e("❌ [SunoAI] HTTP Error: \(httpResponse.statusCode)")
                throw SunoError.httpError(httpResponse.statusCode)
            }
            
            let detailsResponse = try JSONDecoder().decode(SunoLyricsDetailsResponse.self, from: data)
            Logger.i("🔍 [SunoAI] Response code: \(detailsResponse.code)")
            Logger.i("🔍 [SunoAI] Response msg: \(detailsResponse.msg)")
            
            guard detailsResponse.code == 200 else {
                Logger.e("❌ [SunoAI] API Error: \(detailsResponse.msg)")
                throw SunoError.apiError(detailsResponse.msg)
            }
            
            guard let data = detailsResponse.data else {
                Logger.e("❌ [SunoAI] No data in response")
                throw SunoError.invalidResponse
            }
            
            Logger.i("✅ [SunoAI] Lyrics details retrieved: \(data.status.rawValue)")
            return data
            
        } catch {
            Logger.e("❌ [SunoAI] Error getting lyrics details: \(error)")
            throw error
        }
    }
    
    // MARK: - Get Timestamped Lyrics
    func getTimestampedLyrics(taskId: String, audioId: String, musicIndex: Int = 0) async throws -> TimestampedLyricsData {
        Logger.i("🎤 [SunoAI] Getting timestamped lyrics for taskId: \(taskId), audioId: \(audioId)")
        
        guard let url = URL(string: "\(baseURL)/generate/get-timestamped-lyrics") else {
            Logger.e("❌ [SunoAI] Invalid timestamped lyrics URL")
            throw SunoError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = TimestampedLyricsRequest(
            taskId: taskId,
            audioId: audioId,
            musicIndex: musicIndex
        )
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
            
            Logger.d("🎤 [SunoAI] Request URL: \(url)")
            Logger.d("🎤 [SunoAI] Request body: \(String(data: jsonData, encoding: .utf8) ?? "Unable to convert")")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            Logger.d("🎤 [SunoAI] Response received")
            Logger.d("🎤 [SunoAI] Response data: \(String(data: data, encoding: .utf8) ?? "Unable to convert")")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                Logger.e("❌ [SunoAI] Invalid response type")
                throw SunoError.invalidResponse
            }
            
            Logger.d("🎤 [SunoAI] HTTP Status: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                Logger.e("❌ [SunoAI] HTTP Error: \(httpResponse.statusCode)")
                throw SunoError.httpError(httpResponse.statusCode)
            }
            
            let lyricsResponse = try JSONDecoder().decode(TimestampedLyricsResponse.self, from: data)
            Logger.i("🎤 [SunoAI] Response code: \(lyricsResponse.code)")
            Logger.i("🎤 [SunoAI] Response msg: \(lyricsResponse.msg)")
            
            guard lyricsResponse.code == 200 else {
                Logger.e("❌ [SunoAI] API Error: \(lyricsResponse.msg)")
                throw SunoError.apiError(lyricsResponse.msg)
            }
            
            guard let data = lyricsResponse.data else {
                Logger.e("❌ [SunoAI] No data in response")
                throw SunoError.invalidResponse
            }
            
            Logger.i("✅ [SunoAI] Got timestamped lyrics: \(data.alignedWords.count) words")
            return data
            
        } catch {
            Logger.e("❌ [SunoAI] Get timestamped lyrics error: \(error)")
            throw error
        }
    }
    
    // MARK: - Complete Lyrics Generation Flow
    func generateLyricsWithRetry(prompt: String) async throws -> [LyricsResult] {
        Logger.i("🎵 [SunoAI] Starting complete lyrics generation flow")
        
        // Step 1: Generate lyrics
        let taskId = try await generateLyrics(prompt: prompt)
        Logger.i("✅ [SunoAI] Lyrics generation task created: \(taskId)")
        
        // Step 2: Poll for results
        let maxRetries = 60 // 5 minutes max (60 * 5s)
        let retryInterval: TimeInterval = 5.0
        
        for attempt in 1...maxRetries {
            // Check cancellation at start of each loop iteration
            try Task.checkCancellation()
            
            Logger.d("🔄 [SunoAI] Fetching lyrics attempt \(attempt)/\(maxRetries)")
            
            do {
                let details = try await getLyricsGenerationDetails(taskId: taskId)
                
                // Check cancellation after API call
                try Task.checkCancellation()
                
                Logger.d("📊 [SunoAI] Status: \(details.status.rawValue)")
                
                switch details.status {
                case .success:
                    Logger.i("✅ [SunoAI] Lyrics generated successfully!")
                    
                    // Parse lyrics results from response
                    guard let responseData = details.response else {
                        Logger.e("❌ [SunoAI] No response data")
                        throw SunoError.invalidResponse
                    }
                    
                    Logger.d("📝 [SunoAI] Response data count: \(responseData.data.count)")
                    
                    let lyrics = responseData.data.compactMap { lyricsData -> LyricsResult? in
                        Logger.d("📝 [SunoAI] Parsing lyrics - Title: \(lyricsData.title), Status: \(lyricsData.status)")
                        
                        // Only include completed lyrics
                        guard lyricsData.status == "complete" else {
                            Logger.w("⚠️ [SunoAI] Skipping lyrics with status: \(lyricsData.status)")
                            return nil
                        }
                        
                        return LyricsResult(
                            text: lyricsData.text,
                            title: lyricsData.title
                        )
                    }
                    
                    Logger.i("✅ [SunoAI] Got \(lyrics.count) completed lyrics variations")
                    return lyrics
                    
                case .pending:
                    Logger.d("⏳ [SunoAI] Still generating...")
                    if attempt < maxRetries {
                        // Check cancellation before sleep
                        try Task.checkCancellation()
                        try await Task.sleep(nanoseconds: UInt64(retryInterval * 1_000_000_000))
                        // Check cancellation after sleep
                        try Task.checkCancellation()
                    } else {
                        Logger.e("❌ [SunoAI] Max retries reached")
                        throw SunoError.requestTimeout
                    }
                    
                case .createTaskFailed, .generateLyricsFailed, .callbackException, .sensitiveWordError:
                    Logger.e("❌ [SunoAI] Generation failed: \(details.status.rawValue)")
                    throw SunoError.generationFailed(details.status.rawValue)
                }
                
            } catch is CancellationError {
                Logger.i("⚠️ [SunoAI] Lyrics generation cancelled during polling")
                throw CancellationError()
            } catch let sunoError as SunoError {
                // Check if it's HTTP 500 error - stop retry immediately
                if case .httpError(let code) = sunoError, code == 500 {
                    Logger.e("❌ [SunoAI] Server error 500 detected - stopping retry loop")
                    throw sunoError
                }
                // For other errors, continue retry logic
                Logger.e("❌ [SunoAI] Error: \(sunoError)")
                if attempt < maxRetries {
                    // Check cancellation before sleep
                    try? Task.checkCancellation()
                    if Task.isCancelled {
                        throw CancellationError()
                    }
                    try await Task.sleep(nanoseconds: UInt64(retryInterval * 1_000_000_000))
                } else {
                    throw sunoError
                }
            } catch {
                // Check cancellation before handling error
                if Task.isCancelled {
                    Logger.i("⚠️ [SunoAI] Task cancelled, stopping polling")
                    throw CancellationError()
                }
                
                Logger.e("❌ [SunoAI] Error: \(error)")
                if attempt < maxRetries {
                    // Check cancellation before sleep
                    try? Task.checkCancellation()
                    if Task.isCancelled {
                        throw CancellationError()
                    }
                    try await Task.sleep(nanoseconds: UInt64(retryInterval * 1_000_000_000))
                } else {
                    throw error
                }
            }
        }
        
        Logger.e("❌ [SunoAI] Max retries exceeded")
        throw SunoError.requestTimeout
    }
    
    // MARK: - Helper: Fetch Timestamped Lyrics for Songs
    private func fetchTimestampedLyricsForSongs(taskId: String, songs: [SunoData]) async {
        Logger.i("🎤 [SunoAI] Fetching timestamped lyrics for \(songs.count) songs")
        
        for (index, song) in songs.enumerated() {
            do {
                Logger.d("🎤 [SunoAI] Fetching lyrics for song \(index + 1)/\(songs.count): \(song.title) (id: \(song.id))")
                let lyrics = try await getTimestampedLyrics(
                    taskId: taskId,
                    audioId: song.id,
                    musicIndex: index
                )
                
                // Save to local storage
                TimestampedLyricsManager.shared.saveTimestampedLyrics(for: song.id, lyrics: lyrics)
                Logger.i("✅ [SunoAI] Saved timestamped lyrics for song: \(song.title)")
            } catch {
                Logger.w("⚠️ [SunoAI] Failed to get timestamped lyrics for song \(song.title): \(error.localizedDescription)")
                // Continue with next song even if this one fails
            }
        }
    }
}
