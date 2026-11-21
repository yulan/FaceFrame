//
//  TrackingModeTests.swift
//  FaceFrameTests
//
//  Created by Lan YU on 22/11/2026.
//

@testable import FaceFrame
import Foundation
import Testing

struct TrackingModeTests {
    private static let clip = "/tmp/face.mov"

    @Test func aDeviceUsesTheCamera() {
        #expect(TrackingMode(arguments: ["FaceFrame"], isSimulator: false) == .camera)
    }

    /// The simulator has no camera.
    @Test func theSimulatorSimulates() {
        #expect(TrackingMode(arguments: ["FaceFrame"], isSimulator: true) == .simulated)
    }

    @Test func theSimulationCanBeForcedOnADevice() {
        #expect(TrackingMode(arguments: ["FaceFrame", "-simulatedTracking"], isSimulator: false) == .simulated)
    }

    @Test(arguments: [true, false])
    func aReplayWinsOverEverythingElse(isSimulator: Bool) {
        let mode = TrackingMode(
            arguments: ["FaceFrame", "-simulatedTracking", "-replayVideo", Self.clip],
            isSimulator: isSimulator
        )

        #expect(mode == .replay(URL(fileURLWithPath: Self.clip)))
    }

    @Test(arguments: [
        ["FaceFrame", "-replayVideo"],
        ["FaceFrame", "-replayVideo", "-simulatedTracking"],
    ])
    func aReplayWithoutAPathIsIgnored(arguments: [String]) {
        #expect(TrackingMode(arguments: arguments, isSimulator: true) == .simulated)
    }
}
