//
//  Log.swift
//  DataLayer
//
//  Created by Lan YU on 21/11/2026.
//

import OSLog

enum Log {
    private static let subsystem = "YULan.FaceFrame"

    static let tracking = Logger(subsystem: subsystem, category: "tracking")
    static let frames = Logger(subsystem: subsystem, category: "frames")

    /// Shows up under "Points of Interest" in Instruments: one interval per
    /// processed frame. Phase 2 starts by reading these.
    static let signposter = OSSignposter(subsystem: subsystem, category: .pointsOfInterest)
}
