@AGENTS.md

## Claude Code

- The rules are in AGENTS.md, imported above, so every agent reads the same file. Add a new rule there, not here.
- Use plan mode for a change in more than one file, or for anything that touches a layer boundary. Show the plan and wait.
- Fast loop: `swift test` in `Packages/FaceFrameCore` while editing the package. Run all the tests with `xcodebuild test` before handing the work back.
- A large refactoring that repeats the same steps gets its own skill, `.claude/skills/<short-name>/SKILL.md`, instead of a long prompt. The skill says what changes and what must not change.
