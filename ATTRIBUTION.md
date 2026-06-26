# Attribution and third-party mods

**IKappaID's True Real World Vehicle Physics** is original work by **IKappaID**.

## No third-party mod code

This project does **not** include, copy, or ship source or bytecode from other Project Zomboid mods, including but not limited to:

- Realistic Car Physics (RCP) / Project Summer Car (PSC)
- Better Car Physics (BCP)
- True Vehicle Physics (TVP)
- Common Sense Reborn (CSR)
- Vehicle Damage MP Fix or similar patches

All Lua under `Contents/` was written for this mod.

## Ideas vs code

Other mods and community write-ups may have inspired **approaches** (for example: server authority, sandbox mults, optional classpath overrides for MP). That is normal modding practice and is **not** a claim on their code.

| What we may reference | What we do not do |
|----------------------|-------------------|
| Public mod IDs for **load order** and **compat** | `require` or paste their Lua/Java |
| Vanilla PZ APIs (`BaseVehicle`, `ItemContainer`, etc.) | Redistribute their `.class` files |
| Reading another mod’s **published** sandbox/API surface so the mod can yield or defer | Fork or decompile their implementations |

## Compatibility layer

`IK_MP_Compat.lua` and `IK_SP_Compat.lua` detect whether optional mods are **enabled** and adjusts behavior (e.g. yield tow to CSR in SP, skip tow impulses when RCP/PSC is active). Those files document **which public behaviors** we interoperate with; they are not copies of other authors’ source trees.

## Trademarks and names

Mod names and Workshop IDs mentioned in docs or logs belong to their respective authors. Use in compatibility lists does not imply endorsement or affiliation.
