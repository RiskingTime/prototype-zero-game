# Prototype Zero v0.4

Primary goal: make movement and action feedback reliable enough to continue playtesting.

Test first:
1. Hover a legal destination. The route and AP cost should appear without breaking the click.
2. Click the destination. The active character should move immediately, AP should update, and the combat log should record the move.
3. Click an illegal destination. The game should explain why the move cannot happen.
4. Hover an enemy. The game should show range status, hit chance, AP cost, and a reason if the attack is unavailable.
5. Click the character panel in the upper-right to open the first-pass detailed character sheet with equipment slots and combat stats.

Movement remains 4 tiles per AP for this prototype. Combat math is still provisional.
