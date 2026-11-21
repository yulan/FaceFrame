//
//  ExponentialSmoother.swift
//  Domain
//
//  Created by Lan YU on 21/11/2026.
//

import Foundation

/// Removes jitter from the detected pupils with an exponential moving average:
///
///     output = previous + alpha × (input − previous)
///
/// The trade-off: alpha close to 1 follows the face immediately but jitters;
/// close to 0 is stable but lags behind when the head moves.
public struct ExponentialSmoother: Sendable {
    public let alpha: Double
    private var previous: EyePositions?

    /// - Parameter alpha: in (0, 1].
    public init(alpha: Double) {
        precondition(alpha > 0 && alpha <= 1, "alpha must be in (0, 1]")
        self.alpha = alpha
    }

    public mutating func smooth(_ eyes: EyePositions) -> EyePositions {
        // TODO — Phase 1, step 3. Make ExponentialSmootherTests pass.
        // The first value (or the first one after reset()) passes through unchanged.
        // Placeholder below doesn't smooth anything.
        previous = eyes
        return eyes
    }

    /// Call when the face is lost, so the next face doesn't glide in from the
    /// old position.
    public mutating func reset() {
        previous = nil
    }
}
