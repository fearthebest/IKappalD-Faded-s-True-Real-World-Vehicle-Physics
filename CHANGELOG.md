# Changelog

## [2.5.0] — 2026-06-20

### Fixes
- **Build 42.19 load fix:** Guard Java `null` globals (`IK_MP`, `IK_SP`) on boot so SP and MP sub-mods load without `attempted index of non-table: null` crashes.

### Highlights
- **Rebranded Release:** The mod has been rebranded as "IKappaID's True Real World Vehicle Physics" following the removal of Faded's contributions.
- **Independent Codebase:** Removed dependencies and compatibility logic for Project Faded Car (PFC).
- **Internal Cleanup:** Renamed all internal tables, files, and sandbox options to remove legacy "IKFRVP" and "Faded" naming.
- **Stable Release:** This major update brings all the latest improvements and fixes to the stable version of the mod.
- **Split Mod System:** The mod is now split into "Multiplayer" and "SinglePlayer" versions. This makes the mod more stable and ensures that multiplayer servers run smoothly.
- **Full Multiplayer Sync:** Fixed issues where vehicle changes (like engine power or brakes) wouldn't always show up for everyone. Now, all players on a server will see the same vehicle performance.
- **Instant Vehicle Sync:** In multiplayer, vehicle stats are now instantly updated the moment you get into the driver's seat.
- **Better Sandbox Options:** Simplified the names of settings and added helpful descriptions so it's easier to customize the mod to your liking.
- **Expanded Vehicle Support:** Added support for many more modded vehicles, including those from KI5, Autotsar, and others.
- **Trunk Capacity Fixes:** Improved how trunk and seat storage is calculated to ensure it always matches your sandbox settings.

---
*For older changes from the testing branch, please refer to the archived testing branch logs.*
