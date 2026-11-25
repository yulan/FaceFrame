//
//  TrackingMode.swift
//  FaceFrame
//
//  Created by Lan YU on 22/11/2026.
//

import Foundation

/// Where the frames come from. Decided once, at launch.
enum TrackingMode: Equatable {
    case camera
    /// Fake pupils, no picture.
    case simulated
    /// A recorded clip played in a loop.
    case replay(URL)

    /// `-simulatedTracking`: forces the simulation on a device.
    static let simulatedArgument = "-simulatedTracking"
    /// `-replayVideo /path/to/clip.mov`: replays a clip.
    static let replayArgument = "-replayVideo"

    static var isRunningInSimulator: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }

    /// A replay wins. Without one, the simulator uses the simulation: it has no camera.
    init(arguments: [String], isSimulator: Bool) {
        if let path = Self.value(after: Self.replayArgument, in: arguments) {
            self = .replay(URL(fileURLWithPath: path))
        } else if isSimulator || arguments.contains(Self.simulatedArgument) {
            self = .simulated
        } else {
            self = .camera
        }
    }

    private static func value(after argument: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: argument), arguments.indices.contains(index + 1) else {
            return nil
        }
        let value = arguments[index + 1]
        // The next argument is another option, so the path is missing.
        return value.hasPrefix("-") ? nil : value
    }
}
