import Foundation

// MARK: - Suno AI Music Models

// MARK: - Generate Request
struct SunoGenerateRequest: Codable {
    let prompt: String
    let style: String?
    let title: String?
    let customMode: Bool
    let instrumental: Bool
    let model: SunoModel
    let negativeTags: String?
    let vocalGender: VocalGender?
    let styleWeight: Double?
    let weirdnessConstraint: Double?
    let audioWeight: Double?
    let callBackUrl: String?
}

// MARK: - Generate Response
struct SunoGenerateResponse: Codable {
    let code: Int
    let msg: String
    let data: SunoGenerateData?
}

struct SunoGenerateData: Codable {
    let taskId: String
}

// MARK: - Details Response
struct SunoDetailsResponse: Codable {
    let code: Int
    let msg: String
    let data: SunoTaskDetails?
}

struct SunoTaskDetails: Codable {
    let taskId: String
    let parentMusicId: String
    let param: String
    let response: SunoTaskResponse?
    let status: SunoStatus
    let type: String
    let operationType: String
    let errorCode: String?
    let errorMessage: String?
    let createTime: Int64
}

struct SunoTaskResponse: Codable {
    let taskId: String
    let sunoData: [SunoData]
}

struct SunoData: Codable, Identifiable {
    let id: String
    let audioUrl: String
    let sourceAudioUrl: String
    let streamAudioUrl: String
    let sourceStreamAudioUrl: String
    let imageUrl: String
    let sourceImageUrl: String
    let prompt: String
    let modelName: String
    let title: String
    let tags: String
    let createTime: Int64
    var duration: Double
}

// MARK: - Enums
enum SunoModel: String, Codable, CaseIterable {
    case V3_5 = "V3_5"
    case V4 = "V4"
    case V4_5 = "V4_5"
    case V4_5PLUS = "V4_5PLUS"
    case V5 = "V5"
}

enum VocalGender: String, Codable {
    case male = "m"
    case female = "f"
}

enum SunoStatus: String, Codable {
    case PENDING = "PENDING"
    case TEXT_SUCCESS = "TEXT_SUCCESS"
    case FIRST_SUCCESS = "FIRST_SUCCESS"
    case SUCCESS = "SUCCESS"
    case CREATE_TASK_FAILED = "CREATE_TASK_FAILED"
    case GENERATE_AUDIO_FAILED = "GENERATE_AUDIO_FAILED"
    case CALLBACK_EXCEPTION = "CALLBACK_EXCEPTION"
    case SENSITIVE_WORD_ERROR = "SENSITIVE_WORD_ERROR"
}

// MARK: - Lyrics Models
struct SunoLyricsResponse: Codable {
    let code: Int
    let msg: String
    let data: SunoLyricsData?
}

struct SunoLyricsData: Codable {
    let taskId: String
}

struct SunoLyricsDetailsResponse: Codable {
    let code: Int
    let msg: String
    let data: SunoLyricsDetails?
}

struct SunoLyricsDetails: Codable {
    let taskId: String
    let param: String
    let response: SunoLyricsTaskResponse?
    let status: SunoLyricsStatus
    let type: String?
    let errorCode: String?
    let errorMessage: String?
}

struct SunoLyricsTaskResponse: Codable {
    let taskId: String
    let data: [SunoLyricsDataResult]
}

struct SunoLyricsDataResult: Codable {
    let text: String
    let title: String
    let status: String
    let errorMessage: String?
}

struct LyricsResult: Codable, Identifiable {
    let id = UUID()
    let text: String
    let title: String
}

enum SunoLyricsStatus: String, Codable {
    case pending = "PENDING"
    case success = "SUCCESS"
    case createTaskFailed = "CREATE_TASK_FAILED"
    case generateLyricsFailed = "GENERATE_LYRICS_FAILED"
    case callbackException = "CALLBACK_EXCEPTION"
    case sensitiveWordError = "SENSITIVE_WORD_ERROR"
}

// MARK: - Errors
enum SunoError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case generationFailed(String)
    case timeoutExceeded
    case invalidAPIKey
    case invalidURL
    case requestTimeout
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return "API error: \(message)"
        case .generationFailed(let status):
            return "Music generation failed: \(status)"
        case .timeoutExceeded:
            return "Generation timeout exceeded"
        case .invalidAPIKey:
            return "Invalid API key"
        case .invalidURL:
            return "Invalid URL"
        case .requestTimeout:
            return "Request timeout"
        }
    }
}
