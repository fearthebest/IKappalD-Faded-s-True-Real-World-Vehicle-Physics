ProjectFadedCar = ProjectFadedCar or {}

local PFC = ProjectFadedCar
PFC.IKFRVPBridge = PFC.IKFRVPBridge or {}

local Bridge = PFC.IKFRVPBridge

Bridge.MOD_ID = "IKappaIDFadedRealWorldVehiclePhysics"
Bridge.COMMAND_MODULE = "IKFRVP"
Bridge.SERVER_STATE_KEY = "IKFRVP_ServerState"

print("[ProjectFadedCar] Shared IKFRVP bridge module loaded")

local function physicsMod()
    return IKFRVP
end

local function physicsBridge()
    local mod = physicsMod()
    if mod and mod.Bridge then
        return mod.Bridge
    end
    return nil
end

local function readSandboxOption(name, fallback)
    local root = SandboxVars and SandboxVars.IKFRVP or nil
    if root and root[name] ~= nil then
        return root[name]
    end
    local mod = physicsMod()
    if mod and mod.option then
        return mod.option(name, fallback)
    end
    return fallback
end

local function readBoolean(fnName, optionName, fallback)
    local value = readSandboxOption(optionName, nil)
    if value ~= nil then
        return value == true
    end
    local mod = physicsMod()
    if mod and type(mod[fnName]) == "function" then
        return mod[fnName]() == true
    end
    return fallback == true
end

local function readNumber(optionName, fallback)
    local raw = readSandboxOption(optionName, nil)
    if raw ~= nil then
        local value = tonumber(raw)
        if value == nil then return fallback end
        return value
    end
    local mod = physicsMod()
    if mod and type(mod.numberOption) == "function" then
        return mod.numberOption(optionName, fallback)
    end
    return fallback
end

local function serverState()
    if not ModData then return nil end
    if ModData.get then
        local state = ModData.get(Bridge.SERVER_STATE_KEY)
        if state then return state end
    end
    if not (isClient and isClient()) and ModData.getOrCreate then
        return ModData.getOrCreate(Bridge.SERVER_STATE_KEY)
    end
    return nil
end

local function copyStats(target, stats)
    stats = stats or {}
    target.source = tostring(stats.source or "")
    target.seen = tonumber(stats.seen) or 0
    target.profiled = tonumber(stats.profiled) or 0
    target.generic = tonumber(stats.generic) or 0
    target.applied = tonumber(stats.applied) or 0
    target.audited = tonumber(stats.audited) or 0
    target.skipped = tonumber(stats.skipped) or 0
    target.errors = tonumber(stats.errors) or 0
end

function PFC.formatPhysicsNumber(value)
    local number = tonumber(value)
    if number == nil then return "n/a" end
    return string.format("%.2f", number)
end

local function scriptNumber(script, getterName)
    local mod = physicsMod()
    if mod and mod.readScriptNumber then
        return mod.readScriptNumber(script, getterName)
    end
    if not script or not getterName or not script[getterName] then
        return nil
    end
    if getterName == "getSteeringClamp" then
        return tonumber(script:getSteeringClamp(0))
    end
    return tonumber(script[getterName](script))
end

function Bridge.isModActive()
    if PFC.physicsBridgeEnabled and not PFC.physicsBridgeEnabled() then
        return false
    end
    if physicsMod() ~= nil then return true end
    if PFC.hasActiveMod then
        return PFC.hasActiveMod(Bridge.MOD_ID)
    end
    return false
end

function Bridge.isLoaded()
    if PFC.physicsBridgeEnabled and not PFC.physicsBridgeEnabled() then
        return false
    end
    return physicsMod() ~= nil
end

function Bridge.hasAdminAccess(player)
    if type(isMultiplayer) ~= "function" or not isMultiplayer() then
        return true
    end
    if not player or not player.getAccessLevel then
        return false
    end
    local access = string.lower(tostring(player:getAccessLevel() or ""))
    return access == "admin"
end

function Bridge.actionRequiresAdmin(action)
    return action == "retune" or action == "safeHandling"
end

function Bridge.status(vehicle)
    local api = physicsBridge()
    if api and api.getStatus and Bridge.isLoaded() then
        local status = api.getStatus(vehicle)
        status.active = Bridge.isModActive()
        status.loaded = true
        return status
    end

    local mod = physicsMod()
    if mod and mod.buildStatusTable and Bridge.isLoaded() then
        local status = mod.buildStatusTable(vehicle)
        status.active = Bridge.isModActive()
        status.loaded = true
        return status
    end

    local state = serverState()
    local status = {
        active = Bridge.isModActive(),
        loaded = Bridge.isLoaded(),
        version = mod and tostring(mod.Version or "") or tostring(state and state.version or ""),
        enabled = readBoolean("isEnabled", "Enabled", true),
        profileTuning = readBoolean("isProfileTuningEnabled", "ProfileTuning", true),
        genericTuning = readBoolean("isGenericMultiplierTuningEnabled", "GenericMultiplierTuning", false),
        corneringTuning = readBoolean("isCorneringTuningEnabled", "CorneringTuning", true),
        trunkTuning = readBoolean("isTrunkCapacityTuningEnabled", "TrunkCapacityTuning", true),
        handlingPhysics = readBoolean("isHandlingPhysicsEnabled", "HandlingPhysics", false),
        glitchGuard = readBoolean("isGlitchGuardEnabled", "GlitchGuard", true),
        auditOnly = readBoolean("isAuditOnly", "AuditOnly", false),
        debugLogging = readBoolean("isDebugLoggingEnabled", "DebugLogging", false),
        csrCompat = readBoolean("isCSRCompatibilityModeEnabled", "CSRCompatibilityMode", true),
        powerScale = readNumber("PowerScale", 1.0),
        massScale = readNumber("MassScale", 1.0),
        engineTorqueMult = readNumber("EngineTorqueMult", 1.0),
        trunkCapacityMult = readNumber("TrunkCapacityMult", 1.0),
        brakeBaseRetain = readNumber("BrakeBaseRetain", 1.0),
        cornerGripMult = readNumber("CornerGripMult", 1.0),
        scriptName = "",
        profileId = "",
        profileClass = "",
        engineForce = nil,
        mass = nil,
        brakingForce = nil,
        stoppingMovementForce = nil,
        steeringClamp = nil,
        wheelFriction = nil,
        targetEngineForce = nil,
        targetBrakingForce = nil,
        targetSteeringClamp = nil,
        targetWheelFriction = nil,
        liveEnginePower = nil,
        liveBrakingForce = nil,
        glitchTripped = false,
        tripReason = "",
    }

    if mod and mod.isCSRActive then
        status.csrActive = mod.isCSRActive() == true
    elseif PFC.isCSRActive then
        status.csrActive = PFC.isCSRActive()
    else
        status.csrActive = false
    end

    if mod and mod.Safety then
        status.glitchTripped = mod.Safety.tripped == true
        status.tripReason = tostring(mod.Safety.tripReason or "")
    end

    if mod and mod.Tuner and mod.Tuner.lastStats then
        copyStats(status, mod.Tuner.lastStats)
    else
        copyStats(status, state)
    end

    local script = vehicle and vehicle.getScript and vehicle:getScript() or nil
    if script then
        if mod and mod.getScriptFullName then
            status.scriptName = mod.getScriptFullName(script)
        else
            status.scriptName = PFC.getVehicleLabel(vehicle)
        end

        status.engineForce = scriptNumber(script, "getEngineForce")
        status.mass = scriptNumber(script, "getMass")
        status.brakingForce = scriptNumber(script, "getBrakingForce")
        status.stoppingMovementForce = scriptNumber(script, "getStoppingMovementForce")
        status.steeringClamp = scriptNumber(script, "getSteeringClamp")
        status.wheelFriction = scriptNumber(script, "getWheelFriction")

        if mod and mod.Profiles and mod.Profiles.resolveProfile then
            local profile = mod.Profiles.resolveProfile(script)
            if profile then
                status.profileId = tostring(profile.id or "")
                status.profileClass = tostring(profile.class or "")
            end
        end

        if mod and mod.Tuner then
            if mod.Tuner.engineTargets then
                status.targetEngineForce = mod.Tuner.engineTargets[status.scriptName]
            end
            if mod.Tuner.brakeTargets then
                status.targetBrakingForce = mod.Tuner.brakeTargets[status.scriptName]
            end
            if mod.Tuner.maneuverTargets and mod.Tuner.maneuverTargets[status.scriptName] then
                local row = mod.Tuner.maneuverTargets[status.scriptName]
                status.targetSteeringClamp = row.steeringClamp
                status.targetWheelFriction = row.wheelFriction
            end
        end
    end

    if vehicle and vehicle.getEnginePower then
        status.liveEnginePower = tonumber(vehicle:getEnginePower())
    end
    if vehicle and vehicle.getBrakingForce then
        status.liveBrakingForce = tonumber(vehicle:getBrakingForce())
    end

    return status
end

function Bridge.requestNativeStatus(vehicle)
    if isClient and isClient() and sendClientCommand then
        local args = {}
        if vehicle and vehicle.getId then
            args.vehicle = vehicle:getId()
        end
        sendClientCommand(Bridge.COMMAND_MODULE, "RequestStatus", args)
        return true
    end
    Bridge.lastStatus = Bridge.status(nil)
    return Bridge.isLoaded()
end

function Bridge.storeStatus(status)
    if type(status) == "table" then
        Bridge.lastStatus = status
    end
end

function Bridge.syncVehicle(vehicle)
    local api = physicsBridge()
    if api and api.syncVehicle then
        return api.syncVehicle(vehicle)
    end
    return false, "physics-unavailable"
end

function Bridge.retune(source)
    local api = physicsBridge()
    if api and api.retune then
        local ok, message, stats = api.retune(source or "PFCBridge")
        Bridge.lastStatus = Bridge.status(nil)
        if type(stats) == "table" then
            copyStats(Bridge.lastStatus, stats)
        end
        return ok, message
    end
    return false, "physics-retune-unavailable"
end

function Bridge.safeHandling(source)
    local api = physicsBridge()
    if api and api.safeHandling then
        local ok, message = api.safeHandling(source or "PFCBridgeSafe")
        Bridge.lastStatus = Bridge.status(nil)
        return ok, message
    end
    return false, "physics-safe-unavailable"
end

function Bridge.performAction(action, player, vehicle)
    action = tostring(action or "status")

    if not Bridge.isModActive() then
        return false, "physics-missing", Bridge.status(vehicle)
    end

    local api = physicsBridge()
    if api and api.performAction and Bridge.isLoaded() then
        if action == "status" then
            Bridge.requestNativeStatus(vehicle)
        end
        local ok, message, status = api.performAction(action, player, vehicle)
        if type(status) == "table" then
            status.active = Bridge.isModActive()
            status.loaded = true
        end
        if action == "status" then
            return true, message or "physics-status", status
        end
        return ok, message, status
    end

    if Bridge.actionRequiresAdmin(action) and not Bridge.hasAdminAccess(player) then
        return false, "physics-admin-only", Bridge.status(vehicle)
    end
    if action == "status" then
        Bridge.requestNativeStatus(vehicle)
        return true, "physics-status", Bridge.status(vehicle)
    end
    if not Bridge.isLoaded() then
        return false, "physics-unavailable", Bridge.status(vehicle)
    end
    if action == "syncVehicle" then
        local ok, message = Bridge.syncVehicle(vehicle)
        return ok, message, Bridge.status(vehicle)
    end
    if action == "retune" then
        local ok, message = Bridge.retune("PFCBridge")
        return ok, message, Bridge.status(vehicle)
    end
    if action == "safeHandling" then
        local ok, message = Bridge.safeHandling("PFCBridgeSafe")
        return ok, message, Bridge.status(vehicle)
    end

    return false, "physics-bad-action", Bridge.status(vehicle)
end

PFC.API = PFC.API or {}
PFC.API.getPhysicsSnapshot = Bridge.status
PFC.API.isPhysicsModActive = Bridge.isModActive
PFC.API.requestPhysicsStatus = Bridge.requestNativeStatus
