//
//  VisionFaceTracker.swift
//  DataLayer
//
//  Created by Lan YU on 21/11/2026.
//

import Domain
import Vision

/// Finds the pupils with Vision.
///
/// TODO — Phase 1, step 4. What it must do:
///
/// 1. Perform a `VNDetectFaceLandmarksRequest` with
///    `VNImageRequestHandler(cvPixelBuffer: frame.pixelBuffer, orientation: frame.orientation)`.
/// 2. Take a `VNFaceObservation` (the largest if there are several) and its
///    `landmarks?.leftPupil` / `landmarks?.rightPupil`.
/// 3. Convert to `EyePositions` (see its documentation). Vision's points are
///    normalized to the face's bounding box; the box is normalized to the
///    image with the origin at the **bottom-left**. `EyePositions` wants the
///    whole image with the origin at the **top-left**.
/// 4. Which pupil ends up on the left of the screen? Check it with the
///    mirrored front camera, using the landmark dots in the app.
///
/// Put the conversion (point 3) in a pure function and pin it with unit tests:
/// those tests don't need a photo. It is the easiest part to get wrong.
///
/// Simulator: with its default settings the request fails there with
/// "Could not create inference context" (checked on the iOS 27.2 simulator,
/// 22/11/2026). It runs once the CPU is chosen as its compute device: see
/// `supportedComputeStageDevices` and `setComputeDevice(_:for:)`. Needed for
/// the replay mode; a device and the Mac (`swift test`) work as they are.
public struct VisionFaceTracker: FaceTracker {
    public init() {}

    public func eyes(in frame: VideoFrame) throws -> EyePositions? {
        // TODO: replace with the Vision request described above.
        nil
    }
}
