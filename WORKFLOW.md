# Dev workflow (IKFRVP-v2)

**Packing / Steam:** `Desktop\IKFRVP-v2` must include `workshop.txt`, `preview.png`, and `Contents\` at the upload root. Run `sync_to_workshop.ps1` → upload `Zomboid\Workshop\IKFRVP-v2` (not docs/scripts from dev root).

| Task | Command |
|------|---------|
| Playtest | `.\scripts\sync_to_desktop_mods.ps1` |
| Publish sync | `.\scripts\sync_to_workshop.ps1` |
| Checks | `Things for-from Cursor\IKFRVP\testing-branch\scripts\production_check.ps1 -Root .` |

Docs and changelog: `Things for-from Cursor\IKFRVP\testing-branch\`
