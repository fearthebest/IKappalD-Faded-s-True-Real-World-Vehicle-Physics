# Mod packages in this repository

Two **separate** Project Zomboid mods live under `Contents/mods/`. Only the first is intended for players.

## Main mod — IKappaIDFadedRealWorldVehiclePhysics

| Field | Value |
|-------|--------|
| **Folder** | `Contents/mods/IKappaIDFadedRealWorldVehiclePhysics/` |
| **Mod ID** | `IKappaIDFadedRealWorldVehiclePhysics` |
| **Version** | `2.0.0` (`mod.info` / `IKFRVP.Version`) |
| **Purpose** | Vehicle physics tuning, KI5 roster, trunk fixes, CSR compatibility |
| **Manual transmission** | **Not included** |

This is the supported package. Steam Workshop item uses root `workshop.txt` + `preview.png` + `Contents/`.

## WIP addon — IKFRVP_ManualTransmissionWIP

| Field | Value |
|-------|--------|
| **Folder** | `Contents/mods/IKFRVP_ManualTransmissionWIP/` |
| **Mod ID** | `IKFRVP_ManualTransmissionWIP` |
| **Version** | `3.0.0` |
| **Requires** | Main mod `IKappaIDFadedRealWorldVehiclePhysics` |
| **Status** | **Work in progress — broken — do not use for gameplay** |

Experimental clutch/shift Lua addon. Vanilla still **auto-shifts**; there is no supported Lua API to disable it fully. Published as its **own** Workshop item using `workshop/manual-transmission-wip/workshop.txt` (see [PUBLISHING.md](PUBLISHING.md)).

## Related mods (not in this repo)

- **Project Faded Car** — optional companion; uses `IKFRVP.Bridge` from the main mod.
