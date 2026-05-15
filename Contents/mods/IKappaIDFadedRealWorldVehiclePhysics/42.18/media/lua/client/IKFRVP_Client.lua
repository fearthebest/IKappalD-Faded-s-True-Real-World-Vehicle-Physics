require "IKFRVP_Core"
require "IKFRVP_Tuner"
require "IKFRVP_Compat"

if type(isServer) == "function" and isServer() then
    return
end

IKFRVP.Client = IKFRVP.Client or {}

local Client = IKFRVP.Client

Client.playerState = Client.playerState or {}

local function getPlayerVehicle(player)
    if player and player.getVehicle then
        return player:getVehicle()
    end
    return nil
end

local function getVehicleId(vehicle)
    if vehicle and vehicle.getId then
        local id = vehicle:getId()
        if id ~= nil then
            return tostring(id)
        end
    end
    return "unknown"
end

-- Identify a player by a stable id so Client.playerState doesn't leak entries when
-- Project Zomboid reconstructs the IsoPlayer Lua wrapper (respawn, rejoin, debug
-- reattach). Username is preferred; the player table reference is only used when no
-- stable id is available (singleplayer dev builds).
local function getPlayerKey(player)
    if not player then
        return nil
    end
    if player.getUsername then
        local ok, name = pcall(function() return player:getUsername() end)
        if ok and name ~= nil and tostring(name) ~= "" then
            return "user:" .. tostring(name)
        end
    end
    if player.getOnlineID then
        local ok, id = pcall(function() return player:getOnlineID() end)
        if ok and id ~= nil then
            return "online:" .. tostring(id)
        end
    end
    return "ref:" .. tostring(player)
end

local function getState(player)
    local key = getPlayerKey(player)
    if not key then
        return nil
    end
    Client.playerState[key] = Client.playerState[key] or {
        vehicle = nil,
        ticks = 0,
    }
    return Client.playerState[key]
end

local function describeVehicle(vehicle)
    if not vehicle then
        return "none"
    end

    local script = IKFRVP.getVehicleScript(vehicle)
    local mass = nil
    local engineForce = nil
    if script then
        mass = IKFRVP.readScriptNumber(script, "getMass")
        engineForce = IKFRVP.readScriptNumber(script, "getEngineForce")
    end

    return "id="
        .. getVehicleId(vehicle)
        .. ", script="
        .. IKFRVP.getVehicleScriptName(vehicle)
        .. ", engineForce="
        .. IKFRVP.formatNumber(engineForce)
        .. ", mass="
        .. IKFRVP.formatNumber(mass)
end

function Client.requestServerStatus()
    if type(isClient) == "function" and isClient() and sendClientCommand then
        sendClientCommand(IKFRVP.CommandModule, "RequestStatus", {})
    end
end

function Client.onServerCommand(module, command, args)
    if module ~= IKFRVP.CommandModule then
        return
    end
    if command == "Status" and IKFRVP.isDebugLoggingEnabled() then
        args = args or {}
        IKFRVP.log(
            "server-status: version="
            .. tostring(args.version)
            .. ", seen="
            .. tostring(args.seen)
            .. ", profiled="
            .. tostring(args.profiled)
            .. ", applied="
            .. tostring(args.applied)
            .. ", auditOnly="
            .. tostring(args.auditOnly)
        )
    end
end

function Client.onGameStart()
    if not IKFRVP.isEnabled() then
        IKFRVP.log("client disabled by sandbox settings")
        return
    end

    IKFRVP.Compat.logCSRState("client-start")
    IKFRVP.debug("client ready")
    Client.registerDebugEvents()
    Client.requestServerStatus()
end

function Client.onEnterVehicle(player)
    if not IKFRVP.isEnabled() or not IKFRVP.isDebugLoggingEnabled() then
        return
    end
    IKFRVP.log("vehicle-enter: " .. describeVehicle(getPlayerVehicle(player)))
end

function Client.onExitVehicle(player)
    if not IKFRVP.isEnabled() or not IKFRVP.isDebugLoggingEnabled() then
        return
    end
    IKFRVP.log("vehicle-exit: " .. describeVehicle(getPlayerVehicle(player)))
end

function Client.onPlayerUpdate(player)
    if not player or not IKFRVP.isEnabled() or not IKFRVP.isDebugLoggingEnabled() then
        return
    end

    local state = getState(player)
    if not state then
        return
    end
    local vehicle = getPlayerVehicle(player)
    if state.vehicle ~= vehicle then
        state.vehicle = vehicle
        state.ticks = 0
        if vehicle then
            IKFRVP.log("vehicle-active: " .. describeVehicle(vehicle))
        end
    end

    if not vehicle then
        return
    end

    state.ticks = state.ticks + 1
    if state.ticks >= IKFRVP.getProbeIntervalTicks() then
        state.ticks = 0
        IKFRVP.log("vehicle-probe: " .. describeVehicle(vehicle))
    end
end

function Client.registerEvents()
    if Client.eventsRegistered then
        return
    end
    if Events and Events.OnGameStart then
        Events.OnGameStart.Add(Client.onGameStart)
    end
    if Events and Events.OnServerCommand then
        Events.OnServerCommand.Add(Client.onServerCommand)
    end
    Client.eventsRegistered = true
end

function Client.registerDebugEvents()
    if Client.debugEventsRegistered or not IKFRVP.isDebugLoggingEnabled() then
        return
    end
    if Events and Events.OnEnterVehicle then
        Events.OnEnterVehicle.Add(Client.onEnterVehicle)
    end
    if Events and Events.OnExitVehicle then
        Events.OnExitVehicle.Add(Client.onExitVehicle)
    end
    if Events and Events.OnPlayerUpdate then
        Events.OnPlayerUpdate.Add(Client.onPlayerUpdate)
    end
    Client.debugEventsRegistered = true
end

Client.registerEvents()

return Client
