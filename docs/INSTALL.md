# Installation Guide

Follow these steps to ensure the mod is correctly installed for Project Zomboid Build 42.18+ (including 42.19 Unstable).

## Requirements

- **Project Zomboid Build 42.18** or newer.
- Enable **only one** sub-mod per game session (SinglePlayer or Multiplayer).

## Mod Directory Structure

Each sub-mod must be placed in your Project Zomboid `mods` directory with the following structure:

```
%UserProfile%\Zomboid\mods\<Mod_Folder_Name>\
  common\
    media\                 (Required directory; may be empty)
  42.18\
    mod.info               (Mod metadata)
    media\
      lua\                 (Lua source code)
      sandbox-options.txt  (Sandbox configuration)
```

This structure complies with the official Build 42 mod requirements.

## Installation Steps

1. **Download**: Obtain the latest release from the [Releases](https://github.com/fearthebest/IKappalD-Faded-s-True-Real-World-Vehicle-Physics/releases) page or download the repository as a ZIP.
2. **Extract**: Open the archive and navigate to the `Contents/mods/` directory.
3. **Select Sub-Mod**: Choose the appropriate folder based on your play mode:
   - **SinglePlayer**: `IKappaID's True Real World Vehicle Physics SinglePlayer`
   - **Multiplayer**: `IKappaID's True Real World Vehicle Physics Multiplayer`
4. **Deploy**: Copy the selected folder to your local mods directory:
   - Path: `C:\Users\<Username>\Zomboid\mods\`
5. **Enable**: Launch Project Zomboid, navigate to the **Mods** menu, and enable the chosen sub-mod.
6. **Initialize**: Load a save game or start a new session on Build 42.18+.

## Troubleshooting

| Issue | Resolution |
|-------|------------|
| Mod files placed in root `mods/` | Ensure only the sub-mod folder is copied, not the entire repository. |
| Missing `42.18/` parent folder | The full sub-mod folder (e.g., `IKappaID's True Real World Vehicle Physics SinglePlayer`) must be copied. |
| Incomplete directory structure | Ensure the `common/media/` directory is present. |
| Multiple sub-mods enabled | Enable either the SinglePlayer or Multiplayer version, never both. |
| Version mismatch | Verify that Project Zomboid is updated to Build 42.18 or newer. |

## Verification

- The **Mods** menu should display the enabled sub-mod.
- Sandbox settings should include tabs for **IK_SP** (SinglePlayer) or **IK_MP** (Multiplayer).
- When Debug mode is enabled, the console will report version **2.5.0** during initialization.

## Steam Workshop

For users subscribed via the [Steam Workshop (Item 3724847841)](https://steamcommunity.com/sharedfiles/filedetails/?id=3724847841), installation and updates are managed automatically by the Steam client.
