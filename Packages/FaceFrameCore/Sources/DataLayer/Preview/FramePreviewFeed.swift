//
//  FramePreviewFeed.swift
//  DataLayer
//
//  Created by Lan YU on 22/11/2026.
//

import CoreGraphics
import CoreVideo
import ImageIO
import Synchronization

/// A frame as an image the UI can draw.
public struct PreviewFrame: Sendable {
    public let image: CGImage
    /// Orientation to draw `image` with.
    public let orientation: CGImagePropertyOrientation
}

/// Shows the frames of a source that has no preview layer, like a video file.
/// Each frame is copied (about 3.7 MB at 720p), so the pixel buffer stays on
/// the source's queue. The camera doesn't need this.
public final class FramePreviewFeed: Sendable {
    private let continuation = Mutex<AsyncStream<PreviewFrame>.Continuation?>(nil)

    public init() {}

    /// Newest frame only. One subscriber at a time.
    public func frames() -> AsyncStream<PreviewFrame> {
        let (stream, continuation) = AsyncStream.makeStream(of: PreviewFrame.self, bufferingPolicy: .bufferingNewest(1))
        let previous = self.continuation.withLock { current in
            defer { current = continuation }
            return current
        }
        previous?.finish()
        return stream
    }

    /// Called on the frame source's queue.
    func publish(_ frame: VideoFrame) {
        // Nobody is watching, so no copy.
        guard let continuation = continuation.withLock({ $0 }) else { return }
        guard let image = Self.copyImage(from: frame.pixelBuffer) else { return }
        continuation.yield(PreviewFrame(image: image, orientation: frame.orientation))
    }

    /// Copies a BGRA pixel buffer into an image that owns its pixels.
    private static func copyImage(from pixelBuffer: CVPixelBuffer) -> CGImage? {
        guard CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_32BGRA else {
            Log.frames.error("Preview needs BGRA frames")
            return nil
        }
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }

        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let pixels = Data(bytes: baseAddress, count: bytesPerRow * height)
        guard
            let provider = CGDataProvider(data: pixels as CFData),
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        else { return nil }

        // BGRA in memory. The alpha byte is not used.
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue)
            .union(.byteOrder32Little)
        return CGImage(
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }
}
