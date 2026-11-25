//
//  PreviewedFrameSource.swift
//  DataLayer
//
//  Created by Lan YU on 22/11/2026.
//

/// Wraps a frame source and sends each frame to a `FramePreviewFeed`.
public struct PreviewedFrameSource: FrameSource {
    private let base: any FrameSource
    private let feed: FramePreviewFeed

    public init(_ base: any FrameSource, feed: FramePreviewFeed) {
        self.base = base
        self.feed = feed
    }

    public func run(onFrame: @escaping @Sendable (VideoFrame) -> Void) async throws {
        let feed = feed
        try await base.run { frame in
            // Detect first, then show. The picture and its result reach the UI together.
            onFrame(frame)
            feed.publish(frame)
        }
    }

    public func stop() {
        base.stop()
    }
}
