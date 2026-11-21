//
//  CameraFrameSource.swift
//  DataLayer
//
//  Created by Lan YU on 21/11/2026.
//

import AVFoundation
import Domain

/// Front-camera frames for the pipeline.
///
/// TODO — Phase 1, step 5. What it must do:
///
/// 1. Ask for camera access with `AVCaptureDevice.requestAccess(for: .video)`.
///    A refusal (or `.restricted`) becomes `TrackingError.cameraAccessDenied`.
/// 2. Configure an `AVCaptureSession` on a private serial queue: front
///    wide-angle camera, a preset (start with `.hd1280x720`), and an
///    `AVCaptureVideoDataOutput` with `alwaysDiscardsLateVideoFrames = true`
///    whose delegate runs on that same queue. No device → `.cameraUnavailable`.
/// 3. In the delegate, wrap the sample buffer in a `VideoFrame` (orientation
///    `.leftMirrored` for the front camera in portrait) and call `onFrame`
///    synchronously. The `CMSampleBuffer` must not escape the callback.
/// 4. `run` returns only after `stop()`: keep a continuation and resume it
///    in `stop()`. `startRunning()` blocks: never call it on the main thread.
/// 5. The preview (`CameraPreviewView` in the app) needs the same session, so
///    the overlay and the picture share one geometry. Decide how to expose it.
///
/// Swift 6: `AVCaptureSession` is not `Sendable`. Apple's AVCam sample code
/// (updated in 2024) wraps it in an actor whose executor is the session
/// queue. Read it before choosing, and write the reason for the choice here.
public final class CameraFrameSource: FrameSource {
    public init() {}

    public func run(onFrame: @escaping @Sendable (VideoFrame) -> Void) async throws {
        // TODO: replace with the capture session described above.
        throw TrackingError.cameraUnavailable
    }

    public func stop() {
        // TODO
    }
}
