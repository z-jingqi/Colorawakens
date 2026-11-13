# Soft floating liquid study

This separate study follows the revised art direction: soft droplets rather than hard glass
marbles. Two joined drops have a figure-eight waist; three have a three-leaf outline. The
original game, memory-ball demo and earlier sphere studies remain unchanged.

## Godot
Run `godot --path . droplets/main.tscn`. The nine-second automated presentation shows one,
two and three lobes in turn. It is a sequence of three shape studies, not a collision/merging
simulation. A small animated surface deformation adds gentle softness.

Each shape is one continuous smooth-union signed-distance surface, polygonized with marching
tetrahedra. This avoids overlapping transparent sphere shells at the joins. Normals are derived
from the field; an artistic surface shader supplies color regions, Fresnel reflection and
screen-space transmission. It is not a Navier–Stokes/SPH fluid simulation or physical pigment
mixing. Volume is not conserved during the decorative deformation. Normals approximate the
undeformed surface. The colors and poses are studies, not final gameplay rules.

The runtime transmission is a simplified screen warp, not Blender's ray-traced interior.
Opaque background detail is available; other transparent balls and offscreen content are not.
The presentation has not been integrated into gameplay. Startup CPU mesh generation and
per-pixel optical work need profiling and a production asset/caching strategy before mobile use.
No phone testing or many-ball FPS claims are made.

`--test-droplets` runs seven checks for the generated shapes, continuous join field and outside
field. `--capture-droplets` exits after nine seconds. The 23 memory gameplay tests remain passing.
Actual Godot renders of all three poses were inspected for shape and continuity.

## Blender reference
`blender -b -t 8 --python tools/build_soft_droplets.py` builds independent continuous surfaces,
original blue/pink/gold color regions, dielectric liquid material, real area lights and Cycles
rendering. It saves `/tmp/soft-droplets/soft_droplets.blend` and
`/tmp/soft-droplets/Blender-soft-droplets.png`.
This offline image is a material and shape reference, not the Godot rendering or a guarantee of
identical appearance after import. The editable source is the committed build script.
