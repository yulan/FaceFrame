//
//  VisionBenchmarkTests.swift
//  DataLayerTests
//
//  Created by Lan YU on 21/11/2026.
//

import DataLayer
import Domain
import Foundation
import Testing

/// Phase 2 tool, off by default. Runs the real `VisionFaceTracker` over a
/// recorded clip and prints the numbers that go in the README:
///
///     FACEFRAME_BENCHMARK_VIDEO=/path/to/clip.mov swift test --filter VisionBenchmark
///
/// Run it before and after each optimization, on the same clip.
@Suite(.enabled(if: ProcessInfo.processInfo.environment["FACEFRAME_BENCHMARK_VIDEO"] != nil))
struct VisionBenchmarkTests {
    @Test func processingTimePerFrame() async throws {
        let path = try #require(ProcessInfo.processInfo.environment["FACEFRAME_BENCHMARK_VIDEO"])
        let pipeline = TrackingPipeline(
            source: VideoFileFrameSource(url: URL(fileURLWithPath: path), orientation: .recorded(mirrored: true)),
            tracker: VisionFaceTracker(),
            bufferingPolicy: .unbounded
        )

        var times: [Duration] = []
        var facesFound = 0
        for try await result in pipeline.results() {
            times.append(result.processingTime)
            if result.eyes != nil { facesFound += 1 }
        }

        try #require(!times.isEmpty)
        let sorted = times.sorted()
        let average = times.reduce(.zero, +) / times.count
        let p95 = sorted[min(sorted.count - 1, sorted.count * 95 / 100)]
        print("""
        FaceFrame benchmark: \(times.count) frames, face found in \(facesFound)
          average \(average.formatted(.units(allowed: [.milliseconds], fractionalPart: .show(length: 1))))
          p95     \(p95.formatted(.units(allowed: [.milliseconds], fractionalPart: .show(length: 1))))
        """)
    }
}
