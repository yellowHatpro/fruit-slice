# Fruit Slash — Codex Project Guide

## Product vision

Build **Fruit Slash**, an original, polished 3D arcade game inspired by the
general fruit-slicing genre. The player slices airborne fruit with mouse or
touch swipes, builds combos, avoids bombs, and tries to beat a high score.

Do not copy the Fruit Ninja name, branding, art, audio, UI, level layouts, or
other protected assets. Create an original visual identity and original assets.

## Constraints

- Use Godot 4 and typed GDScript.
- Use only free and open-source tools and assets.
- Do not introduce paid add-ons, APIs, or asset packs.
- Prefer original procedural assets made in Blender.
- External assets must have a verified licence; prefer CC0.
- Keep the initial target desktop-friendly while designing input for mouse and
  touch from the beginning.
- The project must remain usable on modest integrated graphics.

## Available tools

- Use Godot MCP to inspect, create, run, and debug the Godot project.
- Use Blender MCP to create and inspect low-poly fruit, sliced variants,
  materials, collision meshes, and exportable GLB assets.
- Prefer Poly Haven for CC0 materials and HDRIs.
- Prefer CC0-filtered Poly Pizza results when an existing lightweight model is
  suitable. Preserve attribution metadata for any CC-BY asset.
- Use FFmpeg only for automated preview or trailer assembly.

## MVP gameplay

The first playable milestone must contain:

1. A start screen and restartable game loop.
2. Fruit spawned below the play area and launched on randomized arcs.
3. Mouse-drag swipe detection with a visible slash trail.
4. Reliable intersection between the swipe and fruit collision geometry.
5. A sliced-fruit response with two halves, impulse, particles, and sound.
6. Score, combos, three lives, missed-fruit penalties, and game over.
7. Bomb hazards that immediately end the current run.
8. Difficulty that increases gradually without becoming unfair.

Do not expand into shops, accounts, online leaderboards, procedural campaigns,
or multiplayer until the MVP is complete and verified.

## Architecture

Keep gameplay systems small and composable. Prefer this structure:

```text
res://
├── assets/
│   ├── audio/
│   ├── models/
│   ├── textures/
│   └── vfx/
├── scenes/
│   ├── game/
│   ├── objects/
│   └── ui/
├── scripts/
│   ├── autoload/
│   ├── gameplay/
│   └── tests/
└── project.godot
```

Recommended responsibilities:

- `GameManager`: run state, score, lives, difficulty, and restart flow.
- `FruitSpawner`: spawn timing, batches, trajectories, and object selection.
- `SliceInput`: pointer sampling, trail rendering, and slice queries.
- `Sliceable`: contract and state transition for sliceable objects.
- `AudioManager`: pooled one-shot effects and music control.

Use signals for cross-system events. Avoid hard-coded node paths when exported
references, groups, or dependency injection are clearer. Avoid large manager
scripts that own unrelated behavior.

## Asset requirements

- Use GLB as the default Blender-to-Godot interchange format.
- Apply Blender transforms before export.
- Use metres consistently and place object origins intentionally.
- Keep fruit silhouettes readable and materials simple.
- Prefer one material per fruit and texture sizes no larger than 2048 px.
- Provide lightweight collision shapes instead of using render meshes directly.
- Keep source `.blend` files separate from exported `.glb` files.
- Generated or downloaded assets must be reviewed in Blender and in Godot.

## Performance targets

- Target a stable 60 FPS at 1080p on integrated graphics.
- Pool frequently spawned fruit halves, particles, trails, and audio players.
- Avoid per-frame allocations in input and spawning code.
- Cap debris lifetime and maximum active physics objects.
- Prefer baked or simple lighting over expensive real-time effects.

## Working method

1. Inspect the repository and current project state before editing.
2. Make the smallest coherent change that advances the active milestone.
3. Run the project through Godot MCP after gameplay changes.
4. Capture and inspect errors and visible behavior; do not assume success.
5. Fix regressions before adding new features.
6. Keep generated files and imported caches out of version control.
7. Commit-ready changes should be focused and easy to review.

When a decision is underspecified, choose a simple, reversible implementation
consistent with the MVP. Ask the user only when the choice materially changes
the product, external services, licensing, or destructive behavior.

## Validation checklist

Before calling a milestone complete:

- The Godot project opens without import or parser errors.
- The main scene runs without debugger errors.
- A complete game can be started, played, lost, and restarted.
- Rapid swipes cannot score the same fruit more than once.
- Fruit leaving the play area is cleaned up and penalized exactly once.
- Bomb and fruit interactions remain correct under low frame rates.
- UI remains legible at common desktop aspect ratios.
- No paid, unlicensed, or unattributed assets are present.
- New gameplay logic has focused automated tests where practical.

## Definition of done

A feature is done only when its code, scene wiring, assets, runtime behavior,
and error output have all been checked. A generated scene or successful command
alone is not proof. Run it, inspect it, and report any remaining limitations.
