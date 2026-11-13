# Compact spatial glass growth

Run `godot --path . spatial_glass/main.tscn`. This 21-second study grows from one to five
lobes, then rotates the real three-dimensional cluster to show its front, side and back.
The first two centers give an eight outline and the first three an equilateral three-leaf form.
The fourth center is off-plane, touching three existing neighbors like a tetrahedron. Later
centers are selected from intersections of equal-distance spheres around triples of neighbors.
Candidates with insufficient clearance are rejected; minimum distance to the cluster centroid
favors compact growth instead of a long vertical chain. The limit remains eight centers.

The lobe-center spacing is 1.4 with visual radius .78. This deliberate shallow union creates a
continuous neck; 'clearance' means avoiding deep accidental overlaps, not physically disjoint
balls. The mesh and refraction shader use exactly the same three-dimensional center array.
Rotating the model changes occlusion and refraction rather than faking depth in a flat picture.
The camera stays at a fixed scale. Incoming balls approach from outside the cluster along their
outward direction. There is no interior illustration.

This is still a shape experiment, not gameplay: the existing three-color fusion rule is unchanged.
The join event switches to a newly generated single mesh, not a physical merging animation.
The mesh is rebuilt on the CPU, so realtime pauses remain possible; offline capture does not
prove device frame rate. Optical rendering uses an approximate exit-ray march and soft authored
environment reflections, without physical caustics or complete internal-reflection handling.
Concave connections may retain sharp refractive bands. No phone hardware has been tested.

Validation: 48 assertions cover generated center clearance, connected interiors, nonplanar fourth
center, compact first-five bounds and one final mesh surface. Memory gameplay retains its 23
passing checks. Existing samples and default gameplay remain untouched.

Visual review caught hard-edged color patches at grazing/rear angles. The final shader smooths
its artistic fallback around the critical refraction angle and bounds the virtual back-plane
projection to avoid singular direction changes. This improves stability but is deliberately
not a physically correct total-internal-reflection solution.
The exit-ray correction alone still produced overly sharp apparent caustic patches under rotation.
For this study, transmission therefore predominantly uses a stable surface-normal lens warp,
with only a small exit-ray contribution and limited path-length tint variation. This sacrifices
physical accuracy to keep the compound object visually stable while reviewing spatial growth.
