//
//  AspectFillMapping.swift
//  Domain
//
//  Created by Lan YU on 21/11/2026.
//

import Foundation

/// Maps a normalized image point to the view.
/// The preview uses aspect fill: the image covers the view and the rest is
/// cropped. A point near the image edge can be outside the view.
public struct AspectFillMapping: Equatable, Sendable {
    /// As displayed, in pixels.
    public let imageSize: Size2D
    /// In points.
    public let viewSize: Size2D

    public init(imageSize: Size2D, viewSize: Size2D) {
        self.imageSize = imageSize
        self.viewSize = viewSize
    }

    /// `normalized`: 0...1 in the image, origin top-left. Returns view points.
    public func viewPoint(for normalized: Point2D) -> Point2D {
        // The larger scale, so the image covers the view.
        let scale = max(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
        let scaledWidth = imageSize.width * scale
        let scaledHeight = imageSize.height * scale
        // Centered. The offset is negative on the cropped axis.
        let offsetX = (viewSize.width - scaledWidth) / 2
        let offsetY = (viewSize.height - scaledHeight) / 2
        return Point2D(
            x: normalized.x * scaledWidth + offsetX,
            y: normalized.y * scaledHeight + offsetY
        )
    }
}
