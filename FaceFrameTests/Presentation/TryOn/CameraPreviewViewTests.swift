//
//  CameraPreviewViewTests.swift
//  FaceFrameTests
//
//  Created by Lan YU on 23/11/2026.
//

import AVFoundation
import DataLayer
@testable import FaceFrame
import Testing

@MainActor
struct CameraPreviewViewTests {
    @MainActor
    private final class FakePreviewSource: CameraPreviewSource {
        private(set) var connectedLayers: [AVCaptureVideoPreviewLayer] = []

        func connect(to layer: AVCaptureVideoPreviewLayer) {
            connectedLayers.append(layer)
        }
    }

    /// `AspectFillMapping` assumes a picture that fills the view.
    @Test func thePictureFillsTheView() {
        let view = CameraPreviewUIView(source: FakePreviewSource())

        #expect(view.previewLayer.videoGravity == .resizeAspectFill)
    }

    @Test func theLayerIsConnectedToTheSourceOnce() {
        let source = FakePreviewSource()

        let view = CameraPreviewUIView(source: source)

        #expect(source.connectedLayers.count == 1)
        #expect(source.connectedLayers.first === view.previewLayer)
    }
}
