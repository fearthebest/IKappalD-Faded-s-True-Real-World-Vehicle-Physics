# IKappaID & Faded's True Real World Vehicle Physics

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/J3J11ZJGEJ)

Vehicle physics tuning for **Project Zomboid Build 42.18+**. The goal is **more believable weight and acceleration** for vanilla-style vehicles while staying **multiplayer-friendly** and **compatible with Common Sense Reborn (CSR)**.

**Repository:** [github.com/fearthebest/IKappalD-Faded-s-True-Real-World-Vehicle-Physics](https://github.com/fearthebest/IKappalD-Faded-s-True-Real-World-Vehicle-Physics)

---

## What this mod does

- Retunes **vehicle mass** and **engine output** (and related script fields) for vehicles the mod recognizes, using a **profile list** tuned per vehicle class.
- Applies **reverse, coasting, and base brake** adjustments as part of that pipeline.
- Supports **simple “generic” multipliers** for vehicles **not** on the profile list, when that mode is enabled.
- **CSR-aware:** compatibility behaviour and optional **tow-assist balancing** when CSR tow settings are above defaults.

This mod does **not** replace core game Java, hijack unrelated UI, or take over hotwiring, seatbelts, inventory, etc.

---

## Requirements

- **Project Zomboid Build 42.18** (see `versionMin` in `mod.info`).
- **Common Sense Reborn** is optional; CSR-related sandbox options apply if you use it.

---

## Installation

### From Steam Workshop

Subscribe to **IKappaID & Faded's True Real World Vehicle Physics** on the Steam Workshop for Project Zomboid, then enable the mod in the **Mods** menu and run **B42.18**.

**Authors’ Workshop pages** (other mods and updates may be listed here):

- **IKappaID:** [Steam Workshop files](https://steamcommunity.com/profiles/76561198273218719/myworkshopfiles/?appid=108600)
- **Faded:** [Steam Workshop files](https://steamcommunity.com/profiles/76561198298230085/myworkshopfiles/?appid=108600)

### From this repository

**v2.0.0 (latest):** clone `main` or checkout tag [`v2.0.0`](https://github.com/fearthebest/IKappalD-Faded-s-True-Real-World-Vehicle-Physics/releases/tag/v2.0.0).

**v1.2.0:** `git checkout v1.2.0`

**v1.1.4b (physics only):** `git checkout v1.1.4b`

1. Copy **`Contents/mods/IKappaIDFadedRealWorldVehiclePhysics`** into your Zomboid mods directory (for example `Zomboid/mods/`). This repository ships **IKFRVP only**.
2. **Project Faded Car** is a **separate mod** (not in this repo). Subscribe or install it separately if you want engine-bay features and the IKFRVP bridge.
3. Enable **IKappaID & Faded's True Real World Vehicle Physics** in the **Mods** list; enable **Project Faded Car** only if you use that companion mod.

---

## Sandbox options

Settings are grouped into **tabs**. Each tab name starts with **`IKFRVP:`** so you can tell this mod’s options apart when many mods are installed.

| Tab | Purpose |
|-----|--------|
| **IKFRVP: General** | Master on/off for this mod’s vehicle tuning. |
| **IKFRVP: CSR compatibility** | CSR-related behaviour and optional tow-assist balancing. |
| **IKFRVP: Global tuning** | Profile list vs generic tuning, global power/weight, baseline brakes, generic sliders, audit-only mode. |
| **IKFRVP: Vehicle class — …** | Per-class multipliers (Compact, Standard, Sport, Heavy, Trailer). |
| **IKFRVP: Experimental** | Optional steering, grip, roll, and suspension — **off by default**; may clip or misbehave on some vehicles or packs. |
| **IKFRVP: Debug** | Console logging and diagnostic polling. |

Many defaults are **neutral (1.0)** where appropriate; **experimental handling** stays **off** until you enable it.

---

## Workshop vehicle packs

Many workshop cars use script names like **`Base` + digit + …**. For those, the mod **limits** how far mass and engine output can drift from the pack author’s values, which reduces sinking, clipping, or odd behaviour. The **experimental handling pass is not applied** to those scripts.

Profile-list tuning applies to vanilla vehicles and the **KI5 vehicle pack** (**442** mapped scripts); others can use **generic** tuning if enabled.

---

## Recommended load order (with CSR)

1. **Common Sense Reborn**  
2. **IKappaID & Faded's True Real World Vehicle Physics**  
3. **Project Faded Car** (optional; **separate Workshop mod** — engine bay + `IKFRVP.Bridge` when both are enabled)

---

## Multiplayer

Tuning is intended to be **deterministic** and suitable for **server authority**. Set sandbox options on the host as you would for any gameplay mod.

---

## Version

Current release: **2.0.0** — see **`mod.info`** (`modversion`) and **`IKFRVP.Version`** in `media/lua/shared/IKFRVP_Core.lua` (also echoed in logs).

### Companion mod (separate)

**Project Faded Car** uses **`IKFRVP.Bridge`** (`IKFRVP_Bridge.lua` in this mod; `PFC_IKFRVPBridge.lua` in PFC). It is not bundled in this package.

### Releases

| Tag | Notes |
|-----|--------|
| [**v2.0.0**](https://github.com/fearthebest/IKappalD-Faded-s-True-Real-World-Vehicle-Physics/releases/tag/v2.0.0) | Physics-only package; KI5 roster (442 vehicles); `IKFRVP.Bridge` for optional PFC |
| [**v1.2.0**](https://github.com/fearthebest/IKappalD-Faded-s-True-Real-World-Vehicle-Physics/releases/tag/v1.2.0) | `IKFRVP.Bridge` API added (PFC was bundled in repo until 2.0.0 split) |
| [**v1.1.4b**](https://github.com/fearthebest/IKappalD-Faded-s-True-Real-World-Vehicle-Physics/releases/tag/v1.1.4b) | Physics-only release (unchanged tag; still available for rollback) |

---

## Authors

- **IKappaID** — [Steam Workshop profile](https://steamcommunity.com/profiles/76561198273218719/myworkshopfiles/?appid=108600)
- **Faded** — [Steam Workshop profile](https://steamcommunity.com/profiles/76561198298230085/myworkshopfiles/?appid=108600)

---

## License

Licensed under the **MIT License** — see the [`LICENSE`](LICENSE) file.

Forks and patches are welcome. Please keep the original copyright and license notices with the code, credit **IKappaID & Faded** as the original authors, and make clear what you changed.

---

## Troubleshooting

- Enable **IKFRVP: Debug** logging for more console detail.  
- After an update, try a **test save** or **reset this mod’s sandbox options**, then adjust sliders gradually.
