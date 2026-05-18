require "IKFRVP_Core"
require "IKFRVP_Tuner"
require "IKFRVP_BrakeRuntime"
require "IKFRVP_Compat"
require "IKFRVP_Bridge"

if type(isClient) == "function" and isClient() then
    return
end

IKFRVP.Server = IKFRVP.Server or {}

local Server = IKFRVP.Server
local Bridge = IKFRVP.Bridge

local function statusPayload(vehicle)
    if IKFRVP.buildStatusTable then
        return IKFRVP.buildStatusTable(vehicle)
    end
    return { version = IKFRVP.Version }
end

local function vehicleFromArgs(args)
    if type(args) ~= "table" or type(args.vehicle) ~= "number" then
        return nil
    end
    if not getVehicleById then
        return nil
    end
    return getVehicleById(args.vehicle)
end

local function sendStatus(player, vehicle)
    if player and sendServerCommand then
        sendServerCommand(player, IKFRVP.CommandModule, "Status", statusPayload(vehicle))
    end
end

function Server.onServerStarted()
    if not IKFRVP.isEnabled() then
        IKFRVP.log("server disabled by sandbox settings")
        return
    end

    if IKFRVP.Compat.onStartup then
        IKFRVP.Compat.onStartup()
    else
        IKFRVP.Compat.logCSRState("server-start")
    end
    if IKFRVP.Safety and IKFRVP.Safety.refreshTripState then
        IKFRVP.Safety.refreshTripState()
        if IKFRVP.Safety.tripped and IKFRVP.Safety.applyRecommendedSandbox then
            IKFRVP.Safety.applyRecommendedSandbox()
            IKFRVP.Safety.retuneWithoutExperimental()
            IKFRVP.log("glitch-guard: server restored safe handling from persisted trip state")
        end
    end

    if Bridge and Bridge.isCompanionActive() then
        IKFRVP.log("companion bridge ready for Project Faded Car")
    end
    IKFRVP.log("server ready; vehicle physics and glitch-guard authority are server-side")
end

function Server.onClientCommand(module, command, player, args)
    if module ~= IKFRVP.CommandModule then
        return
    end

    args = args or {}

    if not Bridge then
        return
    end

    if command == "RequestStatus" then
        sendStatus(player, vehicleFromArgs(args))
        return
    end

    if command == "SyncVehicle" then
        local vehicle = vehicleFromArgs(args)
        local ok, message = Bridge.performAction("syncVehicle", player, vehicle)
        sendStatus(player, vehicle)
        IKFRVP.debug("bridge SyncVehicle: " .. tostring(message) .. " ok=" .. tostring(ok))
        return
    end

    if command == "Retune" then
        if not Bridge.hasAdminAccess(player) then
            sendStatus(player, nil)
            return
        end
        local ok, message = Bridge.performAction("retune", player, nil)
        sendStatus(player, nil)
        IKFRVP.debug("bridge Retune: " .. tostring(message) .. " ok=" .. tostring(ok))
        return
    end

    if command == "SafeHandling" then
        if not Bridge.hasAdminAccess(player) then
            sendStatus(player, nil)
            return
        end
        local ok, message = Bridge.performAction("safeHandling", player, nil)
        sendStatus(player, nil)
        IKFRVP.debug("bridge SafeHandling: " .. tostring(message) .. " ok=" .. tostring(ok))
        return
    end

    IKFRVP.debug("ignored unknown client command: " .. tostring(command))
end

function Server.registerEvents()
    if Server.eventsRegistered then
        return
    end
    if Events and Events.OnServerStarted then
        Events.OnServerStarted.Add(Server.onServerStarted)
    end
    if Events and Events.OnClientCommand then
        Events.OnClientCommand.Add(Server.onClientCommand)
    end
    Server.eventsRegistered = true
end

Server.registerEvents()

return Server
