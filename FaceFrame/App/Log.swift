//
//  Log.swift
//  FaceFrame
//
//  Created by Lan YU on 21/11/2026.
//

import OSLog

/// Same subsystem as DataLayer: one Console filter shows everything.
enum Log {
    private static let subsystem = "YULan.FaceFrame"

    /// Errors shown to the user.
    static let ui = Logger(subsystem: subsystem, category: "ui")
}
