//
//  GlassesPlacement.swift
//  Domain
//
//  Created by Lan YU on 21/11/2026.
//

import Foundation

/// Where to draw the glasses, in view points.
public struct GlassesPlacement: Equatable, Sendable {
    /// Midpoint between the pupils.
    public var center: Point2D
    /// In points.
    public var width: Double
    /// In radians. Positive is clockwise on screen, because y goes down.
    public var angle: Double

    public init(center: Point2D, width: Double, angle: Double) {
        self.center = center
        self.width = width
        self.angle = angle
    }
}
