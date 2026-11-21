//
//  PlaybackClock.swift
//  DataLayer
//
//  Created by Lan YU on 22/11/2026.
//

import Foundation

/// The time and the wait used to pace a replay. Tests inject a fake one, so
/// they never depend on real time.
public struct PlaybackClock: Sendable {
    /// A monotonic time.
    public var now: @Sendable () -> Duration
    /// Blocks the calling thread for the given duration.
    public var sleep: @Sendable (Duration) -> Void

    public init(now: @escaping @Sendable () -> Duration, sleep: @escaping @Sendable (Duration) -> Void) {
        self.now = now
        self.sleep = sleep
    }

    /// The real clock. `sleep` blocks, which is fine on the private queue of a
    /// frame source and nowhere else.
    public static var continuous: PlaybackClock {
        let origin = ContinuousClock.now
        return PlaybackClock(
            now: { ContinuousClock.now - origin },
            sleep: { Thread.sleep(forTimeInterval: $0 / .seconds(1)) }
        )
    }
}
