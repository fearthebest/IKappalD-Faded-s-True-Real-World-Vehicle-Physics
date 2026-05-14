require "IKFRVP_Core"
require "IKFRVP_Tuner"
require "IKFRVP_Compat"

if type(isServer) == "function" and isServer() then
    return
end

IKFRVP.Client = IKFRVP.Client or {}

local Client = IKFRVP.Client

Client.playerState = Client.playerState or {}
Client.brakeSqueal = Client.brakeSqueal or {
    cooldown = 0,
    ring = {},
}

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

local function playHardBrakeSqueal(vehicle)
    if not vehicle then
        return
    end
    local sq = vehicle.getSquare and vehicle:getSquare()
    if not sq then
        return
    end
    local sm = getSoundManager and getSoundManager()
    if not sm or not sm.PlayWorldSound then
        return
    end
    pcall(function()
        sm:PlayWorldSound("VehicleSkid", sq, 0, 50, 1, false)
    end)
end

function Client.updateBrakeTireSqueal(player)
    if type(getPlayer) ~= "function" then
        return
    end
    local gp = getPlayer()
    if not player or not gp or player ~= gp then
        return
    end

    local bs = Client.brakeSqueal
    local vehicle = getPlayerVehicle(player)

    if not vehicle then
        bs.ring = {}
        bs.cooldown = 0
        return
    end

    if vehicle.getDriver and vehicle:getDriver() ~= player then
        bs.ring = {}
        return
    end

    if bs.cooldown > 0 then
        bs.cooldown = bs.cooldown - 1
        return
    end

    local speedKmh = math.abs(vehicle.getCurrentSpeedKmHour and vehicle:getCurrentSpeedKmHour() or 0)
    local braking = vehicle.isBraking and vehicle:isBraking()

    if not braking or speedKmh < 16 then
        bs.ring = {}
        return
    end

    local ring = bs.ring
    ring[#ring + 1] = speedKmh
    if #ring > 6 then
        table.remove(ring, 1)
    end
    if #ring < 6 then
        return
    end

    local decel = ring[1] - ring[#ring]
    if decel < 10 then
        return
    end

    playHardBrakeSqueal(vehicle)
    bs.cooldown = 35
    bs.ring = {}
end

function Client.onPlayerUpdate(player)
    if not player or not IKFRVP.isEnabled() then
        return
    end

    Client.updateBrakeTireSqueal(player)

    if not IKFRVP.isDebugLoggingEnabled() then
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
    if Events and Events.OnPlayerUpdate then
        Events.OnPlayerUpdate.Add(Client.onPlayerUpdate)
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
    Client.debugEventsRegistered = true
end

Client.registerEvents()

return Client
