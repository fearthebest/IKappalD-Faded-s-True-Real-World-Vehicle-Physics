IKFRVP = IKFRVP or {}

IKFRVP.ModId = "IKappaIDFadedRealWorldVehiclePhysics"
IKFRVP.ModName = "IKappaID & Faded's True Real World Vehicle Physics"
IKFRVP.Version = "1.1.3"
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

-- Dispatch table for IKFRVP.readScriptNumber. Each entry describes how to read one numeric
-- VehicleScript field:
--   call    -> function(script) -> raw value, wrapped in pcall by the caller
--   fields  -> ordered list of Lua-side fallback field names (e.g. script.mass) read when
--             the Java getter is missing or throws; the first non-nil one wins
-- Adding a new tunable field is a one-line entry here instead of a copy-paste branch in
-- a 140-line if/elseif ladder (which is how getSteeringClamp went stale in v1.1.3).
local SCRIPT_GETTERS = {
    getEngineForce           = { call = function(s) return s:getEngineForce() end },
    getMass                  = { call = function(s) return s:getMass() end },
    getMaxSpeed              = { call = function(s) return s:getMaxSpeed() end,              fields = { "maxSpeed" } },
    getMaxSpeedReverse       = { call = function(s) return s:getMaxSpeedReverse() end,       fields = { "maxSpeedReverse" } },
    getBrakingForce          = { call = function(s) return s:getBrakingForce() end,          fields = { "brakingForce" } },
    getStoppingMovementForce = { call = function(s) return s:getStoppingMovementForce() end, fields = { "stoppingMovementForce" } },
    getSteeringIncrement     = { call = function(s) return s:getSteeringIncrement() end },
    getRollInfluence         = { call = function(s) return s:getRollInfluence() end },
    getWheelFriction         = { call = function(s) return s:getWheelFriction() end },
    getSuspensionStiffness   = { call = function(s) return s:getSuspensionStiffness() end },
    getSuspensionDamping     = { call = function(s) return s:getSuspensionDamping() end },
    getSuspensionCompression = { call = function(s) return s:getSuspensionCompression() end },
    getSuspensionRestLength  = { call = function(s) return s:getSuspensionRestLength() end },
    getSuspensionTravel      = { call = function(s) return s:getSuspensionTravel() end },
    -- VehicleScript.getSteeringClamp(speed) requires a speed argument; 0 = low-speed clamp,
    -- which is what the tuner uses as its baseline reference.
    getSteeringClamp         = { call = function(s) return s:getSteeringClamp(0) end },
}

function IKFRVP.readScriptNumber(script, getterName)
    if not script or not getterName then
        return nil
    end
    local spec = SCRIPT_GETTERS[getterName]
    if not spec then
        return nil
    end

    local methodName = getterName
    if script[methodName] then
        local ok, raw = pcall(spec.call, script)
        if ok then
            local v = tonumber(raw)
            if v ~= nil then
                return v
            end
        end
    end

    if spec.fields then
        for i = 1, #spec.fields do
            local f = spec.fields[i]
            local raw = script[f]
            if raw ~= nil then
                local v = tonumber(raw)
                if v ~= nil then
                    return v
                end
            end
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

-- Field -> formatter for IKFRVP.fieldPayload. Each formatter takes the numeric value
-- already-validated as non-nil and returns the right-hand side of the VehicleScript:Load
-- key/value pair. The order of PAYLOAD_FIELD_ORDER matches the legacy payload string so
-- existing tests / logs comparing output stay diff-friendly.
local function fmtInt(v)
    return tostring(math.floor(v + 0.5))
end
local function fmtPlain(v)
    return tostring(v)
end
local function fmtF(fmt)
    return function(v)
        return string.format(fmt, v)
    end
end

local PAYLOAD_FORMATTERS = {
    engineForce           = fmtPlain,
    mass                  = fmtPlain,
    maxSpeedReverse       = fmtF("%.2ff"),
    brakingForce          = fmtInt,
    stoppingMovementForce = fmtF("%.2ff"),
    steeringIncrement     = fmtF("%.5ff"),
    steeringClamp         = fmtF("%.3ff"),
    rollInfluence         = fmtF("%.3ff"),
    wheelFriction         = fmtF("%.3ff"),
    suspensionStiffness   = fmtF("%.3ff"),
    suspensionDamping     = fmtF("%.3ff"),
    suspensionCompression = fmtF("%.3ff"),
    suspensionRestLength  = fmtF("%.3ff"),
    maxSuspensionTravelCm = fmtInt,
}

local PAYLOAD_FIELD_ORDER = {
    "engineForce",
    "mass",
    "maxSpeedReverse",
    "brakingForce",
    "stoppingMovementForce",
    "steeringIncrement",
    "steeringClamp",
    "rollInfluence",
    "wheelFriction",
    "suspensionStiffness",
    "suspensionDamping",
    "suspensionCompression",
    "suspensionRestLength",
    "maxSuspensionTravelCm",
}

function IKFRVP.fieldPayload(fields)
    if not fields then
        return nil
    end
    local parts = {}
    for i = 1, #PAYLOAD_FIELD_ORDER do
        local key = PAYLOAD_FIELD_ORDER[i]
        local val = fields[key]
        if val ~= nil then
            parts[#parts + 1] = key .. " = " .. PAYLOAD_FORMATTERS[key](val)
        end
    end
    if #parts == 0 then
        return nil
    end
    return "{ " .. table.concat(parts, ", ") .. " }"
end

-- Exposed so the Tuner can iterate the same list when building change diffs.
IKFRVP._payloadFieldOrder = PAYLOAD_FIELD_ORDER

return IKFRVP
