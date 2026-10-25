# Prototype Zero v0.8

Focus: opposed attack/defense rolls and attribute-derived combat bonuses.

## Core combat math change
Attack resolution is now an opposed roll rather than a single d20 against a static target number.

- Attacker rolls **d20 + Attack Bonus**.
- Defender rolls **d20 + AC Bonus** for physical attacks or **d20 + MR Bonus** for magical attacks.
- The attack hits only when the attack total is **greater than** the defense total; ties favor the defender.
- An attacker natural 1 always misses.
- An attacker natural 20 always hits and remains a critical hit.
- The displayed pre-roll hit chance is calculated exactly across all **400 possible d20-vs-d20 roll pairs**.

## Attribute-derived bonuses
The old hard-coded +11/+12 attack values and static AC/MR target numbers are no longer used for attack resolution.

### Attack Bonus
**Ability modifier + proficiency**

The 1-10 attribute scale maps directly to modifiers: score 1 = -4 through score 10 = +5 (modifier = score - 5). Current proficiency is +2 for each unit's listed primary weapon/spell.

- Knight Longsword: STR 9 (+4) + proficiency +2 = **+6**
- Archer Longbow: DEX 9 (+4) + proficiency +2 = **+6**
- Wizard Arcane Staff: WIS 9 (+4) + proficiency +2 = **+6**
- Cleric Blessed Mace: STR 4 (-1) + proficiency +2 = **+1**

### AC Bonus (physical defense roll)
**CON modifier + half DEX modifier + armor + shield**

Secondary-attribute halves round toward zero. Current prototype equipment bonuses are intentionally simple: Plate +3, Chain Shirt +2, Leather +1, Heavy Hide +2, Robes +0, shield +1.

### MR Bonus (magic defense roll)
**WIS modifier + half INT modifier + magical equipment**

The Cleric's Sun Amulet currently contributes +1 MR; other listed prototype gear contributes +0 MR unless otherwise noted.

## UI/log changes
- Actions hover now explains both sides of the opposed roll and the exact pre-roll hit chance.
- Confirm Attack shows the attack bonus formula, defense bonus formula, tie rule, natural-roll rules, and the 400-outcome probability.
- Character panels and sheets now show **AC roll**, **MR roll**, and attribute-derived Attack Bonus.
- Combat log records both the attacker d20 and defender d20, their bonuses, final totals, and whether the attack was defended.

## Main playtest targets
1. Compare hit chances across different physical and magical matchups. 95% should now be exceptional rather than routine.
2. Confirm that the Wizard is strong against magically weak opponents but less reliable against the Enemy Mage.
3. Confirm that the Knight is difficult to hit physically but vulnerable to magic.
4. Confirm that the Cleric's low-STR Blessed Mace has appropriately modest hit chances.
5. Expand attack log entries and confirm the opposed-roll math is understandable after resolution.
6. Check whether two-die combat feels exciting and readable or excessively swingy.

## Still provisional
The exact proficiency, armor, shield, and magical-equipment bonuses are balance-test values. Cover, elevation, buffs/debuffs, class abilities, and future equipment can later modify the attack or defense side of the opposed roll.
