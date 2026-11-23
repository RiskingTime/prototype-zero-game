# Development Workflow

## Shared workflow (read first)

Before changing anything, read [`AGENTS.md`](./AGENTS.md). It is the canonical workflow for people and coding agents: roles, approval gates, branch naming, review of the exact commit, report and handoff format, and test conventions. Claude Code loads it through [`CLAUDE.md`](./CLAUDE.md). If this file and `AGENTS.md` disagree, `AGENTS.md` wins.

## Current phase

Prototype Zero is in the Godot phase. Active development happens in `godot/` on the `godot-alpha-0.1` integration branch; see [`GODOT_MIGRATION.md`](./GODOT_MIGRATION.md).

Browser v0.13 (`index.html`, `history/`, `releases/`) is frozen as the rules reference and is no longer developed. The browser release process, browser-stage exit criteria and Godot transition notes below are kept as the record of the browser phase.

## Godot playtest build email (engineering tests)

When a new Godot Windows build passes export in CI and is ready to test, email James and Jeremy. This email announces an **engineering test build**. It can be sent before official release approval. It is not the release-completion email described below, which is sent only for an official release that James has approved.

**From:** `james@markdalemanagement.com`. **To:** `james@markdalemanagement.com` and `JeremyRMulder@gmail.com`. Whoever confirms the build is ready (normally the stage writer) sends it. If that agent can't send email, it puts the finished email text in its report for James.

**Subject:** `[Engineering test] Prototype Zero Godot <version> — Windows build <7-character commit SHA>`

**Before sending, check that:**

- the GitHub Actions run succeeded, including the Windows export step;
- the run's commit is the commit named in the email;
- the download link belongs to that run, and the artifact hasn't expired (artifacts expire 30 days after the run).

**Body, in this order:**

1. **Label.** First line: "Engineering test build, not an official release."
2. **Download.** Put this near the top so it stands out. The default download is the exact artifact link for that run, `https://github.com/RiskingTime/prototype-zero-game/actions/runs/<run-id>/artifacts/<artifact-id>`, which is shown on the run page and in the upload step's log. Say that downloading needs a free GitHub account and sign-in (the repository is public, so no other access is needed), and give the expiry date. Then give the Actions run page, `https://github.com/RiskingTime/prototype-zero-game/actions/runs/<run-id>`, as the fallback (download from its Artifacts section).
3. **Build.** Version as written in `BUILD.txt` (for example, `Godot Alpha 0.1`), the full commit SHA, the branch and the PR link.
4. **What changed** since the last tested build, in a few bullets.
5. **Extract and launch.**
   1. First time only: create a free GitHub account at `https://github.com/signup`, then sign in to GitHub in the same browser.
   2. Download the ZIP from the link in this email.
   3. Right-click it and choose Extract All, into a new folder. Don't run the game from inside the ZIP.
   4. Keep `PrototypeZero.exe` and `PrototypeZero.pck` together in that folder.
   5. Open `BUILD.txt` and check that its commit matches the SHA in this email.
   6. Double-click `PrototypeZero.exe`. If Windows SmartScreen or any other security warning appears, stop and don't bypass it. Reply with the exact warning text (a screenshot helps), and before going any further, confirm that the ZIP came from the Actions run named in this email and that the commit in `BUILD.txt` matches that run's commit.
6. **Playtest.** The numbered checklist for this build, each step with its expected result. For Godot Alpha 0.1: click three different tiles and confirm that the pawn moves and the coordinates update each time, then press Esc and confirm the game exits.
7. **Feedback.** Ask each tester to reply to all with pass or fail for each checklist step, the commit from `BUILD.txt`, their Windows version, the exact text of any warning or error (screenshots help), and anything that was confusing.

**No attachment:** don't attach the build. Gmail blocks ZIP files that contain an `.exe`, whatever their size, so the exact artifact link is the way to get the build.

## Source of truth

GitHub is the canonical code and version-history location.

Google Drive continues to hold planning documents, playtest records, and convenient packaged builds for collaborators.

## Release process

For each meaningful browser release:

1. Finish the intended changes and test the build.
2. Update the current source in `index.html`.
3. Preserve a source snapshot under `history/vX.Y/`.
4. Preserve the packaged ZIP under `releases/`.
5. Update `CHANGELOG.md` and the version-specific README.
6. Commit the release to GitHub.
7. Place the packaged playable build and version notes in the project's Google Drive Game Versions folder.
8. Verify that the GitHub release contents and Google Drive release package match the intended version.
9. Send the release-completion email described below from `james@markdalemanagement.com` to `james@markdalemanagement.com` and `JeremyRMulder@gmail.com`.
10. Record new playtest observations in the Playtest & Feedback Log.

A release is not complete until the GitHub version, Drive package, release notes, and release-completion email have all been completed and verified.

## Release-completion email

Every released game version should generate a concise release-completion email in the same style as the release summary provided in chat.

**Sender:** `james@markdalemanagement.com`

**Recipients:**
- `james@markdalemanagement.com`
- `JeremyRMulder@gmail.com`

**Subject format:**

`Prototype Zero vX.Y — <Release Title> is complete`

**Body format:**
- Open with a one-line statement that the release is complete.
- Summarize the material gameplay, UI, AI, systems, or technical changes in clear bullets or short sections.
- Include the primary playtest targets and any important known prototype limitations when they are relevant to the release.
- Include direct links to the Google Drive playable HTML, release notes, and packaged ZIP, plus the relevant GitHub source/release location when available.
- Keep the email readable enough that a collaborator can understand what changed without opening the attachments first.

**Attachments:**
- the current playable HTML build
- the version-specific release notes / README
- the packaged playable ZIP

Send the notification only after the GitHub and Google Drive release artifacts have been verified. The email notification is part of the release definition of done for all future Prototype Zero game versions.

## Browser-stage exit criteria

Move to Godot when:

- a new player can complete a full battle without live explanation
- move → inspect → attack → resolve is stable and understandable
- core combat rules are no longer changing every build
- major UI bugs and misleading interactions are resolved
- combat outcomes are auditable from the interface and combat log
- basic rules-driven or randomized map generation has been tested
- browser source is modular enough to port without carrying forward a tangled single-file architecture

## Next architecture direction

As the prototype grows, the code should separate into logical responsibilities such as game state, combat resolution, movement/pathfinding, initiative/turn state, enemy AI, UI/rendering, and tests.

## Godot transition

Godot 4 is the planned engine stage after the browser prototype proves the mechanics.

The first engine milestone will be a vertical slice containing one complete tactical encounter with representative art, animation, sound, mouse/controller input, and a Steam Deck-like 1280×800 presentation.
