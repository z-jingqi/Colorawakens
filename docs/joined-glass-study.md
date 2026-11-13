# Continuous rigid glass shapes

Latest correction: a single continuous glass body, not separate round balls and not soft liquid.
The pair is a waisted figure eight; the triple is a connected three-leaf shape. All silhouettes
are rigid. The only motion is whole-object gentle vertical translation. There is no wobble,
neck stretching, fluid simulation, collision sequence, or change to gameplay.

Run `godot --path . joined_glass/main.tscn`. The nine-second sequence presents one, two, three
lobes. The shape uses the existing smooth-union polygonizer, but the material marches a ray
through the same implicit form to approximate rear-surface transmission, with colored absorption
and broad environment reflections. A brighter environment/background prevents the previous
muddy, dark colors. The backdrop is procedural and matches the refracted sample.

This is an optical approximation tailored to an orthographic front-facing camera. Internal
multiple reflections, proper total internal reflection, caustics and arbitrary game backgrounds
are not implemented. The surface is a single mesh, not a production collision system. Movie
capture is actual desktop Godot Compatibility rendering, not proof of realtime phone performance.
No mobile hardware verification has been performed.

Validation: `--test-joined-glass` checks three surfaces and connected interior fields (7 assertions).
The separate memory gameplay suite remains 23 assertions. Default game and old studies are preserved.

## Reference and review
Actual official image references were inspected from https://www.pixar.com/inside-out and
https://www.pixar.com/inside-out-2 (also https://press.disney.co.uk/gallery/inside-out-2).
The target is a bright colored memory interior inside a clear shell, not empty photographic glass.
The eight/clover shape is the user's design, not a claim about the film. This study reuses the
project's original `memory/scene.svg` as an authored inner image layer; it does not embed movie
artwork. The interior is a shader composition, not geometry inside the glass. Saturated body
color, a brighter rim and wider softer top reflection are used to approach that visual language.
The result remains a simplified game prototype, not movie-quality reproduction.

An independent visual review found the silhouette and brighter blue/pink/gold direction usable
as a study, but not movie-quality: the inner artwork read too flat and repeated, and the waist
retained sharp refractive lines. The final iteration reduces image dominance, adds radial
curvature distortion, softens sampling and offsets each lobe's framing. Remaining limitations
include the planar source image, authored highlights and neck artifacts. This is a proposed
visual experiment; the user has not approved interior artwork as a final design requirement.
