require "IKFRVP_Core"
require "IKFRVP_Profiles"

IKFRVP.TrunkRuntime = IKFRVP.TrunkRuntime or {}

local R = IKFRVP.TrunkRuntime

R._installed = false
local origGetEffectiveCapacity = nil
local origGetCapacity = nil
local inCapacityHook = false

-- Classification cache: keyed by "type|partId|scriptName" so the full string-scan
-- in isVehicleTrunkCargoContainer runs at most once per unique container type.
local _trunkClassCache = {}

local function sandboxTrunkMult()
    return IKFRVP.numberOption("TrunkCapacityMult", 1.0, 0.35, 2.5)
end

-- JavaDocs: ItemContainer.getVehicle() / getVehiclePart() (preferred over getParent() alone).
local function containerVehicle(container)
    if not container then
        return nil
    end
    if container.getVehicle then
        local vehicle = container:getVehicle()
        if vehicle then
            return vehicle
        end
    end
    if not container.getParent or not instanceof then
        return nil
    end
    local parent = container:getParent()
    if parent and instanceof(parent, "BaseVehicle") then
        return parent
    end
    if parent and instanceof(parent, "VehiclePart") and parent.getVehicle then
        return parent:getVehicle()
    end
    return nil
end

function R.vehicleUsesIKFRVPTuning(vehicle)
    if not vehicle or not IKFRVP.isEnabled() then
        return false
    end
    local script = vehicle.getScript and vehicle:getScript() or nil
    if not script then
        return false
    end
    local profile = IKFRVP.Profiles.resolveProfile(script)
    if profile and IKFRVP.isProfileTuningEnabled() then
        return true
    end
    if IKFRVP.isGenericMultiplierTuningEnabled() then
        return true
    end
    return false
end

local function isGasolineContainer(container)
    if not container or not container.getContentType then
        return false
    end
    local ct = container:getContentType()
    if ct == nil then
        return false
    end
    return string.lower(tostring(ct)) == "gasoline"
end

local function containerPartIdLower(container)
    if not container or not container.getVehiclePart then
        return ""
    end
    local part = container:getVehiclePart()
    if not part or not part.getId then
        return ""
    end
    local id = part:getId()
    if id == nil then
        return ""
    end
    return string.lower(tostring(id))
end

local function containerVehicleScriptLower(container)
    local vehicle = containerVehicle(container)
    if not vehicle or not vehicle.getScript then
        return ""
    end
    local script = vehicle:getScript()
    if not script then
        return ""
    end
    return string.lower(IKFRVP.getScriptFullName(script) or "")
end

function R.isVehicleTrunkCargoContainer(container)
    if not container then
        return false
    end
    if not containerVehicle(container) then
        return false
    end
    if isGasolineContainer(container) then
        return false
    end

    local typ = ""
    if container.getType then
        local t = container:getType()
        if t ~= nil then
            typ = tostring(t)
        end
    end
    local ltyp = string.lower(typ)
    local partId = containerPartIdLower(container)
    local scriptName = containerVehicleScriptLower(container)

    local cacheKey = ltyp .. "|" .. partId .. "|" .. scriptName
    local cached = _trunkClassCache[cacheKey]
    if cached ~= nil then
        return cached
    end

    local result = R._classifyTrunkContainer(ltyp, partId, scriptName, typ)
    _trunkClassCache[cacheKey] = result
    return result
end

function R._classifyTrunkContainer(ltyp, partId, scriptName, typ)

    if ltyp ~= "" and string.find(ltyp, "glove", 1, true) then
        return false
    end
    if ltyp ~= "" and string.find(ltyp, "gas", 1, true) and not string.find(ltyp, "bag", 1, true) then
        return false
    end
    if ltyp ~= "" and string.find(ltyp, "seat", 1, true) then
        return false
    end
    if partId ~= "" and string.find(partId, "glove", 1, true) then
        return false
    end
    if partId ~= "" and string.find(partId, "seat", 1, true) then
        return false
    end
    if partId ~= "" and (string.find(partId, "tank", 1, true) or string.find(partId, "gas", 1, true)) then
        return false
    end
    if scriptName ~= "" and string.find(scriptName, "tanker", 1, true) then
        return false
    end

    -- KI5 / DAMN trailers & ISO rigs: cargo is on script-named trailers, not only vanilla types.
    if scriptName ~= "" and string.find(scriptName, "trailer", 1, true) then
        return true
    end
    if scriptName ~= "" and string.find(scriptName, "isocontainer", 1, true) then
        return true
    end

    -- DAMN / KI5 (90pierceArrow: ARRWTrunkLTL, ARRWTrunk, …)
    if partId ~= "" and string.find(partId, "trunk", 1, true) and not string.find(partId, "door", 1, true) then
        return true
    end
    if partId ~= "" and string.find(partId, "arrw", 1, true) and not string.find(partId, "door", 1, true) then
        return true
    end
    if partId == "truckbed" or string.find(partId, "truckbed", 1, true) then
        return true
    end
    if partId ~= "" and string.find(partId, "cargo", 1, true) and not string.find(partId, "tank", 1, true) then
        return true
    end
    if partId ~= "" and string.find(partId, "toolbox", 1, true) then
        return true
    end
    if partId ~= "" and string.find(partId, "storage", 1, true) and not string.find(partId, "door", 1, true) then
        return true
    end

    if ltyp ~= "" and string.find(ltyp, "trunk", 1, true) and not string.find(ltyp, "door", 1, true) then
        return true
    end
    if ltyp ~= "" and string.find(ltyp, "arrw", 1, true) and not string.find(ltyp, "door", 1, true) then
        return true
    end

    if typ == "Trunk" or typ == "TruckBed" or typ == "TruckBedOpen" or typ == "TrailerTrunk" or typ == "TrailerAnimalFood" then
        return true
    end
    if string.find(ltyp, "truckbed", 1, true) then
        return true
    end
    if string.find(ltyp, "trailertrunk", 1, true) then
        return true
    end
    if string.find(ltyp, "cargo", 1, true) and not string.find(ltyp, "tank", 1, true) then
        return true
    end
    if string.find(ltyp, "toolbox", 1, true) then
        return true
    end
    return false
end

local function scaleCapacity(container, base)
    if base == nil then
        return base
    end
    -- Fast path: skip all vehicle and container lookups when mult is exactly 1.0.
    -- This covers the most common case (default sandbox) at near-zero cost.
    if not IKFRVP.isTrunkCapacityTuningEnabled() then
        return base
    end
    local mult = sandboxTrunkMult()
    if math.abs(mult - 1.0) < 1e-7 then
        return base
    end
    local vehicle = containerVehicle(container)
    if not vehicle then
        return base
    end
    if not R.isVehicleTrunkCargoContainer(container)
        or not R.vehicleUsesIKFRVPTuning(vehicle)
    then
        return base
    end
    local scaled = tonumber(base) * mult
    if scaled == nil then
        return base
    end
    return math.max(0.01, math.floor(scaled + 0.5))
end

function R.install()
    if R._installed then
        return
    end
    if not ItemContainer or not ItemContainer.class then
        return
    end
    if not __classmetatables or not __classmetatables[ItemContainer.class] then
        return
    end
    local mt = __classmetatables[ItemContainer.class]
    local idx = mt and mt.__index
    if not idx or not idx.getEffectiveCapacity then
        return
    end

    origGetEffectiveCapacity = idx.getEffectiveCapacity
    origGetCapacity = idx.getCapacity

    idx.getEffectiveCapacity = function(self, chr)
        if inCapacityHook then
            return origGetEffectiveCapacity(self, chr)
        end
        inCapacityHook = true
        local base = origGetEffectiveCapacity(self, chr)
        local result = scaleCapacity(self, base)
        inCapacityHook = false
        return result
    end

    if origGetCapacity then
        idx.getCapacity = function(self)
            if inCapacityHook then
                return origGetCapacity(self)
            end
            inCapacityHook = true
            local base = origGetCapacity(self)
            local result = scaleCapacity(self, base)
            inCapacityHook = false
            return result
        end
    end

    R._installed = true
    IKFRVP.debug("trunk-runtime: ItemContainer capacity hooks installed")
end

if Events and Events.OnGameBoot then
    Events.OnGameBoot.Add(function()
        R.install()
    end)
end

R.install()

return R
