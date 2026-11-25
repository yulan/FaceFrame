//
//  VisionFaceTrackerTests.swift
//  DataLayerTests
//
//  Created by Lan YU on 23/11/2026.
//

import CoreGraphics
import CoreVideo
@testable import DataLayer
import Domain
import Testing

/// Tests the coordinate conversion. Finding a real face is checked on screen.
struct VisionFaceTrackerTests {
    /// A face box in Vision coordinates. Halves and quarters, so the expected values are exact.
    private static let box = CGRect(x: 0.25, y: 0.125, width: 0.5, height: 0.25)

    // MARK: - From the face box to the image

    @Test(arguments: [
        // Middle of the box.
        (CGPoint(x: 0.5, y: 0.5), Point2D(x: 0.5, y: 0.75)),
        // Bottom-left corner of the box.
        (CGPoint(x: 0, y: 0), Point2D(x: 0.25, y: 0.875)),
        // Top-right corner of the box.
        (CGPoint(x: 1, y: 1), Point2D(x: 0.75, y: 0.625)),
    ])
    func aLandmarkIsPlacedInTheImageWithTheOriginAtTheTop(landmark: CGPoint, expected: Point2D) {
        #expect(VisionFaceTracker.imagePoint(for: landmark, in: Self.box) == expected)
    }

    // MARK: - Left and right

    @Test func leftIsThePupilOnTheLeftOfTheScreen() {
        let onTheRight = CGPoint(x: 0.75, y: 0.5)
        let onTheLeft = CGPoint(x: 0.25, y: 0.5)

        let eyes = VisionFaceTracker.eyePositions(pupils: (onTheRight, onTheLeft), in: Self.box)

        #expect(eyes == EyePositions(left: Point2D(x: 0.375, y: 0.75), right: Point2D(x: 0.625, y: 0.75)))
    }

    @Test func pupilsAlreadyInScreenOrderKeepTheirOrder() {
        let onTheLeft = CGPoint(x: 0.25, y: 0.5)
        let onTheRight = CGPoint(x: 0.75, y: 0.5)

        let eyes = VisionFaceTracker.eyePositions(pupils: (onTheLeft, onTheRight), in: Self.box)

        #expect(eyes == EyePositions(left: Point2D(x: 0.375, y: 0.75), right: Point2D(x: 0.625, y: 0.75)))
    }

    // MARK: - Outline of the face

    @Test func theContourIsPlacedInTheImageInTheSameOrder() {
        // Top-left of the box, middle of its bottom edge, top-right.
        let contour = [CGPoint(x: 0, y: 1), CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 1)]

        let face = VisionFaceTracker.faceLandmarks(
            pupils: (CGPoint(x: 0.25, y: 0.5), CGPoint(x: 0.75, y: 0.5)),
            contour: contour,
            in: Self.box
        )

        #expect(face.contour == [Point2D(x: 0.25, y: 0.625), Point2D(x: 0.5, y: 0.875), Point2D(x: 0.75, y: 0.625)])
        #expect(face.eyes == EyePositions(left: Point2D(x: 0.375, y: 0.75), right: Point2D(x: 0.625, y: 0.75)))
    }

    @Test func aFaceWithoutAContourKeepsItsEyes() {
        let face = VisionFaceTracker.faceLandmarks(
            pupils: (CGPoint(x: 0.25, y: 0.5), CGPoint(x: 0.75, y: 0.5)),
            contour: [],
            in: Self.box
        )

        #expect(face.contour.isEmpty)
        #expect(face.eyes == EyePositions(left: Point2D(x: 0.375, y: 0.75), right: Point2D(x: 0.625, y: 0.75)))
    }

    // MARK: - Vision

    /// Runs the real request. In the simulator it needs the CPU compute device.
    @Test func aPictureWithoutAFaceGivesNoFace() throws {
        let frame = VideoFrame(pixelBuffer: Self.makeBlackPixelBuffer(), timestamp: .zero, orientation: .up)

        #expect(try VisionFaceTracker().face(in: frame) == nil)
    }

    private static func makeBlackPixelBuffer(width: Int = 320, height: Int = 240) -> CVPixelBuffer {
        var created: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, nil, &created)
        guard status == kCVReturnSuccess, let buffer = created else {
            preconditionFailure("CVPixelBufferCreate failed: \(status)")
        }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        if let baseAddress = CVPixelBufferGetBaseAddress(buffer) {
            memset(baseAddress, 0, CVPixelBufferGetBytesPerRow(buffer) * height)
        }
        return buffer
    }
}
