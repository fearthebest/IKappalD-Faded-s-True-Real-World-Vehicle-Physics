# Changelog

## 3.0.0 (separate addon — not this package)

Work-in-progress **manual transmission** sub-mod. Requires main IKFRVP. **Not supported for gameplay.**

---

## 2.0.0

### Added
- Full Kiurio / KI5 vehicle pack roster (**442** vehicles) with per-vehicle physics profiles.
- `IKFRVP_Profiles_KI5.lua` roster table (UTF-8 without BOM) loaded by `IKFRVP_Profiles.lua`.
- Maintainer scripts under `scripts/` (`extract_vehicle_ids.ps1`, `gen_ki5.ps1`) to regenerate the KI5 roster from installed mods.

### Changed
- Repository layout: `docs/`, `scripts/`, `workshop/manual-transmission-wip/`; WIP transmission addon source under `Contents/mods/IKFRVP_ManualTransmissionWIP/`.
- B42-compliant `common/media/` on both mods (mandatory empty folder per PZwiki); player install guide in `docs/INSTALL.md`.
- **Project Faded Car** is not bundled in this package. IKFRVP is physics-only; publish PFC as its own Workshop mod.
- **`IKFRVP.Bridge`** API unchanged (`IKFRVP_Bridge.lua`); PFC uses `PFC_IKFRVPBridge.lua` when both mods are enabled.
- **Manual transmission removed from the main mod.** It lives only in the separate **IKFRVP Manual Transmission WIP** addon (`modversion=3.0.0`), marked broken / do not use.

### Fixed
- KI5 / trailer trunk capacity detection and scaling (including ISO containers and DAMN patterns).
- Sandbox duplicate-key crash (`ManualTransmission` tab vs option) resolved in main mod by removing MT from this package.
- BrakeRuntime engine sync no longer conflicts with manual-transmission clutch logic (MT is a separate addon).
- Trailers and ISO shipping containers classified as heavy trailer cargo instead of passenger cars.
- Lua load crash from invalid roster file format (no top-level `return`, no UTF-8 BOM).
- Vehicle ID extraction now accepts KI5 script names that start with digits.

### Notes
- Sandbox: enable **Tune Roster Vehicles** for KI5 profiles; disable generic mod-vehicle tuning if you only want the roster.
- Replaces the incomplete early **v2.0.0** GitHub tag (334-vehicle roster, bundled PFC).

---

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
