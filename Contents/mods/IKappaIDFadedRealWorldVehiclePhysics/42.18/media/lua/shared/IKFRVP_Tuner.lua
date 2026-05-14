require "IKFRVP_Core"
require "IKFRVP_Profiles"
require "IKFRVP_Compat"

IKFRVP.Tuner = IKFRVP.Tuner or {}

local Tuner = IKFRVP.Tuner

Tuner.baselines = Tuner.baselines or {}
Tuner.appliedSignatures = Tuner.appliedSignatures or {}
Tuner.lastStats = Tuner.lastStats or {}

local function readBaseline(script)
    local scriptName = IKFRVP.getScriptFullName(script)
    if Tuner.baselines[scriptName] then
        return Tuner.baselines[scriptName]
    end

    local baseline = {
        engineForce = IKFRVP.readScriptNumber(script, "getEngineForce"),
        mass = IKFRVP.readScriptNumber(script, "getMass"),
        maxSpeed = IKFRVP.readScriptNumber(script, "getMaxSpeed"),
        maxSpeedReverse = IKFRVP.readScriptNumber(script, "getMaxSpeedReverse"),
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

local function buildProfileTargets(profile, baseline)
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
    if profile.class == "heavy" and baseline.maxSpeed ~= nil then
        fields.maxSpeed = math.min(baseline.maxSpeed, 68)
        local fwdCap = fields.maxSpeed
        if baseline.maxSpeedReverse ~= nil then
            local softCap = math.min(baseline.maxSpeedReverse, fwdCap * 0.32)
            fields.maxSpeedReverse = math.max(6, softCap)
        else
            fields.maxSpeedReverse = math.max(6, math.min(18, fwdCap * 0.28))
        end
    end
    return fields
end

local function buildGenericTargets(baseline)
    local fields = {}
    if baseline.engineForce then
        fields.engineForce = baseline.engineForce * IKFRVP.numberOption("GenericEngineForceMultiplier", 1.0, 0.25, 3.0)
    end
    if baseline.mass then
        fields.mass = baseline.mass * IKFRVP.numberOption("GenericMassMultiplier", 1.0, 0.25, 3.0)
    end
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

    local baseline = readBaseline(script)
    local profile, matchedName = IKFRVP.Profiles.resolveProfile(script)
    local fields = nil
    local mode = nil

    if profile and IKFRVP.isProfileTuningEnabled() then
        fields = buildProfileTargets(profile, baseline)
        mode = "profile:" .. tostring(profile.id)
    elseif IKFRVP.isGenericMultiplierTuningEnabled() then
        fields = buildGenericTargets(baseline)
        mode = "generic"
    else
        return nil
    end

    local changes = {}
    addChange(changes, "engineForce", baseline.engineForce, fields.engineForce)
    addChange(changes, "mass", baseline.mass, fields.mass)
    addChange(changes, "maxSpeed", baseline.maxSpeed, fields.maxSpeed)
    addChange(changes, "maxSpeedReverse", baseline.maxSpeedReverse, fields.maxSpeedReverse)

    if #changes == 0 then
        return nil
    end

    return {
        scriptName = IKFRVP.getScriptFullName(script),
        loadName = IKFRVP.getScriptName(script),
        matchedName = matchedName,
        mode = mode,
        fields = fields,
        payload = IKFRVP.fieldPayload(fields),
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

return Tuner
