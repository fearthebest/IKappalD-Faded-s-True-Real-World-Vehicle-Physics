# Installing from GitHub (players)

Follow these steps so the mod loads correctly on **Build 42.18+** (including **42.19** Unstable).

## Requirements

- **Project Zomboid Build 42.18** or newer (see `versionMin` in `mod.info`).
- Enable **only one** sub-mod per game session (SinglePlayer **or** Multiplayer — not both).

## Correct mod folder layout

Each sub-mod must look like this **inside** your Zomboid mods directory:

```
%UserProfile%\Zomboid\mods\IKappaID's True Real World Vehicle Physics SinglePlayer\
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

## Step-by-step

1. Download the repo: **Code → Download ZIP**, or get the **`v2.5.0`** [release](https://github.com/fearthebest/IKappalD-Faded-s-True-Real-World-Vehicle-Physics/releases).
2. Open the zip and go to:  
   `Contents/mods/`
3. Copy **one** folder depending on how you play:
   - **Single player:** `IKappaID's True Real World Vehicle Physics SinglePlayer`
   - **Multiplayer (dedicated server or MP client):** `IKappaID's True Real World Vehicle Physics Multiplayer`
4. Paste into:  
   `C:\Users\<you>\Zomboid\mods\`  
   (same place as other mods; **not** inside `Workshop/` unless you use Workshop tooling).
5. In-game: **Main menu → Mods** → enable the sub-mod you copied → Apply.
6. Start or load a save on **B42.18+**.

## Common mistakes

| Mistake | Fix |
|---------|-----|
| Copied the whole GitHub repo into `mods/` | Copy only one folder from `Contents/mods/` |
| Copied only `42.18/` without parent folder | Copy the full sub-mod folder (name matches `mod.info` `id=`) |
| Missing `common/media/` | Use a current download from this repo (includes empty `common/`) |
| Enabled both SP and MP sub-mods | Enable **one** only |
| Game build below 42.18 | Update Project Zomboid to 42.18+ |

## Verify it loaded

- Mods menu shows the enabled sub-mod name.
- Sandbox has tabs for **IK_SP** (single player) or **IK_MP** (multiplayer).
- With debug sandbox on, console may show version **2.5.0** on boot.

## Steam Workshop

If you subscribe on Steam ([Workshop item 3724847841](https://steamcommunity.com/sharedfiles/filedetails/?id=3724847841)), the game installs the layout for you — you do **not** need to copy files from GitHub.
