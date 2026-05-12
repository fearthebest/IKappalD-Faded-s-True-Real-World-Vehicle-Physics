# IKappaID & Faded's True Real World Vehicle Physics

Clean-room Project Zomboid Build 42.18 vehicle physics mod.

This build intentionally avoids Java core-class replacement and broad vanilla UI
patches. Vehicle behavior is changed through deterministic vehicle script tuning
that runs from shared Lua on both sides, with the multiplayer server treated as
authoritative.

## Current Behavior

- Applies curated real-world-ish mass and engine-force profiles to vanilla B42
  vehicles.
- Leaves unknown third-party vehicles alone by default.
- Can optionally apply generic multipliers to unknown vehicles through sandbox
  settings.
- Detects Common Sense Reborn and avoids CSR-owned systems, keys, and UI hooks.
- Reads CSR Tow Assist sandbox factors at startup and can lightly compensate
  engine-force targets when those factors are raised above CSR defaults.
- Uses no `pcall` wrappers.

## Install Layout

```text
Contents/mods/IKappaIDFadedRealWorldVehiclePhysics/42.18
```

For dedicated servers, use this internal mod id:

```text
IKappaIDFadedRealWorldVehiclePhysics
```

In Build 42 server configs, the `Mods=` entry may need the B42 backslash form:

```text
Mods=\CommonSenseReborn;\IKappaIDFadedRealWorldVehiclePhysics
```

Load after Common Sense Reborn when both are enabled.
