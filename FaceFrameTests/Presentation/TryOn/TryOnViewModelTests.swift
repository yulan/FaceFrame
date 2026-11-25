//
//  TryOnViewModelTests.swift
//  FaceFrameTests
//
//  Created by Lan YU on 21/11/2026.
//

import Domain
@testable import FaceFrame
import Foundation
import Testing

@MainActor
struct TryOnViewModelTests {
    @Test func publishesTheDetectedFace() async {
        let viewModel = TryOnViewModel(session: FakeTrackingSession(scripted: [.frame(.centered)]))

        await viewModel.run()

        #expect(viewModel.eyes == .centered)
        #expect(viewModel.rawEyes == .centered)
        #expect(viewModel.imageSize == Size2D(width: 100, height: 100))
        #expect(viewModel.state == .stopped)
    }

    @Test func aLostFaceHidesTheGlassesAndTheDots() async {
        let viewModel = TryOnViewModel(session: FakeTrackingSession(scripted: [
            .frame(.centered, contour: Self.contour),
            .frame(nil),
        ]))

        await viewModel.run()

        #expect(viewModel.eyes == nil)
        #expect(viewModel.glassesPlacement(in: Size2D(width: 200, height: 200)) == nil)
        #expect(viewModel.landmarkPoints(in: Size2D(width: 200, height: 200)).isEmpty)
        #expect(viewModel.contourPoints(in: Size2D(width: 200, height: 200)).isEmpty)
    }

    // MARK: - Outline of the face

    private static let contour = [Point2D(x: 0.25, y: 0.5), Point2D(x: 0.5, y: 0.75), Point2D(x: 0.75, y: 0.5)]

    @Test func theOutlineOfTheFaceIsMappedOntoTheView() async {
        let viewModel = TryOnViewModel(session: FakeTrackingSession(scripted: [.frame(.centered, contour: Self.contour)]))

        await viewModel.run()

        // 100 x 100 image in a 200 x 200 view: every coordinate is doubled.
        #expect(viewModel.contourPoints(in: Size2D(width: 200, height: 200)) == [
            Point2D(x: 50, y: 100),
            Point2D(x: 100, y: 150),
            Point2D(x: 150, y: 100),
        ])
    }

    @Test func aFaceWithoutAnOutlineDrawsNoLine() async {
        let viewModel = TryOnViewModel(session: FakeTrackingSession(scripted: [.frame(.centered)]))

        await viewModel.run()

        #expect(viewModel.contourPoints(in: Size2D(width: 200, height: 200)).isEmpty)
    }

    @Test func aNewFaceDoesNotGlideFromTheLostOne() async {
        let viewModel = TryOnViewModel(
            session: FakeTrackingSession(scripted: [.frame(.centered), .frame(nil), .frame(.movedRight)]),
            smoothing: 0.2
        )

        await viewModel.run()

        #expect(viewModel.eyes == .movedRight)
    }

    @Test func showsTheFailure() async {
        let viewModel = TryOnViewModel(session: FakeTrackingSession(scripted: [], failure: .cameraAccessDenied))

        await viewModel.run()

        #expect(viewModel.state == .failed(.cameraAccessDenied))
    }

    @Test func measuresPerformanceFromTheFrames() async throws {
        let viewModel = TryOnViewModel(session: FakeTrackingSession(scripted: [
            .frame(.centered, at: .zero, processing: .milliseconds(2)),
            .frame(.centered, at: .milliseconds(100), processing: .milliseconds(6)),
        ]))

        await viewModel.run()

        let performance = try #require(viewModel.performance)
        #expect(abs(performance.framesPerSecond - 10) < 0.001)
        #expect(performance.averageProcessingTime == .milliseconds(4))
        #expect(viewModel.performanceText != nil)
    }

    // MARK: - Source of the frames

    @Test func theCameraNeedsNoLabel() {
        let viewModel = TryOnViewModel(session: FakeTrackingSession(scripted: []))

        #expect(viewModel.sourceLabel == nil)
    }

    @Test func aReplayAndTheSimulationSayWhatTheyAre() {
        let replay = TryOnViewModel(session: FakeTrackingSession(scripted: []), mode: .replay(URL(fileURLWithPath: "/tmp/face.mov")))
        let simulated = TryOnViewModel(session: FakeTrackingSession(scripted: []), mode: .simulated)

        #expect(replay.sourceLabel?.key == L10n.TryOn.replay.key)
        #expect(simulated.sourceLabel?.key == L10n.TryOn.simulated.key)
    }

    // MARK: - No face

    /// Returns the hint shown after the first result, on a session that stays open.
    private func hintWhileRunning(first: TrackingResult, mode: TrackingMode = .camera) async -> LocalizedStringResource? {
        let session = OpenTrackingSession(first: first)
        let viewModel = TryOnViewModel(session: session, mode: mode)
        let task = Task { await viewModel.run() }
        await session.firstResultApplied()
        let hint = viewModel.noFaceHint
        task.cancel()
        await task.value
        return hint
    }

    @Test func noHintWhileAFaceIsFound() async {
        #expect(await hintWhileRunning(first: .frame(.centered)) == nil)
    }

    @Test func theCameraAsksToLookAtIt() async {
        let hint = await hintWhileRunning(first: .frame(nil))

        #expect(hint?.key == L10n.TryOn.lookAtCamera.key)
    }

    /// A recorded clip can't look at the camera.
    @Test func aReplayOnlySaysThatNoFaceWasFound() async {
        let hint = await hintWhileRunning(first: .frame(nil), mode: .replay(URL(fileURLWithPath: "/tmp/face.mov")))

        #expect(hint?.key == L10n.TryOn.noFace.key)
    }

    @Test func retryRestartsTheTask() {
        let viewModel = TryOnViewModel(session: FakeTrackingSession(scripted: []))

        viewModel.retry()

        #expect(viewModel.runID == 1)
    }

    /// Mapping and placement together.
    @Test func placesTheGlassesBetweenThePupils() async throws {
        let viewModel = TryOnViewModel(session: FakeTrackingSession(scripted: [.frame(.centered)]))
        await viewModel.run()

        // 100 x 100 image in a 200 x 200 view: pupils at (80, 100) and (120, 100).
        let placement = try #require(viewModel.glassesPlacement(in: Size2D(width: 200, height: 200)))

        #expect(abs(placement.center.x - 100) < 0.001 && abs(placement.center.y - 100) < 0.001)
        #expect(abs(placement.width - 40 * 2.1) < 0.001)
        #expect(abs(placement.angle) < 0.001)
    }
}
