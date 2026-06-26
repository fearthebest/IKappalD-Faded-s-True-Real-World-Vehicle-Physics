require "IK_SP_Core"
require "IK_ClassBias"

IK_SP.Handling = IK_SP.Handling or {}

local H = IK_SP.Handling
local C = IK_SP

local CLASS_SUSPENSION_FIRM = {
    sport = 1.05,
    standard = 1.0,
    compact = 1.02,
    heavy = 0.94,
}

local PROFILE_SUSPENSION_FIRM = {
    Sport = 1.05,
    Race = 1.06,
    Offroad = 0.92,
    Pickup = 0.96,
    Van = 0.90,
    StepVan = 0.88,
    CrewPickup = 0.95,
}

local function normalizeClass(className)
    if className == "sport" or className == "standard" or className == "compact" or className == "heavy" then
        return className
    end
    return "standard"
end

local function isTrailerLike(profile)
    return profile and profile.class == "trailer"
end

local function isLikelyThirdPartyBaseVehicle(scriptFullName)
    if not scriptFullName or scriptFullName == "" then
        return false
    end
    return string.match(scriptFullName, "^Base%.%d") ~= nil
end

local function clamp(value, lo, hi)
    if value == nil then
        return nil
    end
    if lo ~= nil and value < lo then
        value = lo
    end
    if hi ~= nil and value > hi then
        value = hi
    end
    return value
end

function H.extendBaseline(script, baseline)
    if not script or not baseline then
        return baseline
    end
    baseline.steeringIncrement = C.readScriptNumber(script, "getSteeringIncrement")
    baseline.steeringClamp = C.readScriptNumber(script, "getSteeringClamp")
    baseline.wheelFriction = C.readScriptNumber(script, "getWheelFriction")
    baseline.rollInfluence = C.readScriptNumber(script, "getRollInfluence")
    baseline.suspensionStiffness = C.readScriptNumber(script, "getSuspensionStiffness")
    baseline.suspensionDamping = C.readScriptNumber(script, "getSuspensionDamping")
    baseline.suspensionCompression = C.readScriptNumber(script, "getSuspensionCompression")
    return baseline
end

function H.effectiveSuspensionFirmness(profile)
    local firm = C.suspensionFirmness()
    if not profile then
        return firm
    end
    local cls = normalizeClass(profile.class or "standard")
    if CLASS_SUSPENSION_FIRM[cls] then
        firm = firm * CLASS_SUSPENSION_FIRM[cls]
    end
    if profile.id and PROFILE_SUSPENSION_FIRM[profile.id] then
        firm = firm * PROFILE_SUSPENSION_FIRM[profile.id]
    end
    firm = firm * IK_ClassBias.biasForProfile(C, profile, "SuspensionBias")
    return firm
end

function H.applyFields(profile, baseline, fields, scriptFullName)
    if not C.isHandlingTuneEnabled() or not baseline or not fields then
        return
    end
    if isTrailerLike(profile) then
        return
    end
    if isLikelyThirdPartyBaseVehicle(scriptFullName) then
        return
    end

    local inc = baseline.steeringIncrement
    if inc and inc > 0 then
        local mult = C.steeringResponseMult() * IK_ClassBias.biasForProfile(C, profile, "SteeringBias")
        local v = inc * mult
        v = clamp(v, 0.0025, 0.12)
        if v and math.abs(v - inc) > 1e-7 then
            fields.steeringIncrement = v
        end
    end

    local steerClamp = baseline.steeringClamp
    if steerClamp and steerClamp > 0 then
        local v = steerClamp * C.steeringClampMult()
        v = clamp(v, 0.06, 1.10)
        if v and math.abs(v - steerClamp) > 1e-7 then
            fields.steeringClamp = v
        end
    end

    local wf = baseline.wheelFriction
    if wf and wf > 0 then
        local v = wf * C.wheelGripMult() * IK_ClassBias.biasForProfile(C, profile, "GripBias")
        v = clamp(v, 0.45, 2.50)
        if v and math.abs(v - wf) > 1e-6 then
            fields.wheelFriction = v
        end
    end

    local roll = baseline.rollInfluence
    if roll ~= nil and roll >= 0 then
        local v = clamp(roll * C.bodyRollMult() * IK_ClassBias.biasForProfile(C, profile, "RollBias"), 0.0, 1.0)
        if math.abs(v - roll) > 1e-6 then
            fields.rollInfluence = v
        end
    end

    local firm = H.effectiveSuspensionFirmness(profile)
    if math.abs(firm - 1.0) > 0.001 then
        local stiff = baseline.suspensionStiffness
        if stiff and stiff > 0 then
            fields.suspensionStiffness = stiff * firm
        end
        local damp = baseline.suspensionDamping
        if damp and damp > 0 then
            local blend = 0.5 + 0.5 * firm
            fields.suspensionDamping = damp * blend
        end
        local comp = baseline.suspensionCompression
        if comp and comp > 0 then
            local blend = 0.5 + 0.5 * firm
            fields.suspensionCompression = comp * blend
        end
    end
end

return H


