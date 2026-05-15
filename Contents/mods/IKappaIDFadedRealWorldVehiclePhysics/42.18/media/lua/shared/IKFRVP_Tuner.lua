require "IKFRVP_Core"
require "IKFRVP_Profiles"
require "IKFRVP_Compat"

IKFRVP.Tuner = IKFRVP.Tuner or {}

local Tuner = IKFRVP.Tuner

Tuner.baselines = Tuner.baselines or {}
Tuner.appliedSignatures = Tuner.appliedSignatures or {}
Tuner.lastStats = Tuner.lastStats or {}

-- Absolute floors after BrakeBaseRetain and after class/generic brake multipliers.
-- These can lift weak targets back up and make sandbox brake sliders feel ineffective (v1.1.4+ rework target).
local BRAKE_FLOOR_AFTER_RETAIN = 10
local BRAKE_FLOOR_AFTER_MULT = 6

local BASELINE_SCHEMA_VER = 5

local function readBaseline(script)
    local scriptName = IKFRVP.getScriptFullName(script)
    local cached = Tuner.baselines[scriptName]
    if cached and cached._schema == BASELINE_SCHEMA_VER then
        return cached
    end

    local baseline = {
        _schema = BASELINE_SCHEMA_VER,
        engineForce = IKFRVP.readScriptNumber(script, "getEngineForce"),
        mass = IKFRVP.readScriptNumber(script, "getMass"),
        maxSpeed = IKFRVP.readScriptNumber(script, "getMaxSpeed"),
        maxSpeedReverse = IKFRVP.readScriptNumber(script, "getMaxSpeedReverse"),
        brakingForce = IKFRVP.readScriptNumber(script, "getBrakingForce"),
        stoppingMovementForce = IKFRVP.readScriptNumber(script, "getStoppingMovementForce"),
        steeringIncrement = IKFRVP.readScriptNumber(script, "getSteeringIncrement"),
        steeringClamp = IKFRVP.readScriptNumber(script, "getSteeringClampLowSpeed"),
        rollInfluence = IKFRVP.readScriptNumber(script, "getRollInfluence"),
        wheelFriction = IKFRVP.readScriptNumber(script, "getWheelFriction"),
        suspensionStiffness = IKFRVP.readScriptNumber(script, "getSuspensionStiffness"),
        suspensionDamping = IKFRVP.readScriptNumber(script, "getSuspensionDamping"),
        suspensionCompression = IKFRVP.readScriptNumber(script, "getSuspensionCompression"),
        suspensionRestLength = IKFRVP.readScriptNumber(script, "getSuspensionRestLength"),
        maxSuspensionTravelCm = IKFRVP.readScriptNumber(script, "getSuspensionTravel"),
    }
    Tuner.baselines[scriptName] = baseline
    return baseline
end

local function classPowerBias(profile)
    if not profile then
        return 1.0
    end
    if profile.class == "sport" then
        return IKFRVP.numberOption("SportPowerBias", 1.0, 0.50, 2.0)
    end
    if profile.class == "heavy" then
        return IKFRVP.numberOption("HeavyVehiclePowerBias", 1.0, 0.50, 2.0)
    end
    return 1.0
end

local function csrSandbox()
    if SandboxVars and SandboxVars.CommonSenseReborn then
        return SandboxVars.CommonSenseReborn
    end
    return nil
end

local function isCSRTowAssistActive()
    local sb = csrSandbox()
    return IKFRVP.isCSRCompatibilityModeEnabled()
        and IKFRVP.isCSRActive()
        and sb ~= nil
        and sb.EnableTowAssist ~= false
        and IKFRVP.boolOption("CSRTowAssistCompensation", true)
end

local function csrTowClass(profile)
    if not profile then
        return "standard"
    end
    if profile.class == "heavy" then
        return "heavy"
    end
    if profile.class == "sport" then
        return "sport"
    end
    return "standard"
end

local function csrTowFactorForClass(towClass)
    local sb = csrSandbox()
    if not sb then
        return 0
    end
    if towClass == "heavy" then
        return tonumber(sb.TowAssistHeavyDutyFactor) or 7.0
    end
    if towClass == "sport" then
        return tonumber(sb.TowAssistSportFactor) or 4.0
    end
    return tonumber(sb.TowAssistStandardFactor) or 5.0
end

local function csrTowDefaultFactor(towClass)
    if towClass == "heavy" then
        return 7.0
    end
    if towClass == "sport" then
        return 4.0
    end
    return 5.0
end

local function csrTowAssistPowerScalar(profile)
    if not isCSRTowAssistActive() or not profile or profile.class == "trailer" then
        return 1.0
    end

    local towClass = csrTowClass(profile)
    local defaultFactor = csrTowDefaultFactor(towClass)
    local factor = csrTowFactorForClass(towClass)
    if defaultFactor <= 0 or factor <= defaultFactor then
        return 1.0
    end

    local strength = IKFRVP.numberOption("CSRTowAssistCompensationStrength", 0.35, 0, 1)
    if strength <= 0 then
        return 1.0
    end

    local ratio = factor / defaultFactor
    local scalar = 1 / (1 + ((ratio - 1) * strength))
    return IKFRVP.clamp(scalar, 0.70, 1.0) or 1.0
end

local function massScaleFor(profile)
    if profile and profile.class == "trailer" then
        return IKFRVP.numberOption("TrailerMassScale", 1.0, 0.25, 3.0)
    end
    return IKFRVP.numberOption("MassScale", 1.0, 0.25, 3.0)
end

local function changed(fromValue, toValue)
    if fromValue == nil or toValue == nil then
        return false
    end
    return math.abs(fromValue - toValue) > 0.001
end

local function addChange(changes, label, fromValue, toValue)
    if changed(fromValue, toValue) then
        changes[#changes + 1] = {
            label = label,
            from = fromValue,
            to = toValue,
        }
    end
end

-- Reverse cap and braking via VehicleScript:Load. maxSpeed is read only (never written) to scale reverse.
-- tuningClass: optional override when profile is nil (generic path) so heavy/sport/compact heuristics still apply.
local function applyReverseAndBrakeTuning(profile, baseline, fields, tuningClass)
    if not baseline or not fields then
        return
    end

    local cls = tuningClass or (profile and profile.class) or "standard"
    local bRev = baseline.maxSpeedReverse
    local fwd = baseline.maxSpeed

    if bRev and bRev > 0.05 then
        local mult = 0.19
        local absCap = 3.35
        local fwdFrac = 0.048
        if cls == "heavy" then
            mult = 0.15
            absCap = 2.45
            fwdFrac = 0.038
        elseif cls == "sport" then
            mult = 0.23
            absCap = 4.85
            fwdFrac = 0.054
        elseif cls == "compact" then
            mult = 0.17
            absCap = 2.95
            fwdFrac = 0.042
        end

        if bRev <= 2.8 then
            mult = math.min(0.44, mult + 0.06)
        end

        local target = bRev * mult
        if fwd and fwd > 1 then
            target = math.min(target, fwd * fwdFrac)
        end
        target = math.min(target, absCap)
        target = math.min(target, bRev * 0.42)
        target = math.min(target, bRev - 0.01)
        target = math.max(0.22, target)
        if target + 0.03 < bRev then
            fields.maxSpeedReverse = target
        end
    end

    local bBrake = baseline.brakingForce
    if bBrake and bBrake > 0 then
        local retain = IKFRVP.numberOption("BrakeBaseRetain", 1.0, 0.55, 1.0)
        if cls == "sport" then
            retain = math.min(1.0, retain * 1.04)
        elseif cls == "heavy" then
            retain = retain * 0.97
        elseif cls == "compact" then
            retain = math.min(1.0, retain * 1.02)
        end
        local soft = math.floor(bBrake * retain + 0.5)
        fields.brakingForce = math.min(bBrake - 1, math.max(BRAKE_FLOOR_AFTER_RETAIN, soft))
    end

    local s = baseline.stoppingMovementForce
    if s and s > 0 then
        local t = math.max(0.34, s * 0.44)
        t = math.min(t, s - 0.02)
        if t + 0.001 < s then
            fields.stoppingMovementForce = t
        end
    end
end

-- Neutral defaults: steering/grip come only from sandbox multipliers so users dial feel in explicitly.
local function handlingSteeringBias(profile)
    return 1.0
end

local function handlingGripBias(profile)
    return 1.0
end

local function isTrailerLike(profile, scriptFullName)
    if profile and profile.class == "trailer" then
        return true
    end
    local n = string.lower(scriptFullName or "")
    return string.find(n, "trailer", 1, true) ~= nil
end

-- Workshop vehicles in `module Base` often use ids like Base.89defender90 — the mesh and
-- script mass were tuned together. Replacing mass with a vanilla profile (e.g. Pickup
-- 2240 kg) or retuning steering/grip can sink wheels into the road until physics recover.
local function isLikelyThirdPartyBaseVehicle(scriptFullName)
    if not scriptFullName or scriptFullName == "" then
        return false
    end
    return string.match(scriptFullName, "^Base%.%d") ~= nil
end

-- Re-clamp engine force for workshop `Base.<digit>…` vehicles (used after profile tuning
-- and again after EngineTorqueMult so a torque boost cannot overshoot pack-safe torque).
local function clampThirdPartyEngineForce(profile, baseline, fields, scriptFullName)
    if not fields or not baseline or not scriptFullName then
        return
    end
    if profile and profile.class == "trailer" then
        return
    end
    if not isLikelyThirdPartyBaseVehicle(scriptFullName) then
        return
    end
    local be = baseline.engineForce
    if be and be > 0 and fields.engineForce and fields.engineForce > 0 then
        local lo = be * 0.70
        local hi = be * 1.38
        fields.engineForce = math.floor(math.max(lo, math.min(hi, fields.engineForce)) + 0.5)
    end
end

-- After profile + sandbox, keep mass/engine within a band around the script baseline so
-- third-party packs keep stable wheel contact.
local function clampThirdPartyVehicleTargets(profile, baseline, fields, scriptFullName)
    if not fields or not baseline or not scriptFullName then
        return
    end
    if profile and profile.class == "trailer" then
        return
    end
    if not isLikelyThirdPartyBaseVehicle(scriptFullName) then
        return
    end
    local bm = baseline.mass
    if bm and bm > 0 and fields.mass and fields.mass > 0 then
        local lo = bm * 0.82
        local hi = bm * 1.22
        fields.mass = math.floor(math.max(lo, math.min(hi, fields.mass)) + 0.5)
    end
    clampThirdPartyEngineForce(profile, baseline, fields, scriptFullName)
end

-- Final multiplier on engineForce (PZ's drivetrain input). Runs after class mults and
-- handling; third-party vehicles are engine-clamped again afterward.
local function applyEngineTorqueSandboxMult(profile, baseline, fields, scriptFullName)
    if not fields or not fields.engineForce or fields.engineForce <= 0 then
        return
    end
    if profile and profile.class == "trailer" then
        return
    end
    local mult = IKFRVP.numberOption("EngineTorqueMult", 1.0, 0.35, 2.5)
    if math.abs(mult - 1.0) < 1e-7 then
        return
    end
    fields.engineForce = math.floor(fields.engineForce * mult + 0.5)
    clampThirdPartyEngineForce(profile, baseline, fields, scriptFullName)
end

-- steeringIncrement / wheelFriction / rollInfluence / suspension — see PZwiki vehicle block.
local function applyHandlingPhysics(profile, baseline, fields, scriptFullName)
    if not IKFRVP.isHandlingPhysicsEnabled() then
        return
    end
    if not baseline or not fields then
        return
    end
    if isTrailerLike(profile, scriptFullName) then
        return
    end
    if isLikelyThirdPartyBaseVehicle(scriptFullName) then
        return
    end

    local inc = baseline.steeringIncrement
    if inc and inc > 0 then
        local mult = IKFRVP.numberOption("SteeringResponseMult", 1.0, 0.52, 1.0) * handlingSteeringBias(profile)
        mult = IKFRVP.clamp(mult, 0.5, 1.12) or mult
        local v = inc * mult
        v = math.max(0.0035, v)
        if math.abs(v - inc) > 1e-7 then
            fields.steeringIncrement = v
        end
    end

    local clamp = baseline.steeringClamp
    if clamp and clamp > 0 then
        local cm = IKFRVP.numberOption("SteeringClampMult", 1.0, 0.85, 1.0)
        local v = clamp * cm
        v = IKFRVP.clamp(v, 0.08, 0.48) or v
        if math.abs(v - clamp) > 1e-7 then
            fields.steeringClamp = v
        end
    end

    local wf = baseline.wheelFriction
    if wf and wf > 0 then
        local gm = IKFRVP.numberOption("WheelGripMult", 1.0, 0.68, 1.06) * handlingGripBias(profile)
        gm = IKFRVP.clamp(gm, 0.65, 1.1) or gm
        local v = wf * gm
        v = math.max(0.55, v)
        if math.abs(v - wf) > 1e-6 then
            fields.wheelFriction = v
        end
    end

    local roll = baseline.rollInfluence
    if roll ~= nil and roll >= 0 then
        local bump = IKFRVP.numberOption("BodyRollMult", 1.0, 1.0, 1.14)
        local v = math.min(1.0, roll * bump)
        if math.abs(v - roll) > 1e-6 then
            fields.rollInfluence = v
        end
    end

    -- Suspension retuning is optional: default firmness 1.0 skips this block. Some mod
    -- vehicles use tight wheel/road tuning; scaling stiffness/damping here can cause
    -- wheels to clip into the ground until physics recover.
    local firm = IKFRVP.numberOption("SuspensionFirmness", 1.0, 0.92, 1.28)
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

local function applyPerClassSandbox(profile, baseline, fields)
    if not profile or not fields or not baseline then
        return
    end

    if profile.class == "trailer" then
        if fields.mass and fields.mass > 0 then
            local mm = IKFRVP.classTuningMult("trailer", "MassMult", 1.0, 0.45, 1.55)
            fields.mass = math.floor(fields.mass * mm + 0.5)
        end
        return
    end

    local cid = profile.class or "standard"

    if fields.engineForce and fields.engineForce > 0 then
        local m = IKFRVP.classTuningMult(cid, "EngineMult", 1.0, 0.45, 1.65)
        fields.engineForce = math.floor(fields.engineForce * m + 0.5)
    end
    if fields.mass and fields.mass > 0 then
        local m = IKFRVP.classTuningMult(cid, "MassMult", 1.0, 0.55, 1.45)
        fields.mass = math.floor(fields.mass * m + 0.5)
    end

    -- Sandbox multipliers must apply even when applyReverseAndBrakeTuning skipped a field
    -- (e.g. reverse already near cap, or stoppingMovement barely changed).
    local revBase = fields.maxSpeedReverse or baseline.maxSpeedReverse
    if revBase and baseline.maxSpeedReverse then
        local m = IKFRVP.classTuningMult(cid, "ReverseMult", 1.0, 0.4, 1.7)
        local v = revBase * m
        v = IKFRVP.clamp(v, 0.1, baseline.maxSpeedReverse - 0.01) or v
        fields.maxSpeedReverse = v
    end

    local brakeBase = fields.brakingForce or baseline.brakingForce
    if brakeBase and baseline.brakingForce and brakeBase > 0 then
        local m = IKFRVP.classTuningMult(cid, "BrakeMult", 1.0, 0.35, 1.35)
        local b = math.floor(brakeBase * m + 0.5)
        fields.brakingForce = math.min(baseline.brakingForce - 1, math.max(BRAKE_FLOOR_AFTER_MULT, b))
    end

    local rollBase = fields.stoppingMovementForce or baseline.stoppingMovementForce
    if rollBase and baseline.stoppingMovementForce and rollBase > 0 then
        local m = IKFRVP.classTuningMult(cid, "RollMult", 1.0, 0.25, 1.45)
        local t = rollBase * m
        t = math.min(baseline.stoppingMovementForce - 0.01, math.max(0.2, t))
        fields.stoppingMovementForce = t
    end
end

local function applyGenericVehicleSandbox(baseline, fields)
    if not fields or not baseline then
        return
    end

    local revBase = fields.maxSpeedReverse or baseline.maxSpeedReverse
    if revBase and baseline.maxSpeedReverse then
        local m = IKFRVP.numberOption("GenericReverseMult", 1.0, 0.4, 1.7)
        local v = revBase * m
        fields.maxSpeedReverse = IKFRVP.clamp(v, 0.1, baseline.maxSpeedReverse - 0.01) or v
    end
    local brakeBase = fields.brakingForce or baseline.brakingForce
    if brakeBase and baseline.brakingForce and brakeBase > 0 then
        local m = IKFRVP.numberOption("GenericBrakeMult", 1.0, 0.35, 1.35)
        local b = math.floor(brakeBase * m + 0.5)
        fields.brakingForce = math.min(baseline.brakingForce - 1, math.max(BRAKE_FLOOR_AFTER_MULT, b))
    end
    local rollBase = fields.stoppingMovementForce or baseline.stoppingMovementForce
    if rollBase and baseline.stoppingMovementForce and rollBase > 0 then
        local m = IKFRVP.numberOption("GenericRollMult", 1.0, 0.25, 1.45)
        local t = rollBase * m
        fields.stoppingMovementForce = math.min(baseline.stoppingMovementForce - 0.01, math.max(0.2, t))
    end
end

local function buildProfileTargets(profile, baseline, scriptFullName)
    local fields = {}
    if profile.engineForce and baseline.engineForce then
        local powerScale = IKFRVP.numberOption("PowerScale", 1.0, 0.25, 3.0)
        fields.engineForce = math.floor(profile.engineForce
            * powerScale
            * classPowerBias(profile)
            * csrTowAssistPowerScalar(profile)
            + 0.5)
    end
    if profile.mass and baseline.mass then
        fields.mass = math.floor(profile.mass * massScaleFor(profile) + 0.5)
    end
    if profile.class ~= "trailer" then
        applyReverseAndBrakeTuning(profile, baseline, fields)
    end
    applyPerClassSandbox(profile, baseline, fields)
    clampThirdPartyVehicleTargets(profile, baseline, fields, scriptFullName)
    applyHandlingPhysics(profile, baseline, fields, scriptFullName)
    applyEngineTorqueSandboxMult(profile, baseline, fields, scriptFullName)
    return fields
end

local function buildGenericTargets(script, baseline, scriptFullName)
    local fields = {}
    if baseline.engineForce then
        fields.engineForce = baseline.engineForce * IKFRVP.numberOption("GenericEngineForceMultiplier", 1.0, 0.25, 3.0)
    end
    if baseline.mass then
        fields.mass = baseline.mass * IKFRVP.numberOption("GenericMassMultiplier", 1.0, 0.25, 3.0)
    end
    local inferredProfile = IKFRVP.Profiles.resolveProfile(script)
    local tuningClass = inferredProfile and inferredProfile.class or "standard"
    applyReverseAndBrakeTuning(nil, baseline, fields, tuningClass)
    applyGenericVehicleSandbox(baseline, fields)
    clampThirdPartyVehicleTargets(nil, baseline, fields, scriptFullName)
    applyHandlingPhysics(nil, baseline, fields, scriptFullName)
    applyEngineTorqueSandboxMult(nil, baseline, fields, scriptFullName)
    return fields
end

local function summarizeChanges(changes)
    local parts = {}
    for i = 1, #changes do
        local change = changes[i]
        parts[#parts + 1] = change.label
            .. "="
            .. IKFRVP.formatNumber(change.from)
            .. "->"
            .. IKFRVP.formatNumber(change.to)
    end
    return table.concat(parts, ", ")
end

function Tuner.buildPlan(script)
    if not script then
        return nil
    end

    local scriptFullName = IKFRVP.getScriptFullName(script)
    local baseline = readBaseline(script)
    local profile, matchedName = IKFRVP.Profiles.resolveProfile(script)
    local fields = nil
    local mode = nil

    if profile and IKFRVP.isProfileTuningEnabled() then
        fields = buildProfileTargets(profile, baseline, scriptFullName)
        mode = "profile:" .. tostring(profile.id)
    elseif IKFRVP.isGenericMultiplierTuningEnabled() then
        fields = buildGenericTargets(script, baseline, scriptFullName)
        mode = "generic"
    else
        return nil
    end

    local changes = {}
    addChange(changes, "engineForce", baseline.engineForce, fields.engineForce)
    addChange(changes, "mass", baseline.mass, fields.mass)
    addChange(changes, "maxSpeedReverse", baseline.maxSpeedReverse, fields.maxSpeedReverse)
    addChange(changes, "brakingForce", baseline.brakingForce, fields.brakingForce)
    addChange(changes, "stoppingMovementForce", baseline.stoppingMovementForce, fields.stoppingMovementForce)
    addChange(changes, "steeringIncrement", baseline.steeringIncrement, fields.steeringIncrement)
    addChange(changes, "steeringClamp", baseline.steeringClamp, fields.steeringClamp)
    addChange(changes, "rollInfluence", baseline.rollInfluence, fields.rollInfluence)
    addChange(changes, "wheelFriction", baseline.wheelFriction, fields.wheelFriction)
    addChange(changes, "suspensionStiffness", baseline.suspensionStiffness, fields.suspensionStiffness)
    addChange(changes, "suspensionDamping", baseline.suspensionDamping, fields.suspensionDamping)
    addChange(changes, "suspensionCompression", baseline.suspensionCompression, fields.suspensionCompression)

    if #changes == 0 then
        return nil
    end

    local payload = IKFRVP.fieldPayload(fields)

    return {
        scriptName = scriptFullName,
        loadName = IKFRVP.getScriptName(script),
        matchedName = matchedName,
        mode = mode,
        fields = fields,
        payload = payload,
        changes = changes,
    }
end

function Tuner.applyPlan(script, plan, stats, source)
    if not script or not plan or not plan.payload then
        return false
    end
    if not script.Load then
        stats.skipped = stats.skipped + 1
        IKFRVP.debug("tuning-skip: " .. plan.scriptName .. " has no Load method")
        return false
    end

    local signature = plan.scriptName .. "|" .. plan.payload
    if Tuner.appliedSignatures[plan.scriptName] == signature then
        stats.unchanged = stats.unchanged + 1
        return false
    end

    if IKFRVP.isAuditOnly() then
        stats.audited = stats.audited + 1
        IKFRVP.log("tuning-audit: " .. plan.scriptName .. " | " .. plan.mode .. " | " .. summarizeChanges(plan.changes))
        return false
    end

    script:Load(plan.loadName, plan.payload)
    Tuner.appliedSignatures[plan.scriptName] = signature
    stats.applied = stats.applied + 1
    IKFRVP.debug("tuning-apply: " .. tostring(source) .. " " .. plan.scriptName .. " | " .. plan.mode .. " | " .. summarizeChanges(plan.changes))
    return true
end

function Tuner.processScript(script, stats, source)
    if not script then
        return
    end

    stats.seen = stats.seen + 1

    local plan = Tuner.buildPlan(script)
    if not plan then
        stats.skipped = stats.skipped + 1
        return
    end

    if string.sub(plan.mode, 1, 7) == "profile" then
        stats.profiled = stats.profiled + 1
    else
        stats.generic = stats.generic + 1
    end

    Tuner.applyPlan(script, plan, stats, source)
end

function Tuner.storeServerState(stats, source)
    if type(isClient) == "function" and isClient() then
        return
    end
    if not ModData or not ModData.getOrCreate then
        return
    end

    local state = ModData.getOrCreate(IKFRVP.ServerStateKey)
    if not state then
        return
    end

    state.version = IKFRVP.Version
    state.source = tostring(source)
    state.side = IKFRVP.side()
    state.enabled = IKFRVP.isEnabled()
    state.profileTuning = IKFRVP.isProfileTuningEnabled()
    state.genericTuning = IKFRVP.isGenericMultiplierTuningEnabled()
    state.auditOnly = IKFRVP.isAuditOnly()
    state.seen = stats.seen
    state.profiled = stats.profiled
    state.generic = stats.generic
    state.applied = stats.applied
    state.audited = stats.audited
    state.skipped = stats.skipped

    if ModData.transmit then
        ModData.transmit(IKFRVP.ServerStateKey)
    end
end

function Tuner.processAllScripts(source)
    local stats = {
        seen = 0,
        profiled = 0,
        generic = 0,
        applied = 0,
        audited = 0,
        skipped = 0,
        unchanged = 0,
    }

    if not IKFRVP.isEnabled() then
        Tuner.lastStats = stats
        return stats
    end

    if not getScriptManager then
        IKFRVP.log("tuning-skip: getScriptManager is unavailable")
        Tuner.lastStats = stats
        return stats
    end

    local manager = getScriptManager()
    if not manager or not manager.getAllVehicleScripts then
        IKFRVP.log("tuning-skip: vehicle script list is unavailable")
        Tuner.lastStats = stats
        return stats
    end

    local scripts = manager:getAllVehicleScripts()
    local count = IKFRVP.javaListSize(scripts)
    for index = 0, count - 1 do
        Tuner.processScript(IKFRVP.javaListGet(scripts, index), stats, source)
    end

    Tuner.lastStats = stats
    Tuner.storeServerState(stats, source)

    if (not (type(isClient) == "function" and isClient())) or IKFRVP.isDebugLoggingEnabled() then
        IKFRVP.log(
            "tuning-summary: source="
            .. tostring(source)
            .. ", seen="
            .. tostring(stats.seen)
            .. ", profiled="
            .. tostring(stats.profiled)
            .. ", generic="
            .. tostring(stats.generic)
            .. ", applied="
            .. tostring(stats.applied)
            .. ", audited="
            .. tostring(stats.audited)
            .. ", skipped="
            .. tostring(stats.skipped)
        )
    end

    return stats
end

function Tuner.onInitGlobalModData(newGame)
    IKFRVP.Compat.logCSRState("global-mod-data")
    Tuner.processAllScripts("OnInitGlobalModData")
end

function Tuner.onGameStart()
    IKFRVP.Compat.logCSRState("game-start")
    Tuner.appliedSignatures = {}
    Tuner.processAllScripts("OnGameStart")
end

function Tuner.registerEvents()
    if Tuner.eventsRegistered then
        return
    end
    if Events and Events.OnInitGlobalModData then
        Events.OnInitGlobalModData.Add(Tuner.onInitGlobalModData)
    end
    if Events and Events.OnGameStart then
        Events.OnGameStart.Add(Tuner.onGameStart)
    end
    Tuner.eventsRegistered = true
end

Tuner.registerEvents()

require "IKFRVP_TrunkRuntime"

return Tuner
