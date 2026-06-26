require "IK_ClassBias"

-- B42 Kahlua: Java null globals are not Lua nil; `x = x or {}` does not recover.
if type(IKappaID_SP) ~= "table" then
    IKappaID_SP = {}
end
if type(IK_SP) ~= "table" then
    IK_SP = IKappaID_SP
end

local M = IKappaID_SP

M.ModId = "IKappaID's True Real World Vehicle Physics SinglePlayer"
M.Version = "2.5.0"
M.ReleaseMilestone = "stable-2.5.0"
M.Branch = "stable"
M.SandboxRoot = "IK_SP"
M.PhysicsBuild = "2026-05-28-physics-mirror-tuning-row"
M.TowBuild = "2026-05-24-tow-drive-gate"

local LOAD_RISKY_NAME_FRAGMENTS = { "Trailer", "Smashed", "Burnt", "Wreck" }

function M.isSinglePlayerSession()
    if type(isMultiplayer) == "function" then
        return not isMultiplayer()
    end
    return true
end

function M.isActiveHere()
    if not M.isSinglePlayerSession() then
        return false
    end
    -- Dedicated server JVM only (no local client): SP mod must not run there.
    if type(isServer) == "function" and isServer() and type(isClient) == "function" and not isClient() then
        return false
    end
    -- Integrated singleplayer is not isClient() per PZwiki; do not require isClient() here.
    return true
end

function M.sandbox()
    if SandboxVars and SandboxVars.IK_SP then
        return SandboxVars.IK_SP
    end
    return nil
end

function M.option(name, fallback)
    local root = M.sandbox()
    if root and root[name] ~= nil then
        return root[name]
    end
    return fallback
end

function M.boolOption(name, fallback)
    return M.option(name, fallback) == true
end

function M.numberOption(name, fallback, minimum, maximum)
    local value = tonumber(M.option(name, fallback))
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

function M.isEnabled()
    return M.boolOption("Enabled", true)
end

function M.isDebugLoggingEnabled()
    return M.boolOption("DebugLogging", false)
end

function M.powerMult()
    return M.numberOption("PowerMult", 1.0, 0.15, 5.0)
end

function M.brakeMult()
    return M.numberOption("BrakeMult", 1.0, 0.15, 5.0)
end

function M.massMult()
    return M.numberOption("MassMult", 1.0, 0.35, 3.0)
end

function M.accelerationMult()
    return M.numberOption("AccelerationMult", 1.0, 0.50, 2.0)
end

function M.sportPowerBias()
    return M.numberOption("SportPowerBias", 1.0, 0.50, 2.0)
end

function M.heavyPowerBias()
    return M.numberOption("HeavyPowerBias", 1.0, 0.50, 2.0)
end

function M.brakeStopTimeMult()
    return M.numberOption("BrakeStopTimeMult", 1.0, 0.40, 2.5)
end

function M.massUpliftMult()
    return M.numberOption("MassUpliftMult", 1.0, 0.70, 1.35)
end

function M.isProfileTuneEnabled()
    return M.boolOption("EnableProfileTune", true)
end

function M.isHandlingTuneEnabled()
    return M.boolOption("EnableHandlingTune", true)
end

function M.suspensionFirmness()
    return M.numberOption("SuspensionFirmness", 1.0, 0.70, 1.60)
end

function M.wheelGripMult()
    return M.numberOption("WheelGripMult", 1.0, 0.50, 1.80)
end

function M.steeringResponseMult()
    return M.numberOption("SteeringResponseMult", 1.0, 0.35, 1.50)
end

function M.steeringClampMult()
    return M.numberOption("SteeringClampMult", 1.0, 0.60, 1.20)
end

function M.bodyRollMult()
    return M.numberOption("BodyRollMult", 1.0, 0.50, 1.50)
end

function M.brakeCreepMult()
    return M.numberOption("BrakeCreepMult", 1.0, 0.25, 2.5)
end

-- When sandbox driving / handling options change, Layer A must re-apply (signature stored in Physics).
function M.physicsFeelSignature()
    local parts = {
        M.formatNumber(M.powerMult()),
        M.formatNumber(M.accelerationMult()),
        M.formatNumber(M.brakeMult()),
        M.formatNumber(M.brakeStopTimeMult()),
        M.formatNumber(M.massMult()),
        M.formatNumber(M.massUpliftMult()),
        tostring(M.isProfileTuneEnabled()),
        tostring(M.isHandlingTuneEnabled()),
        M.formatNumber(M.suspensionFirmness()),
        M.formatNumber(M.wheelGripMult()),
        M.formatNumber(M.steeringResponseMult()),
        M.formatNumber(M.steeringClampMult()),
        M.formatNumber(M.bodyRollMult()),
    }
    IK_ClassBias.appendSignatureParts(M, parts)
    return table.concat(parts, "|")
end

function M.side()
    if type(isServer) == "function" and isServer() then
        return "server"
    end
    if type(isClient) == "function" and isClient() then
        return "client"
    end
    return "unknown"
end

function M.log(message)
    print("[" .. M.ModId .. "][" .. M.side() .. "] " .. tostring(message))
end

function M.debug(message)
    if M.isDebugLoggingEnabled() then
        M.log(message)
    end
end

function M.formatNumber(value)
    local n = tonumber(value)
    if n == nil then
        return "nil"
    end
    return string.format("%.3f", n)
end

-- VehicleScript getters: use explicit :call() — getSteeringClamp(speed) needs speed (0 = low-speed).
local SCRIPT_GETTERS = {
    getEngineForce           = { call = function(s) return s:getEngineForce() end,           fields = { "engineForce" } },
    getMass                  = { call = function(s) return s:getMass() end,                  fields = { "mass" } },
    getMaxSpeed              = { call = function(s) return s:getMaxSpeed() end,              fields = { "maxSpeed" } },
    getMaxSpeedReverse       = { call = function(s) return s:getMaxSpeedReverse() end,       fields = { "maxSpeedReverse" } },
    getBrakingForce          = { call = function(s) return s:getBrakingForce() end,          fields = { "brakingForce" } },
    getStoppingMovementForce = { call = function(s) return s:getStoppingMovementForce() end, fields = { "stoppingMovementForce" } },
    getSteeringIncrement     = { call = function(s) return s:getSteeringIncrement() end,     fields = { "steeringIncrement" } },
    getRollInfluence         = { call = function(s) return s:getRollInfluence() end },
    getWheelFriction         = { call = function(s) return s:getWheelFriction() end,          fields = { "wheelFriction" } },
    getSuspensionStiffness   = { call = function(s) return s:getSuspensionStiffness() end,     fields = { "suspensionStiffness" } },
    getSuspensionDamping     = { call = function(s) return s:getSuspensionDamping() end,     fields = { "suspensionDamping" } },
    getSuspensionCompression = { call = function(s) return s:getSuspensionCompression() end, fields = { "suspensionCompression" } },
    getSteeringClamp         = { call = function(s) return s:getSteeringClamp(0) end,         fields = { "steeringClamp" } },
}

function M.readScriptNumber(script, getterName)
    if not script or not getterName then
        return nil
    end
    local spec = SCRIPT_GETTERS[getterName]
    if not spec then
        return nil
    end

    if spec.call and script[getterName] then
        local n = M.finiteNumber(spec.call(script))
        if n ~= nil then
            return n
        end
    end

    if spec.fields then
        for i = 1, #spec.fields do
            local n = M.finiteNumber(script[spec.fields[i]])
            if n ~= nil then
                return n
            end
        end
    end

    return nil
end

function M.getScriptFullName(script)
    if not script then
        return ""
    end
    if script.getFullName then
        local full = script:getFullName()
        if full and full ~= "" then
            return full
        end
    end
    if script.getName then
        return script:getName() or ""
    end
    return ""
end

function M.getScriptName(script)
    if script and script.getName then
        local name = script:getName()
        if name and name ~= "" then
            return name
        end
    end
    return M.getScriptFullName(script)
end

function M.getScriptLoadName(script)
    if script and script.getName then
        local name = script:getName()
        if name and name ~= "" then
            return name
        end
    end
    return M.getScriptFullName(script)
end

local function fieldsHasPositive(fields, key)
    return fields and fields[key] and fields[key] > 0
end

function M.isScriptNameLoadRisky(fullName, profileClass)
    if not fullName or fullName == "" then
        return true
    end
    if profileClass == "trailer" then
        for i = 1, #LOAD_RISKY_NAME_FRAGMENTS do
            local frag = LOAD_RISKY_NAME_FRAGMENTS[i]
            if frag ~= "Trailer" and string.find(fullName, frag, 1, true) then
                return true
            end
        end
        return false
    end
    for i = 1, #LOAD_RISKY_NAME_FRAGMENTS do
        if string.find(fullName, LOAD_RISKY_NAME_FRAGMENTS[i], 1, true) then
            return true
        end
    end
    return false
end

-- VehicleScript:Load() throws on incomplete workshop scripts. No pcall — skip instead.
function M.canSafelyVehicleScriptLoad(script, fields, profileClass)
    if not script or not script.Load then
        return false, "no_load"
    end

    local fullName = M.getScriptFullName(script)
    if M.isScriptNameLoadRisky(fullName, profileClass) then
        return false, "risky_name"
    end

    if profileClass == "trailer" then
        if type(fields) ~= "table" or not fields.mass or fields.mass <= 0 then
            return false, "no_trailer_mass"
        end
        local loadName = M.getScriptLoadName(script)
        if loadName == "" then
            return false, "no_name"
        end
        return true, loadName
    end

    local loadName = M.getScriptLoadName(script)
    if loadName == "" then
        return false, "no_name"
    end

    if script.getWheelCount then
        local wheelCount = script:getWheelCount()
        if wheelCount == nil or wheelCount <= 0 then
            return false, "no_wheels"
        end
    end

    if script.getGearRatioCount then
        local gearCount = script:getGearRatioCount()
        if gearCount == nil or gearCount <= 0 then
            return false, "no_gears"
        end
    end

    if script.getPartCount then
        local partCount = script:getPartCount()
        if partCount == nil or partCount <= 0 then
            return false, "no_parts"
        end
    end

    local mass = M.readScriptNumber(script, "getMass")
    if (mass == nil or mass <= 0) and not fieldsHasPositive(fields, "mass") then
        return false, "no_mass"
    end

    local engine = M.readScriptNumber(script, "getEngineForce")
    if (engine == nil or engine <= 0) and not fieldsHasPositive(fields, "engineForce") then
        return false, "no_script_engine"
    end

    local brake = M.readScriptNumber(script, "getBrakingForce")
    if (brake == nil or brake <= 0) and not fieldsHasPositive(fields, "brakingForce") then
        return false, "no_script_brake"
    end

    if script.getPhysicsShapeCount then
        local shapeCount = script:getPhysicsShapeCount()
        if shapeCount == nil or shapeCount <= 0 then
            return false, "no_physics_shapes"
        end
    end

    if type(fields) == "table" then
        if not fields.mass or fields.mass <= 0 then
            return false, "no_fields_mass"
        end
        if not fields.engineForce or fields.engineForce <= 0 then
            return false, "no_fields_engine"
        end
        if not fields.brakingForce or fields.brakingForce <= 0 then
            return false, "no_fields_brake"
        end
    else
        return false, "no_fields"
    end

    return true, loadName
end

function M.javaListSize(list)
    if not list then
        return 0
    end
    if list.size then
        return list:size()
    end
    return 0
end

function M.javaListGet(list, index)
    if list and list.get then
        return list:get(index)
    end
    return nil
end

-- VehicleScript:Load expects the same brace payload as the release mod (see IKappaID.fieldPayload).
local LOAD_PAYLOAD_ORDER = {
    "engineForce",
    "mass",
    "brakingForce",
    "stoppingMovementForce",
    "steeringIncrement",
    "steeringClamp",
    "rollInfluence",
    "wheelFriction",
    "suspensionStiffness",
    "suspensionDamping",
    "suspensionCompression",
}

local function loadPayloadRhs(key, value)
    if key == "brakingForce" then
        return tostring(math.floor(value + 0.5))
    end
    if key == "stoppingMovementForce" then
        return string.format("%.2ff", value)
    end
    if key == "steeringIncrement" then
        return string.format("%.5ff", value)
    end
    if key == "steeringClamp" or key == "rollInfluence" or key == "wheelFriction"
        or key == "suspensionStiffness" or key == "suspensionDamping" or key == "suspensionCompression" then
        return string.format("%.3ff", value)
    end
    return tostring(value)
end

function M.buildLoadPayload(fields, profileClass)
    if type(fields) ~= "table" then
        return nil
    end
    if profileClass == "trailer" then
        if not fields.mass or fields.mass <= 0 then
            return nil
        end
        return "{ mass = " .. tostring(fields.mass) .. " }"
    end
    if not fields.mass or fields.mass <= 0 then
        return nil
    end
    if not fields.engineForce or fields.engineForce <= 0 then
        return nil
    end
    if not fields.brakingForce or fields.brakingForce <= 0 then
        return nil
    end
    local parts = {}
    for i = 1, #LOAD_PAYLOAD_ORDER do
        local key = LOAD_PAYLOAD_ORDER[i]
        local value = fields[key]
        if value ~= nil then
            parts[#parts + 1] = key .. " = " .. loadPayloadRhs(key, value)
        end
    end
    if #parts == 0 then
        return nil
    end
    return "{ " .. table.concat(parts, ", ") .. " }"
end

function M.enginePowerFromScriptForce(vehicle, scriptForce)
    local mult = M.powerMult()
    local quality = 100
    if vehicle and vehicle.getEngineQuality then
        local q = vehicle:getEngineQuality()
        if q then
            quality = q
        end
    end
    local qualityMod = math.max(0.6, quality / 100)
    return math.floor((scriptForce or 0) * mult * qualityMod + 0.5)
end

function M.enginePowerNeedsUpdate(current, target)
    if current == nil or target == nil then
        return false
    end
    return math.abs(current - target) >= 1
end

function M.finiteNumber(value)
    local n = tonumber(value)
    if n == nil or n ~= n or n == math.huge or n == -math.huge then
        return nil
    end
    return n
end

function M.callMethod0(obj, methodName)
    if not obj or not methodName or not obj[methodName] then
        return nil
    end
    return obj[methodName](obj)
end

function M.isTrunkTuneEnabled()
    return M.boolOption("EnableTrunkTune", true)
end

function M.trunkCapacityMult()
    return M.numberOption("TrunkCapacityMult", 1.0, 0.25, 4.0)
end

function M.isTowAssistEnabled()
    return M.boolOption("EnableTowAssist", true)
end

function M.towAssistFactor()
    return M.numberOption("TowAssistFactor", 5.0, 0.0, 15.0)
end

function M.yieldTowToCSR()
    return M.boolOption("YieldTowToCSR", true)
end

function M.isReverseTowAssistEnabled()
    return M.boolOption("EnableReverseTowAssist", true)
end

function M.towReverseAssistMult()
    return M.numberOption("TowReverseAssistMult", 0.7, 0.0, 1.0)
end

function M.towLowSpeedBoost()
    return M.numberOption("TowLowSpeedBoost", 1.0, 1.0, 2.0)
end

function M.towAccelSoftness()
    return M.numberOption("TowAccelSoftness", 0.65, 0.25, 1.0)
end

function M.towMaxLoadRatio()
    return M.numberOption("TowMaxLoadRatio", 3.0, 1.0, 5.0)
end

return M


