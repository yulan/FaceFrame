//
//  AspectFillMapping.swift
//  Domain
//
//  Created by Lan YU on 21/11/2026.
//

import Foundation

/// Maps a point normalized to the camera image onto the view that shows it.
///
/// The preview uses aspect fill (`AVLayerVideoGravity.resizeAspectFill`): the
/// image is scaled until it covers the whole view, centered, and whatever
/// sticks out is cropped. So the view is a window onto the middle of the image,
/// and a point near the image edge can land outside the view.
public struct AspectFillMapping: Equatable, Sendable {
    /// Image size as displayed, in pixels (portrait for a portrait preview).
    public let imageSize: Size2D
    /// View size, in points.
    public let viewSize: Size2D

    public init(imageSize: Size2D, viewSize: Size2D) {
        self.imageSize = imageSize
        self.viewSize = viewSize
    }

    /// - Parameter normalized: 0...1 in the image, origin top-left.
    /// - Returns: the same point in view points, origin top-left.
    public func viewPoint(for normalized: Point2D) -> Point2D {
        // TODO — Phase 1, step 1. Make AspectFillMappingTests pass.
        // 1. scale = the larger of viewSize.width / imageSize.width and viewSize.height / imageSize.height
        // 2. size of the scaled image = imageSize * scale
        // 3. offset = (viewSize - scaled size) / 2   (negative on the cropped axis)
        // 4. viewPoint = normalized * scaled size + offset
        // Placeholder below stretches the image to the view: wrong as soon as the aspect ratios differ.
        Point2D(x: normalized.x * viewSize.width, y: normalized.y * viewSize.height)
    }
}
