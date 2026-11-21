# AGENTS.md — Prototype Zero shared workflow

This is the canonical workflow for every coding agent on this repository (Claude, Codex and any auditor). `CLAUDE.md` only imports this file. If another tool's project notes conflict with this file, this file wins until James approves a change to it.

## Project facts

- **Owner and approver:** James.
- **Source of truth:** this repository. Check the repo at a specific commit before drawing conclusions; don't rely on memory or chat history for code state.
- **Integration branch:** `godot-alpha-0.1`. Stage branches open PRs into it.
- **`main`** holds the browser prototype. Draft PR #1 (`godot-alpha-0.1` → `main`) stays unmerged until James approves the merge.
- **Frozen rules reference:** browser v0.13 — `index.html`, `history/`, `releases/`. Never modify these files. Read them to check rules.
- **Engine:** Godot 4.7.2 stable, GDScript. The project lives in `godot/`.
- **Exports:** Windows and Linux builds must come from the same commit. CI currently exports Windows only; a Linux export is a later stage.
- **Current goal:** a small playable battle that Jeremy can launch on Windows, without developer tools, at the Nov 28, 2026 playtest. Work outside that goal needs its own approved stage.

## Roles

- Claude and Codex alternate as **writer** and **independent reviewer**. James assigns the writer for each stage.
- One writer per branch. The reviewer never pushes to the writer's branch.
- Optional auditors are advisory only: they don't push, merge or create issues.
- The default mode is **read-only**. An agent changes the repository only inside a stage James has approved.

## Approval gates

James's explicit approval is required for:

1. Each stage, before implementation starts.
2. Each merge, including draft PR #1 into `main`.
3. Each official release (tag, GitHub release, Drive archive, release-completion email).
4. Each GitHub issue, with its exact title and text approved before it is created.
5. Final artwork, which needs James **and** Jeremy.

Muse, Forms, Sheets and other automations never create GitHub issues.

## Stage lifecycle

1. **Propose** one bounded stage: scope, out of scope, risks, tests and acceptance criteria. One proposal at a time.
2. **Approve:** James approves the stage, assigns the writer, and names the branch and its base commit.
3. **Implement** on the stage branch, starting from the approved base commit. Change only the files in scope.
4. **Open a PR** into `godot-alpha-0.1` and post a report (format below).
5. **Review:** the reviewer reviews the exact commit named in the report and returns a verdict with that full SHA.
6. **Merge** only after James approves.

Branch names start with `godot-`, because CI only runs on `main` and `godot-*` branches. James sets the exact name when approving a stage (Stage 0: `godot-stage-0-workflow`).

## Review rules

- Review the exact full commit SHA, not the branch name.
- Any new push to the branch voids the review. The writer reports the new SHA and the reviewer reviews it again.
- Don't rewrite history (force-push, rebase) on a branch under review.
- The reviewer checks the change against the approved scope and acceptance criteria, runs the checks independently where possible, and states which checks were run and which weren't.
- Docs-only stages are reviewed against a written checklist.
- Code stages: the reviewer drafts acceptance tests from the approved acceptance criteria and hands them to the writer. The writer commits them unmodified, and the reviewer confirms that at review.

## Reports

Every stage report and every review uses this format:

- **Status:** COMPLETE, PARTIAL or BLOCKED.
- **Branch** and **full commit SHA**.
- **PR** and **CI** links, or "no CI run" with the reason.
- **Checks actually run** vs. **checks not run**.
- **Caveats.**
- **Decision needed** from James, if any.
- End with a short **"Paste into Codex"** (or **"Paste into Claude"**) block the other agent can act on.

## Tests and CI

Run Godot headless from the repository root:

```sh
godot --headless --path godot --editor --import
timeout 120 godot --headless --path godot --script res://tests/smoke_test.gd
```

- Test scripts live in `godot/tests/`. They extend `SceneTree`, print a `... PASSED` line and call `quit(0)` on success, and `printerr` a `... FAILED: <reason>` line and call `quit(1)` on failure.
- Always run tests with a timeout. On Godot 4.7.2 a script runtime error or a missing `quit()` leaves Godot running instead of exiting.
- CI (`.github/workflows/godot-windows.yml`) runs on pushes to `main` and `godot-*` **only when `godot/**` or the workflow file changes**, and on manual `workflow_dispatch`. It does not run on pull requests, so docs-only pushes get no CI run.
- CI imports the project, runs `smoke_test.gd`, exports Windows, and uploads an artifact containing `PrototypeZero.exe`, `PrototypeZero.pck`, `README-PLAYTEST.md` and `BUILD.txt` (which records the commit SHA). Artifacts expire after 30 days.

## Builds and releases

- **Engineering builds** are GitHub Actions artifacts. They are not releases.
- **Official releases** need James's approval and follow the release definition of done in `GODOT_MIGRATION.md`. Google Drive archives approved official releases only.
- **Playtest email:** when a Windows build passes export and is ready for James to test, email him as described in `DEVELOPMENT.md` ("Godot playtest build email"). It announces an engineering test, can be sent before official release approval, and is not a release-completion email.
- **Human Windows check** for a build under test: extract the whole ZIP, launch `PrototypeZero.exe`, click three different tiles and confirm that the pawn moves and the coordinates update each time, then press Esc to exit. Record the result together with the SHA from `BUILD.txt`.

## Hard rules

- Never modify the frozen browser v0.13 files: `index.html`, `history/`, `releases/`.
- Without James's explicit approval, never:
  - merge a PR, or push directly to `godot-alpha-0.1` or `main`;
  - create issues, tags, releases, Drive archives or release-completion emails;
  - change scope in the middle of a stage. Propose a new stage instead.
