# AGENTS.md

Rules for AI coding agents (Claude Code, Codex…) working in this repository.
The method comes from the book *AI Driven Swift Architecture* (W. Sassi, D. Poirier, Packt, 2026): rules written down, tests first, Clean Architecture boundaries, and the developer decides.

## This is a learning project

The author is a senior iOS developer. The camera, Vision and AR are new to her, and she uses this project to learn them.

- The author decides the scope, the structure and what is kept. The structure is the one of her other projects: a Foundation-only Domain, a DataLayer, a SwiftUI app on top.
- Agents write the implementation and its tests, only when she asks for it in the current conversation.
- Agents explain what they wrote and point to Apple's documentation or sample code, so that she can read it and explain it herself.
- When she says she writes a part herself, agents explain and review. They do not edit that part, not even to prepare it.
- The README says a step works on a device only after she has checked it there.
- Never present agent-written code as her personal work.

## How we work

- **Plan before code.** For a change in more than one file, write the plan first: files, tests, risks. Wait for the answer.
- **Stay in scope.** A refactoring changes no behaviour. A fix does not redesign. No extra changes "while you are there".
- **Explain the choice.** For each non-trivial choice, say why and what it costs. Say so if a simpler option exists.
- **Small steps.** One behaviour at a time, one commit-sized change at a time.
- **Say what is checked.** Simulator, device or not at all: these are three different answers.
- **Write the lesson down.** When the author corrects a mistake, add it to "Lessons learned" at the end of this file.

## Project map

- `Packages/FaceFrameCore/Sources/Domain`: entities, geometry, smoothing, metrics, `TrackingError`, `FaceTrackingSession`. **Imports only Foundation.**
- `Packages/FaceFrameCore/Sources/DataLayer`: frame sources (camera, video file), `VisionFaceTracker`, `TrackingPipeline`, `SimulatedTrackingSession`, and `Preview` (camera preview, picture of a replay).
- `FaceFrame/App`: `@main`, `TrackingMode` (camera, simulation or replay, from the launch arguments), `AppDependencyContainer`, `Log`.
- `FaceFrame/Presentation`: `TryOnViewModel`, views, `DesignSystem` (`L10n`, `AppSymbol`).
- Tests mirror the source tree: `Packages/FaceFrameCore/Tests/` and `FaceFrameTests/`.
- `Samples/`: local clips for the replay and the benchmark. Ignored by git.

## Commands

```bash
cd Packages/FaceFrameCore && swift test
xcodebuild test -project FaceFrame.xcodeproj -scheme FaceFrame -destination 'platform=iOS Simulator,name=iPhone 17'
```

The first one runs the package tests on the Mac. The second one runs all the tests.

## Architecture: the Domain is the centre

1. **Dependency direction.** Domain imports nothing but Foundation, not even CoreGraphics. DataLayer imports Domain. The app imports both.
2. **AVFoundation and Vision stay in DataLayer.** Their errors are mapped to `TrackingError` there. One exception: `CameraPreviewView` imports AVFoundation, because the preview layer lives in a view. It shows the picture and never touches the capture session. DataLayer connects the session through `CameraPreviewSource`.
3. **The ViewModel depends on `FaceTrackingSession`**, a Domain protocol. Never on a frame source or a tracker.
4. **One pipeline.** The camera and the replay use the same `TrackingPipeline` and the same tracker. A new source of frames implements `FrameSource`.
5. **One composition root.** `AppDependencyContainer` is the only place in the app that creates DataLayer objects. The views receive their backdrop from it (`CameraPreviewSource` or `FramePreviewFeed`). SwiftUI previews and tests may build a `SimulatedTrackingSession` or a fake.
6. **A boundary change needs a decision first** (new module, new dependency, new layer rule). Propose it as a short ADR in the conversation: Status, Context, Decision, Consequences.

## Tests first (TDD)

- **Red, green, refactor.** Write the test first. See it fail for the right reason. Then write the code.
- **Green means the simplest change that passes.** Go up one step only when a test forces it: constant, then variable, then condition, then collection, then a new abstraction.
- **Generalize on the second example.** One test allows a hard-coded answer. A second, different test forces the real logic.
- **Refactor only on green.** A refactoring changes no test expectation.
- **Limit cases are the author's call.** An agent follows the steps, but it does not look for invalid or limit values on its own. Ask which ones matter before writing those tests.
- **Swift Testing** everywhere (`@Test`, `#expect`).
- **No camera, no face, no real time in a test.** Use the fakes in the `Support` folders, the simulation, or a generated clip (`TestVideo`). Inject the time.
- Every behaviour change ships with tests in the mirrored path. Never widen access control just to test.
- What cannot be tested is written in the README, with how it is checked instead.

## Concurrency and real time

Swift 6 language mode, strict concurrency `complete`, zero warnings.

- A `CVPixelBuffer` / `CMSampleBuffer` never leaves the frame source's queue. Only the result (`TrackingResult`, which is `Sendable`) goes to the main actor. What the replay shows on screen is a copy (`FramePreviewFeed`).
- The stream keeps only the newest result. A late UI skips frames. It never shows an old position.
- `startRunning()` and `stopRunning()` block. They stay off the main thread and off the cooperative pool: `CameraFrameSource` is an actor on the session queue.
- `async` means "may suspend". It does not mean "runs in the background".
- `@MainActor` is the UI boundary: views and the ViewModel. Never add it just to silence an error.
- An actor is for state that has an owner and invariants. For one small value read and written at once, use `Mutex`.
- `Sendable` is a promise. If a type resists it, rethink who owns the data before you annotate.
- Prefer `Mutex` to `@unchecked Sendable`. Any `nonisolated(unsafe)` carries a comment that says why it is safe. A new one needs the author's agreement.
- Structured concurrency by default. No `Task.detached`. No stored `Task` in a ViewModel.

## Measure, then optimize

- No performance claim without a number from a run. Say the device, the date and how many readings.
- In the simulator, Vision runs on the CPU. Its timings say nothing about an iPhone.
- One change at a time, then the benchmark again.

## UI

- **No literals in views.** Text in `L10n` and `Localizable.xcstrings` (both `en` and `fr`), symbols in `AppSymbol`, colours in the asset catalog.
- **Accessibility.** Every control has a label. Its state goes in the value.

## Safety

- **Faces:** never commit a picture or a video of a face. Clips stay in `Samples/`. Screenshots from the device stay out of the repository.
- **Git:** never commit, push or rewrite history unless the author asks. Short, plain messages, with no tool signature: this file says who writes what. Each commit builds and passes the tests.

## Before you say "done"

- Run the tests and read the result. Count the tests in the `.xcresult`. A green run only proves that what ran passed.
- Every number in the README comes from a run you can point to.
- Try what a reviewer will try: camera access refused, no camera, no face, a face lost and found again, a replay with a missing file, French.

## Lessons learned

- From the book: a redundant second test. Two tests that force the same code teach nothing. Keep one, and write a different example.
- From this project: in the simulator, the Vision request fails ("Could not create inference context") unless it runs on the CPU. `VisionFaceTracker` sets that for the simulator only.
- From this project: a Vision landmark is relative to the face box, and Vision's origin is at the bottom-left. Convert before use. `VisionFaceTrackerTests` cover it.
- From this project: `VideoFileFrameSourceTests` failed in 4 of the first 8 full runs on 23/11/2026 (decoder error -8969). The cause is not found. They now run one at a time. If they fail, run the tests again.
- From this project (24/11/2026): an agent edited a part the author had said she would write herself. "I write it" means no edit there, not even a stub or a test.
