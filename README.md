# Project Phoenix

A Godot 4 mobile-first 3D shooter prototype with a camera toggle for both third-person and first-person play.

## Implemented in the current prototype
- Procedurally generated training arena, ground, cover blocks and basic lighting.
- Basic player capsule and simple prototype rifle.
- First-person / third-person camera toggle (V on desktop or CAMERA button).
- WASD movement, mouse/touch look, jump and sprint on desktop.
- Hitscan shooting, simple target health, target elimination counter.
- Basic ammo/reload HUD and on-screen FIRE, JUMP, RELOAD and CAMERA buttons.
- Godot Compatibility renderer as a performance-conscious starting point.

## Controls
- **WASD:** move
- **Mouse:** aim (desktop)
- **Space:** jump
- **Shift:** sprint (desktop)
- **Left mouse / FIRE:** shoot
- **R / RELOAD:** reload
- **V / CAMERA:** toggle first-person and third-person
- **Android touch:** drag left side to move, drag right side to aim; use the on-screen buttons for actions

## Open the project
1. Install Godot 4.3 or newer.
2. Import this repository folder as a Godot project.
3. Open `scenes/main.tscn` and run the project.

## Not implemented yet
This is an early local prototype, not a finished Free Fire-like game. It has no online multiplayer, lobby, large battle-royale map, parachute drop, shrinking safe zone, loot/inventory, moving enemy AI, production-quality character models/animations, or Android APK build/signing pipeline. The updated scripts have not yet been verified in the Godot editor or on a physical Android device, so additional fixes may be needed.

## Next development steps
1. Validate the project in Godot and fix parser/runtime issues.
2. Improve camera collision, virtual joystick, aiming and responsive mobile HUD.
3. Add weapon feedback, moving bots, audio and original art assets.
4. Implement the battle-royale match loop and loot.
5. Build and test server-authoritative multiplayer.
6. Profile on Android devices and create a signed Android release.
