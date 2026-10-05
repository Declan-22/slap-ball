# Slap Ball (working title) — Plan v1

> Wii-like arcade Roundnet-inspired game in Godot. Toon style like Just Volleyball, but NOT volleyball. Ground net, dives, walls, perfect sets, tiki-taka. 1-4 players, solo-first.

## Pillars
1. **Clutch dives** — diving save from certain death is the core fantasy.
2. **Brick-wall defense** — double-dive / positioning to shut a side down, at a cost.
3. **Perfect sets** — timing-based set quality unlocks better spikes.
4. **No ball hogs** — you cannot hold. 3-touch rhythm forces passing.
5. **Contained + readable** — like volleyball: fixed powers, skill is where/when, not how hard.
6. **1 → 2 → 4 players** — fun solo at 2am, great 1v1, perfect 2v2. No big lobbies required.

## What we rejected (and why)
- **Team handball 7v7**: 3-step / 3-sec whistles, 14 humans needed, AI teammate hell, solo boring. BANNED for now.
- **Volleyball clone**: perfect loop but direct ripoff risk with same toon style.
- **Soccer / futsal full-field**: ball-on-ground chaos, too many options, AI-heavy.
- **Racquets**: not enough tactics (positioning/faking).
- **Dodgeball / Tchoukball / Beach handball / Net handball / 7m duel**: pitched, rejected.
- **Real Spikeball analog power**: extreme precision on every touch = frustrating. Fixed by discrete powers below.

## Core game: Arcade Roundnet v1
2v2 around a ground trampoline net. 3 touches max to return onto net. No catch/hold.

### Net — bigger + zoned (hybrid sim)
- Real net ~90cm. Ours: **130-140cm diameter**, slightly bigger ball for readability. (Was 140-180cm — shrunk so you can get around it.)
- **No rim faults.** Full sweet spot. Faults only on clean miss.
- 3 zones (feels simmed, actually tuned):
  - **Center**: clean high bounce, predictable. Safe.
  - **Mid**: flatter faster skip. Aggressive.
  - **Rim pocket**: low sticky dribble. Killer if intentional, fault risk if you miss it.
- Angle matters: steep in = high up, flat in = low skip.
- Angle caps: normal spike max ~±60°. Extreme opposite-corner cuts only unlock on Perfect set + high fault risk.
- Implementation: shaped net collider (concave + rim torus, different restitution/friction) + heavy ball + substeps. Deterministic, no wind. Pocket = high-friction / low-bounce ring, not random.

### Ball physics — heavy, not light
- Real Spikeball ~100g floaty. Ours behaves like volleyball 260-280g.
- Fixed flight times **0.6-0.9s** between touches for readability.
- No full cloth sim. Net = trigger/collider that kills velocity and relaunches on fixed arc toward aim zone + zone modifier.
- Manual projectile between touches (not Jolt chaos). Dive pickup = generous sphere.
- No wind, consistent bounce height.

### Touches — fixed power, varied situation
Input power is FIXED (volleyball-like). Situation creates variety.

- **Touch 1 = DIG**: fixed pop-up. Direction via left stick only.
- **Touch 2 = SET**: fixed high arc next to net. Timing → Perfect (glows, unlocks cuts) or Okay.
- **Touch 3 = SPIKE**: fixed speed. Aim among 5 zones: left / straight / right / drop / deep cut + fake (look one way, hit other).

Situation modifiers:
- Standing dig = clean, 5-zone aim.
- Diving dig = heroic save, auto high pop, only 2-3 zones + spread. You lived, gave them a good ball.
- Jump set = faster perfect window.
- Off-balance / low set = wobbly, smaller spike window.
- Steep spike into net = higher bounce, more defendable.
- Flat spike into pocket = low skip, killer but fault risk.

No power meter. Flick = *which* shot, not how hard.

### Defense
- **Dive**: one button + i-frames + big pickup sphere 0.25s. Miss = grounded 1s. The clutch button. Dive reach means you don't always have to run around the net.
- **Hurdle**: press jump at net to vault over to other side. 0.7-0.9s, can't hit mid-air, 0.3s landing recovery. Use to chase cuts. Fake-bait = death. Fun toon visual.
- **Wall**: both defenders commit same side → boosted block radius, other side open. Risk/reward.
- Body blocks: allowed by positioning, no complex rules.

### Scoring / faults (v1 proposal)
- Score to 15, win by 2 (tune: 11 for fast, 21 for long).
- Faults: miss net, double-hit, >3 touches, illegal block. No rim faults.
- Sides soft-locked (not full 360) for camera readability. You own a half, rotate within it. Cross only via hurdle, not run-through.

## Modes
- **Solo (2am test)**: survival (AI peppers you, dive streak), target zones, serve+set tutorial.
- **2 players**: 1v1 duel (smaller net, 2 touches max, faster) + 2v2 co-op vs AI.
- **4 players**: real 2v2, no bots.
- **Later / party**: 3v3 chaos bigger net, King-of-net 2v2v2 rotation. NOT launch.

## Controls (Wii-like)
- Left stick: move.
- One button Hit: context = dig/set/spike. Tap = normal, flick direction = pick zone.
- Y: fake.
- B: dive.
- A / Space near net: hurdle vault over net.
- Aim assist snaps to 5 zones. No pixel hunting.

## Camera
- Side view like Just Volleyball OR low third-person behind your team. Net always readable. TBD in prototype. Sides locked to make this work.

## Style
- Toon + smooth like Just Volleyball inspiration, but differentiate: own palette / mascots / font (NOT comic sans clone). Same vibe = Wii Sports series, not ripoff, as long as sport is different.

## Build order (gray boxes, no art)
1. **Net bounce alone**: ground + net zones + test ball. Shoot from steep/flat/pocket. Tune until readable.
2. **One mover + one hit**: capsule, auto-face net, fixed dig/set/spike cycle. Hit back onto net yourself. Proves camera.
3. **Dive**: add dive + pickup sphere. Throw ball away, dive-save it. If not fun here, kill.
4. **One dumb AI**: returns to center. Rally to 5. First real loop.
5. Then: scoring, 1v1 duel, 2v2, sounds, art.

## Open questions
- Scoring: 11 / 15 / 21?
- Powers/meter or pure skill? (lean pure skill)
- Camera: side vs low 3rd person?
- Net exact sizes: 130 vs 140cm? Ball size?
- Dive cooldown / stamina? Hurdle cooldown?
- Perfect-set timing window ms?

## Next step
Build step 1 in-project: gray court + zoned net + test ball.
