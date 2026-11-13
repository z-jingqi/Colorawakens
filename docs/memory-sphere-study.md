# Memory sphere: natural-light reflection study (revision 3)

## Godot realtime study
Run `godot --path . sphere/main.tscn`. The default game and all earlier demos are preserved.
Revision 3 removes the rectangular highlight sticker, point glint and manually drawn caustic
rings. Reflected and transmitted directions now sample softened disk-area lighting, with a
soft highlight shoulder instead of clipping. View-space normals keep reflections stationary
when the smooth sphere rotates. Color absorption and one internal reflected ray remain.

This is still an unshaded, art-directed analytic optical approximation, not Godot's physical
light solver. It approximates a controlled studio environment and only partially samples the
screen behind it. It does not accurately reflect all scene geometry or other transparent balls.
The prescribed environment must be adapted before game integration. Phone/many-ball performance
has not been measured. The high-resolution SphereMesh is not mobile-optimized.

## Blender offline reference (not realtime output)
Run `blender -b -t 8 --python tools/build_memory_sphere.py` with Blender 4.x.
The script creates a dielectric sphere with Principled transmission, volume absorption,
three actual area lights, a matte floor and an orthographic camera. Cycles traces reflections
and refractions at 512 samples, without denoising (this host lacks OpenImageDenoise).
It saves an editable `tools/source/memory_sphere.blend` and renders
`/tmp/sphere-v3/Blender-memory-sphere.png`. Create that output directory first.
The generated blend is not committed; the complete reproducible source script is committed.

The Blender image is a lighting/material reference, not a model that transfers the same rendered
appearance into Godot. Cycles' light paths, volume absorption, shadows, tonemapping and ray budget
are different from the real-time shader. Current Godot output remains less rich and natural.
Neither study is claimed to reproduce the film or generated concept art.

## Verification
`godot --headless --path . sphere/main.tscn -- --test-sphere` runs three resource/scene checks.
`godot --headless --path . memory/main.tscn -- --test-memory` runs 23 gameplay assertions.
Godot 4.6.3 Compatibility/Mesa movie output was visually checked; fixed-step recording is not
a target-device FPS benchmark. `--capture-sphere` records eight seconds and exits.

Official refraction limits:
https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html
https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html
