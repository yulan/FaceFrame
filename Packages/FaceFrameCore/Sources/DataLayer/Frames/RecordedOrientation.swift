//
//  RecordedOrientation.swift
//  DataLayer
//
//  Created by Lan YU on 22/11/2026.
//

import CoreGraphics
import ImageIO

extension CGImagePropertyOrientation {
    /// The orientation that shows the frames of a recorded video upright.
    ///
    /// A video file stores its frames as the sensor saw them, plus a transform
    /// to apply at playback. A phone held in portrait records landscape frames
    /// and a quarter-turn clockwise.
    ///
    /// - Parameters:
    ///   - preferredTransform: the track's transform. Only quarter turns are
    ///     recognised; anything else is treated as "no rotation".
    ///   - mirrored: also flips the picture left to right, the way the front
    ///     camera preview shows it.
    init(preferredTransform transform: CGAffineTransform, mirrored: Bool) {
        // In the video's coordinates (y down), a quarter-turn clockwise sends
        // (1, 0) to (0, 1), so `a` and `b` are enough to tell the turns apart.
        let turns = (transform.a.rounded(), transform.b.rounded())
        switch turns {
        case (0, 1):
            self = mirrored ? .leftMirrored : .right
        case (-1, 0):
            self = mirrored ? .downMirrored : .down
        case (0, -1):
            self = mirrored ? .rightMirrored : .left
        default:
            self = mirrored ? .upMirrored : .up
        }
    }
}
