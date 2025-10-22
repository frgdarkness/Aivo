//
//  ModelSlabService.swift
//  DreamHomeAI
//
//  Created by AI Assistant on 2024-12-21.
//

import Foundation
import UIKit
import os


// MARK: - ModelSlab Service Protocol
protocol ModelSlabServiceProtocol {

    func removeObject(
        from image: UIImage,
        objectMask: UIImage
    ) async throws -> ModelSlabResponse
    
    func replaceObject(
        from image: UIImage,
        objectMask: UIImage,
        replacement: String
    ) async throws -> ModelSlabResponse

    // v7 - Image to Image (banana)
    func imageToImage(
        imageUri: URL?,
        imageUrl: String?,
        prompt: String
    ) async throws -> String

    // v7 - Text to Image
    func textToImageV7(
        prompt: String
    ) async throws -> String

    // Interior design with image init, matching Gemini params
//    func generateInterior(
//        prompt: String,
//        imageUri: String?,
//        imageUrl: String?
//    ) async throws -> UIImage
    
    func interiorDesign(
        prompt: String,
        imageUri: String?,
        imageUrl: String?
    ) async throws -> UIImage
    
    func exteriorDesign(
        prompt: String,
        imageUri: String?,
        imageUrl: String?
    ) async throws -> UIImage
}

// MARK: - ModelSlab Service Implementation
class ModelSlabService: ModelSlabServiceProtocol {
    
    // MARK: - Properties
    private let networkService: NetworkServiceProtocol
    private let apiKey: String = "pSzKzlKLmPrKQygqYlXUDR3lAB0Mb3G4YDgr1rmO91H2DhpkMRhrWG5vwsq3"
    private let baseURL = "https://modelslab.com/api/v6"
    private let imgbbApiKey: String = "7c66aba95d3a7691931152125cc697e4"
    private let compressionQuality: CGFloat = 0.8
    
    // MARK: - Initialization
    init(
        networkService: NetworkServiceProtocol = NetworkService(),
        //apiKey: String = Configuration.API.modelSlabAPIKey
    ) {
        self.networkService = networkService
        //self.apiKey = apiKey
    }
    
    func interiorDesign(prompt: String, imageUri: String?, imageUrl: String?) async throws -> UIImage {
        Logger.d("[ModelSlab] interiorDesign start | prompt=\(prompt)...")
        Logger.d("imageUri: \(String(describing: imageUri)) - imageUrl: \(String(describing: imageUrl))")

        // 🖼️ Chuẩn hóa ảnh đầu vào
        let primaryImage: String
        if let uriString = imageUri, !uriString.isEmpty {
            let fileURL = URL(fileURLWithPath: uriString)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    let data = try Data(contentsOf: fileURL)
                    if let uploaded = try await uploadToImgbb(imageData: data) {
                        primaryImage = uploaded
                        Logger.d("[ModelSlab] Uploaded local image | url=\(uploaded)")
                    } else {
                        let base64 = data.base64EncodedString()
                        primaryImage = "data:image/jpeg;base64,\(base64)"
                        Logger.w("[ModelSlab] Upload failed → fallback base64, size=\(data.count) bytes")
                    }
                } catch {
                    Logger.e("[ModelSlab] Failed to read local image: \(error.localizedDescription)")
                    throw APIError.encodingError
                }
            } else {
                Logger.w("[ModelSlab] imageUri path not found, treating as remote URL")
                primaryImage = uriString
            }
        } else if let imageUrl = imageUrl, !imageUrl.isEmpty {
            if imageUrl.hasPrefix("file://"), let f = URL(string: imageUrl), let data = try? Data(contentsOf: f) {
                if let uploaded = try await uploadToImgbb(imageData: data) {
                    primaryImage = uploaded
                } else {
                    let base64 = data.base64EncodedString()
                    primaryImage = "data:image/jpeg;base64,\(base64)"
                }
            } else {
                primaryImage = imageUrl
            }
        } else {
            throw APIError.unknown("❌ Missing imageUri or imageUrl for interior request")
        }

        Logger.d("[ModelSlab] interiorDesign input | init_image=\(primaryImage)")
        Logger.d("prompt = \(prompt)")

        // 🧠 Gửi request interior
        let requestBody = InteriorV7Request(
            prompt: prompt,
            initImage: primaryImage,
            key: apiKey
        )

        let url = URL(string: "https://modelslab.com/api/v6/interior/make")!
        Logger.d("[ModelSlab] POST v7 interior-design…")
        let firstResponse = try await performV7Request(url: url, request: requestBody)

        var finalURL: String?

        if firstResponse.isSuccess {
            finalURL = firstResponse.firstImageURL?.absoluteString
        } else if firstResponse.isProcessing {
            let requestId: String = firstResponse.id.map(String.init) ?? firstResponse.fetchResult ?? ""
            guard !requestId.isEmpty else {
                throw APIError.unknown("❌ Missing request_id for fetch polling")
            }

            Logger.d("[ModelSlab] status=processing → polling...")
            let timeoutSeconds: TimeInterval = 300
            let intervalNanoseconds: UInt64 = 5_000_000_000
            let start = Date()
            var attempt = 0

            while Date().timeIntervalSince(start) < timeoutSeconds {
                attempt += 1
                Logger.d("[ModelSlab] fetch attempt #\(attempt) | request_id=\(requestId)")
                let fetchResponse = try await performV6Fetch(requestId: requestId)
                Logger.d("[ModelSlab] fetch status: \(fetchResponse.status)")
                Logger.d("[ModelSlab] fetch status: \(fetchResponse)")
            
                if fetchResponse.status == "success" {
                    finalURL = fetchResponse.firstImageURL
                    break
                } else if fetchResponse.status == "error" {
                    throw APIError.aiServiceError(fetchResponse.message)
                }
                try await Task.sleep(nanoseconds: intervalNanoseconds)
            }
        }

        guard let imageUrlStr = finalURL, let imageUrlFinal = URL(string: imageUrlStr) else {
            throw APIError.unknown("❌ No output image URL found")
        }

        // ✅ Convert ảnh về UIImage
        Logger.d("[ModelSlab] Downloading final image...")
        let (data, _) = try await URLSession.shared.data(from: imageUrlFinal)
        guard let image = UIImage(data: data) else {
            throw APIError.decodingError
        }

        Logger.d("[ModelSlab] ✅ interiorDesign complete | image size: \(data.count) bytes")
        return image
    }

    func exteriorDesign(prompt: String, imageUri: String?, imageUrl: String?) async throws -> UIImage {
        Logger.d("[ModelSlab] exteriorDesign start | prompt=\(prompt)...")
        Logger.d("imageUri: \(String(describing: imageUri)) - imageUrl: \(String(describing: imageUrl))")

        // 🖼️ Chuẩn hóa ảnh đầu vào
        let primaryImage: String
        if let uriString = imageUri, !uriString.isEmpty {
            let fileURL = URL(fileURLWithPath: uriString)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    let data = try Data(contentsOf: fileURL)
                    if let uploaded = try await uploadToImgbb(imageData: data) {
                        primaryImage = uploaded
                        Logger.d("[ModelSlab] Uploaded local image | url=\(uploaded)")
                    } else {
                        let base64 = data.base64EncodedString()
                        primaryImage = "data:image/jpeg;base64,\(base64)"
                        Logger.w("[ModelSlab] Upload failed → fallback base64, size=\(data.count) bytes")
                    }
                } catch {
                    Logger.e("[ModelSlab] Failed to read local image: \(error.localizedDescription)")
                    throw APIError.encodingError
                }
            } else {
                Logger.w("[ModelSlab] imageUri path not found, treating as remote URL")
                primaryImage = uriString
            }
        } else if let imageUrl = imageUrl, !imageUrl.isEmpty {
            if imageUrl.hasPrefix("file://"), let f = URL(string: imageUrl), let data = try? Data(contentsOf: f) {
                if let uploaded = try await uploadToImgbb(imageData: data) {
                    primaryImage = uploaded
                } else {
                    let base64 = data.base64EncodedString()
                    primaryImage = "data:image/jpeg;base64,\(base64)"
                }
            } else {
                primaryImage = imageUrl
            }
        } else {
            throw APIError.unknown("❌ Missing imageUri or imageUrl for exterior request")
        }

        Logger.d("[ModelSlab] exteriorDesign input | init_image=\(primaryImage)")
        Logger.d("prompt = \(prompt)")

        // 📤 Gửi request exterior
        let requestBody = ExteriorV7Request(
            prompt: prompt,
            initImage: primaryImage,
            key: apiKey
        )

        let url = URL(string: "https://modelslab.com/api/v6/interior/exterior_restorer")!
        Logger.d("[ModelSlab] POST v7 exterior-design…")
        let firstResponse = try await performV7Request(url: url, request: requestBody)

        var finalURL: String?

        // ✅ Nếu đã có kết quả sẵn
        if firstResponse.isSuccess {
            finalURL = firstResponse.firstImageURL?.absoluteString
        }
        // 🔄 Nếu vẫn đang xử lý → poll liên tục
        else if firstResponse.isProcessing {
            let requestId: String = firstResponse.id.map(String.init) ?? firstResponse.fetchResult ?? ""
            guard !requestId.isEmpty else {
                throw APIError.unknown("❌ Missing request_id for fetch polling")
            }

            Logger.d("[ModelSlab] status=processing → polling...")
            let timeoutSeconds: TimeInterval = 300
            let intervalNanoseconds: UInt64 = 5_000_000_000
            let start = Date()
            var attempt = 0

            while Date().timeIntervalSince(start) < timeoutSeconds {
                attempt += 1
                Logger.d("[ModelSlab] fetch attempt #\(attempt) | request_id=\(requestId)")
                let fetchResponse = try await performV6Fetch(requestId: requestId)
                Logger.d("[ModelSlab] fetch status: \(fetchResponse.status)")

                if fetchResponse.status == "success" {
                    finalURL = fetchResponse.firstImageURL
                    break
                } else if fetchResponse.status == "error" {
                    throw APIError.aiServiceError(fetchResponse.message)
                }
                try await Task.sleep(nanoseconds: intervalNanoseconds)
            }
        }

        guard let imageUrlStr = finalURL, let imageUrlFinal = URL(string: imageUrlStr) else {
            throw APIError.unknown("❌ No output image URL found")
        }

        // 📥 Convert ảnh sang UIImage
        Logger.d("[ModelSlab] Downloading final image...")
        let (data, _) = try await URLSession.shared.data(from: imageUrlFinal)
        guard let image = UIImage(data: data) else {
            throw APIError.decodingError
        }

        Logger.d("[ModelSlab] ✅ exteriorDesign complete | image size: \(data.count) bytes")
        return image
    }

    func removeObject(
        from image: UIImage,
        objectMask: UIImage
    ) async throws -> ModelSlabResponse {
        
        guard let imageData = image.jpegData(compressionQuality: compressionQuality),
              let maskData = objectMask.jpegData(compressionQuality: 1.0) else {
            throw APIError.encodingError
        }
        
        try validateImageSize(imageData)
        
        let request = ModelSlabRequest(
            key: apiKey,
            modelId: "inpainting-v1",
            prompt: "high quality interior design, clean, professional",
            negativePrompt: buildNegativePrompt(),
            width: 1024,
            height: 1024,
            samples: 1,
            numInferenceSteps: 25,
            guidanceScale: 7.5,
            seed: nil,
            initImage: imageData.base64EncodedString(),
            maskImage: maskData.base64EncodedString(),
            strength: 1.0,
            scheduler: "DPMSolverMultistep",
            webhook: nil,
            trackId: UUID().uuidString
        )
        
        return try await performRequest(request: request)
    }
    
    func replaceObject(
        from image: UIImage,
        objectMask: UIImage,
        replacement: String
    ) async throws -> ModelSlabResponse {
        
        guard let imageData = image.jpegData(compressionQuality: compressionQuality),
              let maskData = objectMask.jpegData(compressionQuality: 1.0) else {
            throw APIError.encodingError
        }
        
        try validateImageSize(imageData)
        
        let prompt = "\(replacement), high quality, professional interior design, realistic lighting"
        
        let request = ModelSlabRequest(
            key: apiKey,
            modelId: "inpainting-v1",
            prompt: prompt,
            negativePrompt: buildNegativePrompt(),
            width: 1024,
            height: 1024,
            samples: 1,
            numInferenceSteps: 30,
            guidanceScale: 7.5,
            seed: nil,
            initImage: imageData.base64EncodedString(),
            maskImage: maskData.base64EncodedString(),
            strength: 0.9,
            scheduler: "DPMSolverMultistep",
            webhook: nil,
            trackId: UUID().uuidString
        )
        
        return try await performRequest(request: request)
    }

    // MARK: - v7 Image-to-Image (banana)
    func imageToImage(
        imageUri: URL?,
        imageUrl: String?,
        prompt: String
    ) async throws -> String {
        Logger.d("[ModelSlab] imageToImage start | prompt=\(prompt)...")
        Logger.d("imageUri: \(String(describing: imageUri)) - imageUrl: \(String(describing: imageUrl))")
        // Prefer local/remote URI if provided, otherwise fallback to direct URL string
        let primaryImage: String
        if let uri = imageUri {
            if uri.isFileURL {
                do {
                    let data = try prepareUploadData(from: uri)
                    if let uploaded = try await uploadToImgbb(imageData: data) {
                        primaryImage = uploaded
                        Logger.d("[ModelSlab] Imgbb uploaded | url=\(uploaded)")
                    } else {
                        let base64 = data.base64EncodedString()
                        primaryImage = "data:image/jpeg;base64,\(base64)"
                        Logger.w("[ModelSlab] Imgbb upload failed → fallback base64, size=\(data.count) bytes")
                    }
                } catch {
                     Logger.e("[ModelSlab] Local image read/upload failed: \(error.localizedDescription)")
                     throw APIError.encodingError
                 }
            } else {
                primaryImage = uri.absoluteString
            }
        } else if let imageUrl = imageUrl, !imageUrl.isEmpty {
            if imageUrl.hasPrefix("file://"), let f = URL(string: imageUrl), f.isFileURL, let data = try? prepareUploadData(from: f) {
                if let uploaded = try await uploadToImgbb(imageData: data) {
                    primaryImage = uploaded
                    Logger.d("[ModelSlab] Imgbb uploaded from file:// | url=\(uploaded)")
                } else {
                    let base64 = data.base64EncodedString()
                    primaryImage = "data:image/jpeg;base64,\(base64)"
                    Logger.w("[ModelSlab] Imgbb upload failed → fallback base64 (file://)")
                }
            } else {
                primaryImage = imageUrl
            }
        } else {
            throw APIError.unknown("Missing imageUri or imageUrl for image-to-image request")
        }
    
        Logger.d("[ModelSlab] imageToImage input | init_image=\(primaryImage)")
        Logger.d("prompt = \(prompt)")
        let requestBody = ImageToImageV7Request(
            prompt: prompt,
            modelId: "nano-banana",
            initImage: primaryImage,
            initImage2: "",
            key: apiKey
        )

        let url = URL(string: "https://modelslab.com/api/v7/images/image-to-image")!
        Logger.d("[ModelSlab] POST v7 image-to-image…")
        let firstResponse = try await performV7Request(url: url, request: requestBody)
        Logger.d("[ModelSlab] v7 response | status=\(firstResponse.status) id=\(firstResponse.id ?? -1) fetch=\(firstResponse.fetchResult ?? "")")

        if firstResponse.isSuccess, let url = firstResponse.firstImageURL?.absoluteString, !url.isEmpty {
            Logger.d("[ModelSlab] v7 success | imageUrl=\(url)")
            return url
        }

        // If processing, poll fetch endpoint until success or timeout (5 minutes), every 5 seconds
        if firstResponse.isProcessing {
            Logger.d("[ModelSlab] status=processing → start polling fetch v6…")
            let requestId: String = {
                if let id = firstResponse.id {
                    return String(id)
                }
                if let fetch = firstResponse.fetchResult, !fetch.isEmpty {
                    return fetch
                }
                return ""
            }()

            guard !requestId.isEmpty else {
                throw APIError.unknown("Missing request_id for fetch polling")
            }

            let timeoutSeconds: TimeInterval = 300 // 5 minutes
            let intervalNanoseconds: UInt64 = 5_000_000_000 // 5 seconds
            let start = Date()
            var attempt: Int = 0

            while Date().timeIntervalSince(start) < timeoutSeconds {
                attempt += 1
                Logger.d("[ModelSlab] fetch attempt #\(attempt) | request_id=\(requestId)")
                let fetchResponse = try await performV6Fetch(requestId: requestId)
                Logger.d("[ModelSlab] fetch response | status=\(fetchResponse.status) message=\(fetchResponse.message)")
                if fetchResponse.status == "success" {
                    if let first = fetchResponse.firstImageURL, !first.isEmpty {
                        Logger.d("[ModelSlab] fetch success | imageUrl=\(first)")
                        return first
                    }
                    // Fallback: if success but no output, break to avoid infinite loop
                    break
                } else if fetchResponse.status == "error" {
                    let message = fetchResponse.message.isEmpty ? "Unknown fetch error" : fetchResponse.message
                    Logger.e("[ModelSlab] fetch error | message=\(message)")
                    throw APIError.aiServiceError(message)
                }

                try await Task.sleep(nanoseconds: intervalNanoseconds)
            }

            Logger.e("[ModelSlab] fetch timeout (\(Int(timeoutSeconds))s)")
            throw APIError.requestTimeout
        }

        // If failed or unexpected
        let err = APIError.fromModelSlabResponse(firstResponse)
        Logger.e("[ModelSlab] v7 failed | error=\(err)")
        throw err
    }

    // MARK: - v7 Text-to-Image
    func textToImageV7(
        prompt: String
    ) async throws -> String {
        Logger.d("[ModelSlab] textToImageV7 start | prompt=\(prompt.prefix(80))...")

        let requestBody = TextToImageV7Request(
            modelId: "imagen-3",
            prompt: prompt,
            key: apiKey
        )

        let url = URL(string: "https://modelslab.com/api/v7/images/text-to-image")!
        Logger.d("[ModelSlab] POST v7 text-to-image…")
        let firstResponse = try await performV7Request(url: url, request: requestBody)
        Logger.d("[ModelSlab] v7 response | status=\(firstResponse.status) id=\(firstResponse.id ?? -1) fetch=\(firstResponse.fetchResult ?? "")")

        if firstResponse.isSuccess, let url = firstResponse.firstImageURL?.absoluteString, !url.isEmpty {
            Logger.d("[ModelSlab] v7 success | imageUrl=\(url)")
            return url
        }

        if firstResponse.isProcessing {
            Logger.d("[ModelSlab] status=processing → start polling fetch v6…")
            let requestId: String = {
                if let id = firstResponse.id {
                    return String(id)
                }
                if let fetch = firstResponse.fetchResult, !fetch.isEmpty {
                    return fetch
                }
                return ""
            }()

            guard !requestId.isEmpty else {
                throw APIError.unknown("Missing request_id for fetch polling")
            }

            let timeoutSeconds: TimeInterval = 300 // 5 minutes
            let intervalNanoseconds: UInt64 = 5_000_000_000 // 5 seconds
            let start = Date()
            var attempt: Int = 0

            while Date().timeIntervalSince(start) < timeoutSeconds {
                attempt += 1
                Logger.d("[ModelSlab] fetch attempt #\(attempt) | request_id=\(requestId)")
                let fetchResponse = try await performV6Fetch(requestId: requestId)
                Logger.d("[ModelSlab] fetch response | status=\(fetchResponse.status) message=\(fetchResponse.message)")
                if fetchResponse.status == "success" {
                    if let first = fetchResponse.firstImageURL, !first.isEmpty {
                        Logger.d("[ModelSlab] fetch success | imageUrl=\(first)")
                        return first
                    }
                    break
                } else if fetchResponse.status == "error" {
                    let message = fetchResponse.message.isEmpty ? "Unknown fetch error" : fetchResponse.message
                    Logger.e("[ModelSlab] fetch error | message=\(message)")
                    throw APIError.aiServiceError(message)
                }

                try await Task.sleep(nanoseconds: intervalNanoseconds)
            }

            Logger.e("[ModelSlab] fetch timeout (\(Int(timeoutSeconds))s)")
            throw APIError.requestTimeout
        }

        let err = APIError.fromModelSlabResponse(firstResponse)
        Logger.e("[ModelSlab] v7 failed | error=\(err)")
        throw err
    }
    
    // MARK: - Private Methods
    private func performRequest(request: ModelSlabRequest) async throws -> ModelSlabResponse {
        let url = URL(string: "\(baseURL)/text2img")!
        
        return try await withCheckedThrowingContinuation { continuation in
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                urlRequest.httpBody = try JSONEncoder().encode(request)
            } catch {
                continuation.resume(throwing: APIError.encodingError)
                return
            }
            
            URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: APIError.networkError(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    continuation.resume(throwing: APIError.invalidResponse)
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    let apiError = APIError(httpStatusCode: httpResponse.statusCode)
                    continuation.resume(throwing: apiError)
                    return
                }
                
                guard let data = data else {
                    continuation.resume(throwing: APIError.missingData)
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(ModelSlabResponse.self, from: data)
                    continuation.resume(returning: response)
                } catch {
                    continuation.resume(throwing: APIError.decodingError)
                }
            }.resume()
        }
    }

    private func performV7Request<T: Encodable>(url: URL, request: T) async throws -> ModelSlabResponse {
        return try await withCheckedThrowingContinuation { continuation in
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

            do {
                urlRequest.httpBody = try JSONEncoder().encode(request)
            } catch {
                continuation.resume(throwing: APIError.encodingError)
                return
            }

            URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: APIError.networkError(error))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    continuation.resume(throwing: APIError.invalidResponse)
                    return
                }

                guard httpResponse.statusCode == 200 else {
                    let apiError = APIError(httpStatusCode: httpResponse.statusCode)
                    continuation.resume(throwing: apiError)
                    return
                }

                guard let data = data else {
                    continuation.resume(throwing: APIError.missingData)
                    return
                }

                do {
                    let response = try JSONDecoder().decode(ModelSlabResponse.self, from: data)
                    continuation.resume(returning: response)
                } catch {
                    continuation.resume(throwing: APIError.decodingError)
                }
            }.resume()
        }
    }

    // MARK: - Imgbb uploader
    private func uploadToImgbb(imageData: Data) async throws -> String? {
        // API: POST https://api.imgbb.com/1/upload?key=API_KEY [multipart/form-data] image=<base64 or binary>
        Logger.d("uploadToImgbb")
        guard let url = URL(string: "https://api.imgbb.com/1/upload?key=\(imgbbApiKey)") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Prepare multipart body
        var body = Data()
        func append(_ string: String) {
            if let data = string.data(using: .utf8) { body.append(data) }
        }

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"image\"; filename=\"upload.jpg\"\r\n")
        append("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        append("\r\n")
        append("--\(boundary)--\r\n")

        return try await withCheckedThrowingContinuation { continuation in
            URLSession.shared.uploadTask(with: request, from: body) { data, response, error in
                Logger.d("upload to imgbb -> response: \(String(describing: response))")
                Logger.d("data: \(String(data: data ?? Data(), encoding: .utf8) ?? "nil")")
                if let error = error {
                    continuation.resume(returning: nil)
                    Logger.e("[Imgbb] upload error: \(error.localizedDescription)")
                    return
                }
                guard let http = response as? HTTPURLResponse, http.statusCode == 200, let data = data else {
                    continuation.resume(returning: nil)
                    return
                }
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let dataObj = json["data"] as? [String: Any],
                       let urlStr = dataObj["url"] as? String {
                        continuation.resume(returning: urlStr)
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    continuation.resume(returning: nil)
                }
            }.resume()
        }
    }

    // Prepare upload data: re-encode JPEG with reasonable quality and optional downscale
    private func prepareUploadData(from fileURL: URL) throws -> Data {
        let maxDimension: CGFloat = 1600
        let targetQuality: CGFloat = 0.8
        let rawData = try Data(contentsOf: fileURL)
        if let image = UIImage(data: rawData) {
            let size = image.size
            let maxSide = max(size.width, size.height)
            let scale = max(1.0, maxSide / maxDimension)
            let targetSize = CGSize(width: size.width / scale, height: size.height / scale)

            UIGraphicsBeginImageContextWithOptions(targetSize, true, 1.0)
            image.draw(in: CGRect(origin: .zero, size: targetSize))
            let resized = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            if let resized, let jpeg = resized.jpegData(compressionQuality: targetQuality) {
                return jpeg
            }
        }
        // Fallback to original data if re-encode fails
        return rawData
    }

    // MARK: - v6 Fetch Polling
    private func performV6Fetch(requestId: String) async throws -> FetchResponse {
        Logger.d("performV6Fetch, requestId: \(requestId)")
        let url = URL(string: "https://modelslab.com/api/v6/images/fetch")!
        let fetchReq = FetchRequest(key: apiKey, requestId: requestId)

        return try await withCheckedThrowingContinuation { continuation in
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

            do {
                urlRequest.httpBody = try JSONEncoder().encode(fetchReq)
            } catch {
                continuation.resume(throwing: APIError.encodingError)
                return
            }

            URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: APIError.networkError(error))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    continuation.resume(throwing: APIError.invalidResponse)
                    return
                }

                guard httpResponse.statusCode == 200 else {
                    let apiError = APIError(httpStatusCode: httpResponse.statusCode)
                    continuation.resume(throwing: apiError)
                    return
                }

                guard let data = data else {
                    continuation.resume(throwing: APIError.missingData)
                    return
                }

                do {
                    let response = try JSONDecoder().decode(FetchResponse.self, from: data)
                    continuation.resume(returning: response)
                } catch {
                    continuation.resume(throwing: APIError.decodingError)
                }
            }.resume()
        }
    }
    
    private func validateImageSize(_ imageData: Data) throws {
        let maxSize = 10 * 1024 * 1024 // 10MB
        guard imageData.count <= maxSize else {
            throw APIError.imageTooLarge
        }
    }
    
    private func buildNegativePrompt() -> String {
        return "blurry, low quality, distorted, ugly, bad anatomy, bad proportions, " +
               "extra limbs, cloned face, malformed limbs, missing arms, missing legs, " +
               "extra arms, extra legs, fused fingers, too many fingers, long neck, " +
               "cross-eyed, mutated hands, polar lowres, bad body, bad face, bad teeth, " +
               "bad arms, bad legs, deformities, watermark, signature, text"
    }
}

// MARK: - ModelSlab Request Model
struct ModelSlabRequest: Codable {
    let key: String
    let modelId: String
    let prompt: String
    let negativePrompt: String
    let width: Int
    let height: Int
    let samples: Int
    let numInferenceSteps: Int
    let guidanceScale: Double
    let seed: Int?
    let initImage: String?
    let maskImage: String?
    let strength: Double?
    let scheduler: String
    let controlnetModel: String?
    let controlnetType: String?
    let webhook: String?
    let trackId: String
    
    enum CodingKeys: String, CodingKey {
        case key
        case modelId = "model_id"
        case prompt
        case negativePrompt = "negative_prompt"
        case width
        case height
        case samples
        case numInferenceSteps = "num_inference_steps"
        case guidanceScale = "guidance_scale"
        case seed
        case initImage = "init_image"
        case maskImage = "mask_image"
        case strength
        case scheduler
        case controlnetModel = "controlnet_model"
        case controlnetType = "controlnet_type"
        case webhook
        case trackId = "track_id"
    }
    
    init(
        key: String,
        modelId: String,
        prompt: String,
        negativePrompt: String,
        width: Int,
        height: Int,
        samples: Int,
        numInferenceSteps: Int,
        guidanceScale: Double,
        seed: Int? = nil,
        initImage: String? = nil,
        maskImage: String? = nil,
        strength: Double? = nil,
        scheduler: String,
        controlnetModel: String? = nil,
        controlnetType: String? = nil,
        webhook: String? = nil,
        trackId: String
    ) {
        self.key = key
        self.modelId = modelId
        self.prompt = prompt
        self.negativePrompt = negativePrompt
        self.width = width
        self.height = height
        self.samples = samples
        self.numInferenceSteps = numInferenceSteps
        self.guidanceScale = guidanceScale
        self.seed = seed
        self.initImage = initImage
        self.maskImage = maskImage
        self.strength = strength
        self.scheduler = scheduler
        self.controlnetModel = controlnetModel
        self.controlnetType = controlnetType
        self.webhook = webhook
        self.trackId = trackId
    }
}

// MARK: - ModelSlab Response Model
struct ModelSlabResponse: Codable {
    let status: String
    let generationTime: Double?
    let id: Int?
    let output: [String]?
    let message: String?
    let eta: Double?
    let fetchResult: String?
    
    enum CodingKeys: String, CodingKey {
        case status
        case generationTime = "generationTime"
        case id
        case output
        case message
        case eta
        case fetchResult = "fetch_result"
    }
    
    var isSuccess: Bool {
        return status == "success"
    }
    
    var isProcessing: Bool {
        return status == "processing"
    }
    
    var isFailed: Bool {
        return status == "failed" || status == "error"
    }
    
    var resultImageURLs: [URL] {
        return output?.compactMap { URL(string: $0) } ?? []
    }
    
    var firstImageURL: URL? {
        return resultImageURLs.first
    }
    
    var errorMessage: String? {
        return isFailed ? message : nil
    }
}

// MARK: - ModelSlab Error Extension
extension APIError {
    static func fromModelSlabResponse(_ response: ModelSlabResponse) -> APIError {
        if response.isFailed {
            return .aiServiceError(response.message ?? "Unknown AI service error")
        }
        return .unknown("Unexpected ModelSlab response")
    }
}

// MARK: - v7 Image-to-Image Request Model
private struct ImageToImageV7Request: Encodable {
    let prompt: String
    let modelId: String
    let initImage: String
    let initImage2: String
    let key: String

    enum CodingKeys: String, CodingKey {
        case prompt
        case modelId = "model_id"
        case initImage = "init_image"
        case initImage2 = "init_image_2"
        case key
    }
}

// MARK: - v6 Fetch Request/Response Models
private struct FetchRequest: Encodable {
    let key: String
    let requestId: String

    enum CodingKeys: String, CodingKey {
        case key
        case requestId = "request_id"
    }
}

// MARK: - v7 Text-to-Image Request Model
private struct TextToImageV7Request: Encodable {
    let modelId: String
    let prompt: String
    let key: String

    enum CodingKeys: String, CodingKey {
        case modelId = "model_id"
        case prompt
        case key
    }
}

private struct ExteriorV7Request: Encodable {
    let prompt: String
    let initImage: String

    // Tham số theo mẫu bạn đưa
    let strength: String = "0.4"
    let negativePrompt: String =
        "blurry, low resolution, bad lighting, poorly drawn furniture, distorted proportions, messy room, unrealistic colors, extra limbs, missing furniture, bad anatomy, low detail, pixelated, grainy, artifacts, oversaturated, asymmetry, ugly, cartoonish, out of frame, duplicate objects"
    let guidanceScale: String = "7.5"
    let base64: String = "false"
    let seed: String = "0"
    let numInferenceSteps: String = "41"
    let specificObject: String = "null"
    let webhook: String = "null"
    let trackId: String = "null"
    let key: String

    enum CodingKeys: String, CodingKey {
        case prompt
        case initImage = "init_image"
        case strength
        case negativePrompt = "negative_prompt"
        case guidanceScale = "guidance_scale"
        case base64
        case seed
        case numInferenceSteps = "num_inference_steps"
        case specificObject = "specific_object"
        case webhook
        case trackId = "track_id"
        case key
    }
}


private struct InteriorV7Request: Encodable {
    let prompt: String
    let initImage: String

    // Các trường tham số theo mẫu của ModelsLab (đặt default giống JSON bạn cung cấp)
    let strength: String = "0.7"
    let negativePrompt: String =
        "blurry, low resolution, bad lighting, poorly drawn furniture, distorted proportions, messy room, unrealistic colors, extra limbs, missing furniture, bad anatomy, low detail, pixelated, grainy, artifacts, oversaturated, asymmetry, ugly, cartoonish, out of frame, duplicate objects"
    let guidanceScale: String = "7.5"
    let base64: String = "false"
    let seed: String = "0"
    let numInferenceSteps: String = "51"
    let webhook: String = "null"
    let trackId: String = "null"
    let scaleDown: String = "6"
    let key: String

    enum CodingKeys: String, CodingKey {
        case prompt
        case initImage = "init_image"
        case strength
        case negativePrompt = "negative_prompt"
        case guidanceScale = "guidance_scale"
        case base64
        case seed
        case numInferenceSteps = "num_inference_steps"
        case webhook
        case trackId = "track_id"
        case scaleDown = "scale_down"
        case key
    }
}

struct FetchResponse: Decodable {
    let status: String
    let message: String
    let tip: String
    let key: String
    let outputURLs: [String]
    let proxyLinks: [String]

    enum CodingKeys: String, CodingKey {
        case status
        case message
        case messege
        case output
        case proxyLinks = "proxy_links"
        case tip
        case key
        case requestId = "request_id"
        case id
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.status = (try? container.decode(String.self, forKey: .status)) ?? ""

        // message / messege có thể là 1 trong 2
        self.message =
            (try? container.decode(String.self, forKey: .message)) ??
            (try? container.decode(String.self, forKey: .messege)) ??
            ""

        self.tip = (try? container.decode(String.self, forKey: .tip)) ?? ""
        self.key = (try? container.decode(String.self, forKey: .key)) ?? ""

        // ✅ decode output linh hoạt: có thể là String hoặc [String]
        if let outputArray = try? container.decode([String].self, forKey: .output) {
            self.outputURLs = outputArray
        } else if let singleOutput = try? container.decode(String.self, forKey: .output),
                  !singleOutput.isEmpty {
            self.outputURLs = [singleOutput]
        } else {
            self.outputURLs = []
        }

        // ✅ proxy_links có thể có hoặc không
        self.proxyLinks = (try? container.decode([String].self, forKey: .proxyLinks)) ?? []
    }

    /// ✅ URL đầu tiên trong danh sách output (ưu tiên proxy nếu có)
    var firstImageURL: String? {
        return proxyLinks.first ?? outputURLs.first
    }
}


//struct FetchResponse: Decodable {
//    let status: String
//    let message: String
//    let output: String
//    let tip: String
//    let key: String
//    let requestId: String
//
//    enum CodingKeys: String, CodingKey {
//        case status
//        case message = "messege" // API sometimes returns 'messege'
//        case output
//        case tip
//        case key
//        case requestId = "request_id"
//    }
//
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.status = (try? container.decode(String.self, forKey: .status)) ?? ""
//        self.message = (try? container.decode(String.self, forKey: .message)) ?? ""
//        self.output = (try? container.decode(String.self, forKey: .output)) ?? ""
//        self.tip = (try? container.decode(String.self, forKey: .tip)) ?? ""
//        self.key = (try? container.decode(String.self, forKey: .key)) ?? ""
//        self.requestId = (try? container.decode(String.self, forKey: .requestId)) ?? ""
//    }
//
//    var firstImageURL: String? {
//        if output.isEmpty { return nil }
//        // output can be either single URL string or array serialized; backend here shows string
//        return output
//    }
//}
