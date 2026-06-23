# Fortress TicTacToe

Dark red fortress-themed Roblox TicTacToe project managed with Rojo and Rokit.

## Commands

Install pinned tools:

```bash
rokit install
```

Run all local checks:

```bash
scripts/verify.sh
```

Start Rojo in the background:

```bash
scripts/start-rojo.sh
```

Stop background Rojo:

```bash
scripts/stop-rojo.sh
```

Build a place file:

```bash
rojo build -o /tmp/fortress-tictactoe-game.rbxlx
```

## Studio Workflow

1. Run `scripts/start-rojo.sh`.
2. Open Roblox Studio.
3. Connect the Rojo plugin to `localhost:34873`.
4. Press Play.

You spawn in a dark red fortress hall. Walk to the war table, press `E`, and play TicTacToe against the seated AI commander.

## Community Models

The game uses a curated set of free Creator Store models for the fortress gate, wall, table, throne, torches, braziers, and guard statues. Their asset IDs live in `src/shared/CommunityAssets.luau`.

At runtime the server loads them with `InsertService`, removes embedded scripts, anchors the geometry, and places them under `Workspace.CommunityFortressModels`. If a Creator Store asset cannot load, the source-owned procedural fortress pieces still build so the game remains playable.

## Theme Palette

- Obsidian: `#10090B`
- Bloodstone: `#3A0D12`
- Crimson: `#8B1E24`
- Ember: `#E8502E`
- Gold: `#D6A64F`
- Bone: `#F2DEBD`
- Smoke: `#6B5A58`
