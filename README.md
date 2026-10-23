# Project Phoenix

A Godot 4 mobile-first 3D shooter prototype with both third-person and first-person camera modes.

## Current prototype scope
- Procedurally created outdoor training arena, cover and simple structures.
- Player capsule with third-person and first-person camera toggle.
- Basic movement, jump, mouse look, raycast shooting, reload, health and ammo display.
- Stationary target bots with health and elimination counter.
- On-screen FIRE, JUMP, RELOAD and CAMERA buttons.
- Compatibility renderer selected as a practical baseline for a wider range of Android devices.

## Controls
- **WASD / arrow keys:** move
- **Mouse:** aim (desktop)
- **Space:** jump
- **F:** fire
- **R:** reload
- **V:** switch first-person / third-person
- **Android touch:** drag the left side to move and the right side to aim; use HUD buttons to fire, jump, reload and switch camera

## Open the project
1. Install Godot 4.x (4.3 or newer recommended).
2. Import this repository folder as a Godot project.
3. Open scenes/main.tscn and run the project.

## Important limitations
This is a learning prototype, not a finished Free Fire clone. It currently has no online multiplayer, lobby, parachute drop, shrinking safe zone, loot/inventory, advanced character animations, production assets, or Android APK build/signing pipeline. The prototype has not yet been verified in the Godot editor or on a physical Android device. Expect additional tuning and bug fixes.

## Roadmap
1. Validate the prototype and refine camera/movement/collision.
2. Add touch joystick and responsive HUD, weapon variety, hit effects and animated bots.
3. Build battle royale systems: map, loot, zone, match lifecycle and win state.
4. Design a server-authoritative multiplayer architecture and test with real clients.
5. Profile on target Android devices, optimize assets and create a signed Android release.
