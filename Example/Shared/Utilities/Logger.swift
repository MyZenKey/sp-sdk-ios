//
//  Logger.swift
//  BankApp
//
//  Created by Adam Tierney on 9/11/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

/// A logging structure. Pass a log level to the ZenKey launch options to enable logging
/// for use during debugging.
public struct Logger {
    static private(set) var logLevel: Level = .verbose //.off

    public enum Level: Int {
        case off, error, warn, info, verbose

        var name: String {
            switch self {
            case .off:
                return ""
            case .warn:
                return "warn"
            case .error:
                return "error"
            case .info:
                return "info"
            case .verbose:
                return "verbose"
            }
        }
    }

    static func configureLogger(level: Level) {
        logLevel = level
    }

    static func log<T>(_ level: Level, _ object: @autoclosure () -> T, _ file: String = #file) {
        #if DEBUG
        guard level.rawValue <= logLevel.rawValue, level != .off else { return }
        let type = file.components(separatedBy: "/").last ?? "Unknown Type"
        print("|\(level.name.uppercased())| \(dateformatter.string(from: Date())) : \(type) :: \(object())")
        #endif
    }
}

extension Logger {
    static func logRequest(_ logLevel: Level, urlRequest: URLRequest) {
        guard let curlString = urlRequest.curlString else {
            Logger.log(.error, "attempting to log curl for \(urlRequest) but it is an invalid request")
            return
        }
        Logger.log(logLevel, "Requesting: \n\(curlString)")
    }

    static func logJSON(_ logLevel: Level, data: Data?) {
        guard let data = data else {
            Logger.log(logLevel, "no data to log json for")
            return
        }

        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            Logger.log(logLevel, "\(json)")
        } catch {
            Logger.log(logLevel, "invalid json")
        }
    }
}

private extension Logger {
    static let dateformatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "Y-MM-dd H:m:ss.SSSS"
        return formatter
    }()
}
