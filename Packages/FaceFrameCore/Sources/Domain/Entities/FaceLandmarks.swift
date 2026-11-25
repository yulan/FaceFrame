//
//  FaceLandmarks.swift
//  Domain
//
//  Created by Lan YU on 23/11/2026.
//

import Foundation

/// One detected face. Same coordinates as `EyePositions`.
public struct FaceLandmarks: Equatable, Sendable {
    public var eyes: EyePositions
    /// Jaw line from one side to the other, in order. No forehead. Can be empty.
    public var contour: [Point2D]

    public init(eyes: EyePositions, contour: [Point2D] = []) {
        self.eyes = eyes
        self.contour = contour
    }
}
