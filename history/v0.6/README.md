# Prototype Zero v0.6

Focus: tactical clarity, reliable movement, readable combat outcomes, and single-screen UI discipline.

## Changes in v0.6
- Friendly units can be moved through but cannot be used as movement destinations.
- Movement paths prefer direct, human-readable routes instead of large zig-zags.
- Enemy movement no longer logs zero-distance moves when blocked.
- A player character automatically ends its turn when AP reaches 0.
- Important tactical messages remain visible until the next meaningful click/action instead of disappearing on a timer.
- Initiative is collapsed to a title-only control by default; click to expand the full order.
- Confirm Attack now shows attacker and target details, hit-chance math, AP cost, damage dice, damage range, average damage, and critical damage range.
- Combat log is newest-first again.
- Combat log attack entries now include attack math, damage dice, HP before/after, and defeat causality in the same event.
- Character-sheet Back to Battlefield control has stronger click/hover behavior.
- Sidebar, buttons, text, and battlefield sizing are more defensive against viewport overflow, including Steam Deck-like dimensions.

## Main playtest targets
1. Confirm that a Wizard can move straight through an allied Knight without a zig-zag detour.
2. Confirm that 0 AP immediately advances to the next combatant.
3. Confirm that important tactical feedback persists until the next click/action.
4. Expand Initiative and collapse it again; collapsed state should show only "Initiative".
5. Open Confirm Attack and verify the odds and damage breakdown are useful.
6. Confirm defeat events in the combat log clearly show which attack caused the defeat and the HP transition.
7. Confirm the entire combat UI stays inside one screen without horizontal or vertical page scrolling.
