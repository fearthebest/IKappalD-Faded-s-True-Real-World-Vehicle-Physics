# IKFRVP Testing Branch — release policy

**Goal:** Steam / `modversion` bumps are rare. Each version should be worth a full restart for hosts and players.

## When to bump `modversion`

Bump **only** when at least one of these is true for the target audience (SP, MP, or both):

1. **Player-visible behavior** — trunk, driving, tow, handling, or MP sync that users can notice in-game.
2. **MP host workflow** — server authority, sandbox sync, mod ID / load order, or dedicated-server fixes.
3. **Breaking or migration** — save compatibility, sandbox key renames, required mod list changes.

Do **not** bump for: comment-only edits, dev scripts, README typos, log string tweaks, or refactors with zero gameplay effect.

## Version lines

| Bump | Meaning | Example |
|------|---------|---------|
| **1.0.x** | Testing branch; x = shipped Steam update | 1.0.8 MP bootstrap + mirror |
| Same x, both sub-mods | SP + MP `modversion` stay aligned on Workshop package | Both 1.0.8 |

Update together on every Steam upload:

- `Contents/mods/*/42.18/mod.info` → `modversion`
- `IKFRVP_*_Core.lua` → `M.Version`
- `IKFRVP_*_Trunk.lua` → `TrunkBuild` (when trunk logic changed)
- `CHANGELOG.md` + `workshop.txt` description (latest version blurb)
- `README.md` internal version line

## Before uploading to Steam

1. Batch all intended fixes into one milestone (see `CHANGELOG.md` **[unreleased]** or new section).
2. Run MP verify checklist (server + remote client logs).
3. `.\scripts\sync_to_game_mods.ps1` for local smoke test.
4. Upload `workshop.txt` + `Contents/` only.

## 1.10.5 checklist (MP) — current milestone

**Client log**

- `orchestrator client boot v1.10.5`
- `physics_authority=server-sim-only`
- `release 1.10.5 (mp-milestone-1.10.5-lua)`
- After enter vehicle: `physics-mirror: requested … OnEnterVehicle` → `script-row` → `applied`

**Server log**

- `orchestrator server boot v1.10.5`
- `physics_authority=server`
- On client request: `physics-mirror: pushed … tuning=true`

Full notes: `Things for-from Cursor\IKFRVP\testing-branch\FOR-MILESTONE-1.10.5.md`

---

## 1.0.8 checklist (MP)

**Server log**

- `bootstrap: server modules armed`
- `orchestrator server boot v1.0.8`
- `release 1.0.8 (mp-bootstrap-physics-mirror): dedicated server owns…`
- `sandbox-sync: server ready pushed=…`
- `tow_authority=server` and `tow_skip=false` (with CSR tow on: `csr_tow_ignored_in_mp`)

**Remote client log**

- `bootstrap: client modules armed`
- `sandbox-sync: applied server snapshot … TrunkCapacityMult=…` (matches server)
- `release 1.0.8 (mp-bootstrap-physics-mirror): client uses server sandbox + physics mirror…`
- `physics-mirror: applied vehicleId=…` (with DebugLogging on, after entering vehicle)
- After entering a vehicle: `trunk-mirror: cached` / `trunk-mirror: pushed` or correct inventory capacity at server mult

**Gameplay**

- Server `TrunkCapacityMult=2` → client trunk UI shows 2×, not client-local 1×.
- Towing with gas in gear works on dedicated server (IKFRVP assist, not CSR-only on client).
