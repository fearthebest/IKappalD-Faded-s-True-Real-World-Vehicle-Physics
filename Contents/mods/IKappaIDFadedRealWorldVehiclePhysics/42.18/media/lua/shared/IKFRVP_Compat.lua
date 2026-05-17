require "IKFRVP_Core"

IKFRVP.Compat = IKFRVP.Compat or {}

local Compat = IKFRVP.Compat

Compat.loggedCSRState = false

function Compat.isCSRActive()
    return IKFRVP.isCSRActive()
end

function Compat.isProjectFadedCarActive()
    return IKFRVP.modActive("ProjectFadedCar")
end

function Compat.isCSRCompatibilityActive()
    return IKFRVP.isCSRCompatibilityModeEnabled() and Compat.isCSRActive()
end

function Compat.logCSRState(source)
    if Compat.loggedCSRState then
        return
    end
    Compat.loggedCSRState = true

    if Compat.isCSRCompatibilityActive() then
        IKFRVP.debug("compat: CommonSenseReborn detected during " .. tostring(source) .. "; CSR-owned vehicle systems are untouched")
    elseif IKFRVP.isCSRCompatibilityModeEnabled() then
        IKFRVP.debug("compat: CommonSenseReborn not detected during " .. tostring(source))
    end
end

function Compat.onStartup()
    Compat.logCSRState("startup")
    if Compat.isProjectFadedCarActive() then
        if IKFRVP.Bridge and IKFRVP.Bridge.isCompanionBridgeEnabled and IKFRVP.Bridge.isCompanionBridgeEnabled() then
            IKFRVP.log("compat: Project Faded Car bridge connected (IKFRVP.Bridge v" .. tostring(IKFRVP.Bridge.VERSION or 0) .. ")")
        else
            IKFRVP.debug("compat: Project Faded Car detected; bridge disabled by companion sandbox")
        end
    end
end

return Compat
