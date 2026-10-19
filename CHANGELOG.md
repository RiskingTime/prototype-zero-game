# Prototype Zero Changelog

## v0.6 — current
Focus: tactical clarity, reliable movement, readable combat outcomes, and single-screen UI discipline.

- Friendly units can be moved through but cannot be movement destinations.
- Movement paths prefer direct, human-readable routes.
- Enemy zero-distance move logging was removed.
- Player turns automatically end at 0 AP.
- Important tactical messages persist until the next meaningful interaction.
- Initiative collapses to a title-only control by default.
- Confirm Attack shows richer attacker/target details, hit math, and damage information.
- Combat log uses newest-first ordering.
- Attack log entries include attack math, damage, HP before/after, and defeat causality.
- Back to Battlefield behaviour and responsive single-screen layout were strengthened.

## v0.5
Focus: pathing, persistent tactical feedback, compact initiative, and character-sheet refinement.

- Movement routing was revised toward simpler paths.
- Invalid actions gained persistent explanations and logging.
- Initiative became a compact expandable control.
- Standalone Attack Info was removed.
- Character-sheet details were expanded.
- Back to Battlefield behaviour was strengthened.

Historical note: v0.5 experimented with oldest-first combat-log ordering; v0.6 reversed that decision.

## v0.4
Focus: movement reliability and action feedback.

- Movement preview and commitment were separated.
- Legal movement clicks were intended to commit immediately.
- Illegal movement clicks explain failure.
- Enemy hover exposes range, hit chance, AP cost, and failure reasons.
- First-pass detailed character sheet added.

## v0.3
Focus: restore the core playable loop.

- Separate Move mode/button removed.
- Direct board movement added.
- Hover path and AP-cost previews added.
- Enemy hover exposes range, hit chance, and attack cost.
- Legal enemy click opens attack confirmation.
- Unit inspection improved.

## v0.2
Focus: first major usability pass.

- Combat UI compressed toward one 16:9 viewport.
- Expandable initiative audit log added.
- Movement highlights and path previews added.
- Attack confirmation and hit-chance preview added.
- Battlefield result feedback improved.
- Grid coordinates A–O and 1–15 added.
- Contextual interaction guidance added.

## v0.1
First playable mechanics build.

- 15×15 tactical grid
- four heroes
- generic test enemies
- 3 AP turns
- individual initiative
- physical attacks vs AC
- magical attacks vs MR
- HP, damage, critical hits, and automated enemy turns
