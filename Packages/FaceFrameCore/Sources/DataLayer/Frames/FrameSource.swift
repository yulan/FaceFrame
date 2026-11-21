//
//  FrameSource.swift
//  DataLayer
//
//  Created by Lan YU on 21/11/2026.
//

import Foundation

/// Something that produces video frames: the camera, or a video file.
public protocol FrameSource: Sendable {
    /// Delivers frames one at a time, on a serial queue owned by the source,
    /// until the source runs out of frames or `stop()` is called. Returns once
    /// delivery has ended.
    ///
    /// `onFrame` is never called concurrently with itself, so it can do
    /// synchronous work on the frame. Throws a `TrackingError`.
    func run(onFrame: @escaping @Sendable (VideoFrame) -> Void) async throws

    /// Ends delivery. Safe to call from any thread, and more than once.
    func stop()
}
