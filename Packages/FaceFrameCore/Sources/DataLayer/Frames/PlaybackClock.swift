//
//  PlaybackClock.swift
//  DataLayer
//
//  Created by Lan YU on 22/11/2026.
//

import Foundation

/// Time and sleep for a replay. Tests use a fake one.
public struct PlaybackClock: Sendable {
    public var now: @Sendable () -> Duration
    /// Blocks the calling thread.
    public var sleep: @Sendable (Duration) -> Void

    public init(now: @escaping @Sendable () -> Duration, sleep: @escaping @Sendable (Duration) -> Void) {
        self.now = now
        self.sleep = sleep
    }

    /// The real clock. `sleep` blocks: only use it on the source's queue.
    public static var continuous: PlaybackClock {
        let origin = ContinuousClock.now
        return PlaybackClock(
            now: { ContinuousClock.now - origin },
            sleep: { Thread.sleep(forTimeInterval: $0 / .seconds(1)) }
        )
    }
}
