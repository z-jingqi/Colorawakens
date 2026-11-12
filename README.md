# Colorawakens

## Design source

[Original GDD v1.0](docs/GDD-v1.0-original.md) is the user's supplied text, preserved byte-for-byte. Its original title is 《拾色者 Color Bloom》; the repository is named Colorawakens. No design rules have been rewritten.

## Playable core MVP (current default)

Open `project.godot` in Godot 4.6.3 and press F5. Main scene: `gameplay/main.tscn`.

- Hold one of the three bottom launchers, drag upward to aim, and release. Mouse and single-touch events are supported. Tap without dragging cancels.
- Each color has a separate 0.35-second cooldown. Balls accelerate from 300 to 1000 px/s; swept collision hits the nearest block without tunnelling.
- **Any three hits restore a block, including repeated colors.** Red + yellow + blue triggers a 130-pixel burst that adds the final color to nearby blocks and can chain.
- Blocks descend across six columns. A block crossing the danger line costs one of three lives.
- Restore 12 blocks to finish the garden. Progress changes the garden colors. Score, best chain, win/loss, pause/resume and replay are implemented.
- Simple generated tones distinguish launch, hit and rainbow events. Art is deliberately lightweight 2D placeholder geometry; the earlier 3D experiment remains separate and unchanged.
- Pause button / Escape pauses; R restarts. Play Again resets the full round.

Verification: `godot --headless --path . -- --test-gameplay` runs 18 assertions covering repeated colors, ordinary completion, chained rainbow propagation, range, nearest swept collision, miss, upward constraint, cooldown independence, pause, life loss, victory, replay, tap cancel, drag release and an actual accelerating projectile collision.

`godot --path . -- --demo` runs a 35-second automated gameplay recording using real projectile paths and game rules, not scripted elimination. This is not human playtesting. Phone touch/hardware performance and final balance are not yet validated. The goal count, fall speed, spawn rate and burst radius are provisional. Additional worlds, special blocks, mobile packaging and full music are outside this MVP.

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
