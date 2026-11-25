//
//  FaceTracker.swift
//  DataLayer
//
//  Created by Lan YU on 21/11/2026.
//

import Domain

/// Finds the face in one frame.
public protocol FaceTracker: Sendable {
    /// Called on the frame source's queue. `nil` when there is no face.
    func face(in frame: VideoFrame) throws -> FaceLandmarks?
}
