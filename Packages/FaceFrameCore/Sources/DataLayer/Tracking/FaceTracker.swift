//
//  FaceTracker.swift
//  DataLayer
//
//  Created by Lan YU on 21/11/2026.
//

import Domain

/// Finds the pupils in one frame.
public protocol FaceTracker: Sendable {
    /// Called on the frame source's queue, one frame at a time.
    /// - Returns: `nil` when there is no face in the frame.
    func eyes(in frame: VideoFrame) throws -> EyePositions?
}
