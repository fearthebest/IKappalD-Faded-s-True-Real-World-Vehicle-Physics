# Build Report

## Status

Workable clean-room mod created in this workspace.

## Implemented

- B42.18 workshop layout.
- Mod metadata and sandbox options.
- Shared core helpers with explicit nil/method guards.
- Vehicle profile database for vanilla B42 vehicle scripts.
- Deterministic script tuner for `engineForce` and `mass`.
- Server status handshake for MP diagnostics.
- Client vehicle probe for debug-only logging.
- Common Sense Reborn compatibility detection.
- Startup-only CSR Tow Assist compensation based on CSR's sandbox factors.
- JSON sandbox translations written as BOM-free text.

## CSR Compatibility

- No `incompatible=CommonSenseReborn`.
- No hard dependency on CSR, so the mod can run alone.
- Detects `CommonSenseReborn` when active.
- Does not use CSR globals, command modules, ModData keys, dashboard patches,
  seatbelt hooks, claim keys, hotwire hooks, timed actions, or inventory systems.
- Does read `SandboxVars.CommonSenseReborn` for Tow Assist factor values when
  CSR compatibility mode and Tow Assist compensation are enabled.
- Recommended load order with CSR: CSR first, this mod second.

## Multiplayer Model

- Vehicle script tuning is deterministic and shared.
- Dedicated/host server is the effective authority for vehicle physics.
- Client code only requests status and logs diagnostics.
- No client command mutates vehicles or world state.
- Tow Assist compensation is calculated during vehicle script tuning, not while
  vehicles are driving.

## Known Limits

- This does not replace `zombie.core.physics.CarController` or
  `WorldSimulation`.
- Lua-confirmed writable fields are limited to `engineForce` and `mass`.
- Deep transmission, tire slip, traction, and gear simulation still need a safe
  future Java strategy or newly verified B42 Lua APIs.
