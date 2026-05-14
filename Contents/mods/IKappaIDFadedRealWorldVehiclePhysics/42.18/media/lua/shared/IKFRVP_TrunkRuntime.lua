require "IKFRVP_Core"
require "IKFRVP_Profiles"

IKFRVP.TrunkRuntime = IKFRVP.TrunkRuntime or {}

local R = IKFRVP.TrunkRuntime

R._installed = false
local origGetEffectiveCapacity = nil

local function sandboxTrunkMult()
    return IKFRVP.numberOption("TrunkCapacityMult", 1.0, 0.35, 2.5)
end

local function clampMultForWorkshopPack(scriptFullName, mult)
    if not scriptFullName or scriptFullName == "" then
        return mult
    end
    if not string.match(scriptFullName, "^Base%.%d") then
        return mult
    end
    return IKFRVP.clamp(mult, 0.82, 1.22) or mult
end

local function multForVehicle(vehicle)
    local mult = sandboxTrunkMult()
    if math.abs(mult - 1.0) < 1e-7 then
        return 1.0
    end
    local script = vehicle and vehicle.getScript and vehicle:getScript() or nil
    local fullName = script and IKFRVP.getScriptFullName(script) or ""
    mult = clampMultForWorkshopPack(fullName, mult)
    return mult
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
    local ok, ct = pcall(function()
        return container:getContentType()
    end)
    if not ok or ct == nil then
        return false
    end
    return string.lower(tostring(ct)) == "gasoline"
end

function R.isVehicleTrunkCargoContainer(container)
    if not container or not container.getParent or not instanceof then
        return false
    end
    local okP, parent = pcall(function()
        return container:getParent()
    end)
    if not okP or not parent or not instanceof(parent, "BaseVehicle") then
        return false
    end
    if isGasolineContainer(container) then
        return false
    end
    local typ = ""
    if container.getType then
        local okT, t = pcall(function()
            return container:getType()
        end)
        if okT and t ~= nil then
            typ = tostring(t)
        end
    end
    local ltyp = string.lower(typ)
    if ltyp == "" then
        return false
    end
    if string.find(ltyp, "glove", 1, true) then
        return false
    end
    if string.find(ltyp, "gas", 1, true) and not string.find(ltyp, "bag", 1, true) then
        return false
    end
    if typ == "TruckBed" or typ == "TruckBedOpen" or typ == "TrailerTrunk" or typ == "TrailerAnimalFood" then
        return true
    end
    if string.find(ltyp, "truckbed", 1, true) then
        return true
    end
    if string.find(ltyp, "trailertrunk", 1, true) then
        return true
    end
    return false
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

    idx.getEffectiveCapacity = function(self, chr)
        local base = origGetEffectiveCapacity(self, chr)
        if base == nil then
            return base
        end
        local parentOk, parent = pcall(function()
            return self:getParent()
        end)
        if not parentOk or not parent or not instanceof(parent, "BaseVehicle") then
            return base
        end
        if not R.isVehicleTrunkCargoContainer(self) then
            return base
        end
        if not R.vehicleUsesIKFRVPTuning(parent) then
            return base
        end
        local mult = multForVehicle(parent)
        if math.abs(mult - 1.0) < 1e-7 then
            return base
        end
        local scaled = tonumber(base) * mult
        if scaled == nil then
            return base
        end
        return math.max(0.01, math.floor(scaled + 0.5))
    end

    R._installed = true
    IKFRVP.debug("trunk-runtime: ItemContainer.getEffectiveCapacity wrap installed")
end

if Events and Events.OnGameBoot then
    Events.OnGameBoot.Add(function()
        R.install()
    end)
end

R.install()

return R
