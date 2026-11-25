# FaceFrame

A learning project: glasses try-on in real time with the front camera.
AVFoundation captures the frames, Vision finds the pupils, and SwiftUI draws a pair of glasses on the face. The frame rate and the detection time are shown on screen.

Swift 6 with strict concurrency, SwiftUI, iOS 18, no third-party dependencies.
Same structure as [OpenWeatherMVVM-C](https://github.com/yulan/OpenWeatherMVVM-C): a local package with `Domain` and `DataLayer`, and the app on top.

## Status

Work in progress. On a device, the camera, the Vision detection and the glasses placement work. The smoothing was added on 24/11/2026, after the check below.

Checked on an iPhone 14 Pro, 23/11/2026:

- the camera picture is on screen
- the badge showed 30 frames per second and 22.0 ms per detection (one reading)
- with the landmarks button, a dot sits on each pupil and a line follows the jaw
- the glasses sit on the eyes

Not checked yet:

- the smoothing on a device
- refusing the camera access
- the Vision detection in a replay (no clip of a face has been recorded)

The glasses are flat. They don't turn when the head turns. See Phase 3.

| Test run (iPhone 17 simulator, iOS 27.2, 24/11/2026) | Count |
| --- | --- |
| Passed | 79 |
| Failed | 0 |
| Skipped, the benchmark needs a video | 1 |

Known problem: on the simulator, `VideoFileFrameSourceTests` failed in 4 of the first 8 full runs on 23/11/2026, with a decoder error (-8969). It did not happen again in the next 36 runs, and the cause is not found. These tests now run one at a time. If they fail, run the tests again.

## Architecture

```
FrameSource -> TrackingPipeline -> TryOnViewModel -> TryOnView
```

- `Packages/FaceFrameCore/Sources/Domain`: geometry, smoothing, performance metrics, errors. Foundation only.
- `Packages/FaceFrameCore/Sources/DataLayer`: the frame sources (camera, video file), the Vision tracker, `TrackingPipeline`, the simulation.
- `FaceFrame/`: the app. `TrackingMode` reads the launch arguments, and `AppDependencyContainer` builds the camera, the simulation or the replay.

A `CVPixelBuffer` is not `Sendable`, and the camera reuses it. So the detection runs on the frame source's queue, and only the result (`TrackingResult`, which is `Sendable`) goes to the MainActor. The stream keeps only the newest result (`bufferingNewest(1)`). If the UI is late, it skips frames and never shows an old position.

## Three sources, one pipeline

| Source | When | Picture on screen |
| --- | --- | --- |
| Camera (`CameraFrameSource`) | on a device | `AVCaptureVideoPreviewLayer` |
| Replay (`VideoFileFrameSource`) | `-replayVideo /path/to/clip.mov`, in the simulator | a copy of each frame (`FramePreviewFeed`) |
| Simulation (`SimulatedTrackingSession`) | simulator by default, or `-simulatedTracking` | none |

### Replay

A clip recorded with the front camera is played in a loop through the same pipeline and the same tracker as the camera. The frames are the same at every run, so two versions of the tracker can be compared. It also works without the phone.

The clip is played at its own speed. A late frame is dropped, as the camera does with `alwaysDiscardsLateVideoFrames`.

Put the clip in `Samples/`. This folder is ignored by git, so a video of a face is never committed. Then, with the app installed in a booted simulator:

```bash
xcrun simctl launch booted YULan.FaceFrame -replayVideo "$PWD/Samples/face.mov"
```

In Xcode: Product > Scheme > Edit Scheme > Run > Arguments, add `-replayVideo /absolute/path/to/Samples/face.mov`.

- The rotation is read from the file (`preferredTransform`). The picture is mirrored like the front camera preview.
- The picture on screen is a copy of each frame, about 3.7 MB at 720p. The camera doesn't pay this cost.
- In the simulator, Vision runs on the CPU. The detection time there says nothing about an iPhone.

## Phase 1: geometry, Vision, camera

| Step | File | State |
| --- | --- | --- |
| 1 | `Domain/Geometry/AspectFillMapping.swift` | Done |
| 2 | `Domain/Geometry/GlassesPlacementCalculator.swift` | Done |
| 3 | `Domain/Filtering/ExponentialSmoother.swift` | Done |
| 4 | `DataLayer/Tracking/VisionFaceTracker.swift` | Done |
| 5 | `DataLayer/Frames/CameraFrameSource.swift` | Done |
| 6 | `FaceFrame/Presentation/TryOn/CameraPreviewView.swift` | Done |

Steps 1 to 5 are in `Packages/FaceFrameCore/Sources`.

Notes:

- The smoothing is an exponential moving average on the two pupils. Each new position moves the glasses 35% of the way (`alpha` = 0.35 in `TryOnViewModel`). This value is a first guess. It is not tuned on a device.
- `VisionFaceTrackerTests` cover the conversion of Vision's coordinates and the order of the two pupils. A landmark is relative to the face box, and Vision's origin is at the bottom-left. Finding a real face has no test. It is checked on screen with the dots.
- In the simulator, the Vision request fails with "Could not create inference context" unless it runs on the CPU. `VisionFaceTracker` sets that for the simulator only.
- The outline of the face comes from the same request as the pupils (`faceContour`), so there is no second detection. Vision gives no forehead, so the line is open.
- `CameraFrameSource` is an actor that runs on the session queue, like `CaptureService` in Apple's AVCam sample. `startRunning()` and `stopRunning()` block, so they stay off the main thread and off the cooperative pool.
- `CameraFrameSourceTests` cover what needs no camera: access refused, no camera, and a stop while the access question is still open.

## Phase 2: measure, then optimize

1. Record a clip of a face with the front camera, 10 to 20 seconds.
2. Run the benchmark on it and write the numbers in the table:

   ```bash
   cd Packages/FaceFrameCore
   FACEFRAME_BENCHMARK_VIDEO=/path/to/clip.mov swift test --filter VisionBenchmark
   ```

   The benchmark reads the clip as fast as it can and keeps every result.

3. Profile on a device with Instruments. The "detect" intervals are under Points of Interest.
4. Try one change at a time and run the benchmark again. Ideas: a lower capture resolution, detecting every N frames and tracking in between with `VNTrackObjectRequest`, a lower frame rate when `ProcessInfo.thermalState` rises.

| Change | Average | p95 | FPS on device |
| --- | --- | --- | --- |
| Baseline | | | |

## Phase 3: ARKit

Two pupils in a 2D picture give a position, a tilt and a relative size. They give no millimetres and no rotation of the head. The plan is a second screen with `ARFaceTrackingConfiguration` (TrueDepth camera) and RealityKit (`AnchorEntity(.face)`): glasses at their real size, and a pupillary distance from `ARFaceAnchor.leftEyeTransform` and `rightEyeTransform`.

## Running

- Simulator: a simulated face by default (badge "Simulation"), or a replay.
- Device: the camera. The launch argument `-simulatedTracking` forces the simulation.
- Package tests, on the Mac: `cd Packages/FaceFrameCore && swift test`
- All tests: `xcodebuild test -project FaceFrame.xcodeproj -scheme FaceFrame -destination 'platform=iOS Simulator,name=iPhone 17'`
