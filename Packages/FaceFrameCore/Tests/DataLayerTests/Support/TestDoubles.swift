//
//  TestDoubles.swift
//  DataLayerTests
//
//  Created by Lan YU on 21/11/2026.
//

import CoreVideo
import DataLayer
import Domain
import ImageIO
import Synchronization

enum TestError: Error {
    case detection
}

/// A small blank pixel buffer. The fakes don't read the pixels.
func makePixelBuffer(width: Int = 4, height: Int = 3) -> CVPixelBuffer {
    var buffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, nil, &buffer)
    precondition(status == kCVReturnSuccess && buffer != nil, "CVPixelBufferCreate failed: \(status)")
    return buffer!
}

/// Delivers `frameCount` blank frames. With `waitsForStop`, keeps running until `stop()`.
final class FakeFrameSource: FrameSource {
    private struct State {
        var stopCount = 0
        var runContinuation: CheckedContinuation<Void, Never>?
        var stopWaiters: [CheckedContinuation<Void, Never>] = []
    }

    private let frameCount: Int
    private let orientation: CGImagePropertyOrientation
    private let waitsForStop: Bool
    private let failure: TrackingError?
    private let state = Mutex(State())

    init(
        frameCount: Int,
        orientation: CGImagePropertyOrientation = .up,
        waitsForStop: Bool = false,
        failure: TrackingError? = nil
    ) {
        self.frameCount = frameCount
        self.orientation = orientation
        self.waitsForStop = waitsForStop
        self.failure = failure
    }

    var stopCount: Int { state.withLock { $0.stopCount } }

    func run(onFrame: @escaping @Sendable (VideoFrame) -> Void) async throws {
        if let failure { throw failure }
        for index in 0..<frameCount {
            onFrame(VideoFrame(
                pixelBuffer: makePixelBuffer(),
                timestamp: .milliseconds(index * 100),
                orientation: orientation
            ))
        }
        guard waitsForStop else { return }
        await withCheckedContinuation { continuation in
            let alreadyStopped = state.withLock { state in
                if state.stopCount > 0 { return true }
                state.runContinuation = continuation
                return false
            }
            if alreadyStopped { continuation.resume() }
        }
    }

    func stop() {
        let (run, waiters) = state.withLock { state in
            state.stopCount += 1
            defer {
                state.runContinuation = nil
                state.stopWaiters = []
            }
            return (state.runContinuation, state.stopWaiters)
        }
        run?.resume()
        waiters.forEach { $0.resume() }
    }

    /// Returns once `stop()` has been called at least once.
    func waitUntilStopped() async {
        await withCheckedContinuation { continuation in
            let alreadyStopped = state.withLock { state in
                if state.stopCount > 0 { return true }
                state.stopWaiters.append(continuation)
                return false
            }
            if alreadyStopped { continuation.resume() }
        }
    }
}

/// Returns the scripted answers in order. `nil` means no face, `.failure` throws.
/// Every face has the given contour.
final class StubFaceTracker: FaceTracker {
    private let answers: [Result<EyePositions?, TestError>]
    private let contour: [Point2D]
    private let callCount = Mutex(0)

    init(answers: [Result<EyePositions?, TestError>], contour: [Point2D] = []) {
        self.answers = answers
        self.contour = contour
    }

    func face(in frame: VideoFrame) throws -> FaceLandmarks? {
        let index = callCount.withLock { count in
            defer { count += 1 }
            return count
        }
        guard index < answers.count else { return nil }
        return try answers[index].get().map { FaceLandmarks(eyes: $0, contour: contour) }
    }
}

/// A clock that never waits. `sleep` moves its time forward and records the call.
final class FakePlaybackClock: Sendable {
    private struct State {
        var time = Duration.zero
        var sleeps: [Duration] = []
    }

    private let state = Mutex(State())

    var clock: PlaybackClock {
        PlaybackClock(
            now: { self.state.withLock { $0.time } },
            sleep: { duration in
                self.state.withLock { state in
                    state.sleeps.append(duration)
                    state.time += duration
                }
            }
        )
    }

    var sleeps: [Duration] { state.withLock { $0.sleeps } }

    /// Pretends that some work took this long.
    func advance(by duration: Duration) {
        state.withLock { $0.time += duration }
    }
}

/// Returns the given instants in order, so the measured durations are exact.
func scriptedNow(_ instants: [Duration]) -> @Sendable () -> Duration {
    let index = Mutex(0)
    return {
        index.withLock { position in
            defer { position += 1 }
            return instants[min(position, instants.count - 1)]
        }
    }
}

extension EyePositions {
    static let sample = EyePositions(left: Point2D(x: 0.4, y: 0.4), right: Point2D(x: 0.6, y: 0.4))
}
