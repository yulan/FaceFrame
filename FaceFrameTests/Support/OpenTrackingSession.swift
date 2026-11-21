//
//  OpenTrackingSession.swift
//  FaceFrameTests
//
//  Created by Lan YU on 22/11/2026.
//

import Domain
import Synchronization

/// Emits one result and then stays open, like a camera that keeps running.
/// For what the view model shows *while* tracking.
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
            // The consumer asks for a second result: it has finished with the first.
            appliedContinuation.yield()
            // Nothing more comes; this returns when the consumer is cancelled.
            for await _ in AsyncStream<Never>(Never.self, { _ in }) {}
            return nil
        }
    }

    /// Returns once the consumer has applied the first result.
    func firstResultApplied() async {
        for await _ in applied { break }
    }
}
