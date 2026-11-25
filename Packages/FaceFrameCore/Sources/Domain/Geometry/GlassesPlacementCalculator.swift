//
//  GlassesPlacementCalculator.swift
//  Domain
//
//  Created by Lan YU on 21/11/2026.
//

import Foundation

/// From two pupils in view points to the glasses placement.
public struct GlassesPlacementCalculator: Equatable, Sendable {
    /// Frame width divided by pupil distance.
    /// About 63 mm between pupils and 135 mm for a frame gives 2.1.
    public var widthToPupilDistanceRatio: Double

    public init(widthToPupilDistanceRatio: Double = 2.1) {
        self.widthToPupilDistanceRatio = widthToPupilDistanceRatio
    }

    public func placement(left: Point2D, right: Point2D) -> GlassesPlacement {
        // The pupils can arrive swapped. Going from left to right keeps the angle
        // between -90 and 90 degrees, so the glasses are never upside down.
        let (start, end) = left.x <= right.x ? (left, right) : (right, left)
        let dx = end.x - start.x
        let dy = end.y - start.y
        return GlassesPlacement(
            center: Point2D(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2),
            width: hypot(dx, dy) * widthToPupilDistanceRatio,
            // y goes down, so the angle is positive when the right eye is lower.
            angle: atan2(dy, dx)
        )
    }
}
