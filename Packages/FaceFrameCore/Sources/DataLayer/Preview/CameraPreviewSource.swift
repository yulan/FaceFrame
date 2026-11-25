//
//  CameraPreviewSource.swift
//  DataLayer
//
//  Created by Lan YU on 23/11/2026.
//

import AVFoundation

/// Connects a preview layer to the capture session.
/// The view doesn't get the session itself. Same idea as `PreviewSource` in AVCam.
public protocol CameraPreviewSource: Sendable {
    @MainActor func connect(to layer: AVCaptureVideoPreviewLayer)
}

struct SessionPreviewSource: CameraPreviewSource {
    // AVCaptureSession isn't Sendable. Safe here: this only gives the session
    // to a preview layer on the main actor. AVCam does the same.
    nonisolated(unsafe) let session: AVCaptureSession

    @MainActor func connect(to layer: AVCaptureVideoPreviewLayer) {
        layer.session = session
    }
}
