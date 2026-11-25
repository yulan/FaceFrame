//
//  FaceTrackingSession.swift
//  Domain
//
//  Created by Lan YU on 21/11/2026.
//

import Foundation

/// A stream of tracking results, for the Presentation layer.
/// Iterating starts the source. Ending the loop or cancelling the task stops it.
/// Fails with a `TrackingError`.
public protocol FaceTrackingSession: Sendable {
    func results() -> AsyncThrowingStream<TrackingResult, any Error>
}
