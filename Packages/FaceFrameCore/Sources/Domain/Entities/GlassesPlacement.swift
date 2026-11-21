//
//  GlassesPlacement.swift
//  Domain
//
//  Created by Lan YU on 21/11/2026.
//

import Foundation

/// Where to draw the glasses, in view points.
public struct GlassesPlacement: Equatable, Sendable {
    /// Midpoint between the pupils: the bridge of the glasses.
    public var center: Point2D
    /// Width of the frame, in points.
    public var width: Double
    /// Rotation in radians. y grows downwards, so a positive angle turns the
    /// glasses clockwise on screen (right eye lower than the left one).
    public var angle: Double

    public init(center: Point2D, width: Double, angle: Double) {
        self.center = center
        self.width = width
        self.angle = angle
    }
}
