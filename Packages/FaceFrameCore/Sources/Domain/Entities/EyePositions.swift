//
//  EyePositions.swift
//  Domain
//
//  Created by Lan YU on 21/11/2026.
//

import Foundation

/// Pupils in the image as displayed, mirroring already applied.
/// Normalized 0...1, origin top-left, y down.
/// `left` is the pupil on the left of the screen.
public struct EyePositions: Equatable, Sendable {
    public var left: Point2D
    public var right: Point2D

    public init(left: Point2D, right: Point2D) {
        self.left = left
        self.right = right
    }
}
