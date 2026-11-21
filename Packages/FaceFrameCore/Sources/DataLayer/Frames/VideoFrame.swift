//
//  VideoFrame.swift
//  DataLayer
//
//  Created by Lan YU on 21/11/2026.
//

import CoreVideo
import Domain
import ImageIO

/// One frame from a `FrameSource`.
///
/// Not `Sendable` on purpose: a `CVPixelBuffer` belongs to the source's queue
/// and is recycled by the capture session. Use it inside `onFrame`, never keep it.
public struct VideoFrame {
    public let pixelBuffer: CVPixelBuffer
    /// Presentation time of the frame.
    public let timestamp: Duration
    /// Orientation that makes the buffer look like the screen, to pass to Vision.
    /// Front camera held in portrait: `.leftMirrored`.
    public let orientation: CGImagePropertyOrientation

    public init(pixelBuffer: CVPixelBuffer, timestamp: Duration, orientation: CGImagePropertyOrientation) {
        self.pixelBuffer = pixelBuffer
        self.timestamp = timestamp
        self.orientation = orientation
    }

    /// Size of the image once `orientation` is applied, in pixels.
    public var displaySize: Size2D {
        let width = Double(CVPixelBufferGetWidth(pixelBuffer))
        let height = Double(CVPixelBufferGetHeight(pixelBuffer))
        switch orientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            return Size2D(width: height, height: width)
        default:
            return Size2D(width: width, height: height)
        }
    }
}
