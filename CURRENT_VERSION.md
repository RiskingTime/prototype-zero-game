# Prototype Zero v0.11

Focus: compact character sheets, class-defining secondary actions, Wizard spell-only action loadout, and animated opposed-roll presentation.

## Changes in v0.11

### Character sheet compression
- Removed the large Primary Attack panel from the active character-sheet layout.
- Main Hand hover tooltips now carry the detailed attack profile: damage, range, AP cost, attack bonus math, and AC/MR context.
- Wizard staff tooltips explicitly identify the staff as a spell focus rather than a separate Basic Attack.
- Reclaimed space is split into two compact panels:
  - Position & Mobility
  - Class Features & Status
- The goal is to keep the full character page readable in one viewport while retaining detailed information through hover tooltips.

### Archer — Fortify Position
- New 1 AP class technique while a physical ranged weapon is equipped.
- Fortify Position prepares the Archer for the following turn.
- The first physical ranged Basic Attack on the next turn has Advantage.
- The stored advantage is consumed by that shot or expires at the end of the turn.
- Voluntary or forced movement breaks Fortify.
- Fortify can be refreshed each turn.
- Advantage/disadvantage continues to use the shared cancellation rule, so Fortify can cancel threatened-ranged disadvantage or the attacker-disadvantage portion of hard cover.

### Knight — Brace
- New 2 AP class technique unlocked by an equipped shield.
- Brace grants Advantage on physical-defense (AC) rolls until the start of the Knight's next turn.
- Brace does not affect MR.
- Unequipping the shield removes Brace availability.
- This is the first prototype of equipment-dependent martial techniques.

### Wizard — prepared spells are the action bar
- Removed the Wizard's generic Basic Attack button.
- The Wizard's four prepared spells now constitute the Wizard's class-specific combat actions.
- Movement and End Turn remain universal controls.
- Changing the prepared spell loadout immediately changes the action bar.
- The Arcane Staff remains a focus that contributes to spell attack math but does not create its own Basic Attack action.

### Animated attack-roll presentation
- Every opposed attack by a hero or enemy now opens a compact roll-resolution overlay.
- The overlay shows:
  - attacker, action, target, attack type and pre-roll hit chance;
  - one d20 for normal rolls;
  - two d20s for Advantage/Disadvantage, with the kept die highlighted;
  - attack attribute, proficiency and gear math;
  - defender AC/MR bonus math;
  - cover, Brace, Blur, Fortify and other roll-mode sources;
  - attack and defense totals;
  - a prominent HIT, DEFENDED or CRITICAL result.
- The combat log remains the permanent audit trail after the animation closes.

## Main playtest targets
1. Confirm the Cleric and Wizard character pages fit comfortably without unnecessary vertical scrolling.
2. Hover Main Hand equipment and confirm no useful attack information was lost when the Primary Attack panel was removed.
3. Archer: use Fortify Position, end the turn, then verify the next ranged Basic Attack has Advantage; move first and confirm the benefit is lost.
4. Archer: test Fortify while threatened by an adjacent enemy and verify Advantage/Disadvantage cancel to a normal attack roll.
5. Knight: with a shield equipped, use Brace and confirm physical attacks against the Knight show defensive Advantage until the Knight's next turn.
6. Knight: remove the shield and confirm Brace disappears from the action bar.
7. Wizard: confirm there is no Basic Attack action and that the action bar contains only the currently prepared spells.
8. Change the Wizard's prepared spell loadout and confirm the combat action bar updates immediately.
9. Watch both player and enemy attacks and judge whether the roll animation creates useful anticipation without slowing combat too much.
10. Verify normal / Advantage / Disadvantage attacks display the correct number of dice and clearly indicate the kept roll and modifier math.

## Known / deliberate prototype limitations
- The roll-resolution sequence is intentionally not yet user-configurable or skippable; v0.11 is testing the default pacing first.
- Fortify applies to the first physical ranged Basic Attack only, not spell attacks or future special shots.
- Brace currently represents the sword-and-shield defensive technique; two-handed Knight techniques such as Power Strike remain future tests.
- The browser prototype remains a rules laboratory; final animation, art, audio and controller presentation will be revisited in Godot.
