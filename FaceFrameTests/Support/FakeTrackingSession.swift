//
//  FakeTrackingSession.swift
//  FaceFrameTests
//
//  Created by Lan YU on 21/11/2026.
//

import Domain

/// Sends the given results, then finishes or fails.
struct FakeTrackingSession: FaceTrackingSession {
    var scripted: [TrackingResult]
    var failure: TrackingError?

    func results() -> AsyncThrowingStream<TrackingResult, any Error> {
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: TrackingResult.self)
        for result in scripted {
            continuation.yield(result)
        }
        continuation.finish(throwing: failure)
        return stream
    }
}

extension TrackingResult {
    static func frame(
        _ eyes: EyePositions?,
        contour: [Point2D] = [],
        at timestamp: Duration = .zero,
        processing: Duration = .milliseconds(4),
        imageSize: Size2D = Size2D(width: 100, height: 100)
    ) -> TrackingResult {
        TrackingResult(
            face: eyes.map { FaceLandmarks(eyes: $0, contour: contour) },
            imageSize: imageSize,
            timestamp: timestamp,
            processingTime: processing
        )
    }
}

extension EyePositions {
    static let centered = EyePositions(left: Point2D(x: 0.4, y: 0.5), right: Point2D(x: 0.6, y: 0.5))
    static let movedRight = EyePositions(left: Point2D(x: 0.5, y: 0.5), right: Point2D(x: 0.7, y: 0.5))
}
