//
//  GlassesPlacementCalculator.swift
//  Domain
//
//  Created by Lan YU on 21/11/2026.
//

import Foundation

/// Turns two pupils (in view points) into where and how to draw the glasses.
public struct GlassesPlacementCalculator: Equatable, Sendable {
    /// Frame width as a multiple of the distance between the pupils.
    /// Adults average about 63 mm between pupils and frames are about 130–140 mm
    /// wide, hence ~2.1. Tune it on screen.
    public var widthToPupilDistanceRatio: Double

    public init(widthToPupilDistanceRatio: Double = 2.1) {
        self.widthToPupilDistanceRatio = widthToPupilDistanceRatio
    }

    public func placement(left: Point2D, right: Point2D) -> GlassesPlacement {
        // TODO — Phase 1, step 2. Make GlassesPlacementCalculatorTests pass.
        // - center: midpoint of the two pupils
        // - width: distance between the pupils × widthToPupilDistanceRatio
        // - angle: atan2 of the vector from the left pupil to the right one
        // - edge case: if the points arrive swapped (right.x < left.x), the
        //   glasses must not be drawn upside down. See the test.
        GlassesPlacement(center: left, width: 0, angle: 0)
    }
}
