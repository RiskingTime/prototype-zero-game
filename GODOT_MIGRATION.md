# Prototype Zero — Godot transition (engineering foundation)

## Decision and current status

HTML v0.13 is frozen as the browser-based reference implementation, except for critical bug fixes. It remains intact on `main`.

We are building an **orthographic 3D battlefield with an isometric-style camera**, using Godot **4.7.2 stable** and **GDScript**. Initial target: **Windows x86-64**, 1280×800 viewport, mouse and keyboard. Placeholder materials and primitives avoid early art dependencies.

This branch contains an Alpha 0.1 engineering test and an automated pipeline; it does **not** port the v0.13 combat systems.

## Milestones

1. Preserve the HTML v0.13 reference and agree on technical architecture.
2. Configure Godot project and GitHub Actions Windows build.
3. Validate the pipeline with a simple clickable 3D battlefield on Windows.
4. Port one complete four-hero encounter: action points, movement, cover, attacks, spells, Opportunity Attacks, Disengage, tactical AI, combat log, and encounter summary.
5. Integrate representative 3D assets, animation, sound, camera, and controller support for the vertical slice.

## Development vs. release builds

- **Development builds**: GitHub Actions creates a downloadable ZIP artifact when relevant project files change. These are for engineering and testing, **not** automatic public releases.
- **Official releases**: After automated checks **and** Windows human playtest approval, package a numbered build, commit source/changelog, archive build and notes to Google Drive, verify files, and send the completion email from james@markdalemanagement.com to james@markdalemanagement.com and JeremyRMulder@gmail.com.
- No automatic release email, Drive upload, or release promotion occurs from this test workflow. This prevents unverified builds being represented as completed releases.

## Where things live

- `godot/`: Godot project and game-ready assets.
- `godot/scenes/`: scenes.
- `godot/scripts/`: game scripts; separate rules from rendering as the project expands.
- `godot/tests/`: automated tests.
- `.github/workflows/godot-windows.yml`: headless validation and Windows export.
- Google Drive: full official release archives and editable original art sources.
- GitHub: source of truth for version-controlled game-ready content.

## Release definition of done (after the pipeline test)

1. Accepted changes implemented, reviewed, and automated tests passed.
2. Engine export generated and both EXE and PCK verified present.
3. A tester successfully launches the build on Windows.
4. Version and release notes accurately reflect tested build.
5. GitHub version and Google Drive archive verified.
6. Release-completion email sent with download and source links plus notes to the two established recipients.

## First playtest acceptance checklist

- [ ] Workflow passes headless import and smoke test.
- [ ] Windows build ZIP contains EXE, PCK, README, and BUILD metadata.
- [ ] Windows tester downloads and extracts ZIP.
- [ ] Executable launches on Windows.
- [ ] Click on at least three distinct grid cells; selected pawn and coordinates update.
- [ ] Esc quits.
- [ ] Tester reports any issues; only then promote the engineering prototype to an official alpha release.
