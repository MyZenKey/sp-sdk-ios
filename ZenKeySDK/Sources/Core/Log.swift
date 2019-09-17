//
//  Log.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 7/24/19.
//  Copyright © 2019 XCI JV, LLC.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

/// A logging structure. Pass a log level to the ZenKey launch options to enable logging
/// for use during debugging.
public struct Log {
    static private(set) var logLevel: Level = .off

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

private extension Log {
    static let dateformatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "Y-MM-dd H:m:ss.SSSS"
        return formatter
    }()
}
