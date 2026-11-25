//
//  FramePreviewView.swift
//  FaceFrame
//
//  Created by Lan YU on 22/11/2026.
//

import DataLayer
import ImageIO
import SwiftUI

/// The frames of a replay, drawn like the camera preview: aspect fill.
struct FramePreviewView: View {
    let feed: FramePreviewFeed
    @State private var frame: PreviewFrame?

    var body: some View {
        Color(.previewBackground)
            .overlay {
                if let frame {
                    Image(decorative: frame.image, scale: 1, orientation: Image.Orientation(frame.orientation))
                        .resizable()
                        .scaledToFill()
                }
            }
            .clipped()
            .task {
                for await next in feed.frames() {
                    frame = next
                }
            }
    }
}

private extension Image.Orientation {
    init(_ orientation: CGImagePropertyOrientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
