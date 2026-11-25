//
//  Point2D.swift
//  Domain
//
//  Created by Lan YU on 21/11/2026.
//

import Foundation

/// Domain doesn't import CoreGraphics, so it has its own point and size.
public struct Point2D: Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public struct Size2D: Equatable, Sendable {
    public var width: Double
    public var height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
}
