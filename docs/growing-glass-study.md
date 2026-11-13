# Count-driven joined glass study

Run `godot --path . growing_glass/main.tscn`. The automated 15-second demonstration grows one
connected glass body from one to five lobes. There is no interior illustration or memory texture.
Blue, pink, gold, mint and violet remain optically colored regions within the continuous surface.

The second ball forms a horizontal figure eight, the third joins above to make a three-leaf
shape, the fourth joins below, and the fifth extends the top. Later additions alternate below
and above. Centers are generated from the existing centers rather than selected from stored
meshes; the shader and mesh both use this center list. The eighth lobe is the implementation
limit, not a game design rule. A separated incoming ball approaches during the last second of
each step; at attachment the unified implicit surface is regenerated.

This is a shape technology demo only. It does not change the game's three-distinct-color fusion
rule. It does not simulate physical collisions, continuous fluid merging or volume conservation.
The approach animation is illustrative, and the join switches from a separate sphere to a newly
built mesh. CPU mesh rebuilding can visibly stall in normal realtime use; offline movie capture
hides wall-clock pauses and is not evidence of mobile FPS. Caching or GPU meshing would be needed
for production. No phone has been tested.

The optical shader is approximate: it ray-marches through the same shape for rear refraction,
uses a procedural matching backdrop and authored soft environment lights, and omits proper
multiple internal reflections, total internal reflection and caustics. Concave joins can show
sharp refractive lines. This is not a final film-quality material.

Validation: `--test-growing-glass` runs 45 assertions on generated positions, clearance,
interior connection and single-surface output up to five rendered lobes/eight layout entries.
The memory gameplay test still has 23 passing checks. Existing scenes and default gameplay
are preserved.
