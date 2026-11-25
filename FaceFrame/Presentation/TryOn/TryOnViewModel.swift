//
//  TryOnViewModel.swift
//  FaceFrame
//
//  Created by Lan YU on 21/11/2026.
//

import Domain
import Foundation
import Observation

@MainActor
@Observable
final class TryOnViewModel {
    enum State: Equatable {
        case starting
        case running
        case stopped
        case failed(TrackingError)
    }

    private(set) var state: State = .starting
    /// Smoothed pupils, for the glasses.
    private(set) var eyes: EyePositions?
    /// Pupils as detected, for the dots.
    private(set) var rawEyes: EyePositions?
    /// Jaw line as detected.
    private(set) var rawContour: [Point2D] = []
    private(set) var imageSize: Size2D?
    private(set) var performance: PerformanceMeter.Snapshot?
    /// Changes on retry. The view then restarts its `.task(id:)`.
    private(set) var runID = 0
    var showsLandmarks = false
    let mode: TrackingMode

    private let session: any FaceTrackingSession
    private let calculator: GlassesPlacementCalculator
    private var smoother: ExponentialSmoother
    private var meter = PerformanceMeter()

    init(
        session: any FaceTrackingSession,
        mode: TrackingMode = .camera,
        smoothing alpha: Double = 0.35,
        calculator: GlassesPlacementCalculator = GlassesPlacementCalculator()
    ) {
        self.session = session
        self.mode = mode
        self.smoother = ExponentialSmoother(alpha: alpha)
        self.calculator = calculator
    }

    /// Runs until the session ends or the calling task is cancelled.
    func run() async {
        state = .starting
        clearTracking()
        do {
            for try await result in session.results() {
                if state != .running { state = .running }
                apply(result)
            }
            state = .stopped
        } catch let error as TrackingError {
            Log.ui.error("Tracking failed: \(String(describing: error), privacy: .public)")
            state = .failed(error)
        } catch {
            Log.ui.error("Tracking failed: \(error.localizedDescription, privacy: .public)")
            state = .failed(.sourceFailed)
        }
    }

    func retry() {
        runID += 1
    }

    /// `nil` for the camera.
    var sourceLabel: LocalizedStringResource? {
        switch mode {
        case .camera: nil
        case .simulated: L10n.TryOn.simulated
        case .replay: L10n.TryOn.replay
        }
    }

    /// Shown while no face is found. A replay can't "look at the camera".
    var noFaceHint: LocalizedStringResource? {
        guard state == .running, rawEyes == nil else { return nil }
        return mode == .camera ? L10n.TryOn.lookAtCamera : L10n.TryOn.noFace
    }

    var performanceText: LocalizedStringResource? {
        guard let performance else { return nil }
        let fps = performance.framesPerSecond.formatted(.number.precision(.fractionLength(0)))
        let milliseconds = (performance.averageProcessingTime / .milliseconds(1))
            .formatted(.number.precision(.fractionLength(1)))
        return L10n.TryOn.performance(fps: fps, milliseconds: milliseconds)
    }

    func glassesPlacement(in viewSize: Size2D) -> GlassesPlacement? {
        guard let eyes, let mapping = mapping(for: viewSize) else { return nil }
        return calculator.placement(left: mapping.viewPoint(for: eyes.left), right: mapping.viewPoint(for: eyes.right))
    }

    func landmarkPoints(in viewSize: Size2D) -> [Point2D] {
        guard let rawEyes, let mapping = mapping(for: viewSize) else { return [] }
        return [mapping.viewPoint(for: rawEyes.left), mapping.viewPoint(for: rawEyes.right)]
    }

    func contourPoints(in viewSize: Size2D) -> [Point2D] {
        guard let mapping = mapping(for: viewSize) else { return [] }
        return rawContour.map(mapping.viewPoint(for:))
    }

    private func mapping(for viewSize: Size2D) -> AspectFillMapping? {
        imageSize.map { AspectFillMapping(imageSize: $0, viewSize: viewSize) }
    }

    private func apply(_ result: TrackingResult) {
        meter.record(timestamp: result.timestamp, processingTime: result.processingTime)
        performance = meter.snapshot
        imageSize = result.imageSize
        rawEyes = result.eyes
        rawContour = result.face?.contour ?? []
        if let detected = result.eyes {
            eyes = smoother.smooth(detected)
        } else {
            eyes = nil
            smoother.reset()
        }
    }

    private func clearTracking() {
        eyes = nil
        rawEyes = nil
        rawContour = []
        imageSize = nil
        performance = nil
        smoother.reset()
        meter.reset()
    }
}
