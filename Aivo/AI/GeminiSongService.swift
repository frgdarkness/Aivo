import Foundation
import FirebaseCore
import FirebaseAI

class GeminiSongService {
    static let shared = GeminiSongService()
    
    private var ai: FirebaseAI?

    private var titleModel: GenerativeModel?
    private var lyricsModel: GenerativeModel?

    private init() {
        setupModels()
    }
    
    private func setupModels() {
        // Ensure Firebase is configured
        guard let app = FirebaseApp.app() else {
            Logger.e("FirebaseApp not initialized for GeminiSongService")
            return
        }
        
//        guard let projectID = app.options.projectID else {
//            Logger.e("Firebase project ID not found for GeminiSongService")
//            return
//        }
//        
//        Logger.d("Initializing GeminiSongService with project ID: \(projectID)")
        
        ai = FirebaseAI.firebaseAI(app: app, backend: .googleAI())
        
        // --- 1. Title Model (Specific Instruction) ---
        let titleInstructionText = """
        You are a creative music assistant. Your task is to analyze song lyrics and suggest short, catchy, and relevant song titles.
        Return ONLY the title text. Do not use quotes.
        """
        let titleInstruction = ModelContent(role: "system", parts: [TextPart(titleInstructionText)])
        
        self.titleModel = ai?.generativeModel(
            modelName: "gemini-2.5-flash-lite",
            generationConfig: GenerationConfig(
                temperature: 0.7,
                topP: 0.95,
                topK: 40,
                maxOutputTokens: 100
            ),
            systemInstruction: titleInstruction
        )
        
        // --- 2. Lyrics Model (Generic/Writer) ---
        // We leave system instruction empty here so we can guide it via prompt, or give it a generic writer persona.
        let lyricsInstructionText = """
        You are a professional songwriter. Your task is to write creative lyrics and suggest titles.
        Always return valid JSON.
        """
        let lyricsInstruction = ModelContent(role: "system", parts: [TextPart(lyricsInstructionText)])

        self.lyricsModel = ai?.generativeModel(
            modelName: "gemini-2.5-flash-lite",
            generationConfig: GenerationConfig(
                temperature: 0.8, // More creative for lyrics
                topP: 0.95,
                topK: 40,
                maxOutputTokens: 2000
            ),
            systemInstruction: lyricsInstruction
        )
        
        Logger.d("GeminiSongService initialized with models: gemini-2.5-flash-lite")
    }

    /// Generates a creative song title for a single lyrics string.
    func generateSongTitle(from lyrics: String) async throws -> String {
        return try await generateSongTitles(from: [lyrics]).first ?? ""
    }
    
    /// Generates creative song titles for a list of lyrics.
    /// Returns a list of titles corresponding to the input lyrics.
    func generateSongTitles(from lyricsList: [String]) async throws -> [String] {
        guard let model = titleModel else {
            Logger.e("Gemini Title Model not initialized")
            throw NSError(domain: "GeminiSongService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model not initialized"])
        }
        
        // If single item, use simple prompt to save tokens/complexity, or just use batch prompt?
        // Let's use a batch prompt structure to ensure uniqueness if possible,
        // though strictly distinct calls might be better for isolation.
        // However, user asked to "gen titles allow list string to gen multiple at once".
        
        // Construct a structured prompt
        var promptText = "Analyze the following lyrics and suggest a unique title for each. Return the result as a JSON array of strings, e.g. [\"Title 1\", \"Title 2\"].\n\n"
        
        for (index, lyrics) in lyricsList.enumerated() {
            promptText += "--- Lyrics \(index + 1) ---\n\(lyrics.prefix(500))...\n\n"
        }
        
        promptText += "Return ONLY the JSON array."
        
        do {
            let response = try await model.generateContent(promptText)
            guard let text = response.text else {
                throw NSError(domain: "GeminiSongService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No text in response"])
            }
            
            Logger.d("Gemini Titles Response: \(text)")
            
            // Clean JSON
            var jsonString = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if jsonString.hasPrefix("```json") { jsonString = String(jsonString.dropFirst(7)) }
            if jsonString.hasPrefix("```") { jsonString = String(jsonString.dropFirst(3)) }
            if jsonString.hasSuffix("```") { jsonString = String(jsonString.dropLast(3)) }
            
            guard let jsonData = jsonString.data(using: .utf8) else {
                // Fallback: try splitting by newline if JSON fails, or return raw text if single
                if lyricsList.count == 1 { return [text.replacingOccurrences(of: "\"", with: "")] }
                throw NSError(domain: "GeminiSongService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"])
            }
            
            let titles = try JSONDecoder().decode([String].self, from: jsonData)
            if titles.count == lyricsList.count {
                return titles
            } else {
                 Logger.w("Gemini returned \(titles.count) titles for \(lyricsList.count) lyrics. Padding with defaults.")
                // Pad or trim
                var result = titles
                while result.count < lyricsList.count { result.append("Song Title") }
                return Array(result.prefix(lyricsList.count))
            }
        } catch {
            Logger.e("Gemini Batch Title Generation Error: \(error)")
            // Fallback: Return empty strings or defaults
            return lyricsList.map { _ in "Song Title" }
        }
    }

    /// Generates variations of lyrics using Gemini with advanced configuration.
    func generateLyrics(config: LyricConfiguration) async throws -> [LyricsResult] {
        guard let model = lyricsModel else {
            Logger.e("Gemini Lyrics Model not initialized")
            throw NSError(domain: "GeminiSongService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model not initialized"])
        }
        
        // Build detailed prompt from configuration
        let description = config.promptDescription
        
        let userPrompt = """
        Write \(config.lyricCount) different versions of song lyrics based on these requirements:
        \(description)
        
        For each version, give it a creative and unique title (the titles must be different).
        
        Return the result as a JSON array of objects, with keys "title" and "text".
        Example format:
        [
            { "title": "Song Title 1", "text": "Verse 1..." },
            { "title": "Song Title 2", "text": "Verse 1..." }
        ]
        """
        
        do {
            // Use generateContent instead of startChat
            let response = try await model.generateContent(userPrompt)
            
            guard let text = response.text else {
                throw NSError(domain: "GeminiSongService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No text in response"])
            }
            
            Logger.d("Gemini generated lyrics raw: \(text.prefix(100))...")
            
            // Clean markdown code blocks
            var jsonString = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if jsonString.hasPrefix("```json") { jsonString = String(jsonString.dropFirst(7)) }
            if jsonString.hasPrefix("```") { jsonString = String(jsonString.dropFirst(3)) }
            if jsonString.hasSuffix("```") { jsonString = String(jsonString.dropLast(3)) }
            
            guard let jsonData = jsonString.data(using: .utf8) else {
                throw NSError(domain: "GeminiSongService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON data"])
            }
            
            struct GeminiLyricsResponse: Codable {
                let title: String
                let text: String
            }
            
            let decoded = try JSONDecoder().decode([GeminiLyricsResponse].self, from: jsonData)
            return decoded.map { LyricsResult(text: $0.text, title: $0.title) }
            
        } catch {
            Logger.e("Gemini Lyrics Generation Error: \(error)")
            throw error
        }
    }
}
