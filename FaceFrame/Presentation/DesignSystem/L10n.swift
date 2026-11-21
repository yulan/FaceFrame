//
//  L10n.swift
//  FaceFrame
//
//  Created by Lan YU on 21/11/2026.
//

import Foundation

/// Every user-facing string, keyed into `Localizable.xcstrings` (en, fr).
enum L10n {
    enum TryOn {
        static func performance(fps: String, milliseconds: String) -> LocalizedStringResource {
            LocalizedStringResource("tryOn.performance", defaultValue: "\(fps) fps · \(milliseconds) ms")
        }
        static let simulated = LocalizedStringResource("tryOn.simulated", defaultValue: "Simulation")
        static let replay = LocalizedStringResource("tryOn.replay", defaultValue: "Replay")
        static let lookAtCamera = LocalizedStringResource("tryOn.lookAtCamera", defaultValue: "Look at the camera")
        static let noFace = LocalizedStringResource("tryOn.noFace", defaultValue: "No face detected")
        static let showLandmarks = LocalizedStringResource("tryOn.landmarks.show", defaultValue: "Show landmarks")
        static let hideLandmarks = LocalizedStringResource("tryOn.landmarks.hide", defaultValue: "Hide landmarks")
        static let openSettings = LocalizedStringResource("tryOn.openSettings", defaultValue: "Open Settings")
        static let retry = LocalizedStringResource("tryOn.retry", defaultValue: "Try Again")

        enum Failure {
            static let deniedTitle = LocalizedStringResource("tryOn.failure.denied.title", defaultValue: "Camera access is off")
            static let deniedMessage = LocalizedStringResource(
                "tryOn.failure.denied.message",
                defaultValue: "Allow camera access in Settings to try on glasses."
            )
            static let unavailableTitle = LocalizedStringResource("tryOn.failure.unavailable.title", defaultValue: "Camera unavailable")
            static let unavailableMessage = LocalizedStringResource(
                "tryOn.failure.unavailable.message",
                defaultValue: "The camera can't be used right now."
            )
            static let failedTitle = LocalizedStringResource("tryOn.failure.failed.title", defaultValue: "Video stopped")
            static let failedMessage = LocalizedStringResource(
                "tryOn.failure.failed.message",
                defaultValue: "Something went wrong with the video."
            )
        }
    }
}
