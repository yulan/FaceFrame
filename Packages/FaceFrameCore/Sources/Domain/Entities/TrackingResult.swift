//
//  TrackingResult.swift
//  Domain
//
//  Created by Lan YU on 21/11/2026.
//

import Foundation

/// Result for one frame. Only `Sendable` values.
public struct TrackingResult: Equatable, Sendable {
    /// `nil` when no face was found.
    public var face: FaceLandmarks?
    /// Image size as displayed, in pixels. Used to map points onto the view.
    public var imageSize: Size2D
    public var timestamp: Duration
    /// Time spent on the detection.
    public var processingTime: Duration

    public init(face: FaceLandmarks?, imageSize: Size2D, timestamp: Duration, processingTime: Duration) {
        self.face = face
        self.imageSize = imageSize
        self.timestamp = timestamp
        self.processingTime = processingTime
    }

    public var eyes: EyePositions? { face?.eyes }
}
