# IKappaID & Faded's True Real World Vehicle Physics

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/J3J11ZJGEJ)

Real-world-style **vehicle physics** for **Project Zomboid Build 42.18+**: mass, engine output, brakes, KI5 roster support, trunk fixes. **Multiplayer-safe**, **CSR-compatible**, Lua-only (no Java patches).

| Package | Version | Status |
|---------|---------|--------|
| **Main mod** — `IKappaIDFadedRealWorldVehiclePhysics` | **2.0.0** | Supported — use this for gameplay |
| **Addon** — `IKFRVP_ManualTransmissionWIP` | **3.0.0** | WIP / broken — do not use |

**Latest release:** [`v2.0.0`](https://github.com/fearthebest/IKappalD-Faded-s-True-Real-World-Vehicle-Physics/releases/tag/v2.0.0)

---

## Repository layout

```
├── Contents/mods/
│   ├── IKappaIDFadedRealWorldVehiclePhysics/   ← main mod (2.0.0)
│   └── IKFRVP_ManualTransmissionWIP/           ← optional WIP addon (3.0.0)
├── workshop.txt          ← Steam Workshop metadata (main mod)
├── preview.png           ← Workshop preview image (main mod)
├── scripts/              ← maintainer tools (KI5 roster generation)
├── docs/                 ← package & publishing notes
├── CHANGELOG.md
└── LICENSE
```

See **[docs/PACKAGES.md](docs/PACKAGES.md)** for what each mod does and **[docs/PUBLISHING.md](docs/PUBLISHING.md)** for Steam upload folders.

---

## Quick start (players)

### Steam Workshop

Subscribe to **IKappaID & Faded's True Real World Vehicle Physics** (main mod **2.0.0**). Enable it in the Mods menu on **B42.18**.

Do **not** enable **IKFRVP Manual Transmission WIP** unless you are testing; it is unsupported.

### Manual install (GitHub)

1. Clone this repo or download the **`v2.0.0`** source zip.
2. Copy **`Contents/mods/IKappaIDFadedRealWorldVehiclePhysics`** to your Zomboid mods folder (e.g. `%UserProfile%\Zomboid\mods\`).
3. Enable the mod in-game. Do **not** copy the WIP transmission addon unless you know why you need it.

**Project Faded Car** is a separate companion mod (engine bay + `IKFRVP.Bridge`); it is not in this repository.

---

## What the main mod does

- Retunes **mass** and **engine force** (and related script fields) via vehicle **profiles**.
- **442 KI5** vehicles on the roster; vanilla and class-based tuning.
- Optional **generic multipliers** for non-roster vehicles.
- **CSR-aware** when Common Sense Reborn is installed.
- **Trunk capacity** fixes for KI5 / trailers / ISO patterns.

It does **not** replace game Java, hijack UI, or add manual transmission (that was split to the WIP addon).

---

## Sandbox (main mod)

Tabs are prefixed with **`IKFRVP:`** — General, CSR, Global tuning, per-class multipliers, Experimental (off by default), Debug.

---

## Load order

1. Common Sense Reborn (optional)  
2. **IKappaID & Faded's True Real World Vehicle Physics**  
3. Project Faded Car (optional, separate Workshop mod)

---

## Maintainers

Regenerate the KI5 roster with PowerShell scripts in **`scripts/`** — see **[scripts/README.md](scripts/README.md)**.

---

## Authors & license

- **IKappaID** — [Workshop](https://steamcommunity.com/profiles/76561198273218719/myworkshopfiles/?appid=108600)  
- **Faded** — [Workshop](https://steamcommunity.com/profiles/76561198298230085/myworkshopfiles/?appid=108600)  

**MIT License** — see [LICENSE](LICENSE). Full history: [CHANGELOG.md](CHANGELOG.md).
