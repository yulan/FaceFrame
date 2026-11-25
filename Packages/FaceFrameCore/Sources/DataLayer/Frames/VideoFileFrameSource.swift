//
//  VideoFileFrameSource.swift
//  DataLayer
//
//  Created by Lan YU on 21/11/2026.
//

import AVFoundation
import Domain
import Synchronization

/// Plays a video file through the same pipeline as the camera.
/// Used by the benchmark (as fast as possible) and by the replay (real time).
public final class VideoFileFrameSource: FrameSource {
    public enum Orientation: Sendable {
        /// The same orientation for every frame.
        case fixed(CGImagePropertyOrientation)
        /// The rotation stored in the file. `mirrored` also flips left and right.
        case recorded(mirrored: Bool)
    }

    public enum Pacing: Sendable {
        /// As fast as the frames can be decoded.
        case asFastAsPossible
        /// Each frame at its own time. A late frame is dropped, like the camera does.
        case realTime
    }

    /// `stop()` ends the runs started so far. A later `run` can start again.
    private struct Runs {
        var started = 0
        var stopped = 0
    }

    private struct Clip {
        let orientation: CGImagePropertyOrientation
        /// `nil` when the file doesn't give it.
        let frameInterval: Duration?
        let duration: Duration
    }

    private let url: URL
    private let orientation: Orientation
    private let pacing: Pacing
    private let loops: Bool
    private let clock: PlaybackClock
    private let queue = DispatchQueue(label: "YULan.FaceFrame.VideoFileFrameSource")
    private let runs = Mutex(Runs())

    /// `loops`: plays again at the end of the file, until `stop()`.
    /// `clock`: for `.realTime`. Tests use a fake one.
    public init(
        url: URL,
        orientation: Orientation = .recorded(mirrored: false),
        pacing: Pacing = .asFastAsPossible,
        loops: Bool = false,
        clock: PlaybackClock = .continuous
    ) {
        self.url = url
        self.orientation = orientation
        self.pacing = pacing
        self.loops = loops
        self.clock = clock
    }

    public func run(onFrame: @escaping @Sendable (VideoFrame) -> Void) async throws {
        let run = runs.withLock { runs in
            runs.started += 1
            return runs.started
        }
        // Register the run first, so a task that is already cancelled stops it too.
        try await withTaskCancellationHandler {
            try await play(run: run, onFrame: onFrame)
        } onCancel: {
            stop()
        }
    }

    public func stop() {
        runs.withLock { $0.stopped = $0.started }
    }

    private func isStopped(_ run: Int) -> Bool {
        runs.withLock { $0.stopped >= run }
    }

    private func play(run: Int, onFrame: @escaping @Sendable (VideoFrame) -> Void) async throws {
        let asset = AVURLAsset(url: url)
        let loadedTrack: AVAssetTrack
        let clip: Clip
        do {
            guard let first = try await asset.loadTracks(withMediaType: .video).first else {
                throw TrackingError.sourceFailed
            }
            loadedTrack = first
            let (transform, frameRate, timeRange) = try await first.load(.preferredTransform, .nominalFrameRate, .timeRange)
            clip = Clip(
                orientation: Self.resolve(orientation, transform: transform),
                frameInterval: frameRate > 0 ? .seconds(1 / Double(frameRate)) : nil,
                duration: .seconds(timeRange.duration.seconds)
            )
        } catch {
            Log.frames.error("Cannot load the video: \(error.localizedDescription, privacy: .public)")
            throw TrackingError.sourceFailed
        }
        // AVAssetTrack isn't Sendable. Safe here: it doesn't change once loaded,
        // and only `queue` uses it after this line.
        nonisolated(unsafe) let track = loadedTrack

        // Decoding and sleeping block the thread, so this runs on our own queue.
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            queue.async { [self] in
                do {
                    try read(asset: asset, track: track, clip: clip, run: run, onFrame: onFrame)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func resolve(_ orientation: Orientation, transform: CGAffineTransform) -> CGImagePropertyOrientation {
        switch orientation {
        case .fixed(let orientation):
            orientation
        case .recorded(let mirrored):
            CGImagePropertyOrientation(preferredTransform: transform, mirrored: mirrored)
        }
    }

    private func read(
        asset: AVAsset,
        track: AVAssetTrack,
        clip: Clip,
        run: Int,
        onFrame: (VideoFrame) -> Void
    ) throws {
        var schedule = Schedule(pacing: pacing, frameInterval: clip.frameInterval, clock: clock)
        var pass = 0
        repeat {
            // Each pass adds one clip duration, so the timestamps keep increasing.
            let offset = clip.duration * pass
            let frameCount = try readOnce(asset: asset, track: track, run: run) { pixelBuffer, time in
                let timestamp = time + offset
                guard schedule.waitForTurn(of: timestamp) else { return }
                onFrame(VideoFrame(pixelBuffer: pixelBuffer, timestamp: timestamp, orientation: clip.orientation))
            }
            // A file without frames would loop forever.
            guard frameCount > 0 else { return }
            pass += 1
        } while loops && !isStopped(run)
    }

    /// Reads the file once. Returns the number of frames.
    private func readOnce(
        asset: AVAsset,
        track: AVAssetTrack,
        run: Int,
        onSample: (CVPixelBuffer, Duration) -> Void
    ) throws -> Int {
        let reader: AVAssetReader
        do {
            reader = try AVAssetReader(asset: asset)
        } catch {
            Log.frames.error("Cannot create the reader: \(error.localizedDescription, privacy: .public)")
            throw TrackingError.sourceFailed
        }
        let output = AVAssetReaderTrackOutput(
            track: track,
            outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        )
        output.alwaysCopiesSampleData = false
        guard reader.canAdd(output) else { throw TrackingError.sourceFailed }
        reader.add(output)
        guard reader.startReading() else { throw TrackingError.sourceFailed }
        defer {
            if reader.status == .reading { reader.cancelReading() }
        }

        var count = 0
        while !isStopped(run), let sample = output.copyNextSampleBuffer() {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sample) else { continue }
            count += 1
            onSample(pixelBuffer, .seconds(CMSampleBufferGetPresentationTimeStamp(sample).seconds))
        }

        if reader.status == .failed {
            Log.frames.error("Reading failed: \(reader.error?.localizedDescription ?? "unknown", privacy: .public)")
            throw TrackingError.sourceFailed
        }
        return count
    }
}

/// Decides when each frame of a replay is delivered.
private struct Schedule {
    let pacing: VideoFileFrameSource.Pacing
    let frameInterval: Duration?
    let clock: PlaybackClock
    /// Clock time and timestamp of the first frame. The other frames are placed from them.
    private var origin: (clock: Duration, timestamp: Duration)?

    init(pacing: VideoFileFrameSource.Pacing, frameInterval: Duration?, clock: PlaybackClock) {
        self.pacing = pacing
        self.frameInterval = frameInterval
        self.clock = clock
    }

    /// Waits until the frame is due. Returns `false` when the frame is late.
    mutating func waitForTurn(of timestamp: Duration) -> Bool {
        guard case .realTime = pacing else { return true }
        guard let origin else {
            origin = (clock.now(), timestamp)
            return true
        }
        let due = origin.clock + (timestamp - origin.timestamp)
        let wait = due - clock.now()
        if wait > .zero {
            clock.sleep(wait)
        } else if let frameInterval, wait <= .zero - frameInterval {
            return false
        }
        return true
    }
}
