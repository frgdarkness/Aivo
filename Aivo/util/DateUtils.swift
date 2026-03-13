import Foundation

struct DateUtils {
    /// Generates a week tag for community sharing (e.g., "2026-w11")
    /// Uses ISO-8601 week numbering.
    static func getCurrentWeekTag() -> String {
        let date = Date()
        let calendar = Calendar(identifier: .iso8601)
        
        let year = calendar.component(.yearForWeekOfYear, from: date)
        let week = calendar.component(.weekOfYear, from: date)
        
        return String(format: "%d-w%02d", year, week)
    }
    
    /// Formats a timestamp into a readable date string
    static func formatTimestamp(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
