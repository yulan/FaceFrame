//
//  EyePositions.swift
//  Domain
//
//  Created by Lan YU on 21/11/2026.
//

import Foundation

/// Pupil positions in the image **as it is displayed**.
///
/// Coordinate space: normalized to the whole image (0...1), origin at the
/// top-left, x to the right, y down. "As displayed" means the front-camera
/// mirroring is already applied, so `left` is the pupil that appears on the
/// left of the screen (the user's right eye).
public struct EyePositions: Equatable, Sendable {
    public var left: Point2D
    public var right: Point2D

    public init(left: Point2D, right: Point2D) {
        self.left = left
        self.right = right
    }
}
