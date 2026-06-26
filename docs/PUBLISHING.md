# Publishing Guidelines

This repository is structured to support publishing to the Steam Workshop. The following guidelines ensure consistency between the development repository and the published Workshop item.

## Steam Workshop Structure

The Workshop upload directory must contain the following files at the root:

- `workshop.txt`: Contains the Workshop item metadata (ID, title, description, tags).
- `preview.png`: The thumbnail image for the Workshop listing.
- `Contents/`: The directory containing the mod packages.

### Main Workshop Item (ID: 3724847841)

The primary Workshop item includes both the SinglePlayer and Multiplayer sub-mods. When updating this item:

1. Use the `workshop.txt` from the repository root.
2. Ensure the `Contents/mods/` directory includes both sub-mod folders.
3. Verify that `modversion` in all `mod.info` files matches the current release (e.g., `2.5.0`).

## Versioning and Releases

### GitHub Releases

Releases are tagged using semantic versioning (e.g., `v2.5.0`). Each release should include:

- A summary of changes and fixes.
- Updated documentation in the `docs/` directory.
- A consistent codebase across both SinglePlayer and Multiplayer packages.

### Synchronization Scripts

Utility scripts are provided in the `scripts/` directory to automate the synchronization of files between the development repository and the local Workshop upload folder. These scripts ensure that metadata and directory structures are preserved during the deployment process.
