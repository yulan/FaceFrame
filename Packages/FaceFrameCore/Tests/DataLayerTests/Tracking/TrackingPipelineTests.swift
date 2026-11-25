//
//  TrackingPipelineTests.swift
//  DataLayerTests
//
//  Created by Lan YU on 21/11/2026.
//

import DataLayer
import Domain
import Testing

struct TrackingPipelineTests {
    private func collect(_ session: some FaceTrackingSession) async throws -> [TrackingResult] {
        var results: [TrackingResult] = []
        for try await result in session.results() {
            results.append(result)
        }
        return results
    }

    @Test func publishesOneResultPerFrame() async throws {
        let pipeline = TrackingPipeline(
            source: FakeFrameSource(frameCount: 3),
            tracker: StubFaceTracker(answers: [.success(.sample), .success(nil), .success(.sample)]),
            bufferingPolicy: .unbounded
        )

        let results = try await collect(pipeline)

        #expect(results.map(\.eyes) == [.sample, nil, .sample])
        #expect(results.map(\.timestamp) == [.zero, .milliseconds(100), .milliseconds(200)])
    }

    @Test func theOutlineOfTheFaceReachesTheResult() async throws {
        let contour = [Point2D(x: 0.3, y: 0.5), Point2D(x: 0.5, y: 0.7), Point2D(x: 0.7, y: 0.5)]
        let pipeline = TrackingPipeline(
            source: FakeFrameSource(frameCount: 2),
            tracker: StubFaceTracker(answers: [.success(.sample), .success(nil)], contour: contour),
            bufferingPolicy: .unbounded
        )

        let results = try await collect(pipeline)

        #expect(results.map(\.face) == [FaceLandmarks(eyes: .sample, contour: contour), nil])
    }

    @Test func reportsTheDisplayedImageSize() async throws {
        // A 4 x 3 buffer with .leftMirrored is 3 x 4 on screen.
        let pipeline = TrackingPipeline(
            source: FakeFrameSource(frameCount: 1, orientation: .leftMirrored),
            tracker: StubFaceTracker(answers: [.success(.sample)]),
            bufferingPolicy: .unbounded
        )

        let results = try await collect(pipeline)

        #expect(results.first?.imageSize == Size2D(width: 3, height: 4))
    }

    @Test func measuresDetectionTimeWithTheInjectedClock() async throws {
        let pipeline = TrackingPipeline(
            source: FakeFrameSource(frameCount: 2),
            tracker: StubFaceTracker(answers: [.success(.sample), .success(.sample)]),
            now: scriptedNow([.zero, .milliseconds(7), .milliseconds(100), .milliseconds(103)]),
            bufferingPolicy: .unbounded
        )

        let results = try await collect(pipeline)

        #expect(results.map(\.processingTime) == [.milliseconds(7), .milliseconds(3)])
    }

    @Test func aFailedDetectionCountsAsNoFaceAndTheSessionGoesOn() async throws {
        let pipeline = TrackingPipeline(
            source: FakeFrameSource(frameCount: 3),
            tracker: StubFaceTracker(answers: [.success(.sample), .failure(.detection), .success(.sample)]),
            bufferingPolicy: .unbounded
        )

        let results = try await collect(pipeline)

        #expect(results.map(\.eyes) == [.sample, nil, .sample])
    }

    @Test func aSourceErrorEndsTheStream() async throws {
        let pipeline = TrackingPipeline(
            source: FakeFrameSource(frameCount: 0, failure: .cameraAccessDenied),
            tracker: StubFaceTracker(answers: [])
        )

        await #expect(throws: TrackingError.cameraAccessDenied) {
            _ = try await collect(pipeline)
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func leavingTheLoopStopsTheSource() async throws {
        let source = FakeFrameSource(frameCount: 1, waitsForStop: true)
        let pipeline = TrackingPipeline(
            source: source,
            tracker: StubFaceTracker(answers: [.success(.sample)])
        )

        for try await _ in pipeline.results() {
            break
        }
        await source.waitUntilStopped()

        #expect(source.stopCount >= 1)
    }
}
