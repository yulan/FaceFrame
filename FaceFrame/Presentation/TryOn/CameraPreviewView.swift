//
//  CameraPreviewView.swift
//  FaceFrame
//
//  Created by Lan YU on 21/11/2026.
//

import AVFoundation
import DataLayer
import SwiftUI
import UIKit

/// The camera picture behind the glasses.
struct CameraPreviewView: UIViewRepresentable {
    let source: any CameraPreviewSource

    func makeUIView(context: Context) -> CameraPreviewUIView {
        CameraPreviewUIView(source: source)
    }

    func updateUIView(_ view: CameraPreviewUIView, context: Context) {}
}

/// The backing layer is the preview layer, so it follows the view's size.
final class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    init(source: any CameraPreviewSource) {
        super.init(frame: .zero)
        // Shown until the first picture arrives.
        backgroundColor = UIColor(resource: .previewBackground)
        // AspectFillMapping assumes aspect fill.
        previewLayer.videoGravity = .resizeAspectFill
        source.connect(to: previewLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
