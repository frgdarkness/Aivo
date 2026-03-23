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
        
        // Download and save cover image (only if imageUrl is not empty)
        let coverURL: URL
        if !sunoData.imageUrl.isEmpty {
            coverURL = try await downloadAndSaveCover(sunoData.imageUrl, songId: sunoData.id, to: sunoDataDirectory)
        } else {
            // Create a placeholder cover URL for cover songs
            let placeholderFileName = "\(sunoData.id)_cover.jpg"
            coverURL = sunoDataDirectory.appendingPathComponent(placeholderFileName)
            print("💾 [SunoDataManager] No cover image URL provided, using placeholder")
        }
        
        // Create metadata file - KEEP ORIGINAL URLs
        let metadata = SunoDataMetadata(
            id: sunoData.id,
            audioUrl: sunoData.audioUrl, // Keep original URL
            sourceAudioUrl: sunoData.sourceAudioUrl,
            streamAudioUrl: sunoData.streamAudioUrl,
            sourceStreamAudioUrl: sunoData.sourceStreamAudioUrl,
            imageUrl: sunoData.imageUrl, // Keep original URL
            sourceImageUrl: sunoData.sourceImageUrl,
            coverUrl: coverURL.absoluteString, // Local cover path
            title: sunoData.title,
            modelName: sunoData.modelName,
            duration: sunoData.duration,
            prompt: sunoData.prompt,
            tags: sunoData.tags,
            createTime: sunoData.createTime,
            savedAt: Int64(Date().timeIntervalSince1970 * 1000),
            playCount: sunoData.playCount,
            weekTag: sunoData.weekTag,
            profileID: sunoData.profileID,
            isPublic: sunoData.isPublic,
            likeCount: sunoData.likeCount,
            username: sunoData.username
        )
        
        let metadataURL = sunoDataDirectory.appendingPathComponent("\(sunoData.id).json")
        let metadataData = try JSONEncoder().encode(metadata)
        try metadataData.write(to: metadataURL)
        
        print("✅ [SunoDataManager] Successfully saved SunoData: \(sunoData.title)")
        print("💾 [SunoDataManager] Audio: \(audioURL.path)")
        print("💾 [SunoDataManager] Cover: \(coverURL.path)")
        print("💾 [SunoDataManager] Metadata: \(metadataURL.path)")
        
        return audioURL
    }
    
    // MARK: - Update Song Data
    func updateSunoData(_ songId: String, title: String, modelName: String) async throws {
        Logger.d("💾 [SunoDataManager] Updating song data for: \(songId)")
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let sunoDataDirectory = documentsPath.appendingPathComponent("SunoData")
        let metadataURL = sunoDataDirectory.appendingPathComponent("\(songId).json")
        
        guard FileManager.default.fileExists(atPath: metadataURL.path) else {
            Logger.e("❌ [SunoDataManager] Metadata file not found for song: \(songId)")
            throw SunoDataError.fileNotFound
        }
        
        do {
            let data = try Data(contentsOf: metadataURL)
            let metadata = try JSONDecoder().decode(SunoDataMetadata.self, from: data)
            
            // Update title and modelName
            let updatedMetadata = SunoDataMetadata(
                id: metadata.id,
                audioUrl: metadata.audioUrl,
                sourceAudioUrl: metadata.sourceAudioUrl,
                streamAudioUrl: metadata.streamAudioUrl,
                sourceStreamAudioUrl: metadata.sourceStreamAudioUrl,
                imageUrl: metadata.imageUrl,
                sourceImageUrl: metadata.sourceImageUrl,
                coverUrl: metadata.coverUrl,
                title: title,
                modelName: modelName,
                duration: metadata.duration,
                prompt: metadata.prompt,
                tags: metadata.tags,
                createTime: metadata.createTime,
                savedAt: metadata.savedAt,
                playCount: metadata.playCount,
                weekTag: metadata.weekTag,
                profileID: metadata.profileID,
                isPublic: metadata.isPublic,
                likeCount: metadata.likeCount,
                username: metadata.username
            )
            
            // Save updated metadata
            let updatedData = try JSONEncoder().encode(updatedMetadata)
            try updatedData.write(to: metadataURL)
            
            Logger.d("✅ [SunoDataManager] Successfully updated song: \(title) by \(modelName)")
        } catch {
            Logger.e("❌ [SunoDataManager] Error updating song data: \(error)")
            throw error
        }
    }
    
    // MARK: - Update Title (deprecated, use updateSunoData instead)
    func updateSunoDataTitle(_ songId: String, title: String) async throws {
        Logger.d("💾 [SunoDataManager] Updating title for song: \(songId)")
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let sunoDataDirectory = documentsPath.appendingPathComponent("SunoData")
        let metadataURL = sunoDataDirectory.appendingPathComponent("\(songId).json")
        
        guard FileManager.default.fileExists(atPath: metadataURL.path) else {
            Logger.e("❌ [SunoDataManager] Metadata file not found for song: \(songId)")
            throw SunoDataError.fileNotFound
        }
        
        do {
            let data = try Data(contentsOf: metadataURL)
            var metadata = try JSONDecoder().decode(SunoDataMetadata.self, from: data)
            
            // Update title
            let updatedMetadata = SunoDataMetadata(
                id: metadata.id,
                audioUrl: metadata.audioUrl,
                sourceAudioUrl: metadata.sourceAudioUrl,
                streamAudioUrl: metadata.streamAudioUrl,
                sourceStreamAudioUrl: metadata.sourceStreamAudioUrl,
                imageUrl: metadata.imageUrl,
                sourceImageUrl: metadata.sourceImageUrl,
                coverUrl: metadata.coverUrl,
                title: title,
                modelName: metadata.modelName,
                duration: metadata.duration,
                prompt: metadata.prompt,
                tags: metadata.tags,
                createTime: metadata.createTime,
                savedAt: metadata.savedAt,
                playCount: metadata.playCount,
                weekTag: metadata.weekTag,
                profileID: metadata.profileID,
                isPublic: metadata.isPublic,
                likeCount: metadata.likeCount,
                username: metadata.username
            )
            
            // Save updated metadata
            let updatedData = try JSONEncoder().encode(updatedMetadata)
            try updatedData.write(to: metadataURL)
            
            Logger.d("✅ [SunoDataManager] Successfully updated title for song: \(title)")
        } catch {
            Logger.e("❌ [SunoDataManager] Error updating title: \(error)")
            throw error
        }
    }
    
    // MARK: - Load All Saved SunoData
    
    var savedSunoDataList: [SunoData] {
        return fetchAllSavedSunoData()
    }
    
    // MARK: - Update Duration
    func updateSunoDataDuration(_ songId: String, duration: Double) async throws {
        Logger.d("💾 [SunoDataManager] Updating duration for song: \(songId)")
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let sunoDataDirectory = documentsPath.appendingPathComponent("SunoData")
        let metadataURL = sunoDataDirectory.appendingPathComponent("\(songId).json")
        
        guard FileManager.default.fileExists(atPath: metadataURL.path) else {
            Logger.e("❌ [SunoDataManager] Metadata file not found for song: \(songId)")
            throw SunoDataError.fileNotFound
        }
        
        do {
            let data = try Data(contentsOf: metadataURL)
            var metadata = try JSONDecoder().decode(SunoDataMetadata.self, from: data)
            
            // Update duration
            metadata.duration = duration
            
            // Save updated metadata
            let updatedData = try JSONEncoder().encode(metadata)
            try updatedData.write(to: metadataURL)
            
            Logger.d("✅ [SunoDataManager] Duration updated: \(duration) seconds")
        } catch {
            Logger.e("❌ [SunoDataManager] Error updating duration: \(error)")
            throw error
        }
    }
    
    func loadAllSavedSunoData() async throws -> [SunoData] {
        return fetchAllSavedSunoData()
    }
    
    func fetchAllSavedSunoData() -> [SunoData] {
        // print("📚 [SunoDataManager] Loading all saved SunoData...") // Reduce log noise
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let sunoDataDirectory = documentsPath.appendingPathComponent("SunoData")
        
        guard FileManager.default.fileExists(atPath: sunoDataDirectory.path) else {
            // print("📚 [SunoDataManager] No SunoData directory found")
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
                    
                    var sunoData = SunoData(
                        id: metadata.id,
                        audioUrl: metadata.audioUrl,
                        sourceAudioUrl: metadata.sourceAudioUrl,
                        streamAudioUrl: metadata.streamAudioUrl,
                        sourceStreamAudioUrl: metadata.sourceStreamAudioUrl,
                        imageUrl: metadata.imageUrl,
                        sourceImageUrl: metadata.sourceImageUrl,
                        prompt: metadata.prompt,
                        modelName: metadata.modelName,
                        title: metadata.title,
                        tags: metadata.tags,
                        createTime: metadata.createTime,
                        duration: metadata.duration,
                        playCount: metadata.playCount,
                        weekTag: metadata.weekTag,
                        profileID: metadata.profileID,
                        isPublic: metadata.isPublic,
                        likeCount: metadata.likeCount,
                        username: metadata.username
                    )
                    
                    // Migration: If profileID is missing for a locally saved song,
                    // ONLY assign current user if the song was generated by this user
                    // (i.e., NOT a platform/explore song with "Aivo Music" username).
                    // Songs from Remote Config/Explore have username "Aivo Music" or nil
                    // and should NOT be claimed by the current user.
                    if sunoData.profileID == nil, let currentProfileID = LocalStorageManager.shared.localProfile?.profileID {
                        let isLikelyPlatformSong = (sunoData.username == nil || sunoData.username == "Aivo Music")
                        if !isLikelyPlatformSong {
                            // Song has a non-default username — likely user-generated, assign profileID
                            sunoData.profileID = currentProfileID
                        }
                    }
                    
                    sunoDataList.append(sunoData)
                } catch {
                    print("❌ [SunoDataManager] Error loading metadata from \(metadataFile.lastPathComponent): \(error)")
                }
            }
            
            // Sort by saved date, newest first
            sunoDataList.sort { $0.createTime > $1.createTime }
            
            // print("📚 [SunoDataManager] Loaded \(sunoDataList.count) saved SunoData")
            return sunoDataList
            
        } catch {
            print("❌ [SunoDataManager] Error loading SunoData: \(error)")
            return []
        }
    }
    
    // MARK: - Delete SunoData
    func deleteSunoData(_ sunoData: SunoData) async throws {
        print("🗑️ [SunoDataManager] Deleting SunoData: \(sunoData.title)")
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let sunoDataDirectory = documentsPath.appendingPathComponent("SunoData")
        
        // Delete metadata file
        let metadataFileName = "\(sunoData.id).json"
        let metadataFileURL = sunoDataDirectory.appendingPathComponent(metadataFileName)
        
        if FileManager.default.fileExists(atPath: metadataFileURL.path) {
            try FileManager.default.removeItem(at: metadataFileURL)
            print("🗑️ [SunoDataManager] Deleted metadata file: \(metadataFileName)")
        }
        
        // Delete audio file
        let audioFileName = "\(sunoData.id)_audio.mp3"
        let audioFileURL = sunoDataDirectory.appendingPathComponent(audioFileName)
        
        if FileManager.default.fileExists(atPath: audioFileURL.path) {
            try FileManager.default.removeItem(at: audioFileURL)
            print("🗑️ [SunoDataManager] Deleted audio file: \(audioFileName)")
        }
        
        // Delete cover image file
        let coverFileName = "\(sunoData.id)_cover.jpg"
        let coverFileURL = sunoDataDirectory.appendingPathComponent(coverFileName)
        
        if FileManager.default.fileExists(atPath: coverFileURL.path) {
            try FileManager.default.removeItem(at: coverFileURL)
            print("🗑️ [SunoDataManager] Deleted cover file: \(coverFileName)")
        }
        
        print("✅ [SunoDataManager] SunoData deleted successfully")
    }
    
    // MARK: - Helper Methods
    func getLocalAudioPath(for songId: String) -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let sunoDataDirectory = documentsPath.appendingPathComponent("SunoData")
        
        // Try different possible file names
        let possibleFileNames = [
            "\(songId)_audio.mp3",
            "\(songId)_audio.wav", 
            "\(songId)_audio.m4a",
            "\(songId).mp3",
            "\(songId).wav",
            "\(songId).m4a"
        ]
        
        for fileName in possibleFileNames {
            let filePath = sunoDataDirectory.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: filePath.path) {
                return filePath
            }
        }
        
        return nil
    }
    
    func getLocalCoverPath(for songId: String) -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        var searchDirectories = [documentsPath.appendingPathComponent("SunoData")]
        
        // Also check LocalSongs directory if ID indicates it's a local song
        if songId.hasPrefix("local_") {
            searchDirectories.append(documentsPath.appendingPathComponent("LocalSongs"))
        }
        
        let possibleFileNames = [
            "\(songId)_cover.jpg",
            "\(songId)_cover.jpeg",
            "\(songId)_cover.png",
            "\(songId).jpg",
            "\(songId).jpeg",
            "\(songId).png"
        ]
        
        for directory in searchDirectories {
            for fileName in possibleFileNames {
                let filePath = directory.appendingPathComponent(fileName)
                if FileManager.default.fileExists(atPath: filePath.path) {
                    return filePath
                }
            }
        }
        
        return nil
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
    let sourceAudioUrl: String
    let streamAudioUrl: String
    let sourceStreamAudioUrl: String
    let imageUrl: String
    let sourceImageUrl: String
    let coverUrl: String // Local cover path
    let title: String
    let modelName: String
    var duration: Double
    let prompt: String
    let tags: String
    let createTime: Int64
    let savedAt: Int64
    
    // Community Sharing Fields
    var playCount: Int?
    var weekTag: String?
    var profileID: String?
    var isPublic: Bool?
    var likeCount: Int?
    var username: String?
}

// MARK: - SunoDataError
enum SunoDataError: Error {
    case invalidURL
    case fileNotFound
    case encodingError
    case decodingError
}
