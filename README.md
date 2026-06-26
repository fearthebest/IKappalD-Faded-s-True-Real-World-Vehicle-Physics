# IKappaID's True Real World Vehicle Physics

Realistic vehicle mass, engine power, handling, trunk capacity, and multiplayer synchronization for Project Zomboid Build 42.

| | |
|---|---|
| **Version** | 2.5.0 |
| **Target build** | B42.18+ |
| **Author** | IKappaID & Faded |
| **Steam Workshop** | [3724847841](https://steamcommunity.com/sharedfiles/filedetails/?id=3724847841) |

## Overview

This mod replaces arcade vehicle behavior with physics tuned from real-world data. It ships as two sub-mods: one for single-player and listen-host sessions, and one for dedicated multiplayer servers. Enable only one sub-mod per session.

## Features

- Realistic mass, power, braking, and handling per vehicle class
- Expanded support for KI5, Autotsar, ATA, fhq Motorious Zone, and community packs
- Server-authoritative sandbox sync in multiplayer
- Trunk and seat storage scaled to sandbox settings
- Split SP and MP packages for stable load order and performance

## Sub-mods

| Sub-mod | Mod ID | Use when |
|---------|--------|----------|
| SinglePlayer | `IKappaID's True Real World Vehicle Physics SinglePlayer` | SP or listen-host |
| Multiplayer | `IKappaID's True Real World Vehicle Physics Multiplayer` | Dedicated MP server |

## Repository structure

```text
.
├── README.md
├── CHANGELOG.md
├── LICENSE
├── workshop-stable.txt      # Steam item title and description
├── preview.png              # Steam preview image
├── Contents/
│   └── mods/
│       ├── IKappaID's True Real World Vehicle Physics SinglePlayer/42.18/
│       └── IKappaID's True Real World Vehicle Physics Multiplayer/42.18/
├── docs/                    # Installation, packaging, and release notes
└── scripts/                 # Sync helpers for playtest and Workshop upload
```

Each sub-mod folder contains `mod.info`, `media/lua/`, and `media/sandbox-options.txt` under the `42.18` version directory.

## Installation (players)

See [docs/INSTALL.md](docs/INSTALL.md) for step-by-step setup. Copy one sub-mod from `Contents/mods/` into your Zomboid `mods` folder, or subscribe on Steam Workshop.

## Development

**Playtest (flat mods folder):**

```powershell
.\scripts\sync_to_desktop_mods.ps1
```

**Publish to Steam Workshop tree:**

```powershell
.\scripts\sync_to_stable_workshop.ps1
```

Target upload folder: `Zomboid\Workshop\IKappaID's True Real World Vehicle Physics`.

Additional workflow notes: [WORKFLOW.md](WORKFLOW.md), [RELEASE.md](RELEASE.md).

## Links

- **Steam Workshop:** https://steamcommunity.com/sharedfiles/filedetails/?id=3724847841
- **Support:** https://ko-fi.com/ikappaid

Community mod — not affiliated with or endorsed by The Indie Stone.
