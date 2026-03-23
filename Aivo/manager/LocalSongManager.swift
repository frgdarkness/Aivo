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
    func importSong(from url: URL) async throws -> SunoData {
        // 1. Generate unique ID
        let id = "local_" + UUID().uuidString
        let directory = getLocalSongsDirectory()
        let destinationURL = directory.appendingPathComponent("\(id).\(url.pathExtension)")
        
        Logger.d("📂 [LocalSongManager] Importing from: \(url.lastPathComponent)")
        
        // 2. Copy file to app storage (using secure copy if from arbitrary location)
        if url.startAccessingSecurityScopedResource() {
            defer { url.stopAccessingSecurityScopedResource() }
            try fileManager.copyItem(at: url, to: destinationURL)
        } else {
             try fileManager.copyItem(at: url, to: destinationURL)
        }
        
        Logger.d("📂 [LocalSongManager] File copied to: \(destinationURL.lastPathComponent)")
        
        // 3. Extract Metadata (Title, Artist, Duration, Artwork)
        let asset = AVURLAsset(url: destinationURL)
        
        // Load metadata & duration asynchronously (required on modern iOS)
        let loadedMetadata: [AVMetadataItem]
        let loadedDuration: CMTime
        
        if #available(iOS 16.0, *) {
            loadedMetadata = try await asset.load(.commonMetadata)
            loadedDuration = try await asset.load(.duration)
        } else {
            // Fallback for older iOS — use synchronous access
            await asset.loadValues(forKeys: ["commonMetadata", "duration"])
            loadedMetadata = asset.commonMetadata
            loadedDuration = asset.duration
        }
        
        let duration = CMTimeGetSeconds(loadedDuration)
        Logger.d("📂 [LocalSongManager] Duration: \(duration)s, Metadata items: \(loadedMetadata.count)")
        
        // Log all metadata for debugging
        for item in loadedMetadata {
            let key = item.commonKey?.rawValue ?? "nil"
            let value = item.stringValue ?? "(non-string)"
            Logger.d("📂 [LocalSongManager] Metadata — key: \(key), value: \(value)")
        }
        
        var title = url.deletingPathExtension().lastPathComponent
        var artist: String? = nil
        
        // Try to read metadata title and artist if available
        if let titleItem = loadedMetadata.first(where: { $0.commonKey == .commonKeyTitle }),
           let titleValue = titleItem.stringValue, !titleValue.isEmpty {
            title = titleValue
            Logger.d("📂 [LocalSongManager] ✅ Title from metadata: \(title)")
        } else {
            Logger.d("📂 [LocalSongManager] ⚠️ No title in metadata, using filename: \(title)")
        }
        
        if let artistItem = loadedMetadata.first(where: { $0.commonKey == .commonKeyArtist }),
           let artistValue = artistItem.stringValue, !artistValue.isEmpty {
            artist = artistValue
            Logger.d("📂 [LocalSongManager] ✅ Artist from metadata: \(artist!)")
        } else {
            Logger.d("📂 [LocalSongManager] ⚠️ No artist in metadata")
        }
        
        // Extract and Save Artwork
        if let artworkItem = loadedMetadata.first(where: { $0.commonKey == .commonKeyArtwork }),
           let artworkData = artworkItem.dataValue {
             let coverURL = directory.appendingPathComponent("\(id)_cover.jpg")
             try? artworkData.write(to: coverURL)
             Logger.d("📂 [LocalSongManager] ✅ Artwork saved")
        } else {
            Logger.d("📂 [LocalSongManager] ⚠️ No artwork in metadata")
        }
        
        // 4. Create SunoData
        Logger.d("📂 [LocalSongManager] Creating SunoData — title: \(title), artist: \(artist ?? "nil")")
        
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
            duration: duration,
            username: artist
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
                        
                        // If saved metadata has no real artist (nil or old default "Aivo Music"),
                        // try to re-extract from audio file metadata
                        var resolvedUsername = metadata.username
                        if resolvedUsername == nil || resolvedUsername == "Aivo Music" {
                            let audioMeta = asset.commonMetadata
                            if let artistItem = audioMeta.first(where: { $0.commonKey == .commonKeyArtist }),
                               let artistValue = artistItem.stringValue, !artistValue.isEmpty {
                                resolvedUsername = artistValue
                                Logger.d("📂 [LocalSongManager] Re-extracted artist for \(id): \(artistValue)")
                            }
                        }
                        
                        let validSong = SunoData(
                            id: metadata.id,
                            audioUrl: fileURL.absoluteString, // Use current valid path
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
                            username: resolvedUsername
                        )
                        songs.append(validSong)
                    } else {
                        // Fallback reconstruction — also try to extract artist
                        let metadata = asset.commonMetadata
                        var fallbackTitle = id
                        var fallbackArtist: String? = nil
                        
                        if let titleItem = metadata.first(where: { $0.commonKey == .commonKeyTitle }),
                           let titleValue = titleItem.stringValue {
                            fallbackTitle = titleValue
                        }
                        if let artistItem = metadata.first(where: { $0.commonKey == .commonKeyArtist }),
                           let artistValue = artistItem.stringValue {
                            fallbackArtist = artistValue
                        }
                        
                        let song = SunoData(
                            id: id,
                            audioUrl: fileURL.absoluteString,
                            modelName: "Local",
                            title: fallbackTitle, 
                            duration: duration,
                            username: fallbackArtist
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
    func importAndSaveSong(from url: URL) async throws -> SunoData {
        let song = try await importSong(from: url)
        saveLocalMetadata(song)
        Logger.d("📂 [LocalSongManager] ✅ Song saved with metadata — title: \(song.title), artist: \(song.username ?? "nil")")
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
