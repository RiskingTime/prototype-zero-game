# Prototype Zero v0.10

Focus: tactical variety — rich hover information, advantage/disadvantage, prepared spells, directional cover/line of sight, and seeded procedural battlefields.

## Major changes

### Rich tactical tooltips
- Character-sheet attributes, HP, AC, MR, Attack, Initiative, equipment and spells use the same shaded hover-tooltip language introduced for inventory items.
- Battlefield unit hover now shows HP, defenses, equipped attack, selected action/spell, range/AP, exact hit chance, roll modes, cover, status effects and targeting restrictions.
- Terrain tiles have tooltips explaining movement and cover behavior.

### Advantage / disadvantage
- Normal: roll 1d20.
- Advantage: roll 2d20 and keep the higher result.
- Disadvantage: roll 2d20 and keep the lower result.
- Advantage and disadvantage cancel one another; multiple sources do not add more dice.
- Physical ranged weapon attacks have disadvantage whenever any hostile unit is adjacent.
- Exact hit chance accounts for both attacker and defender roll modes.

### Cover, flanking and line of sight
- Soft cover: defender has advantage.
- Hard cover: defender has advantage and attacker has disadvantage. This is intentionally very strong.
- Cover is directional: it applies only when the cover object is in the adjacent tile between defender and attacker.
- Moving to another angle can remove cover.
- Trees and rocks farther along the attack line can block line of sight entirely.

### Cleric spell
- **Healing Light** — 1 AP, range 5, heals `1d6 + INT modifier`, no attack roll, once per turn.
- Cleric uses the same prepared-spell architecture as the Wizard and currently has 2 prepared slots.

### Wizard spells and preparation
Wizard currently has 4 prepared-spell slots and 6 reusable prototype spell scrolls:

- **Arcane Dart** — 1 AP, range 6, 1d6 magic damage.
- **Arcane Bolt** — 2 AP, range 7, 2d6 magic damage.
- **Arcane Lance** — 3 AP, range 8, 4d6 magic damage.
- **Force Push** — 2 AP, range 5, push up to 5 tiles; collision with terrain/unit/map edge deals 1d6 damage.
- **Slow** — 2 AP, range 6, target moves 2 tiles/AP through its next turn.
- **Blur** — 1 AP, self; attacks against the Wizard have disadvantage until the Wizard's next turn.

Spell scrolls appear under the new **Spells** inventory filter. They can be prepared/unprepared but are not consumed in this prototype.

### Seeded procedural maps
New Encounter / New Map chooses a new seed and one of five archetypes:

1. Woodland Clearing
2. Rocky Courtyard
3. Marsh
4. River Crossing
5. Ruined Supply Yard

Terrain generation is feature-based and validated for connectivity rather than assigning every tile independently at random.

Terrain rules:
- Ground: 1 movement point.
- Swamp: 2 movement points.
- Water: impassable.
- Tree: impassable, soft cover.
- Rock: impassable, hard cover.
- Barrels / crates: impassable, soft cover.

**Restart Encounter** preserves the current archetype and seed. **New Encounter / New Map** generates another archetype/seed. The active archetype and seed are displayed in the header for reproducible playtests.

## Primary v0.10 playtest targets

1. Does hard cover feel intentionally powerful without making fights stagnant?
2. Is directional cover easy to understand, and does flanking reliably remove it?
3. Does line-of-sight blocking behave as expected?
4. Does adjacent-enemy disadvantage make bows/crossbows meaningfully vulnerable in melee?
5. Do 1/2/3-AP Wizard damage spells create interesting action-economy tradeoffs?
6. Are Force Push, Slow and Blur tactically distinct and useful?
7. Is Healing Light useful without dominating the Cleric's turn?
8. Is preparing 4 of 6 Wizard spells a meaningful loadout choice?
9. Are the five map archetypes readable, fair and sufficiently different?
10. Do Restart Encounter and visible seeds make problem maps reproducible?
11. Are the richer hover tooltips informative without becoming overwhelming?

## Known prototype limitations

- Terrain uses simple symbols/colors rather than final art.
- Elevation is not yet procedurally generated.
- Enemy AI understands pathfinding around terrain but does not yet make sophisticated cover/flanking decisions.
- Spell scrolls are reusable loadout objects rather than one-use consumables.
- Mana, spell slots/charges, cooldowns and broader spell-resource systems are intentionally deferred.
- High-ground combat effects are not implemented in this build.
- Cover geometry uses a deliberately simple directional rule for testing and will need further refinement as maps become more complex.
