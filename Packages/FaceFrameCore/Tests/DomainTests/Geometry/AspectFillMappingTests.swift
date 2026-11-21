//
//  AspectFillMappingTests.swift
//  DomainTests
//
//  Created by Lan YU on 21/11/2026.
//

import Domain
import Testing

/// Written before the implementation: red until the TODO in AspectFillMapping is done.
struct AspectFillMappingTests {
    @Test func sameAspectRatioIsAPlainScale() {
        let mapping = AspectFillMapping(
            imageSize: Size2D(width: 1280, height: 720),
            viewSize: Size2D(width: 640, height: 360)
        )

        expectClose(mapping.viewPoint(for: Point2D(x: 0.5, y: 0.5)), Point2D(x: 320, y: 180))
        expectClose(mapping.viewPoint(for: Point2D(x: 1, y: 1)), Point2D(x: 640, y: 360))
    }

    @Test func tallerViewCropsTheSides() {
        // A 720×1280 image fills a 390×844 view: scale = 844 / 1280, the scaled
        // image is 474.75 pt wide, so 42.375 pt are cropped on each side.
        let mapping = AspectFillMapping(
            imageSize: Size2D(width: 720, height: 1280),
            viewSize: Size2D(width: 390, height: 844)
        )

        expectClose(mapping.viewPoint(for: Point2D(x: 0.5, y: 0.5)), Point2D(x: 195, y: 422))
        expectClose(mapping.viewPoint(for: Point2D(x: 0, y: 0)), Point2D(x: -42.375, y: 0))
        expectClose(mapping.viewPoint(for: Point2D(x: 1, y: 0.25)), Point2D(x: 432.375, y: 211))
    }

    @Test func widerViewCropsTopAndBottom() {
        // A 720×1280 image fills an 800×800 view: scale = 800 / 720, the scaled
        // image is 1422.2 pt high, so 311.1 pt are cropped at the top and bottom.
        let mapping = AspectFillMapping(
            imageSize: Size2D(width: 720, height: 1280),
            viewSize: Size2D(width: 800, height: 800)
        )

        expectClose(mapping.viewPoint(for: Point2D(x: 0.5, y: 0.5)), Point2D(x: 400, y: 400))
        expectClose(mapping.viewPoint(for: Point2D(x: 0.5, y: 0)), Point2D(x: 400, y: -311.111))
    }
}
