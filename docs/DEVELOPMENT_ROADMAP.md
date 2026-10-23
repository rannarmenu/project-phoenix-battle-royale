# Development roadmap

## Stage 1 — Local prototype
- [x] Godot 4 project and generated 3D training range
- [x] Basic player movement and aiming
- [x] First-person / third-person camera toggle
- [x] Hitscan shooting, ammo/reload HUD and destructible targets
- [x] On-screen action buttons and initial Android touch movement/aim
- [ ] Open and run in Godot editor; fix parser/runtime issues
- [ ] Test touch behavior and camera collision on a real Android device

## Stage 2 — Shooter feel
- [ ] Proper virtual joystick and smoother touch controls
- [ ] Weapon recoil, muzzle flash, reload animation, hit markers and sound
- [ ] Moving enemy AI, cover behavior and player damage
- [ ] Rigged character, animations, original weapon assets and better UI
- [ ] Pause menu, sensitivity and graphics settings

## Stage 3 — Battle-royale loop
- [ ] Larger map with optimized points of interest
- [ ] Loot, inventory, weapon pickups, ammo, armor and healing
- [ ] Safe-zone shrink, zone damage and match timer
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
Use Godot's Compatibility renderer as the starting point. Prefer efficient geometry and materials, then increase visual quality only after profiling. This prototype is not yet editor-validated, Android-tested, multiplayer-enabled, or APK-ready.
