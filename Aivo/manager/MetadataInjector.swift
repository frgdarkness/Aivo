import AVFoundation
import UIKit

class MetadataInjector {
    
    enum MetadataError: Error {
        case exportSessionInitFailed
        case exportFailed(Error?)
        case unknown
    }
    
    static func injectMetadata(
        sourceURL: URL,
        outputURL: URL,
        title: String,
        artist: String,
        artwork: UIImage?,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let asset = AVAsset(url: sourceURL)
        
        // Use m4a (AAC) for guaranteed metadata support on iOS
        // Passhthrough might work for some containers but re-encoding to M4A is safest for metadata
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            completion(.failure(MetadataError.exportSessionInitFailed))
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        
        var metadataItems: [AVMutableMetadataItem] = []
        
        // Title
        let titleItem = AVMutableMetadataItem()
        titleItem.identifier = .commonIdentifierTitle
        titleItem.value = title as NSString
        titleItem.extendedLanguageTag = "und"
        metadataItems.append(titleItem)
        
        // Artist
        let artistItem = AVMutableMetadataItem()
        artistItem.identifier = .commonIdentifierArtist
        artistItem.value = artist as NSString
        artistItem.extendedLanguageTag = "und"
        metadataItems.append(artistItem)
        
        // Artwork
        if let artwork = artwork, let imageData = artwork.pngData() {
            let artworkItem = AVMutableMetadataItem()
            artworkItem.identifier = .commonIdentifierArtwork
            artworkItem.value = imageData as NSData
            artworkItem.dataType = kCMMetadataBaseDataType_PNG as String
            artworkItem.extendedLanguageTag = "und"
            metadataItems.append(artworkItem)
        } else if let artwork = artwork, let imageData = artwork.jpegData(compressionQuality: 1.0) {
            let artworkItem = AVMutableMetadataItem()
            artworkItem.identifier = .commonIdentifierArtwork
            artworkItem.value = imageData as NSData
            artworkItem.dataType = kCMMetadataBaseDataType_JPEG as String
            artworkItem.extendedLanguageTag = "und"
            metadataItems.append(artworkItem)
        }
        
        exportSession.metadata = metadataItems
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                completion(.success(outputURL))
            case .failed:
                completion(.failure(MetadataError.exportFailed(exportSession.error)))
            case .cancelled:
                completion(.failure(MetadataError.exportFailed(NSError(domain: "MetadataInjector", code: -1, userInfo: [NSLocalizedDescriptionKey: "Export cancelled"]))))
            default:
                completion(.failure(MetadataError.unknown))
            }
        }
    }
}
