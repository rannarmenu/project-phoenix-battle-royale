# Project Phoenix

A Godot 4 mobile-first 3D shooter prototype with both third-person and first-person camera modes.

## Implemented in the current prototype
- Procedurally generated training arena with cover blocks, low-poly pine trees and outdoor sky lighting.
- Player capsule and simple prototype rifle.
- First-person / third-person camera toggle with a collision-aware spring arm.
- WASD movement, mouse/touch look, jump and desktop sprint.
- Hitscan shooting, ammo/reload HUD and crosshair.
- Six moving enemy bots that approach and attack the player.
- Bot health, elimination counter, player damage and respawn.
- Auto-pickup loot: ammo, medkits and armor with inventory caps.
- Medkit healing, armor damage reduction and inventory HUD.
- Shrinking safe zone with a visible boundary, HUD countdown/status and outside-zone damage.
- Touch action buttons for FIRE, JUMP, RELOAD and CAMERA.
- Compatibility renderer as a performance-conscious starting point.

## Controls
- **WASD:** move
- **Mouse:** aim
- **Space:** jump
- **Shift:** sprint (desktop)
- **Left mouse / FIRE:** shoot
- **R / RELOAD:** reload
- **V / CAMERA:** toggle first-person and third-person
- **Android touch:** drag the left side to move and the right side to aim; use on-screen buttons for actions

## Open the project
1. Install Godot 4.7.2 stable (the CI-tested version).
2. Import this repository folder as a Godot project.
3. Open `scenes/main.tscn` and run the project.

## Automated validation
GitHub Actions passes a Godot 4.7.2 headless import and gameplay smoke test covering scene creation, player spawn, both camera modes, six bots, mesh references, bot damage/elimination, player respawn, enemy attack, loot pickups, inventory, medkit, armor and safe-zone shrink.

This is **not yet a finished Free Fire-like game**. The smoke test does not verify visual quality, real touch behavior, frame rate, thermal performance or gameplay on an Android phone.

## Not implemented yet
- Online multiplayer, lobby, matchmaking or player accounts.
- Large battle-royale map, parachute drop, loot crates and full multi-slot inventory.
- Advanced enemy pathfinding / cover-seeking.
- Production-quality character models, animations, weapon assets and audio.
- Android export preset, signed APK/AAB build and physical-device testing.

## Next development steps
1. Add a visual virtual joystick and refine responsive mobile HUD.
2. Add weapon feedback, character animations, sound and hit effects.
3. Add match phases, loot containers, victory/defeat screen and better map layout.
4. Build and test server-authoritative online multiplayer.
5. Configure Android export, profile on target phones and create a signed release.
