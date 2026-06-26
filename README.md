# IKappaID's True Real World Vehicle Physics — Lua dev (stable 2.5.0)

**Stable Workshop upload:** `Zomboid\Workshop\IKappaID's True Real World Vehicle Physics` after `scripts\sync_to_stable_workshop.ps1` (preserves stable `preview.png` and id **3724847841**).

**Stable Steam:** [3724847841](https://steamcommunity.com/sharedfiles/filedetails/?id=3724847841) · **Version:** 2.5.0 — see `Contents/mods/*/42.18/mod.info`

## Layout

```
IKFRVP-v2/                    ← this repo (dev)
  workshop-stable.txt          ← Steam item title + description (required)
  preview.png                 ← Steam preview image (required)
  Contents/mods/
    IKappaID's True Real World Vehicle Physics Multiplayer/42.18/
    IKappaID's True Real World Vehicle Physics SinglePlayer/42.18/
  scripts/
```

## Playtest (flat mods folder)

```powershell
.\scripts\sync_to_desktop_mods.ps1
```

Updates `Desktop\mods\` (enable **one** of SP or MP per session).

## Publish sync (stable 2.5.0)

```powershell
.\scripts\sync_to_stable_workshop.ps1
```

Copies `Contents/` + `workshop-stable.txt` → `Zomboid\Workshop\IKappaID's True Real World Vehicle Physics`. Keeps the existing stable **preview.png** unless you pass `-RefreshPreview`.
