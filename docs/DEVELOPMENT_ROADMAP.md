# Development roadmap

## Stage 1 — Local prototype
- [x] Godot 4 project and generated 3D training range
- [x] Basic player movement and aiming
- [x] First-person / third-person camera toggle
- [x] Hitscan shooting, ammo/reload HUD and destructible targets
- [x] On-screen action buttons and initial Android touch movement/aim
- [x] Add automated Godot 4.7.2 regression tests for arena, camera, bots, combat systems, loot, inventory, safe-zone behavior, joystick clamping, sprint toggle and five weapon profiles/ammo persistence
- [x] Verify latest automated baseline on GitHub Actions (Godot 4.7.2 import + gameplay smoke test; run 40008888210 passed)
- [ ] Test touch behavior, visual joystick, camera collision and sustained performance on a real Android device (not yet verified)

## Stage 2 — Shooter feel
- [x] Dynamic visual virtual joystick with clamped movement direction (headless-tested)
- [x] Mobile sprint toggle and action buttons isolated from aim-touch area
- [ ] Verify joystick rendering, aim feel and button layout on a real Android device
- [ ] Weapon recoil, muzzle flash, reload animation, hit markers and sound
- [x] Moving enemy AI, player damage and respawn
- [ ] Advanced enemy cover behavior / pathfinding
- [ ] Rigged character, animations, original weapon assets and better UI
- [ ] Pause menu, sensitivity and graphics settings

## Stage 3 — Battle-royale loop
- [ ] Larger map with optimized points of interest
- [x] Ammo, medkit and armor pickups with inventory caps
- [x] Medkit healing and armor damage reduction
- [ ] Loot containers, multi-slot inventory, and weapon pickups
- [x] Safe-zone shrink, boundary ring, HUD status and outside-zone damage
- [ ] Multi-phase match timer, final circle and match-end conditions
- [ ] Match phases, kill feed and victory/defeat screen

## Stage 4 — Multiplayer
- [ ] Choose authoritative server architecture and hosting budget
- [ ] Player identity, lobby/room flow and matchmaking
- [ ] Server-validated movement, shooting, damage and inventory
- [ ] Reconnect handling, latency compensation and abuse mitigation
- [ ] Test with multiple clients and different network conditions

## Stage 5 — Android release
- [ ] Profile CPU, GPU, memory, battery and thermals on target devices
- [ ] Add scalable quality presets and resolution options
- [ ] Android export preset, package ID, permissions and signing
- [ ] Build and test signed APK/AAB on physical devices
- [ ] Privacy policy, crash reporting and release checklist

## Performance direction
Use Godot's Compatibility renderer as the starting point. Prefer efficient geometry and materials, then increase visual quality only after profiling. Godot 4.7.2 headless import and gameplay smoke tests pass (latest verified run: https://github.com/rannarmenu/project-phoenix-battle-royale/actions/runs/40008888210). This is an automated baseline, not proof of Android device behavior. Physical Android testing, online multiplayer and APK/AAB packaging remain outstanding. Work is to proceed in stage order, with a passing test gate before each stage is considered complete.
