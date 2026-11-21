//
//  GlassesOverlayView.swift
//  FaceFrame
//
//  Created by Lan YU on 21/11/2026.
//

import Domain
import SwiftUI

/// Draws the glasses at a placement computed by the ViewModel.
struct GlassesOverlayView: View {
    let placement: GlassesPlacement

    var body: some View {
        Image(systemName: AppSymbol.glasses.rawValue)
            .resizable()
            .scaledToFit()
            .frame(width: max(placement.width, 1))
            .foregroundStyle(Color(.glassesTint))
            .rotationEffect(.radians(placement.angle))
            .position(x: placement.center.x, y: placement.center.y)
            .accessibilityHidden(true)
    }
}
