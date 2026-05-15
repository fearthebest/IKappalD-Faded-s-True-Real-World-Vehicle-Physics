IKFRVP = IKFRVP or {}

IKFRVP.ModId = "IKappaIDFadedRealWorldVehiclePhysics"
IKFRVP.ModName = "IKappaID & Faded's True Real World Vehicle Physics"
IKFRVP.Version = "1.1.4"
IKFRVP.CommandModule = "IKFRVP"
IKFRVP.ServerStateKey = "IKFRVP_ServerState"

-- Unofficial API references (Java binding surface + inferred Lua): keep VehicleScript usage aligned with these.
-- https://demiurgequantified.github.io/ProjectZomboidJavaDocs/
-- https://demiurgequantified.github.io/ProjectZomboidLuaDocs/index.html

local function sandboxRoot()
    if SandboxVars and SandboxVars.IKFRVP then
        return SandboxVars.IKFRVP
    end
    return nil
end

function IKFRVP.option(name, fallback)
    local root = sandboxRoot()
    if root and root[name] ~= nil then
        return root[name]
    end
    return fallback
end

function IKFRVP.boolOption(name, fallback)
    local value = IKFRVP.option(name, fallback)
    return value == true
end

function IKFRVP.numberOption(name, fallback, minimum, maximum)
    local value = tonumber(IKFRVP.option(name, fallback))
    if value == nil then
        value = fallback
    end
    if minimum ~= nil and value < minimum then
        value = minimum
    end
    if maximum ~= nil and value > maximum then
        value = maximum
    end
    return value
end

-- Maps profile.class to SandboxVars.IKFRVP.{Prefix}*Mult option names (e.g. heavy -> HeavyRollMult).
local CLASS_TUNING_PREFIX = {
    compact = "Compact",
    standard = "Standard",
    sport = "Sport",
    heavy = "Heavy",
    trailer = "Trailer",
}

function IKFRVP.classTuningMult(classId, suffix, fallback, minimum, maximum)
    local prefix = CLASS_TUNING_PREFIX[classId] or "Standard"
    return IKFRVP.numberOption(prefix .. suffix, fallback, minimum, maximum)
end

function IKFRVP.isEnabled()
    return IKFRVP.boolOption("Enabled", true)
end

function IKFRVP.isDebugLoggingEnabled()
    return IKFRVP.boolOption("DebugLogging", false)
end

function IKFRVP.isProfileTuningEnabled()
    return IKFRVP.boolOption("ProfileTuning", true)
end

function IKFRVP.isGenericMultiplierTuningEnabled()
    return IKFRVP.boolOption("GenericMultiplierTuning", false)
end

function IKFRVP.isTrunkCapacityTuningEnabled()
    return IKFRVP.boolOption("TrunkCapacityTuning", true)
end

function IKFRVP.isHandlingPhysicsEnabled()
    return IKFRVP.boolOption("HandlingPhysics", false)
end

function IKFRVP.isAuditOnly()
    return IKFRVP.boolOption("AuditOnly", false)
end

function IKFRVP.isCSRCompatibilityModeEnabled()
    return IKFRVP.boolOption("CSRCompatibilityMode", true)
end

function IKFRVP.getProbeIntervalTicks()
    return IKFRVP.numberOption("ProbeIntervalTicks", 300, 60, 1200)
end

function IKFRVP.clamp(value, minimum, maximum)
    local number = tonumber(value)
    if number == nil then
        return nil
    end
    if minimum ~= nil and number < minimum then
        return minimum
    end
    if maximum ~= nil and number > maximum then
        return maximum
    end
    return number
end

function IKFRVP.side()
    if type(isServer) == "function" and isServer() then
        return "server"
    end
    if type(isClient) == "function" and isClient() then
        return "client"
    end
    return "singleplayer"
end

function IKFRVP.log(message)
    print("[" .. IKFRVP.ModId .. "][" .. IKFRVP.side() .. "] " .. tostring(message))
end

function IKFRVP.debug(message)
    if IKFRVP.isDebugLoggingEnabled() then
        IKFRVP.log(message)
    end
end

function IKFRVP.modActive(modId)
    if not modId or modId == "" then
        return false
    end
    if getActivatedMods then
        local mods = getActivatedMods()
        if mods and mods.contains and mods:contains(modId) then
            return true
        end
    end
    return false
end

function IKFRVP.isCSRActive()
    if IKFRVP.modActive("CommonSenseReborn") then
        return true
    end
    return CSR_FeatureFlags ~= nil
        or CSR_VehicleClaim ~= nil
        or CSR_SeatbeltSystem ~= nil
end

function IKFRVP.javaListSize(list)
    if list and list.size then
        return tonumber(list:size()) or 0
    end
    return 0
end

function IKFRVP.javaListGet(list, index)
    if list and list.get then
        return list:get(index)
    end
    return nil
end

function IKFRVP.getScriptName(script)
    if script and script.getName then
        local name = script:getName()
        if name ~= nil and tostring(name) ~= "" then
            return tostring(name)
        end
    end
    return "unknown"
end

function IKFRVP.getScriptFullName(script)
    if script and script.getFullName then
        local fullName = script:getFullName()
        if fullName ~= nil and tostring(fullName) ~= "" then
            return tostring(fullName)
        end
    end
    return IKFRVP.getScriptName(script)
end

function IKFRVP.getVehicleScript(vehicle)
    if vehicle and vehicle.getScript then
        return vehicle:getScript()
    end
    return nil
end

function IKFRVP.getVehicleScriptName(vehicle)
    if vehicle and vehicle.getScriptName then
        local name = vehicle:getScriptName()
        if name ~= nil then
            return tostring(name)
        end
    end
    local script = IKFRVP.getVehicleScript(vehicle)
    return IKFRVP.getScriptFullName(script)
end

function IKFRVP.readScriptNumber(script, getterName)
    if not script or not getterName then
        return nil
    end
    if getterName == "getEngineForce" and script.getEngineForce then
        return tonumber(script:getEngineForce())
    end
    if getterName == "getMass" and script.getMass then
        return tonumber(script:getMass())
    end
    if getterName == "getMaxSpeed" then
        if script.getMaxSpeed then
            local ok, v = pcall(function()
                return tonumber(script:getMaxSpeed())
            end)
            if ok and v ~= nil then
                return v
            end
        end
        if script.maxSpeed ~= nil then
            return tonumber(script.maxSpeed)
        end
        return nil
    end
    if getterName == "getMaxSpeedReverse" then
        if script.getMaxSpeedReverse then
            local ok, v = pcall(function()
                return tonumber(script:getMaxSpeedReverse())
            end)
            if ok and v ~= nil then
                return v
            end
        end
        if script.maxSpeedReverse ~= nil then
            return tonumber(script.maxSpeedReverse)
        end
        return nil
    end
    if getterName == "getBrakingForce" then
        if script.getBrakingForce then
            local ok, v = pcall(function()
                return tonumber(script:getBrakingForce())
            end)
            if ok and v ~= nil then
                return v
            end
        end
        if script.brakingForce ~= nil then
            return tonumber(script.brakingForce)
        end
        return nil
    end
    if getterName == "getStoppingMovementForce" then
        if script.getStoppingMovementForce then
            local ok, v = pcall(function()
                return tonumber(script:getStoppingMovementForce())
            end)
            if ok and v ~= nil then
                return v
            end
        end
        if script.stoppingMovementForce ~= nil then
            return tonumber(script.stoppingMovementForce)
        end
        return nil
    end
    if getterName == "getSteeringIncrement" and script.getSteeringIncrement then
        local ok, v = pcall(function()
            return tonumber(script:getSteeringIncrement())
        end)
        if ok and v ~= nil then
            return v
        end
    end
    if getterName == "getRollInfluence" and script.getRollInfluence then
        local ok, v = pcall(function()
            return tonumber(script:getRollInfluence())
        end)
        if ok and v ~= nil then
            return v
        end
    end
    if getterName == "getWheelFriction" and script.getWheelFriction then
        local ok, v = pcall(function()
            return tonumber(script:getWheelFriction())
        end)
        if ok and v ~= nil then
            return v
        end
    end
    if getterName == "getSuspensionStiffness" and script.getSuspensionStiffness then
        local ok, v = pcall(function()
            return tonumber(script:getSuspensionStiffness())
        end)
        if ok and v ~= nil then
            return v
        end
    end
    if getterName == "getSuspensionDamping" and script.getSuspensionDamping then
        local ok, v = pcall(function()
            return tonumber(script:getSuspensionDamping())
        end)
        if ok and v ~= nil then
            return v
        end
    end
    if getterName == "getSuspensionCompression" and script.getSuspensionCompression then
        local ok, v = pcall(function()
            return tonumber(script:getSuspensionCompression())
        end)
        if ok and v ~= nil then
            return v
        end
    end
    if getterName == "getSuspensionRestLength" and script.getSuspensionRestLength then
        local ok, v = pcall(function()
            return tonumber(script:getSuspensionRestLength())
        end)
        if ok and v ~= nil then
            return v
        end
    end
    if getterName == "getSuspensionTravel" and script.getSuspensionTravel then
        local ok, v = pcall(function()
            return tonumber(script:getSuspensionTravel())
        end)
        if ok and v ~= nil then
            return v
        end
    end
    if getterName == "getSteeringClamp" and script.getSteeringClamp then
        local ok, v = pcall(function()
            return tonumber(script:getSteeringClamp(0))
        end)
        if ok and v ~= nil then
            return v
        end
    end
    return nil
end

function IKFRVP.formatNumber(value)
    local number = tonumber(value)
    if number == nil then
        return "n/a"
    end
    return string.format("%.3f", number)
end

function IKFRVP.fieldPayload(fields)
    local parts = {}
    if fields.engineForce ~= nil then
        parts[#parts + 1] = "engineForce = " .. tostring(fields.engineForce)
    end
    if fields.mass ~= nil then
        parts[#parts + 1] = "mass = " .. tostring(fields.mass)
    end
    if fields.maxSpeedReverse ~= nil then
        parts[#parts + 1] = "maxSpeedReverse = " .. string.format("%.2ff", fields.maxSpeedReverse)
    end
    if fields.brakingForce ~= nil then
        parts[#parts + 1] = "brakingForce = " .. tostring(math.floor(fields.brakingForce + 0.5))
    end
    if fields.stoppingMovementForce ~= nil then
        parts[#parts + 1] = "stoppingMovementForce = " .. string.format("%.2ff", fields.stoppingMovementForce)
    end
    if fields.steeringIncrement ~= nil then
        parts[#parts + 1] = "steeringIncrement = " .. string.format("%.5ff", fields.steeringIncrement)
    end
    if fields.steeringClamp ~= nil then
        parts[#parts + 1] = "steeringClamp = " .. string.format("%.3ff", fields.steeringClamp)
    end
    if fields.rollInfluence ~= nil then
        parts[#parts + 1] = "rollInfluence = " .. string.format("%.3ff", fields.rollInfluence)
    end
    if fields.wheelFriction ~= nil then
        parts[#parts + 1] = "wheelFriction = " .. string.format("%.3ff", fields.wheelFriction)
    end
    if fields.suspensionStiffness ~= nil then
        parts[#parts + 1] = "suspensionStiffness = " .. string.format("%.3ff", fields.suspensionStiffness)
    end
    if fields.suspensionDamping ~= nil then
        parts[#parts + 1] = "suspensionDamping = " .. string.format("%.3ff", fields.suspensionDamping)
    end
    if fields.suspensionCompression ~= nil then
        parts[#parts + 1] = "suspensionCompression = " .. string.format("%.3ff", fields.suspensionCompression)
    end
    if fields.suspensionRestLength ~= nil then
        parts[#parts + 1] = "suspensionRestLength = " .. string.format("%.3ff", fields.suspensionRestLength)
    end
    if fields.maxSuspensionTravelCm ~= nil then
        parts[#parts + 1] = "maxSuspensionTravelCm = " .. tostring(math.floor(fields.maxSuspensionTravelCm + 0.5))
    end
    if #parts == 0 then
        return nil
    end
    return "{ " .. table.concat(parts, ", ") .. " }"
end

return IKFRVP
