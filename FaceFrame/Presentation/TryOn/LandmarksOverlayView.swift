//
//  LandmarksOverlayView.swift
//  FaceFrame
//
//  Created by Lan YU on 21/11/2026.
//

import Domain
import SwiftUI

/// Debug dots on the detected pupils, before smoothing. The quickest way to
/// see a coordinate-conversion bug: the dots must sit on your pupils.
struct LandmarksOverlayView: View {
    let points: [Point2D]
    private let diameter = 10.0

    var body: some View {
        ForEach(Array(points.enumerated()), id: \.offset) { _, point in
            Circle()
                .fill(Color(.landmarkDot))
                .frame(width: diameter, height: diameter)
                .position(x: point.x, y: point.y)
        }
        .accessibilityHidden(true)
    }
}
