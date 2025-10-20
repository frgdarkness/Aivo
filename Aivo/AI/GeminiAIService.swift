import Foundation
import SwiftUI
import UIKit
//#if canImport(FirebaseAI)
import FirebaseAI
//#endif

// MARK: - GeminiAIService Protocol
protocol GeminiAIServiceProtocol {
    func genImage(prompt: String) async throws -> UIImage
    func editImage(prompt: String, imageUri: String?, imageUrl: String?) async throws -> UIImage
    func editImageWithMask(prompt: String, imageUri: String?, imageUrl: String?, maskUri: String?) async throws -> UIImage
}

// MARK: - GeminiAIService
// NOTE: Placeholder implementation wired for project compilation.
// You can integrate Firebase AI Logic as per docs:
// https://firebase.google.com/docs/ai-logic/generate-images-gemini?authuser=0&api=dev#text-to-image
// Swap internals of the async methods below with real SDK calls.
final class GeminiAIService: GeminiAIServiceProtocol {
    enum ServiceError: Error { case invalidInput, loadFailed }
    
    // MARK: - Configuration
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 1.0
    
    // MARK: - Firebase AI Logic Model
    #if canImport(FirebaseAI)
    private lazy var model: GenerativeModel = {
        Logger.d("Initializing Firebase AI model...")
        let backend = FirebaseAI.firebaseAI(backend: .googleAI())
        Logger.d("Firebase AI backend created: \(backend)")
        
        let config = GenerationConfig(responseModalities: [.text, .image])
        Logger.d("Generation config created: \(config)")
        
        let model = backend.generativeModel(
            modelName: "gemini-2.5-flash-image-preview",
            generationConfig: config
        )
        Logger.d("Generative model created: \(model)")
        return model
    }()
    #endif

    // Generate image from text prompt
    func genImage(prompt: String) async throws -> UIImage {
        Logger.d("GeminiAIService: genImage called with prompt: \(prompt)")
        
        #if canImport(FirebaseAI)
        Logger.d("FirebaseAI is available for genImage")
        #else
        Logger.e("FirebaseAI is NOT available for genImage - check imports and configuration")
        #endif
        
        let startTime = Date()
        Logger.d("GeminiAIService: genImage started at \(startTime)")
        
        for attempt in 1...maxRetries {
            do {
                Logger.d("GeminiAIService: genImage attempt \(attempt)/\(maxRetries)")
                let result = try await performGenImage(prompt: prompt)
                let endTime = Date()
                let duration = endTime.timeIntervalSince(startTime)
                Logger.d("GeminiAIService: genImage completed successfully in \(String(format: "%.2f", duration)) seconds")
                return result
            } catch {
                Logger.e("GeminiAIService: genImage attempt \(attempt) failed: \(error)")
                if attempt < maxRetries {
                    Logger.d("GeminiAIService: Retrying in \(retryDelay) seconds...")
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                } else {
                    let endTime = Date()
                    let duration = endTime.timeIntervalSince(startTime)
                    Logger.e("GeminiAIService: genImage failed after \(maxRetries) attempts in \(String(format: "%.2f", duration)) seconds")
                    throw error
                }
            }
        }
        
        throw ServiceError.loadFailed
    }
    
    private func performGenImage(prompt: String) async throws -> UIImage {
        #if canImport(FirebaseAI)
        Logger.d("FirebaseAI is available, calling generateContent")
        Logger.d("Model configuration: \(model)")
        Logger.d("Prompt length: \(prompt.count) characters")
        
        do {
            let response = try await model.generateContent(prompt)
            Logger.d("generateContent response received")
            Logger.d("Response inline data parts count: \(response.inlineDataParts.count)")
            Logger.d("Response candidates count: \(response.candidates.count)")
            
            // Log response details
            if let candidate = response.candidates.first {
                Logger.d("First candidate finish reason: \(candidate.finishReason?.rawValue ?? "unknown")")
                Logger.d("First candidate safety ratings: \(candidate.safetyRatings.map { "\($0.category.rawValue): \($0.probability.rawValue)" })")
            }

            
            // Log inline data parts details
            for (index, dataPart) in response.inlineDataParts.enumerated() {
                Logger.d("Inline data part \(index): mimeType=\(dataPart.mimeType), dataSize=\(dataPart.data.count) bytes")
            }

            // Handle the generated image
            guard let inlineDataPart = response.inlineDataParts.first else {
                Logger.e("ERROR: No image data in response")
                //Logger.e("Available parts: textParts=\(response.textParts.count), inlineDataParts=\(response.inlineDataParts.count)")
                throw ServiceError.loadFailed
            }
            
            Logger.d("Image data size: \(inlineDataPart.data.count) bytes")
            Logger.d("Image MIME type: \(inlineDataPart.mimeType)")
            
            guard let uiImage = UIImage(data: inlineDataPart.data) else {
                Logger.e("ERROR: Failed to convert data to UIImage")
                Logger.e("Data first 20 bytes: \(Array(inlineDataPart.data.prefix(20)))")
                throw ServiceError.loadFailed
            }
            
            Logger.d("Successfully created UIImage from response")
            Logger.d("UIImage size: \(uiImage.size)")
            return uiImage
        } catch {
            Logger.e("FirebaseAI generateContent failed with error: \(error)")
            Logger.e("Error type: \(type(of: error))")
            Logger.e("Error localized description: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                Logger.e("NSError domain: \(nsError.domain), code: \(nsError.code)")
                Logger.e("NSError userInfo: \(nsError.userInfo)")
            }
            throw error
        }
        #else
        Logger.e("FirebaseAI not available, throwing error")
        Logger.e("Please check Firebase AI integration and imports")
        throw ServiceError.loadFailed
        #endif
    }

    // Edit image (no mask)
    func editImage(prompt: String, imageUri: String?, imageUrl: String?) async throws -> UIImage {
        Logger.d("GeminiAIService: editImage called with prompt: \(prompt), imageUri: \(imageUri ?? "nil"), imageUrl: \(imageUrl ?? "nil")")
        
        #if canImport(FirebaseAI)
        Logger.d("FirebaseAI is available for editImage")
        #else
        Logger.e("FirebaseAI is NOT available for editImage - check imports and configuration")
        #endif
        
        let startTime = Date()
        Logger.d("GeminiAIService: editImage started at \(startTime)")
        
        for attempt in 1...maxRetries {
            do {
                Logger.d("GeminiAIService: editImage attempt \(attempt)/\(maxRetries)")
                let result = try await performEditImage(prompt: prompt, imageUri: imageUri, imageUrl: imageUrl)
                let endTime = Date()
                let duration = endTime.timeIntervalSince(startTime)
                Logger.d("GeminiAIService: editImage completed successfully in \(String(format: "%.2f", duration)) seconds")
                return result
            } catch {
                Logger.e("GeminiAIService: editImage attempt \(attempt) failed: \(error)")
                if attempt < maxRetries {
                    Logger.d("GeminiAIService: Retrying in \(retryDelay) seconds...")
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                } else {
                    let endTime = Date()
                    let duration = endTime.timeIntervalSince(startTime)
                    Logger.e("GeminiAIService: editImage failed after \(maxRetries) attempts in \(String(format: "%.2f", duration)) seconds")
                    throw error
                }
            }
        }
        
        throw ServiceError.loadFailed
    }
    
    private func performEditImage(prompt: String, imageUri: String?, imageUrl: String?) async throws -> UIImage {
        // Load image data (local preferred)
        guard let imageData = try await loadImageData(localUri: imageUri, remoteUrl: imageUrl) else {
            Logger.e("ERROR: Failed to load image data")
            Logger.e("imageUri: \(imageUri ?? "nil"), imageUrl: \(imageUrl ?? "nil")")
            throw ServiceError.invalidInput
        }
        Logger.d("Image data loaded successfully, size: \(imageData.count) bytes")
        #if canImport(FirebaseAI)
        Logger.d("FirebaseAI is available, calling generateContent with image")
        let mime = Self.mimeType(for: imageData) ?? "image/jpeg"
        Logger.d("Detected MIME type: \(mime)")
        
        let imagePart = InlineDataPart(data: imageData, mimeType: mime)
        let promptData = TextPart(prompt)
        Logger.d("Created parts - prompt length: \(prompt.count), image size: \(imageData.count) bytes")
        
        do {
            let response = try await model.generateContent([promptData, imagePart])
            Logger.d("generateContent response received")
            Logger.d("Response inline data parts count: \(response.inlineDataParts.count)")
            Logger.d("Response candidates count: \(response.candidates.count)")
            
            // Log response details
            if let candidate = response.candidates.first {
                Logger.d("First candidate finish reason: \(candidate.finishReason?.rawValue ?? "unknown")")
                Logger.d("First candidate safety ratings: \(candidate.safetyRatings.map { "\($0.category.rawValue): \($0.probability.rawValue)" })")
            }
            
            // Log inline data parts details
            for (index, dataPart) in response.inlineDataParts.enumerated() {
                Logger.d("Inline data part \(index): mimeType=\(dataPart.mimeType), dataSize=\(dataPart.data.count) bytes")
            }
            
            guard let bytes = response.inlineDataParts.first?.data,
                  let image = UIImage(data: Data(bytes)) else { 
                Logger.e("ERROR: Failed to create UIImage from response")
                if let firstDataPart = response.inlineDataParts.first {
                    Logger.e("First data part: mimeType=\(firstDataPart.mimeType), size=\(firstDataPart.data.count) bytes")
                    Logger.e("Data first 20 bytes: \(Array(firstDataPart.data.prefix(20)))")
                }
                throw ServiceError.loadFailed 
            }
            
            Logger.d("Successfully created UIImage from response")
            Logger.d("Generated image size: \(image.size)")
            return image
        } catch {
            Logger.e("FirebaseAI generateContent failed with error: \(error)")
            Logger.e("Error type: \(type(of: error))")
            Logger.e("Error localized description: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                Logger.e("NSError domain: \(nsError.domain), code: \(nsError.code)")
                Logger.e("NSError userInfo: \(nsError.userInfo)")
            }
            throw error
        }
        #else
        Logger.w("FirebaseAI not available, returning original image")
        Logger.w("Please check Firebase AI integration and imports")
        if let img = UIImage(data: imageData) { 
            Logger.d("Returning original image with size: \(img.size)")
            return img 
        }
        throw ServiceError.loadFailed
        #endif
    }

    // Edit image with mask
    func editImageWithMask(prompt: String, imageUri: String?, imageUrl: String?, maskUri: String?) async throws -> UIImage {
        Logger.d("GeminiAIService: editImageWithMask called with prompt: \(prompt), imageUri: \(imageUri ?? "nil"), imageUrl: \(imageUrl ?? "nil"), maskUri: \(maskUri ?? "nil")")
        
        #if canImport(FirebaseAI)
        Logger.d("FirebaseAI is available for editImageWithMask")
        #else
        Logger.e("FirebaseAI is NOT available for editImageWithMask - check imports and configuration")
        #endif
        
        let startTime = Date()
        Logger.d("GeminiAIService: editImageWithMask started at \(startTime)")
        
        for attempt in 1...maxRetries {
            do {
                Logger.d("GeminiAIService: editImageWithMask attempt \(attempt)/\(maxRetries)")
                let result = try await performEditImageWithMask(prompt: prompt, imageUri: imageUri, imageUrl: imageUrl, maskUri: maskUri)
                let endTime = Date()
                let duration = endTime.timeIntervalSince(startTime)
                Logger.d("GeminiAIService: editImageWithMask completed successfully in \(String(format: "%.2f", duration)) seconds")
                return result
            } catch {
                Logger.e("GeminiAIService: editImageWithMask attempt \(attempt) failed: \(error)")
                if attempt < maxRetries {
                    Logger.d("GeminiAIService: Retrying in \(retryDelay) seconds...")
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                } else {
                    let endTime = Date()
                    let duration = endTime.timeIntervalSince(startTime)
                    Logger.e("GeminiAIService: editImageWithMask failed after \(maxRetries) attempts in \(String(format: "%.2f", duration)) seconds")
                    throw error
                }
            }
        }
        
        throw ServiceError.loadFailed
    }
    
    private func performEditImageWithMask(prompt: String, imageUri: String?, imageUrl: String?, maskUri: String?) async throws -> UIImage {
        guard let imageData = try await loadImageData(localUri: imageUri, remoteUrl: imageUrl) else {
            Logger.e("ERROR: Failed to load image data for editImageWithMask")
            Logger.e("imageUri: \(imageUri ?? "nil"), imageUrl: \(imageUrl ?? "nil")")
            throw ServiceError.invalidInput
        }
        guard let maskData = try await loadImageData(localUri: maskUri, remoteUrl: nil) else {
            Logger.e("ERROR: Failed to load mask data for editImageWithMask")
            Logger.e("maskUri: \(maskUri ?? "nil")")
            throw ServiceError.invalidInput
        }
        Logger.d("Image data loaded successfully for editImageWithMask, size: \(imageData.count) bytes")
        Logger.d("Mask data loaded successfully for editImageWithMask, size: \(maskData.count) bytes")
        #if canImport(FirebaseAI)
        Logger.d("FirebaseAI is available, calling generateContent with image and mask")
        let imageMime = Self.mimeType(for: imageData) ?? "image/jpeg"
        let maskMime = Self.mimeType(for: maskData) ?? "image/jpeg"
        Logger.d("Image MIME type: \(imageMime), Mask MIME type: \(maskMime)")
        
        let imagePart = InlineDataPart(data: imageData, mimeType: imageMime)
        let maskPart = InlineDataPart(data: maskData, mimeType: maskMime)
        Logger.d("Created parts - prompt length: \(prompt.count), image size: \(imageData.count) bytes, mask size: \(maskData.count) bytes")
        
        do {
            let response = try await model.generateContent(prompt, imagePart, maskPart)
            Logger.d("generateContent response received for editImageWithMask")
            Logger.d("Response inline data parts count: \(response.inlineDataParts.count)")
            Logger.d("Response candidates count: \(response.candidates.count)")
            
            // Log response details
            if let candidate = response.candidates.first {
                Logger.d("First candidate finish reason: \(candidate.finishReason?.rawValue ?? "unknown")")
                Logger.d("First candidate safety ratings: \(candidate.safetyRatings.map { "\($0.category.rawValue): \($0.probability.rawValue)" })")
            }
            
            // Log inline data parts details
            for (index, dataPart) in response.inlineDataParts.enumerated() {
                Logger.d("Inline data part \(index): mimeType=\(dataPart.mimeType), dataSize=\(dataPart.data.count) bytes")
            }
            
            guard let bytes = response.inlineDataParts.first?.data,
                  let image = UIImage(data: Data(bytes)) else { 
                Logger.e("ERROR: Failed to get image data from response for editImageWithMask")
                if let firstDataPart = response.inlineDataParts.first {
                    Logger.e("First data part: mimeType=\(firstDataPart.mimeType), size=\(firstDataPart.data.count) bytes")
                    Logger.e("Data first 20 bytes: \(Array(firstDataPart.data.prefix(20)))")
                }
                throw ServiceError.loadFailed 
            }
            Logger.d("Successfully created UIImage from response for editImageWithMask")
            Logger.d("Generated image size: \(image.size)")
            return image
        } catch {
            Logger.e("FirebaseAI generateContent failed with error for editImageWithMask: \(error)")
            Logger.e("Error type: \(type(of: error))")
            Logger.e("Error localized description: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                Logger.e("NSError domain: \(nsError.domain), code: \(nsError.code)")
                Logger.e("NSError userInfo: \(nsError.userInfo)")
            }
            throw error
        }
        #else
        Logger.w("FirebaseAI not available, returning original image")
        Logger.w("Please check Firebase AI integration and imports")
        if let img = UIImage(data: imageData) { 
            Logger.d("Returning original image with size: \(img.size)")
            return img 
        }
        throw ServiceError.loadFailed
        #endif
    }

    // MARK: - Helpers
    private static func loadLocalImage(uri: String) -> UIImage? {
        let url = URL(fileURLWithPath: uri)
        if let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
            return img
        }
        return nil
    }

    private static func loadImage(fromUrl urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else { throw ServiceError.invalidInput }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw ServiceError.loadFailed
        }
        guard let image = UIImage(data: data) else { throw ServiceError.loadFailed }
        return image
    }

    private func loadImageData(localUri: String?, remoteUrl: String?) async throws -> Data? {
        if let localUri, let data = Self.loadLocalData(uri: localUri) { return data }
        if let remoteUrl, let url = URL(string: remoteUrl) {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { return nil }
            return data
        }
        return nil
    }

    private static func loadLocalData(uri: String) -> Data? {
        let url = URL(fileURLWithPath: uri)
        return try? Data(contentsOf: url)
    }

    private static func mimeType(for data: Data) -> String? {
        // Basic magic numbers detection for PNG/JPEG
        if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return "image/png" }
        if data.starts(with: [0xFF, 0xD8, 0xFF]) { return "image/jpeg" }
        return nil
    }
}


