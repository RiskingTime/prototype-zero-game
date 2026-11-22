# Prototype Zero — Godot 4-vs-4 encounter playtest

This engineering build contains the first 4-vs-4 battle with placeholder graphics: Knight, Archer, Wizard and Cleric against a Sword Brute, Light Melee, Bowman and Enemy Mage. HTML v0.13 is the rules reference.

1. Extract the Windows build ZIP and keep `PrototypeZero.exe`, `PrototypeZero.pck` and `BUILD.txt` together.
2. Open `PrototypeZero.exe` and select **New Game** at the gate. Check that the build and seed appear under the turn order at the top, for example `Seed 123456 · Build 1a2b3c4`.
3. Units act in initiative order, shown at the top. On a hero's turn its reachable tiles are coloured by AP cost: green 1 AP, amber 2 AP, red 3 AP. Click a coloured tile to move.
4. Choose an action with the buttons at the bottom or keys 1–4. Legal targets are outlined. Hover over a target to see the hit chance, roll mode, AP cost and dice, then click the unit to act.
5. The Wizard has Arcane Dart, Arcane Bolt, Force Push and Slow. The Cleric's Healing Light targets the Cleric or an ally, once per round.
6. A hero's turn ends at 0 AP or with **End turn**. Enemies then act on their own.
7. Play to victory or defeat. **Restart (same seed)** replays the same battle; **New battle** picks a new seed. Esc quits.

When reporting an issue, include a screenshot showing the seed and build line. An official release requires a successful Windows playtest.

## Guide backdrop (development view)

The same build can show the battle over the Mossgate registration guide instead of the tiles. This view is for checking how painted scenery lines up with the board; a normal double-click always opens the tiled board.

1. Open the extracted folder.
2. Right-click an empty area and choose **Open in Terminal**. On Windows 10, hold Shift, right-click and choose **Open PowerShell window here**.
3. Run `.\PrototypeZero.exe --backdrop=guide`, then select **New Game** at the gate.
4. The tiles are replaced by the guide, and the build line ends with `· Guide backdrop`, for example `Seed 123456 · Build 1a2b3c4 · Guide backdrop`. Include that line in screenshots.

To launch it by double-clicking instead, create a shortcut to `PrototypeZero.exe` and add ` --backdrop=guide` to the end of the shortcut's **Target**.
