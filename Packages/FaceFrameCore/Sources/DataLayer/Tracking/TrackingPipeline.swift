//
//  TrackingPipeline.swift
//  DataLayer
//
//  Created by Lan YU on 21/11/2026.
//

import Domain
import Foundation

/// Connects a `FrameSource` to a `FaceTracker` and publishes one
/// `TrackingResult` per frame.
///
///     source queue: frame ─▶ tracker.eyes(in:) ─▶ TrackingResult ─▶ stream ─▶ MainActor
///
/// The detection runs synchronously on the source's queue, so the pixel buffer
/// never crosses an isolation boundary; only the `Sendable` result does.
public final class TrackingPipeline: FaceTrackingSession {
    public typealias BufferingPolicy = AsyncThrowingStream<TrackingResult, any Error>.Continuation.BufferingPolicy

    private let source: any FrameSource
    private let tracker: any FaceTracker
    private let now: @Sendable () -> Duration
    private let bufferingPolicy: BufferingPolicy

    /// - Parameters:
    ///   - now: a monotonic time used to measure the detection. Tests inject a
    ///     scripted one.
    ///   - bufferingPolicy: the default keeps only the newest result: if the
    ///     UI falls behind, showing an old position late is worse than
    ///     skipping it. A benchmark that must see every frame uses `.unbounded`.
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
        let eyes: EyePositions?
        do {
            eyes = try tracker.eyes(in: frame)
        } catch {
            // One bad frame shouldn't end the session: treat it as "no face".
            Log.tracking.error("Detection failed: \(error.localizedDescription, privacy: .public)")
            eyes = nil
        }
        let processingTime = now() - start
        Log.signposter.endInterval("detect", signpostState)

        return TrackingResult(
            eyes: eyes,
            imageSize: frame.displaySize,
            timestamp: frame.timestamp,
            processingTime: processingTime
        )
    }

    /// Time elapsed since the call, from the monotonic `ContinuousClock`.
    public static func monotonicNow() -> @Sendable () -> Duration {
        let origin = ContinuousClock.now
        return { ContinuousClock.now - origin }
    }
}
