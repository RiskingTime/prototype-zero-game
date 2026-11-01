# Prototype Zero — Godot Alpha 0.1 (engineering test)

This is a **pipeline test**, not the first official gameplay release. HTML v0.13 remains the reference for combat rules.

## Windows playtest steps

1. Download the Windows build ZIP from the successful GitHub Actions run.
2. Extract **all** files into a folder on your Windows PC. Do not run from inside the ZIP.
3. Keep `PrototypeZero.exe` and `PrototypeZero.pck` together in the same folder.
4. Double-click `PrototypeZero.exe`.
5. Click different battlefield tiles. The blue placeholder moves to the chosen tile and the tile coordinates update.
6. Press Esc to exit.

## What success means

- The game starts and shows a simple tilted, orthographic 3D battlefield.
- Left-clicking a tile moves the blue placeholder to that tile.
- The status text shows the selected cell.
- The game exits normally using Esc.

There are no attacks, action points, animations, pathfinding, AI, or save files in Alpha 0.1.

## If it doesn't run

Report your Windows version, any error message, whether the EXE and PCK are together, and the build SHA in `BUILD.txt`. Some unsigned early builds may show a Windows SmartScreen warning; confirm file origin before choosing whether to run it.

Do not mark this as an official release until the Windows executable has been run successfully on a Windows computer and the release checklist has been completed.
