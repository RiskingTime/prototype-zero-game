# Prototype Zero Changelog

## v0.9 — current
Focus: inventory/equipment interaction, dynamic gear effects, clearer hit-chance wording, and stepped movement.

- Added Inventory beside Back to battlefield on the character screen.
- Added shared party inventory with filters, sorting, hover tooltips, item details, and before/after stat comparison.
- Items can be equipped and unequipped; replaced gear returns to inventory.
- Two-handed weapons automatically stow the current off-hand item.
- Equipment dynamically changes Attack, AC, MR, range, AP cost, damage, and initiative where applicable.
- Added test alternatives including Cleric Holy Staff, armor, shields, rings, gloves, boots, and magical accessories.
- Added usable Healing Potions.
- Attack confirmation now reads HIT CHANCE.
- Player and enemy movement now animates tile by tile instead of teleporting to the destination.

## v0.8
Focus: opposed attack/defense rolls and attribute-derived combat bonuses.

- Replaced static attack-vs-AC/MR checks with opposed d20 attack and defense rolls.
- Attack hits only when attack total exceeds defense total; ties defend.
- Attacker natural 1 always misses; natural 20 always hits and critically hits.
- Hit chance is calculated exactly across all 400 possible d20-vs-d20 outcomes.
- Attack Bonus now derives from the relevant ability modifier plus proficiency.
- AC Bonus derives from CON, half DEX, armor, and shield.
- MR Bonus derives from WIS, half INT, and magical equipment.
- Character panels, attack previews, confirmation dialog, and combat log now expose the full opposed-roll math.
- The old hard-coded +11/+12 attack values and static AC/MR target numbers are no longer used for hit resolution.

## v0.7
Focus: initiative-order reliability, visible enemy turns, weapon/range consistency, and transparent hit-chance math.

- Fixed AI pathing that could cause high-initiative enemies to silently skip their turns.
- Enemy AI now moves to reachable tiles that actually reduce distance to its target.
- Enemy turns resolve one action at a time with visible battlefield and combat-log updates.
- Genuine no-path situations are now logged instead of silently skipped.
- Cleric's Blessed Mace is now a physical melee attack with range 1.
- Enemy hover/click feedback in the Actions box now shows attack bonus, AC/MR, required d20 roll, final hit chance, AP cost, and range/distance.
- Confirm Attack continues to show the fuller attack and damage breakdown.

## v0.6
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
