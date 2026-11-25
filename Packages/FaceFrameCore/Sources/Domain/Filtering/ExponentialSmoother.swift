//
//  ExponentialSmoother.swift
//  Domain
//
//  Created by Lan YU on 21/11/2026.
//

import Foundation

/// Exponential moving average on the pupils:
///     output = previous + alpha * (input - previous)
/// alpha near 1 follows fast but shakes. Near 0 is stable but late.
public struct ExponentialSmoother: Sendable {
    public let alpha: Double
    private var previous: EyePositions?

    /// `alpha` is in (0, 1].
    public init(alpha: Double) {
        precondition(alpha > 0 && alpha <= 1, "alpha must be in (0, 1]")
        self.alpha = alpha
    }

    public mutating func smooth(_ eyes: EyePositions) -> EyePositions {
        guard let previous else {
            self.previous = eyes
            return eyes
        }
        let smoothed = EyePositions(
            left: blend(previous.left, eyes.left),
            right: blend(previous.right, eyes.right)
        )
        self.previous = smoothed
        return smoothed
    }

    private func blend(_ a: Point2D, _ b: Point2D) -> Point2D {
        Point2D(x: a.x + alpha * (b.x - a.x), y: a.y + alpha * (b.y - a.y))
    }

    /// Call when the face is lost, so the next face doesn't start from the old position.
    public mutating func reset() {
        previous = nil
    }
}
