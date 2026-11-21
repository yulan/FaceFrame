//
//  AppDependencyContainer.swift
//  FaceFrame
//
//  Created by Lan YU on 21/11/2026.
//

import DataLayer
import Domain
import Foundation

/// The only place that knows the concrete types.
@MainActor
struct AppDependencyContainer {
    private let mode: TrackingMode
    private let session: any FaceTrackingSession
    private let backdrop: TryOnBackdrop

    init(
        mode: TrackingMode = TrackingMode(
            arguments: ProcessInfo.processInfo.arguments,
            isSimulator: TrackingMode.isRunningInSimulator
        )
    ) {
        self.mode = mode
        switch mode {
        case .camera:
            session = TrackingPipeline(source: CameraFrameSource(), tracker: VisionFaceTracker())
            backdrop = .camera
        case .simulated:
            session = SimulatedTrackingSession()
            backdrop = .plain
        case .replay(let url):
            // Same pipeline and same tracker as the camera; only the source
            // changes. A file has no preview layer, so its frames are also
            // published for the screen. Mirrored, like the front camera preview.
            let feed = FramePreviewFeed()
            let clip = VideoFileFrameSource(
                url: url,
                orientation: .recorded(mirrored: true),
                pacing: .realTime,
                loops: true
            )
            session = TrackingPipeline(source: PreviewedFrameSource(clip, feed: feed), tracker: VisionFaceTracker())
            backdrop = .frames(feed)
        }
    }

    func makeTryOnView() -> TryOnView {
        TryOnView(viewModel: TryOnViewModel(session: session, mode: mode), backdrop: backdrop)
    }
}
