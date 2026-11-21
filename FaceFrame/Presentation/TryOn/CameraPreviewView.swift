//
//  CameraPreviewView.swift
//  FaceFrame
//
//  Created by Lan YU on 21/11/2026.
//

import SwiftUI

/// The camera picture behind the glasses.
///
/// TODO — Phase 1, step 6:
/// - a `UIViewRepresentable` whose `UIView` overrides `layerClass` to return
///   `AVCaptureVideoPreviewLayer.self`;
/// - `videoGravity = .resizeAspectFill`, because `AspectFillMapping` assumes it;
/// - the session comes from `CameraFrameSource` (you decide how in step 5).
///
/// Until then it is a plain background. The simulation and the replay don't
/// use this view (see `TryOnBackdrop`).
struct CameraPreviewView: View {
    var body: some View {
        Color(.previewBackground)
    }
}
