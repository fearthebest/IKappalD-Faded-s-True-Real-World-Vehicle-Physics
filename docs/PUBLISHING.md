# Publishing to Steam Workshop

This monorepo contains **two** Workshop products. Upload them as **separate** items so players are not forced to install the broken transmission addon.

## Main mod (2.0.0)

Zip or upload a folder with **only**:

```
workshop.txt          ← from repository root
preview.png           ← from repository root
Contents/
  mods/
    IKappaIDFadedRealWorldVehiclePhysics/
      common/media/          ← required (empty is OK)
      42.18/mod.info
      42.18/media/
```

Do **not** include `IKFRVP_ManualTransmissionWIP` in this upload.

`workshop.txt` at the repo root is the canonical metadata for the main item (`id=3724847841` in the current file — keep your real Workshop ID when publishing).

## Manual transmission WIP (3.0.0)

Use a **separate** Workshop item. Zip:

```
workshop.txt          ← copy from workshop/manual-transmission-wip/workshop.txt
Contents/
  mods/
    IKFRVP_ManualTransmissionWIP/
      common/media/
      42.18/mod.info
      42.18/media/
```

No `preview.png` required unless you add one. Title and description must state **WIP / broken / do not use**.

## GitHub releases

Tag **`v2.0.0`** should point at a commit where the main mod’s `modversion` and `IKFRVP.Version` are **2.0.0**. The WIP addon may ship in the same repo tag for source consistency; players still install only the main mod from Workshop unless they opt into the second item.
