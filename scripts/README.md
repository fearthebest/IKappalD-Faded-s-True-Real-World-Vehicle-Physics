# Maintainer scripts

PowerShell tools to rebuild the KI5 vehicle roster (`IKFRVP_Profiles_KI5.lua`). **Players do not need these.**

## Prerequisites

- Windows PowerShell 5.1+
- KI5 mods installed via Steam Workshop (or paths you pass manually)
- Build **42.18** vehicle scripts under each mod’s `42.xx/media/scripts/vehicles/`

## Workflow

1. **Extract vehicle IDs** from installed Workshop mods into a text list:

```powershell
cd scripts
.\extract_vehicle_ids.ps1 -CollectionId 3652192243 -OutFile "$env:USERPROFILE\Downloads\VehicleIDKI5.txt"
```

2. **Generate** the Lua roster table into the main mod:

```powershell
.\gen_ki5.ps1 -InputFile "$env:USERPROFILE\Downloads\VehicleIDKI5.txt"
```

By default, `gen_ki5.ps1` writes to:

`../Contents/mods/IKappaIDFadedRealWorldVehiclePhysics/42.18/media/lua/shared/IKFRVP_Profiles_KI5.lua`

3. Test in-game, then commit the updated `.lua` file.

## Files

| Script | Purpose |
|--------|---------|
| `extract_vehicle_ids.ps1` | Scan Workshop/local mod folders; output vehicle script ID list |
| `gen_ki5.ps1` | Map IDs to profile groups; emit `IKFRVP_Profiles_KI5.lua` (UTF-8, no BOM) |
