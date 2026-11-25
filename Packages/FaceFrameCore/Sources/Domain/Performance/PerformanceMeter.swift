//
//  PerformanceMeter.swift
//  Domain
//
//  Created by Lan YU on 21/11/2026.
//

import Foundation

/// Frame rate and processing time over the last `windowSize` frames.
/// Uses the frame timestamps, not the wall clock.
public struct PerformanceMeter: Sendable {
    public struct Snapshot: Equatable, Sendable {
        public var framesPerSecond: Double
        public var averageProcessingTime: Duration

        public init(framesPerSecond: Double, averageProcessingTime: Duration) {
            self.framesPerSecond = framesPerSecond
            self.averageProcessingTime = averageProcessingTime
        }
    }

    private struct Sample: Sendable {
        let timestamp: Duration
        let processingTime: Duration
    }

    public let windowSize: Int
    private var samples: [Sample] = []

    public init(windowSize: Int = 30) {
        precondition(windowSize >= 2, "a frame rate needs at least two frames")
        self.windowSize = windowSize
        samples.reserveCapacity(windowSize)
    }

    public mutating func record(timestamp: Duration, processingTime: Duration) {
        if samples.count == windowSize {
            samples.removeFirst()
        }
        samples.append(Sample(timestamp: timestamp, processingTime: processingTime))
    }

    /// `nil` until two frames with increasing timestamps have been recorded.
    public var snapshot: Snapshot? {
        guard let first = samples.first, let last = samples.last, samples.count >= 2 else { return nil }
        let elapsed = last.timestamp - first.timestamp
        guard elapsed > .zero else { return nil }
        let total = samples.reduce(Duration.zero) { $0 + $1.processingTime }
        return Snapshot(
            framesPerSecond: Double(samples.count - 1) / (elapsed / .seconds(1)),
            averageProcessingTime: total / samples.count
        )
    }

    public mutating func reset() {
        samples.removeAll(keepingCapacity: true)
    }
}
