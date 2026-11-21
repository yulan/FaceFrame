//
//  PreviewedFrameSourceTests.swift
//  DataLayerTests
//
//  Created by Lan YU on 22/11/2026.
//

import CoreGraphics
import CoreVideo
import DataLayer
import Domain
import Foundation
import ImageIO
import Synchronization
import Testing

@Suite(.timeLimit(.minutes(1)))
struct PreviewedFrameSourceTests {
    /// Delivers one BGRA frame per given width, each filled with one colour.
    private struct ColouredFrameSource: FrameSource {
        var widths: [Int]
        var orientation: CGImagePropertyOrientation = .up
        var blue: UInt8 = 10
        var green: UInt8 = 20
        var red: UInt8 = 30

        func run(onFrame: @escaping @Sendable (VideoFrame) -> Void) async throws {
            for (index, width) in widths.enumerated() {
                let buffer = makePixelBuffer(width: width, height: 2)
                CVPixelBufferLockBaseAddress(buffer, [])
                let bytes = CVPixelBufferGetBaseAddress(buffer)!.assumingMemoryBound(to: UInt8.self)
                let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
                for row in 0..<2 {
                    for column in 0..<width {
                        let pixel = bytes + row * bytesPerRow + column * 4
                        pixel[0] = blue
                        pixel[1] = green
                        pixel[2] = red
                        pixel[3] = 255
                    }
                }
                CVPixelBufferUnlockBaseAddress(buffer, [])
                onFrame(VideoFrame(pixelBuffer: buffer, timestamp: .milliseconds(index * 100), orientation: orientation))
            }
        }

        func stop() {}
    }

    @Test func forwardsEveryFrameToThePipeline() async throws {
        let source = PreviewedFrameSource(FakeFrameSource(frameCount: 3), feed: FramePreviewFeed())
        let timestamps = Mutex<[Duration]>([])

        try await source.run { frame in
            timestamps.withLock { $0.append(frame.timestamp) }
        }

        #expect(timestamps.withLock { $0 } == [.zero, .milliseconds(100), .milliseconds(200)])
    }

    @Test func publishesACopyOfTheFrameWithItsOrientation() async throws {
        let feed = FramePreviewFeed()
        let frames = feed.frames()
        let source = PreviewedFrameSource(ColouredFrameSource(widths: [4], orientation: .leftMirrored), feed: feed)

        try await source.run { _ in }

        let frame = try #require(await frames.first { _ in true })
        #expect(frame.orientation == .leftMirrored)
        #expect(frame.image.width == 4 && frame.image.height == 2)
        // Same pixels, in the same B, G, R order.
        let pixels = try #require(frame.image.dataProvider?.data as Data?)
        #expect(Array(pixels.prefix(3)) == [10, 20, 30])
    }

    /// A slow screen must show the latest picture, not a queue of old ones.
    @Test func keepsOnlyTheNewestFrame() async throws {
        let feed = FramePreviewFeed()
        let frames = feed.frames()
        let source = PreviewedFrameSource(ColouredFrameSource(widths: [1, 2, 3]), feed: feed)

        try await source.run { _ in }

        let frame = try #require(await frames.first { _ in true })
        #expect(frame.image.width == 3)
    }

    /// The picture must not be ahead of its tracking result.
    @Test func showsTheFrameAfterItHasBeenProcessed() async throws {
        let feed = FramePreviewFeed()
        let subscribedBefore = feed.frames()
        let subscribedDuring = Mutex<AsyncStream<PreviewFrame>?>(nil)
        let source = PreviewedFrameSource(ColouredFrameSource(widths: [1]), feed: feed)

        try await source.run { _ in
            // Subscribing again while the frame is being processed ends the
            // first stream. A frame published before this point would already
            // be waiting in it.
            subscribedDuring.withLock { $0 = feed.frames() }
        }

        #expect(await subscribedBefore.first { _ in true } == nil)
        let later = try #require(subscribedDuring.withLock { $0 })
        #expect(await later.first { _ in true } != nil)
    }

    @Test func aSecondSubscriberEndsTheFirstStream() async {
        let feed = FramePreviewFeed()
        let first = feed.frames()
        _ = feed.frames()

        #expect(await first.first { _ in true } == nil)
    }

    @Test func stopReachesTheWrappedSource() {
        let base = FakeFrameSource(frameCount: 0)
        let source = PreviewedFrameSource(base, feed: FramePreviewFeed())

        source.stop()

        #expect(base.stopCount == 1)
    }
}
