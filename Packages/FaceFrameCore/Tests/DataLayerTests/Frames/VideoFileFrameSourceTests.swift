//
//  VideoFileFrameSourceTests.swift
//  DataLayerTests
//
//  Created by Lan YU on 21/11/2026.
//

import CoreGraphics
import DataLayer
import Domain
import Foundation
import ImageIO
import Synchronization
import Testing

struct VideoFileFrameSourceTests {
    private final class Recorder: Sendable {
        let timestamps = Mutex<[Duration]>([])
        let sizes = Mutex<[Size2D]>([])

        /// Timestamps in milliseconds: the clips are at 10 frames per second,
        /// so rounding hides the conversion from the file's time scale.
        var milliseconds: [Int] {
            timestamps.withLock { $0 }.map { Int(($0 / .milliseconds(1)).rounded()) }
        }
    }

    private static func milliseconds(_ durations: [Duration]) -> [Int] {
        durations.map { Int(($0 / .milliseconds(1)).rounded()) }
    }

    // MARK: - Reading

    @Test func deliversEveryFrameInOrder() async throws {
        let url = try await TestVideo.make(frameCount: 5)
        defer { try? FileManager.default.removeItem(at: url) }
        let source = VideoFileFrameSource(url: url)
        let recorder = Recorder()

        try await source.run { frame in
            recorder.timestamps.withLock { $0.append(frame.timestamp) }
            recorder.sizes.withLock { $0.append(frame.displaySize) }
        }

        #expect(recorder.milliseconds == [0, 100, 200, 300, 400])
        #expect(recorder.sizes.withLock { $0 }.allSatisfy { $0 == Size2D(width: 64, height: 48) })
    }

    @Test func aMissingFileFailsWithSourceFailed() async {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("does-not-exist.mov")
        let source = VideoFileFrameSource(url: url)

        await #expect(throws: TrackingError.sourceFailed) {
            try await source.run { _ in }
        }
    }

    // MARK: - Orientation

    @Test func aFixedOrientationIsAppliedToTheDisplayedSize() async throws {
        let url = try await TestVideo.make(frameCount: 1)
        defer { try? FileManager.default.removeItem(at: url) }
        let source = VideoFileFrameSource(url: url, orientation: .fixed(.leftMirrored))
        let recorder = Recorder()

        try await source.run { frame in
            recorder.sizes.withLock { $0.append(frame.displaySize) }
        }

        #expect(recorder.sizes.withLock { $0 } == [Size2D(width: 48, height: 64)])
    }

    /// A phone held in portrait stores landscape frames and a quarter turn.
    @Test func readsTheRotationStoredInTheFile() async throws {
        let url = try await TestVideo.make(frameCount: 1, transform: CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: 48, ty: 0))
        defer { try? FileManager.default.removeItem(at: url) }
        let source = VideoFileFrameSource(url: url, orientation: .recorded(mirrored: true))
        let orientations = Mutex<[CGImagePropertyOrientation]>([])
        let recorder = Recorder()

        try await source.run { frame in
            orientations.withLock { $0.append(frame.orientation) }
            recorder.sizes.withLock { $0.append(frame.displaySize) }
        }

        #expect(orientations.withLock { $0 } == [.leftMirrored])
        #expect(recorder.sizes.withLock { $0 } == [Size2D(width: 48, height: 64)])
    }

    // MARK: - Stopping

    @Test func stopEndsDeliveryEarly() async throws {
        let url = try await TestVideo.make(frameCount: 10)
        defer { try? FileManager.default.removeItem(at: url) }
        let source = VideoFileFrameSource(url: url)
        let recorder = Recorder()

        try await source.run { frame in
            let count = recorder.timestamps.withLock { timestamps in
                timestamps.append(frame.timestamp)
                return timestamps.count
            }
            if count == 2 { source.stop() }
        }

        #expect(recorder.timestamps.withLock { $0.count } == 2)
    }

    /// "Try Again" runs the same source a second time.
    @Test func aStoppedSourceCanRunAgain() async throws {
        let url = try await TestVideo.make(frameCount: 3)
        defer { try? FileManager.default.removeItem(at: url) }
        let source = VideoFileFrameSource(url: url)
        let recorder = Recorder()

        try await source.run { _ in source.stop() }
        try await source.run { frame in
            recorder.timestamps.withLock { $0.append(frame.timestamp) }
        }

        #expect(recorder.timestamps.withLock { $0.count } == 3)
    }

    @Test(.timeLimit(.minutes(1)))
    func cancellingTheTaskStopsALoopingSource() async throws {
        let url = try await TestVideo.make(frameCount: 2)
        defer { try? FileManager.default.removeItem(at: url) }
        let source = VideoFileFrameSource(url: url, loops: true)
        let (started, startedContinuation) = AsyncStream.makeStream(of: Void.self)

        let task = Task {
            try await source.run { _ in startedContinuation.yield() }
        }
        for await _ in started { break }
        task.cancel()

        // Without the cancellation handler this would never return.
        try await task.value
    }

    // MARK: - Looping

    @Test func loopingStartsAgainWithTimestampsThatKeepIncreasing() async throws {
        let url = try await TestVideo.make(frameCount: 3)
        defer { try? FileManager.default.removeItem(at: url) }
        let source = VideoFileFrameSource(url: url, loops: true)
        let recorder = Recorder()

        try await source.run { frame in
            let count = recorder.timestamps.withLock { timestamps in
                timestamps.append(frame.timestamp)
                return timestamps.count
            }
            if count == 7 { source.stop() }
        }

        #expect(recorder.milliseconds == [0, 100, 200, 300, 400, 500, 600])
    }

    // MARK: - Real-time pacing

    @Test func realTimeWaitsForEachFramesTurn() async throws {
        let url = try await TestVideo.make(frameCount: 3)
        defer { try? FileManager.default.removeItem(at: url) }
        let fakeClock = FakePlaybackClock()
        let source = VideoFileFrameSource(url: url, pacing: .realTime, clock: fakeClock.clock)

        try await source.run { _ in }

        // The first frame goes out at once; the others one frame apart.
        #expect(Self.milliseconds(fakeClock.sleeps) == [100, 100])
    }

    @Test func realTimeTakesTheProcessingTimeOffTheWait() async throws {
        let url = try await TestVideo.make(frameCount: 3)
        defer { try? FileManager.default.removeItem(at: url) }
        let fakeClock = FakePlaybackClock()
        let source = VideoFileFrameSource(url: url, pacing: .realTime, clock: fakeClock.clock)

        try await source.run { _ in fakeClock.advance(by: .milliseconds(30)) }

        #expect(Self.milliseconds(fakeClock.sleeps) == [70, 70])
    }

    @Test func realTimeDropsAFrameThatIsAlreadyLate() async throws {
        let url = try await TestVideo.make(frameCount: 5)
        defer { try? FileManager.default.removeItem(at: url) }
        let fakeClock = FakePlaybackClock()
        let source = VideoFileFrameSource(url: url, pacing: .realTime, clock: fakeClock.clock)
        let recorder = Recorder()

        try await source.run { frame in
            let isFirst = recorder.timestamps.withLock { timestamps in
                timestamps.append(frame.timestamp)
                return timestamps.count == 1
            }
            // The first frame takes two and a half frames to process.
            if isFirst { fakeClock.advance(by: .milliseconds(250)) }
        }

        // 100 ms is 150 ms late: dropped. 200 ms is only 50 ms late: delivered.
        #expect(recorder.milliseconds == [0, 200, 300, 400])
        #expect(Self.milliseconds(fakeClock.sleeps) == [50, 100])
    }

    @Test func asFastAsPossibleNeverWaits() async throws {
        let url = try await TestVideo.make(frameCount: 3)
        defer { try? FileManager.default.removeItem(at: url) }
        let fakeClock = FakePlaybackClock()
        let source = VideoFileFrameSource(url: url, clock: fakeClock.clock)

        try await source.run { _ in }

        #expect(fakeClock.sleeps.isEmpty)
    }
}
