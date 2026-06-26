-- Server-authoritative IK_MP sandbox for remote MP clients.
require "IK_MP_Core"

IK_MP.SandboxSync = IK_MP.SandboxSync or {}

local S = IK_MP.SandboxSync
local C = IK_MP

-- Must match media/sandbox-options.txt option names (IK_MP.*).
local SANDBOX_KEYS = {
    "Enabled",
    "EnableProfileTune",
    "DebugLogging",
    "PowerMult",
    "AccelerationMult",
    "SportPowerBias",
    "HeavyPowerBias",
    "BrakeMult",
    "BrakeStopTimeMult",
    "BrakeCreepMult",
    "CompactPowerBias",
    "CompactAccelBias",
    "CompactBrakeBias",
    "CompactGripBias",
    "CompactMassBias",
    "CompactSteeringBias",
    "CompactRollBias",
    "CompactSuspensionBias",
    "StandardPowerBias",
    "StandardAccelBias",
    "StandardBrakeBias",
    "StandardGripBias",
    "StandardMassBias",
    "StandardSteeringBias",
    "StandardRollBias",
    "StandardSuspensionBias",
    "SportAccelBias",
    "SportBrakeBias",
    "SportGripBias",
    "SportMassBias",
    "SportSteeringBias",
    "SportRollBias",
    "SportSuspensionBias",
    "HeavyAccelBias",
    "HeavyBrakeBias",
    "HeavyGripBias",
    "HeavyMassBias",
    "HeavySteeringBias",
    "HeavyRollBias",
    "HeavySuspensionBias",
    "MassMult",
    "MassUpliftMult",
    "EnableHandlingTune",
    "SuspensionFirmness",
    "WheelGripMult",
    "SteeringResponseMult",
    "SteeringClampMult",
    "BodyRollMult",
    "EnableTrunkTune",
    "TrunkCapacityMult",
    "EnableTowAssist",
    "TowAssistFactor",
    "EnableReverseTowAssist",
    "TowReverseAssistMult",
    "TowLowSpeedBoost",
    "TowAccelSoftness",
    "TowMaxLoadRatio",
    "YieldTowToCSR",
}

S._serverEventsRegistered = false
S._clientEventsRegistered = false
S._pushRev = 0
S._canonicalSnapshot = nil
S._snapshotSignature = nil
S._playerPushRev = {}
S._deferredPushTicks = 0
S._deferredInitialPushDone = false
S._DEFER_PUSH_MAX = 600
S._clientRetryTicks = 0
S._clientAppliedRev = nil
S._CLIENT_RETRY_MAX = 600
S._CLIENT_REQUEST_COOLDOWN = 90

local function playerUsername(player)
    if player and player.getUsername then
        return tostring(player:getUsername())
    end
    return nil
end

local function clientPlayerInWorld()
    if not getSpecificPlayer then
        return nil
    end
    local player = getSpecificPlayer(0)
    if not player or not player.getCell then
        return nil
    end
    if not player:getCell() then
        return nil
    end
    return player
end

local function snapshotSignature(snapshot)
    if type(snapshot) ~= "table" then
        return ""
    end
    local parts = {}
    for i = 1, #SANDBOX_KEYS do
        local key = SANDBOX_KEYS[i]
        local value = snapshot[key]
        if value ~= nil then
            parts[#parts + 1] = key .. "=" .. tostring(value)
        end
    end
    return table.concat(parts, "|")
end

local function captureSnapshotValues()
    local root = C.localSandbox()
    local snapshot = {}
    for i = 1, #SANDBOX_KEYS do
        local key = SANDBOX_KEYS[i]
        if root and root[key] ~= nil then
            snapshot[key] = root[key]
        end
    end
    return snapshot
end

-- Rebuild canonical server snapshot; bump rev only when preset values change.
function S.refreshCanonicalSnapshot()
    local values = captureSnapshotValues()
    local sig = snapshotSignature(values)
    if sig == S._snapshotSignature and type(S._canonicalSnapshot) == "table" then
        return S._canonicalSnapshot, false
    end
    S._snapshotSignature = sig
    S._pushRev = (S._pushRev or 0) + 1
    values._rev = S._pushRev
    S._canonicalSnapshot = values
    return S._canonicalSnapshot, true
end

function S.buildSnapshot()
    local snapshot, _changed = S.refreshCanonicalSnapshot()
    return snapshot
end

function S.pushToPlayer(player, force)
    if not C.hasServerJvm() or not sendServerCommand or not player then
        return false
    end
    local snapshot = S.buildSnapshot()
    if type(snapshot) ~= "table" then
        return false
    end
    local username = playerUsername(player)
    local rev = snapshot._rev
    if not force and username and rev and S._playerPushRev[username] == rev then
        return false
    end
    sendServerCommand(player, C.ModId, "SandboxSync", { vars = snapshot })
    if player.getVehicle and IK_MP.PhysicsMirror and IK_MP.PhysicsMirror.pushToPlayer then
        local vehicle = player:getVehicle()
        if vehicle then
            IK_MP.PhysicsMirror.pushToPlayer(player, vehicle, nil)
        end
    end
    if username and rev then
        S._playerPushRev[username] = rev
    end
    if force or C.isDebugLoggingEnabled() then
        local name = username or "?"
        C.debug(
            "sandbox-sync: pushed to "
                .. name
                .. " rev="
                .. tostring(rev or "?")
                .. " TrunkCapacityMult="
                .. C.formatNumber(C.trunkCapacityMult())
        )
    end
    return true
end

function S.pushToAllOnline(force)
    if not C.canQueryOnlinePlayers() then
        return 0
    end
    local online = C.safeGetOnlinePlayers()
    if not online or not online.size or online:size() == 0 then
        return 0
    end
    local count = 0
    for i = 0, online:size() - 1 do
        if S.pushToPlayer(online:get(i), force) then
            count = count + 1
        end
    end
    return count
end

function S.handleServerCommand(module, command, player, args)
    if module ~= C.ModId or command ~= "RequestSandbox" then
        return false
    end
    if not player then
        C.debug("sandbox-sync: RequestSandbox with no player (ignored)")
        return true
    end
    S.pushToPlayer(player, false)
    return true
end

function S.handleClientCommand(module, command, args)
    if module ~= C.ModId or command ~= "SandboxSync" then
        return false
    end
    if type(args) ~= "table" or type(args.vars) ~= "table" then
        C.debug("sandbox-sync: SandboxSync command had bad args")
        return false
    end
    local incomingRev = args.vars._rev
    if incomingRev and S._clientAppliedRev == incomingRev then
        return true
    end
    local incomingSig = snapshotSignature(args.vars)
    if C.hasServerSandbox() and incomingSig ~= "" and incomingSig == S._clientAppliedSig then
        return true
    end
    C.applyServerSandbox(args.vars)
    S._clientAppliedRev = incomingRev
    S._clientAppliedSig = incomingSig
    C.log(
        "sandbox-sync: applied server snapshot rev="
            .. tostring(incomingRev or "?")
            .. " TrunkCapacityMult="
            .. C.formatNumber(C.trunkCapacityMult())
    )
    if IK_MP.Physics and IK_MP.Physics.onServerSandboxApplied then
        IK_MP.Physics.onServerSandboxApplied()
    end
    if IK_MP.Trunk and IK_MP.Trunk.onServerSandboxApplied then
        IK_MP.Trunk.onServerSandboxApplied()
    end
    if IK_MP.PhysicsMirror and IK_MP.PhysicsMirror.requestMirrorFromServer then
        local vehicle = nil
        if getPlayer and getPlayer() and getPlayer().getVehicle then
            vehicle = getPlayer():getVehicle()
        end
        IK_MP.PhysicsMirror.requestMirrorFromServer(vehicle, "sandbox-sync")
    end
    return true
end

function S.requestFromServer()
    if not C.isRemoteClient() or not sendClientCommand then
        return false
    end
    if not clientPlayerInWorld() then
        return false
    end
    if C.hasServerSandbox() then
        return false
    end
    sendClientCommand(C.ModId, "RequestSandbox", {})
    C.debug("sandbox-sync: requested server snapshot (in world)")
    return true
end

function S.onTickClientRetry()
    if not C.isRemoteClient() or C.hasServerSandbox() then
        S._clientRetryTicks = 0
        return
    end
    if not clientPlayerInWorld() then
        return
    end
    S._clientRetryTicks = (S._clientRetryTicks or 0) + 1
    if S._clientRetryTicks > S._CLIENT_RETRY_MAX then
        if S._clientRetryTicks == S._CLIENT_RETRY_MAX + 1 then
            C.log("sandbox-sync: still no server snapshot after in-world retries")
        end
        return
    end
    if S._clientRetryTicks == 1 or S._clientRetryTicks == S._CLIENT_REQUEST_COOLDOWN or S._clientRetryTicks % 300 == 0 then
        S.requestFromServer()
    end
end

local function onConnected()
    if IK_MP.Bootstrap and IK_MP.Bootstrap.tryBootAll then
        IK_MP.Bootstrap.tryBootAll()
    end
end

local function onGameStart()
    if C.isRemoteClient() then
        S._clientRetryTicks = 0
        S._clientAppliedRev = nil
        S._clientAppliedSig = nil
        S.requestFromServer()
    elseif C.hasServerJvm() and C.canQueryOnlinePlayers() then
        S.pushToAllOnline(false)
    end
    if IK_MP.Bootstrap and IK_MP.Bootstrap.tryBootAll then
        IK_MP.Bootstrap.tryBootAll()
    end
end

local function onCreatePlayer(playerIndex, player)
    if not C.isRemoteClient() then
        return
    end
    if playerIndex ~= 0 then
        return
    end
    S._clientRetryTicks = 0
    S._clientAppliedRev = nil
    S._clientAppliedSig = nil
    S.requestFromServer()
end

local function onPlayerConnect(player)
    S.pushToPlayer(player, true)
end

function S.onTickDeferredPush()
    if not C.hasServerJvm() or not C.isActiveHere() then
        return
    end
    if S._deferredInitialPushDone then
        return
    end
    if C.canQueryOnlinePlayers() then
        C.markOnlinePlayersReady()
        local pushed = S.pushToAllOnline(false)
        S._deferredInitialPushDone = true
        S._deferredPushTicks = S._DEFER_PUSH_MAX + 1
        if pushed > 0 then
            C.debug("sandbox-sync: deferred push sent to " .. tostring(pushed) .. " player(s)")
        end
        return
    end
    S._deferredPushTicks = (S._deferredPushTicks or 0) + 1
    if S._deferredPushTicks > S._DEFER_PUSH_MAX then
        return
    end
    if S._deferredPushTicks == 30 or S._deferredPushTicks == 120 or S._deferredPushTicks % 240 == 0 then
        if C.canQueryOnlinePlayers() then
            C.markOnlinePlayersReady()
            local pushed = S.pushToAllOnline(false)
            if pushed > 0 then
                S._deferredInitialPushDone = true
                S._deferredPushTicks = S._DEFER_PUSH_MAX + 1
                C.debug("sandbox-sync: deferred push sent to " .. tostring(pushed) .. " player(s)")
            end
        end
    end
end

function S.armServer()
    if not C.hasServerJvm() then
        return false
    end
    if not S._serverEventsRegistered then
        if Events and Events.OnGameStart then
            Events.OnGameStart.Add(onGameStart)
        end
        if Events and Events.OnPlayerConnect then
            Events.OnPlayerConnect.Add(onPlayerConnect)
        end
        if Events and Events.OnTick then
            Events.OnTick.Add(S.onTickDeferredPush)
        end
        S._serverEventsRegistered = true
        C.log("sandbox-sync: server armed (push on connect + RequestSandbox)")
    end
    return true
end

function S.bootServer()
    if not C.hasServerJvm() then
        return false
    end
    S.armServer()
    S._pushRev = 0
    S._canonicalSnapshot = nil
    S._snapshotSignature = nil
    S._playerPushRev = {}
    S._deferredPushTicks = 0
    S._deferredInitialPushDone = false
    C.log("sandbox-sync: server ready (push on player connect / in-world request)")
    return true
end

function S.bootClient()
    if not C.hasClientJvm() then
        return false
    end
    if not S._clientEventsRegistered then
        if Events and Events.OnConnected then
            Events.OnConnected.Add(onConnected)
        end
        if Events and Events.OnGameStart then
            Events.OnGameStart.Add(onGameStart)
        end
        if Events and Events.OnCreatePlayer then
            Events.OnCreatePlayer.Add(onCreatePlayer)
        end
        if Events and Events.OnTick then
            Events.OnTick.Add(S.onTickClientRetry)
        end
        S._clientEventsRegistered = true
        C.log("sandbox-sync: client armed remote=" .. tostring(C.isRemoteClient()))
    end
    return true
end

return S


