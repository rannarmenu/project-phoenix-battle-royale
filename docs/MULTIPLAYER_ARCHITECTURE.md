# Online multiplayer architecture

## Current foundation

The project has a Godot autoload named `NetworkSession` backed by `ENetMultiplayerPeer`. The session API supports starting a host, initiating a client connection, leaving a session, reporting peer joins/leaves, exposing a status snapshot, and validating hostnames/IP addresses and ports.

Default transport is ENet over UDP, port `24567`, with a configurable player limit. Server hosting requires the port to be reachable through the host firewall/router or an appropriate relay/hosting setup. A client must use the server's reachable address; `localhost` only refers to the same device.

## Required production model

1. **Authoritative server:** server owns match clock, zone state, spawn points, loot inventory, damage, eliminations and victory/defeat.
2. **Client requests:** clients send movement/input and fire requests, never authoritative health, inventory or hit results.
3. **Validation:** server checks sender identity, movement speed, position bounds, weapon cooldown, ammunition, raycast/hit distance and rate limits.
4. **Replication:** use `MultiplayerSpawner` for server-created player/loot/bot entities and `MultiplayerSynchronizer` for carefully selected transform/health state. Avoid syncing every internal variable.
5. **Late join/reconnect:** server sends a compact match snapshot, then handles disconnect cleanup and reconnect tokens.
6. **Latency and abuse:** measure round-trip time, interpolate remote players, use server timestamps and rate-limit requests. Add abuse telemetry without logging secrets.

## Not complete yet

This is a **session-layer foundation, not a playable online match**. The current match, player movement, bots, shots, loot, safe-zone and match results are still local prototype logic. Remote player spawn/replication, server-owned combat, matchmaking/lobby UI, dedicated hosting, packet-loss testing and abuse protection must be implemented and tested before online multiplayer can be claimed complete.

## Validation

CI tests that the script loads, initializes offline, accepts valid addresses, rejects malformed addresses/ports, and exposes a status snapshot. CI does not establish a connection between two separate machines. A real two-client test and a reachable hosted server are still required.
