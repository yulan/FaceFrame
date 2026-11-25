//
//  TrackingError.swift
//  Domain
//
//  Created by Lan YU on 21/11/2026.
//

import Foundation

/// The only errors the UI sees. DataLayer maps AVFoundation and Vision errors to these.
public enum TrackingError: Error, Equatable, Sendable {
    /// Refused or restricted.
    case cameraAccessDenied
    /// No camera, or the session didn't start.
    case cameraUnavailable
    /// The source failed while running.
    case sourceFailed
}
