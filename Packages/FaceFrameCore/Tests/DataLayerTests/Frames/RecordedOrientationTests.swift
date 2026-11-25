//
//  RecordedOrientationTests.swift
//  DataLayerTests
//
//  Created by Lan YU on 22/11/2026.
//

import CoreGraphics
@testable import DataLayer
import ImageIO
import Testing

struct RecordedOrientationTests {
    private static let identity = CGAffineTransform.identity
    /// A phone in portrait stores a quarter turn clockwise.
    private static let quarterTurn = CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: 1080, ty: 0)
    private static let halfTurn = CGAffineTransform(a: -1, b: 0, c: 0, d: -1, tx: 1920, ty: 1080)
    private static let threeQuarterTurn = CGAffineTransform(a: 0, b: -1, c: 1, d: 0, tx: 0, ty: 1920)

    @Test(arguments: [
        (identity, CGImagePropertyOrientation.up),
        (quarterTurn, .right),
        (halfTurn, .down),
        (threeQuarterTurn, .left),
    ])
    func readsTheTurn(transform: CGAffineTransform, expected: CGImagePropertyOrientation) {
        #expect(CGImagePropertyOrientation(preferredTransform: transform, mirrored: false) == expected)
    }

    /// Mirrored: flipped left to right. Portrait gives `.leftMirrored`, as for the front camera.
    @Test(arguments: [
        (identity, CGImagePropertyOrientation.upMirrored),
        (quarterTurn, .leftMirrored),
        (halfTurn, .downMirrored),
        (threeQuarterTurn, .rightMirrored),
    ])
    func mirrorsTheTurn(transform: CGAffineTransform, expected: CGImagePropertyOrientation) {
        #expect(CGImagePropertyOrientation(preferredTransform: transform, mirrored: true) == expected)
    }

    @Test func anythingElseIsTreatedAsNoRotation() {
        let skewed = CGAffineTransform(rotationAngle: 0.3)

        #expect(CGImagePropertyOrientation(preferredTransform: skewed, mirrored: false) == .up)
    }
}
