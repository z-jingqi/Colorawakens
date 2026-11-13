# Single memory sphere study
Run `godot --path . sphere/main.tscn` or open that scene and press F6.
The default gameplay scene and all earlier demos remain unchanged.

A blue, gently floating sphere uses Godot's SphereMesh (128 radial segments / 64 rings).
An original spatial shader provides a tinted screen-space transmission approximation,
slowly moving procedural internal color, Fresnel rim, lower caustic arc and studio highlights.
The dots behind it make background distortion visible. No Blender mesh or external art is needed.
The parameters `tint` and `phase` control color and internal motion.

This is an artistic real-time optical approximation, not physically accurate volumetric glass,
path tracing or a final film-quality asset. The high-resolution test mesh is not yet tuned for
many simultaneous mobile balls. Screen-space refraction cannot show offscreen/transparent content.
Phone performance has not been measured.

`--test-sphere` performs three scene/resource sanity checks.
`--capture-sphere` exits after eight seconds for recording.
Rendered with Godot 4.6.3 Compatibility / Mesa llvmpipe. Video is real engine output,
not a generated concept image or target-device FPS benchmark.
