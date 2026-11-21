//
//  PerformanceBadge.swift
//  FaceFrame
//
//  Created by Lan YU on 21/11/2026.
//

import SwiftUI

struct PerformanceBadge: View {
    let text: LocalizedStringResource

    var body: some View {
        Text(text)
            .font(.caption.monospacedDigit())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.regularMaterial, in: Capsule())
    }
}
