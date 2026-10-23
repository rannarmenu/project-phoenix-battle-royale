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
- Mobile HUD with dynamic visual virtual joystick, aim swipe area, sprint toggle and FIRE/JUMP/RELOAD/HEAL/CAMERA buttons.
- Experimental ENet host/join/leave panel and remote-player avatar/transform replication.
- Server-side bounds and movement-speed sanity checks for replicated client positions (not a full anti-cheat system).
- Compatibility renderer and LOW/BALANCED/HIGH lighting presets as a performance-conscious starting point.

## Controls
- **WASD:** move
- **Mouse:** aim
- **Space:** jump
- **Shift:** sprint (desktop)
- **Left mouse / FIRE:** shoot
- **R / RELOAD:** reload
- **V / CAMERA:** toggle first-person and third-person
- **Android touch:** drag the left side to move with a visible joystick, drag the right side to aim; use SPRINT to toggle sprint and the on-screen buttons for actions
- **Online prototype:** open `ONLINE +`, choose HOST on one device, then enter that host's reachable LAN/public IP and the same UDP port on another device and choose JOIN. `127.0.0.1` only points to the same device.

## Open the project
1. Install Godot 4.7.2 stable (the CI-tested version).
2. Import this repository folder as a Godot project.
3. Open `scenes/main.tscn` and run the project.

## Automated validation
GitHub Actions runs a Godot 4.7.2 headless import and gameplay smoke test covering scene creation, player spawn, camera modes, bots, combat, loot/inventory, safe-zone behavior, mobile joystick/sprint, weapon profiles, match victory, network session lifecycle, online-panel validation, and remote-avatar roster creation/removal. The latest run must be checked on the Actions page before treating a commit as verified.

This is **not yet a finished Free Fire-like game**. The smoke test does not verify rendered joystick appearance, real touch behavior, frame rate, thermal performance or gameplay on an Android phone.

## Not implemented yet
- A complete playable online battle: the current online prototype replicates remote player avatars/positions only. Player movement, bot AI, shooting, damage, loot, zone state and match results are not yet authoritative/shared across clients.
- Lobby matchmaking, player accounts, reconnect flow, dedicated server hosting and real two-device/network-condition testing.
- Large battle-royale map, parachute drop, loot crates and full multi-slot inventory.
- Advanced enemy pathfinding / cover-seeking.
- Production-quality character models, animations, weapon assets and audio.
- Android export preset, signed APK/AAB build and physical-device testing.

## Next development steps
1. Implement shared, server-authoritative movement, combat, bots, inventory, safe zone and match outcomes; test with two real clients.
2. Add lobby/room flow, reconnect handling, server hosting and abuse/rate-limit protection.
3. Add larger points of interest, loot containers, weapon pickups, match phases and improved navigation.
4. Add character animation, original weapon/environment assets and audio.
5. Configure Android export, profile on target phones and produce a signed APK/AAB after device testing.
