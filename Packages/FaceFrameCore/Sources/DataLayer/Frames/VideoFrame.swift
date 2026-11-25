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
/// Not `Sendable`: the session reuses the pixel buffer. Use it inside `onFrame` only.
public struct VideoFrame {
    public let pixelBuffer: CVPixelBuffer
    public let timestamp: Duration
    /// Orientation to give to Vision. Front camera in portrait: `.leftMirrored`.
    public let orientation: CGImagePropertyOrientation

    public init(pixelBuffer: CVPixelBuffer, timestamp: Duration, orientation: CGImagePropertyOrientation) {
        self.pixelBuffer = pixelBuffer
        self.timestamp = timestamp
        self.orientation = orientation
    }

    /// Image size with `orientation` applied, in pixels.
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
