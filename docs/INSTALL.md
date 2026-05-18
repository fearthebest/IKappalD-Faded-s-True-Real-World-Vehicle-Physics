# Installing from GitHub (players)

Follow these steps so the mod loads correctly on **Build 42.18+**.

## Requirements

- **Project Zomboid Build 42.18** or newer (see `versionMin` in `mod.info`).
- For the WIP transmission addon: main mod **must** be installed first.

## Correct mod folder layout

Each mod must look like this **inside** your Zomboid mods directory:

```
%UserProfile%\Zomboid\mods\IKappaIDFadedRealWorldVehiclePhysics\
  common\
    media\                 ← required (can be empty)
  42.18\
    mod.info
    media\
      lua\
      sandbox-options.txt
      ...
```

This matches the official [B42 mod structure](https://pzwiki.net/wiki/Mod_structure) (`common/` + version folder).

## Step-by-step (main mod)

1. Download the repo: **Code → Download ZIP**, or get the **`v2.0.0`** release zip.
2. Open the zip and go to:  
   `Contents/mods/IKappaIDFadedRealWorldVehiclePhysics/`
3. Copy the **entire** `IKappaIDFadedRealWorldVehiclePhysics` folder (not the whole repo, not only `42.18`).
4. Paste into:  
   `C:\Users\<you>\Zomboid\mods\`  
   (same place as other mods; **not** inside `Workshop/` unless you know Workshop tooling).
5. In-game: **Main menu → Mods** → enable **IKappaID & Faded's True Real World Vehicle Physics** → Apply.
6. Start or load a save on **B42.18+**.

## Common mistakes (causes “mod does nothing” or won’t load)

| Mistake | Fix |
|---------|-----|
| Copied the whole GitHub repo into `mods/` | Copy only `Contents/mods/IKappaIDFadedRealWorldVehiclePhysics` |
| Copied only `42.18/` without parent folder | Copy the folder named `IKappaIDFadedRealWorldVehiclePhysics` |
| Missing `common/media/` | Use a current download from this repo (includes empty `common/`) |
| Game build below 42.18 | Update Project Zomboid to 42.18+ |
| Enabled WIP transmission only | Enable **main** mod; WIP addon is optional and broken |

## Optional: WIP manual transmission (not recommended)

Only if you accept it is **broken / unsupported**:

1. Install the **main** mod first (steps above).
2. Copy `Contents/mods/IKFRVP_ManualTransmissionWIP` to `Zomboid\mods\`.
3. Enable both mods; main mod must load before the addon (`require` in `mod.info`).

## Verify it loaded

- Mods menu shows **IKappaID & Faded's True Real World Vehicle Physics** enabled.
- Sandbox has tabs starting with **IKFRVP:**.
- With **IKFRVP: Debug** on, console may show IKFRVP version **2.0.0** on server start.

## Steam Workshop

If you subscribe on Steam, the game installs the layout for you — you do **not** need to copy files from GitHub.
