//
//  OpenTrackingSession.swift
//  FaceFrameTests
//
//  Created by Lan YU on 22/11/2026.
//

import Domain
import Synchronization

/// Sends one result and stays open, like a camera.
final class OpenTrackingSession: FaceTrackingSession {
    private let first: TrackingResult
    private let (applied, appliedContinuation) = AsyncStream.makeStream(of: Void.self)

    init(first: TrackingResult) {
        self.first = first
    }

    func results() -> AsyncThrowingStream<TrackingResult, any Error> {
        let pulls = Mutex(0)
        return AsyncThrowingStream { [first, appliedContinuation] in
            let pull = pulls.withLock { count in
                count += 1
                return count
            }
            if pull == 1 { return first }
            // A second result is asked: the first one has been applied.
            appliedContinuation.yield()
            // Nothing more. Returns when the consumer is cancelled.
            for await _ in AsyncStream<Never>(Never.self, { _ in }) {}
            return nil
        }
    }

    /// Returns once the consumer has applied the first result.
    func firstResultApplied() async {
        for await _ in applied { break }
    }
}
