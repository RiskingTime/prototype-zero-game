# Prototype Zero v0.9

Focus: character inventory, interactive equipment, dynamic derived stats, clearer hit-chance wording, and stepped movement.

## Changes in v0.9
- Added an **Inventory** button beside **Back to battlefield** on the character screen.
- Character and Inventory views share the same eight equipment slots: Main Hand, Off Hand, Armor, Amulet, Helm, Gloves, Boots, and Ring.
- Added a party inventory grid with filters for All, Weapons, Armor, Accessories, and Consumables plus sorting by name, type, or slot.
- Inventory items and equipped slots show hover tooltips explaining type, slot, combat effects, and purpose.
- Clicking an inventory item opens a detail panel with its effects and a **current -> after equip** comparison for Attack, AC, MR, and initiative gear bonus where relevant.
- Items can be equipped and unequipped. Replaced equipment returns to party inventory. Two-handed weapons automatically stow the current off-hand item.
- Equipment now changes combat statistics dynamically. Test items include alternative weapons, armor, shields, magical accessories, attack gloves, initiative boots, and rings.
- Added a usable Healing Potion consumable that restores up to 6 HP.
- The Cleric can test a Holy Staff alternative that switches the primary attack from the STR-based Blessed Mace to an INT-based ranged magical attack.
- The Wizard's Arcane Staff now demonstrates a +1 equipment Attack Bonus.
- Attack confirmation now says **HIT CHANCE** rather than simply **HIT**.
- Player and enemy movement now animates one tile at a time along the chosen path rather than teleporting directly to the destination.

## Inventory UI test targets
1. Open a hero character sheet and switch between **Character** and **Inventory**.
2. Hover inventory items and equipped slots. Confirm the tooltips are readable and useful.
3. Equip and unequip several items. Confirm Attack, AC, MR, range, AP cost, damage, and/or initiative change when the gear says they should.
4. Equip a two-handed weapon while holding a shield and confirm the shield is returned to inventory.
5. Test the Cleric's Blessed Mace vs Holy Staff to confirm the primary attack meaningfully changes.
6. Use a Healing Potion after taking damage.
7. Test filters and sorting.

## Movement test targets
1. Move a hero several tiles and confirm every tile step is visible.
2. Watch enemy movement and confirm the same stepped presentation is used.
3. Confirm AP is still charged once for the complete movement action and the combat log records the full path.
4. Confirm movement animation does not allow accidental input during the animation.

## Known prototype limits
- Inventory icons are temporary symbolic icons rather than final art.
- Inventory is currently shared party inventory; encumbrance, gold/value, stack splitting, drag-and-drop, loot pickup, and persistent save/load are not implemented yet.
- Class proficiency restrictions are intentionally simple and will need broader design work as the item catalogue grows.
- Equipment balance values are for testing UI and build trade-offs, not final balance.
