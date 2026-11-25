//
//  CameraFrameSource.swift
//  DataLayer
//
//  Created by Lan YU on 21/11/2026.
//

import AVFoundation
import Domain

/// Front camera frames.
/// An actor on the session queue, like `CaptureService` in AVCam:
/// `startRunning()` and `stopRunning()` block, so they stay off the main
/// thread and off the cooperative pool. Frames come on a second queue.
/// A new `run` ends the previous one.
/// Not handled: session runtime errors, and an iPad with the front camera
/// on the long edge (needs `AVCaptureDevice.RotationCoordinator`).
public actor CameraFrameSource: FrameSource {
    private let sessionQueue = DispatchSerialQueue(label: "YULan.FaceFrame.CameraFrameSource.session")
    private let frameQueue = DispatchQueue(label: "YULan.FaceFrame.CameraFrameSource.frames", qos: .userInitiated)

    public nonisolated var unownedExecutor: UnownedSerialExecutor {
        sessionQueue.asUnownedSerialExecutor()
    }

    /// Lets a preview layer show this session.
    public nonisolated let previewSource: any CameraPreviewSource

    private let session: AVCaptureSession
    private let output = AVCaptureVideoDataOutput()
    private let requestAccess: @Sendable () async -> Bool
    private let frontCamera: @Sendable () -> AVCaptureDevice?

    private var isConfigured = false
    /// Kept alive while it receives frames.
    private var delegate: FrameDelegate?
    /// `stop()` ends the runs started so far. A later `run` can start again.
    private var started = 0
    private var stopped = 0
    /// Resumes the run that is capturing.
    private var capturing: CheckedContinuation<Void, Never>?

    /// `requestAccess`: `true` when the user allows the camera.
    /// `frontCamera`: `nil` when there is none. Tests replace both.
    public init(
        requestAccess: @escaping @Sendable () async -> Bool = CameraFrameSource.requestSystemAccess,
        frontCamera: @escaping @Sendable () -> AVCaptureDevice? = CameraFrameSource.systemFrontCamera
    ) {
        let session = AVCaptureSession()
        self.session = session
        self.previewSource = SessionPreviewSource(session: session)
        self.requestAccess = requestAccess
        self.frontCamera = frontCamera
    }

    public func run(onFrame: @escaping @Sendable (VideoFrame) -> Void) async throws {
        endRuns()
        started += 1
        let run = started
        // Register the run first, so a task that is already cancelled stops it too.
        try await withTaskCancellationHandler {
            try await capture(run: run, onFrame: onFrame)
        } onCancel: {
            stop()
        }
    }

    public nonisolated func stop() {
        // The session queue is the actor's executor. Queued now, so this stop
        // doesn't end a run that starts after the call.
        sessionQueue.async {
            self.assumeIsolated { $0.endRuns() }
        }
    }

    // MARK: - System

    /// Asks the first time. After that, returns the user's choice.
    public static func requestSystemAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            true
        case .notDetermined:
            await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            false
        @unknown default:
            false
        }
    }

    public static func systemFrontCamera() -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
    }

    // MARK: - Capture

    private func capture(run: Int, onFrame: @escaping @Sendable (VideoFrame) -> Void) async throws {
        guard await requestAccess() else { throw TrackingError.cameraAccessDenied }
        // The alert can stay open a long time. The run may be stopped meanwhile.
        guard stopped < run else { return }
        try configureSession()

        let delegate = FrameDelegate(onFrame: onFrame)
        self.delegate = delegate
        output.setSampleBufferDelegate(delegate, queue: frameQueue)
        session.startRunning()
        guard session.isRunning else {
            Log.frames.error("The capture session didn't start")
            stopSession()
            throw TrackingError.cameraUnavailable
        }
        // `endRuns()` stops the session, then resumes here.
        await withCheckedContinuation { capturing = $0 }
    }

    /// Ends the capture and every run started so far.
    private func endRuns() {
        stopped = started
        guard let capturing else { return }
        self.capturing = nil
        stopSession()
        capturing.resume()
    }

    /// Returns when no more frame will be delivered.
    private func stopSession() {
        session.stopRunning()
        output.setSampleBufferDelegate(nil, queue: nil)
        delegate = nil
        // Wait for a frame that is still on the frame queue.
        frameQueue.sync {}
    }

    /// Front camera, 720p, late frames dropped. Done once.
    private func configureSession() throws {
        guard !isConfigured else { return }
        guard let camera = frontCamera() else {
            Log.frames.error("No front camera")
            throw TrackingError.cameraUnavailable
        }
        let input: AVCaptureDeviceInput
        do {
            input = try AVCaptureDeviceInput(device: camera)
        } catch {
            Log.frames.error("Cannot open the camera: \(error.localizedDescription, privacy: .public)")
            throw TrackingError.cameraUnavailable
        }

        session.beginConfiguration()
        defer { session.commitConfiguration() }
        guard session.canAddInput(input), session.canAddOutput(output) else {
            Log.frames.error("The capture session refused the camera or the video output")
            throw TrackingError.cameraUnavailable
        }
        session.addInput(input)
        if session.canSetSessionPreset(.hd1280x720) {
            session.sessionPreset = .hd1280x720
        }
        // Drop a frame that arrives while the previous one is processed.
        output.alwaysDiscardsLateVideoFrames = true
        session.addOutput(output)
        keepSensorPicture()
        isConfigured = true
    }

    /// Asks for the sensor picture: not rotated, not mirrored.
    /// The defaults are not the same on every device (180 degrees on some iPads),
    /// and the orientation given to Vision must match the buffer.
    private func keepSensorPicture() {
        guard let connection = output.connection(with: .video) else { return }
        if connection.isVideoRotationAngleSupported(0) {
            connection.videoRotationAngle = 0
        }
        // Not available on macOS. The Mac only builds this for the package tests.
        #if os(iOS)
        if connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = false
        }
        #endif
    }
}

/// Receives the frames on the frame queue.
private final class FrameDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let onFrame: @Sendable (VideoFrame) -> Void

    init(onFrame: @escaping @Sendable (VideoFrame) -> Void) {
        self.onFrame = onFrame
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        // Called synchronously. The buffer goes back to the pool when this returns.
        onFrame(VideoFrame(
            pixelBuffer: pixelBuffer,
            timestamp: .seconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds),
            // The buffer is the sensor's landscape picture. In portrait,
            // `.leftMirrored` turns it upright and mirrors it like the preview.
            // Same value as in Apple's face tracking sample.
            orientation: .leftMirrored
        ))
    }
}
