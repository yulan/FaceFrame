//
//  VisionFaceTracker.swift
//  DataLayer
//
//  Created by Lan YU on 21/11/2026.
//

import CoreML
import Domain
import Vision

/// Finds the pupils and the jaw line with Vision.
/// One synchronous `VNDetectFaceLandmarksRequest` per frame: the pixel buffer
/// must stay on the frame queue, so the async Swift API doesn't fit.
/// Vision gets the frame's orientation, so its results are already in the
/// displayed picture.
public struct VisionFaceTracker: FaceTracker {
    public init() {}

    public func face(in frame: VideoFrame) throws -> FaceLandmarks? {
        let request = VNDetectFaceLandmarksRequest()
        #if targetEnvironment(simulator)
        try Self.useCPU(for: request)
        #endif
        let handler = VNImageRequestHandler(cvPixelBuffer: frame.pixelBuffer, orientation: frame.orientation)
        try handler.perform([request])

        // Keep the largest face.
        guard
            let face = request.results?.max(by: { Self.area(of: $0) < Self.area(of: $1) }),
            let landmarks = face.landmarks,
            let leftPupil = landmarks.leftPupil?.normalizedPoints.first,
            let rightPupil = landmarks.rightPupil?.normalizedPoints.first
        else { return nil }
        return Self.faceLandmarks(
            pupils: (leftPupil, rightPupil),
            // The contour comes with the same request.
            contour: landmarks.faceContour?.normalizedPoints ?? [],
            in: face.boundingBox
        )
    }

    // MARK: - Coordinates

    /// Vision coordinates to `FaceLandmarks`. The contour keeps its order.
    static func faceLandmarks(pupils: (CGPoint, CGPoint), contour: [CGPoint], in boundingBox: CGRect) -> FaceLandmarks {
        FaceLandmarks(
            eyes: eyePositions(pupils: pupils, in: boundingBox),
            contour: contour.map { imagePoint(for: $0, in: boundingBox) }
        )
    }

    /// `left` is the pupil on the left of the screen. Sorting by x works with
    /// or without mirroring.
    static func eyePositions(pupils: (CGPoint, CGPoint), in boundingBox: CGRect) -> EyePositions {
        let first = imagePoint(for: pupils.0, in: boundingBox)
        let second = imagePoint(for: pupils.1, in: boundingBox)
        return first.x <= second.x
            ? EyePositions(left: first, right: second)
            : EyePositions(left: second, right: first)
    }

    /// Vision: a landmark is relative to the face box, the box to the image,
    /// origin bottom-left. We want the whole image, origin top-left.
    static func imagePoint(for landmark: CGPoint, in boundingBox: CGRect) -> Point2D {
        let x = boundingBox.minX + landmark.x * boundingBox.width
        let yFromBottom = boundingBox.minY + landmark.y * boundingBox.height
        return Point2D(x: x, y: 1 - yFromBottom)
    }

    private static func area(of face: VNFaceObservation) -> CGFloat {
        face.boundingBox.width * face.boundingBox.height
    }

    // MARK: - Simulator

    #if targetEnvironment(simulator)
    /// In the simulator the request fails with "Could not create inference
    /// context" unless it runs on the CPU.
    private static func useCPU(for request: VNRequest) throws {
        for (stage, devices) in try request.supportedComputeStageDevices {
            let cpu = devices.first { device in
                if case .cpu = device { true } else { false }
            }
            guard let cpu else { continue }
            request.setComputeDevice(cpu, for: stage)
        }
    }
    #endif
}
