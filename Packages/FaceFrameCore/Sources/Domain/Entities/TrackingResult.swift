//
//  TrackingResult.swift
//  Domain
//
//  Created by Lan YU on 21/11/2026.
//

import Foundation

/// The outcome of processing one video frame. Only `Sendable` values: the
/// pixel buffer never leaves the frame source's queue.
public struct TrackingResult: Equatable, Sendable {
    /// `nil` when no face was found in this frame.
    public var eyes: EyePositions?
    /// Size of the image as displayed (portrait for the front camera in
    /// portrait), in pixels. Needed to map normalized points onto the view.
    public var imageSize: Size2D
    /// Presentation time of the frame.
    public var timestamp: Duration
    /// Time spent detecting the face in this frame.
    public var processingTime: Duration

    public init(eyes: EyePositions?, imageSize: Size2D, timestamp: Duration, processingTime: Duration) {
        self.eyes = eyes
        self.imageSize = imageSize
        self.timestamp = timestamp
        self.processingTime = processingTime
    }
}
