# Memory Bubbles: independent playable prototype

Run `godot --path . memory/main.tscn` (or open that scene and F6). The original default roguelite, three-area MVP and 3D studies are unchanged.

## Confirmed design
- Single-color balls continuously fall from above.
- One current ball is centered at the bottom; two smaller balls on the left preview the next two colors, in order. This is a queue, not three freely selectable launchers.
- Hold the current ball, drag horizontally within the lower panel, then release. It launches vertically upward from that position, with the previous accelerating projectile behavior preserved.
- A shot sticks to a falling ball/cluster. Falling clusters also stick to one another on contact.
- A connected cluster containing red, yellow and blue fuses into one rainbow ball. Three balls of only one or two colors do not fuse; duplicate colors remain attached.
- Attached groups fall at a faster **constant** speed: 34 + 24 × (ball count - 1) pixels/second, capped at 130. There is no gravity or time-based fall acceleration.
- Each rainbow ball restores a piece of the memory background. Restoring all twelve pieces completes this demo.

## Explicit provisional decisions
The exact rainbow-ball/background impact was not finalized. This demo automatically curves each fused ball into the next gray background patch, shrinking it to imply movement into depth; impact spreads color through a soft circular mask. The final reveal fills residual seams. This is a temporary presentation, not a locked design.

There are no permanent penalties or extra upgrade rules: missed clusters leave the playfield and more balls keep arriving. This allows the fusion/reveal loop to be assessed independently of an unconfirmed loss condition. A shuffled color bag avoids very long repeats. Spawn pattern, speed, 12-patch goal and all timings are trial values.

Mouse and a single touch are supported. A tap or release outside the bottom zone cancels without consuming the queue. Escape/top-right pauses, R restarts, and focus loss pauses and cancels an active drag. A completion button restarts.

## Tests and evidence
`godot --headless --path . memory/main.tscn -- --test-memory`

The focused assertions cover the three-item queue, fixed single/attached fall speeds, speed cap, distinct colors vs duplicate colors, fusion and reveal, release position, vertical accelerating shots, queue advancement, cancellation, pause/resume, swept collision, cluster merging, misses, completion and reset.

`godot --path . memory/main.tscn -- --demo-memory` runs an automated pilot through the same drag/release helpers and collision rules. This is real simulated gameplay, not human playtesting. Target-phone touch, performance and difficulty balance have not been validated.

Art: an original lightweight vector park illustration and procedural glossy balls. No Inside Out or Splatoon assets are used. This is a 2D gameplay prototype, not a final glass material study.
