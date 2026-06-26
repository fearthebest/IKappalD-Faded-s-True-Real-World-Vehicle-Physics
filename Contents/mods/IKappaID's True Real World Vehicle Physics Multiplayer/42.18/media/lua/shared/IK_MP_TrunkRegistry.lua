-- Trunk part/container registry: vanilla profile (CarNormal-style) vs mod extensions.
require "IK_MP_Core"

IK_MP.TrunkRegistry = IK_MP.TrunkRegistry or {}

local R = IK_MP.TrunkRegistry

-- Same container types vanilla uses in template_trunk / ISInventoryPage.
R.VANILLA_CONTAINER_TYPES = {
    Trunk = true,
    TruckBed = true,
    TruckBedOpen = true,
    TrailerTrunk = true,
}

-- Extra container type strings seen on mod vehicles (KI5, ATA, Autotsar, …).
R.MOD_CONTAINER_TYPE_SUBSTRINGS = {
    "trunk",
    "truckbed",
    "trailertrunk",
    "roofrack",
    "roofcrate",
    "gunrack",
    "storage",
    "locker",
    "cabinet",
    "toolbox",
    "cargo",
}

-- Part ids / substrings for mod cargo bins (not used on explicit vanilla roster vehicles).
R.MOD_PART_SUBSTRINGS = {
    "roofrack",
    "roofcrate",
    "locker",
    "cabinet",
    "gunrack",
    "toolbox",
    "toolbx",
    "cargo",
    "storage",
    "trunk",
    "truckbed",
    "trailer",
    "bushfloor",
    "bushroof",
    "bushroofcrate",
    "bushfender",
    "bushstorage",
    "bushmedic",
    "bushammo",
    "cap85",
    "e150trunk",
    "e150roof",
    "atainteractive",
    "palatka",
    "centerconsole",
    "centreconsole",
    "ki5cr",
    "ki5cab",
    "ki5utility",
    "ki5trunk",
    "damntrunk",
    "m911trunk",
    "fhqtrunk",
}

local function partIdIsExcluded(partId)
    if not partId or partId == "" then
        return true
    end
    if string.find(partId, "glove", 1, true) then
        return true
    end
    if string.find(partId, "gastank", 1, true) then
        return true
    end
    if string.find(partId, "gas", 1, true) and string.find(partId, "tank", 1, true) then
        return true
    end
    if string.find(partId, "trunkdoor", 1, true) then
        return true
    end
    if string.find(partId, "muffler", 1, true) or string.find(partId, "battery", 1, true) then
        return true
    end
    if string.find(partId, "tire", 1, true) or string.find(partId, "wheel", 1, true) then
        return true
    end
    return false
end

function R.matchesVanillaContainerType(typ)
    if not typ or typ == "" then
        return false
    end
    return R.VANILLA_CONTAINER_TYPES[typ] == true
end

function R.matchesVanillaPart(part, partId)
    if partIdIsExcluded(partId) then
        return false
    end
    if part and part.isVehicleTrunk and part:isVehicleTrunk() then
        return true
    end
    if partId == "truckbed" or string.find(partId, "truckbed", 1, true) then
        return true
    end
    if string.find(partId, "trunk", 1, true) and not string.find(partId, "door", 1, true) then
        return true
    end
    if string.find(partId, "trailer", 1, true) and not string.find(partId, "hitch", 1, true) then
        return true
    end
    return false
end

function R.matchesVanillaTrunkProfile(typ, partId, part)
    if R.matchesVanillaContainerType(typ) then
        return true
    end
    return R.matchesVanillaPart(part, partId)
end

local function containerTypeMatchesModList(ltyp)
    if not ltyp or ltyp == "" then
        return false
    end
    for i = 1, #R.MOD_CONTAINER_TYPE_SUBSTRINGS do
        if string.find(ltyp, R.MOD_CONTAINER_TYPE_SUBSTRINGS[i], 1, true) then
            if R.MOD_CONTAINER_TYPE_SUBSTRINGS[i] == "trunk" and string.find(ltyp, "door", 1, true) then
                -- skip trunkdoor
            else
                return true
            end
        end
    end
    return false
end

local function partIdMatchesModList(partId)
    if partIdIsExcluded(partId) then
        return false
    end
    for i = 1, #R.MOD_PART_SUBSTRINGS do
        local needle = R.MOD_PART_SUBSTRINGS[i]
        if string.find(partId, needle, 1, true) then
            if needle == "trunk" and string.find(partId, "door", 1, true) then
                -- skip trunk doors
            elseif needle == "trailer" and string.find(partId, "hitch", 1, true) then
                -- skip trailer hitch
            else
                return true
            end
        end
    end
    if string.find(partId, "bush", 1, true) and (
        string.find(partId, "ammo", 1, true) or string.find(partId, "medic", 1, true)
            or string.find(partId, "roofcrate", 1, true) or string.find(partId, "storage", 1, true)
            or string.find(partId, "floor", 1, true) or string.find(partId, "roof", 1, true)
            or string.find(partId, "fender", 1, true)
    ) then
        return true
    end
    if string.find(partId, "cabs", 1, true) and string.find(partId, "ki5", 1, true) then
        return true
    end
    return false
end

function R.matchesModTrunkProfile(typ, partId, part, ltyp)
    if R.matchesVanillaTrunkProfile(typ, partId, part) then
        return true
    end
    if typ and typ ~= "" and R.matchesVanillaContainerType(typ) then
        return true
    end
    if containerTypeMatchesModList(ltyp) then
        return true
    end
    return partIdMatchesModList(partId)
end

return R


