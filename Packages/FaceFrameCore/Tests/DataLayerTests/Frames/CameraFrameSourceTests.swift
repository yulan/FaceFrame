//
//  CameraFrameSourceTests.swift
//  DataLayerTests
//
//  Created by Lan YU on 23/11/2026.
//

import DataLayer
import Domain
import Synchronization
import Testing

/// What can be tested without a camera. The capture is checked on a device.
struct CameraFrameSourceTests {
    /// Replaces the system alert. The test decides when it is answered.
    private final class AccessQuestion: Sendable {
        private struct State {
            var answer: CheckedContinuation<Bool, Never>?
            var waiters: [CheckedContinuation<Void, Never>] = []
        }

        private let state = Mutex(State())

        /// Called by the source. Returns when the test has answered.
        func ask() async -> Bool {
            await withCheckedContinuation { continuation in
                let waiters = state.withLock { state in
                    state.answer = continuation
                    defer { state.waiters = [] }
                    return state.waiters
                }
                waiters.forEach { $0.resume() }
            }
        }

        /// Returns once the source is waiting for the answer.
        func waitUntilAsked() async {
            await withCheckedContinuation { continuation in
                let isAsked = state.withLock { state in
                    if state.answer != nil { return true }
                    state.waiters.append(continuation)
                    return false
                }
                if isAsked { continuation.resume() }
            }
        }

        func answer(_ allowed: Bool) {
            let answer = state.withLock { state in
                defer { state.answer = nil }
                return state.answer
            }
            answer?.resume(returning: allowed)
        }
    }

    // MARK: - Access

    @Test func refusedAccessFailsWithCameraAccessDenied() async {
        let lookups = Mutex(0)
        let source = CameraFrameSource(
            requestAccess: { false },
            frontCamera: {
                lookups.withLock { $0 += 1 }
                return nil
            }
        )

        await #expect(throws: TrackingError.cameraAccessDenied) {
            try await source.run { _ in }
        }
        #expect(lookups.withLock { $0 } == 0)
    }

    /// For example in the simulator.
    @Test func withoutACameraItFailsWithCameraUnavailable() async {
        let source = CameraFrameSource(requestAccess: { true }, frontCamera: { nil })

        await #expect(throws: TrackingError.cameraUnavailable) {
            try await source.run { _ in }
        }
    }

    // MARK: - Stopping

    /// The alert stays open until the user answers.
    @Test(.timeLimit(.minutes(1)))
    func stoppingWhileTheAccessAlertIsOpenEndsTheRunWithoutTheCamera() async throws {
        let question = AccessQuestion()
        let lookups = Mutex(0)
        let source = CameraFrameSource(
            requestAccess: { await question.ask() },
            frontCamera: {
                lookups.withLock { $0 += 1 }
                return nil
            }
        )

        let task = Task { try await source.run { _ in } }
        await question.waitUntilAsked()
        source.stop()
        question.answer(true)

        try await task.value
        #expect(lookups.withLock { $0 } == 0)
    }

    @Test(.timeLimit(.minutes(1)))
    func cancellingTheTaskWhileTheAccessAlertIsOpenEndsTheRun() async throws {
        let question = AccessQuestion()
        let lookups = Mutex(0)
        let source = CameraFrameSource(
            requestAccess: { await question.ask() },
            frontCamera: {
                lookups.withLock { $0 += 1 }
                return nil
            }
        )

        let task = Task { try await source.run { _ in } }
        await question.waitUntilAsked()
        task.cancel()
        question.answer(true)

        // Without the cancellation handler the run would go on to the camera.
        try await task.value
        #expect(lookups.withLock { $0 } == 0)
    }

    /// "Try Again" runs the same source a second time.
    @Test(.timeLimit(.minutes(1)))
    func aStoppedSourceCanRunAgain() async throws {
        let question = AccessQuestion()
        let source = CameraFrameSource(requestAccess: { await question.ask() }, frontCamera: { nil })

        let first = Task { try await source.run { _ in } }
        await question.waitUntilAsked()
        source.stop()
        question.answer(true)
        try await first.value

        let second = Task { try await source.run { _ in } }
        await question.waitUntilAsked()
        question.answer(true)

        // The second run is not stopped: it goes on and looks for the camera.
        await #expect(throws: TrackingError.cameraUnavailable) {
            try await second.value
        }
    }
}
