//
//  Approximate.swift
//  DomainTests
//
//  Created by Lan YU on 21/11/2026.
//

import Domain
import Testing

/// Compares with a tolerance and prints both values on failure.
func expectClose(
    _ actual: Point2D,
    _ expected: Point2D,
    tolerance: Double = 0.001,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    #expect(
        abs(actual.x - expected.x) <= tolerance && abs(actual.y - expected.y) <= tolerance,
        "\(actual) is not \(expected)",
        sourceLocation: sourceLocation
    )
}

func expectClose(
    _ actual: Double,
    _ expected: Double,
    tolerance: Double = 0.001,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    #expect(abs(actual - expected) <= tolerance, "\(actual) is not \(expected)", sourceLocation: sourceLocation)
}
