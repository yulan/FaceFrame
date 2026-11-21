//
//  FaceTrackingSession.swift
//  Domain
//
//  Created by Lan YU on 21/11/2026.
//

import Foundation

/// What the Presentation layer depends on: a stream of tracking results.
///
/// Iterating `results()` starts the source (camera, video file, simulation).
/// Ending the iteration, or cancelling the task that iterates, stops it.
/// The stream fails with a `TrackingError`.
public protocol FaceTrackingSession: Sendable {
    func results() -> AsyncThrowingStream<TrackingResult, any Error>
}
