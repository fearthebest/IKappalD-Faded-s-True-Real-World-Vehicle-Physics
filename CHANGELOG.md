# Changelog

## 1.2.0

### Added
- **Project Faded Car** companion mod (`Contents/mods/ProjectFadedCar`) with engine bay service, dashboard, engine swap, and wreck restoration.
- **`IKFRVP.Bridge`** shared API for companion mods: status, sync, retune, safe reset, and `onCompanionVehicleChanged`.
- Server bridge commands: `RequestStatus` (optional vehicle id), `SyncVehicle`, `Retune`, `SafeHandling`.
- **`IKFRVP.buildStatusTable(vehicle)`** for full physics snapshots on clients and companions.

### Changed
- Load order: IKFRVP loads before Project Faded Car; workshop description updated.

### Notes
- **v1.1.4b** remains on git tag `v1.1.4b` for the physics-only build.

---

## 1.1.4b

### Added
- **MIT License** in repository root.
- **Glitch guard** (sandbox: *Auto-Fix Experimental Glitches*, ON by default): while *Advanced Handling* is enabled, monitors for wheel sink, extreme tilt, or suspension jitter. On detection, reverts experimental sandbox to recommended defaults and re-tunes vehicle scripts without advanced handling. **Multiplayer: server-authoritative** (ModData + `GlitchGuardTripped` command).

### Changed
- **Sandbox UI reorganized**: recommended tuning on General/Class/CSR tabs; experimental handling moved to its own tab; per-class multiplier tabs; debug separated.
- Removed defensive `pcall` from runtime code; the only remaining `pcall` wraps `VehicleScript:Load()` when workshop scripts reject a payload.

### Notes
- Recommended: Profile Tuning ON, Parking & Low-Speed Help ON, Advanced Handling OFF unless testing.
- Fresh spawns are best after a glitch-guard trip.

---

## 1.1.5 (internal / not shipped)

Superseded by **1.1.4b** on GitHub. Do not use for Workshop.

---

## 1.1.4

### Highlights
- Clearer sandbox menu: option names and tooltips rewritten for roster vs generic vehicles, parking help, handling, CSR, and debug.
- Stability: removed experimental live-vehicle script reload code that could crash the game or trap players in vehicles (jumping, color flicker).

### Improved
- Sandbox tabs: General Tuning, Class Multipliers, Handling & Physics, Compatibility & Advanced.
- Parking & Low-Speed Help described in plain language.
- Safe runtime layer: `setBrakingForce` and `setEngineFeature` only (no `scriptReloaded` / spawn hooks).

### Fixed
- Stack overflow when many vehicles spawned (infinite spawn/reload loop).
- Repeated vehicle respawn-like behavior on enter in some builds.

### Physics baseline (from 1.1.3)
- Acceleration, brakes, and power feel for roster vehicles.
- Parking: script tuning + low-speed engine assist; sports cars remain the reference profile.

### Notes
- New save or freshly spawned vehicles are best for parking/cornering tests.
- Recommended: Profile Tuning ON, Cornering Tuning ON, Advanced Handling OFF unless experimenting.

---

## 1.1.3
- Trunk capacity tuning, initial sandbox UI, B42.18 roster physics baseline.

## 1.1.5 (reverted on GitHub)
- Automated release; removed from `main` as unstable / not shipped to Workshop.
