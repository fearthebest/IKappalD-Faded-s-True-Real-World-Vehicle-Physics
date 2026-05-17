-- Companion-mod bridge API (Project Faded Car and future integrations).
-- PFC_IKFRVPBridge.lua calls into IKFRVP.Bridge when this physics mod is loaded.

require "IKFRVP_Core"

IKFRVP.Bridge = IKFRVP.Bridge or {}

local Bridge = IKFRVP.Bridge

Bridge.VERSION = 1
Bridge.COMPANION_MOD_ID = "ProjectFadedCar"
Bridge.SOURCES = {
    status = true,
    syncVehicle = true,
    retune = true,
    safeHandling = true,
}

local ADMIN_ACTIONS = {
    retune = true,
    safeHandling = true,
}

function Bridge.isCompanionActive()
    return IKFRVP.modActive(Bridge.COMPANION_MOD_ID)
end

function Bridge.isCompanionBridgeEnabled()
    if not Bridge.isCompanionActive() then
        return false
    end
    local sandbox = SandboxVars and SandboxVars.ProjectFadedCar or nil
    if sandbox and sandbox.EnableIKFRVPBridge == false then
        return false
    end
    if sandbox and sandbox.EnableProjectFadedCar == false then
        return false
    end
    return true
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
    return ADMIN_ACTIONS[tostring(action or "")] == true
end

function Bridge.getStatus(vehicle)
    if IKFRVP.buildStatusTable then
        return IKFRVP.buildStatusTable(vehicle)
    end
    return { version = IKFRVP.Version, loaded = true, active = true }
end

function Bridge.syncVehicle(vehicle)
    if not IKFRVP.isEnabled() then
        return false, "physics-disabled"
    end
    if not vehicle then
        return false, "missing-vehicle"
    end

    local runtime = IKFRVP.BrakeRuntime
    if not runtime then
        return false, "physics-unavailable"
    end

    local changed = false
    if runtime.syncVehiclePhysics then
        changed = runtime.syncVehiclePhysics(vehicle, {}) == true
    else
        if runtime.syncVehicleBrakes then
            changed = runtime.syncVehicleBrakes(vehicle) == true or changed
        end
        if runtime.syncVehicleEngine then
            changed = runtime.syncVehicleEngine(vehicle) == true or changed
        end
    end

    if changed then
        return true, "physics-synced"
    end
    return true, "physics-current"
end

function Bridge.retune(source)
    if not IKFRVP.isEnabled() then
        return false, "physics-disabled"
    end
    if not IKFRVP.Tuner or not IKFRVP.Tuner.processAllScripts then
        return false, "physics-retune-unavailable"
    end

    IKFRVP.Tuner.appliedSignatures = {}
    local stats = IKFRVP.Tuner.processAllScripts(source or "CompanionBridge")
    return true, "physics-retuned", stats
end

function Bridge.safeHandling(source)
    if not IKFRVP.isEnabled() then
        return false, "physics-disabled"
    end
    if not IKFRVP.Safety then
        return false, "physics-safe-unavailable"
    end

    if IKFRVP.Safety.applyRecommendedSandbox then
        IKFRVP.Safety.applyRecommendedSandbox()
    end
    if IKFRVP.Safety.retuneWithoutExperimental then
        IKFRVP.Safety.retuneWithoutExperimental()
    else
        Bridge.retune(source or "CompanionBridgeSafe")
    end
    return true, "physics-safe-reset"
end

function Bridge.performAction(action, player, vehicle)
    action = tostring(action or "status")

    if not IKFRVP.isEnabled() then
        return false, "physics-disabled", Bridge.getStatus(vehicle)
    end
    if Bridge.actionRequiresAdmin(action) and not Bridge.hasAdminAccess(player) then
        return false, "physics-admin-only", Bridge.getStatus(vehicle)
    end
    if action == "status" then
        return true, "physics-status", Bridge.getStatus(vehicle)
    end
    if action == "syncVehicle" then
        local ok, message = Bridge.syncVehicle(vehicle)
        return ok, message, Bridge.getStatus(vehicle)
    end
    if action == "retune" then
        local ok, message = Bridge.retune("CompanionBridge")
        return ok, message, Bridge.getStatus(vehicle)
    end
    if action == "safeHandling" then
        local ok, message = Bridge.safeHandling("CompanionBridgeSafe")
        return ok, message, Bridge.getStatus(vehicle)
    end

    return false, "physics-bad-action", Bridge.getStatus(vehicle)
end

-- Entry point for Project Faded Car after engine swap, wreck restore, or script reload.
function Bridge.onCompanionVehicleChanged(vehicle, source)
    if not Bridge.isCompanionBridgeEnabled() then
        return false, "bridge-disabled"
    end
    if not vehicle then
        return false, "missing-vehicle"
    end
    IKFRVP.debug("bridge: companion vehicle changed (" .. tostring(source or "unknown") .. ")")
    return Bridge.syncVehicle(vehicle)
end

return Bridge
