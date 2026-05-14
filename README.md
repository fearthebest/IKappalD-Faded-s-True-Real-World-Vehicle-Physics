# IKappaID & Faded's True Real World Vehicle Physics

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

Subscribe, enable the mod in the **Mods** menu, and run **B42.18**.

### From this repository

1. Copy the folder  
   `Contents/mods/IKappaIDFadedRealWorldVehiclePhysics/42.18`  
   into your Zomboid mods directory, for example:  
   `Zomboid/mods/IKappaIDFadedRealWorldVehiclePhysics/42.18`
2. Ensure `mod.info` and `media/` are present.
3. Enable the mod in the **Mods** list.

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

## Recommended load order (with CSR)

1. **Common Sense Reborn**  
2. **IKappaID & Faded's True Real World Vehicle Physics**

---

## Multiplayer

Tuning is intended to be **deterministic** and suitable for **server authority**. Set sandbox options on the host as you would for any gameplay mod.

---

## Version

v1.1.2

---

## Authors

**IKappaID** & **Faded**

---

## License

Add a `LICENSE` file to this repository if you want a formal open-source terms (this README does not specify one).

---

## Troubleshooting

- Enable **IKFRVP: Debug** logging for more console detail.  
- After an update, try a **test save** or **reset this mod’s sandbox options**, then adjust sliders gradually.
