//
//  ExponentialSmootherTests.swift
//  DomainTests
//
//  Created by Lan YU on 21/11/2026.
//

import Domain
import Testing

/// Written before the implementation: some tests are red until the TODO in ExponentialSmoother is done.
struct ExponentialSmootherTests {
    private func eyes(leftX: Double, rightX: Double, y: Double) -> EyePositions {
        EyePositions(left: Point2D(x: leftX, y: y), right: Point2D(x: rightX, y: y))
    }

    @Test func firstValuePassesThrough() {
        var smoother = ExponentialSmoother(alpha: 0.3)
        let first = eyes(leftX: 0.4, rightX: 0.6, y: 0.4)

        #expect(smoother.smooth(first) == first)
    }

    @Test func secondValueMovesAlphaOfTheWay() {
        var smoother = ExponentialSmoother(alpha: 0.5)
        _ = smoother.smooth(eyes(leftX: 0.40, rightX: 0.60, y: 0.40))

        let smoothed = smoother.smooth(eyes(leftX: 0.50, rightX: 0.70, y: 0.50))

        expectClose(smoothed.left, Point2D(x: 0.45, y: 0.45))
        expectClose(smoothed.right, Point2D(x: 0.65, y: 0.45))
    }

    @Test func alphaOneFollowsImmediately() {
        var smoother = ExponentialSmoother(alpha: 1)
        _ = smoother.smooth(eyes(leftX: 0.40, rightX: 0.60, y: 0.40))
        let next = eyes(leftX: 0.50, rightX: 0.70, y: 0.50)

        #expect(smoother.smooth(next) == next)
    }

    @Test func resetForgetsThePreviousFace() {
        var smoother = ExponentialSmoother(alpha: 0.2)
        _ = smoother.smooth(eyes(leftX: 0.1, rightX: 0.3, y: 0.2))
        smoother.reset()
        let newFace = eyes(leftX: 0.6, rightX: 0.8, y: 0.5)

        #expect(smoother.smooth(newFace) == newFace)
    }

    @Test func convergesOnAStillFace() {
        var smoother = ExponentialSmoother(alpha: 0.3)
        _ = smoother.smooth(eyes(leftX: 0.2, rightX: 0.4, y: 0.3))
        let still = eyes(leftX: 0.6, rightX: 0.8, y: 0.5)

        var smoothed = still
        for _ in 0..<30 {
            smoothed = smoother.smooth(still)
        }

        expectClose(smoothed.left, still.left)
        expectClose(smoothed.right, still.right)
    }
}
