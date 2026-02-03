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
    
    // Custom decoder to handle errorCode as either Int or String
    enum CodingKeys: String, CodingKey {
        case taskId, parentMusicId, param, response, status, type, operationType, errorMessage, createTime
        case errorCode
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        taskId = try container.decode(String.self, forKey: .taskId)
        parentMusicId = try container.decode(String.self, forKey: .parentMusicId)
        param = try container.decode(String.self, forKey: .param)
        response = try container.decodeIfPresent(SunoTaskResponse.self, forKey: .response)
        status = try container.decode(SunoStatus.self, forKey: .status)
        type = try container.decode(String.self, forKey: .type)
        operationType = try container.decode(String.self, forKey: .operationType)
        errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
        createTime = try container.decode(Int64.self, forKey: .createTime)
        
        // Handle errorCode as either Int or String
        if let errorCodeInt = try? container.decode(Int.self, forKey: .errorCode) {
            errorCode = String(errorCodeInt)
        } else {
            errorCode = try container.decodeIfPresent(String.self, forKey: .errorCode)
        }
    }
}

struct SunoTaskResponse: Codable {
    let taskId: String
    let sunoData: [SunoData]?
}

struct SunoData: Codable, Identifiable, Equatable {
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
    
    // Custom Decodable init to handle missing fields with default values
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        id = try container.decode(String.self, forKey: .id)
        audioUrl = try container.decode(String.self, forKey: .audioUrl)
        
        // Optional fields with defaults
        sourceAudioUrl = try container.decodeIfPresent(String.self, forKey: .sourceAudioUrl) ?? audioUrl
        streamAudioUrl = try container.decodeIfPresent(String.self, forKey: .streamAudioUrl) ?? audioUrl
        sourceStreamAudioUrl = try container.decodeIfPresent(String.self, forKey: .sourceStreamAudioUrl) ?? audioUrl
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl) ?? ""
        sourceImageUrl = try container.decodeIfPresent(String.self, forKey: .sourceImageUrl) ?? ""
        prompt = try container.decodeIfPresent(String.self, forKey: .prompt) ?? ""
        modelName = try container.decodeIfPresent(String.self, forKey: .modelName) ?? "Aivo music"
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        tags = try container.decodeIfPresent(String.self, forKey: .tags) ?? ""
        createTime = try container.decodeIfPresent(Int64.self, forKey: .createTime) ?? 0
        duration = try container.decodeIfPresent(Double.self, forKey: .duration) ?? 0
    }
    
    // Default init for creating SunoData manually
    init(
        id: String,
        audioUrl: String,
        sourceAudioUrl: String = "",
        streamAudioUrl: String = "",
        sourceStreamAudioUrl: String = "",
        imageUrl: String = "",
        sourceImageUrl: String = "",
        prompt: String = "",
        modelName: String = "Aivo music",
        title: String = "",
        tags: String = "",
        createTime: Int64 = 0,
        duration: Double = 0
    ) {
        self.id = id
        self.audioUrl = audioUrl
        self.sourceAudioUrl = sourceAudioUrl.isEmpty ? audioUrl : sourceAudioUrl
        self.streamAudioUrl = streamAudioUrl.isEmpty ? audioUrl : streamAudioUrl
        self.sourceStreamAudioUrl = sourceStreamAudioUrl.isEmpty ? audioUrl : sourceStreamAudioUrl
        self.imageUrl = imageUrl
        self.sourceImageUrl = sourceImageUrl
        self.prompt = prompt
        self.modelName = modelName
        self.title = title
        self.tags = tags
        self.createTime = createTime
        self.duration = duration
    }
    
    static func == (lhs: SunoData, rhs: SunoData) -> Bool {
        return lhs.id == rhs.id
    }
}

extension SunoData {
    var coverImageLocalPath: String? {
        return SunoDataManager.shared.getLocalCoverPath(for: id)?.path
    }
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

// MARK: - Timestamped Lyrics Models
struct TimestampedLyricsRequest: Codable {
    let taskId: String
    let audioId: String?
    let musicIndex: Int?
    
    enum CodingKeys: String, CodingKey {
        case taskId
        case audioId
        case musicIndex
    }
}

struct TimestampedLyricsResponse: Codable {
    let code: Int
    let msg: String
    let data: TimestampedLyricsData?
}

struct TimestampedLyricsData: Codable {
    let alignedWords: [AlignedWord]
    let waveformData: [Double]
    let hootCer: Double
    let isStreamed: Bool
}

struct AlignedWord: Codable {
    let word: String
    let success: Bool
    let startS: Double
    let endS: Double
    let palign: Int
    
    enum CodingKeys: String, CodingKey {
        case word
        case success
        case startS
        case endS
        case palign
    }
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
    case artistNameNotAllowed
    
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
        case .artistNameNotAllowed:
            return NSLocalizedString("Artist names are not allowed in song descriptions. Please remove the artist name and try again.", comment: "Error when artist name is used in prompt")
        }
    }
}



// MARK: - Mocks
extension SunoData {
    static let mock = SunoData(
        id: "mock_id",
        audioUrl: "https://example.com/audio.mp3",
        imageUrl: "https://example.com/image.jpg",
        modelName: "Aivo V3", title: "Mock Song",
        duration: 180
    )
}
