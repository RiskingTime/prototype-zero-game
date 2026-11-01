# Development Workflow

## Current phase

Prototype Zero is in browser-based mechanics and UI validation.

HTML, CSS, and JavaScript are being used because they allow fast iteration on rules, interaction design, combat feedback, and debugging without committing to final art or engine architecture.

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
