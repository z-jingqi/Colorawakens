# Single memory sphere study, revision 2

Run `godot --path . sphere/main.tscn` or open that scene and press F6.
The default gameplay scene and all earlier demos remain unchanged.

The blue sphere uses Godot's SphereMesh (128 radial segments / 64 rings), not Blender.
Revision 2 replaces the blurred mist and point-like highlight with sharper curved softbox
reflections, thickness-dependent blue absorption, a traced entry/exit refraction direction,
one internal reflected path, a restrained lower caustic accent, and a lighter studio backdrop.
The shader combines a procedural studio environment with a small screen-space transmission
contribution. `ior`, `absorption` and `phase` control the optical study.

This is an art-directed approximation for a front-facing orthographic camera. The studio
reflection environment and caustic accent are authored mathematically, not captured lighting
or a physical caustic solver. It does not reproduce the full scene in reflections. Screen-space
transmission is limited to captured opaque content; overlapping transparent game balls need a
separate solution. It is not path tracing, volumetric glass, or film-quality final art. The surface
is clearer than the first sample but the memory-like internal detail remains simple. Integrating
many balls, varying the camera and tuning the high-resolution mesh still require further work.
Phone performance has not been measured; fixed-step video is not a device benchmark.

Reference: Godot's screen-reading and refraction limitations informed this controlled setup:
https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html
https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html
No external shader code or art was copied.

Verification: `--test-sphere` performs three scene/resource sanity checks. The 23-test memory
ball suite is unchanged and passes. Actual Godot 4.6.3 Compatibility/Mesa rendering was reviewed
at several stages, with no shader errors. `--capture-sphere` exits after eight seconds.
