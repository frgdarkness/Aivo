//
//  Logger.swift
//  YourAppName
//
//  Created by ChatGPT on 2025-10-07.
//

import Foundation

enum LogLevel: String {
    case debug = "🐞 DEBUG"
    case info  = "ℹ️ INFO"
    case warn  = "⚠️ WARN"
    case error = "❌ ERROR"
    
    var color: String {
        switch self {
        case .debug: return "\u{001B}[0;36m" // cyan
        case .info:  return "\u{001B}[0;32m" // green
        case .warn:  return "\u{001B}[0;33m" // yellow
        case .error: return "\u{001B}[0;31m" // red
        }
    }
}

struct Logger {
    
    /// Print full log info with class, func, line, and color
    private static func printLog(
        _ level: LogLevel,
        _ message: Any,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
#if DEBUG
        let fileName = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
        let shortFile = truncate(fileName, to: 20)
        let shortFunc = truncate(function, to: 30)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        let timestamp = dateFormatter.string(from: Date())
        //›let thread = Thread.isMainThread ? "Main" : "Background"
        
        //let formatted = "\(level.color)\(level.rawValue)\u{001B}[0m [\(timestamp)] [\(thread)] \(fileName).\(function)[\(line)] → \(message)"
        let formatted = "\(level.rawValue)\u{001B} [\(timestamp)] ###\(shortFile).\(shortFunc)[\(line)] → \(message)"
        print(formatted)
#endif
    }
    
    private static func truncate(_ text: String, to length: Int) -> String {
        if text.count > length {
            let index = text.index(text.startIndex, offsetBy: length - 3)
            return "\(text[..<index])..."
        }
        return text
    }
    
    /// Debug log (blue / cyan)
    static func d(_ message: Any,
                  file: String = #fileID,
                  function: String = #function,
                  line: Int = #line) {
        printLog(.debug, message, file: file, function: function, line: line)
    }
    
    /// Info log (green)
    static func i(_ message: Any,
                  file: String = #fileID,
                  function: String = #function,
                  line: Int = #line) {
        printLog(.info, message, file: file, function: function, line: line)
    }
    
    /// Warning log (yellow)
    static func w(_ message: Any,
                  file: String = #fileID,
                  function: String = #function,
                  line: Int = #line) {
        printLog(.warn, message, file: file, function: function, line: line)
    }
    
    /// Error log (red)
    static func e(_ message: Any,
                  file: String = #fileID,
                  function: String = #function,
                  line: Int = #line) {
        printLog(.error, message, file: file, function: function, line: line)
    }
}
