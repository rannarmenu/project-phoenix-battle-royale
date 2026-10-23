# Online multiplayer architecture

## Current foundation

The project has a Godot autoload named `NetworkSession` backed by `ENetMultiplayerPeer`. The session API supports starting a host, initiating a client connection, leaving a session, reporting peer joins/leaves, exposing a status snapshot, and validating hostnames/IP addresses and ports. The gameplay HUD now includes an experimental Host/Join panel, roster snapshots, simple remote-player avatars, 20 Hz transform/yaw updates, client position bounds and server-side movement-speed sanity checks.

Default transport is ENet over UDP, port `24567`, with a configurable player limit. Server hosting requires the port to be reachable through the host firewall/router or an appropriate relay/hosting setup. A client must use the server's reachable address; `localhost` only refers to the same device.

## Required production model

1. **Authoritative server:** server owns match clock, zone state, spawn points, loot inventory, damage, eliminations and victory/defeat.
2. **Client requests:** clients send movement/input and fire requests, never authoritative health, inventory or hit results.
3. **Validation:** server checks sender identity, movement speed, position bounds, weapon cooldown, ammunition, raycast/hit distance and rate limits.
4. **Replication:** use `MultiplayerSpawner` for server-created player/loot/bot entities and `MultiplayerSynchronizer` for carefully selected transform/health state. Avoid syncing every internal variable.
5. **Late join/reconnect:** server sends a compact match snapshot, then handles disconnect cleanup and reconnect tokens.
6. **Latency and abuse:** measure round-trip time, interpolate remote players, use server timestamps and rate-limit requests. Add abuse telemetry without logging secrets.

## Not complete yet

This is an **experimental connection and remote-avatar prototype, not a completed online battle**. Remote player positions/heading can be replicated, but client movement still originates from clients, and bots, shots, damage, inventory, loot, safe-zone state, match clock and match results are not shared or server-authoritative. The movement sanity check is not a full anti-cheat measure. Server-owned simulation, replicated combat/world state, real two-device testing, matchmaking, dedicated hosting, packet-loss testing and abuse protection are still required.

## Validation

CI tests the ENet session lifecycle, online-panel toggling, port parsing, remote-avatar creation and roster cleanup. CI does not establish a connection between separate machines. Hosting requires UDP port `24567` (or the configured port) to be reachable; test with a second device and confirm the host firewall/router allows the traffic.
