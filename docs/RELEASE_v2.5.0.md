# Release v2.5.0 — IKappaID's True Real World Vehicle Physics

**Date:** 2026-06-20  
**Target:** Project Zomboid Build 42.18+ (validated on 42.19 Unstable)

## Summary

Major stable release: rebranded as **IKappaID's True Real World Vehicle Physics**, split into **SinglePlayer** and **Multiplayer** sub-mods, with full MP physics mirror sync and B42.19 boot fixes.

## Install

See [INSTALL.md](INSTALL.md). Enable **one** sub-mod only.

## Mod IDs

| Session | Folder / mod ID |
|---------|-----------------|
| Single player | `IKappaID's True Real World Vehicle Physics SinglePlayer` |
| Multiplayer | `IKappaID's True Real World Vehicle Physics Multiplayer` |

Dedicated server `Mods=` example:

```
Mods=\IKappaID's True Real World Vehicle Physics Multiplayer
```

## Highlights

- Rebrand and internal cleanup (no legacy IKFRVP / Faded naming in Lua)
- SP / MP split for stability
- Server-authoritative MP physics mirror (TuningRow + instance stats)
- Trunk capacity sync (server authority in MP)
- Expanded vehicle profile support (KI5, Autotsar, FHQ, ATA, etc.)
- B42.19: guard null Java globals on boot

## Steam

Workshop ID **3724847841** — same package, two sub-mods inside `Contents/mods/`.
