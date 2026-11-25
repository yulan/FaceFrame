//
//  RecordedOrientation.swift
//  DataLayer
//
//  Created by Lan YU on 22/11/2026.
//

import CoreGraphics
import ImageIO

extension CGImagePropertyOrientation {
    /// Orientation that shows a recorded video upright.
    /// Only quarter turns are handled. Other transforms count as no rotation.
    /// `mirrored` also flips left and right, like the front camera preview.
    init(preferredTransform transform: CGAffineTransform, mirrored: Bool) {
        // y goes down in a video. A quarter turn clockwise sends (1, 0) to (0, 1).
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
