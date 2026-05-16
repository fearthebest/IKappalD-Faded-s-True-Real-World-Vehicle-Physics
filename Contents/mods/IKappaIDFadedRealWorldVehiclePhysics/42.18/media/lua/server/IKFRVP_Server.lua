require "IKFRVP_Core"
require "IKFRVP_Tuner"
require "IKFRVP_BrakeRuntime"
require "IKFRVP_Compat"

if type(isClient) == "function" and isClient() then
    return
end

IKFRVP.Server = IKFRVP.Server or {}

local Server = IKFRVP.Server

local function statusArgs()
    local stats = IKFRVP.Tuner and IKFRVP.Tuner.lastStats or {}
    return {
        version = IKFRVP.Version,
        enabled = IKFRVP.isEnabled(),
        profileTuning = IKFRVP.isProfileTuningEnabled(),
        genericTuning = IKFRVP.isGenericMultiplierTuningEnabled(),
        auditOnly = IKFRVP.isAuditOnly(),
        csrActive = IKFRVP.isCSRActive(),
        seen = tonumber(stats.seen) or 0,
        profiled = tonumber(stats.profiled) or 0,
        generic = tonumber(stats.generic) or 0,
        applied = tonumber(stats.applied) or 0,
        audited = tonumber(stats.audited) or 0,
        skipped = tonumber(stats.skipped) or 0,
    }
end

function Server.onServerStarted()
    if not IKFRVP.isEnabled() then
        IKFRVP.log("server disabled by sandbox settings")
        return
    end

    IKFRVP.Compat.logCSRState("server-start")
    if IKFRVP.Safety and IKFRVP.Safety.refreshTripState then
        IKFRVP.Safety.refreshTripState()
        if IKFRVP.Safety.tripped and IKFRVP.Safety.applyRecommendedSandbox then
            IKFRVP.Safety.applyRecommendedSandbox()
            IKFRVP.Safety.retuneWithoutExperimental()
            IKFRVP.log("glitch-guard: server restored safe handling from persisted trip state")
        end
    end
    IKFRVP.log("server ready; vehicle physics and glitch-guard authority are server-side")
end

function Server.onClientCommand(module, command, player, args)
    if module ~= IKFRVP.CommandModule then
        return
    end

    if command == "RequestStatus" then
        if player and sendServerCommand then
            sendServerCommand(player, IKFRVP.CommandModule, "Status", statusArgs())
        end
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
