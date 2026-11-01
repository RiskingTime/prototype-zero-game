# Prototype Zero v0.13 — Combat Clarity & Tactical AI

v0.13 is the browser prototype's major combat-readability and tactical-AI pass. It implements the v0.12 playtest feedback items 57–67 and is intended to prove the combat framework before the project transitions toward a Godot vertical slice.

## What changed

### Action labels and confirmations
- Generic **Basic Attack** buttons are replaced by the equipped attack source: e.g. **Mace Attack**, **Longsword Attack**, and **Longbow Attack**.
- Wizard actions continue to use prepared spell names directly.
- Healing/support confirmations are action-aware. Healing Light uses **Cast Healing Light** with a blue primary control rather than an offensive Confirm Attack treatment.

### Zones of control and Opportunity Attacks
- Entering a tile adjacent to an enemy is safe.
- Once a unit is already adjacent to a hostile, further voluntary movement can provoke that hostile's Opportunity Attack.
- Each unit has one reaction per round; the reaction costs 0 AP.
- Forced movement remains exempt.
- **Disengage** is available to an engaged hero for 1 AP and prevents Opportunity Attacks from voluntary movement for the rest of that turn.
- Path previews flag the exact provoking step, show relevant hostile zones of control, and identify likely reacting enemies.
- Clicking a provoking path opens one consolidated **Opportunity Attack Warning** with approximate reaction hit chances before movement is committed.
- Opportunity Attacks use the same opposed-roll presentation as ordinary combat and carry a clear REACTION label.

### Tactical previews before commitment
- Movement hover information now includes AP cost, AP remaining, movement points, destination terrain cost, engagement state, stance-breaking consequences, and Opportunity Attack risk.
- Attack previews continue to expose AP cost, exact hit chance, roll mode and causes, defense type, cover/LOS consequences, and damage profile.
- The goal is that important tactical consequences are visible before the player commits.

### Unified combat-resolution presentation
- Successful attacks now resolve as one continuous sequence:
  **Attack Roll → Defense Roll → HIT/CRITICAL → Damage Roll → final damage/HP result**.
- There is no intermediate Continue click between the hit result and damage.
- The completed attack/defense result stays visible while the damage section appears in the same dialog.
- Continue / Return to Battlefield appears only after the entire action finishes.
- Healing, collision damage, deterministic effects, and Opportunity Attacks use the same core resolution vocabulary and presentation language.

### Tactical enemy AI
- Enemy decisions now use a lightweight tactical scoring system rather than simple nearest-target pursuit.
- The scorer considers expected attack value, kill opportunities, target vulnerability, useful range, cover/safety, threatened-ranged penalties, Opportunity Attack risk, AP efficiency, and role.
- Melee enemies value engagement and pressure on vulnerable back-line heroes.
- Ranged enemies prefer useful distance and avoid unnecessary engagement.
- Enemy decisions can deliberately accept reaction risk when the expected payoff justifies it.
- Important enemy choices leave a short **AI reason** in the combat log to make browser playtesting auditable.

### End-of-encounter playtest summary
- Victory/defeat now opens an encounter summary with map archetype, seed, rounds, party damage, hit rate, healing, and reaction use.
- A per-character table summarizes damage, healing, hits/attacks, damage taken, kills, movement AP, and reactions.
- A rules-based **Tactical Notes** section highlights playtest patterns such as repeated engagement, low-percentage attacks, repeated hard-cover attacks, healing reliance, unused Brace, or provoked reactions.
- Controls allow Restart Same Encounter, New Encounter, or returning to the combat log.

### Character teaching and equipment comparison
- Each hero now has a one-line tactical identity on the character sheet and battlefield inspection.
- Equipment comparisons emphasize changed values rather than unchanged clutter.
- Comparisons call out attack name, damage, AP cost, range, attack/defense changes, hand occupancy, and gained/lost class actions.
- A short **Tactical consequence** sentence explains the practical trade-off.
- Prepared-spell comparison similarly calls out the action gained or lost from the combat bar.

## Rules preserved from v0.12
- 3 AP turns with diminishing movement: Knight/Cleric/Wizard 3/5/7; Archer 4/6/8; Slow 2/3/4.
- Swamp costs 2 movement points per tile.
- Physical ranged weapon attacks suffer Disadvantage while the attacker is threatened by an adjacent enemy.
- Fortify Advantage can cancel threatened-ranged Disadvantage.
- Soft cover gives the defender Advantage; hard cover gives attacker Disadvantage plus defender Advantage.
- Defender natural 20 is an automatic Critical Defense; simultaneous kept natural 20s resolve in favor of defense.
- Seeded maps and seeded guarded deployment remain reproducible with Restart Encounter.

## Primary v0.13 playtest targets
1. Do Opportunity Attack warnings make zones of control understandable before movement?
2. Does entering adjacency feel fair while subsequent movement feels meaningfully constrained?
3. Does Disengage create a useful AP trade-off?
4. Does the continuous attack + damage dialog feel clearer and less click-heavy?
5. Are movement/attack previews informative without becoming too visually noisy?
6. Does the tactical AI make recognizably better choices, and do its logged reasons make sense?
7. Is the end-of-encounter summary useful for diagnosing balance and play patterns?
8. Do one-line hero identities make each role immediately understandable?
9. Do equipment comparisons explain practical trade-offs better than raw stat deltas?
10. Regression-test v0.12 movement, cover, Fortify, Brace, spell preparation, healing, critical defense, seeded maps, and deployment.

## Known / intentional prototype limitations
- Opportunity Attack reactions still use provisional ordinary attack profiles rather than final class-specific reaction abilities.
- Enemy AI is heuristic and deliberately transparent; it is a testing system, not final production AI.
- End-of-encounter Tactical Notes are rule-based thresholds, not an AI strategy coach.
- Mission objective remains elimination only.
- Final art, animation, audio, controller input, save/load, campaign systems, richer objectives, and production presentation remain for the Godot phase.
