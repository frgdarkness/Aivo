//
//  BackgroundGenerationManager.swift
//  Aivo
//
//  Created on 25/12/24.
//

import Foundation
import Combine
import UserNotifications
import UIKit

enum GenerationType {
    case song
    case cover
    case none
}

/// Manager to handle background music generation tasks independently of UI lifecycle
class BackgroundGenerationManager: ObservableObject {
    
    static let shared = BackgroundGenerationManager()
    
    // MARK: - Published State
    @Published var isGenerating = false
    @Published var resultSunoDataList: [SunoData] = []
    @Published var currentTaskId: String = ""
    @Published var error: Error?
    @Published var hasNewResult = false
    @Published var generationType: GenerationType = .none
    @Published var showSuccessDialog = false
    
    // MARK: - Private Properties
    private var generationTask: Task<Void, Never>?
    
    private init() {
        requestNotificationPermission()
    }
    
    // MARK: - Notifications
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                Logger.d("Notification permission granted", file: "BackgroundGenerationManager.swift")
            } else if let error = error {
                Logger.e("Notification permission denied: \(error.localizedDescription)", file: "BackgroundGenerationManager.swift")
            }
        }
    }
    
    private func sendGenerationCompleteNotification() {
        // Only send notification if app is in background or not active
        let content = UNMutableNotificationContent()
        content.title = "Song Generation Complete! 🎵"
        content.body = "Your new AI songs are ready. Tap to listen!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "SunoGenerationComplete", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.e("Failed to schedule notification: \(error)", file: "BackgroundGenerationManager.swift")
            } else {
                Logger.d("Notification scheduled", file: "BackgroundGenerationManager.swift")
            }
        }
    }
    
    // MARK: - Public API
    
    func startGeneration(
        prompt: String,
        style: String? = nil,
        title: String,
        customMode: Bool,
        instrumental: Bool,
        model: SunoModel,
        vocalGender: VocalGender? = nil,
        selectedMoods: [SongMood] = [],
        selectedGenres: [SongGenre] = []
    ) {
        guard !isGenerating else { return }
        
        Logger.i("Starting background generation...", file: "BackgroundGenerationManager.swift")
        isGenerating = true
        error = nil
        hasNewResult = false
        generationType = .song
        resultSunoDataList = [] // Clear previous results
        showSuccessDialog = false
        
        generationTask = Task {
            do {
                try await Task.sleep(nanoseconds: 500_000_000) // Delay slightly to ensure UI updates
                
                Logger.d("Calling API...", file: "BackgroundGenerationManager.swift")
                
                // Construct style string from moods and genres if style is not explicitly provided
                var styleToUse = style
                if styleToUse == nil || styleToUse?.isEmpty == true {
                    var styleComponents: [String] = []
                    styleComponents.append(contentsOf: selectedGenres.map { $0.displayName })
                    styleComponents.append(contentsOf: selectedMoods.map { $0.displayName })
                    styleToUse = styleComponents.joined(separator: ", ")
                }
                
                // Call API (this will take ~1-2 mins typically)
                 let (generatedSongs, jsonString) = try await SunoAiMusicService.shared.generateMusicWithRetry(
                    prompt: prompt,
                    style: styleToUse,
                    title: title.isEmpty ? nil : title,
                    customMode: customMode,
                    instrumental: instrumental,
                    model: model,
                    vocalGender: vocalGender
                )
                
                // Auto-download songs to library immediately
                Logger.i("Auto-downloading generated songs...", file: "BackgroundGenerationManager.swift")
                var savedSongs: [SunoData] = []
                
                
                for songData in generatedSongs {
                    do {
                        // This will trigger the download and save to SwiftData/LocalStorage
                        // Log auto download start
//                        AnalyticsLogger.shared.logAutoDownloadStart()
                        
                        let savedUrl = try await SunoDataManager.shared.saveSunoData(songData)
                        
                        // Log auto download success
//                        AnalyticsLogger.shared.logAutoDownloadSuccess()
                        
                        Logger.i("Successfully downloaded and saved: \(songData.title) to \(savedUrl.path)", file: "BackgroundGenerationManager.swift")
                        // Reload SunoData with correct local paths if needed, but SunoDataManager saves it to disk.
                        // We will use the original songData but it should be fine as UI uses async image/audio.
                        // Ideally we should construct a SunoData that points to local path, but SunoData struct uses String URLs.
                        // For now we use the one returned from API, the local saving is for library persistence.
                        savedSongs.append(songData)
                    } catch {
                        Logger.e("Failed to auto-download song: \(songData.title), error: \(error)", file: "BackgroundGenerationManager.swift")
                        savedSongs.append(songData)
                    }
                }
                
                await MainActor.run {
                    self.isGenerating = false
                    self.resultSunoDataList = savedSongs
                    self.currentTaskId = UUID().uuidString // TaskId is already handled in Service but we can just use Random
                    self.hasNewResult = true
                    
                    // Log Success
                    // Log Success
                    AnalyticsLogger.shared.logEventWithBundle(AnalyticsLogger.EVENT.EVENT_GENERATE_SONG_SUCCESS, parameters: [
                        "songs_count": savedSongs.count,
                        "model": model.rawValue,
                        "timestamp": Date().timeIntervalSince1970
                    ])
                    
                    Logger.i("Generation & Download successful!", file: "BackgroundGenerationManager.swift")
                    
                    // Show dialog if app is active, otherwise notification
                    if UIApplication.shared.applicationState == .active {
                        self.showSuccessDialog = true
                    } else {
                         self.sendGenerationCompleteNotification()
                         self.showSuccessDialog = true // Also show dialog so it's there when they open app
                    }
                     

                    // Log output to Firebase
                    Task {
                        try? await FirebaseRealtimeService.shared.logGeneratedSong(jsonString: jsonString)
                    }
                    
                    // Try to show rating dialog
                    AppRatingManager.shared.tryShowRateApp()
                }
                
            } catch is CancellationError {
                Logger.w("Task cancelled", file: "BackgroundGenerationManager.swift")
                await MainActor.run {
                    self.isGenerating = false
                }
            } catch {
                Logger.e("Error: \(error)", file: "BackgroundGenerationManager.swift")
                await MainActor.run {
                    self.isGenerating = false
                    self.error = error
                    
                    AnalyticsLogger.shared.logEventWithBundle(AnalyticsLogger.EVENT.EVENT_GENERATE_SONG_FAILED, parameters: ["error": error.localizedDescription])
                }
            }
        }
    }
    
    func cancelGeneration() {
        Logger.w("Cancelling generation...", file: "BackgroundGenerationManager.swift")
        generationTask?.cancel()
        generationTask = nil
        isGenerating = false
    }
    
    func resetState() {
        hasNewResult = false
        error = nil
        resultSunoDataList = []
        currentTaskId = ""
        generationType = .none
        showSuccessDialog = false
    }
    
    // MARK: - Cover Generation
    
    func startCoverGeneration(
        audioUrl: String? = nil,
        fileData: Data? = nil,
        fileName: String? = nil,
        modelId: String,
        songName: String,
        modelName: String, // The display name of the model
        coverImageUrl: String? = nil,
        audioSource: String // "youtube" or "song"
    ) {
        guard !isGenerating else { return }
        
        Logger.i("Starting background cover generation...", file: "BackgroundGenerationManager.swift")
        isGenerating = true
        error = nil
        hasNewResult = false
        generationType = .cover
        resultSunoDataList = []
        showSuccessDialog = false
        
        generationTask = Task {
            do {
                try await Task.sleep(nanoseconds: 500_000_000) 
                
                let modelsLabService = ModelsLabService.shared
                var resultUrl: String?
                
                if let fileData = fileData, let fileName = fileName {
                     // File Upload flow
                     resultUrl = await modelsLabService.processVoiceCoverWithFile(
                        fileData: fileData,
                        fileName: fileName,
                        modelID: modelId
                    )
                } else if let audioUrl = audioUrl {
                    // URL flow
                    resultUrl = await modelsLabService.processVoiceCover(
                        audioUrl: audioUrl,
                        modelID: modelId
                    )
                }
                
                guard let rawUrl = resultUrl else {
                    throw ModelsLabError.invalidResponse
                }
                
                // Trim logic to prevent whitespace issues
                let finalUrl = rawUrl.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !finalUrl.isEmpty else {
                    throw ModelsLabError.invalidResponse
                }
                
                // Create SunoData from result
                let sunoData = createSunoDataFromCoverResult(
                    audioUrl: finalUrl,
                    title: songName,
                    modelName: modelName,
                    coverImageUrl: coverImageUrl,
                    prompt: "Cover by \(modelName)"
                )
                
                // Auto-download to library with retry
                Logger.i("Auto-downloading generated cover...", file: "BackgroundGenerationManager.swift")
                var savedSongs: [SunoData] = []
                
                var attempts = 0
                let maxRetries = 5
                var success = false
                
                while !success && attempts <= maxRetries {
                    do {
                        let savedUrl = try await SunoDataManager.shared.saveSunoData(sunoData)
                        Logger.i("Successfully downloaded and saved cover: \(sunoData.title) at \(savedUrl.path)", file: "BackgroundGenerationManager.swift")
                        
                        // Log Cover Success (Only if save succeeded)
                        AnalyticsLogger.shared.logEventWithBundle(AnalyticsLogger.EVENT.EVENT_GENERATE_COVER_SUCCESS, parameters: [
                            "source": audioSource,
                            "model_id": modelId,
                            "timestamp": Date().timeIntervalSince1970
                        ])
                        
                        savedSongs.append(sunoData)
                        success = true
                    } catch {
                        attempts += 1
                        Logger.e("Failed to save cover (Attempt \(attempts)/\(maxRetries + 1)): \(error)", file: "BackgroundGenerationManager.swift")
                        
                        if attempts <= maxRetries {
                            Logger.i("Retrying in 2 seconds...", file: "BackgroundGenerationManager.swift")
                            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                        } else {
                             // Final failure
                             savedSongs.append(sunoData)
                        }
                    }
                }
                
                await MainActor.run {
                    self.isGenerating = false
                    self.resultSunoDataList = savedSongs
                    self.currentTaskId = UUID().uuidString
                    self.hasNewResult = true
                    
                    if UIApplication.shared.applicationState == .active {
                        self.showSuccessDialog = true
                    } else {
                         self.sendGenerationCompleteNotification()
                         self.showSuccessDialog = true
                    }
                    
                    // Try to show rating dialog
                    AppRatingManager.shared.tryShowRateApp()
                }
                
            } catch is CancellationError {
                Logger.w("Cover task cancelled", file: "BackgroundGenerationManager.swift")
                await MainActor.run { self.isGenerating = false }
            } catch {
                Logger.e("Cover Error: \(error)", file: "BackgroundGenerationManager.swift")
                await MainActor.run {
                    self.isGenerating = false
                    self.error = error
                    
                    AnalyticsLogger.shared.logEventWithBundle(AnalyticsLogger.EVENT.EVENT_GENERATE_COVER_FAILED, parameters: ["error": error.localizedDescription])
                }
            }
        }
    }
    
    private func createSunoDataFromCoverResult(audioUrl: String, title: String, modelName: String, coverImageUrl: String?, prompt: String) -> SunoData {
        // Create SunoData for cover song
        return SunoData(
            id: UUID().uuidString,
            audioUrl: audioUrl,
            imageUrl: coverImageUrl ?? "https://placeholder", // Placeholder or empty, adapter handles it
             sourceImageUrl: coverImageUrl ?? "",
            prompt: prompt,
            modelName: modelName, // AI model name as artist
            title: title,
            tags: "cover, \(modelName)",
            createTime: Int64(Date().timeIntervalSince1970 * 1000)
        )
    }
}
