# Prototype Zero

Prototype Zero is an experimental, party-based, turn-based tactical fantasy RPG being developed in public.

The project is currently in the **browser-prototype phase**. The purpose of this phase is to prove the combat loop, tactical information, movement, attacks, initiative, action points, defenses, and user interface before committing to a full game-engine implementation.

## Current status

- **Current playable build:** v0.9
- **Current technology:** HTML, CSS, and JavaScript
- **Current focus:** interactive inventory/equipment, dynamic gear effects, stepped movement, UI clarity, playtesting, and bug fixing
- **Next technical step:** modularize the browser code as complexity grows and add repeatable regression testing
- **Planned engine:** Godot 4
- **Long-term target:** a Windows / Steam Deck game published through Steam

The browser prototype is intentionally lightweight. It is a rules laboratory, not the final presentation layer.

## Play the current build

The current browser build is [`index.html`](./index.html).

Download it and open it directly in a modern desktop browser. No installation or server is required.

Historical packaged builds are preserved in [`releases/`](./releases), while source snapshots and notes are preserved in [`history/`](./history).

## Game concept

The working vision is a four-character tactical fantasy RPG built around:

- individual initiative
- a 3 AP turn economy
- movement, positioning, range, cover, and elevation
- separate physical and magical defenses
- strong class identity and equipment restrictions
- transparent hit chances and combat math
- specialization with meaningful counters and trade-offs
- a fixed cast of deeper characters rather than disposable generic recruits
- branching roleplay, lore, factions, religion, politics, and story systems later in development

The design draws inspiration from tactical and role-playing games such as XCOM, Baldur's Gate 3, Pathfinder: Wrath of the Righteous, Jagged Alliance, and tabletop fantasy RPGs, while developing its own systems and setting.

## Development roadmap

1. **Browser prototype** — prove the combat loop, UI, and core mechanics.
2. **GitHub / architecture** — preserve source history, modularize code, add tests, and support additional contributors or AI agents.
3. **Godot vertical slice** — port the proven combat systems into Godot and introduce representative art, animation, audio, controller support, and real game scenes.
4. **Alpha systems build** — expand encounters, AI, progression, inventory, dialogue, lore, story, and save/load.
5. **Steam / Steam Deck hardening** — controller UX, 1280×800 layout, settings, performance, packaging, and QA.
6. **Publishable v1** — finish content, polish, testing, and Steam release preparation.

There is still a long way to go. The point of the current prototype is to answer expensive design questions cheaply before building the final game.

## Repository structure

- `index.html` — current playable browser build
- `CURRENT_VERSION.md` — current build notes
- `history/` — historical source snapshots and version notes
- `releases/` — original packaged ZIP builds
- `CHANGELOG.md` — release-by-release summary
- `DEVELOPMENT.md` — development and release workflow
- `LICENSE` — MIT License

## Collaboration

The project is public because the goal is to learn, experiment, and build something interesting rather than protect proprietary technology. Playtesting, design discussion, lore/story ideas, code review, and future contributions are welcome as the project matures.

## License

Code in this repository is available under the [MIT License](./LICENSE).
