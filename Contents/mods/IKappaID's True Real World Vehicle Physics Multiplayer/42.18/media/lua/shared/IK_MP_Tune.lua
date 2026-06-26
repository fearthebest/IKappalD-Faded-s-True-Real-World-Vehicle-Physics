require "IK_MP_Core"
require "IK_MP_Profiles"
require "IK_MP_Handling"
require "IK_ClassBias"

IK_MP.Tune = IK_MP.Tune or {}

local T = IK_MP.Tune
local C = IK_MP
local P = IK_MP.Profiles
local H = IK_MP.Handling

T._baselines = T._baselines or {}

function T.clearCaches()
    T._baselines = {}
end

local CLASS_POWER_MUL = {
    sport = 1.14,
    standard = 1.10,
    compact = 1.08,
    heavy = 1.05,
}

local PROFILE_POWER_MUL = {
    Sport = 1.06,
    Race = 1.10,
    Luxury = 1.04,
    CompactSport = 1.05,
    ModernSedan = 1.04,
    Van = 1.0,
    StepVan = 0.96,
    Pickup = 1.02,
    Offroad = 1.04,
}

local BRAKE_REF_MASS = 1760
local BRAKE_REF_STOP_SEC = 5.0

local BRAKE_STOP_TIME_SEC = {
    sport = 3.15,
    standard = 4.85,
    compact = 5.05,
    heavy = 7.25,
}

local PROFILE_STOP_TIME_MUL = {
    Sport = 0.92,
    Race = 0.88,
    Luxury = 0.94,
    CompactSport = 0.96,
    Van = 1.22,
    StepVan = 1.32,
    Pickup = 1.08,
    Offroad = 1.05,
    CommercialVan = 1.28,
    HeavyTruck = 1.35,
    MilitaryAPC = 1.12,
}

local BRAKE_FLOOR = 8

local MASS_MAX_UPLIFT = {
    sport = 1.18,
    standard = 1.12,
    compact = 1.12,
    heavy = 1.20,
}

local BRAKE_BASELINE_FALLBACK = {
    sport = 90,
    standard = 75,
    compact = 70,
    heavy = 60,
}

local function normalizeClass(className)
    if className == "sport" or className == "standard" or className == "compact" or className == "heavy" then
        return className
    end
    return "standard"
end

local function effectiveBrakeBaseline(baseline, profile)
    local scriptBrake = baseline and baseline.brakingForce
    if scriptBrake and scriptBrake > 0 then
        return scriptBrake
    end
    local cls = normalizeClass(profile and profile.class or "standard")
    return BRAKE_BASELINE_FALLBACK[cls] or BRAKE_BASELINE_FALLBACK.standard
end

local function stabilizeProfileMass(profile, baseline, fields)
    if not profile or profile.class == "trailer" or not baseline or not fields then
        return
    end
    local bm = baseline.mass
    local fm = fields.mass
    if not bm or bm <= 0 or not fm or fm <= 0 then
        return
    end
    local cls = normalizeClass(profile.class or "standard")
    local maxUplift = (MASS_MAX_UPLIFT[cls] or 1.12) * C.massUpliftMult()
    if fm > bm * maxUplift then
        fields.mass = math.floor(bm * maxUplift + 0.5)
    end
end

local function applyBrakePhysics(profile, baseline, fields)
    if not profile or not fields or profile.class == "trailer" then
        return
    end

    local cls = normalizeClass(profile.class or "standard")
    local bBase = effectiveBrakeBaseline(baseline, profile)
    local mass = fields.mass or (baseline and baseline.mass) or BRAKE_REF_MASS
    local stopSec = BRAKE_STOP_TIME_SEC[cls] or BRAKE_REF_STOP_SEC

    if profile.id and PROFILE_STOP_TIME_MUL[profile.id] then
        stopSec = stopSec * PROFILE_STOP_TIME_MUL[profile.id]
    end
    if profile.brakeRetainMul then
        stopSec = stopSec / math.max(0.45, profile.brakeRetainMul)
    end
    stopSec = stopSec * C.brakeStopTimeMult()
    stopSec = math.max(2.4, stopSec)

    local force = bBase * (mass / BRAKE_REF_MASS) * (BRAKE_REF_STOP_SEC / stopSec) * C.brakeMult()
    force = force * IK_ClassBias.biasForProfile(C, profile, "BrakeBias")
    fields.brakingForce = math.max(BRAKE_FLOOR, math.floor(force + 0.5))

    local stopping = baseline and baseline.stoppingMovementForce
    if stopping and stopping > 0 then
        fields.stoppingMovementForce = math.max(0.2, stopping * C.brakeMult() * C.brakeCreepMult())
    end
end

local function applyAccelerationTuning(profile, fields)
    if not profile or not fields or not fields.engineForce or fields.engineForce <= 0 then
        return
    end
    if profile.class == "trailer" then
        return
    end
    local cls = normalizeClass(profile.class or "standard")
    local mul = CLASS_POWER_MUL[cls] or CLASS_POWER_MUL.standard
    if profile.id and PROFILE_POWER_MUL[profile.id] then
        mul = mul * PROFILE_POWER_MUL[profile.id]
    end
    mul = mul * IK_ClassBias.biasForProfile(C, profile, "AccelBias")
    mul = mul * C.accelerationMult()
    if math.abs(mul - 1.0) > 1e-6 then
        fields.engineForce = math.floor(fields.engineForce * mul + 0.5)
    end
end

function T.readBaseline(script)
    if not script then
        return nil
    end
    local fullName = C.getScriptFullName(script)
    if fullName ~= "" and T._baselines[fullName] then
        return T._baselines[fullName]
    end
    local baseline = {
        mass = C.readScriptNumber(script, "getMass"),
        engineForce = C.readScriptNumber(script, "getEngineForce"),
        brakingForce = C.readScriptNumber(script, "getBrakingForce"),
        stoppingMovementForce = C.readScriptNumber(script, "getStoppingMovementForce"),
    }
    H.extendBaseline(script, baseline)
    if fullName ~= "" then
        T._baselines[fullName] = baseline
    end
    return baseline
end

local function buildGenericFields(script, baseline)
    if not baseline then
        baseline = T.readBaseline(script)
    end
    if not baseline then
        return nil
    end

    local fields = {}
    if baseline.mass and baseline.mass > 0 then
        fields.mass = math.floor(baseline.mass * C.massMult() + 0.5)
    end
    if baseline.engineForce and baseline.engineForce > 0 then
        fields.engineForce = math.floor(baseline.engineForce * C.powerMult() + 0.5)
    end
    if baseline.brakingForce and baseline.brakingForce > 0 then
        fields.brakingForce = math.max(BRAKE_FLOOR, baseline.brakingForce * C.brakeMult())
    end
    if baseline.stoppingMovementForce and baseline.stoppingMovementForce > 0 and fields.brakingForce then
        fields.stoppingMovementForce = math.max(0.2, baseline.stoppingMovementForce * C.brakeMult() * C.brakeCreepMult())
    end
    H.applyFields(nil, baseline, fields, C.getScriptFullName(script))
    return fields
end

local function buildTrailerFields(profile, baseline)
    if not profile or not profile.mass then
        return nil
    end
    local fields = {}
    local targetMass = math.floor(profile.mass * C.massMult() + 0.5)
    if baseline and baseline.mass and baseline.mass > 0 then
        local maxUplift = 1.35
        if targetMass > baseline.mass * maxUplift then
            targetMass = math.floor(baseline.mass * maxUplift + 0.5)
        end
    end
    fields.mass = targetMass
    return fields
end

local function buildProfileFields(profile, baseline, scriptFullName)
    if not profile or profile.class == "trailer" then
        return buildTrailerFields(profile, baseline)
    end

    local fields = {}
    local powerBias = IK_ClassBias.biasForProfile(C, profile, "PowerBias")
    local massBias = IK_ClassBias.biasForProfile(C, profile, "MassBias")
    if profile.engineForce and profile.engineForce > 0 then
        fields.engineForce = math.floor(profile.engineForce * C.powerMult() * powerBias + 0.5)
    end
    if profile.mass and baseline and baseline.mass and baseline.mass > 0 then
        fields.mass = math.floor(profile.mass * C.massMult() * massBias + 0.5)
        stabilizeProfileMass(profile, baseline, fields)
    elseif profile.mass then
        fields.mass = math.floor(profile.mass * C.massMult() * massBias + 0.5)
    end

    applyAccelerationTuning(profile, fields)
    applyBrakePhysics(profile, baseline, fields)
    H.applyFields(profile, baseline, fields, scriptFullName)
    return fields
end

function T.buildPlan(script)
    if not script then
        return nil
    end

    local fullName = C.getScriptFullName(script)
    local baseline = T.readBaseline(script)
    local profile = nil
    local profileId = nil
    local mode = "generic"

    if C.isProfileTuneEnabled() then
        profile, fullName = P.resolveProfile(script)
        if profile then
            profileId = profile.id or "unknown"
            mode = "profile:" .. tostring(profileId)
        end
    end

    local fields = nil
    if profile then
        fields = buildProfileFields(profile, baseline, fullName)
    else
        fields = buildGenericFields(script, baseline)
    end

    if not fields then
        return nil
    end

    local profileClass = profile and profile.class or nil
    local payload = C.buildLoadPayload(fields, profileClass)
    if not payload or payload == "" then
        return nil
    end

    return {
        scriptName = fullName,
        profileId = profileId,
        profileClass = profileClass,
        mode = mode,
        fields = fields,
        payload = payload,
    }
end

return T


