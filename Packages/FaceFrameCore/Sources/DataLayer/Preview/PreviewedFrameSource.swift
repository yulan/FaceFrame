//
//  PreviewedFrameSource.swift
//  DataLayer
//
//  Created by Lan YU on 22/11/2026.
//

/// Wraps a frame source and shows every frame it delivers on a `FramePreviewFeed`.
///
/// A decorator, so neither the wrapped source nor the pipeline knows that a
/// preview exists.
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
            // The frame is processed first and shown second: the picture and
            // its tracking result then reach the UI together. Shown first, the
            // picture would be one detection ahead of the glasses.
            onFrame(frame)
            feed.publish(frame)
        }
    }

    public func stop() {
        base.stop()
    }
}
