//
//  FrameSource.swift
//  DataLayer
//
//  Created by Lan YU on 21/11/2026.
//

import Foundation

/// Gives video frames: the camera or a video file.
public protocol FrameSource: Sendable {
    /// Calls `onFrame` for each frame, one at a time, on the source's own queue.
    /// Returns when there are no more frames, or after `stop()`.
    func run(onFrame: @escaping @Sendable (VideoFrame) -> Void) async throws

    /// Can be called from any thread.
    func stop()
}
