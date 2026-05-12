IKFRVP = IKFRVP or {}

IKFRVP.ModId = "IKappaIDFadedRealWorldVehiclePhysics"
IKFRVP.ModName = "IKappaID & Faded's True Real World Vehicle Physics"
IKFRVP.Version = "1.0"
IKFRVP.CommandModule = "IKFRVP"
IKFRVP.ServerStateKey = "IKFRVP_ServerState"

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
    if #parts == 0 then
        return nil
    end
    return "{ " .. table.concat(parts, ", ") .. " }"
end

return IKFRVP
