# Independent glass spheres

The latest direction replaces joined liquid shapes with complete, rigid, round spheres.
Run `godot --path . glass_cluster/main.tscn`. One, two and three spheres are shown in a
nine-second sequence. Two tangent spheres create an eight silhouette; three form a clover-like
triangular arrangement with a small central gap. No neck, membrane or deformation is used.
The earlier studies remain available, and the default game is unchanged.

The shader analytically refracts an orthographic ray at the front and rear of each sphere,
samples a matching procedural backdrop, applies Beer-Lambert-style color absorption, and
blends a Fresnel environment reflection. Broad soft environment light shapes replace painted
surface spots. This is an authored realtime approximation, not path tracing: spheres do not
refract or reflect one another, there are no caustics or contact shadows, and the calculation
assumes the present front-facing orthographic camera. Transparent sphere interactions and
arbitrary game backgrounds would require further renderer work.

The actual Godot recording uses desktop Compatibility rendering on software Mesa at 720x960,
30 movie frames per second. Offline movie recording does not demonstrate realtime device FPS.
No phone hardware has been tested. This scene does not implement collision or change gameplay.

Checks: `godot --headless --path . glass_cluster/main.tscn -- --test-glass` runs 16 assertions
on shape counts, sphere dimensions, and pair tangency. Memory gameplay retains its separate
23-assertion test suite.
