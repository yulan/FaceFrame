//
//  Log.swift
//  FaceFrame
//
//  Created by Lan YU on 21/11/2026.
//

import OSLog

/// Same subsystem as the DataLayer, so one Console filter shows the whole session.
enum Log {
    private static let subsystem = "YULan.FaceFrame"

    /// Errors actually shown to the user.
    static let ui = Logger(subsystem: subsystem, category: "ui")
}
