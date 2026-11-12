# Bloom Cascade: short-run roguelite demo

## Intent
A low-pressure chain-reaction game: keep the direct drag-and-release controls, add meaningful stacking powers instead of complex aiming. This is a playable experiment, not a balanced release.

## Run structure
Five waves contain 12 / 18 / 24 / 30 / 36 blocks. Choose one of three distinct random upgrades before each wave; powers stack until the run ends. Five lives replenish each wave. A completed run restores the entire garden; replay starts fresh. No persistent currency or meta-progression is implemented in this demo.

Normal blocks still need any three hits. Visible pre-painted seeds prime chain reactions. Hard blocks need five. Bloom blocks spread paint on completion even without three colors. Any three distinct colors produce a delayed radius chain; removed blocks cannot complete twice. Explosions propagate at 85 ms intervals so a cascade unfolds rather than disappearing in a single frame.

## Six powers
- Split Seed: each level adds two child seeds at a primary impact. Children inherit ricochet but cannot split recursively.
- Ricochet: each level adds one targeted bounce. A projectile keeps its visited-block list.
- Color Contagion: any restoration spreads paint. Each level adds one paint hit to each nearby block; additional hits cycle colors.
- Bigger Blooms: +35 px explosion radius per level.
- Quick Hands: shorter independent cooldowns and stronger acceleration.
- Rainbow Heart: every fourth shot initially applies all three colors; stacks reduce the interval to a minimum of two.

Primary balls always launch vertically from the chosen bottom position, accelerating up to a cap. Upgrade-created seeds and ricochets can travel diagonally. This keeps the user's launch rule while making the power interactions legible.

## Running
Open project.godot in Godot 4.6.3 and press F5. Mouse or one active touch: pick up a colored ball, drag within the bottom panel, release. Click an upgrade card to choose. Escape pauses; R starts a fresh run. Focus loss cancels drag and pauses.

The original three-area MVP remains at gameplay/main.tscn. The 3D material experiment remains at prototype/main3d.tscn.

## Verification
- `godot --headless --path . -- --test-rogue`: 33 assertions covering offer uniqueness, choice gating, temporary powers, delayed chains, all six upgrades, split/ricochet interaction, drag/touch launch, acceleration, pause/cancel, special blocks, wave progression, life and replay.
- `godot --headless --path . gameplay/main.tscn -- --test-gameplay`: original 34 assertions.
- `godot --path . --fixed-fps 30 --write-movie demo.avi -- --demo`: deterministic input-helper demonstration with seed 32. Upgrade offers and abilities are the real game rules; the pilot chooses and drags automatically. This is not human playtesting.

Safety budgets: 180 simultaneous shots, 2,048 pending paint events. Descendants cannot recursively split; bounce counters and visited lists terminate shot chains. These safeguards are not proof of phone performance. Difficulty, touch-device feel, GPU performance, progression and long-term replay value remain unvalidated.
