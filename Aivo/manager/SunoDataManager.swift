import Foundation
import UIKit

// MARK: - SunoDataManager
class SunoDataManager {
    static let shared = SunoDataManager()
    
    private init() {}
    
    // MARK: - Save SunoData to Local Storage
    func saveSunoData(_ sunoData: SunoData) async throws -> URL {
        print("💾 [SunoDataManager] Saving SunoData: \(sunoData.title)")
        
        // Get documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let sunoDataDirectory = documentsPath.appendingPathComponent("SunoData")
        
        // Create directory if it doesn't exist
        try FileManager.default.createDirectory(at: sunoDataDirectory, withIntermediateDirectories: true)
        
        // Download and save audio file
        let audioURL = try await downloadAndSaveAudio(sunoData.audioUrl, songId: sunoData.id, to: sunoDataDirectory)
        
        // Download and save cover image
        let coverURL = try await downloadAndSaveCover(sunoData.imageUrl, songId: sunoData.id, to: sunoDataDirectory)
        
        // Create metadata file
        let metadata = SunoDataMetadata(
            id: sunoData.id,
            audioUrl: audioURL.absoluteString,
            coverUrl: coverURL.absoluteString,
            title: sunoData.title,
            modelName: sunoData.modelName,
            duration: sunoData.duration,
            prompt: sunoData.prompt,
            tags: sunoData.tags,
            createTime: sunoData.createTime,
            savedAt: Int64(Date().timeIntervalSince1970 * 1000)
        )
        
        let metadataURL = sunoDataDirectory.appendingPathComponent("\(sunoData.id)_metadata.json")
        let metadataData = try JSONEncoder().encode(metadata)
        try metadataData.write(to: metadataURL)
        
        print("✅ [SunoDataManager] Successfully saved SunoData: \(sunoData.title)")
        print("💾 [SunoDataManager] Audio: \(audioURL.path)")
        print("💾 [SunoDataManager] Cover: \(coverURL.path)")
        print("💾 [SunoDataManager] Metadata: \(metadataURL.path)")
        
        return audioURL
    }
    
    // MARK: - Load All Saved SunoData
    func loadAllSavedSunoData() async throws -> [SunoData] {
        print("📚 [SunoDataManager] Loading all saved SunoData...")
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let sunoDataDirectory = documentsPath.appendingPathComponent("SunoData")
        
        guard FileManager.default.fileExists(atPath: sunoDataDirectory.path) else {
            print("📚 [SunoDataManager] No SunoData directory found")
            return []
        }
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: sunoDataDirectory, includingPropertiesForKeys: [.creationDateKey], options: [])
            let metadataFiles = fileURLs.filter { $0.pathExtension == "json" }
            
            var sunoDataList: [SunoData] = []
            
            for metadataFile in metadataFiles {
                do {
                    let data = try Data(contentsOf: metadataFile)
                    let metadata = try JSONDecoder().decode(SunoDataMetadata.self, from: data)
                    
                    let sunoData = SunoData(
                        id: metadata.id,
                        audioUrl: metadata.audioUrl,
                        sourceAudioUrl: metadata.audioUrl,
                        streamAudioUrl: metadata.audioUrl,
                        sourceStreamAudioUrl: metadata.audioUrl,
                        imageUrl: metadata.coverUrl,
                        sourceImageUrl: metadata.coverUrl,
                        prompt: metadata.prompt,
                        modelName: metadata.modelName,
                        title: metadata.title,
                        tags: metadata.tags,
                        createTime: metadata.savedAt,
                        duration: metadata.duration
                    )
                    
                    sunoDataList.append(sunoData)
                } catch {
                    print("❌ [SunoDataManager] Error loading metadata from \(metadataFile.lastPathComponent): \(error)")
                }
            }
            
            // Sort by saved date, newest first
            sunoDataList.sort { $0.createTime > $1.createTime }
            
            print("📚 [SunoDataManager] Loaded \(sunoDataList.count) saved SunoData")
            return sunoDataList
            
        } catch {
            print("❌ [SunoDataManager] Error loading SunoData: \(error)")
            throw error
        }
    }
    
    // MARK: - Private Methods
    private func downloadAndSaveAudio(_ audioUrl: String, songId: String, to directory: URL) async throws -> URL {
        guard let url = URL(string: audioUrl) else {
            throw SunoDataError.invalidURL
        }
        
        let ext = url.pathExtension.isEmpty ? "mp3" : url.pathExtension.lowercased()
        let fileName = "\(songId)_audio.\(ext)"
        let destinationURL = directory.appendingPathComponent(fileName)
        
        print("💾 [SunoDataManager] Downloading audio from: \(audioUrl)")
        print("💾 [SunoDataManager] Saving to: \(destinationURL.path)")
        
        // Download audio file
        let (data, _) = try await URLSession.shared.data(from: url)
        try data.write(to: destinationURL)
        
        print("✅ [SunoDataManager] Audio saved successfully: \(destinationURL.path)")
        return destinationURL
    }
    
    private func downloadAndSaveCover(_ imageUrl: String, songId: String, to directory: URL) async throws -> URL {
        guard let url = URL(string: imageUrl) else {
            throw SunoDataError.invalidURL
        }
        
        let ext = url.pathExtension.isEmpty ? "jpg" : url.pathExtension.lowercased()
        let fileName = "\(songId)_cover.\(ext)"
        let destinationURL = directory.appendingPathComponent(fileName)
        
        // Download cover image
        let (data, _) = try await URLSession.shared.data(from: url)
        try data.write(to: destinationURL)
        
        return destinationURL
    }
}

// MARK: - SunoDataMetadata
struct SunoDataMetadata: Codable {
    let id: String
    let audioUrl: String
    let coverUrl: String
    let title: String
    let modelName: String
    let duration: Double
    let prompt: String
    let tags: String
    let createTime: Int64
    let savedAt: Int64
}

// MARK: - SunoDataError
enum SunoDataError: Error {
    case invalidURL
    case fileNotFound
    case encodingError
    case decodingError
}
