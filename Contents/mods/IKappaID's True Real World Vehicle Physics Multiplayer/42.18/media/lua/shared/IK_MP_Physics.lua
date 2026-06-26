require "IK_MP_Core"
require "IK_MP_Profiles"
require "IK_MP_Tune"
require "IK_MP_Debug"
require "IK_MP_PhysicsMirror"

IK_MP.Physics = IK_MP.Physics or {}

local P = IK_MP.Physics
local C = IK_MP
local D = IK_MP.Debug

P._targets = P._targets or {}
P._applied = P._applied or {}
P._mirrorRows = P._mirrorRows or {}
P._eventsRegistered = false
P._serverTickCounter = 0
P._syncEvery = 30
P._lateTuneTick = 0
P._lateTuneDone = false
P._gameStartApplied = 0
P._feelSignature = nil

local function syncPhysicsFeelSignature()
    local sig = C.physicsFeelSignature()
    if P._feelSignature ~= sig then
        P._applied = {}
        P._targets = {}
        P._mirrorRows = {}
        P._feelSignature = sig
        if IK_MP.Tune and IK_MP.Tune.clearCaches then
            IK_MP.Tune.clearCaches()
        end
    end
end

function P.tuneScript(script, source)
    if not script or not script.Load then
        D.recordSkip("no_load_method")
        return false, "no_load_method"
    end

    local plan = IK_MP.Tune.buildPlan(script)
    if not plan or not plan.fields then
        D.recordSkip("no_plan")
        D.probeScriptIfWatched(script, source, false, "no_plan")
        return false, "no_plan"
    end

    local fullName = plan.scriptName or C.getScriptFullName(script)
    if fullName == "" then
        D.recordSkip("no_script_name")
        return false, "no_script_name"
    end

    local fields = plan.fields
    P._targets[fullName] = fields

    local payload = plan.payload
    if not payload then
        D.recordSkip("no_load_payload")
        C.debug("script-tune-skip[" .. tostring(source) .. "]: " .. fullName .. " reason=no_load_payload")
        D.probeScriptIfWatched(script, source, false, "no_load_payload")
        return false, "no_load_payload"
    end

    local signature = fullName .. "|" .. payload
    if P._applied[fullName] == signature then
        D.recordSkip("unchanged")
        return false, "unchanged"
    end

    local safe, loadNameOrReason = C.canSafelyVehicleScriptLoad(script, fields, plan.profileClass)
    if not safe then
        local reason = tostring(loadNameOrReason)
        D.recordSkip(reason)
        C.debug("script-tune-skip[" .. tostring(source) .. "]: " .. fullName .. " reason=" .. reason)
        D.probeScriptIfWatched(script, source, false, reason)
        return false, reason
    end

    script:Load(loadNameOrReason, payload)
    P._applied[fullName] = signature
    P._targets[fullName] = fields
    P._mirrorRows[fullName] = {
        scriptFullName = fullName,
        loadName = loadNameOrReason,
        payload = payload,
        profileClass = plan.profileClass,
        signature = signature,
    }
    C.debug(
        "script-tune[" .. tostring(source) .. "]: "
        .. fullName
        .. " mode=" .. tostring(plan.mode)
        .. " class=" .. tostring(plan.profileClass or "n/a")
        .. " mass=" .. C.formatNumber(fields.mass)
        .. " engine=" .. C.formatNumber(fields.engineForce)
        .. " brake=" .. C.formatNumber(fields.brakingForce)
    )
    D.probeScriptIfWatched(script, source, true, nil)
    return true, plan.mode
end

function P.tuneAllScripts(source)
    if not C.runsScriptTune() or not C.isEnabled() then
        return { seen = 0, applied = 0 }
    end
    if not getScriptManager then
        C.log("script-tune-skip: getScriptManager unavailable")
        return { seen = 0, applied = 0 }
    end

    local manager = getScriptManager()
    if not manager or not manager.getAllVehicleScripts then
        C.log("script-tune-skip: vehicle script list unavailable")
        return { seen = 0, applied = 0 }
    end

    D.resetSkipCounts()
    syncPhysicsFeelSignature()

    local stats = { seen = 0, applied = 0, profiled = 0, generic = 0, unchanged = 0 }
    local scripts = manager:getAllVehicleScripts()
    local count = C.javaListSize(scripts)
    for index = 0, count - 1 do
        local script = C.javaListGet(scripts, index)
        if script then
            stats.seen = stats.seen + 1
            local applied, modeOrReason = P.tuneScript(script, source)
            if applied then
                stats.applied = stats.applied + 1
                if modeOrReason and string.find(modeOrReason, "profile:", 1, true) then
                    stats.profiled = stats.profiled + 1
                elseif modeOrReason == "generic" then
                    stats.generic = stats.generic + 1
                end
            elseif modeOrReason == "unchanged" then
                stats.unchanged = stats.unchanged + 1
            end
        end
    end

    C.log(
        "script-tune-summary["
        .. tostring(source)
        .. "]: seen="
        .. stats.seen
        .. " applied="
        .. stats.applied
        .. " profiled="
        .. stats.profiled
        .. " generic="
        .. stats.generic
    )
    D.flushTunePass(source, stats)
    return stats
end

function P.getMirrorRowForScript(script)
    if not script then
        return nil
    end
    local fullName = C.getScriptFullName(script)
    if fullName == "" then
        return nil
    end
    local row = P._mirrorRows[fullName]
    if row then
        return row
    end
    local fields = P._targets[fullName]
    if not fields then
        return nil
    end
    local plan = IK_MP.Tune.buildPlan(script)
    if not plan or not plan.payload or plan.payload == "" then
        return nil
    end
    local loadName = C.getScriptLoadName(script)
    if loadName == "" then
        return nil
    end
    local signature = fullName .. "|" .. plan.payload
    row = {
        scriptFullName = fullName,
        loadName = loadName,
        payload = plan.payload,
        profileClass = plan.profileClass,
        signature = signature,
    }
    P._mirrorRows[fullName] = row
    return row
end

function P.getTargetFields(vehicle)
    if not vehicle or not vehicle.getScript then
        return nil
    end
    local script = vehicle:getScript()
    if not script then
        return nil
    end
    local fullName = C.getScriptFullName(script)
    local stored = P._targets[fullName]
    if stored then
        return stored
    end
    local plan = IK_MP.Tune.buildPlan(script)
    if plan and plan.fields then
        return plan.fields
    end
    return nil
end

function P.syncVehicle(vehicle, player)
    if not vehicle or not C.isEnabled() or not C.runsDriverPhysicsSync() then
        return false
    end

    local fields = P.getTargetFields(vehicle)
    if not fields then
        return false
    end

    local changed = false

    if fields.brakingForce and vehicle.setBrakingForce and vehicle.getBrakingForce then
        local target = fields.brakingForce
        local current = vehicle:getBrakingForce()
        if current == nil or math.abs(current - target) > 0.05 then
            vehicle:setBrakingForce(target)
            changed = true
        end
    end

    if fields.engineForce and vehicle.setEngineFeature and vehicle.getEnginePower then
        local targetPower = C.enginePowerFromScriptForce(vehicle, fields.engineForce)
        local current = vehicle:getEnginePower()
        if C.enginePowerNeedsUpdate(current, targetPower) then
            local quality = 100
            local loudness = 100
            if vehicle.getEngineQuality then
                local q = vehicle:getEngineQuality()
                if q then
                    quality = q
                end
            end
            if vehicle.getEngineLoudness then
                local l = vehicle:getEngineLoudness()
                if l then
                    loudness = l
                end
            end
            vehicle:setEngineFeature(quality, loudness, targetPower)
            if vehicle.transmitEngine then
                vehicle:transmitEngine()
            end
            changed = true
        end
    end

    D.syncVehicle(vehicle, changed, fields)

    if changed and C.hasServerJvm() and IK_MP.PhysicsMirror then
        if player and IK_MP.PhysicsMirror.pushToPlayer then
            IK_MP.PhysicsMirror.pushToPlayer(player, vehicle, fields)
        elseif IK_MP.PhysicsMirror.pushToVehicleDrivers then
            IK_MP.PhysicsMirror.pushToVehicleDrivers(vehicle, fields)
        end
    end

    return changed
end

function P.tickPlayer(player)
    if not C.runsDriverPhysicsSync() or not player then
        return
    end
    if not player.getVehicle then
        return
    end
    local vehicle = player:getVehicle()
    if not vehicle then
        return
    end
    if vehicle.isDriver and not vehicle:isDriver(player) then
        return
    end

    P._playerTicks = P._playerTicks or {}
    local ticks = (P._playerTicks[player] or 0) + 1
    P._playerTicks[player] = ticks
    if ticks < P._syncEvery then
        return
    end
    P._playerTicks[player] = 0
    P.syncVehicle(vehicle, player)
end

function P.onServerSandboxApplied()
    syncPhysicsFeelSignature()
    if C.runsScriptTune() and P._lateTuneDone then
        P.tuneAllScripts("OnSandboxApplied")
    end
end

function P.onGameStart()
    if not C.runsScriptTune() or not C.isEnabled() then
        P._lateTuneDone = true
        return
    end
    -- Tune here only: OnInitGlobalModData is too early for some workshop VehicleScripts (Load throws).
    local stats = P.tuneAllScripts("OnGameStart")
    P._gameStartApplied = stats and stats.applied or 0
    P._lateTuneTick = 0
    P._lateTuneDone = P._gameStartApplied > 0
end

function P.onTickLateTune()
    if P._lateTuneDone or not C.runsScriptTune() then
        return
    end
    if (P._gameStartApplied or 0) > 0 then
        P._lateTuneDone = true
        return
    end
    P._lateTuneTick = P._lateTuneTick + 1
    if P._lateTuneTick < 120 then
        return
    end
    local stats = P.tuneAllScripts("OnTickLate")
    P._lateTuneDone = true
    if stats and stats.applied > 0 then
        C.log("script-tune-late: applied=" .. stats.applied .. " (OnGameStart had " .. P._gameStartApplied .. ")")
    elseif C.isDebugLoggingEnabled() then
        C.debug("script-tune-late: still applied=0 after delay")
    end
end

function P.onEnterVehicle(player)
    if not player or not C.isEnabled() then
        return
    end
    if not player.getVehicle then
        return
    end
    local vehicle = player:getVehicle()
    if not vehicle then
        return
    end
    if C.runsScriptTune() and vehicle.getScript then
        syncPhysicsFeelSignature()
        local script = vehicle:getScript()
        if script then
            P.tuneScript(script, "OnEnterVehicle")
        end
    end
    if C.runsDriverPhysicsSync() then
        P.syncVehicle(vehicle, player)
    elseif C.hasServerJvm() and IK_MP.PhysicsMirror and IK_MP.PhysicsMirror.pushToPlayer then
        local fields = P.getTargetFields(vehicle)
        IK_MP.PhysicsMirror.pushToPlayer(player, vehicle, fields)
    end
    if not C.isRemoteClient() then
        D.enterVehicle(player, vehicle)
    end
end

function P.onClientMirrorEnterVehicle(player)
    if not C.isRemoteClient() or not player or not player.getVehicle then
        return
    end
    local vehicle = player:getVehicle()
    if not vehicle then
        return
    end
    if IK_MP.PhysicsMirror and IK_MP.PhysicsMirror.requestMirrorFromServer then
        IK_MP.PhysicsMirror.requestMirrorFromServer(vehicle, "OnEnterVehicle")
    end
    D.enterVehicle(player, vehicle)
end

function P.onServerPlayerUpdate(player)
    if not C.hasServerJvm() or C.hasClientJvm() then
        return
    end
    P.tickPlayer(player)
end

function P.onPlayerUpdate(player)
    if not C.runsDriverPhysicsSync() or not C.hasClientJvm() then
        return
    end
    P.tickPlayer(player)
end

function P.onServerTickDrivers()
    if not C.hasServerJvm() or C.hasClientJvm() then
        return
    end
    P._serverTickCounter = (P._serverTickCounter or 0) + 1
    if P._serverTickCounter % 2 ~= 0 then
        return
    end
    C.forEachSeatedDriver(function(player, _vehicle)
        P.tickPlayer(player)
    end)
end

function P.registerEvents()
    if P._eventsRegistered or not C.isActiveHere() then
        return
    end
    if not C.isEnabled() then
        P._eventsRegistered = true
        return
    end
    if C.hasServerJvm() and not C.hasClientJvm() then
        P._syncEvery = 60
    else
        P._syncEvery = 30
    end
    if Events and Events.OnGameStart then
        Events.OnGameStart.Add(P.onGameStart)
    end
    if Events and Events.OnEnterVehicle then
        Events.OnEnterVehicle.Add(P.onEnterVehicle)
        if C.hasClientJvm() then
            Events.OnEnterVehicle.Add(P.onClientMirrorEnterVehicle)
        end
    end
    if Events and Events.OnPlayerUpdate then
        if C.hasClientJvm() then
            Events.OnPlayerUpdate.Add(P.onPlayerUpdate)
        end
        if C.hasServerJvm() and not C.hasClientJvm() then
            Events.OnPlayerUpdate.Add(P.onServerPlayerUpdate)
        end
    end
    if Events and Events.OnTick then
        Events.OnTick.Add(P.onTickLateTune)
        if C.hasServerJvm() and not C.hasClientJvm() then
            Events.OnTick.Add(P.onServerTickDrivers)
        end
    end
    P._eventsRegistered = true
end

function P.boot()
    if not C.isActiveHere() then
        return false
    end
    local authority = "off"
    if C.runsScriptTune() or C.runsDriverPhysicsSync() then
        authority = C.side()
    elseif C.isRemoteClient() then
        authority = "server-sim-only"
    end
    C.log(
        "physics module ready build=" .. tostring(C.PhysicsBuild)
        .. " profiles=" .. tostring(C.isProfileTuneEnabled())
        .. " handling=" .. tostring(C.isHandlingTuneEnabled())
        .. " physics_authority=" .. authority
    )
    if C.isDebugLoggingEnabled() then
        D.separator("PHYSICS MODULE BOOT")
        D.dumpSandbox()
        D.line("debugSeparators", "on (search DebugLog for IKappaID MP DEBUG)")
        D.sectionEnd()
    end
    P.registerEvents()
    return true
end

return P


