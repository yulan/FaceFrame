//
//  TrackingError.swift
//  Domain
//
//  Created by Lan YU on 21/11/2026.
//

import Foundation

/// The only errors the Presentation layer ever sees. DataLayer maps
/// AVFoundation and Vision errors to one of these.
public enum TrackingError: Error, Equatable, Sendable {
    /// The user refused camera access (or it is restricted).
    case cameraAccessDenied
    /// No usable camera: simulator, or the capture session couldn't start.
    case cameraUnavailable
    /// The frame source failed while running (unreadable file, session error).
    case sourceFailed
}
