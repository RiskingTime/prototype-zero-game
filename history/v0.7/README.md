# Prototype Zero v0.7

Focus: initiative-order reliability, visible enemy turns, weapon/range consistency, and transparent hit-chance math.

## Changes in v0.7
- Fixed an AI pathing bug that could cause a high-initiative enemy to silently skip its turn when the nearest attack position was more than one movement action away.
- Enemy AI now chooses a reachable tile that actually reduces distance to its target instead of searching only for target-adjacent tiles.
- Enemy turns resolve one action at a time with battlefield/log updates between actions, so an enemy that wins initiative visibly acts before control advances to the next combatant.
- If an enemy genuinely cannot find a legal movement path, the combat log now records that it held position rather than silently skipping.
- Corrected the Cleric's Blessed Mace to a **physical melee attack with range 1**. The mace no longer behaves like a ranged magic attack.
- Ranged magic for the Cleric, if retained later, should be represented as a separate spell or ability rather than being attached to the mace.
- Enemy hover/click feedback in the **Actions** box now shows the hit-chance calculation before commitment: attack bonus, AC or MR checked, d20 roll needed, final hit chance, AP cost, and distance/range.
- The existing Confirm Attack dialog still provides the fuller attack/damage breakdown.

## Main playtest targets
1. Restart encounters until an enemy wins initiative. Confirm that the enemy visibly moves and/or attacks before the first hero turn and that its actions appear in the combat log.
2. Confirm that the Cleric's Blessed Mace shows **Physical**, **Range 1**, and cannot attack distant enemies.
3. Hover enemies with different characters and confirm the Actions box explains the d20 hit calculation clearly.
4. Confirm that out-of-range enemies still show the *potential* hit chance and calculation while clearly explaining that the attack is currently illegal.
5. Confirm that no enemy turn ends silently; if an enemy cannot move, the log should say so.

## Hit-chance rule currently used
Physical attacks roll **d20 + attack bonus vs AC**. Magical attacks roll **d20 + attack bonus vs MR**. A natural 1 always misses and a natural 20 always hits, so displayed hit chance is bounded between 5% and 95%.

Combat math and class attack bonuses remain provisional while the prototype is focused on tactical clarity and interaction reliability.
