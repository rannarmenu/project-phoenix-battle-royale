# Project Phoenix — 3D Shooter Prototype

An original Android-focused 3D shooter foundation. This repository is separate from the Rannar Menu website.

## Current prototype scope
- Godot 4 project using the Compatibility renderer.
- Procedurally generated 3D training arena, floor, cover blocks, lighting and target bots.
- First-person movement, mouse look, hitscan firing, target health and elimination counter.
- Basic Android touch controls: left-side drag to move, upper-right drag to aim, plus Fire and Jump buttons.
- No external assets, paid SDK, API key, or game-server dependency in this prototype.

## Important status
This is an early prototype scaffold, not a finished battle-royale game. Online matchmaking, dedicated servers, player accounts, lobby flow, inventory, weapon selection, anti-cheat, production UI, audio, optimized art assets, Android export signing, and real-device performance testing are not implemented yet. The project has not been validated in the Godot editor or tested on an Android device in this commit.

## Open the project
1. Install Godot 4.x on a computer or use a trusted cloud build/editor environment.
2. Download or clone this repository and open the folder containing the project.godot file.
3. Run scenes/main.tscn.

## Prototype controls
**Desktop:** WASD to move, mouse to aim, left mouse button to fire, Space to jump, Esc to release the mouse.

**Android touch layout:** drag on the left side to move; drag on the upper-right side to aim; tap FIRE to shoot and JUMP to jump. Landscape orientation is recommended.

## Planned development order
1. Validate and fix the Godot project and mobile controls.
2. Add original weapon handling, hit effects, sound, and responsive HUD.
3. Add server-authoritative multiplayer and lobby/session flow.
4. Add mobile optimization, Android export configuration, and device testing.
5. Build the larger battle-royale loop only after the core prototype is stable.

## License and originality
The project name and placeholder art are original. This repository does not include Free Fire code, characters, maps, logos, or other proprietary assets. Add only assets that you own or have permission to use.
