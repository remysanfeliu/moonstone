//
//  Logger.swift
//  MoonStone
//
//  Created by SANFELIU Remy on 04/08/2019.
//  Copyright © 2019 Rémy Sanfeliu. All rights reserved.
//

import Foundation
import os.log

/// Abstract Logger interface
protocol ILogger {
    func d(_ message: String)
    func i(_ message: String)
    func w(_ message: String)
    func e(_ message: String)
}

/// Default Logger implementation, using os.log
class Log {
    
    /// Shared instance for ease of use
    static let it = Log()
    
    /// OSLog instance attached to a default case for MoonStone
    private let moonstoneLog = OSLog(subsystem: "com.remysanfeliu.MoonStone", category: "Default")
    
    func d(_ message: String) {
        os_log("%@", log: moonstoneLog, type: .debug, message)
    }
    
    func i(_ message: String) {
        os_log("%@", log: moonstoneLog, type: .info, message)
    }
    
    func w(_ message: String) {
        os_log("%@", log: moonstoneLog, type: .error, message)
    }
    
    func e(_ message: String) {
        os_log("%@", log: moonstoneLog, type: .fault, message)
    }
}
