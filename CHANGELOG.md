# Changelog

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
