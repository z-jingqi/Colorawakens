# Joined cluster to colorful memory sphere

Run `godot --path . colorful_fusion/main.tscn`. This independent 22-second study preserves the existing gameplay entry.

The first 12 seconds reuse continuous joining into the accepted compact five-lobe 3D cluster. After a one-second hold, its centers follow inward corkscrews over five seconds and continuously merge into a single spherical surface. The final sphere is held and gently turned for four seconds. The surface is never swapped for a disconnected replacement mesh.

Final color comes from five spatial color pools with a warped coordinate field: blue, pink, gold, green and purple. These are irregular soft regions, not a hue ramp or evenly spaced rainbow bands. There is no interior illustration. The previous Pixar official memory-sphere reference informs bright color and soft highlights; no film imagery is embedded.

This is authored shape animation, not fluid simulation or volume conservation. The existing procedural-background optical approximation remains: it cannot transmit the actual scene or rear spheres. The finish still reads more solid than the desired transparent film reference, and edges retain slight aliasing. The spiral is the motion of the colored lobes, not added ribbon effects.

Checks: `--test-colorful` runs 2198 assertions covering joins, collapse samples and final single-center endpoint. The separate memory gameplay regression has 23 passing checks. Movie Maker produces 30 FPS offline footage; that does not establish real-time or mobile performance.

Independent visual review sampled joining, the five-second collapse at 0.5-second intervals and dense transition frames. The join/rotation/single-sphere sequence is continuous; final regions are irregular, not rainbow bands. Remaining limitations: the spiral reads as a rotating, shrinking cluster more than physically twisting liquid; the color resembles soft glazed material and transparency is insufficient.

Non-recorded benchmark on 720×960 Mesa llvmpipe software renderer: 187 sampled frames, mean 134.75 ms (~7.42 FPS), p95 275.55 ms, mean script update 0.218 ms. This is not real-time smooth and must be profiled/optimized on target hardware before gameplay integration. No phone result is available.
