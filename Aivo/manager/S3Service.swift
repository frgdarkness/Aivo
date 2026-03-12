import Foundation
import CryptoKit

/// Service to handle file uploads to S3-compatible storage using AWS SigV4
final class S3Service {
    static let shared = S3Service()
    
    // S3 Configuration from User
    private let accessKey = "ayHUSLTcAcxhroQbkcJ5"
    private let secretKey = "watnAsEaGjUGH6eTRcMsX01Q1AH6Ss6dM1PZ9JkD"
    private let bucketName = "aivomusic"
    private let endpoint = "https://s3.appdexter.com"
    private let region = "us-east-1" // Standard fallback for S3-compatible services
    private let publicDomain = "https://s3.appdexter.com"
    
    private init() {}
    
    /// Uploads image data to S3 and returns the public URL
    func uploadAvatar(data: Data, profileID: String) async throws -> String {
        let fileName = "avatars/\(profileID)_\(Int(Date().timeIntervalSince1970)).jpg"
        let url = URL(string: "\(endpoint)/\(bucketName)/\(fileName)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = data
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        
        // Sign the request with SigV4
        let host = url.host ?? ""
        let timestamp = ISO8601DateFormatter.s3Timestamp()
        let datestamp = ISO8601DateFormatter.s3Datestamp()
        
        request.setValue(host, forHTTPHeaderField: "Host")
        request.setValue(timestamp, forHTTPHeaderField: "x-amz-date")
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        
        let payloadHash = SHA256.hash(data: data).hexString
        request.setValue(payloadHash, forHTTPHeaderField: "x-amz-content-sha256")
        
        let headers = [
            "content-type": "image/jpeg",
            "host": host,
            "x-amz-content-sha256": payloadHash,
            "x-amz-date": timestamp
        ]
        
        let signedHeaders = headers.keys.sorted().joined(separator: ";")
        let canonicalHeaders = headers.keys.sorted().map { "\($0):\($0 == "host" ? host : headers[$0]!)" }.joined(separator: "\n") + "\n"
        
        let canonicalRequest = [
            "PUT",
            "/\(bucketName)/\(fileName)",
            "", // query string
            canonicalHeaders,
            signedHeaders,
            payloadHash
        ].joined(separator: "\n")
        
        let canonicalRequestHash = SHA256.hash(data: Data(canonicalRequest.utf8)).hexString
        let credentialScope = "\(datestamp)/\(region)/s3/aws4_request"
        let stringToSign = [
            "AWS4-HMAC-SHA256",
            timestamp,
            credentialScope,
            canonicalRequestHash
        ].joined(separator: "\n")
        
        let signature = calculateSignature(stringToSign: stringToSign, datestamp: datestamp)
        let authorization = "AWS4-HMAC-SHA256 Credential=\(accessKey)/\(credentialScope), SignedHeaders=\(signedHeaders), Signature=\(signature)"
        
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "S3Service", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            let errorMsg = String(data: responseData, encoding: .utf8) ?? "Unknown S3 error"
            Logger.e("❌ S3 Upload Failed (\(httpResponse.statusCode)): \(errorMsg)")
            throw NSError(domain: "S3Service", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
        
        Logger.d("✅ S3 Upload Success: \(fileName)")
        return "\(publicDomain)/\(bucketName)/\(fileName)"
    }
    
    private func calculateSignature(stringToSign: String, datestamp: String) -> String {
        let kDate = hmac(key: Data("AWS4\(secretKey)".utf8), data: Data(datestamp.utf8))
        let kRegion = hmac(key: kDate, data: Data(region.utf8))
        let kService = hmac(key: kRegion, data: Data("s3".utf8))
        let kSigning = hmac(key: kService, data: Data("aws4_request".utf8))
        return hmac(key: kSigning, data: Data(stringToSign.utf8)).hexString
    }
    
    private func hmac(key: Data, data: Data) -> Data {
        let hmacKey = SymmetricKey(data: key)
        let signature = HMAC<SHA256>.authenticationCode(for: data, using: hmacKey)
        return Data(signature)
    }
}

extension SHA256Digest {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}

extension Data {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}

extension ISO8601DateFormatter {
    static func s3Timestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withYear, .withMonth, .withDay, .withTime, .withTimeZone]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: Date()).replacingOccurrences(of: "-", with: "").replacingOccurrences(of: ":", with: "")
    }
    
    static func s3Datestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withYear, .withMonth, .withDay]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: Date()).replacingOccurrences(of: "-", with: "")
    }
}
