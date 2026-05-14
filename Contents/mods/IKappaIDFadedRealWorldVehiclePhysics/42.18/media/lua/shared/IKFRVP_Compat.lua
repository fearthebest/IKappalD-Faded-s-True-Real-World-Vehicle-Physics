require "IKFRVP_Core"

IKFRVP.Compat = IKFRVP.Compat or {}

local Compat = IKFRVP.Compat

Compat.loggedCSRState = false

function Compat.isCSRActive()
    return IKFRVP.isCSRActive()
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
end

return Compat
