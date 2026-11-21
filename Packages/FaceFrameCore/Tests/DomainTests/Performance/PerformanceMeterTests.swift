//
//  PerformanceMeterTests.swift
//  DomainTests
//
//  Created by Lan YU on 21/11/2026.
//

import Domain
import Testing

struct PerformanceMeterTests {
    @Test func noSnapshotBeforeTwoFrames() {
        var meter = PerformanceMeter()
        #expect(meter.snapshot == nil)

        meter.record(timestamp: .zero, processingTime: .milliseconds(5))

        #expect(meter.snapshot == nil)
    }

    @Test func steadyThirtyFramesPerSecond() throws {
        var meter = PerformanceMeter(windowSize: 30)
        for frame in 0..<10 {
            meter.record(timestamp: .milliseconds(frame * 100) / 3, processingTime: .milliseconds(5))
        }

        let snapshot = try #require(meter.snapshot)

        expectClose(snapshot.framesPerSecond, 30, tolerance: 0.01)
        #expect(snapshot.averageProcessingTime == .milliseconds(5))
    }

    @Test func averagesProcessingTime() throws {
        var meter = PerformanceMeter()
        meter.record(timestamp: .milliseconds(0), processingTime: .milliseconds(2))
        meter.record(timestamp: .milliseconds(100), processingTime: .milliseconds(4))
        meter.record(timestamp: .milliseconds(200), processingTime: .milliseconds(6))

        let snapshot = try #require(meter.snapshot)

        #expect(snapshot.averageProcessingTime == .milliseconds(4))
    }

    @Test func onlyTheLastFramesCount() throws {
        var meter = PerformanceMeter(windowSize: 3)
        meter.record(timestamp: .seconds(0), processingTime: .milliseconds(50))
        meter.record(timestamp: .milliseconds(1000), processingTime: .milliseconds(5))
        meter.record(timestamp: .milliseconds(1100), processingTime: .milliseconds(5))
        meter.record(timestamp: .milliseconds(1200), processingTime: .milliseconds(5))

        let snapshot = try #require(meter.snapshot)

        // The slow first frame left the window: 2 intervals in 0.2 s.
        expectClose(snapshot.framesPerSecond, 10)
        #expect(snapshot.averageProcessingTime == .milliseconds(5))
    }

    @Test func identicalTimestampsGiveNoFrameRate() {
        var meter = PerformanceMeter()
        meter.record(timestamp: .seconds(1), processingTime: .milliseconds(5))
        meter.record(timestamp: .seconds(1), processingTime: .milliseconds(5))

        #expect(meter.snapshot == nil)
    }

    @Test func resetClearsTheWindow() {
        var meter = PerformanceMeter()
        meter.record(timestamp: .seconds(0), processingTime: .milliseconds(5))
        meter.record(timestamp: .seconds(1), processingTime: .milliseconds(5))

        meter.reset()

        #expect(meter.snapshot == nil)
    }
}
