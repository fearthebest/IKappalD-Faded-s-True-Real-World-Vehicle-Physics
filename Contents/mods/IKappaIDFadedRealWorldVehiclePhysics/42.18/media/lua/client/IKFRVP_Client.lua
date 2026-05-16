require "IKFRVP_Core"
require "IKFRVP_Tuner"
require "IKFRVP_BrakeRuntime"
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

local function getState(player)
    Client.playerState[player] = Client.playerState[player] or {
        vehicle = nil,
        ticks = 0,
    }
    return Client.playerState[player]
end

local function describeVehicle(vehicle)
    if not vehicle then
        return "none"
    end

    local script = IKFRVP.getVehicleScript(vehicle)
    local scriptName = IKFRVP.getVehicleScriptName(vehicle)
    local mass = nil
    local engineForce = nil
    local steerClamp = nil
    local wheelFriction = nil
    local targetClamp = nil
    local targetGrip = nil
    if script then
        mass = IKFRVP.readScriptNumber(script, "getMass")
        engineForce = IKFRVP.readScriptNumber(script, "getEngineForce")
        steerClamp = IKFRVP.readScriptNumber(script, "getSteeringClamp")
        wheelFriction = IKFRVP.readScriptNumber(script, "getWheelFriction")
    end
    if IKFRVP.Tuner and IKFRVP.Tuner.maneuverTargets then
        local row = IKFRVP.Tuner.maneuverTargets[scriptName]
        if row then
            targetClamp = row.steeringClamp
            targetGrip = row.wheelFriction
        end
    end

    return "id="
        .. getVehicleId(vehicle)
        .. ", script="
        .. IKFRVP.getVehicleScriptName(vehicle)
        .. ", engineForce="
        .. IKFRVP.formatNumber(engineForce)
        .. ", mass="
        .. IKFRVP.formatNumber(mass)
        .. ", steeringClamp="
        .. IKFRVP.formatNumber(steerClamp)
        .. ", wheelFriction="
        .. IKFRVP.formatNumber(wheelFriction)
        .. ", targetClamp="
        .. IKFRVP.formatNumber(targetClamp)
        .. ", targetGrip="
        .. IKFRVP.formatNumber(targetGrip)
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
    if command == "GlitchGuardTripped" then
        if IKFRVP.Safety and IKFRVP.Safety.applyClientTripMirror then
            IKFRVP.Safety.applyClientTripMirror(args or {})
            IKFRVP.log(
                "glitch-guard: server disabled experimental handling ("
                .. tostring(args and args.reason or "unknown")
                .. ")."
            )
        end
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
