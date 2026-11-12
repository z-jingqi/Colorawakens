# Colorawakens

## Design source

[Original GDD v1.0](docs/GDD-v1.0-original.md) is the user's supplied text, preserved byte-for-byte. Its original title is 《拾色者 Color Bloom》; the repository is named Colorawakens. No design rules have been rewritten.

## Bloom Cascade roguelite demo (current default)

Open `project.godot` and press F5. Five increasingly dense waves, random three-choice upgrades, six stacking powers, delayed chain reactions and a recovering garden. Drag a ball within the bottom panel and release to fire vertically upward with acceleration. Special powers add secondary split seeds and ricochets.

See [demo design, controls and verification](docs/roguelike-demo.md). Run `godot --headless --path . -- --test-rogue` for the focused suite. `--demo` runs an automated real-gameplay pilot, not human playtesting. Phone performance and balancing remain unvalidated. No persistent progression yet.

## Original core MVP (preserved)

Open `gameplay/main.tscn` in Godot 4.6.3 and press F6 to play the earlier three-area version.

- Pick up a colored ball, move it to the desired position in the bottom panel, then release. The ball follows the pointer and launches **vertically upward from that released position**, never diagonally from its rack. Mouse and one active touch are supported. A tap or release outside the bottom panel cancels without spending cooldown.
- Three colors retain independent 0.35-second cooldowns. Exported parameters in `gameplay/main.gd` control initial speed (180 px/s), acceleration (850 px/s²), and maximum speed (1000 px/s). Swept collision prevents tunnelling.
- Any three hits restore an ordinary block, including repeated colors. Red + yellow + blue creates a 130-pixel color burst and chain reactions.
- Three short areas introduce mechanics progressively: Quiet Garden (6 restorations), Stone Path (9, adds 5-hit hard blocks), Blooming Grove (12, adds green + blocks whose completion spreads its final color even without three distinct colors). Fall speeds and spawn cadence vary by area.
- Garden color restoration carries across areas in this play session. Losing retries only the current area; completing all three allows a fresh campaign. No disk save is implemented yet.
- Life, score, best chain, next area, retry, pause and restart are supported. Escape pauses, R starts a fresh campaign. Losing application focus cancels a held ball and pauses.
- Visuals remain lightweight 2D placeholders; the earlier 3D material study is preserved unchanged.

Verification: `godot --headless --path . -- --test-gameplay` runs 34 assertions for drag/release origins, horizontal dragging, vertical acceleration and speed cap, mouse/touch flows, cancel/pause/focus loss, cooldown, collisions, ordinary and special blocks, chaining, three-area progression, garden carry-over, retry and victory.

`godot --path . -- --demo` runs automated drags through the actual input helpers and projectile rules for up to 120 seconds. The recording is automated gameplay, not human or phone playtesting. Phone hardware/touch performance, difficulty and balance remain unvalidated; these values are provisional.

## Godot 3D paint study (preserved experiment)

Open `prototype/main3d.tscn` in **Godot 4.6.3** and run it with F6 (or `godot --path . prototype/main3d.tscn`). The three-color automatic demonstration starts immediately.

- Drag upward and release to shoot toward the pointer; `1`, `2`, `3` choose pink/red, yellow, blue.
- `R` resets; `Space` toggles automatic shots.
- A Blender-authored dense rounded-box mesh (`assets/crystal_block.glb`) slowly rotates and moves. Editable source and reproducible export script are in `tools/`.
- Accelerating color spheres use swept collision against the equivalent rounded-box signed distance function.
- Impacts create short-lived 3D splash droplets and persistent local-space pigment.
- Raised, rounded liquid lobes spread quickly, wobble briefly, then form slow gravity-driven fingers and beads. Displacement and a derived surface gradient give the pigment thickness and wet edge highlights.
- Paint is evaluated in local 3D coordinates, including the bevel, without UV seams or a floating rectangular decal.
- Once all three colors arrive: three thin, short color traces converge close to the block over 1.65 seconds, the pigment fades into a clear crystal-like body and holds for 1 second, then the block disappears into 200 colored particles.
- Repeated colors still paint the block but do not complete the three-color condition. No extra gameplay systems were added.
- The v3 study replaces the flat animated rainbow with visible background transmission, approximate refraction, subtle chromatic edges and studio-like reflection highlights. The dot pattern behind the block deliberately reveals optical distortion.

This is an **effect experiment**, not the complete GDD game: no level flow, rainbow chains, progression, mobile export, sound, or physical fluid solver.

### Limits

The shader supports 16 retained impacts, recycling slots after that. Later paint overlays earlier color; this is not physically accurate pigment mixing. The procedural wetness and spread are artistic approximations. The crystal uses screen-space sampling and artistic reflection bands, not physical volumetric refraction or path-traced crystal. Transparent objects behind it and offscreen content are not supported by this approximation. Performance has not been measured on phones. The burst currently uses 200 individual mesh instances; a mobile version should batch these with MultiMesh/GPUParticles. The 3 ribbon meshes are rebuilt during their 1.65-second animation only. The captured demo is fixed-step video, not a mobile FPS benchmark. Pointer aiming works on the camera plane; no touch-device QA has been performed.

### Verification

Run `godot --headless --path . prototype/main3d.tscn --fixed-fps 60 -- --test` and `godot --headless --path . prototype/main3d.tscn --fixed-fps 60 -- --test-repeat`.

The test runs the actual 3D scene, verifies three swept hits, the unique-color gate, exactly one absorption/color/explosion sequence, and cleanup of transient droplets and explosion particles. The repeated-color run verifies three red impacts do not trigger the sequence. It does not replace graphics QA. The supplied 12-second MP4 was rendered by Godot's Movie Maker using Compatibility/OpenGL with Mesa llvmpipe, then encoded as H.264. A half-second contact sheet and full-size spiral, full-color, and explosion frames were visually reviewed. This is still an effect study rather than a final-art reproduction of the concept image.

### Implementation and licensing

All prototype mesh, shader, and gameplay code was written for this project. No code/assets from Splatoon-Ink, InkPainter, or another third-party implementation were copied. The v3 mesh is exported by Blender 4.3.2 using `blender -b --python tools/build_crystal.py`. The `.blend` source is kept in a Godot-ignored tools directory; runtime loads the portable GLB without requiring Blender. This experiment uses the general local-surface paint concept, not a port of a Unity package.

### v3 reference review

Reviewed InkPainter’s `HeightDrip.shader` (https://github.com/EsProgram/InkPainter), specifically its separation of height, flow direction and normal-dependent spreading. This study uses its own analytic surface field, not copied shader code or a port of its texture simulation. The current liquid still has a stylized viscous/gummy appearance; it is not a faithful Splatoon reproduction. Visual acceptance remains with the user.
