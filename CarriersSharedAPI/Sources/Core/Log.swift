//
//  Log.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 7/24/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

struct Log {

    static private(set) var logLevel: Level = .verbose//.off

    enum Level: Int {
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

    static func log<T>(_ level: Level, _ object: @autoclosure () -> T, _ file: String = #file) {
        guard level.rawValue <= logLevel.rawValue, level != .off else { return }
        let type = file.components(separatedBy: "/").last ?? "Unknown Type"
        print("|\(level.name.uppercased())| \(dateformatter.string(from: Date())) : \(type) :: \(object())")
    }
}

private extension Log {
    static let dateformatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "Y-MM-dd H:m:ss.SSSS"
        return formatter
    }()
}
