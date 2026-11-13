# Continuous liquid join, stable compact form

Run `godot --path . fusion_glass/main.tscn`. The 21-second sequence grows from one to five
lobes at the same compact spatial target positions as the preceding study. A new ball comes
from outside the frame on a diagonal 3D path, approaches, forms a short smooth bridge, and
settles into the rigid final form. Each event lasts 1.65 seconds, with approximately .66 seconds
reserved for contact/settling. There is no continuing wobble after settlement. The later view
rotates the actual cluster to expose front/back occlusion.

Unlike the earlier mesh-switch demonstration, the GPU traces the current implicit union surface
each frame. Ball centers and the short contact-curvature pulse change continuously; there is
no replacement mesh at the join boundary. The proxy box is just a ray-entry volume, not the
visible geometry. This is an artistic smooth-union transition, not Navier-Stokes fluid physics,
volume conservation, or a collision simulation. A maximum of eight lobes is supported by the
uniform arrays; this demo shows five. Existing gameplay and the three-color fusion rule are
unchanged. No interior illustration has been added.

## Visual limitations
The accepted compact arrangement is preserved, but transparency is not claimed as solved.
The bright material is an authored procedural-background lens approximation, not a screen
texture and not real transmission of rear balls through front balls. It does not implement
physically correct multi-bounce internal reflections or caustics. Concave seams can retain bright
lines. Ray-marched silhouettes can show slight aliasing. This study evaluates the transition
separately from final material quality.

## Checks and performance
`--test-fusion` samples all four transitions at 99 intervals and checks center movement, blend
parameter continuity, cluster recentering continuity, exact endpoints and stable final targets
(1595 assertions). The existing memory gameplay regression suite remains separate.
`--benchmark-fusion` runs without Movie Maker, discards the first two seconds, and reports
wall-clock frame intervals and CPU script-update time. These are desktop software-renderer
measurements, not phone results. The movie's fixed 30 FPS is an export setting, not a realtime
performance claim. This version trades CPU remeshing for GPU ray marching, whose per-pixel cost
still needs optimization and actual device profiling before integration.

Measured run (720×960, Godot 4.6.3 Compatibility, Mesa llvmpipe software rendering): 167 sampled
frames after warm-up, mean wall interval 129.39 ms (~7.73 FPS), p95 204.32 ms; mean script update
0.098 ms. This is not realtime-smooth on the available software renderer. Movie Maker exported
631 frames at fixed 30 FPS, taking 104 seconds for the 21-second clip. A hardware GPU and mobile
profile are still required; neither 30 FPS nor phone readiness is claimed.

Independent review sampled the first join every .1 seconds and the fourth join's approach and
settling frames: the bridge widens progressively and settles without the previous one-frame
shape swap; the fourth ball approaches from outside the frame rather than popping in. Remaining
visual issues are slight silhouette stair-stepping, limited glass transparency, and partial
occlusion of the fourth join's bridge by the front lobe. The review passes the transition study,
not final material quality, physical-fluid correctness, or device performance.
