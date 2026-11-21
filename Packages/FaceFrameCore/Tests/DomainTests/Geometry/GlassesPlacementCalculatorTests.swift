//
//  GlassesPlacementCalculatorTests.swift
//  DomainTests
//
//  Created by Lan YU on 21/11/2026.
//

import Domain
import Foundation
import Testing

/// Written before the implementation: red until the TODO in GlassesPlacementCalculator is done.
struct GlassesPlacementCalculatorTests {
    private let calculator = GlassesPlacementCalculator(widthToPupilDistanceRatio: 2.1)

    @Test func levelEyes() {
        let placement = calculator.placement(left: Point2D(x: 100, y: 200), right: Point2D(x: 200, y: 200))

        expectClose(placement.center, Point2D(x: 150, y: 200))
        expectClose(placement.width, 210)
        expectClose(placement.angle, 0)
    }

    @Test func rightEyeLowerTurnsClockwise() {
        let placement = calculator.placement(left: Point2D(x: 100, y: 100), right: Point2D(x: 200, y: 200))

        expectClose(placement.center, Point2D(x: 150, y: 150))
        expectClose(placement.width, 2.1 * (100 * 2.0.squareRoot()))
        expectClose(placement.angle, .pi / 4)
    }

    @Test func rightEyeHigherTurnsCounterClockwise() {
        let placement = calculator.placement(left: Point2D(x: 100, y: 200), right: Point2D(x: 200, y: 100))

        expectClose(placement.angle, -.pi / 4)
    }

    @Test(arguments: [1.8, 2.1, 2.4])
    func widthFollowsTheRatio(ratio: Double) {
        let calculator = GlassesPlacementCalculator(widthToPupilDistanceRatio: ratio)

        let placement = calculator.placement(left: Point2D(x: 100, y: 200), right: Point2D(x: 200, y: 200))

        expectClose(placement.width, 100 * ratio)
    }

    @Test func swappedPointsAreNotDrawnUpsideDown() {
        // A mirroring mistake upstream can hand over the pupils swapped. The
        // glasses should still be level, not rotated by 180°.
        let placement = calculator.placement(left: Point2D(x: 200, y: 200), right: Point2D(x: 100, y: 200))

        expectClose(placement.center, Point2D(x: 150, y: 200))
        expectClose(placement.width, 210)
        expectClose(placement.angle, 0)
    }
}
