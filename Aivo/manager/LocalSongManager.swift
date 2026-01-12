import Foundation
import UIKit
import AVFoundation

class LocalSongManager {
    static let shared = LocalSongManager()
    
    private let fileManager = FileManager.default
    
    private init() {}
    
    // MARK: - Directory Management
    private func getLocalSongsDirectory() -> URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let localSongsDir = documentsPath.appendingPathComponent("LocalSongs")
        
        if !fileManager.fileExists(atPath: localSongsDir.path) {
            try? fileManager.createDirectory(at: localSongsDir, withIntermediateDirectories: true)
        }
        
        return localSongsDir
    }
    
    // MARK: - Validation
    func isAudioFile(_ url: URL) -> Bool {
        let allowedExtensions = ["mp3", "wav", "m4a", "aac", "flac"]
        return allowedExtensions.contains(url.pathExtension.lowercased())
    }
    
    // MARK: - Import
    func importSong(from url: URL) throws -> SunoData {
        // 1. Generate unique ID
        let id = "local_" + UUID().uuidString
        let directory = getLocalSongsDirectory()
        let destinationURL = directory.appendingPathComponent("\(id).\(url.pathExtension)")
        
        // 2. Copy file to app storage (using secure copy if from arbitrary location)
        if url.startAccessingSecurityScopedResource() {
            defer { url.stopAccessingSecurityScopedResource() }
            try fileManager.copyItem(at: url, to: destinationURL)
        } else {
             try fileManager.copyItem(at: url, to: destinationURL)
        }
        
        // 3. Extract Metadata (Title, Duration, Artwork)
        let asset = AVAsset(url: destinationURL)
        let duration = CMTimeGetSeconds(asset.duration)
        
        var title = url.deletingPathExtension().lastPathComponent
        // Try to read metadata title if available
        let metadata = asset.commonMetadata
        if let titleItem = metadata.first(where: { $0.commonKey == .commonKeyTitle }),
           let titleValue = titleItem.stringValue {
            title = titleValue
        }
        
        // Extract and Save Artwork
        if let artworkItem = metadata.first(where: { $0.commonKey == .commonKeyArtwork }),
           let artworkData = artworkItem.dataValue {
             let coverURL = directory.appendingPathComponent("\(id)_cover.jpg")
             try? artworkData.write(to: coverURL)
        }
        
        // 4. Create SunoData
        // Local songs act as SunoData but with specific "Local" model name
        // We set audioUrl to the local file path (absolute string)
        
        let localSong = SunoData(
            id: id,
            audioUrl: destinationURL.absoluteString,
            sourceAudioUrl: destinationURL.absoluteString,
            streamAudioUrl: destinationURL.absoluteString, 
            sourceStreamAudioUrl: destinationURL.absoluteString,
            imageUrl: "", // Handled by getLocalCoverPath logic
            sourceImageUrl: "",
            prompt: "Imported from local storage",
            modelName: "Local",
            title: title,
            tags: "Local",
            createTime: Int64(Date().timeIntervalSince1970 * 1000),
            duration: duration
        )
        
        return localSong
    }
    
    // MARK: - List
    func fetchLocalSongs() -> [SunoData] {
        let directory = getLocalSongsDirectory()
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey], options: [.skipsHiddenFiles])
            
            var songs: [SunoData] = []
            
            for fileURL in fileURLs {
                if isAudioFile(fileURL) {
                    let id = fileURL.deletingPathExtension().lastPathComponent
                    // Simple reconstruction. For robust implementation, we might want to store metadata JSON side-by-side like SunoData
                    // But for "Import", re-parsing file info is okay for MVP
                    
                    let asset = AVAsset(url: fileURL)
                    let duration = CMTimeGetSeconds(asset.duration)
                    
                    // Attempt to extract title/artist again or just use filename
                    // Ideally we should persist the metadata when importing to avoid re-parsing every time
                    // For now, let's assume filename is ID and we use it as basic info, relying on the fact that we can create a SunoData wrapper
                    
                    // NOTE: To make this persistent and consistent (keeping user-edited titles), 
                    // we ideally should have separate metadata storage like SunoDataManager.
                    // For this iteration, I'll create a Metadata file for local songs too.
                    if let metadata = loadLocalMetadata(id: id) {
                        // RECONSTRUCT URL: The absolute path in metadata might be valid only for the session it was saved.
                        // We must point it to the current fileURL.
                        var validMetadata = metadata
                        // Since SunoData properties are let (immutable), we need to create a new instance with the updated URL.
                        // Or if we can't modify it easily (it's a struct let), we have to use the init.
                        
                        let validSong = SunoData(
                            id: validMetadata.id,
                            audioUrl: fileURL.absoluteString, // Use current valid path
                            sourceAudioUrl: validMetadata.sourceAudioUrl,
                            streamAudioUrl: validMetadata.streamAudioUrl,
                            sourceStreamAudioUrl: validMetadata.sourceStreamAudioUrl,
                            imageUrl: validMetadata.imageUrl,
                            sourceImageUrl: validMetadata.sourceImageUrl,
                            prompt: validMetadata.prompt,
                            modelName: validMetadata.modelName,
                            title: validMetadata.title,
                            tags: validMetadata.tags,
                            createTime: validMetadata.createTime,
                            duration: validMetadata.duration
                        )
                        songs.append(validSong)
                    } else {
                        // Fallback reconstruction
                        let song = SunoData(
                            id: id,
                            audioUrl: fileURL.absoluteString,
                            modelName: "Local",
                            title: "Unknown Song", 
                            duration: duration
                        )
                        songs.append(song)
                    }
                }
            }
             // Sort by create time desc
            return songs.sorted(by: { $0.createTime > $1.createTime })
            
        } catch {
            print("❌ [LocalSongManager] Failed to fetch local songs: \(error)")
            return []
        }
    }
    
    // MARK: - Metadata Persistence (Simplified for Local)
    private func saveLocalMetadata(_ song: SunoData) {
        let directory = getLocalSongsDirectory()
        let metadataURL = directory.appendingPathComponent("\(song.id).json")
        do {
            let data = try JSONEncoder().encode(song)
            try data.write(to: metadataURL)
        } catch {
             print("❌ [LocalSongManager] Failed to save metadata: \(error)")
        }
    }
     
    private func loadLocalMetadata(id: String) -> SunoData? {
        let directory = getLocalSongsDirectory()
        let metadataURL = directory.appendingPathComponent("\(id).json")
        if fileManager.fileExists(atPath: metadataURL.path),
           let data = try? Data(contentsOf: metadataURL),
           let song = try? JSONDecoder().decode(SunoData.self, from: data) {
            return song
        }
        return nil
    }
    
    // Override import to save metadata
    func importAndSaveSong(from url: URL) throws -> SunoData {
        let song = try importSong(from: url)
        saveLocalMetadata(song)
        return song
    }
    
    func deleteLocalSong(_ song: SunoData) {
        let directory = getLocalSongsDirectory()
         // Delete audio
        if let url = URL(string: song.audioUrl) {
             try? fileManager.removeItem(at: url)
        }
         // Delete metadata
        let metadataURL = directory.appendingPathComponent("\(song.id).json")
        try? fileManager.removeItem(at: metadataURL)
    }
}
