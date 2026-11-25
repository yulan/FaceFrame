//
//  SimulatedTrackingSession.swift
//  DataLayer
//
//  Created by Lan YU on 21/11/2026.
//

import Domain
import Foundation

/// A fake face that moves in a circle and tilts, at a fixed frame rate.
/// For the simulator and SwiftUI previews. Not for tests: it uses the real clock.
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
                        face: Self.face(at: time),
                        imageSize: imageSize,
                        timestamp: .seconds(time),
                        processingTime: .milliseconds(4)
                    ))
                    frame += 1
                    // Sleep until a fixed deadline, so the rate doesn't drift.
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

    private static func face(at time: Double) -> FaceLandmarks {
        let center = Point2D(x: 0.5 + 0.08 * cos(time), y: 0.42 + 0.05 * sin(time))
        let tilt = 0.15 * sin(time * 0.7)
        let halfDistance = 0.09
        let faceHalfWidth = 0.2
        let chinDepth = 0.19
        let contourSegments = 16

        // `along`: on the line of the eyes. `below`: under that line.
        func point(along: Double, below: Double) -> Point2D {
            Point2D(
                x: center.x + along * cos(tilt) - below * sin(tilt),
                y: center.y + along * sin(tilt) + below * cos(tilt)
            )
        }

        // Half an ellipse under the eyes.
        let contour = (0...contourSegments).map { segment in
            let angle = Double.pi * Double(segment) / Double(contourSegments)
            return point(along: -faceHalfWidth * cos(angle), below: chinDepth * sin(angle))
        }
        return FaceLandmarks(
            eyes: EyePositions(
                left: point(along: -halfDistance, below: 0),
                right: point(along: halfDistance, below: 0)
            ),
            contour: contour
        )
    }
}
