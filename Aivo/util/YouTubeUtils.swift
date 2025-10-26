import Foundation

// MARK: - YouTube Metadata Models
struct OEmbed: Decodable {
    let title: String
    let author_name: String
    let thumbnail_url: String?
}

enum YTMetaError: Error { 
    case badURL, notFound, invalidResponse
}

// MARK: - YouTube URL Utilities
class YouTubeUtils {
    
    /// Normalize YouTube URL to basic format (remove extra parameters)
    static func normalizeYouTubeURL(_ url: String) -> String? {
        Logger.d("🔗 [YouTubeUtils] Normalizing URL: \(url)")
        
        // Extract video ID from various YouTube URL formats
        let patterns = [
            #"youtube\.com/watch\?v=([a-zA-Z0-9_-]+)"#,
            #"youtu\.be/([a-zA-Z0-9_-]+)"#,
            #"youtube\.com/embed/([a-zA-Z0-9_-]+)"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)),
               let range = Range(match.range(at: 1), in: url) {
                let videoId = String(url[range])
                let normalizedURL = "https://www.youtube.com/watch?v=\(videoId)"
                Logger.d("🔗 [YouTubeUtils] Normalized URL: \(normalizedURL)")
                return normalizedURL
            }
        }
        
        Logger.e("❌ [YouTubeUtils] Could not extract video ID from URL: \(url)")
        return nil
    }
    
    /// Fetch basic metadata from YouTube oEmbed API
    static func fetchYouTubeBasicMeta(url: String) async throws -> (title: String, channel: String, thumb: String?) {
        Logger.i("📡 [YouTubeUtils] Fetching metadata for: \(url)")
        
        guard var comp = URLComponents(string: "https://www.youtube.com/oembed") else { 
            Logger.e("❌ [YouTubeUtils] Invalid oEmbed URL")
            throw YTMetaError.badURL 
        }
        
        comp.queryItems = [
            .init(name: "url", value: url),
            .init(name: "format", value: "json")
        ]
        
        guard let requestURL = comp.url else {
            Logger.e("❌ [YouTubeUtils] Could not build request URL")
            throw YTMetaError.badURL
        }
        
        Logger.d("📡 [YouTubeUtils] Request URL: \(requestURL.absoluteString)")
        
        let (data, resp) = try await URLSession.shared.data(from: requestURL)
        
        guard let httpResponse = resp as? HTTPURLResponse else {
            Logger.e("❌ [YouTubeUtils] Invalid HTTP response")
            throw YTMetaError.invalidResponse
        }
        
        Logger.d("📡 [YouTubeUtils] HTTP Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else { 
            Logger.e("❌ [YouTubeUtils] HTTP Error: \(httpResponse.statusCode)")
            throw YTMetaError.notFound 
        }
        
        do {
            let meta = try JSONDecoder().decode(OEmbed.self, from: data)
            Logger.i("✅ [YouTubeUtils] Metadata fetched successfully")
            Logger.d("📋 [YouTubeUtils] Title: \(meta.title)")
            Logger.d("📋 [YouTubeUtils] Channel: \(meta.author_name)")
            Logger.d("📋 [YouTubeUtils] Thumbnail: \(meta.thumbnail_url ?? "None")")
            
            return (meta.title, meta.author_name, meta.thumbnail_url)
        } catch {
            Logger.e("❌ [YouTubeUtils] Error decoding metadata: \(error)")
            throw YTMetaError.invalidResponse
        }
    }
    
    /// Heuristic to split Artist – Title from YouTube title
    static func splitArtistTitle(from ytTitle: String) -> (artist: String?, song: String?) {
        Logger.d("🎵 [YouTubeUtils] Splitting artist-title from: \(ytTitle)")
        
        // Remove common suffixes
        var t = ytTitle.replacingOccurrences(of: #"\(.*?(MV|Official|Lyric(s)?|Audio|Video).*?\)"#,
                                             with: "", options: .regularExpression)
        t = t.replacingOccurrences(of: #"\[.*?(MV|Official|Lyric(s)?|Audio|Video).*?\]"#,
                                   with: "", options: .regularExpression)
             .replacingOccurrences(of: "【.*?】", with: "", options: .regularExpression)
             .trimmingCharacters(in: .whitespacesAndNewlines)
        
        Logger.d("🎵 [YouTubeUtils] Cleaned title: \(t)")
        
        // Try common separators
        let seps = [" - ", " – ", " — ", " | ", ":"]
        for s in seps {
            let parts = t.components(separatedBy: s)
            if parts.count >= 2 {
                let left = parts.first!.trimmingCharacters(in: .whitespaces)
                let right = parts.dropFirst().joined(separator: s).trimmingCharacters(in: .whitespaces)
                
                // If right side has quotes, extract content inside
                let song = right.replacingOccurrences(of: #"^[""](.+?)[""]$"#,
                                                      with: "$1", options: .regularExpression)
                
                Logger.d("🎵 [YouTubeUtils] Split result - Artist: \(left), Song: \(song)")
                return (left.isEmpty ? nil : left, song.isEmpty ? nil : song)
            }
        }
        
        Logger.d("🎵 [YouTubeUtils] Could not split, using full title as song")
        return (nil, t.isEmpty ? nil : t)
    }
    
    /// Complete workflow: normalize URL, fetch metadata, extract song info
    static func processYouTubeURL(_ url: String) async -> (normalizedURL: String?, songName: String?, artistName: String?) {
        Logger.i("🎬 [YouTubeUtils] Processing YouTube URL: \(url)")
        
        // Step 1: Normalize URL
        guard let normalizedURL = normalizeYouTubeURL(url) else {
            Logger.e("❌ [YouTubeUtils] Failed to normalize URL")
            return (nil, nil, nil)
        }
        
        // Step 2: Fetch metadata
        do {
            let (title, channel, _) = try await fetchYouTubeBasicMeta(url: normalizedURL)
            
            // Step 3: Split artist and song
            let (artist, song) = splitArtistTitle(from: title)
            
            let finalSongName = song ?? title
            let finalArtistName = artist ?? channel
            
            Logger.i("✅ [YouTubeUtils] Processing complete")
            Logger.d("🎵 [YouTubeUtils] Final song name: \(finalSongName)")
            Logger.d("🎤 [YouTubeUtils] Final artist name: \(finalArtistName)")
            
            return (normalizedURL, finalSongName, finalArtistName)
            
        } catch {
            Logger.e("❌ [YouTubeUtils] Error processing URL: \(error)")
            return (normalizedURL, nil, nil)
        }
    }
}
