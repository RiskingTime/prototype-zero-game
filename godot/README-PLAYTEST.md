# Prototype Zero — Godot combat playtest

This engineering build contains a Knight-versus-Sword Brute duel with placeholder graphics. HTML v0.13 is the rules reference.

1. Extract the Windows build ZIP and keep `PrototypeZero.exe` and `PrototypeZero.pck` together.
2. Open `PrototypeZero.exe`. Verify that both combatants and their HP are visible.
3. When the Knight is active, click an empty tile to move. The first movement AP covers up to three tiles. Each additional movement AP covers up to two.
4. Click the Sword Brute from an adjacent tile to attack. Check the opposed rolls and remaining HP in the log.
5. Click **End turn** to watch the Brute move or attack. A spent turn also advances automatically.
6. Play to victory or defeat. Use **Restart duel** to play again, or press Esc to exit.

Include the commit in `BUILD.txt` when reporting issues. An official release requires a successful Windows playtest.
