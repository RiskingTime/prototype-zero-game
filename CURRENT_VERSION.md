# Prototype Zero v0.12

Focus: varied encounter openings, tighter movement, slower/persistent dice presentation, critical defenses, universal action-roll presentation, and a clearer character combat summary.

## What changed

### 1. Seeded randomized deployment
- Heroes and enemies no longer use one fixed formation.
- Each encounter seed selects a guarded formation and vertical deployment anchor.
- Party front-line roles (Knight/Cleric) and rear-line roles (Archer/Wizard) stay clustered sensibly.
- Enemy melee and ranged roles are likewise grouped rather than scattered randomly.
- Restart Encounter reproduces the same deployment for the same seed.
- New Encounter / New Map generates a new seed and therefore a new formation.

### 2. Tighter diminishing movement
- Knight, Cleric and Wizard cumulative open-ground movement: **3 / 5 / 7** movement points for 1 / 2 / 3 AP committed to movement.
- Archer cumulative open-ground movement: **4 / 6 / 8**.
- Later movement AP therefore add less distance than the first.
- Slow now uses a reduced **2 / 3 / 4** cumulative movement profile.
- Swamp still costs 2 movement points per tile.
- Legal destination cells now distinguish 1-AP, 2-AP and 3-AP movement zones.
- Movement previews show the active movement profile and resulting AP cost.

### 3. Slower roll presentation that waits for the player
- Opposed attack/defense rolls now have a longer anticipation pause and slower dice animation.
- The final result remains on screen until the player presses **Continue / Return to Battlefield**.
- Enter, Space or Esc can also dismiss the completed roll panel.
- Enemy attacks use the same player-controlled pacing.

### 4. Defender natural 20 = critical defense
- A kept defender natural 20 automatically defeats the attack regardless of totals.
- If both attacker and defender keep natural 20s, defense wins.
- Exact pre-roll hit chances use the same rule.
- The roll panel and combat log identify the result as **CRITICAL DEFENSE**.

### 5. Dice presentation for healing, damage and collision rolls
- Healing Light now visibly rolls its d6 and shows the Cleric's INT modifier.
- Successful weapon/spell attacks now visibly roll their damage dice after the hit roll.
- Force Push collision damage now visibly rolls its d6.
- These effect-roll panels also remain visible until the player dismisses them.
- Deterministic actions still resolve without a dice overlay.

### 6. BG3-style combat summary on the character sheet
- The two compact lower panels now summarize **Offense** and **Defense & Mobility**.
- Offense adapts to the current class/loadout: melee or ranged damage + attack bonus, Wizard prepared spell damage + spell attack, and Cleric Healing Light when prepared.
- Defense & Mobility shows HP, AC Bonus, MR Bonus, movement profile and initiative bonus.
- Each summary row keeps rich hover explanations for formulas and underlying mechanics.

## Recommended v0.12 playtest

1. Restart an encounter and confirm the same seed produces the same deployment; create a New Encounter and confirm formation changes.
2. Test the 3/5/7 and 4/6/8 movement bands, including moving more than once in the same turn and moving after spending AP on an attack.
3. Test swamp and Slow under the new movement economy.
4. Watch several player and enemy attacks. Check whether the slower pacing now creates anticipation without feeling excessive.
5. Confirm the resolved roll panel remains visible until Continue is chosen.
6. Look for a defender natural 20 and confirm it produces CRITICAL DEFENSE even if the attacker has the higher total.
7. Cast Healing Light and confirm its d6 is visibly rolled.
8. Land a weapon/spell attack and confirm damage dice appear as a second visible roll.
9. Review each class's character page and confirm the compact combat summary makes the build easy to read without scrolling.

## Known prototype limitations

- Deployment is formation-based and seeded, but it does not yet score every possible opening position for sophisticated tactical fairness.
- Initiative remains logged rather than using the new action-resolution dice panel.
- Movement-zone colors are prototype indicators and may change during UI refinement.
- The browser prototype still prioritizes rules validation over final art, audio and animation polish.
