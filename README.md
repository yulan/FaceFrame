# FaceFrame

A learning project: real-time glasses try-on with the front camera.
AVFoundation captures the frames, Vision finds the pupils, and SwiftUI draws a pair of glasses that follows the face, with the frame rate and the detection time on screen.

Swift 6 (strict concurrency), SwiftUI, iOS 18, no third-party dependencies. Same structure as [OpenWeatherMVVM-C](https://github.com/yulan/OpenWeatherMVVM-C): a local SPM package with `Domain` and `DataLayer`, and the app on top.

## Status

**Work in progress. The pipeline, the screen and the replay of a recorded clip run. The geometry, the Vision detection and the camera capture are still `TODO`.**

| Part | State |
| --- | --- |
| Tracking pipeline, performance metrics, error screen | Done |
| Simulated pupils, to run the screen in the simulator | Done |
| Replay of a recorded clip through the same pipeline | Done |
| Geometry and smoothing: from two pupils to the glasses | `TODO`, tests written |
| Vision detection of the pupils | `TODO` |
| Camera capture and preview | `TODO` |
| Measurements on a device, then optimization | `TODO` |
| ARKit screen, for real sizes | `TODO` |

What the app shows today:

- **in the simulator:** the performance badge (simulated values) and, with the landmarks button, the simulated pupils as two dots. The glasses are not placed yet: that needs the geometry;
- **in a replay:** the picture of the clip, the frame rate, and "No face detected": it needs the Vision detection;
- **on a device:** the "Camera unavailable" screen: it needs the camera capture.

The tests of the `TODO` parts are written first, so they fail until those parts exist.

| Test run (iPhone 17 simulator, iOS 27.2, 23/11/2026) | Count |
| --- | --- |
| Passed | 54 |
| Failed: waiting for a `TODO` | 9 |
| Skipped: benchmark, needs a video | 1 |

## Architecture

```
FrameSource ──frames──▶ TrackingPipeline ──TrackingResult──▶ TryOnViewModel ──▶ TryOnView
(its own queue)         FaceTracker (Vision)                 smoothing, metrics      AspectFillMapping
                        runs on the same queue                 (MainActor)           GlassesPlacementCalculator
```

- `Packages/FaceFrameCore/Sources/Domain`: geometry, smoothing, performance metrics, `TrackingError`, the `FaceTrackingSession` port. Foundation only, with unit tests for all its logic.
- `Packages/FaceFrameCore/Sources/DataLayer`: `FrameSource` (camera, video file), `FaceTracker` (Vision), `TrackingPipeline`, `SimulatedTrackingSession`, and the preview of a replay.
- `FaceFrame/`: the app. `TrackingMode` reads the launch arguments; `AppDependencyContainer` builds the camera, the simulation or the replay from it.

**Concurrency rule:** a `CVPixelBuffer` is not `Sendable` and is recycled by the camera. Detection runs synchronously on the frame source's queue, and only the `Sendable` `TrackingResult` reaches the MainActor. The stream keeps only the newest result (`bufferingNewest(1)`): if the UI falls behind, it skips frames instead of showing old positions late.

## Three sources, one pipeline

| Source | When | Picture on screen |
| --- | --- | --- |
| Camera (`CameraFrameSource`) | on a device | `AVCaptureVideoPreviewLayer` |
| Replay (`VideoFileFrameSource`) | `-replayVideo /path/to/clip.mov`, in the simulator | each frame, copied (`FramePreviewFeed`) |
| Simulation (`SimulatedTrackingSession`) | simulator by default, or `-simulatedTracking` | none: moving dots only |

### Replay

A clip recorded once with the front camera is played in a loop through the same `TrackingPipeline` and the same tracker as the camera. It is there for three reasons:

- **work without the phone:** the detection can be developed and shown in the simulator;
- **same input every time:** a change in the tracker is judged on the same frames, which a live camera never gives;
- **same behaviour as the camera:** the clip is paced by its own timestamps, and a frame that is already one frame late is dropped, as `alwaysDiscardsLateVideoFrames` does. The frame rate on screen is then what a camera would deliver with that detection time.

Put the clip in `Samples/`: the folder is ignored by git, so a video of a face is never committed. Then, with the app installed in a booted simulator:

```bash
xcrun simctl launch booted YULan.FaceFrame -replayVideo "$PWD/Samples/face.mov"
```

In Xcode: Product ▸ Scheme ▸ Edit Scheme ▸ Run ▸ Arguments, add `-replayVideo /absolute/path/to/Samples/face.mov`.

Choices and limits:

- The rotation is read from the file (`preferredTransform`), and the picture is mirrored like the front camera preview.
- The picture is a **copy** of each frame (about 3.7 MB at 720p), so the rule above still holds: no pixel buffer leaves the source's queue. That cost is fine for a development tool; the camera doesn't pay it.
- **The simulator's numbers are not the device's.** In the simulator, Vision needs the CPU as its compute device (see `VisionFaceTracker`), so the detection time there says nothing about an iPhone. Measure on a device or with the benchmark below.

## Phase 1: geometry, Vision, camera

In this order. Each step has tests or a visible check.

| Step | File | Done when |
| --- | --- | --- |
| 1 | `Domain/Geometry/AspectFillMapping.swift` | `AspectFillMappingTests` pass |
| 2 | `Domain/Geometry/GlassesPlacementCalculator.swift` | `GlassesPlacementCalculatorTests` pass; the glasses appear in the simulator |
| 3 | `Domain/Filtering/ExponentialSmoother.swift` | `ExponentialSmootherTests` pass; compare the glasses with the dots (landmarks button) |
| 4 | `DataLayer/Tracking/VisionFaceTracker.swift` | in a replay, the dots sit on the pupils; the coordinate conversion has its own tests |
| 5 | `DataLayer/Frames/CameraFrameSource.swift` | on a device, the frame rate replaces the "Camera unavailable" screen; refusing camera access shows the "Camera access is off" screen |
| 6 | `FaceFrame/Presentation/TryOn/CameraPreviewView.swift` | on a device, the camera picture is behind the glasses |

`TryOnViewModelTests.placesTheGlassesBetweenThePupils` goes green after steps 1 and 2.
Steps 1 to 4 run in the simulator; step 4 needs a recorded clip. Steps 5 and 6 need a device.

## Phase 2: measure, then optimize

1. Record a 10–20 s clip of a face with the front camera.
2. Run the benchmark on it, and write the numbers in the table below:

   ```bash
   cd Packages/FaceFrameCore
   FACEFRAME_BENCHMARK_VIDEO=/path/to/clip.mov swift test --filter VisionBenchmark
   ```

   The benchmark reads the clip as fast as it can decode it and keeps every result; the replay plays the same clip in real time and drops late frames.

3. Profile on a device with Instruments: the "detect" intervals are under Points of Interest.
4. Try one change at a time and re-run the benchmark: lower capture resolution; skip a frame when the previous one is still being processed; detect every N frames and track in between with `VNTrackObjectRequest`; lower the frame rate when `ProcessInfo.thermalState` rises.

| Change | Average | p95 | FPS on device |
| --- | --- | --- | --- |
| Baseline | | | |

## Phase 3: ARKit, for real sizes

Two pupils in a 2D picture give a position, an angle and a relative size, but no millimetres. A second screen with `ARFaceTrackingConfiguration` (TrueDepth camera) and RealityKit (`AnchorEntity(.face)`): glasses built from primitives at their real size, and a pupillary distance estimate from `ARFaceAnchor.leftEyeTransform` / `rightEyeTransform`.

## Running

- **Simulator:** simulated pupils by default (badge "Simulation"), or a replay.
- **Device:** uses the camera once step 5 is done. Launch argument `-simulatedTracking` forces the simulation.
- **Package tests (fast, on the Mac):** `cd Packages/FaceFrameCore && swift test`
- **All tests:** `xcodebuild test -project FaceFrame.xcodeproj -scheme FaceFrame -destination 'platform=iOS Simulator,name=iPhone 17'`
