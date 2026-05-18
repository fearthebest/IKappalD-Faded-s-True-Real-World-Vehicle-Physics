-- IKFRVP Manual Transmission WIP (3.0.0) — sandbox + hooks for main IKFRVP (2.0.x).
-- Requires main mod IKappaIDFadedRealWorldVehiclePhysics to load first.

require "IKFRVP_Core"

IKFRVP.MTVersion = "3.0.0"

function IKFRVP.isManualTransmissionEnabled()
    return IKFRVP.isEnabled() and IKFRVP.boolOption("ManualTransmission", false)
end

function IKFRVP.isManualTransmissionStallingEnabled()
    return IKFRVP.boolOption("ManualTransmissionStalling", true)
end

function IKFRVP.isManualTransmissionRevMatchEnabled()
    return IKFRVP.boolOption("ManualTransmissionRevMatch", true)
end

function IKFRVP.isManualTransmissionHudEnabled()
    return IKFRVP.boolOption("ManualTransmissionHud", true)
end

function IKFRVP.getManualTransmissionClutchCoef()
    return IKFRVP.numberOption("ManualTransmissionClutchCoef", 0.22, 0.05, 1.0)
end

function IKFRVP.isManualClutchActive(vehicle)
    if not IKFRVP.isManualTransmissionEnabled() then
        return false
    end
    if IKFRVP.ManualTransmission and IKFRVP.ManualTransmission.isManagingEngine then
        return IKFRVP.ManualTransmission.isManagingEngine(vehicle)
    end
    return false
end

function IKFRVP.isManualTransmissionControllingEngine(vehicle)
    if not IKFRVP.isManualTransmissionEnabled() or not vehicle then
        return false
    end
    local mt = IKFRVP.ManualTransmission
    if not mt or not mt._vehicleState or not vehicle.getId then
        return false
    end
    local id = vehicle:getId()
    if id == nil then
        return false
    end
    return mt._vehicleState[tostring(id)] ~= nil
end

if IKFRVP.log then
    IKFRVP.log(
        "manual-transmission WIP "
        .. tostring(IKFRVP.MTVersion)
        .. " loaded — broken / unsupported; use main IKFRVP 2.0.x without this addon for gameplay"
    )
end
