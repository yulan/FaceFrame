//
//  TrackingPipeline.swift
//  DataLayer
//
//  Created by Lan YU on 21/11/2026.
//

import Domain
import Foundation

/// Runs the tracker on each frame of a source and publishes one result per frame.
/// The detection runs on the source's queue. Only the `Sendable` result leaves it.
public final class TrackingPipeline: FaceTrackingSession {
    public typealias BufferingPolicy = AsyncThrowingStream<TrackingResult, any Error>.Continuation.BufferingPolicy

    private let source: any FrameSource
    private let tracker: any FaceTracker
    private let now: @Sendable () -> Duration
    private let bufferingPolicy: BufferingPolicy

    /// `now`: the time used to measure the detection. Tests pass a scripted one.
    /// `bufferingPolicy`: by default only the newest result is kept, so a slow UI
    /// skips frames. The benchmark uses `.unbounded`.
    public init(
        source: any FrameSource,
        tracker: any FaceTracker,
        now: @escaping @Sendable () -> Duration = TrackingPipeline.monotonicNow(),
        bufferingPolicy: BufferingPolicy = .bufferingNewest(1)
    ) {
        self.source = source
        self.tracker = tracker
        self.now = now
        self.bufferingPolicy = bufferingPolicy
    }

    public func results() -> AsyncThrowingStream<TrackingResult, any Error> {
        let (stream, continuation) = AsyncThrowingStream.makeStream(
            of: TrackingResult.self,
            bufferingPolicy: bufferingPolicy
        )
        let source = source
        let tracker = tracker
        let now = now

        let task = Task {
            do {
                try await source.run { frame in
                    continuation.yield(Self.process(frame, tracker: tracker, now: now))
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
        continuation.onTermination = { _ in
            task.cancel()
            source.stop()
        }
        return stream
    }

    private static func process(
        _ frame: VideoFrame,
        tracker: any FaceTracker,
        now: @Sendable () -> Duration
    ) -> TrackingResult {
        let signpostState = Log.signposter.beginInterval("detect")
        let start = now()
        let face: FaceLandmarks?
        do {
            face = try tracker.face(in: frame)
        } catch {
            // A failed frame counts as "no face". The session goes on.
            Log.tracking.error("Detection failed: \(error.localizedDescription, privacy: .public)")
            face = nil
        }
        let processingTime = now() - start
        Log.signposter.endInterval("detect", signpostState)

        return TrackingResult(
            face: face,
            imageSize: frame.displaySize,
            timestamp: frame.timestamp,
            processingTime: processingTime
        )
    }

    /// Time since this call.
    public static func monotonicNow() -> @Sendable () -> Duration {
        let origin = ContinuousClock.now
        return { ContinuousClock.now - origin }
    }
}
