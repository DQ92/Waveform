//
// Created by Michał Kos on 16/01/2018.
// Copyright (c) 2018 Dominium. All rights reserved.
//

import Foundation

class Log {

    static var shouldPrint = true
    
    enum LogType: String {
        case debug = "🔹DEBUG: "
        case info = "✅INFO: "
        case warning = "⚠️WARNING: "
        case error = "🆘ERROR: "

        var shouldAppendNewLine: Bool {
            switch self {
            case .error: return true
            default: return false
            }
        }
    }

    class func debug(_ msg: Any?,
                     _ file: String = #file,
                     _ function: String = #function,
                     _ line: Int = #line) {
        log(message: msg, withType: LogType.debug, fileName: file, functionName: function, line: line)
    }

    class func info(_ msg: Any?,
                    _ file: String = #file,
                    _ function: String = #function,
                    _ line: Int = #line) {
        log(message: msg, withType: LogType.info,  fileName: file, functionName: function, line: line)
    }

    class func warning(_ msg: Any?,
                       _ file: String = #file,
                       _ function: String = #function,
                       _ line: Int = #line) {
        log(message: msg, withType: LogType.warning, fileName: file, functionName: function, line: line)
    }

    class func error(_ msg: Any?,
                     _ file: String = #file,
                     _ function: String = #function,
                     _ line: Int = #line) {
        log(message: msg, withType: LogType.error, fileName: file, functionName: function, line: line)
    }

    private static func log(message: Any?,
                            withType type: LogType,
                            fileName: String,
                            functionName: String,
                            line: Int) {
        let filename = fileName.asNSString.lastPathComponent.asNSString.deletingPathExtension
        let fileExtension = fileName.asNSString.lastPathComponent.asNSString.pathExtension
        var messageToShow = String(describing: message)
        if let unwrappedMessage = message {
            messageToShow = String(describing: unwrappedMessage)
        }
        var information = "\(type.rawValue) \(filename).\(fileExtension): \(line) \(functionName): \(messageToShow)"

        if type.shouldAppendNewLine {
            information.append("\n")
        }

        if shouldPrint {
            print(information)
        }
    }
}
