//
//  SimulatedTrackingSession.swift
//  DataLayer
//
//  Created by Lan YU on 21/11/2026.
//

import Domain
import Foundation

/// Fake pupils that drift in a circle and tilt slowly, at a steady frame rate.
///
/// For the simulator (no camera) and SwiftUI previews: it lets you check the
/// overlay, the smoothing and the performance badge before the camera works.
/// Not for tests: it runs on the real clock.
public struct SimulatedTrackingSession: FaceTrackingSession {
    private let framesPerSecond: Int
    private let imageSize = Size2D(width: 720, height: 1280)

    public init(framesPerSecond: Int = 30) {
        precondition(framesPerSecond > 0)
        self.framesPerSecond = framesPerSecond
    }

    public func results() -> AsyncThrowingStream<TrackingResult, any Error> {
        let fps = framesPerSecond
        let imageSize = imageSize
        return AsyncThrowingStream { continuation in
            let task = Task {
                let clock = ContinuousClock()
                let start = clock.now
                var frame = 0
                while !Task.isCancelled {
                    let time = Double(frame) / Double(fps)
                    continuation.yield(TrackingResult(
                        eyes: Self.eyes(at: time),
                        imageSize: imageSize,
                        timestamp: .seconds(time),
                        processingTime: .milliseconds(4)
                    ))
                    frame += 1
                    // Sleep until an absolute deadline so the rate doesn't drift.
                    do {
                        try await clock.sleep(until: start + .seconds(Double(frame) / Double(fps)))
                    } catch {
                        break
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static func eyes(at time: Double) -> EyePositions {
        let center = Point2D(x: 0.5 + 0.08 * cos(time), y: 0.42 + 0.05 * sin(time))
        let tilt = 0.15 * sin(time * 0.7)
        let halfDistance = 0.09
        return EyePositions(
            left: Point2D(x: center.x - halfDistance * cos(tilt), y: center.y - halfDistance * sin(tilt)),
            right: Point2D(x: center.x + halfDistance * cos(tilt), y: center.y + halfDistance * sin(tilt))
        )
    }
}
