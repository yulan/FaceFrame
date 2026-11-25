//
//  LandmarksOverlayView.swift
//  FaceFrame
//
//  Created by Lan YU on 21/11/2026.
//

import Domain
import SwiftUI

/// Debug marks, before smoothing: a dot on each pupil and a line on the jaw.
struct LandmarksOverlayView: View {
    let points: [Point2D]
    /// In order. Drawn as an open line.
    let contour: [Point2D]
    private let diameter = 10.0
    private let lineWidth = 2.0

    var body: some View {
        Group {
            outline
                .stroke(
                    Color(.landmarkDot),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )
            ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                Circle()
                    .fill(Color(.landmarkDot))
                    .frame(width: diameter, height: diameter)
                    .position(x: point.x, y: point.y)
            }
        }
        .accessibilityHidden(true)
    }

    private var outline: Path {
        Path { path in
            path.addLines(contour.map { CGPoint(x: $0.x, y: $0.y) })
        }
    }
}
